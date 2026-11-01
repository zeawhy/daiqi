import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Diagnostic screen shown when the app catches a fatal Dart error during
/// startup (or later). It exists so a tester without a computer can copy the
/// stack trace out of the app itself instead of using adb logcat.
///
/// If the process dies in native code, this screen never appears — that
/// outcome on its own is diagnostic (native crash, not a Dart error).
class CrashScreen extends StatelessWidget {
  const CrashScreen({
    super.key,
    required this.error,
    required this.stack,
  });

  final Object error;
  final String? stack;

  String get _fullText {
    final buffer = StringBuffer();
    buffer.writeln('ERROR: $error');
    buffer.writeln();
    buffer.writeln(stack ?? '(no stack trace)');
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('带齐了启动出错（诊断版）'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'App 启动时抓到了错误，请点下面按钮复制全文，发给 Muse。',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  child: SelectableText(
                    _fullText,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: _fullText));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('已复制，去聊天里粘贴发给 Muse 吧'),
                      ),
                    );
                  }
                },
                child: const Text('复制全部报错信息'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
