import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_esp32_car_height_sensor_app/features/devices/devices.dart';

class DevicesListScreen extends StatefulWidget {
  const DevicesListScreen({
    super.key,
  });

  @override
  State<DevicesListScreen> createState() => _DevicesListScreenState();
}

class _DevicesListScreenState extends State<DevicesListScreen> {
  var _scanResults = <ScanResult>[];

  StreamSubscription<List<ScanResult>>? _devicesSub;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _devicesSub?.cancel();
    super.dispose();
  }

  Future<void> _enableFlutterBle() async {
    final isSupported = await FlutterBluePlus.isSupported;
    if (!isSupported) {
      log("Bluetooth not supported by this device");
      return;
    } else {
      log('Bluetooth ok');
    }

    final state = await FlutterBluePlus.adapterState.first;
    log(state.toString());
    if (state != BluetoothAdapterState.on) {
      log('Bluetooth OFF');
      return;
    }

    _devicesSub?.cancel();
    _devicesSub = FlutterBluePlus.onScanResults.listen(
      (results) => setState(() => _scanResults = results),
      onError: (e) => log(e),
    );

    FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 15),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sensores de Altura'),
      ),
      body: ListView.separated(
        itemCount: _scanResults.length,
        itemBuilder: (context, index) {
          final result = _scanResults[index];
          return ListTile(
            title: Text(result.device.advName),
            subtitle: Text(result.device.platformName),
            onTap: () => _openDeviceScreen(context, result),
          );
        },
        separatorBuilder: (context, index) => Divider(height: 1),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _enableFlutterBle,
        child: Icon(Icons.refresh),
      ),
    );
  }

  void _openDeviceScreen(BuildContext context, ScanResult result) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DeviceScreen(device: result.device),
      ),
    );
  }
}
