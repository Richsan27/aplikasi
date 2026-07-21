import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../widgets/add_to_cart_button.dart';
import '../widgets/barang_dialogs.dart';

int _parseStock(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

class BarangView extends StatefulWidget {
  final List<String> categories;
  final VoidCallback onCategoryAdded;
  final Function(String name, int price, int stock) onAddToCart;

  const BarangView({
    super.key,
    required this.categories,
    required this.onCategoryAdded,
    required this.onAddToCart,
  });

  @override
  State<BarangView> createState() => _BarangViewState();
}

class _BarangViewState extends State<BarangView> {
  String selectedCategoryFilter = 'Semua';
  final int lowStockLimit = 10;
  int _productsLimit = 10;

  Widget categoryPill(String categoryName, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedCategoryFilter = categoryName;
          _productsLimit = 10; // Reset limit when category changes
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
          categoryName,
          style: TextStyle(
            color: isSelected ? const Color(0xFF1E1E24) : const Color(0xFF4B5563),
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('barang').snapshots(),
      builder: (context, barangSnapshot) {
        if (barangSnapshot.hasError) {
          return Center(
            child: Text(
              "Terjadi kesalahan: ${barangSnapshot.error}",
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        if (!barangSnapshot.hasData && barangSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFFFDBA31),
            ),
          );
        }

        final allBarang = barangSnapshot.data?.docs ?? [];
        
        // Find all out-of-stock items (stock == 0) across the entire inventory
        final outOfStockItems = allBarang.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return _parseStock(data['stock']) == 0;
        }).toList();

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('pesanan').snapshots(),
          builder: (context, pesananSnapshot) {
            final ordersDocs = pesananSnapshot.data?.docs ?? [];

            // 1. Calculate best sellers
            final Map<String, int> productSalesCount = {};
            // 2. Calculate last sold dates
            final Map<String, DateTime> lastSoldDates = {};

            for (var orderDoc in ordersDocs) {
              final orderData = orderDoc.data() as Map<String, dynamic>?;
              if (orderData == null) continue;
              final itemsList = orderData['items'] as List<dynamic>? ?? [];
              
              final timestamp = orderData['created_at'] as Timestamp?;
              final DateTime? orderDate = timestamp?.toDate();

              for (var item in itemsList) {
                final name = item['name'] as String? ?? '';
                final qty = (item['qty'] as num?)?.toInt() ?? 0;
                if (name.isNotEmpty) {
                  productSalesCount[name] = (productSalesCount[name] ?? 0) + qty;
                  if (orderDate != null) {
                    final existing = lastSoldDates[name];
                    if (existing == null || orderDate.isAfter(existing)) {
                      lastSoldDates[name] = orderDate;
                    }
                  }
                }
              }
            }

            // Sort to get top 3 popular items with sales >= 2
            final sortedPopular = productSalesCount.entries
                .where((entry) => entry.value >= 2)
                .toList()
              ..sort((a, b) => b.value.compareTo(a.value));
            final Set<String> popularItems = sortedPopular.take(3).map((e) => e.key).toSet();

            // Filter barang in memory based on selectedCategoryFilter
            final filteredBarang = selectedCategoryFilter == 'Semua'
                ? List<QueryDocumentSnapshot>.from(allBarang)
                : allBarang.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return data['category'] == selectedCategoryFilter;
                  }).toList();

            // Sort filtered barang
            filteredBarang.sort((a, b) {
              final aData = a.data() as Map<String, dynamic>;
              final bData = b.data() as Map<String, dynamic>;
              
              final aStock = _parseStock(aData['stock']);
              final bStock = _parseStock(bData['stock']);
              final aIsOutOfStock = aStock == 0;
              final bIsOutOfStock = bStock == 0;
              
              final aName = aData['name'] as String? ?? '';
              final bName = bData['name'] as String? ?? '';
              final aIsPopular = popularItems.contains(aName);
              final bIsPopular = popularItems.contains(bName);

              // 1. Paling bawah: Barang yang stoknya habis (out of stock)
              if (aIsOutOfStock && !bIsOutOfStock) return 1;
              if (!aIsOutOfStock && bIsOutOfStock) return -1;

              // 2. Paling atas: Barang terlaris
              if (aIsPopular && !bIsPopular) return -1;
              if (!aIsPopular && bIsPopular) return 1;

              // 3. Sisanya diurutkan berdasarkan tanggal masuk terbaru
              final aTime = (aData['tanggal_masuk'] ?? aData['created_at']) as Timestamp?;
              final bTime = (bData['tanggal_masuk'] ?? bData['created_at']) as Timestamp?;
              if (aTime == null && bTime == null) return 0;
              if (aTime == null) return 1;
              if (bTime == null) return -1;
              return bTime.compareTo(aTime);
            });

            return Column(
              children: [
                const SizedBox(height: 12),

                // Beautiful Action Row & Search/Pills
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Daftar Produk",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1E1E24),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => showAddCategoryDialog(
                          context: context,
                          onCategoryAdded: widget.onCategoryAdded,
                        ),
                        icon: const Icon(Icons.add_rounded, size: 18, color: Color(0xFFFFA000)),
                        label: const Text(
                          "Kategori",
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

                // Horizontal Category Pills
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      categoryPill('Semua', selectedCategoryFilter == 'Semua'),
                      ...widget.categories.map((cat) => categoryPill(cat, selectedCategoryFilter == cat)),
                    ],
                  ),
                ),
                
                // OUT OF STOCK TOP BANNER WIDGET
                if (outOfStockItems.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF1F2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFFECDD3),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE11D48).withOpacity(0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFE4E6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.error_outline_rounded,
                            color: Color(0xFFE11D48),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Peringatan: ${outOfStockItems.length} Barang Habis!",
                                style: const TextStyle(
                                  color: Color(0xFF9F1239),
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Produk berikut memerlukan restock segera: " +
                                    outOfStockItems.map((doc) {
                                      final data = doc.data() as Map<String, dynamic>;
                                      return data['name'] ?? '';
                                    }).join(", "),
                                style: const TextStyle(
                                  color: Color(0xFFBE123C),
                                  fontSize: 12,
                                  height: 1.4,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 12),

                // Items List
                Expanded(
                  child: filteredBarang.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.inventory_2_outlined,
                                size: 64,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "Belum ada data barang",
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          itemCount: filteredBarang.length > _productsLimit
                              ? _productsLimit + 1
                              : filteredBarang.length,
                          itemBuilder: (context, index) {
                            if (index == _productsLimit) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 16.0),
                                child: Center(
                                  child: TextButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        _productsLimit += 10;
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

                            final item = filteredBarang[index];
                            final docId = item.id;
                            final map = item.data() as Map<String, dynamic>;
                            final name = map['name'] ?? '';
                            final price = map['price'] ?? 0;
                            final stock = _parseStock(map['stock']);
                            final category = map['category'] ?? '-';
                            
                            final isOutOfStock = stock == 0;
                            final isLowStock = stock <= lowStockLimit;

                            final tanggalMasukRaw = map['tanggal_masuk'] ?? map['created_at'];
                            final DateTime? tanggalMasuk = tanggalMasukRaw != null ? (tanggalMasukRaw as Timestamp).toDate() : null;
                            final tanggalMasukStr = tanggalMasuk != null ? DateFormat('dd MMM yyyy').format(tanggalMasuk) : '-';

                            // 1. Popular check
                            final isPopular = popularItems.contains(name);

                            // 2. Inactive check (> 90 days)
                            final lastSold = lastSoldDates[name];
                            final hasSales = lastSold != null;
                            final isInactive = (hasSales && DateTime.now().difference(lastSold).inDays >= 90) ||
                                (!hasSales && tanggalMasuk != null && DateTime.now().difference(tanggalMasuk).inDays >= 90);

                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              decoration: BoxDecoration(
                                color: isOutOfStock
                                    ? const Color(0xFFFFF1F2)
                                    : isLowStock
                                        ? const Color(0xFFFFFBEB)
                                        : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isOutOfStock
                                      ? const Color(0xFFFECDD3)
                                      : isLowStock
                                          ? const Color(0xFFFDE68A)
                                          : const Color(0xFFE5E7EB).withOpacity(0.5),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.015),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
                                child: Row(
                                  children: [
                                    // Leading avatar icon
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: isOutOfStock
                                            ? const Color(0xFFFFE4E6)
                                            : isLowStock
                                                ? const Color(0xFFFEF3C7)
                                                : const Color(0xFFFDBA31).withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        isOutOfStock
                                            ? Icons.error_outline_rounded
                                            : isLowStock
                                                ? Icons.warning_amber_rounded
                                                : Icons.inventory_2_outlined,
                                        color: isOutOfStock
                                            ? const Color(0xFFE11D48)
                                            : isLowStock
                                                ? const Color(0xFFD97706)
                                                : const Color(0xFFFFA000),
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 14),

                                    // Text Content
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            name,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: isOutOfStock
                                                  ? const Color(0xFF9F1239)
                                                  : isLowStock
                                                      ? const Color(0xFF92400E)
                                                      : const Color(0xFF1E1E24),
                                              fontSize: 15,
                                            ),
                                          ),
                                          
                                          // Status Badges Row
                                          if (isOutOfStock || isInactive || isPopular) ...[
                                            const SizedBox(height: 6),
                                            Wrap(
                                              spacing: 6,
                                              runSpacing: 4,
                                              children: [
                                                if (isOutOfStock)
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFFFEE2E2),
                                                      borderRadius: BorderRadius.circular(6),
                                                      border: Border.all(color: const Color(0xFFFCA5A5)),
                                                    ),
                                                    child: const Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Icon(Icons.error_outline_rounded, color: Color(0xFFE11D48), size: 12),
                                                        SizedBox(width: 4),
                                                        Text(
                                                          "Stok Habis!",
                                                          style: TextStyle(
                                                            fontSize: 10,
                                                            color: Color(0xFF9F1239),
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                if (!isOutOfStock && isInactive)
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFFFEF3C7),
                                                      borderRadius: BorderRadius.circular(6),
                                                      border: Border.all(color: const Color(0xFFFDE68A)),
                                                    ),
                                                    child: const Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 12),
                                                        SizedBox(width: 4),
                                                        Text(
                                                          "Macet > 3 Bln",
                                                          style: TextStyle(
                                                            fontSize: 10,
                                                            color: Color(0xFF92400E),
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                if (isPopular)
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFFECFDF5),
                                                      borderRadius: BorderRadius.circular(6),
                                                      border: Border.all(color: const Color(0xFFA7F3D0)),
                                                    ),
                                                    child: const Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Icon(Icons.local_fire_department_rounded, color: Color(0xFF059669), size: 12),
                                                        SizedBox(width: 4),
                                                        Text(
                                                          "Terlaris",
                                                          style: TextStyle(
                                                            fontSize: 10,
                                                            color: Color(0xFF065F46),
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ],

                                          const SizedBox(height: 6),
                                          Wrap(
                                            crossAxisAlignment: WrapCrossAlignment.center,
                                            spacing: 8,
                                            runSpacing: 4,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFF3F4F6),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  category,
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                    color: Color(0xFF6B7280),
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              Text(
                                                "Stok: $stock",
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: isOutOfStock
                                                      ? const Color(0xFFBE123C)
                                                      : isLowStock
                                                          ? const Color(0xFFD97706)
                                                          : const Color(0xFF6B7280),
                                                ),
                                              ),
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.calendar_today_rounded,
                                                    size: 12,
                                                    color: isOutOfStock
                                                        ? const Color(0xFFE11D48)
                                                        : isLowStock
                                                            ? const Color(0xFFD97706)
                                                            : const Color(0xFF9CA3AF),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    tanggalMasukStr,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.bold,
                                                      color: isOutOfStock
                                                          ? const Color(0xFFBE123C)
                                                          : isLowStock
                                                              ? const Color(0xFFD97706)
                                                              : const Color(0xFF6B7280),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            "Rp $price",
                                            style: TextStyle(
                                              color: isOutOfStock
                                                  ? const Color(0xFFBE123C)
                                                  : isLowStock
                                                      ? const Color(0xFFD97706)
                                                      : const Color(0xFFFFA000),
                                              fontSize: 14,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Action Buttons
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Add to Cart / Disabled Cart
                                        if (!isOutOfStock)
                                          AddToCartButton(
                                            onTap: () => widget.onAddToCart(name, price, stock),
                                          )
                                        else
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: const Icon(
                                              Icons.remove_shopping_cart_rounded,
                                              size: 16,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        const SizedBox(width: 8),
                                        // Edit
                                        GestureDetector(
                                          onTap: () => showEditBarangDialog(
                                            context: context,
                                            docId: docId,
                                            data: map,
                                            categories: widget.categories,
                                          ),
                                          child: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Colors.blue.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: const Icon(
                                              Icons.edit_rounded,
                                              size: 16,
                                              color: Colors.blue,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        // Delete
                                        GestureDetector(
                                          onTap: () => showDeleteConfirmDialog(
                                            context: context,
                                            docId: docId,
                                            name: name,
                                          ),
                                          child: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Colors.red.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: const Icon(
                                              Icons.delete_outline_rounded,
                                              size: 16,
                                              color: Colors.red,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
