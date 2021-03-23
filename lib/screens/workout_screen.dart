import 'package:flutter/material.dart';
import 'package:screen/screen.dart';
import 'package:flutter_speech/flutter_speech.dart';

import '../models.dart';
import '../utils.dart';

String stepName(WorkoutState step) {
  switch (step) {
    case WorkoutState.exercising:
      return 'Работа';
    case WorkoutState.resting:
      return 'Отдых';
    case WorkoutState.breaking:
      return 'Перерыв';
    case WorkoutState.finished:
      return 'Конец';
    case WorkoutState.starting:
      return 'Подготовка';
    default:
      return '';
  }
}

class WorkoutScreen extends StatefulWidget {
  final Settings settings;
  final Tabata tabata;

  WorkoutScreen({this.settings, this.tabata});

  @override
  State<StatefulWidget> createState() => _WorkoutScreenState();
}

class Language {
  final String name;
  final String code;

  const Language(this.name, this.code);
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  Workout _workout;
  const languages = Language('Pусский', 'ru_RU');

  @override
  initState() {
    super.initState();
    _workout = Workout(widget.settings, widget.tabata, _onWorkoutChanged);
    _start();
  }

  @override
  dispose() {
    _workout.dispose();
    Screen.keepOn(false);
    super.dispose();
  }

  _onWorkoutChanged() {
    if (_workout.step == WorkoutState.finished) {
      Screen.keepOn(false);
    }
    this.setState(() {});
  }

  _getBackgroundColor(ThemeData theme) {
    switch (_workout.step) {
      case WorkoutState.exercising:
        return Color(0xFF2E7D32);
      case WorkoutState.starting:
      case WorkoutState.resting:
        return  Color(0xFF1565C0);
      case WorkoutState.breaking:
        return Color(0xFFC62828);
      default:
        return Color(0xFF283593);
    }
  }

  _pause() {
    _workout.pause();
    Screen.keepOn(false);
  }

  _start() {
    _workout.start();
    Screen.keepOn(true);
  }
  _nextWorkoutStep() {
    _workout.nextStep();
    Screen.keepOn(true);
  }

  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var lightTextColor = theme.textTheme.bodyText2.color.withOpacity(0.9);
    var textStyleOne = TextStyle(fontSize: 60.0, color: Colors.white);
    var textStyleTwo = TextStyle(fontSize: 30.0, color: Color(0xFFE8E8E8));
    return Scaffold(
      body: Container(
        color: _getBackgroundColor(theme),
        padding: EdgeInsets.symmetric(horizontal: 15),
        child: Column(
          children: <Widget>[
            Expanded(child: Row()),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(stepName(_workout.step), style:textStyleOne)
            ]),
            Divider(height: 32, color: lightTextColor),
            Container(
                width: MediaQuery.of(context).size.width,
                child: FittedBox(child: Text(formatTime(_workout.timeLeft),style: textStyleOne))),
            Divider(height: 32, color: lightTextColor),
            Table(columnWidths: {
              0: FlexColumnWidth(0.5),
              1: FlexColumnWidth(0.5),
              2: FlexColumnWidth(1.0)
            }, children: [
              TableRow(children: [
                TableCell(child: Text('Сеты', style: textStyleTwo)),
                TableCell(child: Text('Круги', style: textStyleTwo)),
                TableCell(
                    child: Text('Время',
                        textAlign: TextAlign.end,
                        style: textStyleTwo))
              ]),
              TableRow(children: [
                TableCell(
                  child:
                      Text('${_workout.set}', style:textStyleOne),
                ),
                TableCell(
                  child:
                      Text('${_workout.rep}', style:textStyleOne),
                ),
                TableCell(
                    child: Text(
                  formatTime(_workout.totalTime),
                  style: textStyleOne,
                  textAlign: TextAlign.right,
                ))
              ]),
            ]),
            Divider(height: 32, color: lightTextColor),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text("Осталось", style: textStyleOne)
            ]),
            Table(columnWidths: {
              0: FlexColumnWidth(0.5),
              1: FlexColumnWidth(0.5),
              2: FlexColumnWidth(1.0)
            }, children: [
              TableRow(children: [
                TableCell(child: Text('Сеты', style: textStyleTwo)),
                TableCell(child: Text('Круги', style: textStyleTwo)),
                TableCell(
                    child: Text('Время',
                        textAlign: TextAlign.end,
                        style: textStyleTwo))
              ]),
              TableRow(children: [
                TableCell(
                  child:
                  Text('${_workout.onlyLeftSet}', style: textStyleOne),
                ),
                TableCell(
                  child:
                  Text('${_workout.onlyLeftRep}', style: textStyleOne),
                ),
                TableCell(
                    child: Text(
                      formatTime(_workout.onlyLeftTime),
                      style: textStyleOne,
                      textAlign: TextAlign.right,
                    ))
              ]),
            ]),
            Expanded(child: _buildButtonBar()),
          ],
        ),
      ),
    );
  }

  Widget _buildButtonBar() {
    if (_workout.step == WorkoutState.finished) {
      return Container();
    }
  var firstButton =   Align(
        alignment: Alignment.bottomCenter,
        child: TextButton(
            onPressed: _workout.isActive ? _pause : _start,
            child: Icon(_workout.isActive ? Icons.pause : Icons.play_arrow,color: Color(0xFFFFFFFF)),));
 var secondButton =   Align(        alignment: Alignment.bottomRight,
        child: TextButton(
            onPressed: _nextWorkoutStep,
          child: Icon(Icons.arrow_forward,color: Color(0xFFFFFFFF)))
    );
return new Row(mainAxisAlignment: MainAxisAlignment.center,children: [firstButton,secondButton]);
  }
}
