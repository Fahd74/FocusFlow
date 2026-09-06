import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/focus_flow_colors.dart';
import '../../../../app/theme/focus_flow_tokens.dart';
import '../../../../shared/presentation/widgets/focus_flow_button.dart';
import '../../../../shared/presentation/widgets/focus_flow_card.dart';
import '../../../../shared/presentation/widgets/focus_flow_page.dart';
import '../../../../shared/presentation/widgets/focus_flow_avatar.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../../core/domain/services/preferences_service.dart';
import '../../../../core/data/focus_flow_repository.dart';
import '../../../../core/domain/focus_flow_models.dart';
import '../../../../shared/presentation/screens/image_crop_screen.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _displayNameController;
  bool _isLoading = false;
  String _email = '';

  String? _selectedAssetAvatar;
  String? _selectedUploadPath;

  final List<String> _presets = [
    'assets/images/avatars/chicken.png',
    'assets/images/avatars/deer.png',
    'assets/images/avatars/dog.png',
    'assets/images/avatars/jaguar.png',
    'assets/images/avatars/lion.png',
    'assets/images/avatars/macaw.png',
    'assets/images/avatars/panda.png',
    'assets/images/avatars/rabbit.png',
    'assets/images/avatars/sloth.png',
  ];

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthCubit>().state;
    final isAuth = authState is AuthAuthenticated;

    if (isAuth) {
      final repository = context.read<FocusFlowRepository>();
      final profile = repository.snapshot.userProfile;
      final user = authState.user;

      String fullName = profile?.fullName ?? user.userMetadata?['full_name'] as String? ?? '';
      String firstName = profile?.firstName ?? '';
      String lastName = profile?.lastName ?? '';

      if (firstName.isEmpty && lastName.isEmpty && fullName.isNotEmpty) {
        final parts = fullName.split(' ');
        firstName = parts.first;
        lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
      }

      _firstNameController = TextEditingController(text: firstName);
      _lastNameController = TextEditingController(text: lastName);
      _displayNameController = TextEditingController(text: fullName);
      _email = profile?.email ?? user.email ?? '';
    } else {
      final prefs = context.read<PreferencesService>();
      String fullName = prefs.guestName;
      String firstName = prefs.guestFirstName;
      String lastName = prefs.guestLastName;

      if (firstName.isEmpty && lastName.isEmpty && fullName.isNotEmpty) {
        final parts = fullName.split(' ');
        firstName = parts.first;
        lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
      }

      _firstNameController = TextEditingController(text: firstName);
      _lastNameController = TextEditingController(text: lastName);
      _displayNameController = TextEditingController(text: fullName);
      _email = prefs.guestEmail;
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authState = context.read<AuthCubit>().state;
      final isAuthenticated = authState is AuthAuthenticated;
      final cubit = context.read<AuthCubit>();
      final prefs = context.read<PreferencesService>();
      final repository = context.read<FocusFlowRepository>();

      final firstName = _firstNameController.text.trim();
      final lastName = _lastNameController.text.trim();
      final displayName = _displayNameController.text.trim();

      String? finalAvatarType;
      String? finalAvatarUrl;
      String? finalAvatarAsset;

      if (_selectedUploadPath != null) {
        if (isAuthenticated) {
          final userId = authState.user.id;
          final file = File(_selectedUploadPath!);
          final fileExtension = _selectedUploadPath!.split('.').last;
          final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
          final storagePath = '$userId/$fileName';

          final supabase = Supabase.instance.client;
          await supabase.storage.from('avatars').upload(storagePath, file);
          final publicUrl = supabase.storage.from('avatars').getPublicUrl(storagePath);

          finalAvatarType = 'upload';
          finalAvatarUrl = publicUrl;
          finalAvatarAsset = null;
        } else {
          finalAvatarType = 'upload';
          finalAvatarUrl = _selectedUploadPath;
          finalAvatarAsset = null;
        }
      } else if (_selectedAssetAvatar != null) {
        finalAvatarType = 'asset';
        finalAvatarUrl = null;
        finalAvatarAsset = _selectedAssetAvatar;
      } else {
        if (isAuthenticated) {
          final profile = repository.snapshot.userProfile;
          if (profile != null) {
            finalAvatarType = profile.avatarType;
            finalAvatarUrl = profile.avatarUrl;
            finalAvatarAsset = profile.avatarAsset;
          }
        } else {
          finalAvatarType = prefs.avatarType;
          finalAvatarUrl = null;
          finalAvatarAsset = prefs.avatarValue;
        }
      }

      if (isAuthenticated) {
        final userId = authState.user.id;

        final success = await cubit.updateProfile(
          firstName: firstName,
          lastName: lastName,
          displayName: displayName,
          avatarType: finalAvatarType,
          avatarUrl: finalAvatarUrl,
          avatarAsset: finalAvatarAsset,
        );

        if (success) {
          final currentProfile = repository.snapshot.userProfile;
          final updatedProfile = UserProfile(
            id: userId,
            fullName: displayName,
            firstName: firstName,
            lastName: lastName,
            email: _email,
            avatarType: finalAvatarType,
            avatarUrl: finalAvatarUrl,
            avatarAsset: finalAvatarAsset,
            createdAt: currentProfile?.createdAt ?? DateTime.now(),
            updatedAt: DateTime.now(),
          );
          await repository.upsertUserProfile(updatedProfile);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profile updated successfully!'),
                backgroundColor: FocusFlowColors.success,
              ),
            );
            context.go(AppRoutes.profile);
          }
        }
      } else {
        await prefs.setGuestName(displayName);
        await prefs.setGuestFirstName(firstName);
        await prefs.setGuestLastName(lastName);
        if (_selectedUploadPath != null) {
          await prefs.setAvatarType('upload');
          await prefs.setAvatarValue(_selectedUploadPath!);
        } else if (_selectedAssetAvatar != null) {
          await prefs.setAvatarType('asset');
          await prefs.setAvatarValue(_selectedAssetAvatar!);
        }

        if (mounted) {
          context.read<AuthCubit>().updateGuestProfile(
            firstName: firstName,
            lastName: lastName,
            displayName: displayName,
            email: _email,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Guest profile saved locally!'),
              backgroundColor: FocusFlowColors.success,
            ),
          );
          context.go(AppRoutes.profile);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving changes: $e'),
            backgroundColor: FocusFlowColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final isGuest = authState is! AuthAuthenticated;

    final breadcrumbs = Row(
      children: [
        InkWell(
          onTap: () => context.go(AppRoutes.profile),
          child: const Text(
            'Profile',
            style: TextStyle(
              fontSize: 12,
              color: FocusFlowColors.quiet,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 6),
        const Icon(
          Icons.chevron_right_rounded,
          size: 14,
          color: FocusFlowColors.quiet,
        ),
        const SizedBox(width: 6),
        const Text(
          'Edit Profile',
          style: TextStyle(
            fontSize: 12,
            color: FocusFlowColors.brand,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );

    Widget avatarWidget;
    if (_selectedUploadPath != null) {
      avatarWidget = Image.file(
        File(_selectedUploadPath!),
        width: 100,
        height: 100,
        fit: BoxFit.cover,
      );
    } else if (_selectedAssetAvatar != null) {
      avatarWidget = Image.asset(
        _selectedAssetAvatar!,
        width: 100,
        height: 100,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const Icon(
          Icons.person_rounded,
          size: 60,
          color: FocusFlowColors.quiet,
        ),
      );
    } else {
      avatarWidget = const FocusFlowAvatar(
        size: 100,
        borderWidth: 3,
        borderColor: FocusFlowColors.border,
      );
    }

    final avatarDisplay = Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: FocusFlowColors.brand.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipOval(
            child: SizedBox.expand(child: avatarWidget),
          ),
          IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: FocusFlowColors.border,
                  width: 3,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    final inlineAvatarPicker = FocusFlowCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CHOOSE PRESET AVATAR',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: FocusFlowColors.muted,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _presets.length,
              itemBuilder: (context, index) {
                final asset = _presets[index];
                final isSelected = _selectedAssetAvatar == asset ||
                    (_selectedAssetAvatar == null && _selectedUploadPath == null &&
                        (isGuest ? (context.read<PreferencesService>().avatarType == 'asset' && context.read<PreferencesService>().avatarValue == asset) : (context.read<FocusFlowRepository>().snapshot.userProfile?.avatarType == 'asset' && context.read<FocusFlowRepository>().snapshot.userProfile?.avatarAsset == asset)));

                return GestureDetector(
                  onTap: _isLoading ? null : () {
                    setState(() {
                      _selectedAssetAvatar = asset;
                      _selectedUploadPath = null;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? FocusFlowColors.brand : Colors.transparent,
                        width: 2.5,
                      ),
                    ),
                    padding: const EdgeInsets.all(2),
                    child: CircleAvatar(
                      radius: 24,
                      backgroundColor: FocusFlowColors.surfaceLow,
                      child: ClipOval(
                        child: Image.asset(
                          asset,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const Icon(
                            Icons.person_rounded,
                            color: FocusFlowColors.quiet,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          const Center(
            child: Text(
              '— or —',
              style: TextStyle(fontSize: 11, color: FocusFlowColors.quiet),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: OutlinedButton.icon(
              onPressed: _isLoading ? null : () async {
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                final navigator = Navigator.of(context);
                try {
                  String? imagePath;
                  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
                    final result = await FilePicker.platform.pickFiles(
                      type: FileType.image,
                      allowMultiple: false,
                    );
                    if (result != null && result.files.isNotEmpty && result.files.single.path != null) {
                      imagePath = result.files.single.path;
                    }
                  } else {
                    final picker = ImagePicker();
                    final image = await picker.pickImage(
                      source: ImageSource.gallery,
                      imageQuality: 80,
                      maxWidth: 512,
                      maxHeight: 512,
                    );
                    if (image != null) {
                      imagePath = image.path;
                    }
                  }

                  if (imagePath != null && imagePath.isNotEmpty) {
                    await Future.delayed(const Duration(milliseconds: 200));
                    if (!mounted) return;

                    final croppedPath = await navigator.push<String?>(
                      MaterialPageRoute(
                        builder: (context) => ImageCropScreen(imageFile: File(imagePath!)),
                      ),
                    );
                    if (croppedPath != null && mounted) {
                      setState(() {
                        _selectedUploadPath = croppedPath;
                        _selectedAssetAvatar = null;
                      });
                    }
                  }
                } catch (e) {
                  debugPrint('Error picking image: $e');
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('Failed to pick or crop image: $e'),
                      backgroundColor: FocusFlowColors.danger,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.photo_library_outlined, size: 16, color: FocusFlowColors.brand),
              label: const Text(
                'Upload from Gallery',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: FocusFlowColors.brand,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: FocusFlowColors.border),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(FocusFlowRadius.md)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );

    final formCard = FocusFlowCard(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'FIRST NAME',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: FocusFlowColors.muted,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              key: const Key('edit_profile_first_name'),
              controller: _firstNameController,
              enabled: !_isLoading,
              style: const TextStyle(color: FocusFlowColors.ink),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your first name';
                }
                return null;
              },
              decoration: InputDecoration(
                hintText: 'Enter your first name...',
                prefixIcon: const Icon(Icons.person_outline_rounded, color: FocusFlowColors.quiet, size: 20),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                filled: true,
                fillColor: FocusFlowColors.surfaceLow,
                border: OutlineInputBorder(
                  borderSide: const BorderSide(color: FocusFlowColors.border),
                  borderRadius: BorderRadius.circular(FocusFlowRadius.md),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: FocusFlowColors.border),
                  borderRadius: BorderRadius.circular(FocusFlowRadius.md),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: FocusFlowColors.brand, width: 1.5),
                  borderRadius: BorderRadius.circular(FocusFlowRadius.md),
                ),
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'LAST NAME',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: FocusFlowColors.muted,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              key: const Key('edit_profile_last_name'),
              controller: _lastNameController,
              enabled: !_isLoading,
              style: const TextStyle(color: FocusFlowColors.ink),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your last name';
                }
                return null;
              },
              decoration: InputDecoration(
                hintText: 'Enter your last name...',
                prefixIcon: const Icon(Icons.person_outline_rounded, color: FocusFlowColors.quiet, size: 20),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                filled: true,
                fillColor: FocusFlowColors.surfaceLow,
                border: OutlineInputBorder(
                  borderSide: const BorderSide(color: FocusFlowColors.border),
                  borderRadius: BorderRadius.circular(FocusFlowRadius.md),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: FocusFlowColors.border),
                  borderRadius: BorderRadius.circular(FocusFlowRadius.md),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: FocusFlowColors.brand, width: 1.5),
                  borderRadius: BorderRadius.circular(FocusFlowRadius.md),
                ),
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'DISPLAY NAME (FULL NAME)',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: FocusFlowColors.muted,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              key: const Key('edit_profile_display_name'),
              controller: _displayNameController,
              enabled: !_isLoading,
              style: const TextStyle(color: FocusFlowColors.ink),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your display name';
                }
                return null;
              },
              decoration: InputDecoration(
                hintText: 'Enter your display name...',
                prefixIcon: const Icon(Icons.badge_outlined, color: FocusFlowColors.quiet, size: 20),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                filled: true,
                fillColor: FocusFlowColors.surfaceLow,
                border: OutlineInputBorder(
                  borderSide: const BorderSide(color: FocusFlowColors.border),
                  borderRadius: BorderRadius.circular(FocusFlowRadius.md),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: FocusFlowColors.border),
                  borderRadius: BorderRadius.circular(FocusFlowRadius.md),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: FocusFlowColors.brand, width: 1.5),
                  borderRadius: BorderRadius.circular(FocusFlowRadius.md),
                ),
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'EMAIL ADDRESS',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: FocusFlowColors.muted,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: FocusFlowColors.surfaceLow,
                border: Border.all(color: FocusFlowColors.border),
                borderRadius: BorderRadius.circular(FocusFlowRadius.md),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock_outline_rounded, color: FocusFlowColors.quiet, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _email,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: FocusFlowColors.quiet,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return FocusFlowPage(
      title: '',
      children: [
        Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                breadcrumbs,
                const SizedBox(height: FocusFlowSpacing.md),
                Center(child: avatarDisplay),
                const SizedBox(height: FocusFlowSpacing.xl),
                inlineAvatarPicker,
                const SizedBox(height: FocusFlowSpacing.xl),
                formCard,
                const SizedBox(height: 24),
                FocusFlowPrimaryButton(
                  label: _isLoading ? 'Saving...' : 'Save Changes',
                  icon: _isLoading ? null : Icons.save_rounded,
                  onPressed: _isLoading ? null : _saveChanges,
                  expanded: true,
                ),
                const SizedBox(height: 16),
                Center(
                  child: InkWell(
                    onTap: _isLoading ? null : () => context.go(AppRoutes.profile),
                    child: const Text(
                      'Cancel and return to profile',
                      style: TextStyle(
                        fontSize: 12,
                        color: FocusFlowColors.quiet,
                        decoration: TextDecoration.underline,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
