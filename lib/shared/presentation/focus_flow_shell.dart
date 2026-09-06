import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/app_routes.dart';
import '../../app/theme/focus_flow_colors.dart';
import '../../app/theme/focus_flow_tokens.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/tasks/presentation/cubit/tasks_cubit.dart';
import '../../core/domain/services/preferences_service.dart';
import 'widgets/focus_flow_logo.dart';
import 'widgets/focus_flow_avatar.dart';

class FocusFlowShell extends StatelessWidget {
  const FocusFlowShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 900;
    final isTablet = width >= 600 && width < 900;

    if (isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            const FocusFlowSidebar(),
            Expanded(child: child),
          ],
        ),
      );
    }

    if (isTablet) {
      return Scaffold(
        body: Row(
          children: [
            const FocusFlowNavigationRail(),
            const VerticalDivider(
              width: 1,
              thickness: 1,
              color: FocusFlowColors.border,
            ),
            Expanded(child: child),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: FocusFlowLogo(compact: true),
        ),
        actions: [
          IconButton(
            tooltip: 'Settings',
            onPressed: () => context.go(AppRoutes.settings),
            icon: const Icon(Icons.settings_outlined),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              borderRadius: BorderRadius.circular(FocusFlowRadius.pill),
              onTap: () => context.go(AppRoutes.profile),
              child: const FocusFlowAvatar(size: 28),
            ),
          ),
        ],
      ),
      body: child,
      bottomNavigationBar: const FocusFlowBottomNav(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// NavigationRail – Tablet (600px - 900px)
// ─────────────────────────────────────────────────────────────────────────────

class FocusFlowNavigationRail extends StatelessWidget {
  const FocusFlowNavigationRail({super.key});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final routes = [
      (AppRoutes.dashboard, Icons.dashboard_outlined, Icons.dashboard_rounded, 'Dashboard'),
      (AppRoutes.goals, Icons.track_changes_outlined, Icons.track_changes_rounded, 'Goals'),
      (AppRoutes.tasks, Icons.check_circle_outline_rounded, Icons.check_circle_rounded, 'Tasks'),
      (AppRoutes.profile, Icons.person_outline_rounded, Icons.person_rounded, 'Profile'),
      (AppRoutes.settings, Icons.settings_outlined, Icons.settings_rounded, 'Settings'),
    ];
    final selected = routes.indexWhere((item) => location.startsWith(item.$1));

    return NavigationRail(
      backgroundColor: FocusFlowColors.surfaceLow,
      selectedIndex: selected < 0 ? 0 : selected,
      onDestinationSelected: (index) => context.go(routes[index].$1),
      labelType: NavigationRailLabelType.selected,
      leading: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Image.asset('assets/images/logo.png', width: 32, height: 32),
      ),
      destinations: [
        for (final item in routes)
          NavigationRailDestination(
            icon: Icon(item.$2),
            selectedIcon: Icon(item.$3),
            label: Text(
              item.$4,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sidebar – Desktop
// Design: surface-container-low bg (#F4F3F3), right-border active indicator
// ─────────────────────────────────────────────────────────────────────────────

class FocusFlowSidebar extends StatelessWidget {
  const FocusFlowSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 256,
      decoration: const BoxDecoration(
        color: FocusFlowColors.surfaceLow, // #F4F3F3 – surface-container-low
        border: Border(
          right: BorderSide(color: FocusFlowColors.border),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 28, 0, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Logo ────────────────────────────────────────────
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: FocusFlowLogo(),
              ),
              const SizedBox(height: 28),

              // ── Navigation ──────────────────────────────────────
              _SidebarItem(
                icon: Icons.dashboard_outlined,
                activeIcon: Icons.dashboard_rounded,
                label: 'Dashboard',
                route: AppRoutes.dashboard,
              ),
              _SidebarItem(
                icon: Icons.track_changes_outlined,
                activeIcon: Icons.track_changes_rounded,
                label: 'Goals',
                route: AppRoutes.goals,
              ),
              _SidebarItem(
                icon: Icons.check_circle_outline_rounded,
                activeIcon: Icons.check_circle_rounded,
                label: 'Tasks',
                route: AppRoutes.tasks,
              ),
              _SidebarItem(
                icon: Icons.person_outline_rounded,
                activeIcon: Icons.person_rounded,
                label: 'Profile',
                route: AppRoutes.profile,
              ),
              _SidebarItem(
                icon: Icons.settings_outlined,
                activeIcon: Icons.settings_rounded,
                label: 'Settings',
                route: AppRoutes.settings,
              ),

              const Spacer(),

              // ── Overdue / Notification card ─────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: BlocBuilder<TasksCubit, TasksState>(
                  builder: (context, state) {
                    final overdueCount =
                        state.tasks.where((t) => t.isOverdue).length;
                    final hasOverdue = overdueCount > 0;

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: hasOverdue
                            ? FocusFlowColors.dangerSoft
                            : FocusFlowColors.surfaceHigh,
                        borderRadius:
                            BorderRadius.circular(FocusFlowRadius.md),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: hasOverdue
                                  ? FocusFlowColors.danger.withValues(alpha: 0.12)
                                  : FocusFlowColors.brand.withValues(alpha: 0.12),
                            ),
                            child: Icon(
                              hasOverdue
                                  ? Icons.warning_amber_rounded
                                  : Icons.notifications_none_rounded,
                              size: 18,
                              color: hasOverdue
                                  ? FocusFlowColors.danger
                                  : FocusFlowColors.brand,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              hasOverdue
                                  ? '$overdueCount Overdue Task${overdueCount > 1 ? 's' : ''}'
                                  : 'All Tasks On Track',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: hasOverdue
                                    ? FocusFlowColors.danger
                                    : FocusFlowColors.ink,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),

              // ── User card ────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: BlocBuilder<AuthCubit, AuthState>(
                  builder: (context, state) {
                    final isAuthenticated = state is AuthAuthenticated;
                    final preferencesService = context.read<PreferencesService>();
                    final name = isAuthenticated
                        ? (state.user.userMetadata?['full_name'] as String? ??
                            'User')
                        : preferencesService.guestName;
                    final subtitle = isAuthenticated
                        ? (state.user.email ?? 'Sync enabled')
                        : 'Local mode';

                    return Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: FocusFlowColors.surface,
                        borderRadius:
                            BorderRadius.circular(FocusFlowRadius.xl),
                        border: Border.all(
                          color: FocusFlowColors.border.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        children: [
                          // Avatar with online dot
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              const FocusFlowAvatar(size: 36),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: isAuthenticated
                                        ? FocusFlowColors.success
                                        : FocusFlowColors.quiet,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: FocusFlowColors.surface,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelLarge
                                      ?.copyWith(fontSize: 13),
                                ),
                                Text(
                                  subtitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: FocusFlowColors.quiet,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Login / Profile action button
                          if (!isAuthenticated)
                            _SidebarIconButton(
                              tooltip: 'Exit Guest Mode',
                              icon: Icons.exit_to_app_rounded,
                              onTap: () async {
                                await context.read<AuthCubit>().signOut();
                              },
                            )
                          else
                            _SidebarIconButton(
                              tooltip: 'Log Out',
                              icon: Icons.logout_rounded,
                              onTap: () async {
                                await context.read<AuthCubit>().signOut();
                              },
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom Nav – Mobile
// ─────────────────────────────────────────────────────────────────────────────

class FocusFlowBottomNav extends StatelessWidget {
  const FocusFlowBottomNav({super.key});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final routes = [
      (AppRoutes.dashboard, Icons.dashboard_outlined, Icons.dashboard_rounded, 'Dashboard'),
      (AppRoutes.goals, Icons.track_changes_outlined, Icons.track_changes_rounded, 'Goals'),
      (AppRoutes.tasks, Icons.check_circle_outline_rounded, Icons.check_circle_rounded, 'Tasks'),
      (AppRoutes.profile, Icons.person_outline_rounded, Icons.person_rounded, 'Profile'),
    ];
    final selected = routes.indexWhere((item) => location.startsWith(item.$1));

    return NavigationBar(
      selectedIndex: selected < 0 ? 0 : selected,
      onDestinationSelected: (index) => context.go(routes[index].$1),
      destinations: [
        for (final item in routes)
          NavigationDestination(
            icon: Icon(item.$2),
            selectedIcon: Icon(item.$3),
            label: item.$4,
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SidebarItem – individual nav item with right-border active indicator
// Per DESIGN.md: Active = secondary/10 bg + border-r-4 in secondary color
// ─────────────────────────────────────────────────────────────────────────────

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.route,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;

  @override
  Widget build(BuildContext context) {
    final isActive = GoRouterState.of(context).uri.path.startsWith(route);

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: InkWell(
        onTap: () => context.go(route),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 44,
          // Right border indicator – 4px wide in secondary color (DESIGN.md)
          decoration: BoxDecoration(
            color: isActive
                ? FocusFlowColors.brand.withValues(alpha: 0.1)
                : Colors.transparent,
            border: isActive
                ? const Border(
                    right: BorderSide(
                      color: FocusFlowColors.brand,
                      width: 3,
                    ),
                  )
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Icon(
                  isActive ? activeIcon : icon,
                  size: FocusFlowIconSize.md,
                  color: isActive
                      ? FocusFlowColors.brand
                      : FocusFlowColors.muted,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: isActive
                        ? FocusFlowColors.brand
                        : FocusFlowColors.muted,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarIconButton extends StatelessWidget {
  const _SidebarIconButton({
    required this.tooltip,
    required this.icon,
    required this.onTap,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(FocusFlowRadius.md),
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(FocusFlowRadius.md),
          ),
          child: Icon(
            icon,
            size: 16,
            color: FocusFlowColors.muted,
          ),
        ),
      ),
    );
  }
}
