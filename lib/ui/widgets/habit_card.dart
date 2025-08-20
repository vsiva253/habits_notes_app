import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/models/habit.dart';

class HabitCard extends StatelessWidget {
  final Habit habit;
  final VoidCallback onTap;
  final VoidCallback onToggleCompletion;

  const HabitCard({
    super.key,
    required this.habit,
    required this.onTap,
    required this.onToggleCompletion,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = _getThemeColor(context, habit.color);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: accent.withOpacity(0.25),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                accent.withOpacity(habit.isCompletedToday ? 0.10 : 0.06),
                theme.colorScheme.surface.withOpacity(0.0),
              ],
            ),
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Rich, non-interactive visual indicator with Hero + repaint isolation
              Hero(
                  tag: 'habit-progress-${habit.id}',
                child: RepaintBoundary(
                  child: _ProgressBadge(habit: habit, color: accent),
                ),
              ),

              const SizedBox(width: 14),

              // Title + metadata
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Hero(
                      tag: 'habit-title-${habit.id}',
                      child: Material(
                        type: MaterialType.transparency,
                        child: Text(
                          _capitalizeFirst(habit.title.trim()),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 10,
                      runSpacing: 4,
                      children: [
                        _Badge(
                          icon: Icons.local_fire_department,
                          label: '${habit.currentStreak}d',
                          color: theme.colorScheme.onSurface.withOpacity(0.65),
                        ),
                        _Badge(
                          icon: Icons.check_circle_outline,
                          label: '${habit.completionHistory.length}',
                          color: theme.colorScheme.onSurface.withOpacity(0.65),
                        ),
                        _Badge(
                          icon: Icons.calendar_today,
                          label: _formatDate(habit.createdAt),
                          color: theme.colorScheme.onSurface.withOpacity(0.50),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: 12),

              // Trailing action (explicit completion control)
              Semantics(
                button: true,
                label: habit.isCompletedToday ? 'Completed today' : 'Mark complete',
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  switchInCurve: Curves.easeOutBack,
                  switchOutCurve: Curves.easeIn,
                  child: habit.isCompletedToday
                      ? _CompletedBadge(color: accent)
                      : _CompleteButton(
                          color: accent,
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            onToggleCompletion();
                          },
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  Color _getColorFromString(String colorString) {
    switch (colorString.toLowerCase()) {
      case 'red':
        return Colors.red;
      case 'blue':
        return Colors.blue;
      case 'green':
        return Colors.green;
      case 'yellow':
        // Use orange for better contrast instead of bright yellow
        return Colors.orange;
      case 'orange':
        return Colors.orange;
      case 'purple':
        return Colors.purple;
      case 'pink':
        return Colors.pink;
      case 'teal':
        return Colors.teal;
      case 'indigo':
        return Colors.indigo;
      case 'brown':
        return Colors.brown;
      case 'grey':
      case 'gray':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Color _getThemeColor(BuildContext context, String colorString) {
    // Use the exact chosen color to reflect user selection accurately
    return _getColorFromString(colorString);
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    
    if (difference == 0) return 'today';
    if (difference == 1) return 'yesterday';
    if (difference < 7) return '$difference days ago';
    if (difference < 30) return '${(difference / 7).round()} w ago';
    if (difference < 365) return '${(difference / 30).round()} mo ago';
    return '${(difference / 365).round()} y ago';
  }
}

class _ProgressBadge extends StatefulWidget {
  final Habit habit;
  final Color color;
  const _ProgressBadge({required this.habit, required this.color});

  @override
  State<_ProgressBadge> createState() => _ProgressBadgeState();
}

class _ProgressBadgeState extends State<_ProgressBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    _updatePulse();
  }

  @override
  void didUpdateWidget(covariant _ProgressBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.habit.isCompletedToday != widget.habit.isCompletedToday) {
      _updatePulse();
    }
  }

  void _updatePulse() {
    if (widget.habit.isCompletedToday) {
      _controller.stop();
      _controller.value = 0.0;
    } else {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool completed = widget.habit.isCompletedToday;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final pulse = completed ? 0.0 : _controller.value; // 0..1
        final haloOpacity = completed ? 0.35 : (0.12 + 0.35 * pulse).clamp(0.12, 0.5);
        final haloBlur = completed ? 16.0 : (6.0 + 18.0 * pulse);
        final innerOpacity = completed ? 0.22 : (0.08 + 0.22 * pulse);
        final scale = completed ? 1.0 : (1.0 + 0.08 * pulse);

        return Transform.scale(
          scale: scale,
          child: SizedBox(
            width: 56,
            height: 56,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Soft halo with pulsing brightness
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: widget.color.withOpacity(haloOpacity),
                        blurRadius: haloBlur,
                        spreadRadius: 1.0,
                      ),
                    ],
                  ),
                ),
                // Pulsing outer ring (only visible when not completed)
                if (!completed)
                  Center(
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: widget.color.withOpacity(0.25 + 0.25 * pulse),
                          width: 1.5 + 0.8 * pulse,
                        ),
                      ),
                    ),
                  ),
                // Badge body
                Center(
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          widget.color.withOpacity(innerOpacity),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Center(
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(
                          begin: 0.0,
                          end: widget.habit.todayProgress.clamp(0.0, 1.0),
                        ),
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, __) {
                          return CustomPaint(
                            painter: _ProgressArcPainter(
                              progress: value,
                              color: widget.color,
                            ),
                            child: SizedBox(
                              width: 46,
                              height: 46,
                              child: Center(
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 220),
                                  child: completed
                                      ? Icon(
                                          Icons.check_rounded,
                                          key: const ValueKey('check'),
                                          color: widget.color,
                                          size: 20,
                                        )
                                      : (widget.habit.currentStreak > 0
                                          ? Text(
                                              '${widget.habit.currentStreak}',
                                              key: const ValueKey('streak'),
                                              style: TextStyle(
                                                color: widget.color,
                                                fontWeight: FontWeight.w800,
                                                fontSize: 16,
                                              ),
                                            )
                                          : Icon(
                                              Icons.radio_button_unchecked,
                                              key: const ValueKey('pending'),
                                              color: widget.color,
                                              size: 18,
                                            )
                                        ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ProgressArcPainter extends CustomPainter {
  final double progress; // 0..1
  final Color color;
  _ProgressArcPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 2;

    // Track
    final trackPaint = Paint()
      ..color = color.withOpacity(0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0) return;

    // Gradient arc
    final rect = Rect.fromCircle(center: center, radius: radius);
    final sweepPaint = Paint()
      ..shader = SweepGradient(
        startAngle: -1.5708, // -90 deg
        endAngle: -1.5708 + (6.28318 * progress).clamp(0.0, 6.28318),
        colors: [
          color.withOpacity(0.9),
          color.withOpacity(0.7),
          color.withOpacity(0.9),
        ],
        stops: const [0.0, 0.6, 1.0],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final startAngle = -1.5708; // -90 deg top
    final sweepAngle = (6.28318 * progress).clamp(0.0, 6.28318);
    canvas.drawArc(rect, startAngle, sweepAngle, false, sweepPaint);
  }

  @override
  bool shouldRepaint(covariant _ProgressArcPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _Badge({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

class _CompleteButton extends StatelessWidget {
  final Color color;
  final VoidCallback onPressed;
  const _CompleteButton({required this.color, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const ValueKey('complete'),
      height: 30,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(Icons.task_alt, size: 16, color: color),
        label: const Text('Complete'),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withOpacity(0.5)),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }
}

class _CompletedBadge extends StatelessWidget {
  final Color color;
  const _CompletedBadge({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('completed'),
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_rounded, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            'Today',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}
