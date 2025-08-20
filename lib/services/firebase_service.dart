import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models/habit.dart';
import '../data/models/note.dart';


class FirebaseService {
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Authentication methods
  Future<firebase_auth.UserCredential> signUp(String email, String password) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Create user document in Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      return userCredential;
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  Future<firebase_auth.UserCredential> signIn(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Stream<firebase_auth.User?> get authStateChanges => _auth.authStateChanges();

  firebase_auth.User? get currentUser => _auth.currentUser;

  // Firestore methods for habits
  Future<void> createHabit(String userId, Habit habit) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('habits')
          .doc(habit.id)
          .set(habit.toJson());
    } catch (e) {
      throw 'Failed to create habit: $e';
    }
  }

  Future<void> updateHabit(String userId, Habit habit) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('habits')
          .doc(habit.id)
          .update(habit.toJson());
    } catch (e) {
      throw 'Failed to update habit: $e';
    }
  }

  Future<void> deleteHabit(String userId, String habitId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('habits')
          .doc(habitId)
          .delete();
    } catch (e) {
      throw 'Failed to delete habit: $e';
    }
  }

  Stream<List<Habit>> getHabitsStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('habits')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Habit.fromJson(doc.data()))
            .toList());
  }

  Future<List<Habit>> getHabits(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('habits')
          .get();
      
      return snapshot.docs
          .map((doc) => Habit.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw 'Failed to fetch habits: $e';
    }
  }

  // Firestore methods for notes
  Future<void> createNote(String userId, Note note) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notes')
          .doc(note.id)
          .set(note.toJson());
    } catch (e) {
      throw 'Failed to create note: $e';
    }
  }

  Future<void> updateNote(String userId, Note note) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notes')
          .doc(note.id)
          .update(note.toJson());
    } catch (e) {
      throw 'Failed to update note: $e';
    }
  }

  Future<void> deleteNote(String userId, String noteId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notes')
          .doc(noteId)
          .delete();
    } catch (e) {
      throw 'Failed to delete note: $e';
    }
  }

  Stream<List<Note>> getNotesStream(String userId, String habitId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notes')
        .where('habitId', isEqualTo: habitId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Note.fromJson(doc.data()))
            .toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt))
        );
  }

  Future<List<Note>> getNotes(String userId, String habitId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notes')
          .where('habitId', isEqualTo: habitId)
          .get();
      
      final list = snapshot.docs
          .map((doc) => Note.fromJson(doc.data()))
          .toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    } catch (e) {
      throw 'Failed to fetch notes: $e';
    }
  }

  // Batch operations for sync
  Future<void> batchSyncHabits(String userId, List<Habit> habits) async {
    try {
      final batch = _firestore.batch();
      
      for (final habit in habits) {
        final docRef = _firestore
            .collection('users')
            .doc(userId)
            .collection('habits')
            .doc(habit.id);
        batch.set(docRef, habit.toJson());
      }
      
      await batch.commit();
    } catch (e) {
      throw 'Failed to batch sync habits: $e';
    }
  }

  Future<void> batchSyncNotes(String userId, List<Note> notes) async {
    try {
      final batch = _firestore.batch();
      
      for (final note in notes) {
        final docRef = _firestore
            .collection('users')
            .doc(userId)
            .collection('notes')
            .doc(note.id);
        batch.set(docRef, note.toJson());
      }
      
      await batch.commit();
    } catch (e) {
      throw 'Failed to batch sync notes: $e';
    }
  }

  String _handleAuthError(dynamic e) {
    if (e is firebase_auth.FirebaseAuthException) {
      switch (e.code) {
        case 'weak-password':
          return 'The password provided is too weak.';
        case 'email-already-in-use':
          return 'An account already exists for that email.';
        case 'user-not-found':
          return 'No user found for that email.';
        case 'wrong-password':
          return 'Wrong password provided.';
        case 'invalid-email':
          return 'The email address is invalid.';
        case 'user-disabled':
          return 'This user account has been disabled.';
        case 'too-many-requests':
          return 'Too many requests. Try again later.';
        case 'operation-not-allowed':
          return 'Email/password accounts are not enabled.';
        default:
          return 'Authentication failed: ${e.message}';
      }
    }
    return 'Authentication failed: $e';
  }
}
