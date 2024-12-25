// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'package:intl/intl.dart';

// TimerWidget to handle countdown
class TimerWidget extends StatelessWidget {
  final DateTime preparationEndTime;

  const TimerWidget({super.key, required this.preparationEndTime});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: _countdownStream(preparationEndTime),
      builder: (context, snapshot) {
        final remainingTime = snapshot.data ?? 0;

        if (remainingTime <= 0) {
          return const Text(
            'Time is up!',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
          );
        }

        return Text(
          'Time Remaining: ${_formatTime(remainingTime)}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        );
      },
    );
  }

  Stream<int> _countdownStream(DateTime endTime) async* {
    while (DateTime.now().isBefore(endTime)) {
      final remaining = endTime.difference(DateTime.now()).inSeconds;
      yield remaining;
      await Future.delayed(const Duration(seconds: 1));
    }
    yield 0; // Yield zero when time is up
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}

// Main OrderStatusScreen
class OrderStatusScreen extends StatefulWidget {
  const OrderStatusScreen({super.key});

  @override
  State<OrderStatusScreen> createState() => _OrderStatusScreenState();
}

class _OrderStatusScreenState extends State<OrderStatusScreen> {
  final CollectionReference ordersCollection = FirebaseFirestore.instance.collection('orders');

  Future<void> updateDiscountedPrice(String orderId, double totalPrice, DateTime preparationEndTime) async {
    double discount = 0;

    if (DateTime.now().isAfter(preparationEndTime)) {
      // Calculate discount based on totalPrice
      if (totalPrice >= 1000) {
        if (totalPrice >= 5000) {
          discount = totalPrice * 0.05;
        } else if (totalPrice >= 4000) {
          discount = totalPrice * 0.04;
        } else if (totalPrice >= 3000) {
          discount = totalPrice * 0.03;
        } else if (totalPrice >= 2000) {
          discount = totalPrice * 0.02;
        } else if (totalPrice >= 1000) {
          discount = totalPrice * 0.01;
        }
      }

      // Update the discounted price without changing status
      if (discount > 0) {
        await ordersCollection.doc(orderId).update({
          'discountedPrice': totalPrice - discount,
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, userSnapshot) {
        final user = userSnapshot.data;

        if (user == null) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              title: const Text(
                'My Orders',
                style: TextStyle(color: Colors.white, fontSize: 35),
              ),
              centerTitle: true,
            ),
            body: const Center(child: Text("User not logged in.")),
          );
        }

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Theme.of(context).colorScheme.primary,
            title: const Text(
              'My Orders',
              style: TextStyle(color: Colors.white, fontSize: 35),
            ),
            centerTitle: true,
          ),
          body: StreamBuilder<QuerySnapshot>(
            stream: ordersCollection.where('userId', isEqualTo: user.uid).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final orders = snapshot.data?.docs ?? [];

              if (orders.isEmpty) {
                return const Center(child: Text("No orders found."));
              }

              // Sort orders by timestamp
              orders.sort((a, b) {
                final timeA = (a['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
                final timeB = (b['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
                return timeB.compareTo(timeA); // Descending order
              });

              return ListView.builder(
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index];
                  final items = order['items'] as List;
                  final status = order['status'];
                  final totalPrice = double.tryParse(order['totalPrice'].toString()) ?? 0;

                  DateTime? preparationEndTime; // Declare the variable

                  // Prepare to update the discounted price
                  if (status == 'preparing') {
                    final preparationEndTimeField = order['preparationEndTime'];
                    if (preparationEndTimeField is Timestamp) {
                      preparationEndTime = preparationEndTimeField.toDate(); // Assign the value
                      updateDiscountedPrice(order.id, totalPrice, preparationEndTime);
                    } else {
                      print('Preparation end time is not a valid Timestamp for order ${order.id}');
                    }
                  }

                  // StreamBuilder for each order to listen for updates
                  return StreamBuilder<DocumentSnapshot>(
                    stream: ordersCollection.doc(order.id).snapshots(),
                    builder: (context, orderSnapshot) {
                      if (orderSnapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (orderSnapshot.hasError) {
                        return Center(child: Text('Error: ${orderSnapshot.error}'));
                      }

                      final updatedOrder = orderSnapshot.data;

                      // Get discounted price, default to totalPrice if not available
                      final discountedPrice = (updatedOrder?.data() != null &&
                              (updatedOrder?.data() as Map<String, dynamic>?)?.containsKey('discountedPrice') == true)
                          ? (updatedOrder!['discountedPrice'] ?? totalPrice) // Default to totalPrice if null
                          : totalPrice;

                      // Ensure timestamp exists and is not null
                      final timeStamp = (updatedOrder?['timestamp'] != null && updatedOrder!['timestamp'] is Timestamp)
                          ? (updatedOrder['timestamp'] as Timestamp).toDate()
                          : DateTime.now(); // Fallback to now if null

                      final formattedDate = DateFormat('dd-MM-yyyy').format(timeStamp);
                      final formattedTime = DateFormat('hh:mm a').format(timeStamp);

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Order ID: ${order.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Text('Status: $status'),
                              Text('Table Number: ${order['tableNumber']}'),
                              Text('Payment Method: ${order['paymentMethod']}'),
                              Text('Date of Order: $formattedDate at $formattedTime'),
                              Text('Total: ${totalPrice.toStringAsFixed(2)} PKR'),
                              Text('Discounted Total: ${discountedPrice.toStringAsFixed(2)} PKR'),
                              const SizedBox(height: 8),
                              const Text('Ordered Items:', style: TextStyle(fontWeight: FontWeight.bold)),
                              ...items.map((item) {
                                return Text('${item['name']} (Qty: ${item['quantity']})');
                              }),
                              const SizedBox(height: 8),
                              if (status == 'preparing' && preparationEndTime != null)
                                TimerWidget(
                                  preparationEndTime: preparationEndTime, // Use the defined variable
                                )
                              else if (status == 'pending' || status == 'completed')
                                Text(
                                  'Status: ${status[0].toUpperCase()}${status.substring(1)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}