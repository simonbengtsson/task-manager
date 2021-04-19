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

  List<Day> days = [];

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
                  "${weekdays[DateTime.now().weekday - 1]}, ${DateTime.now().day} ${months[DateTime.now().month - 1]}",
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
    return DragTarget<Task>(onAcceptWithDetails: (details) {
      setState(() {
        todayTasks.add(details.data);
      });
    }, builder: (context, candidateItems, rejectedItems) {
      return ListView(
        padding: EdgeInsets.symmetric(vertical: 20),
        /*onReorder: (int oldIndex, int newIndex) {
          setState(() {
            if (oldIndex < newIndex) {
              newIndex -= 1;
            }
            var item = todayTasks.removeAt(oldIndex);
            todayTasks.insert(newIndex, item);
          });
        },*/
        children: [
          for (var entry in todayTasks.asMap().entries)
            buildTaskRow(context, entry.key, entry.value)
        ],
      );
    });
  }

  @override
  initState() {
    var now = DateTime.now();
    days = List<Day>.generate(28, (int i) {
      var timestamp = now.millisecondsSinceEpoch +
          (i + 1) * 24 * 3600 * 1000 -
          3600 * 1000 * 4;
      var date = DateTime.fromMillisecondsSinceEpoch(timestamp);
      var day = Day(date);
      if (i == 0) {
        day.tasks.add(Task("Peach tickets", DateTime.now()));
      }
      return day;
    });
    super.initState();
  }

  Widget buildCalendar(BuildContext context) {
    return Container(
      height: 240,
      child: ListView(
          scrollDirection: Axis.horizontal,
          children: [for (var day in days) buildCalendarDay(day)]),
    );
  }

  Widget buildCalendarDay(Day day) {
    return DragTarget<Task>(onAcceptWithDetails: (details) {
      setState(() {
        day.tasks.add(details.data);
      });
    }, builder: (context, candidateItems, rejectedItems) {
      return Container(
        width: 200,
        decoration: BoxDecoration(
          color: Colors.grey[[6, 7].contains(day.date.weekday) ? 300 : 200],
          border: Border.all(color: Colors.grey[100]!),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  "${weekdays[day.date.weekday - 1]} ${day.date.day}",
                  style: TextStyle(
                      fontWeight: FontWeight.w500, color: Colors.grey[500]),
                ),
              ),
              buildCalendarDayTaskList(day),
            ],
          ),
        ),
      );
    });
  }

  Widget buildCalendarDayTaskList(Day day) {
    return Column(
      children: [
        for (var task in day.tasks)
          LongPressDraggable(
            feedback: Row(children: [
              ConstrainedBox(
                constraints: BoxConstraints(minWidth: 300),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        blurRadius: 7,
                      ),
                    ],
                  ),
                  padding: EdgeInsets.all(10),
                  child: Text(task.text,
                      style: TextStyle(
                          fontSize: 15,
                          color:
                          task.completedAt == null ? Colors.black : Colors.grey,
                          decoration: task.completedAt == null
                              ? TextDecoration.none
                              : TextDecoration.lineThrough)),
                ),
              ),
            ]),
            data: task,
            dragAnchorStrategy: pointerDragAnchorStrategy,
            onDragCompleted: () {
              setState(() {
                day.tasks.remove(task);
              });
            },
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 5.0),
                  child: Icon(
                    Icons.radio_button_unchecked,
                    size: 14,
                    color: Colors.grey[600],
                  ),
                ),
                Text(task.text),
              ],
            ),
          ),
      ],
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

    return LongPressDraggable(
      data: task,
      dragAnchorStrategy: pointerDragAnchorStrategy,
      feedback: Row(children: [
        ConstrainedBox(
          constraints: BoxConstraints(minWidth: 300),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[200],
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  blurRadius: 7,
                ),
              ],
            ),
            padding: EdgeInsets.all(10),
            child: Text(task.text,
                style: TextStyle(
                    fontSize: 15,
                    color:
                        task.completedAt == null ? Colors.black : Colors.grey,
                    decoration: task.completedAt == null
                        ? TextDecoration.none
                        : TextDecoration.lineThrough)),
          ),
        ),
      ]),
      onDragCompleted: () {
        todayTasks.remove(task);
      },
      child: Container(
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
      ),
    );
  }
}
