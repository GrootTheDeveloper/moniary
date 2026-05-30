import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';
import '../l10n/gen_l10n/app_localizations.dart';
import 'app_router.dart';
import 'app_theme.dart';
import '../features/settings/application/privacy_controller.dart';

class MoniaryApp extends ConsumerStatefulWidget {
  const MoniaryApp({super.key});

  @override
  ConsumerState<MoniaryApp> createState() => _MoniaryAppState();
}

class _MoniaryAppState extends ConsumerState<MoniaryApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      ref.read(privacyControllerProvider.notifier).lockApp();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: ref.watch(appRouterProvider),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
