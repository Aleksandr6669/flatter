import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bluetooth LE Scanner',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ScanScreen(),
    );
  }
}

class ScanScreen extends StatefulWidget {
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
      // Filter devices that have a non-empty platform name
      final filteredResults =
          results.where((r) => r.device.platformName.isNotEmpty).toList();
      if (mounted) {
        setState(() {
          _scanResults = filteredResults;
        });
      }
    });
    _isScanningSubscription = FlutterBluePlus.isScanning.listen((isScanning) {
      if (mounted) {
        setState(() {
          _isScanning = isScanning;
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

  Future<void> _startScan() async {
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
  }

  Future<void> _stopScan() async {
    await FlutterBluePlus.stopScan();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan for Devices'),
      ),
      body: RefreshIndicator(
        onRefresh: _startScan,
        child: ListView.builder(
          itemCount: _scanResults.length,
          itemBuilder: (context, index) {
            final result = _scanResults[index];
            return ListTile(
              title: Text(result.device.platformName),
              subtitle: Text(result.device.remoteId.toString()),
              trailing: ElevatedButton(
                child: const Text('Connect'),
                onPressed: () {
                  _stopScan();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DeviceScreen(device: result.device),
                      settings: const RouteSettings(name: '/device'),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isScanning ? _stopScan : _startScan,
        child: Icon(_isScanning ? Icons.stop : Icons.search),
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
  bool _isConnected = false;
  late StreamSubscription<BluetoothConnectionState> _connectionStateSubscription;

  bool _isMonitoring = false;
  StreamSubscription<List<int>>? _postureSubscription;
  BluetoothCharacteristic? _postureCharacteristic;
  int _postureAngle = 0;
  String _postureMessage = '';

  @override
  void initState() {
    super.initState();
    _connectionStateSubscription =
        widget.device.connectionState.listen((state) async {
      if (mounted) {
        _isConnected = state == BluetoothConnectionState.connected;
        if (_isConnected) {
          final services = await widget.device.discoverServices();
          setState(() {
            _services = services;
          });
        } else {
          _services = [];
          _stopPostureMonitoring(); // Stop monitoring if disconnected
        }
        setState(() {});
      }
    });
    _connectToDevice();
  }

  Future<void> _connectToDevice() async {
    await widget.device.connect(license: License.free);
  }

  @override
  void dispose() {
    _connectionStateSubscription.cancel();
    _stopPostureMonitoring();
    widget.device.disconnect();
    super.dispose();
  }

  Future<void> _toggleMonitoring(bool value) async {
    if (value) {
      await _startPostureMonitoring();
    } else {
      await _stopPostureMonitoring();
    }
  }

  Future<void> _startPostureMonitoring() async {
    if (_services.isEmpty || !_isConnected) return;

    for (var service in _services) {
      for (var char in service.characteristics) {
        if (char.properties.notify) {
          _postureCharacteristic = char;
          break;
        }
      }
      if (_postureCharacteristic != null) break;
    }

    if (_postureCharacteristic != null) {
      await _postureCharacteristic!.setNotifyValue(true);
      _postureSubscription = _postureCharacteristic!.lastValueStream.listen((value) {
        if (value.isNotEmpty) {
          int angle = value[0]; // Assuming first byte is the angle
          developer.log("Текущий угол: $angle");
          String message = '';
          if (angle > 30) {
            message = "Саша, выровняй спину!";
            developer.log(message);
          }
          if (mounted) {
            setState(() {
              _postureAngle = angle;
              _postureMessage = message;
            });
          }
        }
      });
      if (mounted) {
        setState(() {
          _isMonitoring = true;
        });
      }
    }
  }

  Future<void> _stopPostureMonitoring() async {
    await _postureSubscription?.cancel();
    _postureSubscription = null;
    if (_postureCharacteristic != null && _isConnected) {
      try {
        await _postureCharacteristic!.setNotifyValue(false);
      } catch (e) {
        developer.log("Error disabling notifications: $e");
      }
    }
    _postureCharacteristic = null;

    if (mounted) {
      setState(() {
        _isMonitoring = false;
        _postureAngle = 0;
        _postureMessage = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.device.platformName.isNotEmpty
            ? widget.device.platformName
            : 'Unknown Device'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: Text(_isConnected ? 'CONNECTED' : 'DISCONNECTED',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SwitchListTile(
              title: const Text('Monitor Posture'),
              value: _isMonitoring,
              onChanged: _isConnected ? _toggleMonitoring : null,
            ),
            if (_isMonitoring)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text('Текущий угол: $_postureAngle°', style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 8),
                    if (_postureMessage.isNotEmpty)
                      Text(
                        _postureMessage,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                  ],
                ),
              ),
            const Divider(),
            ..._services.map((service) {
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text('Service: ${service.uuid}',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                    ),
                    ...service.characteristics.map((characteristic) {
                      return ListTile(
                        title: Text('Characteristic: ${characteristic.uuid}'),
                        subtitle: Text('Properties: ${characteristic.properties}'),
                      );
                    }).toList(),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
