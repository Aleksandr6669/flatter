import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

void main() {
  runApp(const FlutterBlueApp());
}

class FlutterBlueApp extends StatelessWidget {
  const FlutterBlueApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      color: Colors.lightBlue,
      home: StreamBuilder<BluetoothAdapterState>(
          stream: FlutterBluePlus.adapterState,
          initialData: BluetoothAdapterState.unknown,
          builder: (c, snapshot) {
            final adapterState = snapshot.data;
            if (adapterState == BluetoothAdapterState.on) {
              return const ScanScreen();
            } else {
              return BluetoothOffScreen(adapterState: adapterState);
            }
          }),
    );
  }
}

class BluetoothOffScreen extends StatelessWidget {
  const BluetoothOffScreen({super.key, this.adapterState});

  final BluetoothAdapterState? adapterState;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlue,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.bluetooth_disabled,
              size: 200.0,
              color: Colors.white54,
            ),
            Text(
              'Bluetooth Adapter is ${adapterState?.toString().substring(15) ?? 'not available'}.',
              style: Theme.of(context)
                  .primaryTextTheme
                  .titleSmall
                  ?.copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  List<ScanResult> _scanResults = [];
  bool _isScanning = false;
  late StreamSubscription<List<ScanResult>> _scanResultsSubscription;
  late StreamSubscription<bool> _isScanningSubscription;

  @override
  void initState() {
    super.initState();

    _scanResultsSubscription = FlutterBluePlus.scanResults.listen((results) {
      _scanResults = results;
      if (mounted) {
        setState(() {});
      }
    });

    _isScanningSubscription = FlutterBluePlus.isScanning.listen((state) {
      if (mounted) {
        setState(() {
          _isScanning = state;
        });
      }
    });
  }

  @override
  void dispose() {
    _scanResultsSubscription.cancel();
    _isScanningSubscription.cancel();
    super.dispose();
  }

  Future<void> onScanPressed() async {
    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Future<void> onStopPressed() async {
    try {
      await FlutterBluePlus.stopScan();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  void onConnectPressed(BluetoothDevice device) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DeviceScreen(device: device),
      ),
    );
  }


  Future onRefresh() {
    if (!_isScanning) {
      onScanPressed();
    }
    if (mounted) {
      setState(() {});
    }
    return Future.delayed(const Duration(milliseconds: 500));
  }

  Widget buildScanButton(BuildContext context) {
    if (_isScanning) {
      return FloatingActionButton(
        onPressed: onStopPressed,
        backgroundColor: Colors.red,
        child: const Icon(Icons.stop),
      );
    } else {
      return FloatingActionButton(onPressed: onScanPressed, child: const Text("SCAN"));
    }
  }

  List<Widget> _buildScanResultTiles(BuildContext context) {
    return _scanResults
        .map(
          (r) => ScanResultTile(
            result: r,
            onTap: () => onConnectPressed(r.device),
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Devices'),
      ),
      body: RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          children: <Widget>[
            ..._buildScanResultTiles(context),
          ],
        ),
      ),
      floatingActionButton: buildScanButton(context),
    );
  }
}

class ScanResultTile extends StatelessWidget {
  const ScanResultTile({super.key, required this.result, this.onTap});

  final ScanResult result;
  final VoidCallback? onTap;

  Widget _buildTitle(BuildContext context) {
    String deviceName = '';
    if (result.device.platformName.isNotEmpty) {
      deviceName = result.device.platformName;
    } else if (result.advertisementData.advName.isNotEmpty) {
      deviceName = result.advertisementData.advName;
    } else {
      deviceName = 'Unknown Device';
    }
    return Text(
      deviceName,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildAdvRow(BuildContext context) {
    return Text(result.device.remoteId.toString());
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: _buildTitle(context),
      subtitle: _buildAdvRow(context),
      trailing: ElevatedButton(
        onPressed: (result.advertisementData.connectable) ? onTap : null,
        child: const Text('Connect'),
      ),
    );
  }
}

class DeviceScreen extends StatefulWidget {
  final BluetoothDevice device;

  const DeviceScreen({super.key, required this.device});

  @override
  State<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  List<BluetoothService> _services = [];
  bool _isConnecting = false;
  bool _isDisconnecting = false;
  late StreamSubscription<BluetoothConnectionState> _connectionStateSubscription;

  @override
  void initState() {
    super.initState();
    _connectionStateSubscription =
        widget.device.connectionState.listen((state) async {
      if (mounted) {
        if (state == BluetoothConnectionState.connected) {
           _services = await widget.device.discoverServices();
           setState(() {});
        }
         if (state == BluetoothConnectionState.disconnected) {
           if(Navigator.of(context).canPop()){
             Navigator.of(context).pop();
           }
        }
      }
    });
    _connect();
  }

  @override
  void dispose() {
    _connectionStateSubscription.cancel();
    super.dispose();
  }

  Future<void> _connect() async {
    if (_isConnecting) return;
    setState(() {
      _isConnecting = true;
    });
    try {
      await widget.device.connect(timeout: const Duration(seconds: 15), license: License.free);
    } catch (e) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text("Connection Failed: $e")),
         );
         Navigator.of(context).pop();
      }
    } finally {
       if (mounted) {
        setState(() {
          _isConnecting = false;
        });
      }
    }
  }

   Future<void> _disconnect() async {
    if (_isDisconnecting) return;
    setState(() {
      _isDisconnecting = true;
    });
    try {
      await widget.device.disconnect();
    } catch (e) {
       // Handle disconnection error
    } finally {
       if (mounted) {
        setState(() {
          _isDisconnecting = false;
        });
      }
    }
  }

  List<Widget> _buildServiceTiles() {
    return _services
        .map(
          (s) => ServiceTile(
            service: s,
            characteristicTiles: s.characteristics
                .map(
                  (c) => CharacteristicTile(
                    characteristic: c,
                    onReadPressed: () => c.read(),
                    onWritePressed: () async {
                      await c.write([0x12, 0x34]);
                    },
                    onNotificationPressed: () async {
                      await c.setNotifyValue(!c.isNotifying);
                      await c.read();
                    },
                  ),
                )
                .toList(),
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.device.platformName.isNotEmpty ? widget.device.platformName : 'Unknown Device'),
        actions: <Widget>[
          StreamBuilder<BluetoothConnectionState>(
            stream: widget.device.connectionState,
            initialData: BluetoothConnectionState.disconnected,
            builder: (c, snapshot) {
              final state = snapshot.data;
              if (state == BluetoothConnectionState.connected) {
                return TextButton(
                  onPressed: _disconnect,
                  child: const Text('DISCONNECT', style: TextStyle(color: Colors.white)),
                );
              }
              if (state == BluetoothConnectionState.disconnected) {
                 return TextButton(
                  onPressed: _connect,
                  child: const Text('CONNECT', style: TextStyle(color: Colors.white)),
                );
              }
              return const Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(color: Colors.white), 
              );
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
             StreamBuilder<BluetoothConnectionState>(
               stream: widget.device.connectionState,
               initialData: BluetoothConnectionState.disconnected,
               builder: (c, snapshot) => ListTile(
                leading: (snapshot.data == BluetoothConnectionState.connected)
                    ? const Icon(Icons.bluetooth_connected)
                    : const Icon(Icons.bluetooth_disabled),
                title: Text(
                    'Device is ${snapshot.data.toString().split('.').last}.'),
                subtitle: Text(widget.device.remoteId.toString()),
              ), 
             ),
            ..._buildServiceTiles(),
          ],
        ),
      ),
    );
  }
}


class ServiceTile extends StatelessWidget {
  final BluetoothService service;
  final List<CharacteristicTile> characteristicTiles;

  const ServiceTile(
      {super.key, required this.service, required this.characteristicTiles});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        ListTile(
          title: const Text('Service'),
          subtitle:
              Text('0x${service.uuid.toString().toUpperCase().substring(4, 8)}'),
        ),
        ...characteristicTiles,
      ],
    );
  }
}

class CharacteristicTile extends StatelessWidget {
  final BluetoothCharacteristic characteristic;
  final VoidCallback? onReadPressed;
  final VoidCallback? onWritePressed;
  final VoidCallback? onNotificationPressed;

  const CharacteristicTile(
      {super.key,
      required this.characteristic,
      this.onReadPressed,
      this.onWritePressed,
      this.onNotificationPressed});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<int>>(
      stream: characteristic.lastValueStream,
      initialData: characteristic.lastValue,
      builder: (c, snapshot) {
        final value = snapshot.data;
        return ListTile(
            title: Text('Characteristic 0x${characteristic.uuid.toString().toUpperCase().substring(4, 8)}'),
            subtitle: Text(value.toString()),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
            trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (characteristic.properties.read)
                IconButton(
                  icon: const Icon(Icons.file_download, color: Colors.black,),
                  onPressed: onReadPressed,
                ),
              if (characteristic.properties.write)
                IconButton(
                  icon: const Icon(Icons.file_upload, color: Colors.black,),
                  onPressed: onWritePressed,
                ),
              if (characteristic.properties.notify ||
                  characteristic.properties.indicate)
                IconButton(
                  icon: Icon(
                    characteristic.isNotifying ? Icons.sync_disabled : Icons.sync, color: Colors.black,),
                  onPressed: onNotificationPressed,
                )
            ],
          ),
        );
      },
    );
  }
}
