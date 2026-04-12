import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../utils/constants.dart';

class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const NeverScrollableScrollPhysics(), // Disable scrolling during skeleton
        slivers: [
          // ── App Bar Skeleton ───────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 180,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.white,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(AppDimensions.paddingL),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Row(
                            children: [
                              // Avatar Skeleton
                              Container(
                                width: 58,
                                height: 58,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: AppDimensions.paddingM),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 60,
                                      height: 14,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      width: 140,
                                      height: 22,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      width: 100,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
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

          // ── Body Skeleton ────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingL),
              child: Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Doctor Card Skeleton
                    Container(
                      width: double.infinity,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                      ),
                    ),
                    const SizedBox(height: AppDimensions.paddingL),

                    // Status Card Skeleton
                    Container(
                      width: double.infinity,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                      ),
                    ),
                    const SizedBox(height: AppDimensions.paddingL),

                    // Section Title Skeleton
                    Container(
                      width: 100,
                      height: 20,
                      color: Colors.white,
                    ),
                    const SizedBox(height: AppDimensions.paddingM),

                    // Vitals Grid Skeleton
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: AppDimensions.paddingM,
                      mainAxisSpacing: AppDimensions.paddingM,
                      childAspectRatio: 1.5,
                      children: List.generate(4, (index) {
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
