import 'package:flutter/material.dart';

class AddToCartButton extends StatefulWidget {
  final VoidCallback onTap;
  const AddToCartButton({super.key, required this.onTap});

  @override
  State<AddToCartButton> createState() => _AddToCartButtonState();
}

class _AddToCartButtonState extends State<AddToCartButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _triggerTap() async {
    _controller.forward().then((_) => _controller.reverse());
    setState(() {
      _isSuccess = true;
    });
    widget.onTap();
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() {
        _isSuccess = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTap: _triggerTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _isSuccess 
                ? const Color(0xFFDCFCE7) 
                : const Color(0xFFFDBA31).withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
            child: _isSuccess
                ? const Icon(
                    Icons.check_rounded,
                    key: ValueKey('check'),
                    size: 16,
                    color: Color(0xFF15803D),
                  )
                : const Icon(
                    Icons.add_shopping_cart_rounded,
                    key: ValueKey('cart'),
                    size: 16,
                    color: Color(0xFFFFA000),
                  ),
          ),
        ),
      ),
    );
  }
}
