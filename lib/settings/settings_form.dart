import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rembirth/settings/settings_controller.dart';

class SettingsPageWidget extends StatelessWidget {
  const SettingsPageWidget({super.key});

  @override
  Widget build(BuildContext context) {
    void showStatus(String message) {
      if (message.isEmpty) return;

      ScaffoldMessenger.of(context)
        ..removeCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(message),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 6,
          ),
        );
    }

    final settingsController = context.watch<SettingsController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // --- Dark Mode Toggle ---
          SwitchListTile(
            title: const Text('Dark Mode'),
            value: settingsController.settings.isDarkMode,
            onChanged: (isEnabled) {
              context.read<SettingsController>().setDarkModeEnabled(isEnabled);
              showStatus('Switched to ${isEnabled ? "Dark Mode" : "Light Mode"}');
            },
          ),

          // --- Notifications Toggle ---
          const Divider(),
          SwitchListTile(
            title: const Text('Enable Notifications'),
            value: settingsController.settings.notificationsEnabled,
            onChanged: (isEnabled) async {
              await context.read<SettingsController>().setNotificationsEnabled(isEnabled);
              showStatus('Notifications ${isEnabled ? "enabled" : "disabled"}');
            },
          ),

          // --- Notification Time Picker ---
          ListTile(
            title: const Text('Notification Time'),
            subtitle: Text(settingsController.settings.notificationTime.format(context)),
            trailing: const Icon(Icons.schedule, size: 32),
            enabled: settingsController.settings.notificationsEnabled,
            onTap: () async {
              final pickedTime = await showTimePicker(
                context: context,
                initialTime: settingsController.settings.notificationTime,
              );

              if (!context.mounted) return;

              if (pickedTime != null) {
                await context.read<SettingsController>().updateNotificationTime(pickedTime);
                if (!context.mounted) return;
                showStatus('Notification time set to ${pickedTime.format(context)}');
              }
            },
          ),

          // --- About ---
          const Divider(),
          ListTile(title: const Text('About'), subtitle: const Text('Rembirth v1.0.0'), onTap: () => {}),
        ],
      ),
    );
  }
}
