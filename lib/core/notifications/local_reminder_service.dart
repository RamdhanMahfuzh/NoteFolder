import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:notefolder/domain/entities/note_entity.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class LocalReminderService {
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  bool get _isSupported => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  Future<void> initialize() async {
    if (!_isSupported || _initialized) return;
    tz_data.initializeTimeZones();
    final timezone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timezone.identifier));
    await _notifications.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_launcher_foreground'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    _initialized = true;
  }

  Future<bool> scheduleDeadline(NoteEntity note) async {
    if (!_isSupported) return false;
    await initialize();
    final notificationId = _notificationId(note.id);
    await _notifications.cancel(id: notificationId);
    final deadline = note.deadline;
    if (deadline == null || !deadline.isAfter(DateTime.now())) return true;

    final permissionGranted = await _requestPermission();
    if (!permissionGranted) return false;

    await _notifications.zonedSchedule(
      id: notificationId,
      title: 'Note deadline',
      body: '"${note.title}" today\'s deadline',
      scheduledDate: tz.TZDateTime.from(deadline, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'deadline_reminders',
          'Deadline reminders',
          channelDescription: 'Notifications when a note deadline arrives',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
        ),
        iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: note.id,
    );
    return true;
  }

  Future<void> cancelDeadline(String noteId) async {
    if (!_isSupported) return;
    await initialize();
    await _notifications.cancel(id: _notificationId(noteId));
  }

  Future<bool> _requestPermission() async {
    if (Platform.isAndroid) {
      final android = _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      return await android?.requestNotificationsPermission() ?? true;
    }
    final ios = _notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    return await ios?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        ) ??
        false;
  }

  int _notificationId(String noteId) {
    var hash = 0x811c9dc5;
    for (final codeUnit in noteId.codeUnits) {
      hash = ((hash ^ codeUnit) * 0x01000193) & 0x7fffffff;
    }
    return hash;
  }
}
