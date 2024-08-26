import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../utils/snackbar.dart';
import '../utils/extra.dart';

class DeviceScreen extends StatefulWidget {
  final BluetoothDevice device;

  const DeviceScreen({super.key, required this.device});

  @override
  State<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  String serviceUuid = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
  String charaCteristicUuid = "beb5483e-36e1-4688-b7f5-ea07361b26a8";
  bool isReady = false;
  late Stream<List<int>> stream;
  late List _esp32data;
  List _esp32dataDouble = [0.0, 0.0, 0.0, 0.0];

  int? _rssi;
  BluetoothConnectionState _connectionState =
      BluetoothConnectionState.disconnected;
  List<BluetoothService> _services = [];
  bool _isConnecting = false;
  bool _isDisconnecting = false;

  late StreamSubscription<BluetoothConnectionState>
      _connectionStateSubscription;
  late StreamSubscription<bool> _isConnectingSubscription;
  late StreamSubscription<bool> _isDisconnectingSubscription;

  @override
  void initState() {
    super.initState();

    isReady = false;

    _connectionStateSubscription =
        widget.device.connectionState.listen((state) async {
      _connectionState = state;
      if (state == BluetoothConnectionState.connected) {
        _services = []; // deve redescobrir os serviços
      }
      if (state == BluetoothConnectionState.connected && _rssi == null) {
        _rssi = await widget.device.readRssi();
      }
      discoverServices();
      if (mounted) {
        setState(() {});
      }
    });

    _isConnectingSubscription = widget.device.isConnecting.listen((value) {
      _isConnecting = value;
      if (mounted) {
        setState(() {});
      }
    });

    _isDisconnectingSubscription =
        widget.device.isDisconnecting.listen((value) {
      _isDisconnecting = value;
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _connectionStateSubscription.cancel();
    _isConnectingSubscription.cancel();
    _isDisconnectingSubscription.cancel();
    super.dispose();
  }

  bool get isConnected {
    return _connectionState == BluetoothConnectionState.connected;
  }

  Future onConnectPressed() async {
    try {
      await widget.device.connectAndUpdateStream();
      Snackbar.show(ABC.c, "Conectado com sucesso!", success: true);
    } catch (e) {
      if (e is FlutterBluePlusException &&
          e.code == FbpErrorCode.connectionCanceled.index) {
        // Ignora conecções canceladas pelo usuário
      } else {
        Snackbar.show(ABC.c, prettyException("Erro de conexão:", e),
            success: false);
      }
    }
  }

  Future onCancelPressed() async {
    try {
      await widget.device.disconnectAndUpdateStream(queue: false);
      Snackbar.show(ABC.c, "Cancelado com sucesso!", success: true);
    } catch (e) {
      Snackbar.show(ABC.c, prettyException("Erro de cancelamento:", e),
          success: false);
    }
  }

  Future onDisconnectPressed() async {
    try {
      await widget.device.disconnectAndUpdateStream();
      Snackbar.show(ABC.c, "Desconectado com sucesso!", success: true);
    } catch (e) {
      Snackbar.show(ABC.c, prettyException("Erro de desconexão:", e),
          success: false);
    }
  }

  Future discoverServices() async {
    try {
      _services = await widget.device.discoverServices();
      setState(() {});
      for (var service in _services) {
        if (service.uuid.toString() == serviceUuid) {
          for (var characteristic in service.characteristics) {
            if (characteristic.uuid.toString() == charaCteristicUuid) {
              characteristic.setNotifyValue(!characteristic.isNotifying);
              stream = characteristic.lastValueStream;
              if (mounted) {
                setState(() {
                  isReady = true;
                });
              }
            }
          }
        }
      }
      Snackbar.show(ABC.c, "Dados recebidos com sucesso", success: true);
    } catch (e) {
      Snackbar.show(ABC.c, prettyException("Erro nos dados do dispositivo:", e),
          success: false);
    }
  }

  Widget buildSpinner(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14.0),
      child: AspectRatio(
        aspectRatio: 1.0,
        child: CircularProgressIndicator(
          backgroundColor: Colors.black12,
          color: Colors.black26,
        ),
      ),
    );
  }

  Widget buildRemoteId(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text('${widget.device.remoteId}'),
    );
  }

  Widget buildRssiTile(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        isConnected
            ? const Icon(Icons.bluetooth_connected)
            : const Icon(Icons.bluetooth_disabled),
        Text(((isConnected && _rssi != null) ? '${_rssi!} dBm' : ''),
            style: Theme.of(context).textTheme.bodySmall)
      ],
    );
  }

  Widget buildConnectButton(BuildContext context) {
    return Row(children: [
      if (_isConnecting || _isDisconnecting) buildSpinner(context),
      TextButton(
          onPressed: _isConnecting
              ? onCancelPressed
              : (isConnected ? onDisconnectPressed : onConnectPressed),
          child: Text(
            _isConnecting
                ? "CANCELAR"
                : (isConnected ? "DESCONECTAR" : "CONETAR"),
            style: Theme.of(context)
                .primaryTextTheme
                .labelLarge
                ?.copyWith(color: Colors.white),
          ))
    ]);
  }

  String _dataParser(dataFromDevice) {
    return utf8.decode(dataFromDevice);
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: Snackbar.snackBarKeyC,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.device.platformName),
          actions: [buildConnectButton(context)],
        ),
        body: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 25.0),
                title: Text(
                    'Sensores ${(_connectionState.toString().split('.')[1]) == 'connected' ? 'conectados' : 'desconectado'}!'),
                trailing: buildRssiTile(context),
              ),
              SizedBox(
                height: 20,
              ),
              Container(
                  child: !isReady
                      ? Center(
                          child: Text(
                            "Aguardando...",
                            style: TextStyle(fontSize: 24, color: Colors.red),
                          ),
                        )
                      : StreamBuilder<List<int>>(
                          stream: stream,
                          builder: (BuildContext context,
                              AsyncSnapshot<List<int>> snapshot) {
                            if (snapshot.hasError) {
                              return Text('Erro: ${snapshot.error}');
                            }

                            if (snapshot.connectionState ==
                                ConnectionState.active) {
                              // coletando dados via bluetooth
                              String currentValue = snapshot.data != null
                                  ? _dataParser(snapshot.data)
                                  : '1,2,3,4';
                              _esp32data = currentValue.split(",");
                              _esp32dataDouble[0] =
                                  double.tryParse(_esp32data[0])! / 10;
                              _esp32dataDouble[1] =
                                  double.tryParse(_esp32data[1])! / 10;
                              _esp32dataDouble[2] =
                                  double.tryParse(_esp32data[2])! / 10;
                              _esp32dataDouble[3] =
                                  double.tryParse(_esp32data[3])! / 10;

                              return Column(
                                children: [
                                  SensorBar(
                                      esp32dataDouble: _esp32dataDouble[0]),
                                  Text(
                                    '${_esp32dataDouble[0]}',
                                    style: TextStyle(fontSize: 48),
                                  ),
                                  SensorBar(
                                      esp32dataDouble: _esp32dataDouble[1]),
                                  Text(
                                    '${_esp32dataDouble[1]}',
                                    style: TextStyle(fontSize: 48),
                                  ),
                                  SensorBar(
                                      esp32dataDouble: _esp32dataDouble[2]),
                                  Text(
                                    '${_esp32dataDouble[2]}',
                                    style: TextStyle(fontSize: 48),
                                  ),
                                  SensorBar(
                                      esp32dataDouble: _esp32dataDouble[3]),
                                  Text(
                                    '${_esp32dataDouble[3]}',
                                    style: TextStyle(fontSize: 48),
                                  ),
                                ],
                              );
                            } else {
                              return Text('Verifique o dispositivo.');
                            }
                          },
                        )),
            ],
          ),
        ),
      ),
    );
  }
}

class SensorBar extends StatelessWidget {
  const SensorBar({
    super.key,
    required double esp32dataDouble,
  }) : _esp32dataDouble = esp32dataDouble;

  final double _esp32dataDouble;
  final int maxFactor =
      200; //Alterar para o tamanho máximo de medida das barras.

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          color: Colors.red,
          width: (_esp32dataDouble /
                      maxFactor *
                      MediaQuery.of(context).size.width >
                  MediaQuery.of(context).size.width)
              ? MediaQuery.of(context).size.width
              : _esp32dataDouble /
                  maxFactor *
                  MediaQuery.of(context).size.width,
          height: 20,
        ),
        Expanded(
          child: Container(
            color: Colors.green,
            height: 20, // Altura da barra (pode variar)
          ),
        ),
      ],
    );
  }
}
