import 'package:flutter/material.dart';

import 'models.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  MainScreen({Key? key}) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final List<Task> todayTasks = [
    Task('Buy milk', DateTime.now()),
    Task('Run 5km', DateTime.now()),
    Task('Walk the dog', DateTime.now()),
  ];

  Task? activeTask;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildHeader(context),
                  Expanded(child: buildTaskList(context)),
                ],
              ),
            ),
          ),
          buildCalendar(context),
        ],
      ),
    );
  }

  Widget buildHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 30),
      child: Row(
        children: [
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
              this.setState(() {
                var task = Task.create();
                activeTask = task;
                todayTasks.insert(0, task);
              });
            },
          ),
          PopupMenuButton(
            icon: Icon(Icons.more_horiz),
            onSelected: (value) {
              if (value == "settings") {
                print("Settings clicked");
              }
            },
            itemBuilder: (BuildContext context) {
              var item = PopupMenuItem<String>(
                value: "settings",
                child: Text("Settings"),
              );
              return [item];
            },
          ),
        ],
      ),
    );
  }

  Widget buildTaskList(BuildContext context) {
    return ReorderableListView(
      padding: EdgeInsets.symmetric(vertical: 20),
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
  }

  Widget buildCalendar(BuildContext context) {
    var now = DateTime.now();
    var days = List<Day>.generate(
        28,
            (int i) => Day(DateTime.fromMillisecondsSinceEpoch(
            now.millisecondsSinceEpoch +
                (i + 1) * 24 * 3600 * 1000 -
                3600 * 1000 * 4)));

    return Container(
      height: 200,
      child: ListView(scrollDirection: Axis.horizontal, children: [
        for (var day in days)
          Container(
            width: 120,
            decoration: BoxDecoration(
              color: Colors.grey[[6, 7].contains(day.date.weekday) ? 300 : 200],
              border: Border.all(color: Colors.grey[100]!),
            ),
            child: Center(child: Text(weekdays[day.date.weekday - 1])),
          )
      ]),
    );
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
                  var doneIndex =
                      todayTasks.indexWhere((element) => element.done);
                  if (task.done) {
                    var firstCompletedIndex =
                        doneIndex < 0 ? todayTasks.length - 1 : doneIndex;
                    task.completedAt = null;
                    var index = todayTasks.indexOf(task);
                    var item = todayTasks.removeAt(index);
                    todayTasks.insert(firstCompletedIndex, item);
                  } else {
                    var firstCompletedIndex =
                        doneIndex < 0 ? todayTasks.length - 1 : doneIndex - 1;
                    task.completedAt = DateTime.now();
                    todayTasks.remove(task);
                    todayTasks.insert(firstCompletedIndex, task);
                  }
                });
              },
            )),
        textField,
      ]),
    );
  }
}
