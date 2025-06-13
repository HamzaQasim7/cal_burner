import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/daily_activity_model.dart';

class ActivityRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Save daily activity
  Future<void> saveDailyActivity(DailyActivity activity) async {
    try {
      await _firestore
          .collection('users')
          .doc(activity.userId)
          .collection('daily_activities')
          .doc(activity.id)
          .set(activity.toJson());

      // Save to local storage as backup
      await _saveToLocal(activity);
    } catch (e) {
      print('Error saving daily activity: $e');
      throw Exception('Failed to save daily activity');
    }
  }

  // Get today's activity
  Future<DailyActivity?> getTodayActivity(String userId) async {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);

    try {
      final querySnapshot =
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('daily_activities')
              .where(
                'date',
                isGreaterThanOrEqualTo: todayStart.toIso8601String(),
              )
              .where(
                'date',
                isLessThan: todayStart.add(Duration(days: 1)).toIso8601String(),
              )
              .limit(1)
              .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        return DailyActivity.fromJson({'id': doc.id, ...doc.data()});
      }
    } catch (e) {
      print('Error getting today activity: $e');
    }
    return null;
  }

  // Get weekly activities
  Future<List<DailyActivity>> getWeeklyActivities(
    String userId,
    DateTime weekStart,
  ) async {
    final weekEnd = weekStart.add(Duration(days: 7));

    try {
      final querySnapshot =
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('daily_activities')
              .where(
                'date',
                isGreaterThanOrEqualTo: weekStart.toIso8601String(),
              )
              .where('date', isLessThan: weekEnd.toIso8601String())
              .orderBy('date')
              .get();

      return querySnapshot.docs
          .map((doc) => DailyActivity.fromJson({'id': doc.id, ...doc.data()}))
          .toList();
    } catch (e) {
      print('Error getting weekly activities: $e');
      return [];
    }
  }

  // Get monthly activities
  Future<List<DailyActivity>> getMonthlyActivities(
    String userId,
    DateTime monthStart,
  ) async {
    final monthEnd = DateTime(monthStart.year, monthStart.month + 1, 1);

    try {
      final querySnapshot =
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('daily_activities')
              .where(
                'date',
                isGreaterThanOrEqualTo: monthStart.toIso8601String(),
              )
              .where('date', isLessThan: monthEnd.toIso8601String())
              .orderBy('date')
              .get();

      return querySnapshot.docs
          .map((doc) => DailyActivity.fromJson({'id': doc.id, ...doc.data()}))
          .toList();
    } catch (e) {
      print('Error getting monthly activities: $e');
      return [];
    }
  }

  // Update today's activity
  Future<void> updateTodayActivity(DailyActivity activity) async {
    try {
      await _firestore
          .collection('users')
          .doc(activity.userId)
          .collection('daily_activities')
          .doc(activity.id)
          .update(activity.copyWith(updatedAt: DateTime.now()).toJson());

      await _saveToLocal(activity);
    } catch (e) {
      print('Error updating today activity: $e');
      throw Exception('Failed to update today activity');
    }
  }

  // Save to local storage
  Future<void> _saveToLocal(DailyActivity activity) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'activity_${activity.userId}_${activity.dateString}';
      await prefs.setString(key, activity.toJson().toString());
    } catch (e) {
      print('Error saving to local storage: $e');
    }
  }

  // Get from local storage
  Future<DailyActivity?> getTodayActivityFromLocal(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now();
      final dateString = "${today.day}/${today.month}/${today.year}";
      final key = 'activity_${userId}_$dateString';
      final activityData = prefs.getString(key);

      if (activityData != null) {
        // Note: You'd need to properly parse this JSON string
        // This is a simplified version
        return null; // Return parsed activity
      }
    } catch (e) {
      print('Error getting activity from local storage: $e');
    }
    return null;
  }
}
