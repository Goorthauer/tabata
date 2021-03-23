import 'dart:async';
import 'dart:convert';

import 'package:audioplayers/audio_cache.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

var player = AudioCache();

Tabata get defaultTabata => Tabata(
      sets: 5,
      reps: 5,
      startDelay: Duration(seconds: 10),
      exerciseTime: Duration(seconds: 20),
      restTime: Duration(seconds: 10),
      breakTime: Duration(seconds: 60),
    );

class Settings {
  final SharedPreferences _prefs;

  bool nightMode;
  bool silentMode;
  Color primarySwatch;
  String countdownPip;
  String startRep;
  String startRest;
  String startBreak;
  String startSet;
  String endWorkout;

  Settings(this._prefs) {
    Map<String, dynamic> json =
        jsonDecode(_prefs.getString('settings') ?? '{}');
    nightMode = json['nightMode'] ?? false;
    silentMode = json['silentMode'] ?? false;
    primarySwatch = Colors.primaries[
        json['primarySwatch'] ?? Colors.primaries.indexOf(Colors.deepPurple)];
    countdownPip = json['countdownPip'] ?? 'pip.mp3';
    startRep = json['startRep'] ?? 'boop.mp3';
    startRest = json['startRest'] ?? 'dingdingding.mp3';
    startBreak = json['startBreak'] ?? 'dingdingding.mp3';
    startSet = json['startSet'] ?? 'boop.mp3';
    endWorkout = json['endWorkout'] ?? 'dingdingding.mp3';
  }

  save() {
    _prefs.setString('settings', jsonEncode(this));
  }

  Map<String, dynamic> toJson() => {
        'nightMode': nightMode,
        'silentMode': silentMode,
        'primarySwatch': Colors.primaries.indexOf(primarySwatch),
        'countdownPip': countdownPip,
        'startRep': startRep,
        'startRest': startRest,
        'startBreak': startBreak,
        'startSet': startSet,
        'endWorkout': endWorkout,
      };
}

class Tabata {
  /// Sets in a workout
  int sets;

  /// Reps in a set
  int reps;

  /// Time to exercise for in each rep
  Duration exerciseTime;

  /// Rest time between reps
  Duration restTime;

  /// Break time between sets
  Duration breakTime;

  /// Initial countdown before starting workout
  Duration startDelay;

  Tabata({
    this.sets,
    this.reps,
    this.startDelay,
    this.exerciseTime,
    this.restTime,
    this.breakTime,
  });

  Duration getTotalTime() {
    return (exerciseTime * sets * reps) +
        (restTime * sets * (reps - 1)) +
        (breakTime * (sets - 1));
  }

  Tabata.fromJson(Map<String, dynamic> json)
      : sets = json['sets'],
        reps = json['reps'],
        exerciseTime = Duration(seconds: json['exerciseTime']),
        restTime = Duration(seconds: json['restTime']),
        breakTime = Duration(seconds: json['breakTime']),
        startDelay = Duration(seconds: json['startDelay']);

  Map<String, dynamic> toJson() => {
        'sets': sets,
        'reps': reps,
        'exerciseTime': exerciseTime.inSeconds,
        'restTime': restTime.inSeconds,
        'breakTime': breakTime.inSeconds,
        'startDelay': startDelay.inSeconds,
      };
}

enum WorkoutState { initial, starting, exercising, resting, breaking, finished }

class Workout {
  Settings _settings;

  Tabata _config;

  /// Callback for when the workout's state has changed.
  Function _onStateChange;

  WorkoutState _step = WorkoutState.initial;

  Timer _timer;

  /// Time left in the current step
  Duration _timeLeft;

  Duration _totalTime =  Duration(seconds: 0);

  Duration _onlyLeftTotalTime =  Duration(seconds: 0);

  /// Current set
  int _set = 0;

  int _onlyLeftSet = 0;

  /// Current rep
  int _rep = 0;

  int _onlyLeftRep = 0;

  Workout(this._settings, this._config, this._onStateChange);


  nextStep(){
    _nextStep();
    _onStateChange();
  }
  prevStep(){
    _prevStep();
    _onStateChange();
  }

  startInitial(){
    _step = WorkoutState.initial;
    _set = 0;
    _rep = 0;
    _onlyLeftTotalTime =  Duration(seconds: 0);
    _onStateChange();
  }
  /// Starts or resumes the workout
  start() {
    _onlyLeftSet = _config.sets;
    _onlyLeftRep = _config.reps;
    _onlyLeftTotalTime = _config.getTotalTime() + _config.startDelay + _config.breakTime;
    if (_step == WorkoutState.initial) {
      _step = WorkoutState.starting;
      if (_config.startDelay.inSeconds == 0) {
        _nextStep();
      } else {
        _timeLeft = _config.startDelay;

      }
    }
    _timer = Timer.periodic(Duration(seconds: 1), _tick);
    _onStateChange();
  }

  /// Pauses the workout
  pause() {
    _timer.cancel();
    _onStateChange();
  }

  /// Stops the timer without triggering the state change callback.
  dispose() {
    _timer.cancel();
  }

  _tick(Timer timer) {
    _onlyLeftTotalTime -=Duration(seconds:1);
    if (_step != WorkoutState.starting) {
      _totalTime += Duration(seconds: 1);
    }

    if (_timeLeft.inSeconds == 1) {
      _nextStep();
    } else {
      _timeLeft -= Duration(seconds: 1);
      if (_timeLeft.inSeconds <= 3 && _timeLeft.inSeconds >= 1) {
        _playSound(_settings.countdownPip);
      }
    }

    _onStateChange();
  }

  /// Moves the workout to the next step and sets up state for it.
  _nextStep() {
    if (_step == WorkoutState.exercising) {
      if (rep == _config.reps) {
        if (set == _config.sets) {
          _finish();
        } else {
          _startBreak();
        }
      } else {
        _startRest();
      }
    } else if (_step == WorkoutState.resting) {
      _startRep();
    } else if (_step == WorkoutState.starting ||
        _step == WorkoutState.breaking) {
      _startSet();
    }
  }
  _prevStep() {
    if (_step == WorkoutState.exercising) {
      if( rep > 0 && rep <=_config.reps) {
        _prevRep();
      }
    }
  }

  Future _playSound(String sound) {
    if (_settings.silentMode) {
      return Future.value();
    }
    return player.play(sound);
  }

  _startRest() {
    _step = WorkoutState.resting;
    if (_config.restTime.inSeconds == 0) {
      _nextStep();
      return;
    }
    _onlyLeftTotalTime -= _timeLeft;
    _timeLeft = _config.restTime;
    _playSound(_settings.startRest);
  }

  _prevRep(){
    _rep--;
    _onlyLeftRep +=1;
    _step = WorkoutState.exercising;
    _onlyLeftTotalTime += _timeLeft;
    _timeLeft = _config.exerciseTime;
  }
  _startRep() {
    _rep++;
    _onlyLeftRep -=1;
    _step = WorkoutState.exercising;
    _onlyLeftTotalTime -= _timeLeft;
    _timeLeft = _config.exerciseTime;
    _playSound(_settings.startRep);
  }

  _startBreak() {
    _step = WorkoutState.breaking;
    if (_config.breakTime.inSeconds == 0) {
      _nextStep();
      return;
    }
    _onlyLeftTotalTime -= _timeLeft;
    _timeLeft = _config.breakTime;
    _playSound(_settings.startBreak);
  }

  _startSet() {
    _set++;
    _onlyLeftSet -=1;
    _onlyLeftRep = _config.reps;
    _rep = 1;
    _step = WorkoutState.exercising;
    if (_timeLeft != null) {
      _onlyLeftTotalTime -= _timeLeft;
    }
    _timeLeft = _config.exerciseTime;
    _playSound(_settings.startSet);
  }

  _finish() {
    _timer.cancel();
    _step = WorkoutState.finished;
    _timeLeft = Duration(seconds: 0);
    _onlyLeftTotalTime = _timeLeft;
    _onlyLeftRep = 0;
    _playSound(_settings.endWorkout).then((p) {
      if (p == null) {
        return;
      }
      p.onPlayerCompletion.first.then((_) {
        _playSound(_settings.endWorkout);
      });
    });
  }

  get config => _config;

  get set => _set;

  get rep => _rep;

  get step => _step;

  get timeLeft => _timeLeft;

  get totalTime => _totalTime;

  get onlyLeftTime => _onlyLeftTotalTime;

  get onlyLeftSet => _onlyLeftSet;

  get onlyLeftRep => _onlyLeftRep;

  get isActive => _timer != null && _timer.isActive;
}
