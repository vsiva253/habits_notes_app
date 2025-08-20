import 'package:flutter/material.dart';

class HabitCardSkeleton extends StatelessWidget {
  const HabitCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.4);
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: base, width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _shimmerCircle(context, size: 60),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _shimmerBar(context, height: 16, widthFactor: 0.5),
                const SizedBox(height: 8),
                _shimmerBar(context, height: 12, widthFactor: 0.35),
                const SizedBox(height: 8),
                _shimmerBar(context, height: 10, widthFactor: 0.25),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _shimmerBar(BuildContext context, {required double height, double widthFactor = 1}) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );
  }

  Widget _shimmerCircle(BuildContext context, {required double size}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
      ),
    );
  }
}

class AnalyticsSkeleton extends StatelessWidget {
  const AnalyticsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.4),
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _shimmerCircle(context, size: 24),
              const SizedBox(width: 8),
              _bar(context, width: 140, height: 16),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _tile(context)),
              Expanded(child: _tile(context)),
              Expanded(child: _tile(context)),
            ],
          ),
          const SizedBox(height: 20),
          _bar(context, width: double.infinity, height: 8),
          const SizedBox(height: 8),
          _bar(context, width: 200, height: 12),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        const SizedBox(height: 8),
        _bar(context, width: 40, height: 18),
        const SizedBox(height: 4),
        _bar(context, width: 60, height: 12),
      ],
    );
  }

  Widget _bar(BuildContext context, {required double width, required double height}) {
    return SizedBox(
      width: width,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );
  }

  Widget _shimmerCircle(BuildContext context, {required double size}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
      ),
    );
  }
}


