// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rms_project/cart/cart_provider.dart';
import 'package:rms_project/payment/order_review_page.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  bool isLoading = true; // Track loading state

  @override
  void initState() {
    super.initState();

    // Listen for authentication changes
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        // Only load cart if user logs in
        Provider.of<CartProvider>(context, listen: false).loadCart();
        setState(() {
          isLoading = false; // Stop loading
        });
      } else {
        // User logged out, handle accordingly
        setState(() {
          isLoading = false; // Stop loading
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: const Text('Cart', style: TextStyle(color: Colors.white, fontSize: 35)),
        centerTitle: true,
      ),
      body: Consumer<CartProvider>(
        builder: (context, provider, child) {
          if (isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
      
          final cartItems = provider.cartItems;
          final user = FirebaseAuth.instance.currentUser;
      
          if (user == null) {
            return const Center(child: Text('Please log in to view your cart.', style: TextStyle(color: Colors.black)));
          }
      
          if (cartItems.isEmpty) {
            return const Center(child: Text('Your cart is empty.', style: TextStyle(color: Colors.black)));
          }
      
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: cartItems.length,
                  itemBuilder: (context, index) {
                    return CartItemTile(key: ValueKey(cartItems[index]['id']), index: index);
                  },
                ),
              ),
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(50.0),
                    topRight: Radius.circular(50.0),
                  ),
                ),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Total: PKR ${provider.totalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const OrderReviewPage()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF8A65),
                      ),
                      child: const Text('Proceed to Checkout', style: TextStyle(color: Colors.black)),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class CartItemTile extends StatelessWidget {
  final int index;

  const CartItemTile({required this.index, super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<CartProvider, Map<String, dynamic>>(
      selector: (context, provider) => provider.cartItems[index],
      builder: (context, cartItem, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white),
            ),
            margin: const EdgeInsets.only(bottom: 15),
            child: Row(
              children: [
                Container(
                  width: MediaQuery.of(context).size.width * 0.22,
                  height: 100,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(15)),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: cartItem['image'] != null
                        ? Image.memory(const Base64Decoder().convert(cartItem['image']), fit: BoxFit.cover)
                        : const Icon(Icons.image, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PKR ${(cartItem['price'] * cartItem['quantity']).toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: Colors.white),
                    ),
                    Text(
                      cartItem['name'],
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: Colors.white),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => context.read<CartProvider>().decreaseQuantity(index),
                          icon: const Icon(Icons.remove),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            '${cartItem['quantity']}',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
                          ),
                        ),
                        IconButton(
                          onPressed: () => context.read<CartProvider>().increaseQuantity(index),
                          icon: const Icon(Icons.add),
                        ),
                      ],
                    ),
                  ],
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => context.read<CartProvider>().removeFromCart(index),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}