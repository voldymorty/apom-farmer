import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:client/global/colortheme.dart';
import 'package:client/models/notification_model.dart';
import 'package:client/screens/Farmer/order_details_screen.dart';
import 'package:client/repository/notification_repository.dart';
import 'package:client/widgets/custom_app_bar.dart';
import 'package:client/widgets/custom_snackbar.dart';

// ─── Filter definition ────────────────────────────────────────────────────────

enum NotificationFilter {
  all('All', null, null),
  unread('Unread', null, false),
  orders('Orders', 'order', null),
  payments('Payments', 'payment', null),
  delivery('Delivery', 'delivery', null);

  final String label;
  final String? type;
  final bool? isRead; // null = any, false = unread only

  const NotificationFilter(this.label, this.type, this.isRead);
}

// ─── Date grouping ────────────────────────────────────────────────────────────

enum DateGroup { today, yesterday, earlier }

DateGroup _dateGroupFor(DateTime dt) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));
  final d = DateTime(dt.year, dt.month, dt.day);
  if (d == today) return DateGroup.today;
  if (d == yesterday) return DateGroup.yesterday;
  return DateGroup.earlier;
}

String _dateGroupLabel(DateGroup g) {
  switch (g) {
    case DateGroup.today:
      return 'Today';
    case DateGroup.yesterday:
      return 'Yesterday';
    case DateGroup.earlier:
      return 'Earlier';
  }
}

// ─── List item sealed type ────────────────────────────────────────────────────

abstract class _ListItem {}

class _HeaderItem extends _ListItem {
  final DateGroup group;
  _HeaderItem(this.group);
}

class _NotifItem extends _ListItem {
  final NotificationItem notification;
  final int originalIndex;
  _NotifItem(this.notification, this.originalIndex);
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class NotificationScreen extends ConsumerStatefulWidget {
  const NotificationScreen({super.key});

  @override
  ConsumerState<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends ConsumerState<NotificationScreen> {
  final ScrollController _scrollController = ScrollController();
  final List<NotificationItem> _notifications = [];

  bool _isLoading = false;
  bool _hasMore = true;
  int _page = 1;
  static const int _limit = 20;

  NotificationFilter _activeFilter = NotificationFilter.all;

  // ── Derived filtered list ──
  List<NotificationItem> get _filtered {
    if (_activeFilter == NotificationFilter.all) return _notifications;
    return _notifications.where((n) {
      final typeOk =
          _activeFilter.type == null ||
          n.type.toLowerCase() == _activeFilter.type;
      final readOk =
          _activeFilter.isRead == null || n.isRead == _activeFilter.isRead;
      return typeOk && readOk;
    }).toList();
  }

  int get _unreadCount => _notifications.where((n) => !n.isRead).length;

  // ── Grouped list items ──
  List<_ListItem> get _groupedItems {
    final items = _filtered;
    if (items.isEmpty) return [];

    final result = <_ListItem>[];
    DateGroup? lastGroup;

    for (final item in items) {
      final originalIndex = _notifications.indexOf(item);
      final group = _dateGroupFor(item.createdAt);
      if (group != lastGroup) {
        result.add(_HeaderItem(group));
        lastGroup = group;
      }
      result.add(_NotifItem(item, originalIndex));
    }
    return result;
  }

  @override
  void initState() {
    super.initState();
    _loadInitialNotifications();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // ── Data loading ──

  Future<void> _loadInitialNotifications() async {
    setState(() {
      _isLoading = true;
      _notifications.clear();
      _page = 1;
      _hasMore = true;
    });

    try {
      final model = await ref
          .read(notificationRepositoryProvider)
          .getNotifications(page: _page, limit: _limit);

      if (!mounted) return;
      setState(() {
        _notifications.addAll(model.data.notifications);
        _isLoading = false;
        final pagination = model.data.pagination;
        _hasMore =
            pagination != null
                ? _page < pagination.totalPages
                : model.data.notifications.length >= _limit;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      CustomSnackBar.error(context, 'Failed to load notifications');
    }
  }

  Future<void> _loadMoreNotifications() async {
    if (_isLoading || !_hasMore) return;
    setState(() => _isLoading = true);

    try {
      final nextPage = _page + 1;
      final model = await ref
          .read(notificationRepositoryProvider)
          .getNotifications(page: nextPage, limit: _limit);

      if (!mounted) return;
      setState(() {
        _notifications.addAll(model.data.notifications);
        _page = nextPage;
        _isLoading = false;
        final pagination = model.data.pagination;
        _hasMore =
            pagination != null
                ? _page < pagination.totalPages
                : model.data.notifications.length >= _limit;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      CustomSnackBar.error(context, 'Failed to load more notifications');
    }
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreNotifications();
    }
  }

  // ── Actions ──

  Future<void> _markAsRead(NotificationItem notification, int index) async {
    if (notification.isRead) return;
    setState(() {
      _notifications[index] = notification.copyWith(
        isRead: true,
        readAt: DateTime.now(),
      );
    });
    try {
      await ref
          .read(notificationRepositoryProvider)
          .markAsRead(notification.notificationId);
      ref.invalidate(unreadCountProvider);
    } catch (_) {
      if (!mounted) return;
      setState(() => _notifications[index] = notification);
    }
  }

  Future<void> _markAllAsRead() async {
    final hasUnread = _notifications.any((n) => !n.isRead);
    if (!hasUnread) {
      CustomSnackBar.info(context, 'All notifications are already read');
      return;
    }
    setState(() {
      for (int i = 0; i < _notifications.length; i++) {
        if (!_notifications[i].isRead) {
          _notifications[i] = _notifications[i].copyWith(
            isRead: true,
            readAt: DateTime.now(),
          );
        }
      }
    });
    try {
      await ref.read(notificationRepositoryProvider).markAllAsRead();
      ref.invalidate(unreadCountProvider);
      if (!mounted) return;
      CustomSnackBar.success(context, 'All notifications marked as read');
    } catch (e) {
      _loadInitialNotifications();
      if (!mounted) return;
      CustomSnackBar.error(context, 'Failed to mark all as read');
    }
  }

  // Future<void> _dismissNotification(
  //     NotificationItem notification, int originalIndex) async {
  //   // Optimistic removal
  //   final removed = _notifications.removeAt(originalIndex);
  //   setState(() {});

  //   try {
  //     await ref
  //         .read(notificationRepositoryProvider)
  //         .deleteNotification(notification.notificationId);
  //     ref.invalidate(unreadCountProvider);
  //   } catch (_) {
  //     // Restore on failure
  //     if (!mounted) return;
  //     setState(() => _notifications.insert(originalIndex, removed));
  //     CustomSnackBar.error(context, 'Could not remove notification');
  //   }
  // }

  void _handleTap(NotificationItem notification, int originalIndex) {
    _markAsRead(notification, originalIndex);

    final refType = notification.referenceType?.toLowerCase() ?? '';
    final refId = notification.referenceId;

    if ((refType == 'order' || refType == 'crop' || refType == 'pickup') &&
        refId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => OrderDetailScreen(cropId: refId)),
      );
    }
  }

  // ── Helpers ──

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 2) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  IconData _iconFor(String type) {
    switch (type.toLowerCase()) {
      case 'order':
        return Icons.shopping_bag_outlined;
      case 'payment':
        return Icons.credit_card_outlined;
      case 'delivery':
        return Icons.local_shipping_outlined;
      case 'approval':
        return Icons.verified_outlined;
      default:
        return Icons.notifications_none_outlined;
    }
  }

  Color _colorFor(String type) {
    switch (type.toLowerCase()) {
      case 'order':
        return AppColors.farmerColor;
      case 'payment':
        return AppColors.success;
      case 'delivery':
        return const Color(0xFF534AB7);
      case 'approval':
        return const Color(0xFF854F0B);
      default:
        return AppColors.textSecondary;
    }
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      appBar: CustomAppBar(
        title: 'Notifications',
        backgroundColor: AppColors.farmerColor,
        showBackButton: true,
        actions: [
          if (_unreadCount > 0)
            IconButton(
              icon: const Icon(Icons.done_all_rounded, color: Colors.white),
              tooltip: 'Mark all as read',
              onPressed: _markAllAsRead,
            ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadInitialNotifications,
              color: AppColors.farmerColor,
              child: _buildBody(),
            ),
          ),
        ],
      ),
    );
  }

  // ── Filter bar ──

  Widget _buildFilterBar() {
    return Container(
      height: 48,
      color: Colors.white,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        itemCount: NotificationFilter.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final filter = NotificationFilter.values[i];
          final isActive = filter == _activeFilter;

          // Badge count
          int? count;
          if (filter == NotificationFilter.unread) {
            count = _unreadCount;
          } else if (filter == NotificationFilter.all) {
            count = _notifications.length;
          }

          return GestureDetector(
            onTap: () => setState(() => _activeFilter = filter),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: isActive ? AppColors.farmerColor : Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color:
                      isActive
                          ? AppColors.farmerColor
                          : const Color(0xFFD3D1C7),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    filter.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isActive ? Colors.white : const Color(0xFF5F5E5A),
                    ),
                  ),
                  if (count != null && count > 0) ...[
                    const SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isActive
                                ? Colors.white.withOpacity(0.25)
                                : AppColors.farmerColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isActive ? Colors.white : Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Body ──

  Widget _buildBody() {
    final items = _groupedItems;
    final isEmpty = items.isEmpty && !_isLoading;

    if (isEmpty) return _buildEmptyState();

    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: items.length + (_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        // Loading indicator at end
        if (index == items.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        final item = items[index];

        if (item is _HeaderItem) {
          return _buildDateHeader(item.group);
        }

        if (item is _NotifItem) {
          return _buildTile(item.notification, item.originalIndex);
        }

        return const SizedBox.shrink();
      },
    );
  }

  // ── Date header ──

  Widget _buildDateHeader(DateGroup group) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Text(
        _dateGroupLabel(group).toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Color(0xFF888780),
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  // ── Notification tile with swipe-to-dismiss ──

  Widget _buildTile(NotificationItem notif, int originalIndex) {
    final isUnread = !notif.isRead;
    final typeColor = _colorFor(notif.type);
    final isHighPriority = notif.priority.toLowerCase() == 'high';

    return GestureDetector(
      onTap: () => _handleTap(notif, originalIndex),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isUnread
                ? AppColors.farmerColor.withOpacity(0.35)
                : const Color(0xFFE5E7EB),
            width: 0.5,
          ),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left accent rail
              if (isUnread)
                Container(
                  width: 3,
                  decoration: BoxDecoration(
                    color: AppColors.farmerColor,
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(14),
                    ),
                  ),
                ),

              // Card content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icon
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: typeColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(_iconFor(notif.type),
                            color: typeColor, size: 20),
                      ),
                      const SizedBox(width: 12),

                      // Text body
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    notif.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isUnread
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                      color: isUnread
                                          ? const Color(0xFF111827)
                                          : const Color(0xFF374151),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _formatTime(notif.createdAt),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF9CA3AF),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              notif.message,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                height: 1.5,
                                color: isUnread
                                    ? const Color(0xFF374151)
                                    : const Color(0xFF6B7280),
                              ),
                            ),

                            // Footer chips
                            if (isHighPriority || notif.referenceId != null) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  if (isHighPriority) ...[
                                    _buildBadge(
                                      'Urgent',
                                      const Color(0xFFFCEBEB),
                                      const Color(0xFFA32D2D),
                                    ),
                                    const SizedBox(width: 6),
                                  ],
                                  if (notif.referenceId != null)
                                    _buildBadge(
                                      '${notif.referenceType?.toUpperCase() ?? 'REF'} #${notif.referenceId}',
                                      AppColors.farmerColor.withOpacity(0.1),
                                      AppColors.farmerColor,
                                    ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Unread dot
                      if (isUnread) ...[
                        const SizedBox(width: 8),
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppColors.farmerColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }

  // ── Empty state ──

  Widget _buildEmptyState() {
    final (icon, title, subtitle) = _emptyStateContent(_activeFilter);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.22),
        Center(
          child: Column(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.farmerColor.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 36,
                  color: AppColors.farmerColor.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C2C2A),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48),
                child: Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF888780),
                    height: 1.5,
                  ),
                ),
              ),
              if (_activeFilter != NotificationFilter.all) ...[
                const SizedBox(height: 20),
                GestureDetector(
                  onTap:
                      () => setState(
                        () => _activeFilter = NotificationFilter.all,
                      ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.farmerColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'View all notifications',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.farmerColor,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  (IconData, String, String) _emptyStateContent(NotificationFilter filter) {
    switch (filter) {
      case NotificationFilter.unread:
        return (
          Icons.mark_email_read_outlined,
          "You're all caught up",
          "No unread notifications. Check back later for updates on your crops and orders.",
        );
      case NotificationFilter.orders:
        return (
          Icons.shopping_bag_outlined,
          'No order notifications',
          'Order updates will appear here when vendors place or modify orders.',
        );
      case NotificationFilter.payments:
        return (
          Icons.credit_card_outlined,
          'No payment notifications',
          'Payment confirmations and payout alerts will show up here.',
        );
      case NotificationFilter.delivery:
        return (
          Icons.local_shipping_outlined,
          'No delivery updates',
          'Pickup and delivery status notifications will appear here.',
        );
      case NotificationFilter.all:
        return (
          Icons.notifications_none_outlined,
          'No notifications yet',
          "You'll be notified here when something needs your attention.",
        );
    }
  }
}
