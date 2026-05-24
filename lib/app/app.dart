import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';
import 'app_router.dart';
import 'app_theme.dart';

class MoniaryApp extends StatelessWidget {
  const MoniaryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: appRouter,
    );
  }
}
