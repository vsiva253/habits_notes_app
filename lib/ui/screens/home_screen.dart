import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../logic/auth_cubit.dart';
import '../../logic/habits_cubit.dart';
import '../../logic/sync_cubit.dart';
import '../../data/models/habit.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../widgets/habit_card.dart';
import '../widgets/analytics_card.dart';
import '../widgets/sync_indicator.dart';
import 'habit_detail_screen.dart';
import 'create_habit_screen.dart';
import '../widgets/skeletons.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _loadData() async {
    final authCubit = context.read<AuthCubit>();
    final habitsCubit = context.read<HabitsCubit>();
    final syncCubit = context.read<SyncCubit>();
    
    if (authCubit.isAuthenticated) {
      final user = authCubit.getCurrentUser();
      if (user != null) {
        // First load local
        await habitsCubit.loadHabits(user.id);
        // If nothing local, fetch remote directly for a faster first-time load
        final currentState = habitsCubit.state;
        if (currentState is HabitsLoaded && currentState.habits.isEmpty) {
          await syncCubit.fetchAllRemote(user.id);
          await habitsCubit.loadHabits(user.id);
        } else {
          // Otherwise run full sync in background
          syncCubit.syncData(user.id);
        }
      }
    }
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      final habitsCubit = context.read<HabitsCubit>();
      final user = context.read<AuthCubit>().getCurrentUser();
      if (user != null) {
        habitsCubit.searchHabits(query, user.id);
      }
    });
  }

  void _createHabit() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateHabitScreen(),
      ),
    );
  }

  void _openHabitDetail(Habit habit) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HabitDetailScreen(habit: habit),
      ),
    ).then((_) {
      final user = context.read<AuthCubit>().getCurrentUser();
      if (user != null) {
        context.read<HabitsCubit>().loadHabits(user.id);
      }
    });
  }

  // _buildDeleteBackground removed; using Slidable action instead

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: Colors.white,
        title: const Text('Habits & Notes'),
        actions: [
          BlocBuilder<SyncCubit, SyncState>(
            builder: (context, state) {
              final theme = Theme.of(context);
              String? label;
              Color color = theme.colorScheme.onSurfaceVariant;
              if (state is SyncInProgress) {
                label = 'Syncing…';
                color = theme.colorScheme.primary;
              } else if (state is SyncCompleted) {
                label = 'Synced';
              } else if (state is SyncError) {
                label = 'Sync failed';
                color = theme.colorScheme.error;
              } else {
                label = null; // hide idle
              }
              return Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SyncIndicator(syncState: state),
                    if (label != null) ...[
                      const SizedBox(width: 6),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ]
                  ],
                ),
              );
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'signout') {
                context.read<AuthCubit>().signOut();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'signout',
                child: Row(
                  children: const [
                    Icon(Icons.logout, color: Color(0xFFD9A441)),
                    SizedBox(width: 8),
                    Text('Sign Out'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: BlocListener<SyncCubit, SyncState>(
          listener: (context, state) {
            if (state is SyncCompleted) {
              final user = context.read<AuthCubit>().getCurrentUser();
              if (user != null) {
                context.read<HabitsCubit>().refreshHabits(user.id);
              }
            }
          },
          child: CustomScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            // Profile Header
            SliverToBoxAdapter(
              child: BlocBuilder<AuthCubit, AuthState>(
                builder: (context, state) {
                  if (state is Authenticated) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      color: Theme.of(context).colorScheme.primaryContainer,
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            child: Text(
                              state.user.email[0].toUpperCase(),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  state.user.email,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Member since ${_formatDate(state.user.createdAt)}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),

            // Search Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search habits...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: (_searchController.text.isNotEmpty)
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('');
                              setState(() {});
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                  ),
                  onChanged: _onSearchChanged,
                  onTap: () => setState(() {}),
                ),
              ),
            ),

            // Analytics Card
            SliverToBoxAdapter(
              child: BlocBuilder<HabitsCubit, HabitsState>(
                builder: (context, state) {
                  final syncState = context.watch<SyncCubit>().state;
                  final isSyncing = syncState is SyncInProgress;
                  final isLoading = state is HabitsLoading;
                  final isFirstEmpty = state is HabitsLoaded && state.habits.isEmpty;
                  
                  if ((isLoading) || (isSyncing && isFirstEmpty)) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: AnalyticsSkeleton(),
                    );
                  }
                  
                  if (state is HabitsLoaded && state.summary != null && state.searchQuery.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: AnalyticsCard(summary: state.summary!),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),

            SliverToBoxAdapter(
              child: BlocBuilder<HabitsCubit, HabitsState>(
                builder: (context, state) {
                  final showSpacer = state is HabitsLoaded
                      ? state.searchQuery.isEmpty
                      : state is HabitsLoading;
                  return showSpacer
                      ? const SizedBox(height: 16)
                      : const SizedBox.shrink();
                },
              ),
            ),

            // Habits List as a single sliver list
            BlocBuilder<HabitsCubit, HabitsState>(
              builder: (context, state) {
                final syncState = context.watch<SyncCubit>().state;
                final isSyncing = syncState is SyncInProgress;
                final isLoading = state is HabitsLoading;
                final isFirstEmpty = state is HabitsLoaded && state.habits.isEmpty;
                
                if (isLoading || (isSyncing && isFirstEmpty)) {
                  return SliverList.builder(
                    itemCount: 6,
                    itemBuilder: (context, index) => const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: HabitCardSkeleton(),
                    ),
                  );
                } else if (state is HabitsLoaded) {
                  if (state.filteredHabits.isEmpty) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_task,
                              size: 64,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              state.searchQuery.isEmpty
                                  ? 'No habits yet'
                                  : 'No habits found',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              state.searchQuery.isEmpty
                                  ? 'Create your first habit to get started'
                                  : 'Try adjusting your search',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return SliverList.builder(
                    itemCount: state.filteredHabits.length,
                    itemBuilder: (context, index) {
                      final habit = state.filteredHabits[index];
                      return TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0, end: 1),
                        duration: Duration(milliseconds: 250 + (index * 30)),
                        curve: Curves.easeOut,
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(0, (1 - value) * 12),
                              child: child,
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16).copyWith(bottom: 12),
                          child: _SlidableHabit(
                            habit: habit,
                            onOpenDetail: () => _openHabitDetail(habit),
                          ),
                        ),
                      );
                    },
                  );
                } else if (state is HabitsError) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error loading habits',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            state.message,
                            style: Theme.of(context).textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadData,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return const SliverToBoxAdapter(child: SizedBox.shrink());
              },
            ),
          ],
        ),
        ),
      ),
      
      floatingActionButton: FloatingActionButton(
        onPressed: _createHabit,
        child: const Icon(Icons.add),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    
    if (difference == 0) return 'today';
    if (difference == 1) return 'yesterday';
    if (difference < 7) return '$difference days ago';
    if (difference < 30) return '${(difference / 7).round()} weeks ago';
    if (difference < 365) return '${(difference / 30).round()} months ago';
    return '${(difference / 365).round()} years ago';
  }
}

class _SlidableHabit extends StatelessWidget {
  final Habit habit;
  final VoidCallback onOpenDetail;

  const _SlidableHabit({
    required this.habit,
    required this.onOpenDetail,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Slidable(
        key: ValueKey('slidable-habit-${habit.id}'),
        closeOnScroll: true,
        endActionPane: ActionPane(
          motion: const StretchMotion(),
          extentRatio: 0.29,
          children: [
            CustomSlidableAction(
              autoClose: true,
              onPressed: (_) {
                final user = context.read<AuthCubit>().getCurrentUser();
                if (user != null) {
                  HapticFeedback.mediumImpact();
                  context.read<HabitsCubit>().deleteHabit(habit.id, user.id);
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      const SnackBar(content: Text('Habit deleted')),
                    );
                }
              },
              child: Container(
                height: double.infinity,
                margin: const EdgeInsets.symmetric(vertical: 2),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.error,
                      Theme.of(context).colorScheme.error.withOpacity(0.85),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.error.withOpacity(0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.delete_forever_rounded,
                      color: Theme.of(context).colorScheme.onError,
                      size: 24,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        child: HabitCard(
          habit: habit,
          onTap: onOpenDetail,
          onToggleCompletion: () {
            final user = context.read<AuthCubit>().getCurrentUser();
            if (user != null) {
              HapticFeedback.selectionClick();
              final oldCompleted = habit.isCompletedToday;
              context.read<HabitsCubit>().toggleHabitCompletion(habit, user.id);
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text(oldCompleted ? 'Marked incomplete' : 'Marked complete'),
                    action: SnackBarAction(
                      label: 'Undo',
                      onPressed: () {
                        context.read<HabitsCubit>().toggleHabitCompletion(habit, user.id);
                      },
                    ),
                  ),
                );
            }
          },
        ),
      ),
    );
  }
}
