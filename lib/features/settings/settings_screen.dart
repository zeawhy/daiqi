import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../shared/services/audio_service.dart';
import '../../shared/services/haptic_service.dart';
import '../../shared/services/notification_service.dart';
import '../../shared/widgets/brand_backpack_icon.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with WidgetsBindingObserver {
  bool _sound = AudioService.enabled;
  bool _haptic = HapticService.enabled;
  bool _notificationGranted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermission();
    }
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
    HapticService.selection();
    final granted = await NotificationService.requestPermission();
    if (mounted) {
      setState(() {
        _notificationGranted = granted;
      });
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            granted ? '通知权限已开启' : '未获得通知权限，可在系统设置中开启',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _showClearRecordsDialog() async {
    HapticService.selection();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: const Text(
            '清除遗忘记录',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
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
      HapticService.lightImpact();
      final checklistRepo = ref.read(checklistRepositoryProvider);
      await checklistRepo.clearAllForgotRecords();
      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          const SnackBar(
            content: Text('已清除所有遗忘记录'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 2, 6, 6),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reducedMotion = ref.watch(reducedMotionProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // Section 1: Feedback & Motion
          _buildSectionHeader('交互与反馈'),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadowSoft,
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
                    secondary: Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        color: AppColors.pastelLavender,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.volume_up_outlined,
                        color: AppColors.textPrimary,
                        size: 20,
                      ),
                    ),
                    title: const Text('声音', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('放进背包、取出及拉链音效'),
                    value: _sound,
                    onChanged: (val) {
                      HapticService.selection();
                      setState(() {
                        _sound = val;
                        AudioService.enabled = val;
                      });
                    },
                  ),
                  const Divider(height: 1, color: AppColors.border),
                  SwitchListTile(
                    secondary: Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        color: AppColors.pastelSky,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.vibration_rounded,
                        color: AppColors.textPrimary,
                        size: 20,
                      ),
                    ),
                    title: const Text('震动', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('拖动、吸附及装包触感反馈'),
                    value: _haptic,
                    onChanged: (val) {
                      setState(() {
                        _haptic = val;
                        HapticService.enabled = val;
                      });
                      if (val) {
                        HapticService.selection();
                      }
                    },
                  ),
                  const Divider(height: 1, color: AppColors.border),
                  SwitchListTile(
                    secondary: Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.motion_photos_off_outlined,
                        color: AppColors.textPrimary,
                        size: 20,
                      ),
                    ),
                    title: const Text('减少动效', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('开启后所有动画改为简单淡入淡出'),
                    value: reducedMotion,
                    onChanged: (val) {
                      HapticService.selection();
                      ref.read(reducedMotionProvider.notifier).setReducedMotion(val);
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Section 2: Permissions & Onboarding
          _buildSectionHeader('通知与引导'),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadowSoft,
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
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.doneLight,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle, color: AppColors.done, size: 15),
                                SizedBox(width: 4),
                                Text(
                                  '已开启',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.done,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : TextButton(
                            onPressed: _requestNotification,
                            child: const Text('去开启'),
                          ),
                    onTap: _notificationGranted ? null : _requestNotification,
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
                    onTap: () {
                      HapticService.selection();
                      context.push('/onboarding');
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Section 3: Data Management
          _buildSectionHeader('数据管理'),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadowSoft,
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
          const SizedBox(height: 18),

          // Section 4: About
          _buildSectionHeader('关于'),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadowSoft,
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
                    color: AppColors.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const BrandBackpackIcon(
                    size: 20,
                    showCheck: true,
                    strokeWidth: 1.8,
                    strokeColor: AppColors.textPrimary,
                    checkColor: AppColors.done,
                  ),
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
      ),
    );
  }
}
