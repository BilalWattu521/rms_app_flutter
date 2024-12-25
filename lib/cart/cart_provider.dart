// ignore_for_file: avoid_print, use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rms_project/authentication/sign_in_page.dart';

class CartProvider with ChangeNotifier {
  List<Map<String, dynamic>> _cartItems = [];
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Map<String, dynamic>> get cartItems => _cartItems;

  // Load cart from Firebase Firestore
  Future<void> loadCart() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('cart')
            .get();

        _cartItems = snapshot.docs.map((doc) {
          var data = doc.data();
          return {
            'id': doc.id,
            'name': data['name'],
            'price': data['price'],
            'quantity': data['quantity'],
            'image': data.containsKey('image') ? data['image'] : '',
          };
        }).toList();

        notifyListeners();
      } catch (e) {
        print('Error loading cart: $e');
      }
    }
  }

  // Add item to cart and save to Firebase Firestore
  Future<void> addToCart(
      Map<String, dynamic> product, BuildContext context) async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final docRef = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('cart')
            .add({
          'name': product['name'],
          'price': product['price'],
          'quantity': product['quantity'],
          'image': product['image'],
        });

        product['id'] = docRef.id; // Add ID to the product
        _cartItems.add(product);
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Added to cart!')),
        );
        notifyListeners();
        
      } catch (e) {
        print('Error adding to cart: $e');
      }
    } else {
      // Show an alert dialog if the user is not authenticated
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Login Required'),
            content: const Text('Please log in to add items to your cart.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SignInPage()),
                  ); // Navigate to SignInPage
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  // Remove item from cart
  Future<void> removeFromCart(int index) async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final cartItem = _cartItems[index];
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('cart')
            .doc(cartItem['id'])
            .delete();

        _cartItems.removeAt(index);
        notifyListeners();
      } catch (e) {
        print('Error removing from cart: $e');
      }
    }
  }

  // Increase item quantity
  Future<void> increaseQuantity(int index) async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final cartItem = _cartItems[index];
        final newQuantity = cartItem['quantity'] + 1;

        // Update Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('cart')
            .doc(cartItem['id'])
            .update({'quantity': newQuantity});

        _cartItems[index]['quantity'] = newQuantity;

        // Notify only the specific widget
        _notifyItemChange(index);
      } catch (e) {
        print('Error increasing quantity: $e');
      }
    }
  }

  // Decrease item quantity
  Future<void> decreaseQuantity(int index) async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final cartItem = _cartItems[index];
        final newQuantity =
            cartItem['quantity'] > 1 ? cartItem['quantity'] - 1 : 1;

        // Update Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('cart')
            .doc(cartItem['id'])
            .update({'quantity': newQuantity});

        _cartItems[index]['quantity'] = newQuantity;

        // Notify only the specific widget
        _notifyItemChange(index);
      } catch (e) {
        print('Error decreasing quantity: $e');
      }
    }
  }

  // Get total price
  double get totalPrice {
    return _cartItems.fold(
        0.0, (total, item) => total + item['price'] * item['quantity']);
  }

  // Clear the cart
  Future<void> clearCart() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('cart')
            .get();

        for (var doc in snapshot.docs) {
          await doc.reference.delete();
        }
        _cartItems.clear();
        notifyListeners();
      } catch (e) {
        print('Error clearing cart: $e');
      }
    }
  }

  // Call this method after a successful login
  Future<void> refreshCart() async {
    await loadCart();
  }

  // Notify only the widget associated with the specific item
  void _notifyItemChange(int index) {
    notifyListeners();
  }
}
