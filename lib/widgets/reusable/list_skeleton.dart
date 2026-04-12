import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../utils/constants.dart';

class ListSkeleton extends StatelessWidget {
  final int itemCount;
  final bool hasAvatar;
  final bool compact;

  const ListSkeleton({
    super.key,
    this.itemCount = 6,
    this.hasAvatar = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[200]!,
      highlightColor: Colors.grey[50]!,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingM,
          vertical: AppDimensions.paddingM,
        ),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        itemBuilder: (_, __) => Padding(
          padding: EdgeInsets.only(bottom: compact ? 12.0 : 16.0),
          child: Container(
            padding: EdgeInsets.all(compact ? 12.0 : 16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (hasAvatar) ...[
                  Container(
                    width: compact ? 40 : 50,
                    height: compact ? 40 : 50,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                         width: 120,
                         height: 12,
                         decoration: BoxDecoration(
                           color: Colors.white,
                           borderRadius: BorderRadius.circular(4),
                         ),
                      ),
                      if (!compact) ...[
                        const SizedBox(height: 8),
                         Container(
                           width: 80,
                           height: 10,
                           decoration: BoxDecoration(
                             color: Colors.white,
                             borderRadius: BorderRadius.circular(4),
                           ),
                         ),
                      ]
                    ],
                  ),
                ),
                if (!compact) ...[
                  const SizedBox(width: 16),
                  Container(
                    width: 40,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }
}
