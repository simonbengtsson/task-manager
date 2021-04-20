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
  List<Task> todayTasks = [];
  List<Day> days = [];
  Task? activeTask;
  bool demoMode = false;

  @override
  initState() {
    var now = DateTime.now();
    days = List<Day>.generate(5, (int i) {
      var timestamp = now.millisecondsSinceEpoch +
          (i + 1) * 24 * 3600 * 1000 -
          3600 * 1000 * 4;
      var date = DateTime.fromMillisecondsSinceEpoch(timestamp);
      var day = Day(date);
      return day;
    });

    ValueStore().loadTasks().then((tasks) {
      setState(() {
        todayTasks = tasks;
      });
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // Find a better place for this?
    if (!demoMode) {
      ValueStore().saveTasks(todayTasks);
    }

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
            onSelected: (value) async {
              var loadedTasks = await ValueStore().loadTasks();
              if (value == "demo") {
                setState(() {
                  demoMode = !demoMode;
                  if (demoMode) {
                    todayTasks = [];

                    todayTasks.add(Task('Buy milk'));
                    todayTasks.add(Task('Run 5km'));
                    todayTasks.add(Task('Walk the dog'));

                    var food = Task('Food Conference');
                    food.date = DateTime.fromMillisecondsSinceEpoch(DateTime.now().millisecondsSinceEpoch - 48 * 3600 * 1000);
                    todayTasks.add(food);

                    var yoga = Task('Yoga');
                    yoga.date = DateTime.fromMillisecondsSinceEpoch(DateTime.now().millisecondsSinceEpoch + 24 * 3600 * 1000);
                    todayTasks.add(yoga);
                  } else {
                    todayTasks = loadedTasks;
                  }
                });
              }
            },
            itemBuilder: (BuildContext context) {
              var item = PopupMenuItem<String>(
                value: "demo",
                child: Text(demoMode ? 'Turn off Demo' : "Switch to Demo"),
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
        var index = todayTasks.indexOf(details.data);
        todayTasks[index].date = null;
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
          for (var entry in todayTasks.where((element) {
            var date = element.date;
            if (date == null) return true;
            return Day(date).daySince1970 <= Day(DateTime.now()).daySince1970;
          }).toList().asMap().entries)
            buildTaskRow(context, entry.key, entry.value)
        ],
      );
    });
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
        var index = todayTasks.indexOf(details.data);
        todayTasks[index].date = day.date;
        //details.data.date = day.date;
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
    var dayTasks = todayTasks.where((element) {
      var date = element.date;
      if (date == null) return false;
      return Day(date).daySince1970 == day.daySince1970;
    });
    return Column(
      children: [
        for (var task in dayTasks)
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
                task.date = null;
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
