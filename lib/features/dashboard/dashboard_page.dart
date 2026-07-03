import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../../utils/notification_helper.dart';
import '../keranjang/cart_page.dart';
import '../pesanan/order_page.dart';
import 'views/home_view.dart';
import 'views/barang_view.dart';
import 'views/profile_view.dart';
import 'widgets/barang_dialogs.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int selectedIndex = 0;

  final Set<String> _knownOutOfStock = {};
  final Set<String> _knownLowStock = {};
  bool _isFirstLoad = true;
  StreamSubscription<QuerySnapshot>? _barangSubscription;

  // ==================== CART ====================

  List<Map<String, dynamic>> cart = [];

  void addToCart(String name, int price, int stock) {
    int index = cart.indexWhere(
      (item) => item['name'] == name,
    );

    if (index >= 0) {
      if (cart[index]['qty'] < stock) {
        cart[index]['qty'] += 1;
      } else {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal: Batas stok tercapai! Maksimal: $stock"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    } else {
      cart.add({
        'name': name,
        'price': price,
        'qty': 1,
        'stock': stock,
      });
    }

    setState(() {});

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Color(0xFFDCFCE7),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Color(0xFF15803D),
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "$name berhasil ditambahkan ke keranjang",
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
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFBBF7D0), width: 1.5),
        ),
        elevation: 6,
      ),
    );
  }

  void onAdd(int index) {
    final item = cart[index];
    final int stock = item['stock'] ?? 0;
    if (item['qty'] < stock) {
      cart[index]['qty'] += 1;
      setState(() {});
    } else {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Batas stok tercapai! Maksimal: $stock"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void onRemove(int index) {
    if (cart[index]['qty'] > 1) {
      cart[index]['qty'] -= 1;
    } else {
      cart.removeAt(index);
    }

    setState(() {});
  }

  void onQtyChanged(int index, int newQty) {
    cart[index]['qty'] = newQty;
    setState(() {});
  }

  // ==================== CATEGORY ====================

  List<String> categories = [];

  Future<void> fetchCategories() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('kategori')
        .get();

    setState(() {
      categories = snapshot.docs
          .map((e) => e['name'].toString())
          .toList();
    });
  }

  @override
  void initState() {
    super.initState();
    fetchCategories();
    
    // Request notification permissions
    print("DashboardPage: requesting notification permissions...");
    NotificationHelper().requestPermissions().then((_) {
      print("DashboardPage: permissions request completed.");
    }).catchError((e) {
      print("DashboardPage: permissions request failed: $e");
    });

    // Listen to barang stock changes for local push alerts (out of stock & low stock)
    print("DashboardPage: initializing Firestore barang listener...");
    _barangSubscription = FirebaseFirestore.instance
        .collection('barang')
        .snapshots()
        .listen((snapshot) {
      print("DashboardPage: Firestore barang stream updated with ${snapshot.docs.length} docs.");
      final List<String> currentOutOfStock = [];
      final Map<String, int> currentLowStock = {};
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final name = data['name'] as String? ?? '';
        final stock = data['stock'] as int? ?? 0;
        
        if (name.isNotEmpty) {
          if (stock == 0) {
            currentOutOfStock.add(name);
          } else if (stock <= 10) {
            currentLowStock[name] = stock;
          }
        }
      }

      print("DashboardPage: FirstLoad=$_isFirstLoad, currentOutOfStock=$currentOutOfStock, currentLowStock=${currentLowStock.keys.toList()}");

      if (_isFirstLoad) {
        _knownOutOfStock.addAll(currentOutOfStock);
        _knownLowStock.addAll(currentLowStock.keys);
        _isFirstLoad = false;
        print("DashboardPage: Initial sets populated. OutOfStock=$_knownOutOfStock, LowStock=$_knownLowStock");
      } else {
        // 1. Process Out of Stock items
        for (var name in currentOutOfStock) {
          if (!_knownOutOfStock.contains(name)) {
            print("DashboardPage: Triggering OUT OF STOCK notification for $name");
            NotificationHelper().showNotification(
              "🚨 Stok Habis!",
              "Barang '$name' telah habis stoknya.",
            );
            _knownOutOfStock.add(name);
            _knownLowStock.remove(name);
          }
        }
        
        // 2. Process Low Stock items
        for (var entry in currentLowStock.entries) {
          final name = entry.key;
          final stock = entry.value;
          if (!_knownLowStock.contains(name) && !_knownOutOfStock.contains(name)) {
            print("DashboardPage: Triggering LOW STOCK notification for $name");
            NotificationHelper().showNotification(
              "⚠️ Stok Menipis!",
              "Barang '$name' hampir habis. Sisa stok: $stock.",
            );
            _knownLowStock.add(name);
          }
        }
        
        // Cleanup refilled items
        _knownOutOfStock.removeWhere((name) => !currentOutOfStock.contains(name));
        _knownLowStock.removeWhere((name) => !currentLowStock.containsKey(name));
        print("DashboardPage: Updated sets: OutOfStock=$_knownOutOfStock, LowStock=$_knownLowStock");
      }
    }, onError: (error) {
      print("DashboardPage Firestore Stream Error: $error");
    });
  }

  @override
  void dispose() {
    _barangSubscription?.cancel();
    super.dispose();
  }

  // ==================== BUILD ====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),

      floatingActionButton: selectedIndex == 1
          ? FloatingActionButton(
              onPressed: () => showAddBarangDialog(
                context: context,
                categories: categories,
              ),
              backgroundColor: const Color(0xFFFDBA31),
              foregroundColor: const Color(0xFF1E1E24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
              child: const Icon(Icons.add_rounded),
            )
          : null,

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 15,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: selectedIndex,
          onTap: (i) => setState(() {
            selectedIndex = i;
          }),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFFFFA000),
          unselectedItemColor: const Color(0xFF9CA3AF),
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
          elevation: 0,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: "Beranda",
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2_outlined),
              activeIcon: Icon(Icons.inventory_2_rounded),
              label: "Barang",
            ),
            BottomNavigationBarItem(
              icon: Stack(
                children: [
                  const Icon(Icons.shopping_cart_outlined),
                  if (cart.isNotEmpty)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFFE11D48),
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 14,
                          minHeight: 14,
                        ),
                        child: Text(
                          "${cart.length}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              activeIcon: Stack(
                children: [
                  const Icon(Icons.shopping_cart_rounded),
                  if (cart.isNotEmpty)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFFE11D48),
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 14,
                          minHeight: 14,
                        ),
                        child: Text(
                          "${cart.length}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              label: "Keranjang",
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long_rounded),
              label: "Pesanan",
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: "Profil",
            ),
          ],
        ),
      ),

      body: SafeArea(
        child: selectedIndex == 0
            ? const HomeView()
            : selectedIndex == 1
                ? BarangView(
                    categories: categories,
                    onCategoryAdded: fetchCategories,
                    onAddToCart: addToCart,
                  )
                : selectedIndex == 2
                    ? CartPage(
                        cart: cart,
                        onAdd: onAdd,
                        onRemove: onRemove,
                        onQtyChanged: onQtyChanged,
                      )
                    : selectedIndex == 3
                        ? const PesananPage()
                        : const ProfileView(),
      ),
    );
  }
}