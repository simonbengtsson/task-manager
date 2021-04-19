
class Task {
  String text;
  DateTime createdAt;
  DateTime? completedAt;
  DateTime? date;

  bool get done {
    return completedAt != null;
  }

  Task(this.text, this.createdAt);

  factory Task.create() {
    return Task('', DateTime.now());
  }

  factory Task.fromJson(Map<String, Object> json) {
    var name = json["name"] as String;
    var createdAt = json["createdAt"] as DateTime;
    return Task(name, createdAt);
  }
}

class Day {
  List<Task> tasks = [];
  DateTime date;

  Day(this.date);
}

var weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
var months = ['Jan', 'Feb', 'Mar', 'Apr', 'May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];