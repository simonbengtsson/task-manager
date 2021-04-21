import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:icalendar_parser/icalendar_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ValueStore {
  saveCalendars(List<String> calendarUrls) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String jsonString = jsonEncode(calendarUrls.toSet().toList());
    await prefs.setString('calendars', jsonString);
  }

  Future<List<String>> getCalendars() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String jsonString = prefs.getString('calendars') ?? '[]';
    List<dynamic> saved = jsonDecode(jsonString);
    return saved.map((e) => e as String).toList();
  }

  Future<List<Task>> loadCalendarEvents() async {
    List<String> saved = await getCalendars();

    List<Task> allTasks = [];
    for (var calendarUrl in saved) {
      var res = await http.get(Uri.parse(calendarUrl));
      var lines = res.body.split('\r\n');
      print("Lines: ${lines.length}");
      final calendar = ICalendar.fromLines(lines);
      final events =
        calendar.data!.where((element) => element['type'] == 'VEVENT' && Day(element['dtstart'] as DateTime).daySince1970 >= Day(DateTime.now()).daySince1970).toList();
      print(events[0]);
      var tasks = events.map((e) => Task.fromIcs(e)).toList();
      allTasks.addAll(tasks);
    }
    return allTasks;
  }

  Future<List<Task>> loadTasks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String jsonString = prefs.getString('tasks') ?? '[]';
    List<dynamic> saved = jsonDecode(jsonString);
    var tasks = saved.map((e) => Task.fromJson(e)).toList();
    return tasks;
  }

  saveTasks(List<Task> tasks) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var data = tasks.map((e) => e.toJson()).toList();
    String jsonString = jsonEncode(data);
    await prefs.setString('tasks', jsonString);
  }
}

Random random = Random();

String generateId() {
  const chars =
      'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
  int length = 10;
  var item = Iterable.generate(
      length, (_) => chars.codeUnitAt(random.nextInt(chars.length)));
  return String.fromCharCodes(item);
}

class Task {
  String text;
  String? calendarId;
  DateTime? completedAt;
  DateTime? date;

  bool get done {
    return completedAt != null;
  }

  bool get fromCalendar {
    return calendarId != null;
  }

  Task(this.text);

  factory Task.create() {
    return Task('');
  }

  Map<String, dynamic> toJson() {
    var map = {'text': text};
    if (completedAt != null)
      map['completedAt'] = completedAt!.toIso8601String();
    if (date != null) map['date'] = date!.toIso8601String();
    if (calendarId != null) map['calendarId'] = calendarId!;
    return map;
  }

  factory Task.fromIcs(Map<String, dynamic> ics) {
    var calendarId = ics["uid"] as String;
    var text = ics["summary"] as String;
    var startsAt = ics["dtstart"] as DateTime;

    var task = Task(text);
    task.calendarId = calendarId;
    task.date = startsAt;

    return task;
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    var text = json["text"] as String;
    var calendarId = json["calendarId"] as String?;
    var dateString = json["date"] as String?;
    var completedAtString = json["completedAt"] as String?;

    var task = Task(text);
    if (calendarId != null) task.calendarId = calendarId;
    if (dateString != null) task.date = DateTime.parse(dateString);
    if (completedAtString != null)
      task.completedAt = DateTime.parse(completedAtString);

    return task;
  }
}

class Day {
  DateTime date;

  Day(this.date);

  int get daySince1970 {
    return (date.millisecondsSinceEpoch / 1000 / 3600 / 24).floor();
  }
}

var weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
var months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec'
];
