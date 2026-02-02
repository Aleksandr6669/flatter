
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const FlutterBlueApp());
}

class FlutterBlueApp extends StatelessWidget {
  const FlutterBlueApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: Colors.lightBlue,
        scaffoldBackgroundColor: Colors.grey[100],
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.lightBlue,
          foregroundColor: Colors.white,
          titleTextStyle: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.lightBlue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
      ),
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
        },
      ),
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
              size: 150.0,
              color: Colors.white54,
            ),
            const SizedBox(height: 20),
            Text(
              'Bluetooth выключен',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Пожалуйста, включите Bluetooth для сканирования устройств.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.white70,
              ),
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
  late StreamSubscription<List<ScanResult>> _scanResultsSubscription;
  late StreamSubscription<bool> _isScanningSubscription;

  @override
  void initState() {
    super.initState();
    _scanResultsSubscription = FlutterBluePlus.scanResults.listen((results) {
      if (mounted) {
        setState(() {
          _scanResults = results;
        });
      }
    });

    _isScanningSubscription = FlutterBluePlus.isScanning.listen((state) {
      if (mounted) {
        setState(() {});
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
      final snackBar = SnackBar(content: Text('Ошибка сканирования: ${e.toString()}'));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    }
  }

  Future<void> onStopPressed() async {
    try {
      await FlutterBluePlus.stopScan();
    } catch (e) {
      final snackBar = SnackBar(content: Text('Ошибка остановки: ${e.toString()}'));
       if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    }
  }

  void onConnectPressed(BluetoothDevice device) {
     final route = MaterialPageRoute(
      builder: (context) => DeviceScreen(device: device),
      settings: const RouteSettings(name: '/DeviceScreen'),
    );
    Navigator.of(context).push(route);
  }

  Future<void> onRefresh() async {
    if (!FlutterBluePlus.isScanningNow) {
      await onScanPressed();
    }
     if (mounted) {
      setState(() {});
    }
  }

  Widget buildScanButton(BuildContext context) {
    bool isScanning = FlutterBluePlus.isScanningNow;
    return FloatingActionButton.extended(
      onPressed: isScanning ? onStopPressed : onScanPressed,
      label: Text(isScanning ? 'ОСТАНОВИТЬ' : 'СКАНИРОВАТЬ'),
      icon: isScanning ? const Icon(Icons.stop) : const Icon(Icons.search),
      backgroundColor: isScanning ? Colors.redAccent : Colors.lightBlue,
    );
  }

  Widget _buildScanResultList() {
    return _scanResults.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.search_off, size: 80, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  FlutterBluePlus.isScanningNow ? 'Идет поиск...' : 'Устройства не найдены',
                  style: const TextStyle(fontSize: 18, color: Colors.grey),
                ),
                if (!FlutterBluePlus.isScanningNow)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'Нажмите "СКАНИРОВАТЬ" для начала поиска',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ),
              ],
            ),
          )
        : ListView.builder(
            itemCount: _scanResults.length,
            itemBuilder: (context, index) {
              final result = _scanResults[index];
              return ScanResultTile(
                result: result,
                onTap: () => onConnectPressed(result.device),
              );
            },
          );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Поиск Bluetooth устройств'),
        
      ),
      body: RefreshIndicator(
        onRefresh: onRefresh,
        child: _buildScanResultList(),
      ),
      floatingActionButton: buildScanButton(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class ScanResultTile extends StatelessWidget {
  const ScanResultTile({super.key, required this.result, this.onTap});

  final ScanResult result;
  final VoidCallback? onTap;

  String getNiceName() {
    String name = '';
    if (result.device.platformName.isNotEmpty) {
      name = result.device.platformName;
    } else if (result.advertisementData.advName.isNotEmpty) {
      name = result.advertisementData.advName;
    } else {
      name = 'N/A';
    }
    return name;
  }

  IconData getRssiIcon() {
    int rssi = result.rssi;
    if (rssi > -60) return Icons.network_wifi;
    if (rssi > -70) return Icons.network_wifi_3_bar;
    if (rssi > -80) return Icons.network_wifi_2_bar;
    if (rssi > -90) return Icons.network_wifi_1_bar;
    return Icons.signal_wifi_off;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              getRssiIcon(),
              color: Colors.lightBlue,
            ),
            Text(
              '${result.rssi} dBm',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        title: Text(
          getNiceName(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          result.device.remoteId.toString(),
          style: const TextStyle(fontSize: 12),
        ),
        trailing: ElevatedButton(
          onPressed: result.advertisementData.connectable ? onTap : null,
          child: const Text('ПОДКЛ.'),
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
  late StreamSubscription<BluetoothConnectionState> _connectionStateSubscription;

  @override
  void initState() {
    super.initState();

    _connectionStateSubscription =
        widget.device.connectionState.listen((state) async {
      if (mounted) {
         if (state == BluetoothConnectionState.disconnected) {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
        }
        setState(() {});
      }
    });

    _connectAndDiscover();
  }

  @override
  void dispose() {
    _connectionStateSubscription.cancel();
    _disconnect();
    super.dispose();
  }

  Future<void> _connectAndDiscover() async {
    try {
      if (widget.device.isConnected) return;
      await widget.device.connect(timeout: const Duration(seconds: 15), license: License.free);
      if(mounted){
          _services = await widget.device.discoverServices();
          setState((){});
      }
    } catch (e) {
      if (mounted) {
        final snackBar = SnackBar(content: Text('Ошибка подключения: $e'));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _disconnect() async {
    try {
      await widget.device.disconnect();
    } catch (e) {
       if (mounted) {
          final snackBar = SnackBar(content: Text('Ошибка отключения: $e'));
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
       }
    }
  }


  Widget _buildInfoTile() {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(10),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
             Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('MAC Адрес:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(widget.device.remoteId.toString()),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Статус:', style: TextStyle(fontWeight: FontWeight.bold)),
                  StreamBuilder<BluetoothConnectionState>(
                      stream: widget.device.connectionState,
                      initialData: BluetoothConnectionState.disconnected,
                      builder: (c, snapshot) {
                        return Text(
                          snapshot.data.toString().split('.').last,
                          style: TextStyle(
                              color: snapshot.data == BluetoothConnectionState.connected
                                  ? Colors.green
                                  : Colors.red),
                        );
                      }),
                ],
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String deviceName = widget.device.platformName.isNotEmpty ? widget.device.platformName : 'Unknown Device';
    return Scaffold(
      appBar: AppBar(
        title: Text(deviceName),
        actions: <Widget>[
          TextButton(
            onPressed: widget.device.isConnected ? _disconnect : _connectAndDiscover,
            child: Text(
              widget.device.isConnected ? 'ОТКЛЮЧИТЬ' : 'ПОДКЛЮЧИТЬ',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            _buildInfoTile(),
            if (_services.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 50.0),
                child: widget.device.isConnected
                    ? const Center(child: CircularProgressIndicator())
                    : const Center(
                        child: Text(
                        'Устройство не подключено',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      )),
              ),
            ..._services.map(
              (s) => ServiceTile(
                service: s,
                characteristicTiles: s.characteristics
                    .map(
                      (c) => CharacteristicTile(
                        characteristic: c,
                        onReadPressed: () async {
                           await c.read();
                           if(mounted) setState((){});
                        },
                        onWritePressed: () async {
                          // Simple write example
                          await c.write([0x01]);
                          if(mounted) setState((){});
                        },
                        onNotificationPressed: () async {
                           await c.setNotifyValue(!c.isNotifying);
                           if(mounted) setState((){});
                        },
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ServiceTile extends StatelessWidget {
  final BluetoothService service;
  final List<CharacteristicTile> characteristicTiles;

  const ServiceTile({super.key, required this.service, required this.characteristicTiles});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: ExpansionTile(
        title: const Text('Service', style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('0x${service.uuid.toString().toUpperCase().substring(4, 8)}'),
        children: characteristicTiles,
      ),
    );
  }
}

class CharacteristicTile extends StatelessWidget {
  final BluetoothCharacteristic characteristic;
  final VoidCallback? onReadPressed;
  final VoidCallback? onWritePressed;
  final VoidCallback? onNotificationPressed;

  const CharacteristicTile({
    super.key,
    required this.characteristic,
    this.onReadPressed,
    this.onWritePressed,
    this.onNotificationPressed,
  });

   String getProperties() {
    List<String> props = [];
    if (characteristic.properties.read) props.add("Read");
    if (characteristic.properties.write) props.add("Write");
    if (characteristic.properties.notify) props.add("Notify");
    if (characteristic.properties.indicate) props.add("Indicate");
    return props.join(', ');
  }


  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<int>>(
      stream: characteristic.lastValueStream,
      initialData: characteristic.lastValue,
      builder: (context, snapshot) {
        final value = snapshot.data ?? [];
        return ListTile(
          title: Text(
            'Characteristic 0x${characteristic.uuid.toString().toUpperCase().substring(4, 8)}',
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               Text('Value: ${value.toString()}'),
               Text('Properties: ${getProperties()}', style: const TextStyle(color: Colors.grey)),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (characteristic.properties.read)
                IconButton(icon: const Icon(Icons.file_download_outlined), onPressed: onReadPressed),
              if (characteristic.properties.write)
                IconButton(icon: const Icon(Icons.file_upload_outlined), onPressed: onWritePressed),
              if (characteristic.properties.notify || characteristic.properties.indicate)
                IconButton(
                  icon: Icon(
                    characteristic.isNotifying ? Icons.notifications_active : Icons.notifications_none,
                  ),
                  onPressed: onNotificationPressed,
                ),
            ],
          ),
        );
      },
    );
  }
}
