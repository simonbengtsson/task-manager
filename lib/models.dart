import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:icalendar_parser/icalendar_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppModel extends ChangeNotifier {

  AppModel() {
    Timer.periodic(Duration(minutes: 5), (timer) {
      loadCalendarEvents();
    });
    Timer.periodic(Duration(minutes: 1), (timer) {
      if (Day(this.today).daySince1970 != Day(DateTime.now()).daySince1970) {
        _today = DateTime.now();
        notifyListeners();
      }
    });

    ValueStore().loadTasks().then((tasks) {
      _tasks.addAll(tasks);
      notifyListeners();
    });
  }

  Future loadCalendarEvents() async {
    var newTasks = await ValueStore().loadCalendarEvents();
    print("Fetched events: ${newTasks.length}");
    _tasks.removeWhere((element) => element.fromCalendar);
    _tasks.addAll(newTasks);
    notifyListeners();
  }

  final List<Task> _tasks = [];
  UnmodifiableListView<Task> get tasks => UnmodifiableListView(_tasks);

  final List<Calendar> _calendar = [];
  UnmodifiableListView<Calendar> get calendar => UnmodifiableListView(_calendar);

  DateTime get today => _today;
  DateTime _today = DateTime.now();

  void moveTask(Task task, int index) {
    _tasks.remove(task);
    _tasks.insert(index, task);
    notify();
  }

  void removeTask(Task task) {
    _tasks.remove(task);
    notify();
  }

  void addTask(Task item, int? index) {
    if (index != null) {
      _tasks.insert(index, item);
    } else {
      _tasks.add(item);
    }
    notify();
  }

  void addCalendar(Calendar item) {
    _calendar.add(item);
    notify();
    loadCalendarEvents();
  }

  void notify() {
    notifyListeners();
    persist();
  }

  void loadDemoTasks() {
    _tasks.add(Task('Buy milk'));
    _tasks.add(Task('Run 5km'));
    _tasks.add(Task('Walk the dog'));

    var food = Task('Food Conference');
    food.date = DateTime.fromMillisecondsSinceEpoch(
        DateTime.now().millisecondsSinceEpoch - 48 * 3600 * 1000);
    _tasks.add(food);

    var yoga = Task('Yoga');
    yoga.date = DateTime.fromMillisecondsSinceEpoch(
        DateTime.now().millisecondsSinceEpoch + 24 * 3600 * 1000);
    _tasks.add(yoga);
    notify();
  }

  void persist() async {
    ValueStore().saveTasks(tasks);
    ValueStore().saveCalendars(_calendar);
  }
}

class Calendar {
  String url;
  String name;

  Calendar(this.url, this.name);

  factory Calendar.fromJson(Map<String, dynamic> json) {
    var url = json["url"] as String;
    var name = json["name"] as String;
    return Calendar(url, name);
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'url': url, 'name': name};
  }
}

class ValueStore {
  Future saveCalendars(List<Calendar> calendars) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var encoded = calendars.map((e) => e.toJson()).toList();
    String jsonString = jsonEncode(encoded);
    await prefs.setString('calendar_v2', jsonString);
  }

  Future<List<Calendar>> getCalendars() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String jsonString = prefs.getString('calendars_v2') ?? '[]';
    var saved = jsonDecode(jsonString) as List<dynamic>;
    return saved.map((dynamic e) => Calendar.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Task>> loadCalendarEvents() async {
    List<Calendar> saved = await getCalendars();

    List<Task> allTasks = [];
    for (var calendar in saved) {
      var res = await loadCalendarContent(calendar.url);
      final iCalendar = ICalendar.fromLines(res['fileLines'] as List<String>);
      final events =
        iCalendar.data!.where((element) => element['type'] == 'VEVENT' && Day(element['dtstart'] as DateTime).daySince1970 >= Day(DateTime.now()).daySince1970).toList();
      print(events[0]);
      var tasks = events.map((e) => Task.fromIcs(e)).toList();
      allTasks.addAll(tasks);
    }
    return allTasks;
  }

  Future<Map<String, dynamic>> loadCalendarContent(String calendarUrl) async {
    var res = await http.get(Uri.parse(calendarUrl));
    var lines = res.body.split('\r\n');
    var nameProperty = 'X-WR-CALNAME:';
    var nameLine = lines.firstWhere((line) => line.startsWith(nameProperty), orElse: () => 'Unknown');
    var name = nameLine.replaceAll(nameProperty, '').trim();
    return <String, dynamic>{'fileLines': lines, 'name': name};
  }

  Future<List<Task>> loadTasks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String jsonString = prefs.getString('tasks') ?? '[]';
    var saved = jsonDecode(jsonString) as List<dynamic>;
    var tasks = saved.map((dynamic e) => Task.fromJson(e as Map<String, dynamic>)).toList();
    return tasks;
  }

  Future saveTasks(List<Task> tasks) async {
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
    return completedAt != null || (fromCalendar && DateTime.now().millisecondsSinceEpoch > date!.millisecondsSinceEpoch);
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
