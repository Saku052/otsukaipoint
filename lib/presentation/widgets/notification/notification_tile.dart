import 'package:flutter/material.dart';
import '../../../domain/entities/notification.dart' as entities;

/// 通知タイルウィジェット
class NotificationTile extends StatelessWidget {
  final entities.Notification notification;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const NotificationTile({
    super.key,
    required this.notification,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: _buildLeadingIcon(),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
            color: notification.isRead ? null : Colors.black87,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification.message,
              style: TextStyle(
                color: notification.isRead ? Colors.grey[600] : Colors.black54,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatDateTime(notification.createdAt),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'delete') {
              onDelete();
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('削除'),
                ],
              ),
            ),
          ],
        ),
        onTap: onTap,
        tileColor: notification.isRead ? null : Colors.blue.withValues(alpha: 0.05),
      ),
    );
  }

  Widget _buildLeadingIcon() {
    Color iconColor;
    IconData iconData;

    switch (notification.type) {
      case 'allowance_received':
        iconColor = Colors.green;
        iconData = Icons.attach_money;
        break;
      case 'item_added':
        iconColor = Colors.blue;
        iconData = Icons.add_shopping_cart;
        break;
      case 'item_completed':
        iconColor = Colors.orange;
        iconData = Icons.check_circle;
        break;
      case 'item_approved':
        iconColor = Colors.green;
        iconData = Icons.thumb_up;
        break;
      case 'item_rejected':
        iconColor = Colors.red;
        iconData = Icons.thumb_down;
        break;
      case 'family_invitation':
        iconColor = Colors.purple;
        iconData = Icons.family_restroom;
        break;
      case 'list_created':
        iconColor = Colors.indigo;
        iconData = Icons.list_alt;
        break;
      default:
        iconColor = Colors.grey;
        iconData = Icons.notifications;
        break;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 20,
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return '今';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}分前';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}時間前';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}日前';
    } else {
      return '${dateTime.month}/${dateTime.day}';
    }
  }
}