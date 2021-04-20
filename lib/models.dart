
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

  factory Task.fromJson(Map<String, Object> json) {
    var name = json["name"] as String;
    return Task(name);
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