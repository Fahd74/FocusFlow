import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/focus_flow_colors.dart';
import '../../../../app/theme/focus_flow_tokens.dart';
import '../../../../shared/presentation/widgets/focus_flow_button.dart';

import '../../../../shared/presentation/widgets/focus_flow_card.dart';
import '../../../../shared/presentation/widgets/focus_flow_page.dart';
import '../../../../shared/presentation/widgets/focus_flow_avatar.dart';
import '../../../dashboard/presentation/cubit/dashboard_cubit.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../goals/presentation/cubit/goals_cubit.dart';
import '../../../../core/data/remote/supabase_sync_engine.dart';
import '../../../../core/domain/services/preferences_service.dart';
import '../../../../core/data/focus_flow_repository.dart';
import '../../../../core/domain/focus_flow_models.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  StreamSubscription? _subscription;
  UserProfile? _userProfile;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _subscription?.cancel();
    final repository = context.read<FocusFlowRepository>();
    _userProfile = repository.snapshot.userProfile;
    _subscription = repository.watchSnapshot().listen((snapshot) {
      if (mounted) {
        setState(() {
          _userProfile = snapshot.userProfile;
        });
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        final user = authState is AuthAuthenticated ? authState.user : null;
        final preferencesService = context.read<PreferencesService>();
        final profile = _userProfile;
        
        final name = profile?.fullName ?? user?.userMetadata?['full_name'] as String? ?? preferencesService.guestName;
        final email = profile?.email ?? user?.email ?? preferencesService.guestEmail;
        final isGuest = user == null;

        return FocusFlowPage(
          title: '', // Custom profile layout header
          onRefresh: () async {
            try {
              // Capture context-dependent objects before any async gap
              final authCubit = context.read<AuthCubit>();
              final syncEngine = context.read<SupabaseSyncEngine?>();
              await authCubit.refreshUser();
              if (syncEngine != null) {
                await syncEngine.forceSync();
              } else {
                await Future.delayed(const Duration(milliseconds: 600));
              }
            } catch (_) {}
          },
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth >= 1050;

                // 1. Hero Profile Section
                final heroProfile = Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Stack(
                      children: [
                        FocusFlowAvatar(
                          size: isDesktop ? 110 : 76,
                          borderWidth: 3,
                          borderColor: FocusFlowColors.border,
                        ),
                        Positioned(
                          bottom: -2,
                          right: -2,
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: FocusFlowColors.brand,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                            ),
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: const Icon(
                                Icons.edit_outlined,
                                size: 16,
                                color: Colors.white,
                              ),
                              onPressed: () => context.go(AppRoutes.editProfile),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(width: isDesktop ? FocusFlowSpacing.lg : FocusFlowSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: Theme.of(context)
                                .textTheme
                                .displayLarge
                                ?.copyWith(
                                  fontFamily: 'SpaceGrotesk',
                                  fontSize: isDesktop ? 32 : 24,
                                  fontWeight: FontWeight.bold,
                                  color: FocusFlowColors.ink,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            email,
                            style: const TextStyle(
                              fontSize: 14,
                              color: FocusFlowColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );

                // 2. Left Bento column: Stats + Weekly Trend Chart
                final leftColumn = BlocBuilder<DashboardCubit, DashboardState>(
                  builder: (context, dashState) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Quick Stats Row
                        LayoutBuilder(
                          builder: (context, statsConstraints) {
                            final wideStats = statsConstraints.maxWidth >= 600;
                            final statTiles = [
                              _ProfileStatCard(
                                label: 'Goals Completed',
                                value: '${dashState.goalsDone}',
                                subtitle: '+2 this month',
                                valueColor: FocusFlowColors.brand,
                              ),
                              _ProfileStatCard(
                                label: 'Tasks Finished',
                                value: '${dashState.tasksDone}',
                                subtitle: 'Top 10%',
                                valueColor: FocusFlowColors.brand,
                              ),
                              _ProfileStatCard(
                                label: 'Current Streak',
                                value: '${dashState.currentStreak}',
                                subtitle: 'Days',
                                valueColor: FocusFlowColors.ink,
                              ),
                            ];

                            if (wideStats) {
                              return Row(
                                children: [
                                  for (int i = 0; i < statTiles.length; i++) ...[
                                    Expanded(child: statTiles[i]),
                                    if (i != statTiles.length - 1)
                                      const SizedBox(width: FocusFlowSpacing.md),
                                  ]
                                ],
                              );
                            }

                            return Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(child: statTiles[0]),
                                    const SizedBox(width: FocusFlowSpacing.md),
                                    Expanded(child: statTiles[1]),
                                  ],
                                ),
                                const SizedBox(height: FocusFlowSpacing.md),
                                SizedBox(
                                  width: double.infinity,
                                  child: statTiles[2],
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: FocusFlowSpacing.lg),

                        // Weekly Focus Trend Card
                        FocusFlowCard(
                          padding: const EdgeInsets.all(24),
                          child: const _WeeklyFocusTrendChart(),
                        ),
                      ],
                    );
                  },
                );

                final actionsRow = Padding(
                  padding: const EdgeInsets.symmetric(vertical: FocusFlowSpacing.md),
                  child: Row(
                    children: [
                      Expanded(
                        child: FocusFlowSecondaryButton(
                          label: 'Edit Profile',
                          icon: Icons.person_outline_rounded,
                          onPressed: () => context.go(AppRoutes.editProfile),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: isGuest
                            ? FocusFlowPrimaryButton(
                                label: 'Log In',
                                icon: Icons.login_rounded,
                                onPressed: () async {
                                  await context.read<AuthCubit>().signOut();
                                },
                              )
                            : OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: FocusFlowColors.danger),
                                  foregroundColor: FocusFlowColors.danger,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(FocusFlowRadius.md),
                                  ),
                                ),
                                onPressed: () async {
                                  await context.read<AuthCubit>().signOut();
                                  if (context.mounted) {
                                    context.go(AppRoutes.login);
                                  }
                                },
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.logout_rounded, size: 16),
                                    SizedBox(width: 8),
                                    Text(
                                      'Log Out',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    ],
                  ),
                );

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    heroProfile,
                    const SizedBox(height: FocusFlowSpacing.xl),
                    leftColumn,
                    const SizedBox(height: FocusFlowSpacing.lg),
                    actionsRow,
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _ProfileStatCard extends StatelessWidget {
  const _ProfileStatCard({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.valueColor,
  });

  final String label;
  final String value;
  final String subtitle;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: FocusFlowColors.border),
        borderRadius: BorderRadius.circular(FocusFlowRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: FocusFlowColors.muted,
              letterSpacing: 0.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: valueColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: FocusFlowColors.quiet,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


class _WeeklyFocusTrendChart extends StatelessWidget {
  const _WeeklyFocusTrendChart();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardCubit, DashboardState>(
      builder: (context, state) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        
        final monday = today.subtract(Duration(days: now.weekday - 1));

        final workCounts = List<int>.filled(7, 0);
        final personalCounts = List<int>.filled(7, 0);

        for (var i = 0; i < 7; i++) {
          final targetDay = monday.add(Duration(days: i));
          
          final dayTasks = state.tasks.where((task) {
            if (task.completedAt == null) return false;
            final completionDay = DateTime(
              task.completedAt!.year,
              task.completedAt!.month,
              task.completedAt!.day,
            );
            return completionDay.isAtSameMomentAs(targetDay);
          });

          for (final task in dayTasks) {
            final goalsState = context.read<GoalsCubit>().state;
            final parentGoal = goalsState.goals.where((g) => g.id == task.goalId).firstOrNull;
            final goalType = parentGoal != null
                ? goalsState.goalTypes.where((t) => t.id == parentGoal.typeId).firstOrNull
                : null;
            
            final isWork = goalType != null &&
                (goalType.name.toLowerCase().contains('work') || goalType.id.toLowerCase().contains('work'));
            
            if (isWork) {
              workCounts[i]++;
            } else {
              personalCounts[i]++;
            }
          }
        }

        int maxTotal = 0;
        for (var i = 0; i < 7; i++) {
          final total = workCounts[i] + personalCounts[i];
          if (total > maxTotal) {
            maxTotal = total;
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Weekly Focus Trend',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: FocusFlowColors.brand,
                      ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Task distribution over the last 7 days',
                  style: TextStyle(fontSize: 12, color: FocusFlowColors.muted),
                ),
              ],
            ),
            const SizedBox(height: 30),
            SizedBox(
              height: 180,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var index = 0; index < 7; index++) ...[
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: LayoutBuilder(
                                builder: (context, barConstraints) {
                                  final total = workCounts[index] + personalCounts[index];
                                  if (total == 0) {
                                    return Container(
                                      height: 6,
                                      width: 18,
                                      decoration: BoxDecoration(
                                        color: FocusFlowColors.surfaceLow,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    );
                                  }

                                  final scale = total / (maxTotal == 0 ? 1 : maxTotal);
                                  final maxHeight = barConstraints.maxHeight;
                                  final barHeight = maxHeight * scale;

                                  return Container(
                                    width: 18,
                                    height: barHeight,
                                    decoration: const BoxDecoration(
                                      color: Colors.transparent,
                                      borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(5),
                                      ),
                                    ),
                                    clipBehavior: Clip.antiAlias,

                                    child: Column(
                                      children: [
                                        if (personalCounts[index] > 0)
                                          Expanded(
                                            flex: personalCounts[index],
                                            child: Container(
                                              color: FocusFlowColors.secondary,
                                            ),
                                          ),
                                        if (workCounts[index] > 0)
                                          Expanded(
                                            flex: workCounts[index],
                                            child: Container(
                                              color: FocusFlowColors.brand,
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: FocusFlowSpacing.sm),
                          Text(
                            ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][index],
                            style: const TextStyle(fontSize: 11, color: FocusFlowColors.quiet),
                          ),
                        ],
                      ),
                    ),
                    if (index != 6)
                      const SizedBox(width: FocusFlowSpacing.sm),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}



