import 'package:flutter/material.dart';
import 'package:rms_project/admin_panel/order_management/completed_orders_screen.dart';
import 'package:rms_project/admin_panel/order_management/pending_orders_screen.dart';
import 'package:rms_project/admin_panel/order_management/preparing_orders_screen.dart';

class ManageOrdersPage extends StatelessWidget {
  ManageOrdersPage({super.key});
  final buttonStyle = ElevatedButton.styleFrom(
    textStyle: const TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 20,
    ),
    backgroundColor: Colors.white,
    foregroundColor: Colors.black,
    minimumSize: const Size(300, 50),
  );
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Manage Orders'),
          centerTitle: true,
          titleTextStyle: const TextStyle(
            fontSize: 35,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
          backgroundColor: Colors.green,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () => Navigator.push(context,MaterialPageRoute(builder: (context) => PendingOrdersScreen())),
                style: buttonStyle,
                child: const Text('Pending Orders'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.push(context,MaterialPageRoute(builder: (context)=> const PreparingOrdersScreen())),
                style: buttonStyle,
                child: const Text('Preparing Orders'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.push(context,MaterialPageRoute(builder: (context)=> CompletedOrdersScreen())),
                style: buttonStyle,
                child: const Text('Completed Orders'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
