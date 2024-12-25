import 'package:flutter/material.dart';
import 'package:rms_project/admin_panel/menu_management/add_item_page.dart';
import 'package:rms_project/admin_panel/menu_management/delete_item_page.dart';
import 'package:rms_project/admin_panel/menu_management/update_item_page.dart';
import 'package:rms_project/user_panel/user_page.dart';

class ManageMenuPage extends StatelessWidget {
  ManageMenuPage({super.key});
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
          title: const Text('Manage Menu'),
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
                onPressed: () => Navigator.push(context,MaterialPageRoute(builder: (context) => const AddItemPage())),
                style: buttonStyle,
                child: const Text('Add New Item'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.push(context,MaterialPageRoute(builder: (context)=> const UpdateItemPage())),
                style: buttonStyle,
                child: const Text('Update Existing Item'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.push(context,MaterialPageRoute(builder: (context)=> const DeleteItemPage())),
                style: buttonStyle,
                child: const Text('Delete an Item'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.push(context,MaterialPageRoute(builder: (context)=> const UserPage())),
                style: buttonStyle,
                child: const Text('View Menu'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
