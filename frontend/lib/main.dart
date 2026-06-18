import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/simulator/ui/main_navigation_page.dart';
import 'package:frontend/features/simulator/domain/providers/settings_provider.dart';
import 'package:frontend/features/auth/services/auth_service.dart';
import 'package:frontend/features/auth/domain/providers/auth_provider.dart';
import 'package:frontend/features/auth/ui/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthService.initialize();
  AuthService.initListener();
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final authState = ref.watch(authProvider);

    return MaterialApp(
      title: 'PokerLab',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settings.themeMode,
      home: Builder(
        builder: (context) {
          AppColors.setTheme(context);
          return authState.when(
            data: (user) {
              if (user == null) {
                return const LoginPage();
              }
              return const MainNavigationPage();
            },
            loading: () => Scaffold(
              backgroundColor: AppColors.background,
              body: const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
            error: (err, stack) => Scaffold(
              backgroundColor: AppColors.background,
              body: Center(
                child: Text(
                  '登入初始化失敗: $err',
                  style: const TextStyle(color: AppColors.loseColor, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}


