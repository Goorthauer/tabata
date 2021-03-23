import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models.dart';
import '../utils.dart';
import '../widgets/durationpicker.dart';
import 'settings_screen.dart';
import 'workout_screen.dart';

class TabataScreen extends StatefulWidget {
  final Settings settings;
  final SharedPreferences prefs;
  final Function onSettingsChanged;

  TabataScreen({
    @required this.settings,
    @required this.prefs,
    @required this.onSettingsChanged,
  });

  @override
  State<StatefulWidget> createState() => _TabataScreenState();
}

class _TabataScreenState extends State<TabataScreen> {
  Tabata _tabata;

  @override
  initState() {
    var json = widget.prefs.getString('tabata');
    _tabata = json != null ? Tabata.fromJson(jsonDecode(json)) : defaultTabata;
    super.initState();
  }

  _onTabataChanged() {
    setState(() {});
    _saveTabata();
  }

  _saveTabata() {
    widget.prefs.setString('tabata', jsonEncode(_tabata.toJson()));
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Просто таймер'),
        leading: Icon(Icons.access_alarm),
        actions: <Widget>[
          Builder(
            builder: (context) => IconButton(
              icon: Icon(widget.settings.silentMode
                  ? Icons.volume_off
                  : Icons.volume_up),
              onPressed: () {
                widget.settings.silentMode = !widget.settings.silentMode;
                widget.onSettingsChanged();
                var snackBar = SnackBar(
                    duration: Duration(seconds: 1),
                    content: Text(
                        'Тихий режим ${!widget.settings.silentMode ? 'де' : ''}активирован'));
                Scaffold.of(context).showSnackBar(snackBar);
              },
              tooltip: 'Тихий режим',
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.settings,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsScreen(
                      settings: widget.settings,
                      onSettingsChanged: widget.onSettingsChanged),
                ),
              );
            },
            tooltip: 'Настройки',
          ),
        ],
      ),
      body: ListView(
        children: <Widget>[
          ListTile(
            title: Text('Подготовка'),
            subtitle: Text(formatTime(_tabata.startDelay)),
            leading: Icon(Icons.lightbulb),
            onTap: () {
              showDialog<Duration>(
                context: context,
                builder: (BuildContext context) {
                  return DurationPickerDialog(
                    initialDuration: _tabata.startDelay,
                    title: Text('Время подготовки до старта'),
                  );
                },
              ).then((startDelay) {
                if (startDelay == null) return;
                _tabata.startDelay = startDelay;
                _onTabataChanged();
              });
            },
          ),
          Divider(
            height: 5,
          ),
          ListTile(
            title: Text('Работа'),
            subtitle: Text(formatTime(_tabata.exerciseTime)),
            leading: Icon(Icons.accessibility),
            onTap: () {
              showDialog<Duration>(
                context: context,
                builder: (BuildContext context) {
                  return DurationPickerDialog(
                    initialDuration: _tabata.exerciseTime,
                    title: Text('Время непрерывной работы'),
                  );
                },
              ).then((exerciseTime) {
                if (exerciseTime == null) return;
                _tabata.exerciseTime = exerciseTime;
                _onTabataChanged();
              });
            },
          ),
          ListTile(
            title: Text('Отдых'),
            subtitle: Text(formatTime(_tabata.restTime)),
            leading: Icon(Icons.weekend),
            onTap: () {
              showDialog<Duration>(
                context: context,
                builder: (BuildContext context) {
                  return DurationPickerDialog(
                    initialDuration: _tabata.restTime,
                    title: Text('Отдых между циклами'),
                  );
                },
              ).then((restTime) {
                if (restTime == null) return;
                _tabata.restTime = restTime;
                _onTabataChanged();
              });
            },
          ),
          ListTile(
            title: Text('Перерыв'),
            subtitle: Text(formatTime(_tabata.breakTime)),
            leading: Icon(Icons.watch_later),
            onTap: () {
              showDialog<Duration>(
                context: context,
                builder: (BuildContext context) {
                  return DurationPickerDialog(
                    initialDuration: _tabata.breakTime,
                    title: Text('Перерыв между сетами'),
                  );
                },
              ).then((breakTime) {
                if (breakTime == null) return;
                _tabata.breakTime = breakTime;
                _onTabataChanged();
              });
            },
          ),
          Divider(
            height: 5,
          ),
          ListTile(
            title: Text('Сеты'),
            subtitle: Text('${_tabata.sets}'),
            leading: Icon(Icons.fitness_center),
            onTap: () {
              showDialog<int>(
                context: context,
                builder: (BuildContext context) {
                  return NumberPickerDialog.integer(
                    minValue: 1,
                    maxValue: 99,
                    initialIntegerValue: _tabata.sets,
                    title: Text('Количество сетов в комплексе'),
                  );
                },
              ).then((sets) {
                if (sets == null) return;
                _tabata.sets = sets;
                _onTabataChanged();
              });
            },
          ),
          ListTile(
            title: Text('Круги'),
            subtitle: Text('${_tabata.reps}'),
            leading: Icon(Icons.repeat),
            onTap: () {
              showDialog<int>(
                context: context,
                builder: (BuildContext context) {
                  return NumberPickerDialog.integer(
                    minValue: 1,
                    maxValue: 99,
                    initialIntegerValue: _tabata.reps,
                    title: Text('Количество повторов в комплексе'),
                  );
                },
              ).then((reps) {
                if (reps == null) return;
                _tabata.reps = reps;
                _onTabataChanged();
              });
            },
          ),
          Divider(height: 10),
          ListTile(
            title: Text(
              'Время чистой работы',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Text(formatTime(_tabata.getTotalTime())),
            leading: Icon(Icons.timelapse),
          ),
          ListTile(
            title: Text(
              'Полное время',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Text(formatTime(_tabata.getTotalTime() +
                (
                    _tabata.startDelay
                    //* _tabata.reps
                ) +
                (_tabata.breakTime
                    // * _tabata.sets
                ))),
            leading: Icon(Icons.av_timer),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => WorkoutScreen(
                      settings: widget.settings, tabata: _tabata)));
        },
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Theme.of(context).primaryTextTheme.button.color,
        tooltip: 'Стартовать',
        child: Icon(Icons.play_arrow),
      ),
    );
  }
}
