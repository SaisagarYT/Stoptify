import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/route_paths.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/app_logo_badge.dart';
import '../../widgets/common/monochrome_button.dart';
import '../../widgets/common/monochrome_text_field.dart';
import '../../widgets/common/saas_tab_switcher.dart';

// Modern premium SaaS Authentication screen with responsive tab switching
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> with SingleTickerProviderStateMixin {
  int _selectedTab = 0; // 0: Sign In, 1: Create Account

  // Sign In controllers
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  final _loginFormKey = GlobalKey<FormState>();
  bool _rememberMe = true;

  // Register controllers
  final _registerNameController = TextEditingController();
  final _registerEmailController = TextEditingController();
  final _registerPasswordController = TextEditingController();
  final _registerConfirmPasswordController = TextEditingController();
  final _registerFormKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _registerNameController.dispose();
    _registerEmailController.dispose();
    _registerPasswordController.dispose();
    _registerConfirmPasswordController.dispose();
    super.dispose();
  }

  // Handles Sign In submission
  Future<void> _handleSignIn() async {
    if (!_loginFormKey.currentState!.validate()) return;
    final ok = await ref.read(authProvider.notifier).login(
          email: _loginEmailController.text.trim(),
          password: _loginPasswordController.text,
        );
    if (ok && mounted) {
      context.go(RoutePaths.resumeIntake);
    }
  }

  // Handles Registration submission
  Future<void> _handleRegister() async {
    if (!_registerFormKey.currentState!.validate()) return;
    if (_registerPasswordController.text != _registerConfirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match.')),
      );
      return;
    }

    final ok = await ref.read(authProvider.notifier).register(
          name: _registerNameController.text.trim(),
          email: _registerEmailController.text.trim(),
          password: _registerPasswordController.text,
        );
    if (ok && mounted) {
      context.go(RoutePaths.skillBaseline);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Stack(
          children: [
            // --- Ambient SaaS Top Radial Glow ---
            Positioned(
              top: -80,
              left: 0,
              right: 0,
              height: 340,
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topCenter,
                    radius: 0.9,
                    colors: [
                      const Color(0xFF282834).withValues(alpha: 0.45),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 430),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // --- Brand Section ---
                        Center(
                          child: Column(
                            children: [
                              const AppLogoBadge(size: 60)
                                  .animate()
                                  .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1), duration: 400.ms, curve: Curves.easeOutBack),
                              const SizedBox(height: 16),
                              Text(
                                'Stoptify',
                                style: AppTypography.heading(
                                  fontSize: 32,
                                  weight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Mastery through focus. Knowing when to stop.',
                                textAlign: TextAlign.center,
                                style: AppTypography.body(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(duration: 350.ms).slideY(begin: -0.05, end: 0),

                        const SizedBox(height: 32),

                        // --- Interactive SaaS Card ---
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFF2E2E38), width: 1.2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.45),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Top Tab Switcher
                              SaasTabSwitcher(
                                tabs: const ['Sign In', 'Create Account'],
                                selectedIndex: _selectedTab,
                                onChanged: (index) {
                                  setState(() => _selectedTab = index);
                                },
                              ),

                              const SizedBox(height: 24),

                              // Animated Form Crossfade & Slide
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 280),
                                switchInCurve: Curves.easeOutCubic,
                                switchOutCurve: Curves.easeInCubic,
                                transitionBuilder: (child, animation) {
                                  return FadeTransition(
                                    opacity: animation,
                                    child: SlideTransition(
                                      position: Tween<Offset>(
                                        begin: const Offset(0, 0.04),
                                        end: Offset.zero,
                                      ).animate(animation),
                                      child: child,
                                    ),
                                  );
                                },
                                child: _selectedTab == 0
                                    ? _buildSignInForm(authState)
                                    : _buildRegisterForm(authState),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(delay: 100.ms, duration: 400.ms).slideY(begin: 0.04, end: 0),

                        const SizedBox(height: 24),

                        // Subtle Footer Note
                        Center(
                          child: Text(
                            'AI-driven curriculum with strict Definition of Done gates.',
                            textAlign: TextAlign.center,
                            style: AppTypography.body(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Sign In Form View
  Widget _buildSignInForm(AuthState authState) {
    return Form(
      key: _loginFormKey,
      child: Column(
        key: const ValueKey('sign_in_form'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Welcome back',
            style: AppTypography.heading(
              fontSize: 20,
              weight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Enter your credentials to access your roadmaps',
            style: AppTypography.body(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 22),

          MonochromeTextField(
            controller: _loginEmailController,
            label: 'Email address',
            hint: 'name@example.com',
            prefixIcon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Email is required.';
              if (!v.contains('@') || !v.contains('.')) return 'Enter a valid email.';
              return null;
            },
          ),

          const SizedBox(height: 16),

          MonochromeTextField(
            controller: _loginPasswordController,
            label: 'Password',
            hint: '••••••••',
            prefixIcon: Icons.lock_outline_rounded,
            isPassword: true,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Password is required.';
              if (v.length < 6) return 'Password must be at least 6 characters.';
              return null;
            },
          ),

          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: () => setState(() => _rememberMe = !_rememberMe),
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: Checkbox(
                          value: _rememberMe,
                          onChanged: (v) => setState(() => _rememberMe = v ?? true),
                          activeColor: AppColors.buttonPrimary,
                          checkColor: AppColors.buttonText,
                          side: const BorderSide(color: AppColors.borderStrong, width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Remember me',
                        style: AppTypography.body(fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
              Text(
                'Forgot password?',
                style: AppTypography.body(
                  fontSize: 13,
                  weight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),

          if (authState.error != null) ...[
            const SizedBox(height: 16),
            _buildErrorBanner(authState.error!),
          ],

          const SizedBox(height: 24),

          MonochromeButton(
            label: 'Sign In',
            icon: Icons.arrow_forward_rounded,
            isLoading: authState.isLoading,
            onPressed: _handleSignIn,
          ),
        ],
      ),
    );
  }

  // Register Form View
  Widget _buildRegisterForm(AuthState authState) {
    return Form(
      key: _registerFormKey,
      child: Column(
        key: const ValueKey('register_form'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Create an account',
            style: AppTypography.heading(
              fontSize: 20,
              weight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Start your focused journey with verifiable stop gates',
            style: AppTypography.body(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 22),

          MonochromeTextField(
            controller: _registerNameController,
            label: 'Full Name',
            hint: 'Sai Sagar',
            prefixIcon: Icons.person_outline_rounded,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Full name is required.';
              if (v.trim().length < 2) return 'Full name must be at least 2 characters.';
              return null;
            },
          ),

          const SizedBox(height: 16),

          MonochromeTextField(
            controller: _registerEmailController,
            label: 'Email address',
            hint: 'name@example.com',
            prefixIcon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Email is required.';
              if (!v.contains('@') || !v.contains('.')) return 'Enter a valid email.';
              return null;
            },
          ),

          const SizedBox(height: 16),

          MonochromeTextField(
            controller: _registerPasswordController,
            label: 'Password',
            hint: 'At least 6 characters',
            prefixIcon: Icons.lock_outline_rounded,
            isPassword: true,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Password is required.';
              if (v.length < 6) return 'Password must be at least 6 characters.';
              return null;
            },
          ),

          const SizedBox(height: 16),

          MonochromeTextField(
            controller: _registerConfirmPasswordController,
            label: 'Confirm Password',
            hint: 'Re-enter your password',
            prefixIcon: Icons.lock_outline_rounded,
            isPassword: true,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Confirm your password.';
              if (v != _registerPasswordController.text) return 'Passwords do not match.';
              return null;
            },
          ),

          if (authState.error != null) ...[
            const SizedBox(height: 16),
            _buildErrorBanner(authState.error!),
          ],

          const SizedBox(height: 24),

          MonochromeButton(
            label: 'Create Account',
            icon: Icons.arrow_forward_rounded,
            isLoading: authState.isLoading,
            onPressed: _handleRegister,
          ),
        ],
      ),
    );
  }

  // Error Alert Banner
  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.errorRed.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.errorRed.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, size: 16, color: AppColors.errorRed),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: AppTypography.body(fontSize: 12.5, color: AppColors.errorRed),
            ),
          ),
        ],
      ),
    );
  }
}
