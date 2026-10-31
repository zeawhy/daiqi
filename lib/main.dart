import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'shared/services/audio_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  AudioService.init();
  runApp(
    const ProviderScope(
      child: DaiqiApp(),
    ),
  );
}
