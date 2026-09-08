import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/route_paths.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/glass_card.dart';
import '../../widgets/common/gradient_button.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await ref.read(authProvider.notifier).register(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
    if (ok && mounted) {
      context.go(RoutePaths.skillBaseline);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: GlassCard(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Create your account', style: AppTypography.heading(fontSize: 20)),
                      const SizedBox(height: 4),
                      Text(
                        "We'll baseline your skills next.",
                        style: AppTypography.body(fontSize: 13, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _nameController,
                        style: AppTypography.body(fontSize: 14),
                        decoration: const InputDecoration(labelText: 'Full name'),
                        validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _emailController,
                        style: AppTypography.body(fontSize: 14),
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(labelText: 'Email'),
                        validator: (v) =>
                            (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _passwordController,
                        style: AppTypography.body(fontSize: 14),
                        obscureText: true,
                        decoration: const InputDecoration(labelText: 'Password'),
                        validator: (v) => (v == null || v.length < 6) ? 'Min 6 characters' : null,
                      ),
                      if (authState.error != null) ...[
                        const SizedBox(height: 12),
                        Text(authState.error!,
                            style: AppTypography.body(fontSize: 12.5, color: AppColors.errorCoral)),
                      ],
                      const SizedBox(height: 22),
                      GradientButton(
                        label: 'Create Account',
                        icon: Icons.arrow_forward_rounded,
                        isLoading: authState.isLoading,
                        onPressed: _submit,
                      ),
                      const SizedBox(height: 14),
                      Center(
                        child: TextButton(
                          onPressed: () => context.go(RoutePaths.login),
                          child: const Text('Already have an account? Sign in'),
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.06, end: 0),
            ),
          ),
        ),
      ),
    );
  }
}
