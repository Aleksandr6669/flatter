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
      title: 'HiPee Posture Tracker',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        textTheme: TextTheme(
          displayLarge: TextStyle(fontSize: 72.0, fontWeight: FontWeight.bold, color: Colors.teal.shade800),
          titleLarge: TextStyle(fontSize: 36.0, fontStyle: FontStyle.italic, color: Colors.teal.shade600),
          bodyMedium: TextStyle(fontSize: 14.0, fontFamily: 'Hind', color: Colors.grey.shade800),
        ),
      ),
      home: HiPeeControllerScreen(),
    );
  }
}

class HiPeeControllerScreen extends StatefulWidget {
  @override
  State<HiPeeControllerScreen> createState() => _HiPeeControllerScreenState();
}

class _HiPeeControllerScreenState extends State<HiPeeControllerScreen> {
  StreamSubscription<List<ScanResult>>? _scanResultsSubscription;
  StreamSubscription<bool>? _isScanningSubscription;
  bool _isScanning = false;
  String _statusMessage = "Initializing...";
  BluetoothDevice? _hipeeDevice;

  @override
  void initState() {
    super.initState();
    _isScanningSubscription = FlutterBluePlus.isScanning.listen((isScanning) {
      if (mounted) {
        setState(() {
          _isScanning = isScanning;
        });
      }
    });
    _startScan();
  }

  @override
  void dispose() {
    _stopScan();
    _scanResultsSubscription?.cancel();
    _isScanningSubscription?.cancel();
    super.dispose();
  }

  Future<void> _startScan() async {
    setState(() {
      _statusMessage = "Scanning for 'hipee' device...";
      _hipeeDevice = null;
    });

    try {
      _scanResultsSubscription = FlutterBluePlus.scanResults.listen((results) {
        final foundDevice = results.firstWhere(
          (r) => r.device.platformName.toLowerCase() == 'hipee',
          orElse: () => ScanResult(
              device: BluetoothDevice(remoteId: const DeviceIdentifier('')),
              advertisementData: AdvertisementData(advName: '', txPowerLevel: null, appearance: null, connectable: false, manufacturerData: {}, serviceData: {}, serviceUuids: []),
              rssi: 0,
              timeStamp: DateTime.now()),
        );

        if (foundDevice.device.remoteId.toString() != '' && _hipeeDevice == null) {
          _hipeeDevice = foundDevice.device;
          _stopScan();
          setState(() {
            _statusMessage = "Found 'hipee'! Connecting...";
          });
          _connectToDevice(_hipeeDevice!);
        }
      });

      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 20));

    } catch (e) {
      developer.log("Error starting scan: $e");
      setState(() {
        _statusMessage = "Error: Bluetooth is not available or enabled.";
      });
    }

    if(_hipeeDevice == null && mounted){
         setState(() {
            _statusMessage = "'hipee' device not found. Please make sure it's on and nearby.";
          });
    }
  }

  Future<void> _stopScan() async {
    await FlutterBluePlus.stopScan();
    await _scanResultsSubscription?.cancel();
    _scanResultsSubscription = null;
  }

  void _connectToDevice(BluetoothDevice device) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => DeviceScreen(device: device),
        settings: const RouteSettings(name: '/device'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HiPee Posture Tracker'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isScanning)
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
              ),
            const SizedBox(height: 24),
            Text(
              _statusMessage,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            if (!_isScanning && _hipeeDevice == null)
              ElevatedButton(
                onPressed: _startScan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  textStyle: const TextStyle(fontSize: 18)
                ),
                child: const Text('Retry Scan'),
              )
          ],
        ),
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
          // Automatically start monitoring
          _toggleMonitoring(true);
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
    try {
      await widget.device.connect(license: License.free);
    } catch(e) {
       developer.log("Error connecting to device: $e");
       if (mounted) {
         // Show error and pop back
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text("Failed to connect to device."), backgroundColor: Colors.red)
         );
         Navigator.of(context).pop();
       }
    }
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

    // Specific UUIDs for HiPee device
    final serviceUuid = Guid("0000ff00-0000-1000-8000-00805f9b34fb");
    final characteristicUuid = Guid("0000ff01-0000-1000-8000-00805f9b34fb");

    try {
       final service = _services.firstWhere((s) => s.uuid == serviceUuid);
       _postureCharacteristic = service.characteristics.firstWhere((c) => c.uuid == characteristicUuid);
    } catch (e) {
      developer.log("HiPee service/characteristic not found: $e");
      // Fallback to first notifying characteristic
      for (var service in _services) {
        for (var char in service.characteristics) {
          if (char.properties.notify) {
            _postureCharacteristic = char;
            break;
          }
        }
        if (_postureCharacteristic != null) break;
      }
    }


    if (_postureCharacteristic != null) {
      await _postureCharacteristic!.setNotifyValue(true);
      _postureSubscription = _postureCharacteristic!.lastValueStream.listen((value) {
        if (value.isNotEmpty) {
          // Assuming the angle is in the 3rd byte for HiPee
          int angle = value.length > 2 ? value[2] : value[0];
          developer.log("Raw value: $value, Current angle: $angle");

          String message = '';
          if (angle > 20) { // More sensitive threshold
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
    } else {
      developer.log("No suitable characteristic found for posture monitoring.");
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
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: (){
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => HiPeeControllerScreen()),
              );
          },
        ),
      ),
      body: Center(
        child: !_isConnected ?
        const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
                CircularProgressIndicator(),
                SizedBox(height: 20),
                Text("Connecting..."),
            ],
        )
        : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Posture Status", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
             Text('Текущий угол: $_postureAngle°', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 20),
            if (_postureMessage.isNotEmpty)
              Text(
                _postureMessage,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
            if (!_isMonitoring && _isConnected)
               const Padding(
                 padding: EdgeInsets.all(20.0),
                 child: Text("Waiting for posture data...", style: TextStyle(fontStyle: FontStyle.italic),),
               ),
          ],
        ),
      ),
    );
  }
}