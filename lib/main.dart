import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'models.dart';

void main() {
  runApp(ChangeNotifierProvider(create: (ctx) => AppModel(), child: MyApp()));
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
  Task? activeTask;

  @override
  initState() {
    super.initState();
  }

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
              Consumer<AppModel>(
                builder: (context, model, child) {
                  return Text(
                      "${weekdays[model.today.weekday - 1]}, ${model.today.day} ${months[model.today.month - 1]}",
                      style: TextStyle(color: Colors.grey[600]));
                },
              ),
            ]),
          ),
          Consumer<AppModel>(
            builder: (context, model, child) => Tooltip(
              message: 'Add Task',
              child: IconButton(
                icon: Icon(Icons.add),
                onPressed: () {
                  this.setState(() {
                    var task = Task.create();
                    activeTask = task;
                    model.addTask(task, 0);
                  });
                },
              ),
            ),
          ),
          Consumer<AppModel>(
              builder: (context, model, child) => PopupMenuButton(
                    icon: Icon(Icons.more_horiz),
                    onSelected: (value) async {
                      if (value == "demo") {
                        setState(() {
                          model.loadDemoTasks();
                        });
                      } else if (value == "removeAllTasks") {
                        print("Not implemented yet");
                      } else if (value == "addCalendar") {
                        presentAddCalendarDialog(context);
                      } else if (value == "removeAllCalendars") {
                        print("Not implemented yet");
                      }
                    },
                    itemBuilder: (BuildContext context) {
                      var demo = PopupMenuItem<String>(
                        value: "demo",
                        child: Text('Load Demo Tasks'),
                      );
                      var rmTasks = PopupMenuItem<String>(
                        value: "removeAllTasks",
                        child: Text('Remove all Tasks'),
                      );
                      var rmCalendars = PopupMenuItem<String>(
                        value: "removeAllCalendars",
                        child: Text('Remove all Calendars'),
                      );
                      var addCalendar = PopupMenuItem<String>(
                        value: "addCalendar",
                        child: Text('Add Calendar'),
                      );
                      return [addCalendar, demo, rmTasks, rmCalendars];
                    },
                  )),
        ],
      ),
    );
  }

  TextEditingController _textFieldController = TextEditingController();

  Future<dynamic> presentAddCalendarDialog(BuildContext context) {
    return showDialog<dynamic>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add Calendar'),
          content: TextField(
            autofocus: true,
            controller: _textFieldController,
            decoration: InputDecoration(hintText: "Calendar URL"),
          ),
          actions: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: TextButton(
                child: Text('CANCEL'),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ),
            Consumer<AppModel>(
              builder: (context, AppModel model, child) => Padding(
                padding:
                    const EdgeInsets.only(left: 0, bottom: 8.0, top: 8, right: 8),
                child: TextButton(
                  child: Text('ADD'),
                  onPressed: () async {
                    Navigator.pop(context);
                    print(_textFieldController.text);
                    var calendars = await ValueStore().getCalendars();
                    calendars.add(_textFieldController.text);
                    await ValueStore().saveCalendars(calendars);
                    await model.loadCalendarEvents();
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget buildTaskList(BuildContext context) {
    return DragTarget<Task>(onAcceptWithDetails: (details) {
      setState(() {
        details.data.date = null;
      });
    }, builder: (context, candidateItems, rejectedItems) {
      return Consumer<AppModel>(
        builder: (ctx, model, child) => ListView(
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
            for (var entry in model.tasks
                .where((element) {
                  var date = element.date;
                  if (date == null) return true;
                  return Day(date).daySince1970 <=
                      Day(DateTime.now()).daySince1970;
                })
                .toList()
                .asMap()
                .entries)
              buildTaskRow(context, entry.key, entry.value)
          ],
        ),
      );
    });
  }

  Widget buildCalendar(BuildContext context) {
    return Consumer<AppModel>(builder: (context, model, child) {
      return Container(
        height: 240,
        child: ListView(scrollDirection: Axis.horizontal, children: [
          for (var day in calendarDays(model.today)) buildCalendarDay(day)
        ]),
      );
    });
  }

  List<Day> calendarDays(DateTime today) {
    return List<Day>.generate(14, (int i) {
      var timestamp = today.millisecondsSinceEpoch + (i + 1) * 24 * 3600 * 1000;
      var date = DateTime.fromMillisecondsSinceEpoch(timestamp);
      var day = Day(date);
      return day;
    });
  }

  Widget buildCalendarDay(Day day) {
    return DragTarget<Task>(onAcceptWithDetails: (details) {
      setState(() {
        details.data.date = day.date;
      });
    }, builder: (context, candidateItems, rejectedItems) {
      return Consumer<AppModel>(
        builder: (ctx, model, child) => Container(
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
                buildCalendarDayTaskList(day, model.tasks),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget buildCalendarDayTaskList(Day day, List<Task> tasks) {
    var dayTasks = tasks.where((element) {
      var date = element.date;
      if (date == null) return false;
      return Day(date).daySince1970 == day.daySince1970;
    });
    return Column(
      children: [
        for (var task in dayTasks) buildFutureTaskRow(task),
      ],
    );
  }

  Widget buildFutureTaskRow(Task task) {
    if (task.fromCalendar || task.done) {
      return buildFutureTaskInsideRow(task);
    }
    return LongPressDraggable(
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
                    color: task.done ? Colors.grey : Colors.black,
                    decoration: task.done
                        ? TextDecoration.lineThrough
                        : TextDecoration.none)),
          ),
        ),
      ]),
      data: task,
      dragAnchorStrategy: pointerDragAnchorStrategy,
      child: buildFutureTaskInsideRow(task),
    );
  }

  Widget buildFutureTaskInsideRow(Task task) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 5.0),
            child: Icon(
              task.fromCalendar
                  ? Icons.calendar_today_rounded
                  : Icons.radio_button_unchecked,
              size: 14,
              color: Colors.grey[600],
            ),
          ),
          Expanded(child: Text(task.text)),
        ],
      ),
    );
  }

  Widget buildTaskRow(BuildContext context, int index, Task task) {
    if (task.fromCalendar || task.done) {
      return buildTaskInsideRow(task, index);
    }
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
                    color: task.done ? Colors.grey : Colors.black,
                    decoration: task.done
                        ? TextDecoration.lineThrough
                        : TextDecoration.none)),
          ),
        ),
      ]),
      child: buildTaskInsideRow(task, index),
    );
  }

  Widget buildTaskInsideRow(Task task, int index) {
    return Consumer<AppModel>(
      builder: (ctx, model, child) => Container(
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
                    task.fromCalendar
                        ? Icons.calendar_today_rounded
                        : (task.done
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked),
                    color: Colors.grey[400]),
                onPressed: () {
                  if (task.fromCalendar) return;
                  setState(() {
                    var tasks = model.tasks;
                    var doneIndex = tasks
                        .indexWhere((element) => element.completedAt != null);
                    if (task.done) {
                      var firstCompletedIndex =
                          doneIndex < 0 ? tasks.length - 1 : doneIndex;
                      task.completedAt = null;
                      model.moveTask(task, firstCompletedIndex);
                    } else {
                      var firstCompletedIndex =
                          doneIndex < 0 ? tasks.length - 1 : doneIndex - 1;
                      task.completedAt = DateTime.now();
                      model.moveTask(task, firstCompletedIndex);
                    }
                  });
                },
              )),
          buildTaskRowText(task, model),
        ]),
      ),
    );
  }

  Widget buildTaskRowText(Task task, AppModel model) {
    return task == activeTask
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
                      model.removeTask(task);
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
                if (task.fromCalendar) return;
                setState(() {
                  activeTask = task;
                });
              },
              child: Text(task.text,
                  style: TextStyle(
                      color: task.done ? Colors.grey : Colors.black,
                      decoration: task.done
                          ? TextDecoration.lineThrough
                          : TextDecoration.none)),
            ),
          );
  }
}
