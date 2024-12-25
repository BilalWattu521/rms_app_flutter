// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

class AddItemPage extends StatefulWidget {
  const AddItemPage({super.key});

  @override
  State<AddItemPage> createState() => _AddItemPageState();
}

class _AddItemPageState extends State<AddItemPage> {
  final _categoryController = TextEditingController();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  File? _image;
  final ImagePicker _picker = ImagePicker();

  String? _selectedCategory; // Track selected category
  List<String> _categories = []; // List to hold categories

  @override
  void initState() {
    super.initState();
    _fetchCategories(); // Fetch categories when the widget is initialized
  }

  // Method to fetch categories from Firestore
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

  // Method to pick an image from the gallery
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  // Method to convert image to base64 and add data to Firestore
  Future<void> _addItemToFirestore() async {
    if ((_selectedCategory == null || _selectedCategory!.isEmpty) ||
        _nameController.text.isEmpty ||
        _priceController.text.isEmpty ||
        _image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields and select an image')),
      );
      return;
    }

    try {
      // Convert the image to a base64 string
      final bytes = await _image!.readAsBytes();
      final base64Image = base64Encode(bytes);

      // Add item data to Firestore with base64 image string
      await FirebaseFirestore.instance.collection('items').add({
        'category': _selectedCategory,
        'name': _nameController.text,
        'price': double.parse(_priceController.text),
        'description': _descriptionController.text,
        'image_base64': base64Image,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item added successfully')),
      );
      _categoryController.clear();
      _nameController.clear();
      _priceController.clear();
      _descriptionController.clear();
      setState(() {
        _image = null;
        _selectedCategory = null; // Clear selected category
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add item: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Add Item Page'),
          centerTitle: true,
          titleTextStyle: const TextStyle(
            fontSize: 35,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
          backgroundColor: Colors.green,
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  hint: const Text('Select Category*'),
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
                  items: [
                    ..._categories.map((category) {
                      return DropdownMenuItem<String>(
                        value: category,
                        child: Text(category),
                      );
                    }),
                    const DropdownMenuItem<String>(
                      value: 'new',
                      child: Text('Create New Category'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value;
                      if (_selectedCategory == 'new') {
                        // Clear the selected category to allow input
                        _categoryController.clear();
                      }
                    });
                  },
                ),
                if (_selectedCategory == 'new')
                  TextField(
                    controller: _categoryController,
                    decoration: const InputDecoration(
                      labelText: 'New Category',
                      hintText: 'Enter new category name',
                    ),
                  ),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name*',
                    hintText: 'Enter name',
                  ),
                ),
                TextField(
                  controller: _priceController,
                  decoration: const InputDecoration(
                    labelText: 'Price*',
                    hintText: 'Enter price',
                  ),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (Optional)',
                    hintText: 'Enter description',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 10),
                IconButton(
                  icon: const Icon(Icons.image),
                  onPressed: _pickImage,
                ),
                if (_image != null)
                  Image.file(
                    _image!,
                    height: 100,
                  ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _addItemToFirestore,
                  child: const Text('Add Item'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}