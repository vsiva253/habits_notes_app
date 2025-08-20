import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../services/sync_service.dart';

// Events
abstract class SyncEvent extends Equatable {
  const SyncEvent();

  @override
  List<Object?> get props => [];
}

class SyncData extends SyncEvent {
  final String userId;

  const SyncData(this.userId);

  @override
  List<Object?> get props => [userId];
}

class SyncStatusChanged extends SyncEvent {
  final SyncStatus status;

  const SyncStatusChanged(this.status);

  @override
  List<Object?> get props => [status];
}

// States
abstract class SyncState extends Equatable {
  const SyncState();

  @override
  List<Object?> get props => [];
}

class SyncInitial extends SyncState {}

class SyncIdle extends SyncState {}

class SyncInProgress extends SyncState {}

class SyncCompleted extends SyncState {
  final DateTime completedAt;

   SyncCompleted([DateTime? at]) : completedAt = at ?? DateTime.now();

  @override
  List<Object?> get props => [completedAt];
}

class SyncError extends SyncState {
  final String message;

  const SyncError(this.message);

  @override
  List<Object?> get props => [message];
}

// Cubit
class SyncCubit extends Cubit<SyncState> {
  final SyncService _syncService = SyncService();

  SyncCubit() : super(SyncInitial()) {
    _listenToSyncStatus();
  }

  void _listenToSyncStatus() {
    _syncService.syncStatusStream.listen((status) {
      switch (status) {
        case SyncStatus.idle:
          emit(SyncIdle());
          break;
        case SyncStatus.syncing:
          emit(SyncInProgress());
          break;
        case SyncStatus.completed:
          emit(SyncCompleted());
          break;
        case SyncStatus.error:
          emit(const SyncError('Sync failed'));
          break;
      }
    });
  }

  Future<void> syncData(String userId) async {
    try {
      await _syncService.syncData(userId);
    } catch (e) {
      emit(SyncError(e.toString()));
    }
  }

  Future<void> fetchAllRemote(String userId) async {
    try {
      await _syncService.fetchAllRemote(userId);
    } catch (e) {
      emit(SyncError(e.toString()));
    }
  }

  bool get isSyncing => state is SyncInProgress;
  bool get hasError => state is SyncError;
  String? get errorMessage {
    final currentState = state;
    if (currentState is SyncError) {
      return currentState.message;
    }
    return null;
  }

  @override
  Future<void> close() async {
    await _syncService.dispose();
    super.close();
  }
}
