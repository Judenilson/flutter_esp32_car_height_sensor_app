import 'dart:async';
import 'dart:developer';

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
  var _sensorAValue = 205.0;
  var _sensorBValue = 100.0;
  var _sensorCValue = 190.0;
  var _sensorDValue = 255.0;

  BluetoothCharacteristic? _characteristic;

  StreamSubscription<BluetoothConnectionState>? _deviceSub;

  @override
  void initState() {
    final device = widget.device;
    device.connectionState.listen(
      (state) {
        if (state == BluetoothConnectionState.disconnected) {
          _connectAndRead(device);
        }
      },
    );
    super.initState();
  }

  @override
  void dispose() {
    _deviceSub?.cancel();
    super.dispose();
  }

  Future<void> _connectAndRead(BluetoothDevice device) async {
    await device.connect();
    final services = await device.discoverServices();
    log(services.toString());

    const serviceUuid = '4fafc201-1fb5-459e-8fcc-c5c9c331914b';
    final serviceExist = services
        .where((element) => element.serviceUuid.str == serviceUuid)
        .isNotEmpty;
    if (!serviceExist) return;

    final service = services.firstWhere(
      (element) => element.serviceUuid.str == serviceUuid,
    );

    final characteristics = service.characteristics;

    const characteristicUuid = 'beb5483e-36e1-4688-b7f5-ea07361b26a8';
    final characteristicExist = characteristics
        .where(
            (element) => element.characteristicUuid.str == characteristicUuid)
        .isNotEmpty;
    if (!characteristicExist) return;

    final characteristic = characteristics.firstWhere(
      (element) => element.characteristicUuid.str == characteristicUuid,
    );
    _characteristic = characteristic;

    final value = await characteristic.read();
    log(value.toString());
    if (value.length != 10) return;
    _sensorAValue = value[0].toDouble()*100 + value[1].toDouble();
    _sensorBValue = value[2].toDouble()*100 + value[3].toDouble();
    _sensorCValue = value[4].toDouble()*100 + value[5].toDouble();
    _sensorDValue = value[6].toDouble()*100 + value[7].toDouble();
    setState(() {});

  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_sensorAValue.toString()),
            ColorSlider(
              color: Colors.red,
              value: _sensorAValue,
              onChanged: _setSensorAValue,
            ),
            Text(_sensorBValue.toString()),
            ColorSlider(
              color: Colors.green,
              value: _sensorBValue,
              onChanged: _setSensorBValue,
            ),
            Text(_sensorCValue.toString()),
            ColorSlider(
              color: Colors.blue,
              value: _sensorCValue,
              onChanged: _setSensorCValue,
            ),
            Text(_sensorDValue.toString()),
            ColorSlider(
              color: Colors.blue,
              value: _sensorDValue,
              onChanged: _setSensorDValue,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _resetHeightCharacteristic,
        child: Icon(Icons.refresh),
      ),
    );
  }

  void _setSensorAValue(double value) {
    setState(() => _sensorAValue = value);
    _writeCharacteristic();
  }

  void _setSensorBValue(double value) {
    setState(() => _sensorBValue = value);
    _writeCharacteristic();
  }

  void _setSensorCValue(double value) {
    setState(() => _sensorCValue = value);
    _writeCharacteristic();
  }

  void _setSensorDValue(double value) {
    setState(() => _sensorDValue = value);
    _writeCharacteristic();
  }

  void _writeCharacteristic() {
    final characteristic = _characteristic;
    if (characteristic != null) {
      characteristic.write(
        [
          (_sensorAValue/100).toInt(),
          (_sensorAValue%100).toInt(),
          (_sensorBValue/100).toInt(),
          (_sensorBValue%100).toInt(),
          (_sensorCValue/100).toInt(),
          (_sensorCValue%100).toInt(),
          (_sensorDValue/100).toInt(),
          (_sensorDValue%100).toInt(),
        ],
      );
    }
  }

  void _resetHeightCharacteristic() {
    final characteristic = _characteristic;
    if (characteristic != null) {
      characteristic.write(
        [
          (_sensorAValue/100).toInt(),
          (_sensorAValue%100).toInt(),
          (_sensorBValue/100).toInt(),
          (_sensorBValue%100).toInt(),
          (_sensorCValue/100).toInt(),
          (_sensorCValue%100).toInt(),
          (_sensorDValue/100).toInt(),
          (_sensorDValue%100).toInt(),
          1,
          0
        ],
      );
    }
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
