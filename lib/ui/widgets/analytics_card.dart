import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/analytics_service.dart';
import '../../logic/habits_cubit.dart';

class AnalyticsCard extends StatefulWidget {
  final HabitSummary summary;

  const AnalyticsCard({
    super.key,
    required this.summary,
  });

  @override
  State<AnalyticsCard> createState() => _AnalyticsCardState();
}

class _AnalyticsCardState extends State<AnalyticsCard> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _showRate = true; // true => % rate, false => counts

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 336,
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() => _currentPage = index);
                    },
                    children: [
                      _buildDailyPage(context),
                      _buildWeeklyPage(context),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: SizedBox(
            width: 160,
            child: CupertinoSlidingSegmentedControl<int>(
              backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
              groupValue: _currentPage,
              children: const {
                0: Padding(
                  padding: EdgeInsets.symmetric(vertical: 6),
                  child: Text('Today'),
                ),
                1: Padding(
                  padding: EdgeInsets.symmetric(vertical: 6),
                  child: Text('Week'),
                ),
              },
              onValueChanged: (value) {
                if (value == null) return;
                setState(() => _currentPage = value);
                _pageController.animateToPage(
                  value,
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDailyPage(BuildContext context) {
    final summary = widget.summary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Row(
          children: [
            Icon(
              Icons.analytics,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              'Today\'s Progress',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _buildAnimatedStatItem(
                context,
                'Total Habits',
                summary.totalHabits.toDouble(),
                Icons.list_alt,
                Theme.of(context).colorScheme.primary,
              ),
            ),
            Expanded(
              child: _buildAnimatedStatItem(
                context,
                'Completed',
                summary.completedToday.toDouble(),
                Icons.check_circle,
                Theme.of(context).colorScheme.tertiary,
              ),
            ),
            Expanded(
              child: _buildAnimatedStatItem(
                context,
                'Completion Rate',
                (summary.completionRate * 100),
                Icons.pie_chart,
                Theme.of(context).colorScheme.secondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _buildAnimatedStatItem(
                context,
                'Avg Streak',
                summary.averageStreak.toDouble(),
                Icons.local_fire_department,
                Theme.of(context).colorScheme.secondary,
              ),
            ),
            Expanded(
              child: _buildAnimatedStatItem(
                context,
                'Best Streak',
                summary.bestStreak.toDouble(),
                Icons.emoji_events,
                Theme.of(context).colorScheme.secondary,
              ),
            ),
            const Expanded(
              child: SizedBox.shrink(),
            ),
          ],
        ),
        const SizedBox(height: 16),
        LinearProgressIndicator(
          value: summary.completionRate,
          backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
          valueColor: AlwaysStoppedAnimation<Color>(
            Theme.of(context).colorScheme.primary,
          ),
          minHeight: 8,
        ),
        const SizedBox(height: 8),
        Text(
          '${(summary.completionRate * 100).round()}% of habits completed today',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildWeeklyPage(BuildContext context) {
    return BlocBuilder<HabitsCubit, HabitsState>(
      builder: (context, state) {
        if (state is! HabitsLoaded || state.habits.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Row(
                children: [
                  Icon(
                    Icons.analytics_outlined,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Weekly Progress',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  // Removed 'Last 7 days' chip to avoid overlap
                ],
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'No data yet',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 16),
            ],
          );
        }

        final weeklyCounts = _computeWeeklyData(state.habits);
        final maxCount = weeklyCounts.fold<int>(0, (max, v) => v > max ? v : max);
        final safeMaxCount = maxCount == 0 ? 1 : maxCount;
        final now = DateTime.now();
        final dayLabels = List.generate(7, (i) {
          final date = now.subtract(Duration(days: 6 - i));
          return _weekdayShort(date.weekday);
        });

        final total = weeklyCounts.fold<int>(0, (s, v) => s + v);
        final avg = (total / 7).toStringAsFixed(1);
        const double chartHeight = 100;
        final totalHabits = widget.summary.totalHabits;
        final weeklyRates = weeklyCounts
            .map<double>((c) => totalHabits == 0 ? 0 : (c / totalHabits) * 100)
            .toList(growable: false);
        final bestIndex = _indexOfMax(weeklyCounts);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 28),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              alignment: WrapAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.analytics_outlined,
                      color: Theme.of(context).colorScheme.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Weekly Progress',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    // Removed 'Last 7 days' chip to avoid overlap
                  ],
                ),
                FittedBox(
                  child: ToggleButtons(
                    isSelected: [_showRate == false, _showRate == true],
                    constraints: const BoxConstraints(minHeight: 28, minWidth: 56),
                    onPressed: (index) {
                      setState(() => _showRate = index == 1);
                    },
                    children: const [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6),
                        child: Text('Count'),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6),
                        child: Text('% Rate'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: chartHeight + 38,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SizedBox(
                    width: 36,
                    child: _buildYAxisLabels(context, chartHeight,
                        countsMax: safeMaxCount,
                        showRate: _showRate,
                        totalHabits: totalHabits),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: _buildGridLines(context),
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: List.generate(7, (i) {
                            final count = weeklyCounts[i];
                            final rate = weeklyRates[i];
                            final heightFactor = _showRate
                                ? (rate / 100.0)
                                : (count / safeMaxCount);
                            final scheme = Theme.of(context).colorScheme;
                            Color baseColor;
                            if (i == bestIndex) {
                              baseColor = scheme.tertiary;
                            } else if (i == 6) {
                              baseColor = scheme.primary;
                            } else {
                              baseColor = scheme.primary.withOpacity(0.8);
                            }
                            final display = _showRate
                                ? '${rate.round()}%'
                                : count.toString();
                            const double barWidth = 6;
                            return Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  SizedBox(
                                    height: 16,
                                    child: Center(
                                      child: Opacity(
                                        opacity: 0.8,
                                        child: Text(
                                          display,
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelSmall
                                              ?.copyWith(fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    height: chartHeight,
                                    child: Align(
                                      alignment: Alignment.bottomCenter,
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 400),
                                        curve: Curves.easeOutCubic,
                                        height: chartHeight * heightFactor,
                                        width: barWidth,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.bottomCenter,
                                            end: Alignment.topCenter,
                                            colors: [
                                              baseColor,
                                              baseColor.withOpacity(0.6),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    dayLabels[i],
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withOpacity(0.7),
                                        ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Builder(builder: (context) {
              final activeDays = weeklyCounts.where((v) => v > 0).length;
              final bestDayLabel = _bestDayLabel(weeklyCounts);
              final bestVal = weeklyCounts[_indexOfMax(weeklyCounts)];
              final bestRate = widget.summary.totalHabits == 0
                  ? 0
                  : ((bestVal / widget.summary.totalHabits) * 100).round();
              final todayVal = weeklyCounts[6];
              final todayRate = widget.summary.totalHabits == 0
                  ? 0
                  : ((todayVal / widget.summary.totalHabits) * 100).round();

              return Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _buildInfoChip(
                    context,
                    icon: Icons.summarize,
                    label: 'Total',
                    value: total.toString(),
                  ),
                  _buildInfoChip(
                    context,
                    icon: Icons.calendar_view_week,
                    label: 'Avg/Day',
                    value: avg,
                  ),
                  _buildInfoChip(
                    context,
                    icon: Icons.fact_check_outlined,
                    label: 'Active Days',
                    value: '$activeDays/7',
                  ),
                  _buildInfoChip(
                    context,
                    icon: Icons.emoji_events_outlined,
                    label: 'Best',
                    value: '$bestDayLabel — $bestVal (${bestRate}%)',
                  ),
                  _buildInfoChip(
                    context,
                    icon: Icons.today_outlined,
                    label: 'Today',
                    value: '$todayVal (${todayRate}%)',
                  ),
                ],
              );
            }),
          ],
        );
      },
    );
  }

  int _indexOfMax(List<int> values) {
    if (values.isEmpty) return 0;
    int best = 0;
    for (int i = 1; i < values.length; i++) {
      if (values[i] > values[best]) best = i;
    }
    return best;
  }

  Widget _buildGridLines(BuildContext context) {
    return Column(
      children: List.generate(5, (i) {
        return Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withOpacity(0.08),
                  width: 1,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildYAxisLabels(BuildContext context, double chartHeight,
      {required int countsMax, required bool showRate, required int totalHabits}) {
    final textStyle = Theme.of(context)
        .textTheme
        .labelSmall
        ?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6));
    final labels = <String>[];
    if (showRate) {
      labels.addAll(['100%', '75%', '50%', '25%', '0%']);
    } else {
      final tick1 = countsMax;
      final tick2 = (countsMax * 0.75).ceil();
      final tick3 = (countsMax * 0.5).ceil();
      final tick4 = (countsMax * 0.25).ceil();
      labels.addAll(['$tick1', '$tick2', '$tick3', '$tick4', '0']);
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: labels
          .map((l) => SizedBox(height: chartHeight / 4, child: Text(l, style: textStyle)))
          .toList(),
    );
  }

  List<int> _computeWeeklyData(List habits) {
    final now = DateTime.now();
    return List.generate(7, (index) {
      final date = now.subtract(Duration(days: 6 - index));
      final dateOnly = DateTime(date.year, date.month, date.day);
      int completedCount = 0;
      for (final habit in habits) {
        if (habit.completionHistory.any((completionDate) {
          final d = DateTime(
            completionDate.year,
            completionDate.month,
            completionDate.day,
          );
          return d.isAtSameMomentAs(dateOnly);
        })) {
          completedCount++;
        }
      }
      return completedCount;
    });
  }

  String _weekdayShort(int weekday) {
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return labels[weekday - 1];
  }

  String _bestDayLabel(List<int> weeklyData) {
    if (weeklyData.every((v) => v == 0)) return '-';
    final now = DateTime.now();
    int bestIndex = 0;
    for (int i = 1; i < weeklyData.length; i++) {
      if (weeklyData[i] > weeklyData[bestIndex]) bestIndex = i;
    }
    final date = now.subtract(Duration(days: 6 - bestIndex));
    return _weekdayShort(date.weekday);
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
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

  // _buildWeeklyStat removed; replaced by _buildInfoChip

  Widget _buildInfoChip(BuildContext context,
      {required IconData icon, required String label, required String value}) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: scheme.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.onSurface.withOpacity(0.7),
                ),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedStatItem(
    BuildContext context,
    String label,
    double value,
    IconData icon,
    Color color,
  ) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, _) {
        final isPercent = label == 'Completion Rate';
        final display = isPercent
            ? '${animatedValue.clamp(0, 100).round()}%'
            : animatedValue.round().toString();
        return _buildStatItem(context, label, display, icon, color);
      },
    );
  }
}
