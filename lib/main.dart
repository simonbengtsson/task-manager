import 'package:flutter/material.dart';

var weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

void main() {
  runApp(MyApp());
}

class Task {
  String text;
  DateTime createdAt;
  DateTime? completedAt;
  DateTime? date;

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

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Manager',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final List<Task> todayTasks = [
    Task('Next steps peach', DateTime.now()),
    Task('Nikhil code review', DateTime.now()),
  ];

  Task? activeTask;

  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
  }

  Widget buildTaskRow(BuildContext context, int index, Task task) {
    var textField = task == activeTask
        ? Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: 30),
              child: TextFormField(
                initialValue: task.text,
                autofocus: true,
                onEditingComplete: () {
                  setState(() {
                    activeTask = null;
                    if (task.text.isEmpty) {
                      todayTasks.removeAt(index);
                    }
                  });
                },
                onChanged: (text) {
                  task.text = text;
                },
                decoration: InputDecoration(
                    border: OutlineInputBorder(), hintText: 'Add Task'),
              ),
            ),
          )
        : ConstrainedBox(
            // To be able to easier edit tasks with small texts
            constraints: BoxConstraints(minWidth: 50),
            child: InkWell(
              onTap: () {
                setState(() {
                  activeTask = task;
                });
              },
              child: Text(task.text,
                  style: TextStyle(
                      color:
                          task.completedAt == null ? Colors.black : Colors.grey,
                      decoration: task.completedAt == null
                          ? TextDecoration.none
                          : TextDecoration.lineThrough)),
            ),
          );

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        border: Border.all(color: Colors.grey[100]!),
      ),
      key: Key(index.toString()),
      height: 50,
      child: Row(children: [
        Padding(
            padding: EdgeInsets.only(right: 10),
            child: IconButton(
              hoverColor: Colors.transparent,
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              icon: Icon(
                  task.completedAt == null
                      ? Icons.radio_button_unchecked
                      : Icons.check_circle,
                  color: Colors.grey[400]),
              onPressed: () {
                setState(() {
                  todayTasks[index].completedAt =
                      todayTasks[index].completedAt == null
                          ? DateTime.now()
                          : null;
                });
              },
            )),
        textField,
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    var now = DateTime.now();
    var days = List<Day>.generate(
        28,
        (int i) => Day(DateTime.fromMillisecondsSinceEpoch(
            now.millisecondsSinceEpoch +
                i * 24 * 3600 * 1000 -
                3600 * 1000 * 4)));

    var taskList = ReorderableListView(
      padding: EdgeInsets.symmetric(vertical: 20),
      scrollController: _scrollController,
      onReorder: (int oldIndex, int newIndex) {
        setState(() {
          if (oldIndex < newIndex) {
            newIndex -= 1;
          }
          var item = todayTasks.removeAt(oldIndex);
          todayTasks.insert(newIndex, item);
        });
      },
      children: [
        for (var entry in todayTasks.asMap().entries)
          buildTaskRow(context, entry.key, entry.value)
      ],
    );

    List<Widget> today = [
      Padding(
        padding: EdgeInsets.only(top: 30),
        child: Row(
          children: [
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Today',
                      style: TextStyle(fontSize: 28),
                    ),
                    Text(
                        "${weekdays[DateTime.now().weekday - 1]}, ${DateTime.now().day} April",
                        style: TextStyle(color: Colors.grey[600]))
                  ]),
            ),
            IconButton(
              icon: Icon(Icons.add),
              onPressed: () {
                _scrollController.animateTo(
                  // Without + 100 it didn't scroll all the way to the bottom
                  // The + 100 also added a nice bounce affect
                  _scrollController.position.maxScrollExtent + 100,
                  duration: Duration(milliseconds: 100),
                  curve: Curves.easeIn,
                );
                this.setState(() {
                  var task = Task.create();
                  activeTask = task;
                  todayTasks.add(task);
                });
              },
            ),
          ],
        ),
      ),
      Expanded(child: taskList),
    ];

    var dayList = ListView(
      scrollDirection: Axis.horizontal,
      children: days.map((day) {
        var color = Colors.grey[[6, 7].contains(day.date.weekday) ? 300 : 200];
        return Container(
          width: 120,
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: Colors.grey[100]!),
          ),
          child: Center(child: Text(weekdays[day.date.weekday - 1])),
        );
      }).toList(),
    );

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: today,
              ),
            ),
          ),
          Container(
            height: 200,
            child: dayList,
          )
        ],
      ),
    );
  }
}
