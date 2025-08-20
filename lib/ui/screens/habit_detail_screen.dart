import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../logic/auth_cubit.dart';
import '../../logic/habits_cubit.dart';
import '../../logic/notes_cubit.dart';
import '../../logic/sync_cubit.dart';
import '../../data/models/habit.dart';
import '../../data/models/note.dart';
import '../widgets/note_card.dart';
import 'create_note_screen.dart';
import 'create_habit_screen.dart';

class HabitDetailScreen extends StatefulWidget {
  final Habit habit;

  const HabitDetailScreen({
    super.key,
    required this.habit,
  });

  @override
  State<HabitDetailScreen> createState() => _HabitDetailScreenState();
}

class _HabitDetailScreenState extends State<HabitDetailScreen> {
  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  void _loadNotes() {
    final notesCubit = context.read<NotesCubit>();
    final authCubit = context.read<AuthCubit>();
    final user = authCubit.getCurrentUser();
    if (user != null) {
      notesCubit.loadNotes(widget.habit.id, user.id);
    }
  }

  void _toggleCompletion() {
    final authCubit = context.read<AuthCubit>();
    final habitsCubit = context.read<HabitsCubit>();
    final habitsState = habitsCubit.state;
    Habit? currentHabit;
    if (habitsState is HabitsLoaded) {
      try {
        currentHabit = habitsState.habits.firstWhere((h) => h.id == widget.habit.id);
      } catch (_) {
        currentHabit = widget.habit;
      }
    } else {
      currentHabit = widget.habit;
    }
    
    if (authCubit.isAuthenticated) {
      final user = authCubit.getCurrentUser();
      if (user != null) {
        habitsCubit.toggleHabitCompletion(currentHabit, user.id);
      }
    }
  }

  void _createNote() {
    _openAddNoteSheet();
  }

  void _editNote(Note note) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateNoteScreen(
          habitId: widget.habit.id,
          note: note,
        ),
      ),
    );
  }

  Future<void> _openAddNoteSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _AddNoteSheet(habitId: widget.habit.id);
      },
    );
  }

  Widget _buildDeleteBackground(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            scheme.error.withOpacity(0.7),
            scheme.error,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Delete',
            style: TextStyle(
              color: scheme.onError,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.delete_outline,
            color: scheme.onError,
          ),
        ],
      ),
    );
  }

  void _deleteNote(Note note) {
    final authCubit = context.read<AuthCubit>();
    final notesCubit = context.read<NotesCubit>();
    
    if (authCubit.isAuthenticated) {
      final user = authCubit.getCurrentUser();
      if (user != null) {
        notesCubit.deleteNote(note.id, user.id);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HabitsCubit, HabitsState>(
      builder: (context, habitsState) {
        Habit habit = widget.habit;
        if (habitsState is HabitsLoaded) {
          final maybeHabit = habitsState.habits.where((h) => h.id == widget.habit.id);
          if (maybeHabit.isNotEmpty) {
            habit = maybeHabit.first;
          }
        }

        return BlocListener<SyncCubit, SyncState>(
          listener: (context, state) {
            if (state is SyncCompleted) {
              final user = context.read<AuthCubit>().getCurrentUser();
              if (user != null) {
                context.read<NotesCubit>().refreshNotes(user.id, habit.id);
              }
            }
          },
          child: Scaffold(
        appBar: AppBar(
          title: Hero(
            tag: 'habit-title-${habit.id}',
            child: Material(
              type: MaterialType.transparency,
              child: Text(habit.title),
            ),
          ),
          actions: [
            IconButton(
              tooltip: 'Edit',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CreateHabitScreen(habit: habit),
                  ),
                );
              },
            ),
            FilledButton.tonalIcon(
              onPressed: _toggleCompletion,
              icon: Icon(habit.isCompletedToday ? Icons.check : Icons.task_alt, size: 18),
              label: Text(habit.isCompletedToday ? 'Completed' : 'Mark complete'),
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                padding: MaterialStateProperty.all(const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Column(
          children: [
            // Habit Info Card
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.4),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Hero(
                        tag: 'habit-progress-${habit.id}',
                        child: _DetailProgressBadge(habit: habit),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              habit.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.local_fire_department,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${habit.currentStreak} day streak',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox.shrink(),
                    ],
                  ),
                  const SizedBox(height: 20),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return Row(
                        children: [
                          Expanded(
                            child: _buildStatItem(
                              'Total Completions',
                              '${habit.completionHistory.length}',
                              Icons.check_circle,
                            ),
                          ),
                          Expanded(
                            child: _buildStatItem(
                              'Completion Rate',
                              '${(habit.completionHistory.length / 30 * 100).round()}%',
                              Icons.pie_chart,
                            ),
                          ),
                          Expanded(
                            child: _buildStatItem(
                              'Created',
                              _formatDate(habit.createdAt),
                              Icons.calendar_today,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            
            // Notes Section Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Notes',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: _createNote,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Note'),
                    style: const ButtonStyle(),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Notes List
            Expanded(
              child: BlocBuilder<NotesCubit, NotesState>(
                builder: (context, state) {
                  if (state is NotesLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is NotesLoaded) {
                    if (state.notes.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.note_add,
                              size: 64,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No notes yet',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Add your first note to track your progress',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }
                    
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: state.notes.length,
                      itemBuilder: (context, index) {
                        final note = state.notes[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Dismissible(
                            key: ValueKey('note-${note.id}'),
                            direction: DismissDirection.endToStart,
                            background: const SizedBox.shrink(),
                            secondaryBackground: _buildDeleteBackground(context),
                            movementDuration: const Duration(milliseconds: 220),
                            resizeDuration: const Duration(milliseconds: 220),
                            dismissThresholds: const {
                              DismissDirection.endToStart: 0.25,
                            },
                            onDismissed: (_) {
                              HapticFeedback.mediumImpact();
                              _deleteNote(note);
                              ScaffoldMessenger.of(context)
                                ..hideCurrentSnackBar()
                                ..showSnackBar(
                                  const SnackBar(content: Text('Note deleted')),
                                );
                            },
                            child: NoteCard(
                              note: note,
                              onTap: () => _editNote(note),
                              onDelete: () => _deleteNote(note),
                            ),
                          ),
                        );
                      },
                    );
                  } else if (state is NotesError) {
                    return Center(
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
                            'Error loading notes',
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
                            onPressed: _loadNotes,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }
                  
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: Theme.of(context).colorScheme.secondary,
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // Removed unused _getColorFromString helper

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

class _DetailProgressBadge extends StatelessWidget {
  final Habit habit;
  const _DetailProgressBadge({required this.habit});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    final completed = habit.isCompletedToday;
    return RepaintBoundary(
      child: SizedBox(
        width: 72,
        height: 72,
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(completed ? 0.35 : 0.22),
                    blurRadius: completed ? 18 : 12,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            Center(
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      color.withOpacity(completed ? 0.22 : 0.14),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Center(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: habit.todayProgress.clamp(0.0, 1.0)),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) {
                      return CustomPaint(
                        painter: _DetailProgressArcPainter(
                          progress: value,
                          color: color,
                        ),
                        child: SizedBox(
                          width: 60,
                          height: 60,
                          child: Center(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 220),
                              child: completed
                                  ? Icon(Icons.check_rounded, key: const ValueKey('check'), color: color, size: 26)
                                  : (habit.currentStreak > 0
                                      ? Text(
                                          '${habit.currentStreak}',
                                          key: const ValueKey('streak'),
                                          style: TextStyle(
                                            color: color,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 18,
                                          ),
                                        )
                                      : Icon(Icons.radio_button_unchecked, key: const ValueKey('pending'), color: color, size: 20)),
                          ),
                        ),
                      ));
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailProgressArcPainter extends CustomPainter {
  final double progress; // 0..1
  final Color color;
  _DetailProgressArcPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 2;

    final trackPaint = Paint()
      ..color = color.withOpacity(0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0) return;

    final rect = Rect.fromCircle(center: center, radius: radius);
    final sweepPaint = Paint()
      ..shader = SweepGradient(
        startAngle: -1.5708,
        endAngle: -1.5708 + (6.28318 * progress).clamp(0.0, 6.28318),
        colors: [
          color.withOpacity(0.95),
          color.withOpacity(0.7),
          color.withOpacity(0.95),
        ],
        stops: const [0.0, 0.6, 1.0],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    final startAngle = -1.5708;
    final sweepAngle = (6.28318 * progress).clamp(0.0, 6.28318);
    canvas.drawArc(rect, startAngle, sweepAngle, false, sweepPaint);
  }

  @override
  bool shouldRepaint(covariant _DetailProgressArcPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

class _AddNoteSheet extends StatefulWidget {
  final String habitId;
  const _AddNoteSheet({required this.habitId});

  @override
  State<_AddNoteSheet> createState() => _AddNoteSheetState();
}

class _AddNoteSheetState extends State<_AddNoteSheet> with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _saving = false;
  late AnimationController _animController;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _fadeIn = CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic);
    _slideUp = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final authCubit = context.read<AuthCubit>();
    final notesCubit = context.read<NotesCubit>();
    final user = authCubit.getCurrentUser();

    if (user != null) {
      await notesCubit.createNote(
        text: _controller.text.trim(),
        habitId: widget.habitId,
        userId: user.id,
      );
    }

    await Future.delayed(const Duration(milliseconds: 220));
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(bottom: viewInsets.bottom),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 16,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: FadeTransition(
              opacity: _fadeIn,
              child: SlideTransition(
                position: _slideUp,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: scheme.onSurface.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.notes_rounded, color: scheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Add Note',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const Spacer(),
                          IconButton(
                            tooltip: 'Close',
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Form(
                        key: _formKey,
                        child: TextFormField(
                          controller: _controller,
                          maxLines: 6,
                          textInputAction: TextInputAction.newline,
                          decoration: InputDecoration(
                            hintText: 'Write something about this habit…',
                            filled: true,
                            fillColor: scheme.surfaceVariant.withOpacity(0.3),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Please enter some text';
                            if (v.trim().length < 3) return 'Note must be at least 3 characters';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 250),
                              switchInCurve: Curves.easeOutBack,
                              switchOutCurve: Curves.easeIn,
                              child: _saving
                                  ? FilledButton.icon(
                                      key: const ValueKey('saving'),
                                      onPressed: null,
                                      icon: const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      ),
                                      label: const Text('Saving...'),
                                    )
                                  : FilledButton.icon(
                                      key: const ValueKey('save'),
                                      onPressed: _save,
                                      icon: const Icon(Icons.save_alt),
                                      label: const Text('Save Note'),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
