import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:image/image.dart' as img;
import 'package:qr_flutter/qr_flutter.dart';


class BluetoothPrinterHelper {
  // Singleton Pattern
  static final BluetoothPrinterHelper _instance = BluetoothPrinterHelper._internal();
  factory BluetoothPrinterHelper() => _instance;
  BluetoothPrinterHelper._internal();

  // Ubah URL di bawah ini ke domain Vercel Anda setelah dideploy
  // Contoh: static const String receiptBaseUrl = "https://ican-receipt.vercel.app";
  static const String receiptBaseUrl = "https://rinciann-pembayarann.vercel.app";

  static const String _prefAddressKey = 'bluetooth_printer_address';
  static const String _prefNameKey = 'bluetooth_printer_name';

  String? _savedAddress;
  String? _savedName;

  String? get savedAddress => _savedAddress;
  String? get savedName => _savedName;

  /// Helper to generate QR Code as a pixel-perfect image and return ESC/POS bytes.
  /// Renders exact 1-bit black & white matrix with 8-bit byte alignment to prevent distortion.
  /// Fix: r=row=Y axis, c=column=X axis (sesuai konvensi QR matrix).
  Future<List<int>> _generateQrCodeBytes(String data, Generator generator) async {
    try {
      final qrValidationResult = QrValidator.validate(
        data: data,
        version: QrVersions.auto,
        errorCorrectionLevel: QrErrorCorrectLevel.M, // Naikkan ke M agar lebih tahan error
      );

      if (qrValidationResult.status == QrValidationStatus.valid) {
        final qrCode = qrValidationResult.qrCode!;
        final qrImageMatrix = QrImage(qrCode);
        final int matrixSize = qrImageMatrix.moduleCount;
        const int quietZone = 4; // Standard 4-module quiet zone

        // Hitung scale: minimal 5px per modul agar QR terbaca scanner
        final int totalModules = matrixSize + (quietZone * 2);
        int scale = 6;
        if (totalModules * 6 > 280) scale = 5;
        if (totalModules * 5 > 280) scale = 4;
        // Jangan kurang dari 4 - di bawah itu QR tidak terbaca
        if (scale < 4) scale = 4;

        // Ukuran area QR (termasuk quiet zone)
        final int qrAreaSize = totalModules * scale;

        // CRITICAL: imageSize harus kelipatan 8 (byte-aligned) agar tidak geser di thermal printer
        final int imageSize = ((qrAreaSize + 7) ~/ 8) * 8;

        // Offset tengah agar QR tepat di pusat gambar
        final int offset = (imageSize - qrAreaSize) ~/ 2;

        final img.Image qrImage = img.Image(width: imageSize, height: imageSize);

        // Fill background: putih solid
        img.fill(qrImage, color: img.ColorRgb8(255, 255, 255));

        // Gambar modul QR: r = baris (Y), c = kolom (X) — penting tidak tertukar!
        for (int row = 0; row < matrixSize; row++) {
          for (int col = 0; col < matrixSize; col++) {
            if (qrImageMatrix.isDark(row, col)) {
              // col → sumbu X, row → sumbu Y
              final int pixelX = offset + (quietZone + col) * scale;
              final int pixelY = offset + (quietZone + row) * scale;

              for (int dy = 0; dy < scale; dy++) {
                for (int dx = 0; dx < scale; dx++) {
                  final int px = pixelX + dx;
                  final int py = pixelY + dy;
                  if (px < imageSize && py < imageSize) {
                    qrImage.setPixelRgb(px, py, 0, 0, 0);
                  }
                }
              }
            }
          }
        }

        return generator.image(qrImage, align: PosAlign.center);
      }
    } catch (e) {
      print("Error generating QR code image: $e");
    }
    // Fallback: pakai perintah QR native ESC/POS jika rendering gagal
    return generator.qrcode(
      data,
      align: PosAlign.center,
      size: QRSize.size4,
      cor: QRCorrection.M,
    );
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
      const testQrUrl = '$receiptBaseUrl?inv=TEST-12345';
      bytes += await _generateQrCodeBytes(testQrUrl, generator);
      bytes += generator.feed(1);
      // PENTING: reset printer setelah cetak gambar QR
      bytes += generator.reset();

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
  String generateReceiptUrl(String invoice, [DateTime? date, List<dynamic>? items, int? total]) {
    final String cleanInvoice = Uri.encodeComponent(invoice);
    final String url = "$receiptBaseUrl?inv=$cleanInvoice";
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

      final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

      // Metadata
      bytes += generator.text('Invoice : $invoice');
      bytes += generator.text('Tanggal : ${DateFormat('dd MMM yyyy, HH:mm').format(date)}');
      bytes += generator.text('--------------------------------', styles: const PosStyles(align: PosAlign.center));

      // Items Column Headers (58mm width is 32 columns typically)
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

        final formattedPrice = currencyFormatter.format(price);
        final formattedTotal = currencyFormatter.format(itemTotal);

        if (name.length > 12) {
          bytes += generator.text(name);
          bytes += generator.row([
            PosColumn(text: '  $qty x $formattedPrice', width: 7, styles: const PosStyles(align: PosAlign.left)),
            PosColumn(text: formattedTotal, width: 5, styles: const PosStyles(align: PosAlign.right)),
          ]);
        } else {
          bytes += generator.row([
            PosColumn(text: name, width: 5),
            PosColumn(text: '$qty x $formattedPrice', width: 4, styles: const PosStyles(align: PosAlign.right)),
            PosColumn(text: formattedTotal, width: 3, styles: const PosStyles(align: PosAlign.right)),
          ]);
        }
      }

      bytes += generator.text('--------------------------------', styles: const PosStyles(align: PosAlign.center));

      // Total Row
      bytes += generator.row([
        PosColumn(text: 'Total Belanja', width: 6, styles: const PosStyles(bold: true)),
        PosColumn(text: currencyFormatter.format(total), width: 6, styles: const PosStyles(bold: true, align: PosAlign.right)),
      ]);

      bytes += generator.feed(1);

      // Web HTML Receipt QR Code
      final receiptUrl = generateReceiptUrl(invoice, date, items, total);
      bytes += await _generateQrCodeBytes(receiptUrl, generator);
      bytes += generator.feed(1);
      // PENTING: reset printer setelah cetak gambar QR agar teks berikutnya tidak rusak
      bytes += generator.reset();

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
