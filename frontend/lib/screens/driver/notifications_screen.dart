import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config/app_config.dart';

class NotificationsScreen extends StatefulWidget {
  final String driverId;

  const NotificationsScreen({
    super.key,
    required this.driverId,
  });

  @override
  State<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState
    extends State<NotificationsScreen> {
  List<dynamic> notifications = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(Uri.parse(
          '${AppConfig.baseUrl}/notifications/${widget.driverId}'));
      if (response.statusCode == 200) {
        setState(() {
          notifications =
          jsonDecode(response.body) as List;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> markAllRead() async {
    try {
      await http.put(Uri.parse(
          '${AppConfig.baseUrl}/notifications/read-all'
              '/${widget.driverId}'));
      // Refresh list
      await fetchNotifications();
    } catch (e) {
      debugPrint('Mark all read error: $e');
    }
  }

  Future<void> markOneRead(dynamic notification) async {
    if (notification['read'] == true) return;
    try {
      await http.put(Uri.parse(
          '${AppConfig.baseUrl}/notifications/read'
              '/${notification['id']}'));
      await fetchNotifications();
    } catch (e) {
      debugPrint('Mark read error: $e');
    }
  }

  Future<void> clearAll() async {
    try {
      await http.delete(Uri.parse(
          '${AppConfig.baseUrl}/notifications/${widget.driverId}'));
      await fetchNotifications();
    } catch (e) {
      debugPrint('Clear error: $e');
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'PACKAGE_ASSIGNED':
        return Icons.inventory_2_rounded;
      case 'INCIDENT':
        return Icons.warning_rounded;
      case 'DEADLINE_WARNING':
        return Icons.timer_rounded;
      case 'GENERAL':
        return Icons.notifications_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'PACKAGE_ASSIGNED':
        return const Color(0xFF2E7D32);
      case 'INCIDENT':
        return Colors.red.shade700;
      case 'DEADLINE_WARNING':
        return Colors.orange.shade700;
      case 'GENERAL':
        return const Color(0xFF0D47A1);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = notifications
        .where((n) => n['read'] == false)
        .length;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        title: const Text('Notifications'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (notifications.isNotEmpty)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded,
                  color: Colors.white),
              onSelected: (val) {
                if (val == 'mark_all') markAllRead();
                if (val == 'clear') clearAll();
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'mark_all',
                  child: Row(
                    children: [
                      Icon(Icons.done_all_rounded,
                          size: 18),
                      SizedBox(width: 8),
                      Text('Mark all as read'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'clear',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline_rounded,
                          size: 18,
                          color: Colors.red),
                      SizedBox(width: 8),
                      Text('Clear all',
                          style: TextStyle(
                              color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: isLoading
          ? const Center(
          child: CircularProgressIndicator())
          : notifications.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            Icon(
                Icons
                    .notifications_none_rounded,
                size: 72,
                color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No notifications yet',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      )
          : Column(
        children: [
          // Unread count banner
          if (unreadCount > 0)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
              color: const Color(0xFF1B5E20)
                  .withOpacity(0.08),
              child: Text(
                '$unreadCount unread notification'
                    '${unreadCount == 1 ? '' : 's'}',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF1B5E20),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final n = notifications[index];
                final isRead =
                    n['read'] == true;
                final type =
                    n['type'] ?? 'GENERAL';
                final color =
                _getTypeColor(type);

                return GestureDetector(
                  onTap: () => markOneRead(n),
                  child: Container(
                    margin: const EdgeInsets
                        .only(bottom: 10),
                    padding:
                    const EdgeInsets.all(
                        16),
                    decoration: BoxDecoration(
                      color: isRead
                          ? Colors.white
                          : color
                          .withOpacity(
                          0.06),
                      borderRadius:
                      BorderRadius.circular(
                          14),
                      border: Border.all(
                        color: isRead
                            ? Colors
                            .grey.shade200
                            : color
                            .withOpacity(
                            0.3),
                        width: isRead ? 1 : 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey
                              .withOpacity(
                              0.06),
                          blurRadius: 8,
                          offset: const Offset(
                              0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                      children: [
                        // Icon
                        Container(
                          padding:
                          const EdgeInsets
                              .all(10),
                          decoration:
                          BoxDecoration(
                            color: color
                                .withOpacity(
                                0.1),
                            borderRadius:
                            BorderRadius
                                .circular(
                                10),
                          ),
                          child: Icon(
                            _getTypeIcon(type),
                            color: color,
                            size: 22,
                          ),
                        ),
                        const SizedBox(
                            width: 12),

                        // Content
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                            children: [
                              Text(
                                n['message'] ??
                                    '',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: const Color(
                                      0xFF1A1A2E),
                                  fontWeight: isRead
                                      ? FontWeight
                                      .w400
                                      : FontWeight
                                      .w600,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(
                                  height: 6),
                              Text(
                                n['createdAt'] ??
                                    '',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors
                                      .grey
                                      .shade500,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Unread dot
                        if (!isRead)
                          Container(
                            width: 8,
                            height: 8,
                            margin:
                            const EdgeInsets
                                .only(
                                top: 4,
                                left: 6),
                            decoration:
                            BoxDecoration(
                              color: color,
                              shape:
                              BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}