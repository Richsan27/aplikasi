import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DetailPesananPage extends StatelessWidget {
  final Map<String, dynamic> orderData;

  const DetailPesananPage({
    super.key,
    required this.orderData,
  });

  @override
  Widget build(BuildContext context) {
    final items = List<Map<String, dynamic>>.from(
      orderData['items'] ?? [],
    );

    final createdAt = orderData['created_at'] as Timestamp;
    final total = orderData['total'] ?? 0;
    final invoice = orderData['invoice'] ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text(
          "Detail Transaksi",
          style: TextStyle(
            color: Color(0xFF1E1E24),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1E1E24)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        child: Column(
          children: [
            // Receipt Card container
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: const Color(0xFFE5E7EB).withOpacity(0.5),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top Icon Indicator (Success state)
                    Center(
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_circle_rounded,
                          color: Color(0xFF15803D),
                          size: 32,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    const Center(
                      child: Text(
                        "Transaksi Berhasil",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF15803D),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Receipt Info Table
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "No. Invoice",
                          style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          invoice,
                          style: const TextStyle(color: Color(0xFF1E1E24), fontSize: 13, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Waktu Transaksi",
                          style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          DateFormat('dd MMM yyyy, HH:mm').format(createdAt.toDate()),
                          style: const TextStyle(color: Color(0xFF1E1E24), fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Dashed Divider 1
                    const DashedDivider(),
                    const SizedBox(height: 20),

                    // Item Lists Header
                    const Text(
                      "Rincian Belanja",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E1E24),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // List of items
                    ...items.map((item) {
                      final itemPrice = item['price'] ?? 0;
                      final itemQty = item['qty'] ?? 0;
                      final itemSubtotal = itemPrice * itemQty;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['name'] ?? '',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1E1E24),
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Rp $itemPrice x $itemQty",
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              "Rp $itemSubtotal",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E1E24),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),

                    const SizedBox(height: 20),

                    // Dashed Divider 2
                    const DashedDivider(),
                    const SizedBox(height: 20),

                    // Total Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Total Bayar",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                        Text(
                          "Rp $total",
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFFFA000),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Selesai Button (Done styled with arrow indicator)
            SizedBox(
              height: 54,
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFDBA31),
                  foregroundColor: const Color(0xFF1E1E24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(27),
                  ),
                  elevation: 0,
                ),
                onPressed: () => Navigator.pop(context),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(width: 24),
                    Text(
                      "Kembali ke Pesanan",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Icon(Icons.check_rounded, size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// Dashed Divider widget representing custom tear-off line
class DashedDivider extends StatelessWidget {
  const DashedDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        80,
        (index) => Expanded(
          child: Container(
            color: index % 2 == 0 ? Colors.transparent : Colors.grey[300],
            height: 1.5,
          ),
        ),
      ),
    );
  }
}