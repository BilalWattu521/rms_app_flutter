import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class CompletedOrdersScreen extends StatelessWidget {
  final CollectionReference ordersCollection =
      FirebaseFirestore.instance.collection('orders');

      CompletedOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Completed Orders"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: ordersCollection.where('status', isEqualTo: 'completed').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final orders = snapshot.data!.docs;

          if (orders.isEmpty) {
            return const Center(child: Text("No completed orders found."));
          }

          // Sort orders by timestamp (newest first)
          orders.sort((a, b) {
            final timeA = (a['timestamp'] as Timestamp).toDate();
            final timeB = (b['timestamp'] as Timestamp).toDate();
            return timeB.compareTo(timeA); // Descending order
          });

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              final items = order['items'] as List;
              final completionTime = (order['timestamp'] as Timestamp).toDate(); // Assume 'timestamp' is when the order was completed

              final formattedDate = DateFormat('dd-MM-yyyy').format(completionTime);
              final formattedTime = DateFormat('hh:mm a').format(completionTime);

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Order ID: ${order.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('Table Number: ${order['tableNumber']}'),
                      Text('Payment Method: ${order['paymentMethod']}'),
                      Text('Total: ${order['totalPrice']} PKR'),
                      const SizedBox(height: 8),
                      Text('Completion Date: $formattedDate at $formattedTime', style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      const Text('Ordered Items:', style: TextStyle(fontWeight: FontWeight.bold)),
                      ...items.map((item) {
                        return Text('${item['name']} (Qty: ${item['quantity']})');
                      }),
                      const SizedBox(height: 8),
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
}