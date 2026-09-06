import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';

import '../../../../app/theme/focus_flow_colors.dart';
import '../../../../app/theme/focus_flow_tokens.dart';
import '../../../../core/domain/focus_flow_models.dart';
import '../../../../shared/presentation/utils/icon_mapper.dart';
import '../../../../shared/presentation/widgets/focus_flow_button.dart';
import '../../../../shared/presentation/widgets/focus_flow_card.dart';
import '../../../../core/data/remote/supabase_sync_engine.dart';
import '../../../../shared/presentation/widgets/focus_flow_choice_palette.dart';
import '../../../../shared/presentation/widgets/focus_flow_page.dart';
import '../../../goals/presentation/cubit/goals_cubit.dart';
import '../cubit/settings_cubit.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FocusFlowPage(
      onRefresh: () async {
        try {
          final syncEngine = context.read<SupabaseSyncEngine?>();
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
            final isWide = constraints.maxWidth > 900;

            final leftColumn = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _EventTriggersSection(),
                const SizedBox(height: FocusFlowSpacing.lg),
                const _DeliveryChannelsSection(),
                const SizedBox(height: FocusFlowSpacing.lg),
                const _DoNotDisturbHoursSection(),
                const SizedBox(height: FocusFlowSpacing.lg),
                const _SoundAndHapticsSection(),
              ],
            );

            final rightColumn = const _GoalTypesSettingsSection();

            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 8,
                    child: leftColumn,
                  ),
                  const SizedBox(width: FocusFlowSpacing.lg),
                  Expanded(
                    flex: 4,
                    child: rightColumn,
                  ),
                ],
              );
            } else {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  leftColumn,
                  const SizedBox(height: FocusFlowSpacing.lg),
                  rightColumn,
                ],
              );
            }
          },
        ),
      ],
    );
  }
}

class _PreferenceToggleRow extends StatelessWidget {
  const _PreferenceToggleRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: FocusFlowColors.surfaceLow,
            borderRadius: BorderRadius.circular(FocusFlowRadius.md),
          ),
          child: Icon(
            icon,
            color: FocusFlowColors.muted,
            size: 20,
          ),
        ),
        const SizedBox(width: FocusFlowSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: FocusFlowColors.brand,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: FocusFlowSpacing.xxs),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: FocusFlowColors.muted,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(width: FocusFlowSpacing.md),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: FocusFlowColors.brand,
          activeTrackColor: FocusFlowColors.brandSoft,
          inactiveThumbColor: Colors.white,
          inactiveTrackColor: FocusFlowColors.surfaceHigh,
        ),
      ],
    );
  }
}

class _EventTriggersSection extends StatelessWidget {
  const _EventTriggersSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        final cubit = context.read<SettingsCubit>();
        return FocusFlowCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.notifications_active_rounded, color: FocusFlowColors.brand, size: FocusFlowIconSize.md),
                  const SizedBox(width: FocusFlowSpacing.sm),
                  Text(
                    'Event Triggers',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: FocusFlowColors.brand,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: FocusFlowSpacing.lg),
              _PreferenceToggleRow(
                icon: Icons.timer_outlined,
                title: 'Task Deadlines',
                subtitle: 'Reminders for upcoming due dates and hard cutoffs.',
                value: state.taskDeadlines,
                onChanged: (val) => cubit.updateTaskDeadlines(val),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: FocusFlowSpacing.md),
                child: Divider(),
              ),
              _PreferenceToggleRow(
                icon: Icons.bolt_outlined,
                title: 'Streak Alerts',
                subtitle: 'Daily motivation to keep your momentum going.',
                value: state.streakAlerts,
                onChanged: (val) => cubit.updateStreakAlerts(val),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DeliveryChannelsSection extends StatelessWidget {
  const _DeliveryChannelsSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        final cubit = context.read<SettingsCubit>();
        return FocusFlowCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.send_rounded, color: FocusFlowColors.brand, size: FocusFlowIconSize.md),
                  const SizedBox(width: FocusFlowSpacing.sm),
                  Text(
                    'Delivery Channels',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: FocusFlowColors.brand,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: FocusFlowSpacing.lg),
              _PreferenceToggleRow(
                icon: Icons.phone_iphone_rounded,
                title: 'Mobile Notifications',
                subtitle: 'Instant alerts delivered directly to your connected mobile devices.',
                value: state.mobileNotifications,
                onChanged: (val) => cubit.updateMobileNotifications(val),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: FocusFlowSpacing.md),
                child: Divider(),
              ),
              _PreferenceToggleRow(
                icon: Icons.mail_outline_rounded,
                title: 'Email Digests',
                subtitle: 'Weekly summaries of your progress and upcoming goal milestones.',
                value: state.emailDigests,
                onChanged: (val) => cubit.updateEmailDigests(val),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: FocusFlowSpacing.md),
                child: Divider(),
              ),
              _PreferenceToggleRow(
                icon: Icons.desktop_windows_rounded,
                title: 'Desktop Notifications',
                subtitle: 'Receive alerts on your browser or desktop app while working.',
                value: state.desktopNotifications,
                onChanged: (val) => cubit.updateDesktopNotifications(val),
              ),
              if (!kIsWeb && Platform.isWindows) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: FocusFlowSpacing.md),
                  child: Divider(),
                ),
                _PreferenceToggleRow(
                  icon: Icons.power_settings_new_rounded,
                  title: 'Start with Windows',
                  subtitle: 'Launch FocusFlow silently in the system tray when Windows boots.',
                  value: state.windowsAutoStart,
                  onChanged: (val) => cubit.updateWindowsAutoStart(val),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _DoNotDisturbHoursSection extends StatelessWidget {
  const _DoNotDisturbHoursSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        final cubit = context.read<SettingsCubit>();
        final isEnabled = state.dndEnabled;

        return FocusFlowCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.bedtime_rounded, color: FocusFlowColors.brand, size: FocusFlowIconSize.md),
                      const SizedBox(width: FocusFlowSpacing.sm),
                      Text(
                        'Do Not Disturb Hours',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: FocusFlowColors.brand,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  Switch(
                    value: isEnabled,
                    onChanged: (val) => cubit.updateDndEnabled(val),
                    activeThumbColor: FocusFlowColors.brand,
                    activeTrackColor: FocusFlowColors.brandSoft,
                    inactiveThumbColor: Colors.white,
                    inactiveTrackColor: FocusFlowColors.surfaceHigh,
                  ),
                ],
              ),
              const SizedBox(height: FocusFlowSpacing.xs),
              Text(
                'Automatically silence non-critical notifications during your deep work or rest periods.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: FocusFlowColors.muted,
                    ),
              ),
              const SizedBox(height: FocusFlowSpacing.lg),
              Opacity(
                opacity: isEnabled ? 1.0 : 0.5,
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: isEnabled
                            ? () async {
                                final time = await showTimePicker(
                                  context: context,
                                  initialTime: state.dndStart,
                                );
                                if (time != null) {
                                  cubit.updateDndStart(time);
                                }
                              }
                            : null,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Start Time',
                          ),
                          child: Text(
                            '${state.dndStartHour.toString().padLeft(2, '0')}:${state.dndStartMinute.toString().padLeft(2, '0')}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: FocusFlowSpacing.md),
                    Expanded(
                      child: InkWell(
                        onTap: isEnabled
                            ? () async {
                                final time = await showTimePicker(
                                  context: context,
                                  initialTime: state.dndEnd,
                                );
                                if (time != null) {
                                  cubit.updateDndEnd(time);
                                }
                              }
                            : null,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'End Time',
                          ),
                          child: Text(
                            '${state.dndEndHour.toString().padLeft(2, '0')}:${state.dndEndMinute.toString().padLeft(2, '0')}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SoundAndHapticsSection extends StatefulWidget {
  const _SoundAndHapticsSection();

  @override
  State<_SoundAndHapticsSection> createState() => _SoundAndHapticsSectionState();
}

class _SoundAndHapticsSectionState extends State<_SoundAndHapticsSection> {
  late final AudioPlayer _audioPlayer;
  Timer? _previewTimer;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
  }

  @override
  void dispose() {
    _previewTimer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playSoundPreview({String? assetName, String? customPath}) async {
    try {
      await _audioPlayer.stop();
      _previewTimer?.cancel();
      if (customPath != null) {
        await _audioPlayer.play(DeviceFileSource(customPath));
      } else if (assetName != null && assetName != 'none') {
        await _audioPlayer.play(AssetSource('sounds/$assetName.wav'));
      }
      _previewTimer = Timer(const Duration(seconds: 5), () => _audioPlayer.stop());
    } catch (e) {
      debugPrint('Error playing sound preview: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        final cubit = context.read<SettingsCubit>();
        return FocusFlowCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.volume_up_rounded, color: FocusFlowColors.brand, size: FocusFlowIconSize.md),
                  const SizedBox(width: FocusFlowSpacing.sm),
                  Text(
                    'Sound & Haptics',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: FocusFlowColors.brand,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: FocusFlowSpacing.lg),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Mobile Notification Sound',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: FocusFlowColors.brand,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      if (state.notificationSound == 'chime' && state.customSoundPath == null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: FocusFlowColors.brandSoft,
                            borderRadius: BorderRadius.circular(FocusFlowRadius.sm),
                          ),
                          child: const Text(
                            'Default',
                            style: TextStyle(
                              color: FocusFlowColors.brand,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: FocusFlowSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          key: ValueKey('mobile_${state.notificationSound}'),
                          initialValue: state.notificationSound,
                          decoration: const InputDecoration(labelText: 'Select Preset'),
                          items: const [
                            DropdownMenuItem(value: 'default', child: Text('System Default')),
                            DropdownMenuItem(value: 'chime', child: Text('Calm Chime')),
                            DropdownMenuItem(value: 'bell', child: Text('Alert Bell')),
                            DropdownMenuItem(value: 'none', child: Text('None (Silent)')),
                          ],
                          onChanged: (val) async {
                            if (val != null) {
                              await cubit.updateNotificationSound(val);
                              await cubit.updateCustomNotificationSoundPath(null);
                              await _playSoundPreview(assetName: val);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: FocusFlowSpacing.md),
                      TextButton.icon(
                        onPressed: () async {
                          final result = await FilePicker.platform.pickFiles(type: FileType.audio);
                          if (result != null && result.files.single.path != null) {
                            final path = result.files.single.path!;
                            await cubit.updateCustomNotificationSoundPath(path);
                            await _playSoundPreview(customPath: path);
                          }
                        },
                        icon: const Icon(Icons.folder_open_rounded, size: 16),
                        label: const Text('Pick File'),
                        style: TextButton.styleFrom(
                          foregroundColor: FocusFlowColors.brand,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                  if (state.customSoundPath != null) ...[
                    const SizedBox(height: FocusFlowSpacing.xs),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: FocusFlowColors.surfaceLow,
                        borderRadius: BorderRadius.circular(FocusFlowRadius.sm),
                        border: Border.all(color: FocusFlowColors.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.audiotrack_rounded, size: FocusFlowIconSize.sm, color: FocusFlowColors.brand),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Custom: ${state.customSoundPath!.split(RegExp(r'[\\/]')).last}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: FocusFlowColors.ink,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 16, color: FocusFlowColors.danger),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => cubit.updateCustomNotificationSoundPath(null),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: FocusFlowSpacing.lg),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Desktop Notification Sound',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: FocusFlowColors.brand,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      if (state.desktopNotificationSound == 'chime' && state.customDesktopSoundPath == null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: FocusFlowColors.brandSoft,
                            borderRadius: BorderRadius.circular(FocusFlowRadius.sm),
                          ),
                          child: const Text(
                            'Default',
                            style: TextStyle(
                              color: FocusFlowColors.brand,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: FocusFlowSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          key: ValueKey('desktop_${state.desktopNotificationSound}'),
                          initialValue: state.desktopNotificationSound,
                          decoration: const InputDecoration(labelText: 'Select Preset'),
                          items: const [
                            DropdownMenuItem(value: 'default', child: Text('System Default')),
                            DropdownMenuItem(value: 'chime', child: Text('Calm Chime')),
                            DropdownMenuItem(value: 'bell', child: Text('Alert Bell')),
                            DropdownMenuItem(value: 'none', child: Text('None (Silent)')),
                          ],
                          onChanged: (val) async {
                            if (val != null) {
                              await cubit.updateDesktopNotificationSound(val);
                              await cubit.updateCustomDesktopNotificationSoundPath(null);
                              await _playSoundPreview(assetName: val);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: FocusFlowSpacing.md),
                      TextButton.icon(
                        onPressed: () async {
                          final result = await FilePicker.platform.pickFiles(type: FileType.audio);
                          if (result != null && result.files.single.path != null) {
                            final path = result.files.single.path!;
                            await cubit.updateCustomDesktopNotificationSoundPath(path);
                            await _playSoundPreview(customPath: path);
                          }
                        },
                        icon: const Icon(Icons.folder_open_rounded, size: 16),
                        label: const Text('Pick File'),
                        style: TextButton.styleFrom(
                          foregroundColor: FocusFlowColors.brand,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                  if (state.customDesktopSoundPath != null) ...[
                    const SizedBox(height: FocusFlowSpacing.xs),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: FocusFlowColors.surfaceLow,
                        borderRadius: BorderRadius.circular(FocusFlowRadius.sm),
                        border: Border.all(color: FocusFlowColors.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.audiotrack_rounded, size: FocusFlowIconSize.sm, color: FocusFlowColors.brand),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Custom: ${state.customDesktopSoundPath!.split(RegExp(r'[\\/]')).last}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: FocusFlowColors.ink,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 16, color: FocusFlowColors.danger),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => cubit.updateCustomDesktopNotificationSoundPath(null),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GoalTypesSettingsSection extends StatefulWidget {
  const _GoalTypesSettingsSection();

  @override
  State<_GoalTypesSettingsSection> createState() =>
      _GoalTypesSettingsSectionState();
}

class _GoalTypesSettingsSectionState extends State<_GoalTypesSettingsSection> {
  final _nameController = TextEditingController();
  Color _selectedColor = FocusFlowColors.brand;
  IconData _selectedIcon = Icons.track_changes_rounded;
  String? _editingId;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _edit(CustomGoalType type) {
    setState(() {
      _editingId = type.id;
      _nameController.text = type.name;
      _selectedColor = _parseColor(type.colorHex);
      _selectedIcon = FocusFlowIconMapper.parseIcon(type.iconCode);
    });
  }

  void _cancelEdit() {
    setState(() {
      _editingId = null;
      _nameController.clear();
      _selectedColor = FocusFlowColors.brand;
      _selectedIcon = Icons.track_changes_rounded;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GoalsCubit, GoalsState>(
      builder: (context, state) {
        return FocusFlowCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.category_outlined, color: FocusFlowColors.secondary),
                  const SizedBox(width: FocusFlowSpacing.sm),
                  Text(
                    'Goal Types',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: FocusFlowColors.brand,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: FocusFlowSpacing.xs),
              Text(
                'Manage custom goal type names, colors, and icons.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: FocusFlowColors.muted,
                    ),
              ),
              const SizedBox(height: FocusFlowSpacing.lg),
              for (final type in state.goalTypes) ...[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _parseColor(type.colorHex).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(FocusFlowRadius.md),
                    ),
                    child: Icon(
                      FocusFlowIconMapper.parseIcon(type.iconCode),
                      color: _parseColor(type.colorHex),
                      size: 20,
                    ),
                  ),
                  title: Text(
                    type.name,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: FocusFlowColors.ink,
                        ),
                  ),
                  subtitle: type.isDefault
                      ? Text(
                          'Default (Cannot be deleted)',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: FocusFlowColors.muted,
                              ),
                        )
                      : null,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => _edit(type),
                      ),
                      if (!type.isDefault)
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: FocusFlowColors.danger,
                          ),
                          onPressed: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Delete Goal Type?'),
                                content: const Text(
                                  'Any existing goals using this type will be moved to "Other".',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );
                            if (confirmed == true && context.mounted) {
                              await context.read<GoalsCubit>().deleteGoalType(
                                type.id,
                              );
                            }
                          },
                        ),
                    ],
                  ),
                ),
                const Divider(),
              ],
              const SizedBox(height: FocusFlowSpacing.lg),
              Text(
                _editingId == null ? 'Add New Type' : 'Edit Type',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: FocusFlowColors.brand,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: FocusFlowSpacing.sm),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Type Name',
                  hintText: 'e.g., Career Growth',
                ),
              ),
              const SizedBox(height: FocusFlowSpacing.md),
              Text(
                'Color Theme',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: FocusFlowColors.muted,
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const SizedBox(height: FocusFlowSpacing.xs),
              FocusFlowColorPalette(
                selectedColor: _selectedColor,
                onSelected: (c) => setState(() => _selectedColor = c),
              ),
              const SizedBox(height: FocusFlowSpacing.md),
              Text(
                'Icon Design',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: FocusFlowColors.muted,
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const SizedBox(height: FocusFlowSpacing.xs),
              FocusFlowIconPalette(
                selectedIcon: _selectedIcon,
                onSelected: (i) => setState(() => _selectedIcon = i),
              ),
              const SizedBox(height: FocusFlowSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (_editingId != null)
                    TextButton(
                      onPressed: _cancelEdit,
                      child: const Text('Cancel'),
                    ),
                  const SizedBox(width: FocusFlowSpacing.sm),
                  FocusFlowPrimaryButton(
                    label: _editingId == null ? 'Add Type' : 'Save Changes',
                    icon: _editingId == null
                        ? Icons.add_rounded
                        : Icons.save_rounded,
                    onPressed: () async {
                      final name = _nameController.text.trim();
                      if (name.isEmpty) return;
                      final colorHex =
                          '#${_selectedColor.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
                      final iconCode = FocusFlowIconMapper.reverseParseIcon(_selectedIcon);

                      final cubit = context.read<GoalsCubit>();
                      if (_editingId != null) {
                        await cubit.updateGoalType(
                          id: _editingId!,
                          name: name,
                          colorHex: colorHex,
                          iconCode: iconCode,
                        );
                      } else {
                        await cubit.addGoalType(
                          name: name,
                          colorHex: colorHex,
                          iconCode: iconCode,
                        );
                      }
                      _cancelEdit();
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

Color _parseColor(String hex) {
  var hexColor = hex.replaceAll('#', '');
  if (hexColor.length == 6) {
    hexColor = 'FF$hexColor';
  }
  return Color(int.tryParse(hexColor, radix: 16) ?? 0xFF8B95A7);
}
