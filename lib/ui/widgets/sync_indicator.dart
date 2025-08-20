import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../logic/sync_cubit.dart';
import '../../logic/auth_cubit.dart';
import '../../logic/habits_cubit.dart';

class SyncIndicator extends StatelessWidget {
  final SyncState syncState;

  const SyncIndicator({
    super.key,
    required this.syncState,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Tooltip(
        message: _tooltipText(context),
        child: GestureDetector(
          onTap: () {
            final messenger = ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar();

            final authCubit = context.read<AuthCubit>();
            final user = authCubit.getCurrentUser();
            if (user == null) {
              messenger.showSnackBar(
                const SnackBar(content: Text('Please sign in to sync')),
              );
              return;
            }

            final syncCubit = context.read<SyncCubit>();
            if (syncCubit.isSyncing) {
              messenger.showSnackBar(
                const SnackBar(content: Text('Already syncing')),
              );
              return;
            }

            // If local data is empty, fetch from cloud first for a better UX
            final habitsState = context.read<HabitsCubit>().state;
            if (habitsState is HabitsLoaded && habitsState.habits.isEmpty) {
              messenger.showSnackBar(
                const SnackBar(content: Text('Fetching from cloud…')),
              );
              syncCubit.fetchAllRemote(user.id);
            } else {
              messenger.showSnackBar(
                const SnackBar(content: Text('Sync started')),
              );
              syncCubit.syncData(user.id);
            }
          },
          child: _buildIndicator(context),
        ),
      ),
    );
  }

  Widget _buildIndicator(BuildContext context) {
    switch (syncState.runtimeType) {
      case SyncIdle:
        return Container(
          key: const ValueKey('idle'),
          width: 8,
          height: 8,
          margin: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.grey,
            shape: BoxShape.circle,
          ),
        );
      
      case SyncInProgress:
        return Container(
          key: const ValueKey('syncing'),
          width: 8,
          height: 8,
          margin: const EdgeInsets.all(16),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(seconds: 1),
            builder: (context, value, child) {
              return Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                      blurRadius: 6 * value,
                      spreadRadius: 1 * value,
                    ),
                  ],
                ),
                child: Center(
                  child: SizedBox(
                    width: 4,
                    height: 4,
                    child: CircularProgressIndicator(
                      value: value,
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ),
              );
            },
            onEnd: () {
              // Restart animation
              (context as Element).markNeedsBuild();
            },
          ),
        );
      
      case SyncCompleted:
        return Container(
          key: const ValueKey('completed'),
          width: 8,
          height: 8,
          margin: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.green,
            shape: BoxShape.circle,
          ),
        );
      
      case SyncError:
        return Container(
          key: const ValueKey('error'),
          width: 8,
          height: 8,
          margin: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.red,
            shape: BoxShape.circle,
          ),
        );
      
      default:
        return const SizedBox.shrink();
    }
  }

  String _tooltipText(BuildContext context) {
    if (syncState is SyncInProgress) return 'Syncing...';
    if (syncState is SyncError) return 'Sync failed. Tap to retry';
    if (syncState is SyncCompleted) {
      final at = (syncState as SyncCompleted).completedAt;
      return 'Last sync: ${_timeAgo(at)}';
    }
    return 'Tap to sync';
  }

  String _timeAgo(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
