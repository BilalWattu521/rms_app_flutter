// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rms_project/cart/cart_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OrderReviewPage extends StatefulWidget {
  const OrderReviewPage({super.key});

  @override
  State<OrderReviewPage> createState() => _OrderReviewPageState();
}

class _OrderReviewPageState extends State<OrderReviewPage> {
  String? selectedPaymentMethod = 'Card'; // Default payment method
  final TextEditingController tableNumberController = TextEditingController();
  final TextEditingController cardNumberController = TextEditingController();
  final TextEditingController expiryDateController = TextEditingController();
  final TextEditingController cvcController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final cartItems = cartProvider.cartItems;
    final totalPrice = cartProvider.totalPrice.toStringAsFixed(2);

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          elevation: 0,
          centerTitle: true,
          title: const Text(
            'Order Review',
            style: TextStyle(color: Colors.white),
          ),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order Items
                Text(
                  'Your Items',
                  style: Theme.of(context).textTheme.titleLarge!.copyWith(
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: cartItems.length,
                  itemBuilder: (context, index) {
                    final item = cartItems[index];
                    return _buildOrderItem(
                      imagePath: item['image'], // Assuming it's a Base64 string
                      title: item['name'],
                      subtitle:
                          'Qty: ${item['quantity']}',
                    );
                  },
                ),
                const SizedBox(height: 24),

                // Table Number Section
                Text(
                  'Table Number',
                  style: Theme.of(context).textTheme.titleLarge!.copyWith(
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: tableNumberController,
                  style: const TextStyle(color: Colors.black),
                  decoration: InputDecoration(
                    hintText: 'Enter your table number',
                    hintStyle: const TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 24),

                // Price Breakdown
                _buildPriceRow('Subtotal', 'PKR $totalPrice', isBold: true),
                const SizedBox(height: 24),

                // Payment Method Section
                Text(
                  'Payment Method',
                  style: Theme.of(context).textTheme.titleLarge!.copyWith(
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedPaymentMethod,
                  dropdownColor: Theme.of(context).colorScheme.surface,
                  items: ['Card', 'Cash']
                      .map((method) => DropdownMenuItem(
                            value: method,
                            child: Text(method,
                                style: const TextStyle(color: Colors.black)),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedPaymentMethod = value;
                    });
                  },
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                  ),
                ),
                const SizedBox(height: 24),

                // Card Information Container
                if (selectedPaymentMethod == 'Card') ...[
                  _buildCardInfoFields(),
                ],

                // Checkout Button
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Handle checkout
                      if (tableNumberController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Please enter table number')),
                        );
                      } else {
                        _placeOrder(cartItems, totalPrice);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Checkout PKR $totalPrice',
                      style: const TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _placeOrder(
      List<Map<String, dynamic>> cartItems, String totalPrice) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final orderData = {
          'userId': user.uid,
          'items': cartItems,
          'totalPrice': totalPrice,
          'paymentMethod': selectedPaymentMethod,
          'cardNumber': selectedPaymentMethod == 'Card'
              ? cardNumberController.text
              : null,
          'expiryDate': selectedPaymentMethod == 'Card'
              ? expiryDateController.text
              : null,
          'cvc': selectedPaymentMethod == 'Card' ? cvcController.text : null,
          'tableNumber': tableNumberController.text,
          'timestamp': FieldValue.serverTimestamp(),
          'status': 'pending', // Set default status to pending
          'discountedPrice':null,
        };

        await FirebaseFirestore.instance.collection('orders').add(orderData);

        // Clear cart after order placement
        // ignore: use_build_context_synchronously
        Provider.of<CartProvider>(context, listen: false).clearCart();

        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order placed successfully!')),
        );

        // Optionally navigate to a confirmation page
        // ignore: use_build_context_synchronously
        Navigator.pop(context);
      } catch (e) {
        print('Error placing order');
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Error placing order. Please try again.')),
        );
      }
    }
  }

  Widget _buildCardInfoFields() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Card Information',
            style: Theme.of(context).textTheme.titleLarge!.copyWith(
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: cardNumberController,
            style: const TextStyle(color: Colors.black),
            decoration: InputDecoration(
              hintText: 'Card Number',
              hintStyle: const TextStyle(color: Colors.grey),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.grey),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _selectExpiryDate(context),
                  child: AbsorbPointer(
                    child: TextField(
                      controller: expiryDateController,
                      style: const TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        hintText: 'MM/YY',
                        hintStyle: const TextStyle(color: Colors.grey),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 16),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16), // Space between fields
              Expanded(
                child: TextField(
                  controller: cvcController,
                  style: const TextStyle(color: Colors.black),
                  decoration: InputDecoration(
                    hintText: 'CVC',
                    hintStyle: const TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Custom method to select expiry date
  Future<void> _selectExpiryDate(BuildContext context) async {
    int selectedMonth = 1; // January
    int selectedYear =
        DateTime.now().year % 100; // Current year (last two digits)

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Select Expiry Date"),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Select Month"),
                  DropdownButton<int>(
                    value: selectedMonth,
                    items: List.generate(12, (index) => index + 1)
                        .map((month) => DropdownMenuItem(
                              value: month,
                              child: Text(month.toString()),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedMonth = value; // Update state in the dialog
                        });
                      }
                    },
                    isExpanded: true,
                  ),
                  const SizedBox(height: 16), // Space between dropdowns
                  const Text("Select Year"),
                  DropdownButton<int>(
                    value: selectedYear,
                    items: List.generate(
                            10, (index) => DateTime.now().year % 100 + index)
                        .map((year) => DropdownMenuItem(
                              value: year,
                              child: Text(year.toString()),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedYear = value; // Update state in the dialog
                        });
                      }
                    },
                    isExpanded: true,
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                String formattedDate =
                    "${selectedMonth.toString().padLeft(2, '0')}/${selectedYear.toString()}";
                expiryDateController.text = formattedDate;
                Navigator.of(context).pop();
              },
              child: const Text("OK"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildOrderItem({
    required String imagePath,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(
                image: MemoryImage(
                  const Base64Decoder().convert(imagePath),
                ),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black),
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.grey),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String price, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: Colors.black,
          ),
        ),
        Text(
          price,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}