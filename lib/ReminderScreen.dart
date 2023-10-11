import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class ReminderScreen extends StatefulWidget {
  @override
  _ReminderScreenState createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> {
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  TextEditingController timeController = TextEditingController();
  String selectedDay = "Monday";
  String selectedActivity = "Wake up";

  @override
  void initState() {
    super.initState();
    initializeNotifications();
  }

  void initializeNotifications() async {
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    var initializationSettingsAndroid =
        AndroidInitializationSettings('app_icon');
    var initializationSettingsIOS = IOSInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
        onDidReceiveLocalNotification:
            (int id, String? title, String? body, String? payload) async {});

    var initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid, iOS: initializationSettingsIOS);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onSelectNotification: (String? payload) async {});

    // Initialize timezone package
    tz.initializeTimeZones();
  }

  Future<void> scheduleNotification(
      String day, String time, String activity) async {
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'daily_notification',
      'Daily Notification',
      importance: Importance.max,
      priority: Priority.high,
      sound:
          RawResourceAndroidNotificationSound('notification'), // Add this line
    );

    var iOSPlatformChannelSpecifics = IOSNotificationDetails();
    var platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics);

    // Get current timezone
    var currentTimeZone = await tz.getLocation('New Delhi');
    tz.TZDateTime now = tz.TZDateTime.now(currentTimeZone);
    tz.TZDateTime notificationDateTime = tz.TZDateTime(
      currentTimeZone,
      now.year,
      now.month,
      now.day,
      int.parse(time.split(':')[0]),
      int.parse(time.split(':')[1]),
    ).add(Duration(days: dayToNumber(day) - now.weekday));

    if (notificationDateTime.isBefore(now)) {
      notificationDateTime = notificationDateTime.add(Duration(days: 7));
    }

    await flutterLocalNotificationsPlugin.zonedSchedule(
      0,
      activity,
      'Time for $activity!',
      notificationDateTime,
      platformChannelSpecifics,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidAllowWhileIdle: true,
    );
  }

  int dayToNumber(String day) {
    switch (day) {
      case "Monday":
        return 1;
      case "Tuesday":
        return 2;
      case "Wednesday":
        return 3;
      case "Thursday":
        return 4;
      case "Friday":
        return 5;
      case "Saturday":
        return 6;
      case "Sunday":
        return 7;
      default:
        return 1;
    }
  }

  // Added this method to show a success snackbar
  void showSuccessSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Reminder set successfully!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reminder App'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButton<String>(
              value: selectedDay,
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    selectedDay = newValue;
                  });
                }
              },
              items: <String>[
                'Monday',
                'Tuesday',
                'Wednesday',
                'Thursday',
                'Friday',
                'Saturday',
                'Sunday'
              ].map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
            SizedBox(height: 10),
            TextField(
              controller: timeController,
              decoration: InputDecoration(
                labelText: 'Select Time',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.access_time),
              ),
              readOnly: true,
              onTap: () async {
                TimeOfDay? selectedTime = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );
                if (selectedTime != null) {
                  timeController.text = selectedTime.format(context);
                }
              },
            ),
            SizedBox(height: 10),
            DropdownButton<String>(
              value: selectedActivity,
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    selectedActivity = newValue;
                  });
                }
              },
              items: <String>[
                'Wake up',
                'Go to gym',
                'Breakfast',
                'Meetings',
                'Lunch',
                'Quick nap',
                'Go to library',
                'Dinner',
                'Go to sleep'
              ].map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                scheduleNotification(
                    selectedDay, timeController.text, selectedActivity);
                showSuccessSnackbar(); // Show a success message
              },
              child: Text('Set Reminder'),
            ),
          ],
        ),
      ),
    );
  }
}
