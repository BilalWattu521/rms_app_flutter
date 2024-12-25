import 'package:flutter/material.dart';
import 'package:rms_project/admin_panel/menu_management/manage_menu_page.dart';
import 'package:rms_project/admin_panel/order_management/manage_orders_page.dart';
import 'package:rms_project/admin_panel/view_sales_report.dart';


class AdminPage extends StatelessWidget {
  AdminPage({super.key});
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
          title: const Text('Admin Panel'),
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
                onPressed: () => Navigator.push(context,MaterialPageRoute(builder: (context)=> ManageMenuPage())),
                style: buttonStyle,
                child: const Text('Manage Menu'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.push(context,MaterialPageRoute(builder: (context)=> ManageOrdersPage())),
                style: buttonStyle,
                child: const Text('Manage Orders'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.push(context,MaterialPageRoute(builder: (context)=> const ViewSalesReport())),
                style: buttonStyle,
                child: const Text('View Sales Report'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
