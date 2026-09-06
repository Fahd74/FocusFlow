import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/data/focus_flow_repository.dart';
import '../../../core/domain/services/preferences_service.dart';
import '../../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../../app/theme/focus_flow_colors.dart';
import '../../../core/domain/focus_flow_models.dart';

class FocusFlowAvatar extends StatelessWidget {
  const FocusFlowAvatar({
    super.key,
    required this.size,
    this.borderColor,
    this.borderWidth = 0.0,
  });

  final double size;
  final Color? borderColor;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    final repository = context.read<FocusFlowRepository>();
    return StreamBuilder<FocusFlowSnapshot>(
      stream: repository.watchSnapshot(),
      initialData: repository.snapshot,
      builder: (context, snapshot) {
        final authState = context.watch<AuthCubit>().state;
        final isAuthenticated = authState is AuthAuthenticated;

        String? avatarType;
        String? avatarValue;

        if (isAuthenticated) {
          final profile = snapshot.data?.userProfile ?? repository.snapshot.userProfile;
          if (profile != null) {
            avatarType = profile.avatarType;
            avatarValue = profile.avatarType == 'upload' ? profile.avatarUrl : profile.avatarAsset;
          } else {
            final user = authState.user;
            avatarType = user.userMetadata?['avatar_type'] as String?;
            final url = user.userMetadata?['avatar_url'] as String?;
            final asset = user.userMetadata?['avatar_asset'] as String?;
            avatarValue = avatarType == 'upload' ? url : asset;
          }
        } else {
          final prefs = context.watch<PreferencesService>();
          avatarType = prefs.avatarType;
          avatarValue = prefs.avatarValue;
        }

        Widget avatarImage;

        if (avatarType == 'asset' && avatarValue != null && avatarValue.isNotEmpty) {
          avatarImage = Image.asset(
            avatarValue,
            key: ValueKey(avatarValue),
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Icon(
              Icons.person_rounded,
              size: size * 0.6,
              color: FocusFlowColors.quiet,
            ),
          );
        } else if (avatarType == 'upload' && avatarValue != null && avatarValue.isNotEmpty) {
          if (avatarValue.startsWith('http')) {
            avatarImage = Image.network(
              avatarValue,
              key: ValueKey(avatarValue),
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.person_rounded,
                size: size * 0.6,
                color: FocusFlowColors.quiet,
              ),
            );
          } else {
            avatarImage = Image.file(
              File(avatarValue),
              key: ValueKey(avatarValue),
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.person_rounded,
                size: size * 0.6,
                color: FocusFlowColors.quiet,
              ),
            );
          }
        } else {
          avatarImage = Icon(
            Icons.person_rounded,
            size: size * 0.6,
            color: FocusFlowColors.quiet,
          );
        }

        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: FocusFlowColors.brand.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipOval(
                child: SizedBox.expand(child: avatarImage),
              ),
              if (borderWidth > 0)
                IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: borderColor ?? FocusFlowColors.border,
                        width: borderWidth,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
