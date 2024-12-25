// PendingOrdersScreen.dart
// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class PendingOrdersScreen extends StatelessWidget {
  final CollectionReference ordersCollection =
      FirebaseFirestore.instance.collection('orders');

      PendingOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pending Orders"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: ordersCollection.where('status', isEqualTo: 'pending').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final orders = snapshot.data!.docs;

          if (orders.isEmpty) {
            return const Center(child: Text("No pending orders found."));
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
              final totalPrice = double.tryParse(order['totalPrice'].toString()) ?? 0.0;

              // Ensure timestamp exists and is not null
              final timeStamp = (order['timestamp'] != null && order['timestamp'] is Timestamp)
                  ? (order['timestamp'] as Timestamp).toDate()
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
                      Text('Order Date: $formattedDate at $formattedTime'),
                      Text('Table Number: ${order['tableNumber']}'),
                      Text('Payment Method: ${order['paymentMethod']}'),
                      Text('Total: ${totalPrice.toStringAsFixed(2)} PKR'),
                      const SizedBox(height: 8),
                      const Text('Ordered Items:', style: TextStyle(fontWeight: FontWeight.bold)),
                      ...items.map((item) {
                        return Text('${item['name']} (Qty: ${item['quantity']})');
                      }),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        child: const Text("Confirm"),
                        onPressed: () {
                          _showPreparationTimeDialog(context, order.id);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showPreparationTimeDialog(BuildContext context, String orderId) {
    final TextEditingController timeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Preparation Time"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Enter preparation time in minutes:"),
              TextField(
                controller: timeController,
                decoration: const InputDecoration(hintText: "e.g. 30 minutes"),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                final preparationTime = int.tryParse(timeController.text);
                if (preparationTime != null) {
                  _updateOrderStatus(orderId, 'preparing', preparationTime);
                  Navigator.of(context).pop();
                }
              },
              child: const Text("Confirm"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateOrderStatus(String orderId, String newStatus, int preparationTime) async {
    final preparationEndTime = DateTime.now().add(Duration(minutes: preparationTime));

    try {
      await ordersCollection.doc(orderId).update({
        'status': newStatus,
        'preparationEndTime': preparationEndTime,
        'preparationTime': preparationTime,
      });
    } catch (e) {
      print('Error updating order status: $e');
    }
  }
}

