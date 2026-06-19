import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive.dart';
import '../../../routes/route_names.dart';
import '../providers/auth_provider.dart';
import '../widgets/login_form.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final ok = await ref.read(authControllerProvider.notifier).login(
          username: _usernameController.text,
          password: _passwordController.text,
        );

    if (!mounted || !ok) return;

    final usuario = ref.read(authControllerProvider).usuario;
    if (usuario?.isAdmin ?? false) {
      context.go(RouteNames.dashboardAdmin);
    } else {
      context.go(RouteNames.dashboardEmpleado);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final isMobile = Responsive.isMobile(context);

    return Scaffold(
      body: Row(
        children: [
          if (!isMobile)
            Expanded(
              flex: 5,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.sidebarLight, Color(0xFF2D2640)],
                  ),
                ),
                child: const Center(
                  child: Padding(
                    padding: EdgeInsets.all(48),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.spa_outlined, size: 64, color: Colors.white70),
                        SizedBox(height: 24),
                        Text(
                          AppConstants.appName,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Panel administrativo profesional\npara tu negocio de belleza',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          Expanded(
            flex: isMobile ? 1 : 4,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isMobile) ...[
                        const Icon(Icons.spa_outlined, size: 40, color: AppColors.primary),
                        const SizedBox(height: 16),
                      ],
                      Text(
                        'Bienvenido',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Ingresa tus credenciales para continuar',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 32),
                      LoginForm(
                        formKey: _formKey,
                        usernameController: _usernameController,
                        passwordController: _passwordController,
                        onSubmit: _submit,
                        isLoading: auth.isLoading,
                        errorMessage: auth.status == AuthStatus.error
                            ? auth.errorMessage
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
