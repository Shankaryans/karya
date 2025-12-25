import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/task.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  // Navigator key for showing dialogs from non-UI code
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  final Map<String, AudioPlayer> _ringPlayers = {};

  Future<void> _startRingtone(String id) async {
    stopRingtone(id);

    // Get selected asset from settings box
    try {
      final box = Hive.box('settings');
      final asset = box.get('notificationSound') as String?;

      if (asset == null) {
        // fallback to a short system alert if no asset configured
        _ringPlayers[id] = AudioPlayer()..play(DeviceFileSource(''));
        SystemSound.play(SystemSoundType.alert);
        return;
      }

      final player = AudioPlayer();
      // Loop the asset until stopped
      await player.setReleaseMode(ReleaseMode.loop);
      final assetPath = asset.startsWith('assets/')
          ? asset.substring('assets/'.length)
          : asset;
      await player.play(AssetSource(assetPath));
      _ringPlayers[id] = player;
    } catch (e) {
      // On any error fallback to SystemSound
      SystemSound.play(SystemSoundType.alert);
    }
  }

  void stopRingtone(String id) {
    final player = _ringPlayers[id];
    if (player != null) {
      player.stop();
      player.dispose();
      _ringPlayers.remove(id);
    }
  }

  /// Show modal alert for a task (isStart = true for start alert, false for end alert)
  /// isPreNotification = true for 10-min pre-alert
  /// onSnooze/onStop are callbacks executed when user selects those actions.
  void showTaskAlert(
    Task task, {
    required bool isStart,
    bool isPreNotification = false,
    required VoidCallback onSnooze,
    required VoidCallback onStop,
  }) {
    final ctx = navigatorKey.currentContext;
    if (ctx == null) return;

    // Start ringtone
    _startRingtone(task.id);

    showDialog(
      context: ctx,
      barrierDismissible: false,
      builder: (context) {
        final titleText = isPreNotification
            ? 'Task Starting Soon'
            : isStart
            ? 'Task Starting'
            : 'Task Ended';

        return AlertDialog(
          title: Text(titleText),
          content: Text(
            '${task.title}\n'
            '${task.dueDate.month}/${task.dueDate.day}/${task.dueDate.year}\n'
            '${task.getStartTime().format(context)} - ${task.getEndTime().format(context)}'
            '\n\n${isPreNotification ? '(Starting in 10 minutes)' : ''}',
          ),
          actions: [
            TextButton(
              onPressed: () {
                stopRingtone(task.id);
                onSnooze();
                Navigator.of(context).pop();
              },
              child: Text(isPreNotification ? 'Remind Later' : 'Snooze 10m'),
            ),
            TextButton(
              onPressed: () {
                stopRingtone(task.id);
                onStop();
                Navigator.of(context).pop();
              },
              child: const Text('Stop'),
            ),
          ],
        );
      },
    );
  }
}
