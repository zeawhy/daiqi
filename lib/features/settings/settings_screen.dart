import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../shared/services/audio_service.dart';
import '../../shared/services/haptic_service.dart';
import '../../shared/services/notification_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _sound = AudioService.enabled;
  bool _haptic = HapticService.enabled;
  bool _notificationGranted = false;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final granted = await NotificationService.isPermissionGranted();
    if (mounted) {
      setState(() {
        _notificationGranted = granted;
      });
    }
  }

  Future<void> _requestNotification() async {
    final granted = await NotificationService.requestPermission();
    if (mounted) {
      setState(() {
        _notificationGranted = granted;
      });
    }
  }

  Future<void> _showClearRecordsDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('清除遗忘记录', style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text(
            '确定要清除所有遗忘记录吗？排行榜和高危标记都将被重置，此操作无法撤销。',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(false),
              child: const Text('取消', style: TextStyle(color: AppColors.textSecondary)),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
              onPressed: () => Navigator.of(dialogCtx).pop(true),
              child: const Text('清除'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      final checklistRepo = ref.read(checklistRepositoryProvider);
      await checklistRepo.clearAllForgotRecords();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('已清除所有遗忘记录'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

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
          // Section 1: Feedback & Motion
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(28, 25, 23, 0.05),
                  blurRadius: 24,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Card(
              margin: EdgeInsets.zero,
              elevation: 0,
              color: AppColors.card,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: const BorderSide(color: AppColors.border, width: 0.5),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('声音', style: TextStyle(fontWeight: FontWeight.w600)),
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
                  const Divider(height: 1, color: AppColors.border),
                  SwitchListTile(
                    title: const Text('震动', style: TextStyle(fontWeight: FontWeight.w600)),
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
                  const Divider(height: 1, color: AppColors.border),
                  SwitchListTile(
                    title: const Text('减少动效', style: TextStyle(fontWeight: FontWeight.w600)),
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
          ),
          const SizedBox(height: 16),

          // Section 2: Permissions & Onboarding
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(28, 25, 23, 0.05),
                  blurRadius: 24,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Card(
              margin: EdgeInsets.zero,
              elevation: 0,
              color: AppColors.card,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: const BorderSide(color: AppColors.border, width: 0.5),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        color: AppColors.pastelAmber,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.notifications_active_outlined, color: AppColors.textPrimary, size: 20),
                    ),
                    title: const Text('通知权限', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      _notificationGranted ? '已开启' : '未开启，可能无法在设定时间收到装包提醒',
                      style: TextStyle(
                        fontSize: 12,
                        color: _notificationGranted ? AppColors.done : AppColors.textSecondary,
                      ),
                    ),
                    trailing: _notificationGranted
                        ? const Icon(Icons.check_circle, color: AppColors.done, size: 20)
                        : TextButton(
                            onPressed: _requestNotification,
                            child: const Text('去开启'),
                          ),
                  ),
                  const Divider(height: 1, color: AppColors.border),
                  ListTile(
                    leading: Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        color: AppColors.pastelSky,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.school_outlined, color: AppColors.textPrimary, size: 20),
                    ),
                    title: const Text('重新播放引导', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('查看首次装包操作互动演示', style: TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                    onTap: () => context.push('/onboarding'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Section 3: Data Management
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(28, 25, 23, 0.05),
                  blurRadius: 24,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Card(
              margin: EdgeInsets.zero,
              elevation: 0,
              color: AppColors.card,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: const BorderSide(color: AppColors.border, width: 0.5),
              ),
              child: ListTile(
                leading: Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    color: AppColors.dangerLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.delete_sweep_outlined, color: AppColors.danger, size: 20),
                ),
                title: const Text('清除所有遗忘记录', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w600)),
                subtitle: const Text('清空所有遗忘记录与高危标记', style: TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                onTap: _showClearRecordsDialog,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Section 4: About
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(28, 25, 23, 0.05),
                  blurRadius: 24,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Card(
              margin: EdgeInsets.zero,
              elevation: 0,
              color: AppColors.card,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: const BorderSide(color: AppColors.border, width: 0.5),
              ),
              child: ListTile(
                leading: Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    color: AppColors.pastelLavender,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.backpack_outlined, color: AppColors.textPrimary, size: 20),
                ),
                title: const Text('关于「带齐了」', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('出门前 30 秒，确认带齐'),
                trailing: const Text(
                  'v1.0.0 (MVP)',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
