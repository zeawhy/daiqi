import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../shared/services/audio_service.dart';
import '../../shared/services/haptic_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _sound = AudioService.enabled;
  bool _haptic = HapticService.enabled;

  @override
  Widget build(BuildContext context) {
    final reducedMotion = ref.watch(reducedMotionProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('声音'),
                  subtitle: const Text('放进背包、取出及拉链音效'),
                  activeThumbColor: AppColors.primary,
                  value: _sound,
                  onChanged: (val) {
                    setState(() {
                      _sound = val;
                      AudioService.enabled = val;
                    });
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('震动'),
                  subtitle: const Text('拖动、吸附及装包触感反馈'),
                  activeThumbColor: AppColors.primary,
                  value: _haptic,
                  onChanged: (val) {
                    setState(() {
                      _haptic = val;
                      HapticService.enabled = val;
                    });
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('减少动效'),
                  subtitle: const Text('开启后所有动画改为简单淡入淡出'),
                  activeThumbColor: AppColors.primary,
                  value: reducedMotion,
                  onChanged: (val) {
                    ref.read(reducedMotionProvider.notifier).setReducedMotion(val);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              title: const Text('关于「带齐了」'),
              subtitle: const Text('出门前 30 秒，确认带齐'),
              trailing: const Text('v1.0.0 (MVP)'),
            ),
          ),
        ],
      ),
    );
  }
}
