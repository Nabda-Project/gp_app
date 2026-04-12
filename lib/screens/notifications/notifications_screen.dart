import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../utils/constants.dart';
import '../../utils/app_localizations.dart';
import '../../widgets/reusable/decorated_background.dart';
import '../../widgets/animations/animated_list_item.dart';
import '../../widgets/reusable/list_skeleton.dart';
import '../../widgets/reusable/empty_state_view.dart';
import '../../services/notification_api_service.dart';
import '../../services/storage_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final ScrollController _scrollController = ScrollController();
  List<NotificationItem> _notifications = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _fetchNotifications({bool refresh = false}) async {
    if (refresh) {
      if (mounted) {
        setState(() {
          _currentPage = 0;
          _hasMore = true;
        });
      }
    }
    final user = StorageService.getUser();
    if (user?.backendId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final notifications = await NotificationApiService.getNotifications(
        user!.backendId!,
        page: _currentPage,
      );
      if (mounted) {
        setState(() {
          if (refresh) {
            _notifications = notifications;
          } else {
            _notifications.addAll(notifications);
          }
          if (notifications.isEmpty || notifications.length < 20) {
            _hasMore = false;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      log('Failed to load notifications: $e', name: 'NotificationsScreen');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore || _isLoading) return;
    
    setState(() => _isLoadingMore = true);
    _currentPage++;
    
    final user = StorageService.getUser();
    if (user?.backendId == null) return;
    
    try {
      final notifications = await NotificationApiService.getNotifications(
        user!.backendId!,
        page: _currentPage,
      );
      if (mounted) {
        setState(() {
          _notifications.addAll(notifications);
          if (notifications.isEmpty || notifications.length < 20) {
            _hasMore = false;
          }
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      log('Failed to load more notifications: $e');
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
          _currentPage--; // Revert page on failure
        });
      }
    }
  }

  /// Mark ALL as read — instant UI update then API call.
  Future<void> _markAllAsRead() async {
    final user = StorageService.getUser();
    if (user?.backendId == null) return;

    // 1) Instant local state update — remove all blue dots immediately
    setState(() {
      _notifications = _notifications
          .map((n) => NotificationItem(
                id: n.id,
                userId: n.userId,
                type: n.type,
                title: n.title,
                body: n.body,
                relatedId: n.relatedId,
                relatedName: n.relatedName,
                isRead: true,
                createdAt: n.createdAt,
              ))
          .toList();
    });

    // 2) Fire API in background
    await NotificationApiService.markAllAsRead(user!.backendId!);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.get('markAllRead')),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  /// Mark a single notification as read — instant UI update.
  Future<void> _markAsRead(NotificationItem item) async {
    if (item.isRead) return;
    final user = StorageService.getUser();
    if (user?.backendId == null) return;

    // 1) Instant local state update — remove blue dot immediately
    final index = _notifications.indexWhere((n) => n.id == item.id);
    if (index != -1) {
      setState(() {
        _notifications[index] = NotificationItem(
          id: item.id,
          userId: item.userId,
          type: item.type,
          title: item.title,
          body: item.body,
          relatedId: item.relatedId,
          relatedName: item.relatedName,
          isRead: true,
          createdAt: item.createdAt,
        );
      });
    }

    // 2) Fire API in background
    await NotificationApiService.markAsRead(item.id, user!.backendId!);

    // If it's a CHAT notification, also mark chat notifications from that sender
    if (item.type == 'CHAT' && item.relatedId != null) {
      await NotificationApiService.markChatAsRead(
          user.backendId!, item.relatedId!);
    }
  }

  /// Delete a notification — no confirmation, instant delete.
  Future<void> _deleteNotification(NotificationItem item) async {
    final user = StorageService.getUser();
    if (user?.backendId == null) return;

    // 1) Remove from local list instantly
    setState(() {
      _notifications.removeWhere((n) => n.id == item.id);
    });

    // 2) Fire API in background
    await NotificationApiService.deleteNotification(item.id, user!.backendId!);
  }

  /// Delete ALL notifications.
  Future<void> _deleteAllNotifications() async {
    final user = StorageService.getUser();
    if (user?.backendId == null) return;

    // 1) Clear local list instantly
    setState(() {
      _notifications.clear();
    });

    // 2) Fire API in background
    await NotificationApiService.deleteAllNotifications(user!.backendId!);
  }

  void _onNotificationTap(NotificationItem item) async {
    // Mark as read first
    await _markAsRead(item);

    if (!mounted) return;

    // Navigate to relevant screen
    if (item.type == 'CHAT' && item.relatedId != null) {
      // Navigate to the chat with this person
      Navigator.pushNamed(
        context,
        '/doctor_chat',
        arguments: {
          'doctorName': item.relatedName,
          'doctorId': item.relatedId,
        },
      );
    }
    // For appointment notifications, no specific navigation needed —
    // the dashboard already shows the updated appointment.
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'CHAT':
        return Icons.chat_bubble_rounded;
      case 'APPOINTMENT_SCHEDULED':
        return Icons.calendar_today_rounded;
      case 'APPOINTMENT_CONFIRMED':
        return Icons.check_circle_rounded;
      case 'APPOINTMENT_CANCELLED':
        return Icons.cancel_rounded;
      case 'APPOINTMENT_COMPLETED':
        return Icons.task_alt_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'CHAT':
        return AppColors.primaryBlue;
      case 'APPOINTMENT_SCHEDULED':
        return Colors.purple;
      case 'APPOINTMENT_CONFIRMED':
        return AppColors.accentTeal;
      case 'APPOINTMENT_CANCELLED':
        return AppColors.error;
      case 'APPOINTMENT_COMPLETED':
        return Colors.green;
      default:
        return AppColors.grey;
    }
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final hasUnread = _notifications.any((n) => !n.isRead);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.get('notificationsTitle'),
          style: const TextStyle(
            color: AppColors.darkBlue,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.darkBlue),
        actions: [
          if (hasUnread)
            TextButton(
              onPressed: _markAllAsRead,
              child: Text(
                AppLocalizations.of(context)!.get('markAllRead'),
                style: const TextStyle(fontSize: 13),
              ),
            ),
          if (_notifications.isNotEmpty)
            IconButton(
              onPressed: _deleteAllNotifications,
              icon: const Icon(
                Icons.delete_sweep_rounded,
                color: AppColors.error,
              ),
              tooltip: AppLocalizations.of(context)!.get('deleteAll'),
            ),
        ],
      ),
      body: DecoratedBackground(
        child: _isLoading
            ? const ListSkeleton(itemCount: 8, hasAvatar: false, compact: true)
            : _notifications.isEmpty
                ? EmptyStateView(
                    icon: Icons.notifications_off_rounded,
                    title: AppLocalizations.of(context)!.get('noNotifications'),
                    description: 'When you receive alerts or messages, they will appear here.',
                    actionText: 'Refresh',
                    onAction: () => _fetchNotifications(refresh: true),
                  )
                : RefreshIndicator(
                    onRefresh: () => _fetchNotifications(refresh: true),
                    child: ListView.builder(
                      controller: _scrollController,
                      padding:
                          const EdgeInsets.all(AppDimensions.paddingM),
                      itemCount: _notifications.length + (_hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _notifications.length) {
                          return const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(
                              child: CircularProgressIndicator(
                                  color: AppColors.primaryBlue),
                            ),
                          );
                        }

                        final item = _notifications[index];
                        final typeColor = _getColorForType(item.type);

                        return AnimatedListItem(
                          index: index,
                          child: Container(
                            margin: const EdgeInsets.only(
                              bottom: AppDimensions.paddingS,
                            ),
                            decoration: BoxDecoration(
                              color: item.isRead
                                  ? AppColors.white
                                  : typeColor.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(
                                AppDimensions.radiusM,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black
                                      .withValues(alpha: 0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                              border: item.isRead
                                  ? null
                                  : Border.all(
                                      color: typeColor
                                          .withValues(alpha: 0.15),
                                      width: 1,
                                    ),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => _onNotificationTap(item),
                                borderRadius: BorderRadius.circular(
                                  AppDimensions.radiusM,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal:
                                        AppDimensions.paddingM,
                                    vertical: 14,
                                  ),
                                  child: Row(
                                    children: [
                                      // Icon
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: typeColor.withValues(
                                              alpha: item.isRead
                                                  ? 0.08
                                                  : 0.15),
                                          borderRadius:
                                              BorderRadius.circular(
                                                  12),
                                        ),
                                        child: Icon(
                                          _getIconForType(item.type),
                                          color: item.isRead
                                              ? AppColors.grey
                                              : typeColor,
                                          size: 22,
                                        ),
                                      ),
                                      const SizedBox(
                                          width:
                                              AppDimensions.paddingM),
                                      // Content
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    item.title,
                                                    style: TextStyle(
                                                      fontWeight: item
                                                              .isRead
                                                          ? FontWeight
                                                              .w500
                                                          : FontWeight
                                                              .bold,
                                                      color: AppColors
                                                          .darkBlue,
                                                      fontSize: 14,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow
                                                            .ellipsis,
                                                  ),
                                                ),
                                                if (!item.isRead)
                                                  Container(
                                                    width: 8,
                                                    height: 8,
                                                    margin:
                                                        const EdgeInsets
                                                            .only(
                                                            left: 8),
                                                    decoration:
                                                        BoxDecoration(
                                                      color: typeColor,
                                                      shape: BoxShape
                                                          .circle,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              item.body,
                                              style: const TextStyle(
                                                color: AppColors.grey,
                                                fontSize: 13,
                                              ),
                                              maxLines: 2,
                                              overflow:
                                                  TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              _formatTime(
                                                  item.createdAt),
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: AppColors.grey
                                                    .withValues(
                                                        alpha: 0.7),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Delete button
                                      const SizedBox(width: 4),
                                      SizedBox(
                                        width: 36,
                                        height: 36,
                                        child: IconButton(
                                          onPressed: () =>
                                              _deleteNotification(item),
                                          icon: Icon(
                                            Icons.delete_outline_rounded,
                                            color: AppColors.grey
                                                .withValues(alpha: 0.5),
                                            size: 20,
                                          ),
                                          padding: EdgeInsets.zero,
                                          splashRadius: 18,
                                          tooltip: AppLocalizations.of(
                                                  context)!
                                              .get('deleteNotification'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
      ),
    );
  }
}
