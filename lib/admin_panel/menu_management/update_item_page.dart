// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert'; // For base64 encoding
import 'dart:typed_data'; // For Uint8List

class UpdateItemPage extends StatefulWidget {
  const UpdateItemPage({super.key});

  @override
  State<UpdateItemPage> createState() => _UpdateItemPageState();
}

class _UpdateItemPageState extends State<UpdateItemPage> {
  String? _selectedCategory;
  String? _selectedItem;
  List<String> _categories = [];
  final Map<String, List<Map<String, dynamic>>> _items = {}; // Store items by category
  String? _imageBase64; // Store the base64 image data

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController(); // Added description controller
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  // Fetch categories from Firestore
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

  // Fetch items based on selected category
  Future<void> _fetchItems(String category) async {
    final itemSnapshot = await FirebaseFirestore.instance
        .collection('items')
        .where('category', isEqualTo: category)
        .get();
    
    setState(() {
      _items[category] = itemSnapshot.docs.map((doc) {
        return {
          'name': doc['name'],
          'price': doc['price'],
          'description': doc['description'], // Fetch description
          'image_base64': doc.data().containsKey('image_base64') ? doc['image_base64'] : '', // Check if 'image_base64' exists
        };
      }).toList();
      _selectedItem = null; // Reset selected item
    });
  }

  // Open dialog to edit the selected item's details
  void _openEditDialog(Map<String, dynamic> item) {
    _nameController.text = item['name'];
    _priceController.text = item['price'].toString();
    _descriptionController.text = item['description'] ?? ''; // Set description
    _imageBase64 = item['image_base64']; // Store current base64 image data

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Item'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: _priceController,
                  decoration: const InputDecoration(labelText: 'Price'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: _descriptionController, // Add description field
                  decoration: const InputDecoration(labelText: 'Description (Optional)'),
                  maxLines: 3, // Allow for multiple lines
                ),
                const SizedBox(height: 10),
                // Display the image if the base64 string is valid
                if (_imageBase64 != null && _imageBase64!.isNotEmpty)
                  Image.memory(
                    base64Decode(_imageBase64!), // Decode base64 to image
                    height: 100,
                    width: 100,
                    fit: BoxFit.cover,
                  ),
                ElevatedButton(
                  onPressed: _pickImage,
                  child: const Text('Pick Image from Gallery'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();  // Close the dialog
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await _updateItem(item['name']);
                Navigator.of(context).pop();  // Close the dialog
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  // Pick an image from the gallery
  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      // Convert image to base64
      final Uint8List imageBytes = await image.readAsBytes();
      setState(() {
        _imageBase64 = base64Encode(imageBytes); // Encode image to base64
      });
    }
  }

  // Update item in Firestore
  Future<void> _updateItem(String oldName) async {
    if (_selectedItem == null || _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both category and item to update')),
      );
      return;
    }

    try {
      final itemSnapshot = await FirebaseFirestore.instance
          .collection('items')
          .where('name', isEqualTo: oldName)
          .where('category', isEqualTo: _selectedCategory!)
          .get();

      for (var doc in itemSnapshot.docs) {
        await doc.reference.update({
          'name': _nameController.text,
          'price': double.tryParse(_priceController.text) ?? 0.0,
          'description': _descriptionController.text, // Update with new description
          'image_base64': _imageBase64, // Update with new base64 image data
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item updated successfully')),
      );

      // Reset input fields and selections
      setState(() {
        _selectedItem = null;
        _selectedCategory = null;
        _items.clear();
        _nameController.clear();
        _priceController.clear();
        _descriptionController.clear(); // Clear description
        _imageBase64 = null; // Clear image base64 data
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update item: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Update Item Page'),
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
                isExpanded: true,  // Make dropdown fill the width
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
                  isExpanded: true,  // Make dropdown fill the width
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
                      value: item['name'],
                      child: Text(item['name']),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedItem = value;
                      // Find the selected item details
                      final selectedItem = _items[_selectedCategory]?.firstWhere((item) => item['name'] == value);
                      if (selectedItem != null) {
                        _openEditDialog(selectedItem);
                      }
                    });
                  },
                ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}