// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rms_project/cart/cart_provider.dart';

class FoodCardDetailPage extends StatefulWidget {
  final String productId; // The ID of the product to fetch

  const FoodCardDetailPage({super.key, required this.productId});

  @override
  State<FoodCardDetailPage> createState() => _FoodCardDetailPageState();
}

class _FoodCardDetailPageState extends State<FoodCardDetailPage> {
  int quantity = 1;
  Map<String, dynamic>? productData;

  @override
  void initState() {
    super.initState();
    _fetchProductData();
  }

  void _fetchProductData() async {
    try {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('items')
          .doc(widget.productId)
          .get();

      if (snapshot.exists) {
        setState(() {
          productData = snapshot.data() as Map<String, dynamic>;
        });
      }
    } catch (e) {
      print("Error fetching product data: $e");
    }
  }

  void _increaseQuantity() {
    setState(() {
      quantity++;
    });
  }

  void _decreaseQuantity() {
    if (quantity > 1) {
      setState(() {
        quantity--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (productData == null) {
      return Scaffold(
        backgroundColor: Colors.blue,
        appBar: AppBar(
          backgroundColor: Colors.blue,
          title: const Text('Loading...'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Decoding the image if it's base64 encoded
    Uint8List? decodedImage;
    if (productData!['image_base64'] != null) {
      decodedImage = base64Decode(productData!['image_base64']);
    }

    return Scaffold(
      body: Column(
        children: [
          AppBar(
            backgroundColor: Theme.of(context).colorScheme.primary,
            title: const Text(
              'Details',
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            centerTitle: true,
            elevation: 0,
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                    ),
                    child: decodedImage != null
                        ? Image.memory(
                            decodedImage,
                            fit: BoxFit.cover,
                          )
                        : const Center(
                            child: Icon(Icons.image_not_supported,
                                color: Colors.grey)),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      productData!['name'],
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'PKR ${(productData!['price'] * quantity).toStringAsFixed(2)}', // Updated line
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        Card(
                          color: Colors.black,
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove),
                                onPressed: _decreaseQuantity,
                                color: Colors.white,
                              ),
                              Text(
                                '$quantity',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: _increaseQuantity,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      productData!['description'] ??
                          'No description available.',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: ElevatedButton(
                      onPressed: () {
                        // Add to cart using CartProvider
                        final product = {
                          'name': productData!['name'],
                          'price': productData!['price'],
                          'quantity': quantity,
                          'image': productData!['image_base64'],
                        };
                        Provider.of<CartProvider>(context, listen: false)
                            .addToCart(product, context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Add to Cart',
                        style: TextStyle(fontSize: 18,color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
