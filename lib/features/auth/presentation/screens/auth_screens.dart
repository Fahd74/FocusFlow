import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/focus_flow_colors.dart';
import '../../../../app/theme/focus_flow_tokens.dart';
import '../../../../shared/presentation/widgets/focus_flow_button.dart';
import '../../../../shared/presentation/widgets/focus_flow_logo.dart';
import '../cubit/auth_cubit.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
        } else if (state is AuthAuthenticated) {
          context.go(AppRoutes.dashboard);
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;
        return _AuthScaffold(
          title: 'Welcome Back',
          subtitle: 'Sign in to continue your focus journey.',
          primaryAction: isLoading ? 'Logging In...' : 'Log In',
          secondaryAction: 'Create account',
          fields: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email Address',
                prefixIcon: Icon(Icons.mail_outline_rounded),
              ),
              keyboardType: TextInputType.emailAddress,
              enabled: !isLoading,
            ),
            const SizedBox(height: FocusFlowSpacing.md),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                prefixIcon: Icon(Icons.lock_outline_rounded),
              ),
              enabled: !isLoading,
            ),
            const SizedBox(height: FocusFlowSpacing.lg),
            FocusFlowSecondaryButton(
              label: 'Continue as Guest',
              icon: Icons.person_outline_rounded,
              onPressed: () {
                context.read<AuthCubit>().continueAsGuest();
                context.go(AppRoutes.dashboard);
              },
              expanded: true,
            ),
          ],
          onPrimary: isLoading
              ? null
              : () {
                  final email = _emailController.text.trim();
                  final pass = _passwordController.text;
                  if (email.isEmpty || pass.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter email and password')),
                    );
                    return;
                  }
                  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                  if (!emailRegex.hasMatch(email)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter a valid email address')),
                    );
                    return;
                  }
                  context.read<AuthCubit>().signIn(email, pass);
                },
          onSecondary: () => context.go(AppRoutes.signup),
          footer: TextButton(
            onPressed: () => context.go(AppRoutes.forgotPassword),
            child: const Text('Forgot Password?'),
          ),
        );
      },
    );
  }
}

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
        } else if (state is AuthAuthenticated) {
          context.go(AppRoutes.dashboard);
        } else if (state is AuthEmailConfirmationRequired) {
          context.go(
            AppRoutes.checkEmail,
            extra:
                'We sent a confirmation link to your email. Please check your inbox and spam folder.',
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;
        return _AuthScaffold(
          title: 'Create your account',
          subtitle: 'Start breaking your goals into small, achievable tasks today.',
          primaryAction: isLoading ? 'Creating...' : 'Create Account',
          secondaryAction: 'Log in',
          fields: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
              enabled: !isLoading,
            ),
            const SizedBox(height: FocusFlowSpacing.md),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email Address',
                prefixIcon: Icon(Icons.mail_outline_rounded),
              ),
              keyboardType: TextInputType.emailAddress,
              enabled: !isLoading,
            ),
            const SizedBox(height: FocusFlowSpacing.md),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 420;
                final password = TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password'),
                  enabled: !isLoading,
                );
                final confirm = TextField(
                  controller: _confirmController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Confirm'),
                  enabled: !isLoading,
                );
                if (!wide) {
                  return Column(
                    children: [
                      password,
                      const SizedBox(height: FocusFlowSpacing.md),
                      confirm,
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: password),
                    const SizedBox(width: FocusFlowSpacing.md),
                    Expanded(child: confirm),
                  ],
                );
              },
            ),
          ],
          onPrimary: isLoading
              ? null
              : () {
                  final name = _nameController.text.trim();
                  final email = _emailController.text.trim();
                  final password = _passwordController.text;
                  final confirm = _confirmController.text;

                  if (name.isEmpty || email.isEmpty || password.isEmpty || confirm.isEmpty) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('All fields are required')));
                    return;
                  }
                  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                  if (!emailRegex.hasMatch(email)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter a valid email address')),
                    );
                    return;
                  }
                  if (password != confirm) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
                    return;
                  }
                  context.read<AuthCubit>().signUp(email, password, name);
                },
          onSecondary: () => context.go(AppRoutes.login),
        );
      },
    );
  }
}

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;
        return _AuthScaffold(
          title: 'Reset Password',
          subtitle: 'Enter the email address associated with your FocusFlow account.',
          primaryAction: isLoading ? 'Sending...' : 'Send Reset Link',
          secondaryAction: 'Back to login',
          fields: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email Address',
                prefixIcon: Icon(Icons.mail_outline_rounded),
              ),
              keyboardType: TextInputType.emailAddress,
              enabled: !isLoading,
            ),
          ],
          onPrimary: isLoading
              ? null
              : () async {
                  final email = _emailController.text.trim();
                  if (email.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter your email address')),
                    );
                    return;
                  }
                  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                  if (!emailRegex.hasMatch(email)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter a valid email address')),
                    );
                    return;
                  }
                   String? redirectTo;
                   if (kIsWeb) {
                     redirectTo = '${Uri.base.origin}${AppRoutes.resetPassword}';
                   } else {
                     redirectTo = 'focusflow://reset-password';
                   }
                   final success = await context.read<AuthCubit>().resetPassword(email, redirectTo: redirectTo);
                   if (success && context.mounted) {
                     context.go(
                       AppRoutes.checkEmail,
                       extra:
                           'We sent a reset link to your inbox. Please check your email and spam folder.',
                     );
                   }
                },
          onSecondary: () => context.go(AppRoutes.login),
          leading: TextButton.icon(
            onPressed: () => context.go(AppRoutes.login),
            icon: const Icon(Icons.arrow_back_rounded),
            label: const Text('Back'),
          ),
        );
      },
    );
  }
}

class CheckEmailScreen extends StatelessWidget {
  const CheckEmailScreen({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(FocusFlowSpacing.lg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(44),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: FocusFlowColors.brandSoft,
                      ),
                      child: const Icon(
                        Icons.mark_email_read_outlined,
                        color: FocusFlowColors.brand,
                        size: 34,
                      ),
                    ),
                    const SizedBox(height: FocusFlowSpacing.lg),
                    Text(
                      'Check your email',
                      style: Theme.of(context).textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: FocusFlowSpacing.sm),
                    Text(
                      message ??
                          'We sent a link to your email. Please check your inbox and spam folder.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: FocusFlowSpacing.xl),
                    FocusFlowPrimaryButton(
                      label: 'Back to Login',
                      onPressed: () => context.go(AppRoutes.login),
                      expanded: true,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthScaffold extends StatelessWidget {
  const _AuthScaffold({
    required this.title,
    required this.subtitle,
    required this.primaryAction,
    required this.secondaryAction,
    required this.fields,
    this.onPrimary,
    this.onSecondary,
    this.footer,
    this.leading,
  });

  final String title;
  final String subtitle;
  final String primaryAction;
  final String secondaryAction;
  final List<Widget> fields;
  final VoidCallback? onPrimary;
  final VoidCallback? onSecondary;
  final Widget? footer;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 900;

    if (isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            // ── Left brand panel – Connectivity Blue ────────────────
            Expanded(
              child: Container(
                color: FocusFlowColors.brand,
                child: Padding(
                  padding: const EdgeInsets.all(60),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.asset(
                        'assets/images/logo.png',
                        width: 56,
                        height: 56,
                        fit: BoxFit.contain,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'FocusFlow',
                        style: const TextStyle(
                          fontFamily: 'SpaceGrotesk',
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Organize your goals.\nTrack your progress.\nStay in flow.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 16,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 40),
                      // Feature bullets
                      _BrandBullet(
                        icon: Icons.track_changes_rounded,
                        text: 'Goal-driven task management',
                      ),
                      const SizedBox(height: 16),
                      _BrandBullet(
                        icon: Icons.notifications_active_rounded,
                        text: 'Smart reminders & alerts',
                      ),
                      const SizedBox(height: 16),
                      _BrandBullet(
                        icon: Icons.cloud_sync_rounded,
                        text: 'Sync across all your devices',
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // ── Right form panel ─────────────────────────────────────
            Expanded(
              child: Container(
                color: FocusFlowColors.canvas,
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(FocusFlowSpacing.xl),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (leading != null) ...[
                            Align(alignment: Alignment.centerLeft, child: leading),
                            const SizedBox(height: FocusFlowSpacing.md),
                          ],
                          Text(title, style: Theme.of(context).textTheme.headlineMedium),
                          const SizedBox(height: FocusFlowSpacing.xs),
                          Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
                          const SizedBox(height: FocusFlowSpacing.xl),
                          ...fields,
                          const SizedBox(height: FocusFlowSpacing.lg),
                          FocusFlowPrimaryButton(
                            label: primaryAction,
                            onPressed: onPrimary,
                            expanded: true,
                          ),
                          const SizedBox(height: FocusFlowSpacing.sm),
                          if (footer != null)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                TextButton(
                                  onPressed: onSecondary,
                                  child: Text(secondaryAction),
                                ),
                                footer!,
                              ],
                            )
                          else
                            TextButton(
                              onPressed: onSecondary,
                              child: Text(secondaryAction),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Mobile – centered card layout
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(FocusFlowSpacing.lg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (leading != null) ...[
                      Align(alignment: Alignment.centerLeft, child: leading),
                      const SizedBox(height: FocusFlowSpacing.md),
                    ],
                    const Center(child: FocusFlowLogo(compact: true)),
                    const SizedBox(height: FocusFlowSpacing.xl),
                    Text(
                      title,
                      style: Theme.of(context).textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: FocusFlowSpacing.sm),
                    Text(subtitle, textAlign: TextAlign.center),
                    const SizedBox(height: FocusFlowSpacing.xl),
                    ...fields,
                    const SizedBox(height: FocusFlowSpacing.lg),
                    FocusFlowPrimaryButton(
                      label: primaryAction,
                      onPressed: onPrimary,
                      expanded: true,
                    ),
                    const SizedBox(height: FocusFlowSpacing.sm),
                    if (footer != null)
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        runSpacing: FocusFlowSpacing.xs,
                        children: [
                          TextButton(
                            onPressed: onSecondary,
                            child: Text(secondaryAction),
                          ),
                          footer!,
                        ],
                      )
                    else
                      TextButton(
                        onPressed: onSecondary,
                        child: Text(secondaryAction),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandBullet extends StatelessWidget {
  const _BrandBullet({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
        } else if (state is AuthAuthenticated || state is AuthUnauthenticated) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Password updated successfully')));
          context.go(AppRoutes.dashboard);
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;
        return _AuthScaffold(
          title: 'Set New Password',
          subtitle: 'Create a strong password for your account.',
          primaryAction: isLoading ? 'Updating...' : 'Update Password',
          secondaryAction: 'Cancel and login',
          fields: [
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New Password',
                prefixIcon: Icon(Icons.lock_outline_rounded),
              ),
              enabled: !isLoading,
            ),
            const SizedBox(height: FocusFlowSpacing.md),
            TextField(
              controller: _confirmController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm Password',
                prefixIcon: Icon(Icons.lock_outline_rounded),
              ),
              enabled: !isLoading,
            ),
          ],
          onPrimary: isLoading
              ? null
              : () async {
                  final password = _passwordController.text;
                  final confirm = _confirmController.text;

                  if (password.isEmpty || confirm.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please fill in both fields')),
                    );
                    return;
                  }
                  if (password != confirm) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
                    return;
                  }
                  if (password.length < 6) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Password must be at least 6 characters')),
                    );
                    return;
                  }
                  final success = await context.read<AuthCubit>().updatePassword(password);
                  if (success && context.mounted) {
                    context.go(AppRoutes.dashboard);
                  }
                },
          onSecondary: () => context.go(AppRoutes.login),
        );
      },
    );
  }
}
