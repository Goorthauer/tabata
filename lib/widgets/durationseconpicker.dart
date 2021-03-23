import 'package:flutter/material.dart';
import 'package:numberpicker/numberpicker.dart';

class DurationSecondPickerPickerDialog extends StatefulWidget {
  final Duration initialDuration;
  final EdgeInsets titlePadding;
  final Widget title;
  final Widget confirmWidget;
  final Widget cancelWidget;

  DurationSecondPickerPickerDialog({
    @required this.initialDuration,
    this.title,
    this.titlePadding,
    Widget confirmWidget,
    Widget cancelWidget,
  })  : confirmWidget = confirmWidget ?? new Text('OK'),
        cancelWidget = cancelWidget ?? new Text('Отмена');

  @override
  State<StatefulWidget> createState() =>
      new _DurationSecondPickerPickerDialogState(initialDuration);
}

class _DurationSecondPickerPickerDialogState extends State<DurationSecondPickerPickerDialog> {
  int minutes;
  int seconds;
  final number = TextEditingController();

  _DurationSecondPickerPickerDialogState(Duration initialDuration) {
    minutes = initialDuration.inMinutes;
    seconds = initialDuration.inSeconds % Duration.secondsPerMinute;
  }

  @override
  Widget build(BuildContext context) {
    number.text = ((minutes*60)+seconds).toString();
    number.selection = TextSelection.fromPosition(TextPosition(offset: number.text.length));
    return new AlertDialog(
      title: widget.title,
      titlePadding: widget.titlePadding,
      content: Container(

              child:Column(children: [
                TextField(
                  controller: number,
                  autofocus: true,
                  autocorrect: true,
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    this.setState(() {
                      minutes = int.parse(value) ~/ Duration.secondsPerMinute;
                      seconds = int.parse(value) % Duration.secondsPerMinute;
                    });
                  },
                ),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  new NumberPicker.integer(
                    listViewWidth: 65,
                    initialValue: minutes,
                    minValue: 0,
                    maxValue: 99,
                    zeroPad: true,
                    onChanged: (value) {
                      this.setState(() {
                        minutes = value;
                      });
                    },
                  ),
                  Text(
                    ':',
                    style: TextStyle(fontSize: 30),
                  ),
                  new NumberPicker.integer(
                    listViewWidth: 65,
                    initialValue: seconds,
                    minValue: 0,
                    maxValue: 59,
                    zeroPad: true,
                    onChanged: (value) {
                      this.setState(() {
                        seconds = value;
                      });
                    },
                  ),
                ])
              ])
      ),
      actions: [
        new TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: widget.cancelWidget,
        ),
        new TextButton(
          onPressed: () => Navigator.of(context)
              .pop(new Duration(minutes: minutes, seconds: seconds)),
          child: widget.confirmWidget,
        ),
      ],
    );
  }
}
