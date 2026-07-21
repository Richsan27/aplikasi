import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../detail_pesanan/detail_pesanan_page.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PesananPage extends StatefulWidget {
  const PesananPage({super.key});

  @override
  State<PesananPage> createState() => _PesananPageState();
}

class _PesananPageState extends State<PesananPage> {
  String selectedRecapFilter = 'Semua';
  List<QueryDocumentSnapshot> _currentOrders = [];
  int _ordersLimit = 10;

  Widget buildFilterPill(String filterName) {
    bool isSelected = selectedRecapFilter == filterName;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedRecapFilter = filterName;
          _ordersLimit = 10; // Reset limit when filter changes
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFDBA31) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFFFDBA31) : const Color(0xFFE5E7EB),
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFFDBA31).withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Text(
          filterName,
          style: TextStyle(
            color: isSelected ? const Color(0xFF1E1E24) : const Color(0xFF4B5563),
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  void showDeleteConfirmDialog(BuildContext context, String docId, String invoice) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          backgroundColor: Colors.white,
          contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: Color(0xFFFEE2E2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFE11D48),
                  size: 36,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Hapus Transaksi",
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  color: Color(0xFF1E1E24),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                "Yakin ingin menghapus transaksi $invoice?\nTindakan ini tidak dapat dibatalkan.",
                style: const TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 14,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          actions: [
            SizedBox(
              width: 110,
              height: 44,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF6B7280),
                  side: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  "Batal",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            SizedBox(
              width: 110,
              height: 44,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE11D48),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () async {
                  await FirebaseFirestore.instance.collection('pesanan').doc(docId).delete();
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Color(0xFFFEE2E2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.delete_outline_rounded,
                                color: Color(0xFFDC2626),
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "Transaksi '$invoice' berhasil dihapus",
                                style: const TextStyle(
                                  color: Color(0xFF1E1E24),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                        backgroundColor: Colors.white,
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                        margin: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(color: Color(0xFFFCA5A5), width: 1.5),
                        ),
                        elevation: 6,
                      ),
                    );
                  }
                },
                child: const Text(
                  "Hapus",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> exportToPDF(List<QueryDocumentSnapshot> orders) async {
    if (orders.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Tidak ada transaksi untuk diekspor"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final pdf = pw.Document();

    int grandTotal = 0;
    for (var order in orders) {
      final data = order.data() as Map<String, dynamic>;
      grandTotal += ((data['total'] ?? 0) as num).toInt();
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Custom Brand Header
            pw.Container(
              padding: const pw.EdgeInsets.only(bottom: 16),
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColor.fromInt(0xFFFFA000), width: 2),
                ),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        "REKAP TRANSAKSI PORINA STORE",
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          color: const PdfColor.fromInt(0xFF1E1E24),
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        "Sistem POS & Kasir Photocopy Porina",
                        style: pw.TextStyle(
                          fontSize: 10,
                          color: const PdfColor.fromInt(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        "Periode: $selectedRecapFilter",
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                          color: const PdfColor.fromInt(0xFF1E1E24),
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        "Dicetak: ${DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now())}",
                        style: pw.TextStyle(
                          fontSize: 9,
                          color: const PdfColor.fromInt(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 24),

            // Transactions Table
            pw.Table.fromTextArray(
              headers: ["No. Invoice", "Tanggal", "Detail Item", "Total (Rp)"],
              data: orders.map((order) {
                final data = order.data() as Map<String, dynamic>;
                final invoice = data['invoice'] ?? '';
                final total = data['total'] ?? 0;
                final Timestamp? createdAt = data['created_at'] as Timestamp?;
                String formattedDate = '';
                if (createdAt != null) {
                  formattedDate = DateFormat('dd-MM-yyyy HH:mm').format(createdAt.toDate());
                }

                final itemsList = data['items'] as List<dynamic>? ?? [];
                String itemsStr = itemsList.map((item) {
                  final m = item as Map<String, dynamic>;
                  return "${m['name']} (x${m['qty']})";
                }).join(", ");

                return [
                  invoice,
                  formattedDate,
                  itemsStr,
                  NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0).format(total).trim()
                ];
              }).toList(),
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
                fontSize: 10,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColor.fromInt(0xFF1E1E24),
              ),
              cellStyle: const pw.TextStyle(fontSize: 9),
              cellAlignment: pw.Alignment.centerLeft,
              cellAlignments: {
                3: pw.Alignment.centerRight,
              },
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),

            pw.SizedBox(height: 30),

            // Grand Summary Block
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  "Total Transaksi: ${orders.length}",
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 11,
                    color: const PdfColor.fromInt(0xFF1E1E24),
                  ),
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                    border: pw.Border.all(color: PdfColors.grey300, width: 1),
                  ),
                  child: pw.Row(
                    children: [
                      pw.Text(
                        "TOTAL PENDAPATAN: ",
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 11,
                          color: const PdfColor.fromInt(0xFF6B7280),
                        ),
                      ),
                      pw.Text(
                        "Rp ${NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0).format(grandTotal).trim()}",
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 13,
                          color: const PdfColor.fromInt(0xFFFFA000),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ];
        },
      ),
    );

    try {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: "rekap_transaksi_${selectedRecapFilter.toLowerCase()}.pdf",
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal mencetak PDF: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Daftar Transaksi",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E1E24),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => exportToPDF(_currentOrders),
                  icon: const Icon(Icons.picture_as_pdf_rounded, size: 18, color: Color(0xFFFFA000)),
                  label: const Text(
                    "Unduh PDF",
                    style: TextStyle(
                      color: Color(0xFFFFA000),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFFFDBA31).withOpacity(0.12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 8),

          // Filter Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                buildFilterPill("Semua"),
                buildFilterPill("Mingguan"),
                buildFilterPill("Bulanan"),
              ],
            ),
          ),

          const SizedBox(height: 8),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('pesanan')
                  .orderBy('created_at', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData && snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFFDBA31),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFDBA31).withOpacity(0.08),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.receipt_long_outlined,
                            size: 36,
                            color: Color(0xFFFFA000),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          "Belum Ada Transaksi",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E1E24),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          "Transaksi yang diselesaikan akan tampil di sini",
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF9CA3AF),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                final allOrders = snapshot.data!.docs;
                final now = DateTime.now();
                final filteredOrders = allOrders.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final Timestamp? createdAt = data['created_at'] as Timestamp?;
                  if (createdAt == null) return selectedRecapFilter == 'Semua';
                  final date = createdAt.toDate();
                  if (selectedRecapFilter == 'Mingguan') {
                    return date.isAfter(now.subtract(const Duration(days: 7)));
                  } else if (selectedRecapFilter == 'Bulanan') {
                    return date.isAfter(now.subtract(const Duration(days: 30)));
                  }
                  return true;
                }).toList();

                _currentOrders = filteredOrders;

                if (filteredOrders.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 64,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "Tidak ada transaksi pada periode ini",
                          style: TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: [
                    // Dynamic Header update to bind the active export button
                    // We will update the row so the export button actually runs with the current list of orders!
                    Expanded(
                      child: ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: filteredOrders.length > _ordersLimit
                            ? _ordersLimit + 1
                            : filteredOrders.length,
                        itemBuilder: (context, index) {
                          if (index == _ordersLimit) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16.0),
                              child: Center(
                                child: TextButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _ordersLimit += 10;
                                    });
                                  },
                                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFFFFA000)),
                                  label: const Text(
                                    "Muat Lebih Banyak",
                                    style: TextStyle(
                                      color: Color(0xFFFFA000),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  style: TextButton.styleFrom(
                                    backgroundColor: const Color(0xFFFDBA31).withOpacity(0.08),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  ),
                                ),
                              ),
                            );
                          }

                          final order = filteredOrders[index];
                          final orderData = order.data() as Map<String, dynamic>;
                          final total = orderData['total'] ?? 0;
                          final invoice = orderData['invoice'] ?? '';
                          
                          // Format Timestamp
                          final Timestamp? createdAt = orderData['created_at'] as Timestamp?;
                          String formattedDate = '';
                          if (createdAt != null) {
                            formattedDate = DateFormat('dd MMM yyyy, HH:mm').format(createdAt.toDate());
                          }

                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFFE5E7EB).withOpacity(0.5),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.015),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                leading: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFDBA31).withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.receipt_long_rounded,
                                    color: Color(0xFFFFA000),
                                    size: 20,
                                  ),
                                ),
                                title: Text(
                                  invoice,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E1E24),
                                    fontSize: 15,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    if (formattedDate.isNotEmpty)
                                      Text(
                                        formattedDate,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[500],
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Total: Rp $total",
                                      style: const TextStyle(
                                        color: Color(0xFFFFA000),
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    GestureDetector(
                                      onTap: () => showDeleteConfirmDialog(context, order.id, invoice),
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.red.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Icon(
                                          Icons.delete_outline_rounded,
                                          size: 18,
                                          color: Colors.red,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(
                                      Icons.chevron_right_rounded,
                                      color: Color(0xFF9CA3AF),
                                    ),
                                  ],
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => DetailPesananPage(
                                        orderData: orderData,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}