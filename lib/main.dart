import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

void main() {
  runApp(const FlutterBlueApp());
}

// --- Виджеты в стиле "Жидкое стекло" ---

class LiquidButton extends StatelessWidget {
  final VoidCallback? onTap;
  final Widget child;
  final double width;
  final double height;
  final double borderRadius;

  const LiquidButton({
    super.key,
    this.onTap,
    required this.child,
    this.width = 100,
    this.height = 50,
    this.borderRadius = 15,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: LiquidGlass.grouped(
        shape: LiquidRoundedSuperellipse(
          borderRadius: borderRadius,
        ),
        child: SizedBox(
          width: width,
          height: height,
          child: Center(child: child),
        ),
      ),
    );
  }
}

// --- Основная структура приложения ---

class FlutterBlueApp extends StatelessWidget {
  const FlutterBlueApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.lightBlue,
        brightness: Brightness.light,
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.lightBlue,
        brightness: Brightness.dark,
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme.apply(bodyColor: Colors.white, displayColor: Colors.white)),
      ),
      themeMode: ThemeMode.system,
      home: StreamBuilder<BluetoothAdapterState>(
        stream: FlutterBluePlus.adapterState,
        initialData: BluetoothAdapterState.unknown,
        builder: (c, snapshot) {
          final adapterState = snapshot.data;
          if (adapterState == BluetoothAdapterState.on) {
            return const AppShell();
          } else {
            return BluetoothOffScreen(adapterState: adapterState);
          }
        },
      ),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 1;

  static const List<Widget> _widgetOptions = <Widget>[
    HomeScreen(),
    ScanScreen(),
    AboutScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LiquidGlassLayer(
        settings: const LiquidGlassSettings(
          thickness: 20,
          blur: 10,
        ),
        child: Stack(
          children: [
            _widgetOptions.elementAt(_selectedIndex),
            Align(
              alignment: Alignment.bottomCenter,
              child: LiquidGlassBlendGroup(
                blend: 20.0,
                child: Container(
                  padding: const EdgeInsets.only(bottom: 24, top: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildNavItem(icon: Icons.home_rounded, index: 0),
                      _buildNavItem(icon: Icons.bluetooth_searching_rounded, index: 1),
                      _buildNavItem(icon: Icons.info_outline_rounded, index: 2),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({required IconData icon, required int index}) {
    bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: LiquidGlass.grouped(
        shape: LiquidRoundedSuperellipse(
          borderRadius: 40,
        ),
        child: SizedBox(
          width: 80,
          height: 80,
          child: Icon(
            icon,
            color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface.withAlpha(200),
            size: 30,
          ),
        ),
      ),
    );
  }
}

// --- Экраны ---

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Главная'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bluetooth_audio_rounded, size: 100, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 20),
          Text('Bluetooth Сканер', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          const Text('Найдите и подключитесь к устройствам поблизости', textAlign: TextAlign.center),
        ],
      )),
    );
  }
}

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('О приложении'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            'Это приложение разработано для демонстрации возможностей Flutter и плагина flutter_blue_plus.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
        ),
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
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.bluetooth_disabled, size: 150.0, color: Colors.white54),
            const SizedBox(height: 20),
            Text('Bluetooth выключен', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 10),
            Text('Пожалуйста, включите Bluetooth для сканирования устройств.', textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 16, color: Colors.white70)),
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
        setState(() => _scanResults = results);
      }
    });
    _isScanningSubscription = FlutterBluePlus.isScanning.listen((state) {
      if (mounted) setState(() {});
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
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка сканирования: $e')));
    }
  }

  Future<void> onStopPressed() async {
    try {
      await FlutterBluePlus.stopScan();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка остановки: $e')));
    }
  }

  void onConnectPressed(BluetoothDevice device) {
    final route = MaterialPageRoute(builder: (context) => DeviceScreen(device: device), settings: const RouteSettings(name: '/DeviceScreen'));
    Navigator.of(context, rootNavigator: true).push(route);
  }

  Future<void> onRefresh() async {
    if (!FlutterBluePlus.isScanningNow) {
      await onScanPressed();
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    bool isScanning = FlutterBluePlus.isScanningNow;
    final bottomPadding = MediaQuery.of(context).padding.bottom + 180;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Сканер устройств'), backgroundColor: Colors.transparent, elevation: 0),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: onRefresh,
            child: _scanResults.isEmpty
                ? Center(
                    child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.search_off, size: 80, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(isScanning ? 'Идет поиск...' : 'Устройства не найдены', style: const TextStyle(fontSize: 18, color: Colors.grey)),
                      if (!isScanning) Text('Нажмите кнопку сканирования для начала поиска', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                    ],
                  ))
                : ListView.builder(
                    padding: EdgeInsets.only(bottom: bottomPadding), // Отступ для плавающей кнопки и меню
                    itemCount: _scanResults.length,
                    itemBuilder: (context, index) => ScanResultTile(result: _scanResults[index], onTap: () => onConnectPressed(_scanResults[index].device)),
                  ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: EdgeInsets.only(right: 30, bottom: bottomPadding - 80),
              child: LiquidButton(
                onTap: isScanning ? onStopPressed : onScanPressed,
                width: 150,
                height: 60,
                borderRadius: 25,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(isScanning ? Icons.stop_rounded : Icons.search_rounded, color: isScanning ? Colors.redAccent : Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(isScanning ? 'ОСТАНОВИТЬ' : 'СКАНИРОВАТЬ', style: TextStyle(color: isScanning ? Colors.redAccent : Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ScanResultTile extends StatelessWidget {
  const ScanResultTile({super.key, required this.result, this.onTap});

  final ScanResult result;
  final VoidCallback? onTap;

  String getNiceName() {
    String name = result.device.platformName.isNotEmpty ? result.device.platformName : result.advertisementData.advName;
    return name.isNotEmpty ? name : 'N/A';
  }

  IconData getRssiIcon() {
    if (result.rssi > -60) return Icons.network_wifi;
    if (result.rssi > -70) return Icons.network_wifi_3_bar;
    if (result.rssi > -80) return Icons.network_wifi_2_bar;
    return Icons.network_wifi_1_bar;
  }

  @override
  Widget build(BuildContext context) {
    bool isConnectable = result.advertisementData.connectable;
    return Card(
      elevation: 2,
      color: Theme.of(context).colorScheme.surface.withAlpha(180),
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [Icon(getRssiIcon(), color: Theme.of(context).colorScheme.primary), Text('${result.rssi} dBm', style: const TextStyle(fontSize: 12, color: Colors.grey))],
        ),
        title: Text(getNiceName(), style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(result.device.remoteId.toString(), style: const TextStyle(fontSize: 12)),
        trailing: isConnectable
            ? LiquidButton(onTap: onTap, child: Text('ПОДКЛ.', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)))
            : const SizedBox(width: 100, child: Center(child: Text('-', style: TextStyle(color: Colors.grey)))),
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
    _connectionStateSubscription = widget.device.connectionState.listen((state) async {
      if (mounted) {
        if (state == BluetoothConnectionState.disconnected && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
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
    if (widget.device.isConnected) return;
    try {
      await widget.device.connect(timeout: const Duration(seconds: 15), license: License.free);
      if (mounted) {
        _services = await widget.device.discoverServices();
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка подключения: $e')));
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

  @override
  Widget build(BuildContext context) {
    String deviceName = widget.device.platformName.isNotEmpty ? widget.device.platformName : 'Unknown Device';
    bool isConnected = widget.device.isConnected;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(deviceName),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 10.0),
            child: LiquidButton(
              onTap: () => isConnected ? _disconnect() : _connectAndDiscover(),
              width: 140,
              borderRadius: 20,
              child: Text(
                isConnected ? 'ОТКЛЮЧИТЬ' : 'ПОДКЛЮЧИТЬ',
                style: TextStyle(color: isConnected ? Colors.redAccent : Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
              ),
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 120), // Отступ для меню
        child: Column(
          children: <Widget>[
            _buildInfoTile(),
            if (_services.isEmpty && isConnected) const Padding(padding: EdgeInsets.only(top: 50.0), child: Center(child: CircularProgressIndicator())),
            ..._services.map((s) => ServiceTile(
                  service: s,
                  characteristicTiles: s.characteristics.map((c) => CharacteristicTile(characteristic: c)).toList(),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile() {
    return Card(
      elevation: 2,
      color: Theme.of(context).colorScheme.surface.withAlpha(180),
      margin: const EdgeInsets.all(10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('MAC Адрес:', style: TextStyle(fontWeight: FontWeight.bold)), Text(widget.device.remoteId.toString())]),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Статус:', style: TextStyle(fontWeight: FontWeight.bold)),
              StreamBuilder<BluetoothConnectionState>(
                  stream: widget.device.connectionState,
                  initialData: BluetoothConnectionState.disconnected,
                  builder: (c, snapshot) {
                    bool isConnected = snapshot.data == BluetoothConnectionState.connected;
                    return Text(snapshot.data.toString().split('.').last, style: TextStyle(fontWeight: FontWeight.bold, color: isConnected ? Colors.green : Colors.red));
                  }),
            ]),
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
      color: Theme.of(context).colorScheme.surface.withAlpha(180),
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: const Text('Service', style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('0x${service.uuid.toString().toUpperCase().substring(4, 8)}'),
        children: characteristicTiles,
      ),
    );
  }
}

class CharacteristicTile extends StatefulWidget {
  final BluetoothCharacteristic characteristic;

  const CharacteristicTile({super.key, required this.characteristic});

  @override
  State<CharacteristicTile> createState() => _CharacteristicTileState();
}

class _CharacteristicTileState extends State<CharacteristicTile> {
  List<int> _value = [];
  late StreamSubscription<List<int>> _lastValueSubscription;

  @override
  void initState() {
    super.initState();
    _lastValueSubscription = widget.characteristic.lastValueStream.listen((value) {
      if (mounted) setState(() => _value = value);
    });
  }

  @override
  void dispose() {
    _lastValueSubscription.cancel();
    super.dispose();
  }

  String getProperties() {
    List<String> props = [];
    if (widget.characteristic.properties.read) props.add("Read");
    if (widget.characteristic.properties.write) props.add("Write");
    if (widget.characteristic.properties.notify) props.add("Notify");
    if (widget.characteristic.properties.indicate) props.add("Indicate");
    return props.join(', ');
  }

  Future onReadPressed() async {
    await widget.characteristic.read();
  }

  Future onWritePressed() async {
    await widget.characteristic.write([0x01]); // Simple write example
  }

  Future onNotificationPressed() async {
    await widget.characteristic.setNotifyValue(!widget.characteristic.isNotifying);
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text('Characteristic 0x${widget.characteristic.uuid.toString().toUpperCase().substring(4, 8)}'),
      subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Value: ${_value.toString()}'), Text('Properties: ${getProperties()}', style: const TextStyle(color: Colors.grey))]),
      trailing: LiquidGlassBlendGroup(
        blend: 10,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (widget.characteristic.properties.read) LiquidButton(onTap: onReadPressed, width: 44, height: 44, borderRadius: 22, child: const Icon(Icons.file_download_outlined, size: 24)),
            if (widget.characteristic.properties.write) LiquidButton(onTap: onWritePressed, width: 44, height: 44, borderRadius: 22, child: const Icon(Icons.file_upload_outlined, size: 24)),
            if (widget.characteristic.properties.notify || widget.characteristic.properties.indicate)
              LiquidButton(onTap: onNotificationPressed, width: 44, height: 44, borderRadius: 22, child: Icon(widget.characteristic.isNotifying ? Icons.notifications_active : Icons.notifications_none, size: 24)),
          ],
        ),
      ),
    );
  }
}
