// import 'package:flutter_test/flutter_test.dart';
// import 'package:bloc_test/bloc_test.dart';
// import 'package:mockito/mockito.dart';
// import 'package:mockito/annotations.dart';
// import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
// import 'package:habits_notes_app/logic/auth_cubit.dart';
// import 'package:habits_notes_app/services/firebase_service.dart';
// import 'package:habits_notes_app/data/models/user.dart' as app_user;

// import 'auth_cubit_test.mocks.dart';

// @GenerateMocks([FirebaseService, firebase_auth.User, firebase_auth.UserCredential])
// void main() {
//   group('AuthCubit Tests', () {
//     late AuthCubit authCubit;
//     late MockFirebaseService mockFirebaseService;
//     late MockUser mockFirebaseUser;
//     late MockUserCredential mockUserCredential;

//     setUp(() {
//       mockFirebaseService = MockFirebaseService();
//       mockFirebaseUser = MockUser();
//       mockUserCredential = MockUserCredential();
//       authCubit = AuthCubit();
//     });

//     tearDown(() {
//       authCubit.close();
//     });

//     group('signUp', () {
//       const email = 'test@example.com';
//       const password = 'password123';

//       blocTest<AuthCubit, AuthState>(
//         'emits [AuthLoading] when signUp is called',
//         build: () {
//           when(mockFirebaseService.signUp(email, password))
//               .thenAnswer((_) async => mockUserCredential);
//           when(mockUserCredential.user).thenReturn(mockFirebaseUser);
//           when(mockFirebaseUser.uid).thenReturn('test-uid');
//           when(mockFirebaseUser.email).thenReturn(email);
//           return authCubit;
//         },
//         act: (cubit) => cubit.signUp(email, password),
//         expect: () => [AuthLoading()],
//       );

//       blocTest<AuthCubit, AuthState>(
//         'emits [AuthLoading, AuthError] when signUp fails',
//         build: () {
//           when(mockFirebaseService.signUp(email, password))
//               .thenThrow(Exception('Sign up failed'));
//           return authCubit;
//         },
//         act: (cubit) => cubit.signUp(email, password),
//         expect: () => [
//           AuthLoading(),
//           isA<AuthError>()
//               .having((state) => state.message, 'error message', contains('Sign up failed')),
//         ],
//       );

//       blocTest<AuthCubit, AuthState>(
//         'emits [AuthLoading, AuthError] when user is null after signUp',
//         build: () {
//           when(mockFirebaseService.signUp(email, password))
//               .thenAnswer((_) async => mockUserCredential);
//           when(mockUserCredential.user).thenReturn(null);
//           return authCubit;
//         },
//         act: (cubit) => cubit.signUp(email, password),
//         expect: () => [
//           AuthLoading(),
//           const AuthError('Sign up failed.'),
//         ],
//       );
//     });

//     group('signIn', () {
//       const email = 'test@example.com';
//       const password = 'password123';

//       blocTest<AuthCubit, AuthState>(
//         'emits [AuthLoading] when signIn is called',
//         build: () {
//           when(mockFirebaseService.signIn(email, password))
//               .thenAnswer((_) async => mockUserCredential);
//           when(mockUserCredential.user).thenReturn(mockFirebaseUser);
//           when(mockFirebaseUser.uid).thenReturn('test-uid');
//           when(mockFirebaseUser.email).thenReturn(email);
//           return authCubit;
//         },
//         act: (cubit) => cubit.signIn(email, password),
//         expect: () => [AuthLoading()],
//       );

//       blocTest<AuthCubit, AuthState>(
//         'emits [AuthLoading, AuthError] when signIn fails',
//         build: () {
//           when(mockFirebaseService.signIn(email, password))
//               .thenThrow(Exception('Sign in failed'));
//           return authCubit;
//         },
//         act: (cubit) => cubit.signIn(email, password),
//         expect: () => [
//           AuthLoading(),
//           isA<AuthError>()
//               .having((state) => state.message, 'error message', contains('Sign in failed')),
//         ],
//       );

//       blocTest<AuthCubit, AuthState>(
//         'emits [AuthLoading, AuthError] when user is null after signIn',
//         build: () {
//           when(mockFirebaseService.signIn(email, password))
//               .thenAnswer((_) async => mockUserCredential);
//           when(mockUserCredential.user).thenReturn(null);
//           return authCubit;
//         },
//         act: (cubit) => cubit.signIn(email, password),
//         expect: () => [
//           AuthLoading(),
//           const AuthError('Sign in failed.'),
//         ],
//       );
//     });

//     group('signOut', () {
//       blocTest<AuthCubit, AuthState>(
//         'calls firebase signOut when signOut is called',
//         build: () {
//           when(mockFirebaseService.signOut()).thenAnswer((_) async {});
//           return authCubit;
//         },
//         act: (cubit) => cubit.signOut(),
//         verify: (cubit) {
//           verify(mockFirebaseService.signOut()).called(1);
//         },
//       );

//       blocTest<AuthCubit, AuthState>(
//         'emits AuthError when signOut fails',
//         build: () {
//           when(mockFirebaseService.signOut())
//               .thenThrow(Exception('Sign out failed'));
//           return authCubit;
//         },
//         act: (cubit) => cubit.signOut(),
//         expect: () => [
//           isA<AuthError>()
//               .having((state) => state.message, 'error message', contains('Sign out failed')),
//         ],
//       );
//     });

//     group('state management', () {
//       test('initial state is AuthInitial', () {
//         expect(authCubit.state, isA<AuthInitial>());
//       });

//       test('isAuthenticated returns true when state is Authenticated', () {
//         final user = app_user.User(
//           id: 'test-id',
//           email: 'test@example.com',
//           createdAt: DateTime.now(),
//         );
        
//         // This would require emitting the state in a test
//         // authCubit.emit(Authenticated(user));
//         // expect(authCubit.isAuthenticated, true);
//       });

//       test('isAuthenticated returns false when state is not Authenticated', () {
//         expect(authCubit.isAuthenticated, false);
//       });
//     });

//     group('Authenticated state', () {
//       test('should be equal for same user', () {
//         final user1 = app_user.User(
//           id: 'same-id',
//           email: 'same@example.com',
//           createdAt: DateTime(2024, 1, 1),
//         );

//         final user2 = app_user.User(
//           id: 'same-id',
//           email: 'same@example.com',
//           createdAt: DateTime(2024, 1, 1),
//         );

//         final state1 = Authenticated(user1);
//         final state2 = Authenticated(user2);

//         expect(state1, equals(state2));
//         expect(state1.hashCode, equals(state2.hashCode));
//       });

//       test('should not be equal for different users', () {
//         final user1 = app_user.User(
//           id: 'id1',
//           email: 'user1@example.com',
//           createdAt: DateTime.now(),
//         );

//         final user2 = app_user.User(
//           id: 'id2',
//           email: 'user2@example.com',
//           createdAt: DateTime.now(),
//         );

//         final state1 = Authenticated(user1);
//         final state2 = Authenticated(user2);

//         expect(state1, isNot(equals(state2)));
//       });
//     });

//     group('AuthError state', () {
//       test('should be equal for same error message', () {
//         const error1 = AuthError('Same error');
//         const error2 = AuthError('Same error');

//         expect(error1, equals(error2));
//         expect(error1.hashCode, equals(error2.hashCode));
//       });

//       test('should not be equal for different error messages', () {
//         const error1 = AuthError('Error 1');
//         const error2 = AuthError('Error 2');

//         expect(error1, isNot(equals(error2)));
//       });
//     });
//   });
// }
