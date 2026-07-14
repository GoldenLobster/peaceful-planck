import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'presentation/navigation/app_router.dart';

void main() {
  runApp(const ProviderScope(child: YTMUltimateApp()));
}

class YTMUltimateApp extends StatelessWidget {
  const YTMUltimateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'ytmUltimate',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: Colors.black,
        colorScheme: const ColorScheme.dark(
          primary: Colors.white,
          surface: Colors.black,
        ),
      ),
      routerConfig: appRouter,
    );
  }
}
