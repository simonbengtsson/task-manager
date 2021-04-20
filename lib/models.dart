import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ValueStore {
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
    prefs.setString('tasks', jsonString);
    return tasks;
  }
}

class Task {
  String text;
  DateTime? completedAt;
  DateTime? date;

  bool get done {
    return completedAt != null;
  }

  Task(this.text);

  factory Task.create() {
    return Task('');
  }

  Map<String, dynamic> toJson() {
    var map = { 'text': text };
    if (completedAt != null)
      map['completedAt'] = completedAt!.toIso8601String();
    if (date != null)
      map['date'] = date!.toIso8601String();
    return map;
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    var text = json["text"] as String;
    var dateString = json["date"] as String?;
    var completedAtString = json["completedAt"] as String?;

    var task = Task(text);
    if (dateString != null)
      task.date = DateTime.parse(dateString);
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
var months = ['Jan', 'Feb', 'Mar', 'Apr', 'May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];