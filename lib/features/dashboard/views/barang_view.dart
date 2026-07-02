import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/add_to_cart_button.dart';
import '../widgets/barang_dialogs.dart';

class BarangView extends StatefulWidget {
  final List<String> categories;
  final VoidCallback onCategoryAdded;
  final Function(String name, int price) onAddToCart;

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
  final int lowStockLimit = 5;

  Widget categoryPill(String categoryName, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedCategoryFilter = categoryName;
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
    Query query = FirebaseFirestore.instance.collection('barang');

    if (selectedCategoryFilter != 'Semua') {
      query = query.where(
        'category',
        isEqualTo: selectedCategoryFilter,
      );
    }

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
        const SizedBox(height: 12),

        // Items List
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: query.snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    "Terjadi kesalahan: ${snapshot.error}",
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              }

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
                );
              }

              final data = List<QueryDocumentSnapshot>.from(snapshot.data!.docs);
              data.sort((a, b) {
                final aData = a.data() as Map<String, dynamic>;
                final bData = b.data() as Map<String, dynamic>;
                final aTime = aData['created_at'] as Timestamp?;
                final bTime = bData['created_at'] as Timestamp?;
                if (aTime == null && bTime == null) return 0;
                if (aTime == null) return 1;
                if (bTime == null) return -1;
                return bTime.compareTo(aTime);
              });

              return ListView.builder(
                physics: const BouncingScrollPhysics(),
                itemCount: data.length,
                itemBuilder: (context, index) {
                  final item = data[index];
                  final docId = item.id;
                  final map = item.data() as Map<String, dynamic>;
                  final name = map['name'] ?? '';
                  final price = map['price'] ?? 0;
                  final stock = map['stock'] ?? 0;
                  final category = map['category'] ?? '-';
                  final isLowStock = stock <= lowStockLimit;

                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: isLowStock ? const Color(0xFFFFF1F2) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isLowStock ? const Color(0xFFFECDD3) : const Color(0xFFE5E7EB).withOpacity(0.5),
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
                              color: isLowStock
                                  ? const Color(0xFFFFE4E6)
                                  : const Color(0xFFFDBA31).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isLowStock ? Icons.warning_amber_rounded : Icons.inventory_2_outlined,
                              color: isLowStock ? const Color(0xFFE11D48) : const Color(0xFFFFA000),
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
                                    color: isLowStock ? const Color(0xFF9F1239) : const Color(0xFF1E1E24),
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 4),
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
                                        color: isLowStock ? const Color(0xFFBE123C) : const Color(0xFF6B7280),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  "Rp $price",
                                  style: TextStyle(
                                    color: isLowStock ? const Color(0xFFBE123C) : const Color(0xFFFFA000),
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
                              // Add to Cart
                              AddToCartButton(
                                onTap: () => widget.onAddToCart(name, price),
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
              );
            },
          ),
        ),
      ],
    );
  }
}
