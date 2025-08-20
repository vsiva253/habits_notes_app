// import 'package:flutter_test/flutter_test.dart';
// import 'package:bloc_test/bloc_test.dart';
// import 'package:mockito/mockito.dart';
// import 'package:mockito/annotations.dart';
// import 'package:habits_notes_app/logic/notes_cubit.dart';
// import 'package:habits_notes_app/data/repositories/note_repository.dart';
// import 'package:habits_notes_app/data/models/note.dart';

// import 'notes_cubit_test.mocks.dart';

// @GenerateMocks([NoteRepository])
// void main() {
//   group('NotesCubit Tests', () {
//     late NotesCubit notesCubit;
//     late MockNoteRepository mockRepository;
//     const String testUserId = 'test-user-id';
//     const String testHabitId = 'test-habit-id';

//     setUp(() {
//       mockRepository = MockNoteRepository();
//       notesCubit = NotesCubit();
//     });

//     tearDown(() {
//       notesCubit.close();
//     });

//     group('loadNotes', () {
//       final testNotes = [
//         Note(
//           id: '1',
//           habitId: testHabitId,
//           text: 'First note',
//           createdAt: DateTime(2024, 1, 1),
//         ),
//         Note(
//           id: '2',
//           habitId: testHabitId,
//           text: 'Second note',
//           createdAt: DateTime(2024, 1, 2),
//         ),
//       ];

//       blocTest<NotesCubit, NotesState>(
//         'emits [NotesLoading, NotesLoaded] when loadNotes succeeds',
//         build: () {
//           when(mockRepository.getNotesForHabit(testUserId, testHabitId))
//               .thenAnswer((_) async => testNotes);
//           return notesCubit;
//         },
//         act: (cubit) => cubit.loadNotes(testHabitId, testUserId),
//         expect: () => [
//           NotesLoading(),
//           isA<NotesLoaded>()
//               .having((state) => state.notes.length, 'notes length', 2)
//               .having((state) => state.filteredNotes.length, 'filtered notes length', 2)
//               .having((state) => state.habitId, 'habit id', testHabitId),
//         ],
//       );

//       blocTest<NotesCubit, NotesState>(
//         'emits [NotesLoading, NotesError] when loadNotes fails',
//         build: () {
//           when(mockRepository.getNotesForHabit(testUserId, testHabitId))
//               .thenThrow(Exception('Failed to load notes'));
//           return notesCubit;
//         },
//         act: (cubit) => cubit.loadNotes(testHabitId, testUserId),
//         expect: () => [
//           NotesLoading(),
//           isA<NotesError>()
//               .having((state) => state.message, 'error message', contains('Failed to load notes')),
//         ],
//       );
//     });

//     group('createNote', () {
//       const noteText = 'New note text';
//       final newNote = Note(
//         id: 'new-id',
//         habitId: testHabitId,
//         text: noteText,
//         createdAt: DateTime.now(),
//       );

//       blocTest<NotesCubit, NotesState>(
//         'adds new note to existing notes when createNote succeeds',
//         build: () {
//           when(mockRepository.createNote(
//             text: noteText,
//             habitId: testHabitId,
//             userId: testUserId,
//           )).thenAnswer((_) async => newNote);
//           return notesCubit;
//         },
//         seed: () => const NotesLoaded(
//           notes: [],
//           filteredNotes: [],
//           habitId: testHabitId,
//         ),
//         act: (cubit) => cubit.createNote(
//           text: noteText,
//           habitId: testHabitId,
//           userId: testUserId,
//         ),
//         expect: () => [
//           isA<NotesLoaded>()
//               .having((state) => state.notes.length, 'notes length', 1)
//               .having((state) => state.notes.first.text, 'first note text', noteText),
//         ],
//       );

//       blocTest<NotesCubit, NotesState>(
//         'emits NotesError when createNote fails',
//         build: () {
//           when(mockRepository.createNote(
//             text: noteText,
//             habitId: testHabitId,
//             userId: testUserId,
//           )).thenThrow(Exception('Failed to create note'));
//           return notesCubit;
//         },
//         seed: () => const NotesLoaded(
//           notes: [],
//           filteredNotes: [],
//           habitId: testHabitId,
//         ),
//         act: (cubit) => cubit.createNote(
//           text: noteText,
//           habitId: testHabitId,
//           userId: testUserId,
//         ),
//         expect: () => [
//           isA<NotesError>()
//               .having((state) => state.message, 'error message', contains('Failed to create note')),
//         ],
//       );
//     });

//     group('updateNote', () {
//       final originalNote = Note(
//         id: 'update-id',
//         habitId: testHabitId,
//         text: 'Original text',
//         createdAt: DateTime(2024, 1, 1),
//       );

//       final updatedNote = originalNote.copyWith(text: 'Updated text');

//       blocTest<NotesCubit, NotesState>(
//         'updates note in the list when updateNote succeeds',
//         build: () {
//           when(mockRepository.updateNote(updatedNote, testUserId))
//               .thenAnswer((_) async {});
//           return notesCubit;
//         },
//         seed: () => NotesLoaded(
//           notes: [originalNote],
//           filteredNotes: [originalNote],
//           habitId: testHabitId,
//         ),
//         act: (cubit) => cubit.updateNote(updatedNote, testUserId),
//         expect: () => [
//           isA<NotesLoaded>()
//               .having((state) => state.notes.first.text, 'updated text', 'Updated text'),
//         ],
//       );
//     });

//     group('deleteNote', () {
//       final noteToDelete = Note(
//         id: 'delete-id',
//         habitId: testHabitId,
//         text: 'Delete me',
//         createdAt: DateTime.now(),
//       );

//       blocTest<NotesCubit, NotesState>(
//         'removes note from list when deleteNote succeeds',
//         build: () {
//           when(mockRepository.deleteNote('delete-id', testUserId))
//               .thenAnswer((_) async {});
//           return notesCubit;
//         },
//         seed: () => NotesLoaded(
//           notes: [noteToDelete],
//           filteredNotes: [noteToDelete],
//           habitId: testHabitId,
//         ),
//         act: (cubit) => cubit.deleteNote('delete-id', testUserId),
//         expect: () => [
//           isA<NotesLoaded>()
//               .having((state) => state.notes, 'notes', isEmpty)
//               .having((state) => state.filteredNotes, 'filtered notes', isEmpty),
//         ],
//       );
//     });

//     group('searchNotes', () {
//       final notes = [
//         Note(
//           id: '1',
//           habitId: testHabitId,
//           text: 'Exercise routine notes',
//           createdAt: DateTime.now(),
//         ),
//         Note(
//           id: '2',
//           habitId: testHabitId,
//           text: 'Reading progress update',
//           createdAt: DateTime.now(),
//         ),
//       ];

//       blocTest<NotesCubit, NotesState>(
//         'filters notes based on search query',
//         build: () {
//           when(mockRepository.searchNotes(testUserId, 'exercise', habitId: testHabitId))
//               .thenAnswer((_) async => [notes[0]]);
//           return notesCubit;
//         },
//         seed: () => NotesLoaded(
//           notes: notes,
//           filteredNotes: notes,
//           habitId: testHabitId,
//         ),
//         act: (cubit) => cubit.searchNotes('exercise', testUserId, habitId: testHabitId),
//         expect: () => [
//           isA<NotesLoaded>()
//               .having((state) => state.filteredNotes.length, 'filtered count', 1)
//               .having((state) => state.filteredNotes.first.text, 'filtered text', 'Exercise routine notes')
//               .having((state) => state.searchQuery, 'search query', 'exercise'),
//         ],
//       );

//       blocTest<NotesCubit, NotesState>(
//         'shows all notes when search query is empty',
//         build: () {
//           when(mockRepository.searchNotes(testUserId, '', habitId: testHabitId))
//               .thenAnswer((_) async => notes);
//           return notesCubit;
//         },
//         seed: () => NotesLoaded(
//           notes: notes,
//           filteredNotes: [notes[0]], // Previously filtered
//           habitId: testHabitId,
//           searchQuery: 'exercise',
//         ),
//         act: (cubit) => cubit.searchNotes('', testUserId, habitId: testHabitId),
//         expect: () => [
//           isA<NotesLoaded>()
//               .having((state) => state.filteredNotes.length, 'filtered count', 2)
//               .having((state) => state.searchQuery, 'search query', ''),
//         ],
//       );
//     });

//     group('state management', () {
//       test('initial state is NotesInitial', () {
//         expect(notesCubit.state, isA<NotesInitial>());
//       });

//       test('NotesLoaded copyWith works correctly', () {
//         const originalState = NotesLoaded(
//           notes: [],
//           filteredNotes: [],
//           habitId: testHabitId,
//           searchQuery: 'test',
//         );

//         final newNotes = [
//           Note(
//             id: '1',
//             habitId: testHabitId,
//             text: 'New note',
//             createdAt: DateTime.now(),
//           ),
//         ];

//         final newState = originalState.copyWith(notes: newNotes);

//         expect(newState.notes, newNotes);
//         expect(newState.filteredNotes, originalState.filteredNotes);
//         expect(newState.habitId, originalState.habitId);
//         expect(newState.searchQuery, originalState.searchQuery);
//       });
//     });

//     group('utility methods', () {
//       test('_filterNotes filters correctly', () {
//         final notes = [
//           Note(
//             id: '1',
//             habitId: testHabitId,
//             text: 'Exercise routine',
//             createdAt: DateTime.now(),
//           ),
//           Note(
//             id: '2',
//             habitId: testHabitId,
//             text: 'Reading progress',
//             createdAt: DateTime.now(),
//           ),
//         ];

//         // Access private method through reflection or test it indirectly
//         // For now, we'll test the behavior through searchNotes
//       });

//       blocTest<NotesCubit, NotesState>(
//         'refreshNotes updates state when notes change',
//         build: () {
//           final updatedNotes = [
//             Note(
//               id: '1',
//               habitId: testHabitId,
//               text: 'Updated note',
//               createdAt: DateTime.now(),
//             ),
//           ];
//           when(mockRepository.getNotesForHabit(testUserId, testHabitId))
//               .thenAnswer((_) async => updatedNotes);
//           return notesCubit;
//         },
//         seed: () => const NotesLoaded(
//           notes: [],
//           filteredNotes: [],
//           habitId: testHabitId,
//         ),
//         act: (cubit) => cubit.refreshNotes(testUserId, testHabitId),
//         expect: () => [
//           isA<NotesLoaded>()
//               .having((state) => state.notes.length, 'notes length', 1)
//               .having((state) => state.notes.first.text, 'note text', 'Updated note'),
//         ],
//       );
//     });
//   });
// }
