// ignore_for_file: use_build_context_synchronously, avoid_print

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:async';

class PreparingOrdersScreen extends StatefulWidget {
  const PreparingOrdersScreen({super.key});

  @override
  State<PreparingOrdersScreen> createState() => _PreparingOrdersScreenState();
}

class _PreparingOrdersScreenState extends State<PreparingOrdersScreen> {
  final CollectionReference ordersCollection =
      FirebaseFirestore.instance.collection('orders');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Preparing Orders"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: ordersCollection
            .where('status', isEqualTo: 'preparing')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final orders = snapshot.data!.docs;

          if (orders.isEmpty) {
            return const Center(child: Text("No preparing orders found."));
          }

          // Sort orders by timestamp (oldest first)
          orders.sort((a, b) {
            final timeA = (a['timestamp'] as Timestamp).toDate();
            final timeB = (b['timestamp'] as Timestamp).toDate();
            return timeA.compareTo(timeB); // Ascending order
          });

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              final items = order['items'] as List;
              final endTime =
                  (order['preparationEndTime'] as Timestamp).toDate();

              // Ensure timestamp exists and is not null
              final timeStamp = (order['timestamp'] != null &&
                      order['timestamp'] is Timestamp)
                  ? (order['timestamp'] as Timestamp).toDate()
                  : DateTime.now(); // Fallback to now if null

              final formattedDate = DateFormat('dd-MM-yyyy').format(timeStamp);
              final formattedTime = DateFormat('hh:mm a').format(timeStamp);

              return StreamBuilder<int>(
                stream: _countdownStream(endTime),
                builder: (context, timerSnapshot) {
                  final remainingTime = timerSnapshot.data ?? 0;

                  return Card(
                    margin:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Order ID: ${order.id}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text('Order Date: $formattedDate at $formattedTime'),
                          Text('Table Number: ${order['tableNumber']}'),
                          Text('Payment Method: ${order['paymentMethod']}'),
                          Text('Total: ${order['totalPrice']} PKR'),
                          const SizedBox(height: 8),
                          const Text('Ordered Items:',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          ...items.map((item) {
                            return Text(
                                '${item['name']} (Qty: ${item['quantity']})');
                          }),
                          const SizedBox(height: 8),
                          Text(
                              'Time Remaining: ${remainingTime > 0 ? _formatTime(remainingTime) : "Time Up"}'),
                          ElevatedButton(
                            child: const Text("Deliver"),
                            onPressed: () {
                              _updateOrderStatus(
                                  context, order.id, 'completed');
                            },
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
  }

  Stream<int> _countdownStream(DateTime endTime) async* {
    while (DateTime.now().isBefore(endTime)) {
      final remaining = endTime.difference(DateTime.now()).inSeconds;
      yield remaining;
      await Future.delayed(const Duration(seconds: 1));
    }
    yield 0;
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Future<void> _updateOrderStatus(
      BuildContext context, String orderId, String newStatus) async {
    // Capture the current context to avoid using it after the widget is disposed.
    final currentContext = context;

    try {
      await ordersCollection.doc(orderId).update({
        'status': newStatus,
      });

      // Show SnackBar if the widget is still mounted
      if (mounted) {
        ScaffoldMessenger.of(currentContext).showSnackBar(
          const SnackBar(content: Text('Order status updated to completed!')),
        );
      }
    } catch (e) {
      print('Error updating order status: $e');
      // Show error message only if the widget is still mounted
      if (mounted) {
        ScaffoldMessenger.of(currentContext).showSnackBar(
          const SnackBar(content: Text('Error updating order status.')),
        );
      }
    }
  }
}
