import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../data/models/note.dart';
import '../data/repositories/note_repository.dart';

import '../services/firebase_service.dart';
import '../services/hive_service.dart'; // Added import for HiveService

// Events
abstract class NotesEvent extends Equatable {
  const NotesEvent();

  @override
  List<Object?> get props => [];
}

class LoadNotes extends NotesEvent {
  final String habitId;
  final String userId;

  const LoadNotes({
    required this.habitId,
    required this.userId,
  });

  @override
  List<Object?> get props => [habitId, userId];
}

class CreateNote extends NotesEvent {
  final String text;
  final String habitId;
  final String userId;

  const CreateNote({
    required this.text,
    required this.habitId,
    required this.userId,
  });

  @override
  List<Object?> get props => [text, habitId, userId];
}

class UpdateNote extends NotesEvent {
  final Note note;
  final String userId;

  const UpdateNote({
    required this.note,
    required this.userId,
  });

  @override
  List<Object?> get props => [note, userId];
}

class DeleteNote extends NotesEvent {
  final String noteId;
  final String userId;

  const DeleteNote({
    required this.noteId,
    required this.userId,
  });

  @override
  List<Object?> get props => [noteId, userId];
}

class SearchNotes extends NotesEvent {
  final String query;
  final String? habitId;

  const SearchNotes({
    required this.query,
    this.habitId,
  });

  @override
  List<Object?> get props => [query, habitId];
}

// States
abstract class NotesState extends Equatable {
  const NotesState();

  @override
  List<Object?> get props => [];
}

class NotesInitial extends NotesState {}

class NotesLoading extends NotesState {}

class NotesLoaded extends NotesState {
  final List<Note> notes;
  final List<Note> filteredNotes;
  final String habitId;
  final String searchQuery;

  const NotesLoaded({
    required this.notes,
    required this.filteredNotes,
    required this.habitId,
    this.searchQuery = '',
  });

  NotesLoaded copyWith({
    List<Note>? notes,
    List<Note>? filteredNotes,
    String? habitId,
    String? searchQuery,
  }) {
    return NotesLoaded(
      notes: notes ?? this.notes,
      filteredNotes: filteredNotes ?? this.filteredNotes,
      habitId: habitId ?? this.habitId,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props => [notes, filteredNotes, habitId, searchQuery];
}

class NotesError extends NotesState {
  final String message;

  const NotesError(this.message);

  @override
  List<Object?> get props => [message];
}

// Cubit
class NotesCubit extends Cubit<NotesState> {
  final NoteRepository _noteRepository = NoteRepository();
  final FirebaseService _firebaseService = FirebaseService(); // Added FirebaseService instance

  NotesCubit() : super(NotesInitial());

  Future<void> loadNotes(String habitId, String userId) async {
    emit(NotesLoading());
    
    try {
      // Load local first
      var notes = await _noteRepository.getNotesForHabit(userId, habitId);
      
      // If empty locally, fetch from remote and persist locally
      if (notes.isEmpty) {
        try {
          final remote = await _firebaseService.getNotes(userId, habitId);
          if (remote.isNotEmpty) {
            await HiveService.saveNotes(userId, remote);
            notes = remote;
          }
        } catch (_) {
          // ignore remote errors here; local still shown
        }
      }
      
      emit(NotesLoaded(
        notes: notes,
        filteredNotes: notes,
        habitId: habitId,
      ));
    } catch (e) {
      emit(NotesError(e.toString()));
    }
  }

  Future<void> createNote({
    required String text,
    required String habitId,
    required String userId,
  }) async {
    try {
      final note = await _noteRepository.createNote(
        text: text,
        habitId: habitId,
        userId: userId,
      );
      
      final currentState = state;
      if (currentState is NotesLoaded) {
        final updatedNotes = [note, ...currentState.notes];
        final updatedFilteredNotes = _filterNotes(updatedNotes, currentState.searchQuery);
        
        emit(currentState.copyWith(
          notes: updatedNotes,
          filteredNotes: updatedFilteredNotes,
        ));
      }
    } catch (e) {
      emit(NotesError(e.toString()));
    }
  }

  Future<void> updateNote(Note note, String userId) async {
    try {
      await _noteRepository.updateNote(note, userId);
      
      final currentState = state;
      if (currentState is NotesLoaded) {
        final updatedNotes = currentState.notes.map((n) => n.id == note.id ? note : n).toList();
        final updatedFilteredNotes = _filterNotes(updatedNotes, currentState.searchQuery);
        
        emit(currentState.copyWith(
          notes: updatedNotes,
          filteredNotes: updatedFilteredNotes,
        ));
      }
    } catch (e) {
      emit(NotesError(e.toString()));
    }
  }

  Future<void> deleteNote(String noteId, String userId) async {
    try {
      await _noteRepository.deleteNote(noteId, userId);
      
      final currentState = state;
      if (currentState is NotesLoaded) {
        final updatedNotes = currentState.notes.where((n) => n.id != noteId).toList();
        final updatedFilteredNotes = _filterNotes(updatedNotes, currentState.searchQuery);
        
        emit(currentState.copyWith(
          notes: updatedNotes,
          filteredNotes: updatedFilteredNotes,
        ));
      }
    } catch (e) {
      emit(NotesError(e.toString()));
    }
  }

  Future<void> searchNotes(String query, String userId, {String? habitId}) async {
    final currentState = state;
    if (currentState is NotesLoaded) {
      try {
        final filteredNotes = await _noteRepository.searchNotes(userId, query, habitId: habitId);
        emit(currentState.copyWith(
          filteredNotes: filteredNotes,
          searchQuery: query,
        ));
      } catch (e) {
        emit(NotesError(e.toString()));
      }
    }
  }

  List<Note> _filterNotes(List<Note> notes, String query) {
    if (query.isEmpty) return notes;
    return notes
        .where((note) => 
            note.text.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  Future<List<Note>> getRecentNotes(String userId, {int limit = 10}) async {
    final currentState = state;
    if (currentState is NotesLoaded) {
      try {
        return await _noteRepository.getRecentNotes(userId, limit: limit);
      } catch (e) {
        print('Failed to get recent notes: $e');
        return [];
      }
    }
    return [];
  }

  Future<int> getNotesCount(String userId) async {
    final currentState = state;
    if (currentState is NotesLoaded) {
      try {
        return await _noteRepository.getNotesCountForHabit(userId, currentState.habitId);
      } catch (e) {
        print('Failed to get notes count: $e');
        return 0;
      }
    }
    return 0;
  }

  Future<void> refreshNotes(String userId, String habitId) async {
    try {
      final notes = await _noteRepository.getNotesForHabit(userId, habitId);
      final currentState = state;
      if (currentState is NotesLoaded) {
        if (_areNotesSame(currentState.notes, notes)) {
          return; // no changes
        }
        final filtered = _filterNotes(notes, currentState.searchQuery);
        emit(currentState.copyWith(notes: notes, filteredNotes: filtered));
      } else {
        emit(NotesLoaded(notes: notes, filteredNotes: notes, habitId: habitId));
      }
    } catch (e) {
      emit(NotesError(e.toString()));
    }
  }

  bool _areNotesSame(List<Note> a, List<Note> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    final Map<String, DateTime> mapA = { for (final n in a) n.id: n.createdAt };
    for (final nb in b) {
      final t = mapA[nb.id];
      if (t == null) return false;
      if (!t.isAtSameMomentAs(nb.createdAt)) return false;
    }
    return true;
  }
}
