import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// A reusable skeleton loading widget using shimmer effect
class SkeletonLoader extends StatelessWidget {
  final double? width;
  final double height;
  final BorderRadius? borderRadius;
  final EdgeInsets? margin;

  const SkeletonLoader({
    super.key,
    this.width,
    this.height = 16.0,
    this.borderRadius,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: borderRadius ?? BorderRadius.circular(4),
      ),
    );
  }
}

/// Shimmer wrapper for skeleton loaders
class ShimmerWrapper extends StatelessWidget {
  final Widget child;

  const ShimmerWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: child,
    );
  }
}

/// List item skeleton
class ListItemSkeleton extends StatelessWidget {
  const ListItemSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerWrapper(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SkeletonLoader(
              width: 48,
              height: 48,
              borderRadius: BorderRadius.all(Radius.circular(24)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonLoader(
                    width: MediaQuery.of(context).size.width * 0.6,
                    height: 16,
                  ),
                  const SizedBox(height: 8),
                  SkeletonLoader(
                    width: MediaQuery.of(context).size.width * 0.4,
                    height: 14,
                  ),
                  const SizedBox(height: 4),
                  SkeletonLoader(
                    width: MediaQuery.of(context).size.width * 0.3,
                    height: 12,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Card skeleton
class CardSkeleton extends StatelessWidget {
  final double? height;

  const CardSkeleton({super.key, this.height});

  @override
  Widget build(BuildContext context) {
    return ShimmerWrapper(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
        height: height ?? 120,
      ),
    );
  }
}

/// List skeleton with multiple items
class ListSkeleton extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext, int)? itemBuilder;

  const ListSkeleton({
    super.key,
    this.itemCount = 5,
    this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: itemBuilder ?? (context, index) => const ListItemSkeleton(),
    );
  }
}

/// Grid skeleton
class GridSkeleton extends StatelessWidget {
  final int itemCount;
  final int crossAxisCount;

  const GridSkeleton({
    super.key,
    this.itemCount = 6,
    this.crossAxisCount = 2,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return ShimmerWrapper(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      },
    );
  }
}

/// Form field skeleton
class FormFieldSkeleton extends StatelessWidget {
  final double? width;

  const FormFieldSkeleton({super.key, this.width});

  @override
  Widget build(BuildContext context) {
    return ShimmerWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonLoader(
            width: width ?? 100,
            height: 12,
            margin: const EdgeInsets.only(bottom: 8),
          ),
          SkeletonLoader(
            width: width ?? double.infinity,
            height: 48,
            borderRadius: BorderRadius.circular(8),
          ),
        ],
      ),
    );
  }
}

/// Profile header skeleton
class ProfileHeaderSkeleton extends StatelessWidget {
  const ProfileHeaderSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerWrapper(
      child: Column(
        children: [
          const SkeletonLoader(
            width: 80,
            height: 80,
            borderRadius: BorderRadius.all(Radius.circular(40)),
          ),
          const SizedBox(height: 16),
          SkeletonLoader(
            width: MediaQuery.of(context).size.width * 0.4,
            height: 20,
          ),
          const SizedBox(height: 8),
          SkeletonLoader(
            width: MediaQuery.of(context).size.width * 0.3,
            height: 16,
          ),
        ],
      ),
    );
  }
}

/// Table row skeleton
class TableRowSkeleton extends StatelessWidget {
  final int columns;

  const TableRowSkeleton({super.key, this.columns = 4});

  @override
  Widget build(BuildContext context) {
    return ShimmerWrapper(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            columns,
            (index) => Expanded(
              child: SkeletonLoader(
                height: 14,
                margin: EdgeInsets.only(right: index < columns - 1 ? 12 : 0),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
