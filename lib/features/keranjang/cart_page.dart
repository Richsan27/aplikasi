import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CartPage extends StatefulWidget {
  final List<Map<String, dynamic>> cart;
  final Function(int index) onAdd;
  final Function(int index) onRemove;

  const CartPage({
    super.key,
    required this.cart,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {

  Future<void> checkout(int total) async {

    if (widget.cart.isEmpty) return;

    await FirebaseFirestore.instance
        .collection('pesanan')
        .add({
      'invoice':
          'INV-${DateTime.now().millisecondsSinceEpoch}',
      'total': total,
      'items': widget.cart,
      'created_at': Timestamp.now(),
    });

    widget.cart.clear();

    if (mounted) {
      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Checkout berhasil',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    int total = 0;

    for (var item in widget.cart) {
      total += (item['price'] as int) * (item['qty'] as int);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          
          // Header
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              "Keranjang Belanja",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1E1E24),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          const SizedBox(height: 8),

          // Empty State or List View
          widget.cart.isEmpty
              ? Expanded(
                  child: Center(
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
                            Icons.shopping_cart_outlined,
                            size: 36,
                            color: Color(0xFFFFA000),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          "Keranjangmu Kosong",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E1E24),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          "Tambahkan barang dari menu Barang terlebih dahulu",
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF9CA3AF),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : Expanded(
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: widget.cart.length,
                    itemBuilder: (context, index) {
                      final item = widget.cart[index];
                      final price = item['price'] as int;
                      final qty = item['qty'] as int;
                      final itemTotal = price * qty;

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
                        child: Padding(
                          padding: const EdgeInsets.all(14.0),
                          child: Row(
                            children: [
                              // Small item graphic
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFDBA31).withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.inventory_2_outlined,
                                  color: Color(0xFFFFA000),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 14),

                              // Item Details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['name'],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1E1E24),
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Rp $price x $qty",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[500],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      "Rp $itemTotal",
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFFFFA000),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Quantity Controls Row
                              Row(
                                children: [
                                  // Minus Button
                                  IconButton(
                                    style: IconButton.styleFrom(
                                      backgroundColor: const Color(0xFFF3F4F6),
                                      shape: const CircleBorder(),
                                      padding: const EdgeInsets.all(8),
                                    ),
                                    constraints: const BoxConstraints(),
                                    icon: const Icon(
                                      Icons.remove_rounded,
                                      size: 16,
                                      color: Color(0xFF1E1E24),
                                    ),
                                    onPressed: () => widget.onRemove(index),
                                  ),
                                  
                                  const SizedBox(width: 12),
                                  
                                  Text(
                                    "$qty",
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1E1E24),
                                    ),
                                  ),
                                  
                                  const SizedBox(width: 12),
                                  
                                  // Plus Button
                                  IconButton(
                                    style: IconButton.styleFrom(
                                      backgroundColor: const Color(0xFFFDBA31),
                                      shape: const CircleBorder(),
                                      padding: const EdgeInsets.all(8),
                                    ),
                                    constraints: const BoxConstraints(),
                                    icon: const Icon(
                                      Icons.add_rounded,
                                      size: 16,
                                      color: Color(0xFF1E1E24),
                                    ),
                                    onPressed: () => widget.onAdd(index),
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

          // Bottom Checkout Card
          if (widget.cart.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 15,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Total Belanja",
                          style: TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          "Rp $total",
                          style: const TextStyle(
                            color: Color(0xFF1E1E24),
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    
                    // Checkout Button (Done style with arrow)
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFDBA31),
                          foregroundColor: const Color(0xFF1E1E24),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(26),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () => checkout(total),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            SizedBox(width: 24),
                            Text(
                              "Proses Checkout",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            Icon(Icons.arrow_forward_rounded, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}