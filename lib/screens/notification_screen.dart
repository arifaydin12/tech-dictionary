import 'package:flutter/material.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> notifications = [
      {'title': 'Yeni kelime eklendi', 'body': '"API" terimi eklendi.'},
      {'title': 'Favori terim', 'body': '"Flutter" favorilere eklendi.'},
      {'title': 'Güncelleme', 'body': 'Uygulama güncellendi.'},
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Bildirimler')),
      body: notifications.isEmpty
          ? Center(child: Text('Henüz bir bildirim yok.', style: Theme.of(context).textTheme.bodyLarge))
          : ListView.separated(
              itemCount: notifications.length,
              separatorBuilder: (_, __) => Divider(height: 1),
              itemBuilder: (context, index) {
                final notif = notifications[index];
                return ListTile(
                  leading: Icon(Icons.notifications, color: Theme.of(context).colorScheme.primary),
                  title: Text(notif['title'] ?? '', style: Theme.of(context).textTheme.titleMedium),
                  subtitle: Text(notif['body'] ?? '', style: Theme.of(context).textTheme.bodyMedium),
                );
              },
            ),
    );
  }
}
