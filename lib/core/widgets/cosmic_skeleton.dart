import 'dart:math';
import 'package:flutter/material.dart';

/// Reusable shimmer skeleton loader dengan cosmic styling.
/// Menampilkan placeholder animasi shimmer untuk konten yang sedang dimuat.
///
/// Gunakan [CosmicSkeletonCard] untuk card placeholder dan
/// [CosmicSkeletonRow] untuk baris teks placeholder.
class CosmicSkeletonCard extends StatefulWidget {
  const CosmicSkeletonCard({
    super.key,
    this.height = 120,
    this.width,
    this.borderRadius = 14,
    this.childAspectRatio,
  });

  final double height;
  final double? width;
  final double borderRadius;
  final double? childAspectRatio;

  @override
  State<CosmicSkeletonCard> createState() => _CosmicSkeletonCardState();
}

class _CosmicSkeletonCardState extends State<CosmicSkeletonCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final gradient = LinearGradient(
          begin: Alignment(_animation.value - 1, 0),
          end: Alignment(_animation.value + 1, 0),
          colors: const [
            Color(0x0DFFFFFF),
            Color(0x15FFFFFF),
            Color(0x0DFFFFFF),
          ],
        );
        return Container(
          height: widget.height,
          width: widget.width,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              colors: [
                Colors.white.withValues(alpha: 0.04),
                Colors.white.withValues(alpha: 0.07),
                Colors.white.withValues(alpha: 0.04),
              ],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.06),
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            child: ShaderMask(
              shaderCallback: (bounds) => gradient.createShader(bounds),
              blendMode: BlendMode.srcATop,
              child: Container(color: Colors.white.withValues(alpha: 0.03)),
            ),
          ),
        );
      },
    );
  }
}

/// Grid of skeleton cards — cocok untuk loading state kalender atau grid layout.
class CosmicSkeletonGrid extends StatelessWidget {
  const CosmicSkeletonGrid({
    super.key,
    this.columns = 3,
    this.rows = 4,
    this.cardHeight = 90,
    this.spacing = 10,
  });

  final int columns;
  final int rows;
  final double cardHeight;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(rows, (row) {
        return Padding(
          padding: EdgeInsets.only(bottom: row < rows - 1 ? spacing : 0),
          child: Row(
            children: List.generate(columns, (col) {
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: col < columns - 1 ? spacing : 0,
                  ),
                  child: CosmicSkeletonCard(height: cardHeight),
                ),
              );
            }),
          ),
        );
      }),
    );
  }
}

/// Skeleton untuk baris teks — shimmer placeholder saat konten naratif dimuat.
class CosmicSkeletonText extends StatelessWidget {
  const CosmicSkeletonText({super.key, this.lines = 3, this.widths});

  final int lines;
  final List<double>? widths;

  @override
  Widget build(BuildContext context) {
    final rng = Random(42);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(lines, (i) {
        final w = widths != null && i < widths!.length
            ? widths![i]
            : 0.5 + rng.nextDouble() * 0.5;
        return Padding(
          padding: EdgeInsets.only(bottom: i < lines - 1 ? 10 : 0),
          child: FractionallySizedBox(
            widthFactor: w,
            child: Container(
              height: 12,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
        );
      }),
    );
  }
}
