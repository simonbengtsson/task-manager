import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:icalendar_parser/icalendar_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Api {
  Future<ICalendar> fetchCalendar(String calendarUrl) async {
    var url = Uri.parse(calendarUrl);
    var res = await http.get(url);

    return ICalendar.fromString(res.body);
  }

  Future<List<Task>> fetchCalendarEvents() async {
    List<Calendar> saved = await ValueStore().getCalendars();

    List<Task> allTasks = [];
    for (var calendar in saved) {
      final iCalendar = await fetchCalendar(calendar.url);
      var tasks = parseCalendarTasks(iCalendar);
      allTasks.addAll(tasks);
    }
    return allTasks;
  }

  List<Task> parseCalendarTasks(ICalendar calendar) {
    final events = calendar.data!.where((element) {
      if (element['type'] != 'VEVENT') return false;
      var date = element['dtstart'] as DateTime;
      return Day.fromDate(date) >= Day.today().modified(-10);
    }).toList();
    return events.map((e) => Task.fromIcs(e)).toList();
  }
}

class AppModel extends ChangeNotifier {
  AppModel() {
    ICalendar.registerField(field: "X-WR-CALNAME");
    ICalendar.unregisterField("DTSTART");
    ICalendar.registerField(
        field: "DTSTART",
        function: (String value, Map<String, String> params, List events,
            Map<String, dynamic> lastEvent) {
          lastEvent['dtstart'] = DateTime.parse(value).toLocal();
          lastEvent['dtstart_allday'] = params['VALUE'] == 'DATE';
          return lastEvent;
        });

    Timer.periodic(Duration(minutes: 5), (timer) {
      updateCalendarEvents();
    });
    Timer.periodic(Duration(minutes: 1), (timer) {
      if (this.today != Day.today()) {
        _today = Day.today();
        notifyListeners();
      }
    });
    loadInitial();
  }

  Future loadInitial() async {
    var tasks = await ValueStore().getTasks();
    var calendars = await ValueStore().getCalendars();
    print("Tasks: ${tasks.length} Calendars: ${calendars.length}");
    _tasks.addAll(tasks);
    _calendars.addAll(calendars);
    notifyListeners();
  }

  final List<Task> _tasks = [];

  UnmodifiableListView<Task> get tasks => UnmodifiableListView(_tasks);

  List<Calendar> _calendars = [];

  UnmodifiableListView<Calendar> get calendars =>
      UnmodifiableListView(_calendars);

  Day get today => _today;
  Day _today = Day.today();

  Future updateCalendarEvents() async {
    var newTasks = await Api().fetchCalendarEvents();
    print("Fetched events: ${newTasks.length}");
    _tasks.removeWhere((element) => element.fromCalendar);
    _tasks.addAll(newTasks);
    print("Updated ${newTasks.length}");
    notify();
  }

  void moveTask(Task task, int index) {
    _tasks.remove(task);
    _tasks.insert(index, task);
    notify();
  }

  void toggleTaskCompletion(Task task) {
    if (task.completedAt == null) {
      task.completedAt = DateTime.now();
    } else {
      task.completedAt = null;
    }
    notify();
  }

  void changeTaskDate(Task task, Day newDay) {
    task.todoDay = newDay;
    notify();
  }

  void removeTask(Task task) {
    _tasks.remove(task);
    notify();
  }

  void removeAllTask() {
    _tasks.clear();
    notify();
  }

  void removeAllCalendars() {
    _calendars.clear();
    notify();
  }

  void removeCalendar(Calendar calendar) {
    _calendars.remove(calendar);
    persist().then((res) {
      updateCalendarEvents();
    });
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
    _calendars.add(item);
    persist().then((res) {
      updateCalendarEvents();
    });
  }

  Future notify() async {
    notifyListeners();
    await persist();
  }

  void loadDemoTasks() {
    _tasks.add(Task('Buy milk', Day.today()));
    _tasks.add(Task('Run 5km', Day.today()));
    _tasks.add(Task('Walk the dog', Day.today()));

    var food = Task('Food Conference', Day.today());
    food.todoDay = Day.today().modified(-2);
    _tasks.add(food);

    var yoga = Task('Yoga', Day.today());
    yoga.todoDay = Day.today().modified(1);
    _tasks.add(yoga);
    notify();
  }

  Future<void> persist() async {
    print("Persist: c ${calendars.length} t ${tasks.length}");
    await ValueStore().saveTasks(tasks);
    await ValueStore().saveCalendars(_calendars);
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
    await prefs.setString('calendars_v2', jsonString);
  }

  Future<List<Calendar>> getCalendars() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String jsonString = prefs.getString('calendars_v2') ?? '[]';
    var saved = jsonDecode(jsonString) as List<dynamic>;
    return saved
        .map((dynamic e) {
          try {
            return Calendar.fromJson(e as Map<String, dynamic>);
          } catch (ex) {
            print("Could not parse saved calendar: ${ex}");
            return null;
          }
        })
        .whereType<Calendar>()
        .toList();
  }

  Future<List<Task>> getTasks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String jsonString = prefs.getString('tasks') ?? '[]';
    var saved = jsonDecode(jsonString) as List<dynamic>;
    var tasks = saved
        .map((dynamic e) {
          try {
            return Task.fromJson(e as Map<String, dynamic>);
          } catch (ex) {
            print("Could not load task: ${ex}");
            return null;
          }
        })
        .whereType<Task>()
        .toList();
    return tasks;
  }

  Future saveTasks(List<Task> tasks) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var data = tasks.map((e) => e.toJson()).toList();
    String jsonString = jsonEncode(data);
    await prefs.setString('tasks', jsonString);
  }
}

class Task {
  String text;
  Day? todoDay;

  String? calendarId;
  DateTime? calendarDate;
  bool calendarAllDay = false;

  DateTime? completedAt;

  Task(this.text, this.todoDay);

  Day get day {
    if (fromCalendar) {
      var date = calendarDate!.toLocal();
      return Day(date.year, date.month, date.day);
    } else {
      return todoDay! <= Day.today() ? Day.today() : todoDay!;
    }
  }

  bool get done {
    return completedAt != null ||
        (fromCalendar &&
            DateTime.now().millisecondsSinceEpoch >
                calendarDate!.millisecondsSinceEpoch);
  }

  bool get fromCalendar {
    return calendarId != null;
  }

  Map<String, dynamic> toJson() {
    var map = {'text': text};
    if (fromCalendar) {
      map['calendarId'] = calendarId!;
      map['calendarDate'] = calendarDate!.toUtc().toIso8601String();
      map['calendarAllDay'] = calendarAllDay.toString();
    } else {
      map['todoDay'] = todoDay.toString();
      if (completedAt != null)
        map['completedAt'] = completedAt!.toUtc().toIso8601String();
    }
    return map;
  }

  factory Task.fromIcs(Map<String, dynamic> ics) {
    var calendarId = ics["uid"] as String;
    var text = ics["summary"] as String;
    var startsAt = ics["dtstart"] as DateTime;
    var allDay = ics["dtstart_allday"] as bool;

    var task = Task(text, null);
    task.calendarId = calendarId;
    task.calendarDate = startsAt;
    task.calendarAllDay = allDay;

    return task;
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    var text = json["text"] as String;
    var calendarId = json["calendarId"] as String?;
    var calendarDate = json["calendarDate"] as String?;
    var calendarAllDay = json["calendarAllDay"] as String?;
    var todoDay = json["todoDay"] as String?;
    var completedAt = json["completedAt"] as String?;

    var task = Task(text, null);
    if (calendarId != null) {
      task.calendarId = calendarId;
      task.calendarAllDay = calendarAllDay!.toLowerCase() == 'true';
      task.calendarDate = DateTime.parse(calendarDate!);
    } else {
      task.todoDay = Day.fromDate(DateTime.parse(todoDay!));
      if (completedAt != null)
        task.completedAt = DateTime.parse(completedAt).toLocal();
    }

    return task;
  }
}

class Day {
  int year;
  int month;
  int day;

  DateTime get date {
    return DateTime(year, month, day);
  }

  Day(this.year, this.month, this.day);

  factory Day.fromDate(DateTime date) {
    var local = date.toLocal();
    return Day(local.year, local.month, local.day);
  }

  factory Day.today() {
    return Day.fromDate(DateTime.now());
  }

  String toString() {
    var date = DateTime(year, month, day);
    return date.toIso8601String().substring(0, 10);
  }

  bool operator <=(Day other) => this.compareTo(other) <= 0;

  bool operator >=(Day other) => this.compareTo(other) >= 0;

  bool operator <(Day other) => this.compareTo(other) < 0;

  bool operator >(Day other) => this.compareTo(other) > 0;

  bool operator ==(other) => other is Day && this.compareTo(other) == 0;

  Day modified(int days) {
    var date = DateTime(year, month, day);
    var time = date.millisecondsSinceEpoch;
    var newTime = time += days * 24 * 3600 * 1000;
    var newDate = DateTime.fromMillisecondsSinceEpoch(newTime);
    return Day(newDate.year, newDate.month, newDate.day);
  }

  int compareTo(Day other) {
    return toString().compareTo(other.toString());
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
