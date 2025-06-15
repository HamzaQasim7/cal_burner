import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  // Notification channels
  static const String stepGoalChannelId = 'step_goal_channel';
  static const String reminderChannelId = 'reminder_channel';
  static const String achievementChannelId = 'achievement_channel';

  Future<void> initialize() async {
    // Initialize timezone data
    tz.initializeTimeZones();

    // Android initialization settings
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    // Create notification channels for Android
    if (Platform.isAndroid) {
      await _createNotificationChannels();
    }

    // Request permissions for iOS
    if (Platform.isIOS) {
      await _requestIOSPermissions();
    }
  }

  Future<void> _createNotificationChannels() async {
    const List<AndroidNotificationChannel> channels = [
      AndroidNotificationChannel(
        stepGoalChannelId,
        'Step Goals',
        description: 'Notifications for step goal achievements',
        importance: Importance.high,
        sound: RawResourceAndroidNotificationSound('notification_sound'),
      ),
      AndroidNotificationChannel(
        reminderChannelId,
        'Walking Reminders',
        description: 'Reminders to walk and stay active',
        importance: Importance.defaultImportance,
      ),
      AndroidNotificationChannel(
        achievementChannelId,
        'Achievements',
        description: 'Fitness achievements and milestones',
        importance: Importance.high,
        sound: RawResourceAndroidNotificationSound('achievement_sound'),
      ),
    ];

    for (final channel in channels) {
      await _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(channel);
    }
  }

  Future<void> _requestIOSPermissions() async {
    await _notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  void _onNotificationResponse(NotificationResponse response) {
    // Handle notification tap
    final payload = response.payload;
    if (payload != null) {
      print('Notification tapped with payload: $payload');
      // Navigate to specific screen based on payload
      _handleNotificationPayload(payload);
    }
  }

  void _handleNotificationPayload(String payload) {
    // Parse payload and navigate accordingly
    switch (payload) {
      case 'step_goal_achieved':
        // Navigate to stats screen
        break;
      case 'walking_reminder':
        // Navigate to main screen
        break;
      case 'weekly_summary':
        // Navigate to weekly stats
        break;
      default:
        // Navigate to home screen
        break;
    }
  }

  // Show step goal achievement notification
  Future<void> showStepGoalAchieved({
    required int steps,
    required int goal,
    required double caloriesBurned,
    required double distance,
  }) async {
    const NotificationDetails notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        stepGoalChannelId,
        'Step Goals',
        channelDescription: 'Notifications for step goal achievements',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        styleInformation: BigTextStyleInformation(
          'Congratulations! You\'ve reached your daily step goal. Keep up the great work!',
        ),
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _notifications.show(
      1,
      '🎉 Goal Achieved!',
      '$steps steps completed! Burned ${caloriesBurned.toStringAsFixed(0)} calories and walked ${distance.toStringAsFixed(2)} km',
      notificationDetails,
      payload: 'step_goal_achieved',
    );
  }

  // Show milestone achievement notification
  Future<void> showMilestoneAchieved({
    required String milestone,
    required String description,
  }) async {
    const NotificationDetails notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        achievementChannelId,
        'Achievements',
        channelDescription: 'Fitness achievements and milestones',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@drawable/ic_achievement',
        largeIcon: DrawableResourceAndroidBitmap('@drawable/ic_achievement'),
        styleInformation: BigTextStyleInformation(''),
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _notifications.show(
      2,
      '🏆 $milestone',
      description,
      notificationDetails,
      payload: 'milestone_achieved',
    );
  }

  // Show walking reminder notification
  Future<void> showWalkingReminder() async {
    const NotificationDetails notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        reminderChannelId,
        'Walking Reminders',
        channelDescription: 'Reminders to walk and stay active',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        icon: '@drawable/ic_walk',
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: false,
        presentSound: true,
      ),
    );

    await _notifications.show(
      3,
      '👟 Time to Walk!',
      'You\'ve been inactive for a while. Take a short walk to stay healthy!',
      notificationDetails,
      payload: 'walking_reminder',
    );
  }

  // Schedule daily step goal reminder
  Future<void> scheduleDailyStepReminder({
    required int hour,
    required int minute,
    required int stepGoal,
  }) async {
    await _notifications.zonedSchedule(
      4,
      '📊 Daily Step Check',
      'How are you doing with your $stepGoal step goal today?',
      _nextInstanceOfTime(hour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          reminderChannelId,
          'Walking Reminders',
          channelDescription: 'Daily step goal reminders',
          importance: Importance.defaultImportance,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,

      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'daily_reminder',
    );
  }

  // Schedule weekly summary notification
  Future<void> scheduleWeeklySummary({
    required int weekday, // 1 = Monday, 7 = Sunday
    required int hour,
    required int minute,
  }) async {
    await _notifications.zonedSchedule(
      5,
      '📈 Weekly Summary',
      'Check out your weekly fitness progress!',
      _nextInstanceOfWeekday(weekday, hour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          reminderChannelId,
          'Walking Reminders',
          channelDescription: 'Weekly fitness summaries',
          importance: Importance.defaultImportance,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      payload: 'weekly_summary',
    );
  }

  // Schedule inactivity reminder
  Future<void> scheduleInactivityReminder({
    required Duration inactivityPeriod,
  }) async {
    final scheduledDate = tz.TZDateTime.now(tz.local).add(inactivityPeriod);

    await _notifications.zonedSchedule(
      6,
      '🚶‍♂️ Move Time!',
      'You\'ve been sitting for a while. Time to get moving!',
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          reminderChannelId,
          'Walking Reminders',
          channelDescription: 'Inactivity reminders',
          importance: Importance.defaultImportance,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,

      payload: 'inactivity_reminder',
    );
  }

  // Show custom notification
  Future<void> showCustomNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    NotificationDetails? notificationDetails,
  }) async {
    final details =
        notificationDetails ??
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'default_channel',
            'Default',
            channelDescription: 'Default notifications',
            importance: Importance.defaultImportance,
          ),
          iOS: DarwinNotificationDetails(),
        );

    await _notifications.show(id, title, body, details, payload: payload);
  }

  // Cancel specific notification
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  // Get pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  // Helper method to get next instance of a specific time
  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  // Helper method to get next instance of a specific weekday and time
  tz.TZDateTime _nextInstanceOfWeekday(int weekday, int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    while (scheduledDate.weekday != weekday) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 7));
    }

    return scheduledDate;
  }

  // Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    if (Platform.isAndroid) {
      final androidImplementation =
          _notifications
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();
      return await androidImplementation?.areNotificationsEnabled() ?? false;
    } else if (Platform.isIOS) {
      final iosImplementation =
          _notifications
              .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin
              >();
      final settings = await iosImplementation?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return settings ?? false;
    }
    return false;
  }

  // Request notification permissions (especially for Android 13+)
  Future<bool> requestNotificationPermissions() async {
    if (Platform.isAndroid) {
      final androidImplementation =
          _notifications
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();
      return await androidImplementation?.requestNotificationsPermission() ??
          false;
    }
    return true; // iOS permissions are requested during initialization
  }
}
