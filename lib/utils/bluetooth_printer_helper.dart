import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;
import 'package:image/image.dart' as img;
import 'package:qr_flutter/qr_flutter.dart';


class BluetoothPrinterHelper {
  // Singleton Pattern
  static final BluetoothPrinterHelper _instance = BluetoothPrinterHelper._internal();
  factory BluetoothPrinterHelper() => _instance;
  BluetoothPrinterHelper._internal();

  // Ubah URL di bawah ini ke domain Vercel Anda setelah dideploy
  // Contoh: static const String receiptBaseUrl = "https://ican-receipt.vercel.app";
  static const String receiptBaseUrl = "https://rincian-pembayarann.vercel.app";

  static const String _prefAddressKey = 'bluetooth_printer_address';
  static const String _prefNameKey = 'bluetooth_printer_name';

  String? _savedAddress;
  String? _savedName;

  String? get savedAddress => _savedAddress;
  String? get savedName => _savedName;

  /// Helper to generate QR Code as an image and return ESC/POS bytes.
  /// This avoids buffer overflow on printers with long QR code strings.
  Future<List<int>> _generateQrCodeBytes(String data, Generator generator) async {
    try {
      final qrValidationResult = QrValidator.validate(
        data: data,
        version: QrVersions.auto,
        errorCorrectionLevel: QrErrorCorrectLevel.L,
      );
      
      if (qrValidationResult.status == QrValidationStatus.valid) {
        final qrCode = qrValidationResult.qrCode!;
        final painter = QrPainter.withQr(
          qr: qrCode,
          eyeStyle: const QrEyeStyle(
            eyeShape: QrEyeShape.square,
            color: ui.Color(0xFF000000),
          ),
          dataModuleStyle: const QrDataModuleStyle(
            dataModuleShape: QrDataModuleShape.square,
            color: ui.Color(0xFF000000),
          ),
          gapless: true,
        );
        
        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(recorder);
        
        // Draw solid white background first
        final backgroundPaint = ui.Paint()..color = const ui.Color(0xFFFFFFFF);
        canvas.drawRect(const ui.Rect.fromLTWH(0, 0, 200, 200), backgroundPaint);
        
        // Paint at 200x200 size, suitable for 58mm thermal printers
        painter.paint(canvas, const ui.Size(200, 200));
        final picture = recorder.endRecording();
        final uiImage = await picture.toImage(200, 200);
        final byteData = await uiImage.toByteData(format: ui.ImageByteFormat.png);
        
        if (byteData != null) {
          final pngBytes = byteData.buffer.asUint8List();
          final img.Image? decodedImage = img.decodePng(pngBytes);
          if (decodedImage != null) {
            return generator.imageRaster(decodedImage, align: PosAlign.center);
          }
        }
      }
    } catch (e) {
      print("Error generating QR code image: $e");
    }
    // Fallback to native ESC/POS QR code command if image rendering fails
    return generator.qrcode(data);
  }

  /// Initialize and try to auto-connect to the saved printer
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _savedAddress = prefs.getString(_prefAddressKey);
    _savedName = prefs.getString(_prefNameKey);

    if (_savedAddress != null) {
      final isConnected = await checkConnection();
      if (!isConnected) {
        // Try to connect in the background
        await connect(_savedAddress!, _savedName!);
      }
    }
  }

  /// Request required Bluetooth permissions
  Future<bool> requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetooth,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.location,
    ].request();

    final isBluetoothConnectGranted = statuses[Permission.bluetoothConnect]?.isGranted ?? true;
    final isBluetoothScanGranted = statuses[Permission.bluetoothScan]?.isGranted ?? true;
    final isBluetoothGranted = statuses[Permission.bluetooth]?.isGranted ?? true;

    return isBluetoothGranted && isBluetoothConnectGranted && isBluetoothScanGranted;
  }

  /// Get list of paired bluetooth devices
  Future<List<BluetoothInfo>> getPairedDevices() async {
    final hasPermission = await requestPermissions();
    if (!hasPermission) {
      return [];
    }

    try {
      final List<BluetoothInfo> devices = await PrintBluetoothThermal.pairedBluetooths;
      return devices;
    } catch (e) {
      print("Error getting paired bluetooth devices: $e");
      return [];
    }
  }

  /// Connect to a bluetooth device
  Future<bool> connect(String address, String name) async {
    try {
      final bool result = await PrintBluetoothThermal.connect(macPrinterAddress: address);
      if (result) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_prefAddressKey, address);
        await prefs.setString(_prefNameKey, name);
        _savedAddress = address;
        _savedName = name;
        print("Successfully connected to printer: $name ($address)");
      }
      return result;
    } catch (e) {
      print("Failed to connect to printer: $e");
      return false;
    }
  }

  /// Disconnect the current printer
  Future<bool> disconnect() async {
    try {
      final bool result = await PrintBluetoothThermal.disconnect;
      if (result) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_prefAddressKey);
        await prefs.remove(_prefNameKey);
        _savedAddress = null;
        _savedName = null;
        print("Disconnected from printer");
      }
      return result;
    } catch (e) {
      print("Failed to disconnect printer: $e");
      return false;
    }
  }

  /// Check if the printer is currently connected
  Future<bool> checkConnection() async {
    try {
      final bool isConnected = await PrintBluetoothThermal.connectionStatus;
      return isConnected;
    } catch (e) {
      print("Error checking connection status: $e");
      return false;
    }
  }

  /// Print a test receipt page
  Future<bool> printTest() async {
    final isConnected = await checkConnection();
    if (!isConnected) {
      if (_savedAddress != null && _savedName != null) {
        // Try reconnecting first
        final reconnected = await connect(_savedAddress!, _savedName!);
        if (!reconnected) return false;
      } else {
        return false;
      }
    }

    try {
      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm58, profile);
      List<int> bytes = [];

      // Shop Header
      bytes += generator.text(
        'Photocopy Porina',
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ),
      );
      bytes += generator.text(
        'Sistem POS & Kasir',
        styles: const PosStyles(align: PosAlign.center),
      );
      bytes += generator.feed(1);

      bytes += generator.text(
        '=== TES CETAK ===',
        styles: const PosStyles(align: PosAlign.center, bold: true),
      );
      bytes += generator.feed(1);

      bytes += generator.text(
        'Printer Bluetooth berhasil terhubung dan berfungsi dengan baik!',
        styles: const PosStyles(align: PosAlign.center),
      );
      bytes += generator.feed(1);

      bytes += generator.text(
        'Waktu: ${DateFormat('dd-MM-yyyy HH:mm:ss').format(DateTime.now())}',
        styles: const PosStyles(align: PosAlign.center),
      );
      bytes += generator.text(
        '--------------------------------',
        styles: const PosStyles(align: PosAlign.center),
      );
      bytes += generator.feed(1);

      // Print Test QR Code
      const testQrUrl = '$receiptBaseUrl?invoice=TEST-12345&date=16%20Jul%202026,%2019:00&total=10000&items=Tes%20Printer%20Porina:1:10000';
      bytes += await _generateQrCodeBytes(testQrUrl, generator);
      bytes += generator.feed(1);

      bytes += generator.feed(1);
      bytes += generator.cut();

      final bool result = await PrintBluetoothThermal.writeBytes(bytes);
      return result;
    } catch (e) {
      print("Error printing test page: $e");
      return false;
    }
  }

  /// Generate a digital web receipt URL
  String generateReceiptUrl(String invoice, DateTime date, List<dynamic> items, int total) {
    final String formattedDate = DateFormat('dd MMM yyyy, HH:mm').format(date);
    final List<String> itemStrings = [];
    for (var item in items) {
      final String name = item['name'] ?? '';
      final encodedName = Uri.encodeComponent(name);
      final qty = item['qty'] ?? 0;
      final price = item['price'] ?? 0;
      itemStrings.add('$encodedName:$qty:$price');
    }
    final String itemsParam = itemStrings.join(',');
    final String url = "$receiptBaseUrl"
        "?invoice=${Uri.encodeComponent(invoice)}"
        "&date=${Uri.encodeComponent(formattedDate)}"
        "&total=$total"
        "&items=$itemsParam";
    print("DEBUG RECEIPT URL: $url");
    return url;
  }

  /// Print a completed order receipt
  Future<bool> printOrderReceipt(Map<String, dynamic> order) async {
    final isConnected = await checkConnection();
    if (!isConnected) {
      if (_savedAddress != null && _savedName != null) {
        // Try reconnecting first
        final reconnected = await connect(_savedAddress!, _savedName!);
        if (!reconnected) return false;
      } else {
        return false;
      }
    }

    try {
      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm58, profile);
      List<int> bytes = [];

      // Extract details
      final invoice = order['invoice'] ?? 'INV-N/A';
      final total = order['total'] ?? 0;
      
      DateTime date = DateTime.now();
      if (order['created_at'] != null) {
        if (order['created_at'] is DateTime) {
          date = order['created_at'];
        } else {
          // If it's a Firestore Timestamp
          date = (order['created_at'] as dynamic).toDate();
        }
      }

      final items = List<dynamic>.from(order['items'] ?? []);

      // Shop Header
      bytes += generator.text(
        'Photocopy Porina',
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ),
      );
      bytes += generator.text(
        'Sistem POS & Kasir',
        styles: const PosStyles(align: PosAlign.center),
      );
      bytes += generator.feed(1);

      // Metadata
      bytes += generator.text('Invoice : $invoice');
      bytes += generator.text('Tanggal : ${DateFormat('dd MMM yyyy, HH:mm').format(date)}');
      bytes += generator.text('--------------------------------', styles: const PosStyles(align: PosAlign.center));

      // Items Column Headers (58mm width is 32 columns typically)
      // We will print "Item" (width 6), "Qty x Harga" (width 3), "Total" (width 3)
      bytes += generator.row([
        PosColumn(text: 'Item', width: 5, styles: const PosStyles(bold: true)),
        PosColumn(text: 'Harga/Qty', width: 4, styles: const PosStyles(bold: true, align: PosAlign.right)),
        PosColumn(text: 'Total', width: 3, styles: const PosStyles(bold: true, align: PosAlign.right)),
      ]);
      bytes += generator.text('--------------------------------', styles: const PosStyles(align: PosAlign.center));

      // Print Items
      for (var item in items) {
        final name = item['name'] ?? '';
        final qty = item['qty'] ?? 0;
        final price = item['price'] ?? 0;
        final itemTotal = qty * price;

        if (name.length > 15) {
          bytes += generator.text(name);
          bytes += generator.row([
            PosColumn(text: '', width: 2),
            PosColumn(text: '$qty x $price', width: 6, styles: const PosStyles(align: PosAlign.right)),
            PosColumn(text: '$itemTotal', width: 4, styles: const PosStyles(align: PosAlign.right)),
          ]);
        } else {
          bytes += generator.row([
            PosColumn(text: name, width: 5),
            PosColumn(text: '$qty x $price', width: 4, styles: const PosStyles(align: PosAlign.right)),
            PosColumn(text: '$itemTotal', width: 3, styles: const PosStyles(align: PosAlign.right)),
          ]);
        }
      }

      bytes += generator.text('--------------------------------', styles: const PosStyles(align: PosAlign.center));

      // Total Row
      bytes += generator.row([
        PosColumn(text: 'Total Belanja', width: 7, styles: const PosStyles(bold: true)),
        PosColumn(text: 'Rp $total', width: 5, styles: const PosStyles(bold: true, align: PosAlign.right)),
      ]);

      bytes += generator.feed(1);

      // Web HTML Receipt QR Code
      final receiptUrl = generateReceiptUrl(invoice, date, items, total);
      bytes += await _generateQrCodeBytes(receiptUrl, generator);
      bytes += generator.feed(1);

      bytes += generator.text(
        'Terima Kasih',
        styles: const PosStyles(align: PosAlign.center, bold: true),
      );
      bytes += generator.text(
        'Atas Kunjungan Anda',
        styles: const PosStyles(align: PosAlign.center),
      );
      bytes += generator.feed(3);
      bytes += generator.cut();

      final bool result = await PrintBluetoothThermal.writeBytes(bytes);
      return result;
    } catch (e) {
      print("Error printing order receipt: $e");
      return false;
    }
  }
}
