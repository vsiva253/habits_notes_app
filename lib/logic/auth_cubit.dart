import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../data/models/user.dart' as app_user;
import '../services/firebase_service.dart';
import '../services/hive_service.dart';

// Events
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class SignUpRequested extends AuthEvent {
  final String email;
  final String password;

  const SignUpRequested({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];
}

class SignInRequested extends AuthEvent {
  final String email;
  final String password;

  const SignInRequested({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];
}

class SignOutRequested extends AuthEvent {}

class AuthCheckRequested extends AuthEvent {}

// States
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class Authenticated extends AuthState {
  final app_user.User user;

  const Authenticated(this.user);

  @override
  List<Object?> get props => [user];
}

class Unauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}

// Cubit
class AuthCubit extends Cubit<AuthState> {
  final FirebaseService _firebaseService = FirebaseService();

  AuthCubit() : super(AuthInitial()) {
    _log('AuthCubit initialized');
    _checkAuthState();
  }

  void _checkAuthState() {
    _log('Subscribing to authStateChanges stream');
    _firebaseService.authStateChanges.listen((firebase_auth.User? firebaseUser) async {
      _log('authStateChanges event: user=${firebaseUser?.uid ?? 'null'} email=${firebaseUser?.email ?? 'null'}');
      if (firebaseUser != null) {
        final user = app_user.User(
          id: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          createdAt: firebaseUser.metadata.creationTime ?? DateTime.now(),
        );
        
        // Save user to local storage
        await HiveService.saveUser(user);
        _log('Saved user to Hive: ${user.id}. Emitting Authenticated');
        emit(Authenticated(user));
      } else {
        // Get current user ID before clearing to clear their specific data
        final currentUser = HiveService.getCurrentUser();
        if (currentUser != null) {
          _log('Clearing all data for user: ${currentUser.id}');
          await HiveService.clearAllUserData(currentUser.id);
        } else {
          await HiveService.clearUser();
        }
        _log('No firebase user. Cleared all user data. Emitting Unauthenticated');
        emit(Unauthenticated());
      }
    });
  }

  Future<void> signUp(String email, String password) async {
    _log('signUp() called for email=$email');
    emit(AuthLoading());
    
    try {
      final userCredential = await _firebaseService.signUp(email, password);
      // Rely on authStateChanges stream to emit Authenticated
      if (userCredential.user == null) {
        _log('signUp() failed: user is null');
        emit(const AuthError('Sign up failed.'));
      }
    } catch (e) {
      _log('signUp() error: $e');
      emit(AuthError(e.toString()));
    }
  }

  Future<void> signIn(String email, String password) async {
    _log('signIn() called for email=$email');
    emit(AuthLoading());
    
    try {
      final userCredential = await _firebaseService.signIn(email, password);
      // Rely on authStateChanges stream to emit Authenticated
      if (userCredential.user == null) {
        _log('signIn() failed: user is null');
        emit(const AuthError('Sign in failed.'));
      }
    } catch (e) {
      _log('signIn() error: $e');
      emit(AuthError(e.toString()));
    }
  }

  Future<void> signOut() async {
    try {
      _log('signOut() called');
      
      // Get current user ID before signing out
      final currentUser = HiveService.getCurrentUser();
      if (currentUser != null) {
        _log('Clearing all data for user: ${currentUser.id} before sign out');
        await HiveService.clearAllUserData(currentUser.id);
      }
      
      await _firebaseService.signOut();
      // Auth state will be updated via the stream listener
    } catch (e) {
      _log('signOut() error: $e');
      emit(AuthError(e.toString()));
    }
  }

  app_user.User? getCurrentUser() {
    return HiveService.getCurrentUser();
  }

  bool get isAuthenticated => state is Authenticated;

  void _log(String message) {
    final now = DateTime.now().toIso8601String();
    debugPrint('[AuthCubit][$now] $message');
  }
}
