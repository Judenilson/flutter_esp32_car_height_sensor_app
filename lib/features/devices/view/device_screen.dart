import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class DeviceScreen extends StatefulWidget {
  const DeviceScreen({
    super.key,
    required this.device,
  });

  final BluetoothDevice device;

  @override
  State<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  var _greenValue = 205.0;
  var _blueValue = 100.0;
  var _redValue = 190.0;

  StreamSubscription<BluetoothConnectionState>? _deviceSub;

  @override
  void initState() {
    final device = widget.device;
    device.connectionState.listen((state) {
      if (state == BluetoothConnectionState.disconnected) {
        _connectAndRead(device);
      }
    },);
    super.initState();
  }

  @override
  void dispose() {
    _deviceSub?.cancel();
    super.dispose();
  }

  Future<void> _connectAndRead(BluetoothDevice device) async {
    await device.connect();

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ColorSlider(
              color: Colors.red,
              value: _redValue,
              onChanged: _setRedValue,
            ),
            ColorSlider(
              color: Colors.green,
              value: _greenValue,
              onChanged: _setGreenValue,
            ),
            ColorSlider(
              color: Colors.blue,
              value: _blueValue,
              onChanged: _setBlueValue,
            ),
          ],
        ),
      ),
    );
  }

  void _setBlueValue(double value) {
    setState(() => _blueValue = value);
  }

  void _setRedValue(double value) {
    setState(() => _redValue = value);
  }

  void _setGreenValue(double value) {
    setState(() => _greenValue = value);
  }
}

class ColorSlider extends StatelessWidget {
  const ColorSlider({
    super.key,
    required this.color,
    required this.value,
    required this.onChanged,
  });

  final Color color;
  final double value;
  final Function(double value) onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ColorBox(color: color),
        Slider(
          value: value,
          max: 255,
          min: 0,
          divisions: 255,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class ColorBox extends StatelessWidget {
  const ColorBox({
    super.key,
    required this.color,
  });

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 25,
      width: 25,
      decoration: BoxDecoration(color: color),
    );
  }
}
