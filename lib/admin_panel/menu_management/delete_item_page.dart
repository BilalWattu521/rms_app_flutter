// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
class DeleteItemPage extends StatefulWidget {
  const DeleteItemPage({super.key});

  @override
  State<DeleteItemPage> createState() => _DeleteItemPageState();
}

class _DeleteItemPageState extends State<DeleteItemPage> {
  String? _selectedCategory;
  String? _selectedItem;
  List<String> _categories = [];
  final Map<String, List<String>> _items = {};
  BuildContext? _dialogContext; // Add a variable to hold context for dialog

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _dialogContext = context; // Save the context for use in dialog
  }

  Future<void> _fetchCategories() async {
    final categorySnapshot = await FirebaseFirestore.instance.collection('items').get();
    final categoriesSet = <String>{};

    for (var doc in categorySnapshot.docs) {
      categoriesSet.add(doc['category']);
    }

    setState(() {
      _categories = categoriesSet.toList();
    });
  }

  Future<void> _fetchItems(String category) async {
    final itemSnapshot = await FirebaseFirestore.instance
        .collection('items')
        .where('category', isEqualTo: category)
        .get();

    setState(() {
      _items[category] = itemSnapshot.docs.map((doc) => doc['name'] as String).toList();
      _selectedItem = null; // Reset selected item
    });
  }

  Future<void> _deleteItem() async {
    if (_selectedItem == null || _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both category and item to delete')),
      );
      return;
    }

    // Show confirmation dialog
    showDialog(
      context: _dialogContext!,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: const Text('Are you sure you want to delete this item?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();  // Close the dialog
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();  // Close the dialog
                try {
                  final itemSnapshot = await FirebaseFirestore.instance
                      .collection('items')
                      .where('name', isEqualTo: _selectedItem)
                      .where('category', isEqualTo: _selectedCategory!)
                      .get();

                  for (var doc in itemSnapshot.docs) {
                    await doc.reference.delete();
                  }

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Item deleted successfully')),
                  );

                  setState(() {
                    _selectedItem = null;
                    _selectedCategory = null; // Clear selected category
                    _items.clear(); // Clear items
                  });
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete item: $e')),
                  );
                }
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Delete Item Page'),
          centerTitle: true,
          backgroundColor: Colors.red,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                hint: const Text('Select Category'),
                value: _selectedCategory,
                isExpanded: true,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: Theme.of(context).brightness == Brightness.dark 
                      ? Colors.grey[800] 
                      : Colors.grey[200],
                  contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                    if (value != null) {
                      _fetchItems(value); // Fetch items for the selected category
                    }
                  });
                },
              ),
              const SizedBox(height: 16),
              if (_selectedCategory != null)
                DropdownButtonFormField<String>(
                  hint: const Text('Select Item'),
                  value: _selectedItem,
                  isExpanded: true,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: Theme.of(context).brightness == Brightness.dark 
                        ? Colors.grey[800] 
                        : Colors.grey[200],
                    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  ),
                  items: _items[_selectedCategory]?.map((item) {
                    return DropdownMenuItem<String>(
                      value: item,
                      child: Text(item),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedItem = value;
                    });
                  },
                ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _deleteItem,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Delete Item'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}