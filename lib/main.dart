import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'config/app_theme.dart';
import 'services/api_client.dart';
import 'services/auth_service.dart';
import 'services/user_service.dart';
import 'services/missing_person_service.dart';
import 'services/sighting_service.dart';
import 'services/found_report_service.dart';
import 'services/alert_service.dart';
import 'screens/reports/create_report_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiClient>(
          create: (_) => ApiClient(),
          dispose: (_, client) => client.dispose(),
        ),
        ProxyProvider<ApiClient, AuthService>(
          update: (_, apiClient, __) => AuthService(apiClient),
        ),
        ProxyProvider<ApiClient, UserService>(
          update: (_, apiClient, __) => UserService(apiClient),
        ),
        ProxyProvider<ApiClient, MissingPersonService>(
          update: (_, apiClient, __) => MissingPersonService(apiClient),
        ),
        ProxyProvider<ApiClient, SightingService>(
          update: (_, apiClient, __) => SightingService(apiClient),
        ),
        ProxyProvider<ApiClient, FoundReportService>(
          update: (_, apiClient, __) => FoundReportService(apiClient),
        ),
        ProxyProvider<ApiClient, AlertService>(
          update: (_, apiClient, __) => AlertService(apiClient),
        ),
      ],
      child: MaterialApp(
        title: 'BackToHome',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('es', 'ES'), // Español
          Locale('en', 'US'), // Inglés
        ],
        locale: const Locale('es', 'ES'),
        home: const SplashScreen(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/home': (context) => const HomeScreen(),
          '/reports/create': (context) => const CreateReportScreen(),
        },
      ),
    );
  }
}
