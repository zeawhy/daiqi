import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/crash_screen.dart';
import 'shared/services/audio_service.dart';

/// First fatal Dart error caught after startup, if any. The root widget
/// listens to this and swaps the whole UI for [CrashScreen] so the stack
/// trace can be copied out of the app without adb.
final ValueNotifier<Object?> crashNotifier = ValueNotifier<Object?>(null);
final ValueNotifier<String?> crashStackNotifier =
    ValueNotifier<String?>(null);

void _reportCrash(Object error, StackTrace? stack) {
  // Only keep the first error: later cascade errors would hide the cause.
  // Set the stack BEFORE the error notifier: flipping the error notifier
  // rebuilds listeners synchronously, and they read the stack on that pass.
  if (crashNotifier.value == null) {
    crashStackNotifier.value = stack?.toString();
    crashNotifier.value = error;
  }
}

void main() {
  runZonedGuarded(() {
    WidgetsFlutterBinding.ensureInitialized();
    FlutterError.onError = (details) {
      // Keep the default console dump, then surface the error in-app.
      FlutterError.presentError(details);
      _reportCrash(details.exception, details.stack);
    };
    AudioService.init();
    runApp(
      ProviderScope(
        child: ValueListenableBuilder<Object?>(
          valueListenable: crashNotifier,
          builder: (context, error, _) {
            if (error != null) {
              return CrashScreen(
                error: error,
                stack: crashStackNotifier.value,
              );
            }
            return const DaiqiApp();
          },
        ),
      ),
    );
  }, (error, stack) {
    _reportCrash(error, stack);
  });
}
