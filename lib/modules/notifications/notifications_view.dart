import 'package:flutter/material.dart';
import 'package:order/app/theme/theme_colors.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../app/constants/api_endpoints.dart';
import '../../app/theme/app_colors.dart';
import '../../data/providers/api_provider.dart';
import '../../shared/services/fcm_service.dart';

class NotificationsView extends StatefulWidget {
  const NotificationsView({super.key});
  @override
  State<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView> {
  List<dynamic> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final res = await ApiProvider.get(ApiEndpoints.notificationsGetAll);
    if (res.success) _notifications = res.data?['notifications'] ?? [];
    setState(() => _isLoading = false);
    // Reset badge count after loading notifications
    FcmService.to.resetUnreadCount();
  }

  Future<void> _markAllRead() async {
    await ApiProvider.post(ApiEndpoints.notificationsMarkAllRead);
    _load();
    FcmService.to.resetUnreadCount();
    Get.snackbar('Success'.tr, 'All marked as read'.tr, snackPosition: SnackPosition.BOTTOM, backgroundColor: AppColors.success.withValues(alpha: 0.9), colorText: Colors.white, margin: const EdgeInsets.all(12));
  }

  Future<void> _delete(String id) async {
    await ApiProvider.post(ApiEndpoints.notificationsDelete, body: {'id': id});
    _load();
  }

  /// Format DB timestamp (UTC) to relative time string
  String _formatTime(String ts) {
    if (ts.isEmpty) return '';
    try {
      // DB stores timestamps in UTC — append 'Z' so Dart parses as UTC,
      // then convert to local for correct time-ago calculation.
      final utcStr = ts.endsWith('Z') ? ts : '${ts.replaceAll(' ', 'T')}Z';
      final dt = DateTime.parse(utcStr).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 1) return 'Just now'.tr;
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return DateFormat('MMM d, yyyy').format(dt);
    } catch (_) {
      return ts;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.cx.scaffold,
      appBar: AppBar(
        title: Text('Notifications'.tr),
        actions: [
          if (_notifications.isNotEmpty) TextButton(onPressed: _markAllRead, child: Text('Mark all as read'.tr, style: const TextStyle(color: AppColors.primaryOrange, fontSize: 12))),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryOrange))
          : _notifications.isEmpty
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.notifications_off_outlined, size: 60, color: Colors.white.withValues(alpha: 0.2)),
                  const SizedBox(height: 12),
                  Text('No notifications'.tr, style: TextStyle(color: context.cx.textSecondary, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text('You\'re all caught up!'.tr, style: TextStyle(color: context.cx.textSecondary, fontSize: 13)),
                ]))
              : RefreshIndicator(
                  color: AppColors.primaryOrange,
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _notifications.length,
                    itemBuilder: (ctx, i) {
                      final n = _notifications[i];
                      final isRead = n['is_read'] == 1 || n['is_read'] == true;
                      return Dismissible(
                        key: Key(n['id'].toString()),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) => _delete(n['id'].toString()),
                        background: Container(
                          alignment: AlignmentDirectional.centerEnd,
                          padding: const EdgeInsetsDirectional.only(end: 20),
                          decoration: BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isRead ? context.cx.card : AppColors.primaryOrange.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: isRead ? null : Border.all(color: AppColors.primaryOrange.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40, height: 40,
                                decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.primaryOrange.withValues(alpha: 0.15)),
                                child: const Icon(Icons.notifications_outlined, color: AppColors.primaryOrange, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(n['title'] ?? '', style: TextStyle(color: Colors.white, fontWeight: isRead ? FontWeight.normal : FontWeight.w600, fontSize: 14)),
                                const SizedBox(height: 3),
                                Text(n['body'] ?? '', style: TextStyle(color: context.cx.textSecondary, fontSize: 12), maxLines: 2),
                                const SizedBox(height: 4),
                                Text(_formatTime(n['created_at']?.toString() ?? ''), style: TextStyle(color: context.cx.textSecondary, fontSize: 10)),
                              ])),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
