import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../data/models/habit.dart';
import '../data/repositories/habit_repository.dart';
import '../services/analytics_service.dart';

// Events
abstract class HabitsEvent extends Equatable {
  const HabitsEvent();

  @override
  List<Object?> get props => [];
}

class LoadHabits extends HabitsEvent {
  final String userId;

  const LoadHabits(this.userId);

  @override
  List<Object?> get props => [userId];
}

class CreateHabit extends HabitsEvent {
  final String title;
  final String color;
  final String userId;

  const CreateHabit({
    required this.title,
    required this.color,
    required this.userId,
  });

  @override
  List<Object?> get props => [title, color, userId];
}

class UpdateHabit extends HabitsEvent {
  final Habit habit;
  final String userId;

  const UpdateHabit({
    required this.habit,
    required this.userId,
  });

  @override
  List<Object?> get props => [habit, userId];
}

class DeleteHabit extends HabitsEvent {
  final String habitId;
  final String userId;

  const DeleteHabit({
    required this.habitId,
    required this.userId,
  });

  @override
  List<Object?> get props => [habitId, userId];
}

class ToggleHabitCompletion extends HabitsEvent {
  final Habit habit;
  final String userId;

  const ToggleHabitCompletion({
    required this.habit,
    required this.userId,
  });

  @override
  List<Object?> get props => [habit, userId];
}

class SearchHabits extends HabitsEvent {
  final String query;

  const SearchHabits(this.query);

  @override
  List<Object?> get props => [query];
}

class LoadAnalytics extends HabitsEvent {}

// States
abstract class HabitsState extends Equatable {
  const HabitsState();

  @override
  List<Object?> get props => [];
}

class HabitsInitial extends HabitsState {}

class HabitsLoading extends HabitsState {}

class HabitsLoaded extends HabitsState {
  final List<Habit> habits;
  final List<Habit> filteredHabits;
  final String searchQuery;
  final HabitSummary? summary;

  const HabitsLoaded({
    required this.habits,
    required this.filteredHabits,
    this.searchQuery = '',
    this.summary,
  });

  HabitsLoaded copyWith({
    List<Habit>? habits,
    List<Habit>? filteredHabits,
    String? searchQuery,
    HabitSummary? summary,
  }) {
    return HabitsLoaded(
      habits: habits ?? this.habits,
      filteredHabits: filteredHabits ?? this.filteredHabits,
      searchQuery: searchQuery ?? this.searchQuery,
      summary: summary ?? this.summary,
    );
  }

  @override
  List<Object?> get props => [habits, filteredHabits, searchQuery, summary];
}

class HabitsError extends HabitsState {
  final String message;

  const HabitsError(this.message);

  @override
  List<Object?> get props => [message];
}

// Cubit
class HabitsCubit extends Cubit<HabitsState> {
  final HabitRepository _habitRepository = HabitRepository();

  HabitsCubit() : super(HabitsInitial());

  Future<void> loadHabits(String userId) async {
    emit(HabitsLoading());
    
    try {
      final habits = await _habitRepository.getAllHabits(userId);
      final sortedHabits = _sortHabits(habits);
      emit(HabitsLoaded(
        habits: sortedHabits,
        filteredHabits: sortedHabits,
      ));
      
      // Load analytics in parallel
      await loadAnalytics();
    } catch (e) {
      emit(HabitsError(e.toString()));
    }
  }

  Future<void> createHabit({
    required String title,
    required String color,
    required String userId,
  }) async {
    try {
      final habit = await _habitRepository.createHabit(
        title: title,
        color: color,
        userId: userId,
      );
      
      final currentState = state;
      if (currentState is HabitsLoaded) {
        final updatedHabits = _sortHabits([habit, ...currentState.habits]);
        final updatedFilteredHabits = _filterHabits(updatedHabits, currentState.searchQuery);
        
        emit(currentState.copyWith(
          habits: updatedHabits,
          filteredHabits: updatedFilteredHabits,
        ));
        
        // Reload analytics
        await loadAnalytics();
      }
    } catch (e) {
      emit(HabitsError(e.toString()));
    }
  }

  Future<void> updateHabit(Habit habit, String userId) async {
    try {
      await _habitRepository.updateHabit(habit, userId);
      
      final currentState = state;
      if (currentState is HabitsLoaded) {
        final updatedHabits = _sortHabits(currentState.habits.map((h) => h.id == habit.id ? habit : h).toList());
        final updatedFilteredHabits = _filterHabits(updatedHabits, currentState.searchQuery);
        
        emit(currentState.copyWith(
          habits: updatedHabits,
          filteredHabits: updatedFilteredHabits,
        ));
        
        // Reload analytics
        await loadAnalytics();
      }
    } catch (e) {
      emit(HabitsError(e.toString()));
    }
  }

  Future<void> deleteHabit(String habitId, String userId) async {
    try {
      await _habitRepository.deleteHabit(habitId, userId);
      
      final currentState = state;
      if (currentState is HabitsLoaded) {
        final updatedHabits = _sortHabits(currentState.habits.where((h) => h.id != habitId).toList());
        final updatedFilteredHabits = _filterHabits(updatedHabits, currentState.searchQuery);
        
        emit(currentState.copyWith(
          habits: updatedHabits,
          filteredHabits: updatedFilteredHabits,
        ));
        
        // Reload analytics
        await loadAnalytics();
      }
    } catch (e) {
      emit(HabitsError(e.toString()));
    }
  }

  Future<void> toggleHabitCompletion(Habit habit, String userId) async {
    try {
      await _habitRepository.toggleTodayCompletion(habit, userId);
      
      // Reload habits to get updated completion status
      await loadHabits(userId);
    } catch (e) {
      emit(HabitsError(e.toString()));
    }
  }

  Future<void> searchHabits(String query, String userId) async {
    final currentState = state;
    if (currentState is HabitsLoaded) {
      try {
        final filteredHabits = await _habitRepository.searchHabits(userId, query);
        emit(currentState.copyWith(
          filteredHabits: filteredHabits,
          searchQuery: query,
        ));
      } catch (e) {
        emit(HabitsError(e.toString()));
      }
    }
  }

  Future<void> loadAnalytics() async {
    final currentState = state;
    if (currentState is HabitsLoaded) {
      try {
        final summary = await AnalyticsService.generateSummary(currentState.habits);
        emit(currentState.copyWith(summary: summary));
      } catch (e) {
        // Don't emit error for analytics failure, just log it
        print('Failed to load analytics: $e');
      }
    }
  }

  List<Habit> _filterHabits(List<Habit> habits, String query) {
    if (query.isEmpty) return habits;
    return habits
        .where((habit) => 
            habit.title.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  List<Habit> _sortHabits(List<Habit> habits) {
    final sorted = List<Habit>.from(habits);
    sorted.sort((a, b) {
      // Push completed-today to bottom
      if (a.isCompletedToday != b.isCompletedToday) {
        return a.isCompletedToday ? 1 : -1;
      }
      // Newest updated first within same completion group
      return b.updatedAt.compareTo(a.updatedAt);
    });
    return sorted;
  }

  Future<List<Habit>> getHabitsCompletedToday(String userId) async {
    final currentState = state;
    if (currentState is HabitsLoaded) {
      try {
        return await _habitRepository.getHabitsCompletedToday(userId);
      } catch (e) {
        print('Failed to get habits completed today: $e');
        return [];
      }
    }
    return [];
  }

  Future<List<Habit>> getHabitsWithStreaks(String userId) async {
    final currentState = state;
    if (currentState is HabitsLoaded) {
      try {
        return await _habitRepository.getHabitsWithStreaks(userId);
      } catch (e) {
        print('Failed to get habits with streaks: $e');
        return [];
      }
    }
    return [];
  }

  Future<void> refreshHabits(String userId) async {
    try {
      final habits = await _habitRepository.getAllHabits(userId);
      final sortedHabits = _sortHabits(habits);
      final currentState = state;
      if (currentState is HabitsLoaded) {
        if (_areHabitsSame(currentState.habits, sortedHabits)) {
          return; // no changes, avoid rebuild flicker
        }
        final filtered = _filterHabits(sortedHabits, currentState.searchQuery);
        emit(currentState.copyWith(habits: sortedHabits, filteredHabits: filtered));
        await loadAnalytics();
      } else {
        emit(HabitsLoaded(habits: sortedHabits, filteredHabits: sortedHabits));
        await loadAnalytics();
      }
    } catch (e) {
      emit(HabitsError(e.toString()));
    }
  }

  bool _areHabitsSame(List<Habit> a, List<Habit> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    // Compare by id -> updatedAt map
    final Map<String, DateTime> mapA = { for (final h in a) h.id: h.updatedAt };
    for (final hb in b) {
      final t = mapA[hb.id];
      if (t == null) return false;
      if (!t.isAtSameMomentAs(hb.updatedAt)) return false;
    }
    return true;
  }
}
