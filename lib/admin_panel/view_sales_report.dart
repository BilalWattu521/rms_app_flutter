// ignore_for_file: avoid_types_as_parameter_names

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ViewSalesReport extends StatefulWidget {
  @override
  State<ViewSalesReport> createState() => _ViewSalesReportState();
   const ViewSalesReport({super.key});
}

class _ViewSalesReportState extends State<ViewSalesReport> {
  DateTime? selectedDate;
  final CollectionReference ordersCollection =
      FirebaseFirestore.instance.collection('orders');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sales Report"),
      ),
      body: Column(
        children: [
          // Date selection row
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  selectedDate == null
                      ? "Select a date"
                      : DateFormat('dd-MM-yyyy').format(selectedDate!),
                  style: const TextStyle(fontSize: 18),
                ),
                ElevatedButton(
                  onPressed: () => _selectDate(context),
                  child: const Text("Select Date"),
                ),
              ],
            ),
          ),
          // Display total price and orders
          if (selectedDate != null) ...[
            FutureBuilder<List<Order>>(
              future: _fetchCompletedOrders(selectedDate!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final orders = snapshot.data ?? [];
                double totalPrice = orders.fold(0, (sum, order) => sum + order.totalPrice);

                return Expanded(
                  child: Column(
                    children: [
                      Text(
                        'Total Sales: ${totalPrice.toStringAsFixed(2)} PKR',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView.builder(
                          itemCount: orders.length,
                          itemBuilder: (context, index) {
                            final order = orders[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Order ID: ${order.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    Text('Table Number: ${order.tableNumber}'),
                                    Text('Payment Method: ${order.paymentMethod}'),
                                    Text('Total: ${order.totalPrice.toStringAsFixed(2)} PKR'),
                                    Text('Order Date: ${DateFormat('dd-MM-yyyy').format(order.timestamp)}'),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<List<Order>> _fetchCompletedOrders(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final QuerySnapshot snapshot = await ordersCollection
        .where('status', isEqualTo: 'completed')
        .where('timestamp', isGreaterThan: startOfDay)
        .where('timestamp', isLessThan: endOfDay)
        .get();

    return snapshot.docs.map((doc) {
      return Order(
        id: doc.id,
        tableNumber: doc['tableNumber'],
        paymentMethod: doc['paymentMethod'],
        totalPrice: _parseTotalPrice(doc['totalPrice']),
        timestamp: (doc['timestamp'] as Timestamp).toDate(),
      );
    }).toList();
  }

  double _parseTotalPrice(dynamic totalPrice) {
    if (totalPrice is String) {
      return double.tryParse(totalPrice) ?? 0.0; // Fallback to 0.0 if parsing fails
    } else if (totalPrice is num) {
      return totalPrice.toDouble();
    }
    return 0.0; // Default case
  }
}

class Order {
  final String id;
  final String tableNumber;
  final String paymentMethod;
  final double totalPrice;
  final DateTime timestamp;

  Order({
    required this.id,
    required this.tableNumber,
    required this.paymentMethod,
    required this.totalPrice,
    required this.timestamp,
  });
}