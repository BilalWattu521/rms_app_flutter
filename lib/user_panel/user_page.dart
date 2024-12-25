import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rms_project/user_panel/food_card_detail_page.dart';

class FoodCard extends StatelessWidget {
  final String name;
  final String imageBase64;
  final double price;

  const FoodCard({
    super.key,
    required this.name,
    required this.imageBase64,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    Uint8List? decodedImage;

    // Decode the base64 image string
    if (imageBase64.isNotEmpty) {
      try {
        decodedImage = base64Decode(imageBase64);
      } catch (e) {
        debugPrint('Error decoding base64 image: $e');
      }
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: decodedImage != null
                ? ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    child: Image.memory(
                      decodedImage,
                      fit: BoxFit.cover,
                    ),
                  )
                : const Icon(
                    Icons.image_not_supported,
                    size: 80,
                    color: Colors.grey,
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 5),
                Text(
                  'Rs ${price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class UserPage extends StatefulWidget {
  const UserPage({super.key});

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  String selectedCategory = '';
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    // Dispose the ScrollController when the widget is removed
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: const Text(
          'Menu',
          style: TextStyle(color: Colors.white, fontSize: 35),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('items').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text('No Items Found'));
            }

            // Group items by category
            final itemsByCategory = <String, List<Map<String, dynamic>>>{};
            final categories = <String>[];

            for (var doc in snapshot.data!.docs) {
              final data = doc.data() as Map<String, dynamic>;
              final category = data['category'] as String? ?? 'Uncategorized';

              itemsByCategory.putIfAbsent(category, () => []);
              itemsByCategory[category]!.add({'id': doc.id, ...data});

              if (!categories.contains(category)) {
                categories.add(category);
              }
            }

            categories.sort();

            if (selectedCategory.isEmpty && categories.isNotEmpty) {
              selectedCategory = categories.first;
            }

            final filteredItems = itemsByCategory[selectedCategory] ?? [];

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  controller: _scrollController, // Attach ScrollController
                  child: Row(
                    children: categories.map((category) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: ChoiceChip(
                          label: Text(
                            category,
                            style: TextStyle(
                              color: selectedCategory == category
                                  ? Colors.white
                                  : Colors.black,
                            ),
                          ),
                          selected: selectedCategory == category,
                          selectedColor: Theme.of(context).colorScheme.primary,
                          backgroundColor: Colors.grey[300],
                          onSelected: (selected) {
                            if (selectedCategory != category) {
                              setState(() {
                                selectedCategory = category;
                              });
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 10),
                // Items Grid
                Expanded(
                  child: filteredItems.isEmpty
                      ? const Center(
                          child: Text(
                            'No items in this category',
                            style: TextStyle(fontSize: 16),
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(8.0),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio: 0.75,
                          ),
                          itemCount: filteredItems.length,
                          itemBuilder: (context, index) {
                            final item = filteredItems[index];
                            return GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FoodCardDetailPage(
                                    productId: item['id'],
                                  ),
                                ),
                              ),
                              child: FoodCard(
                                name: item['name'],
                                imageBase64: item['image_base64'] ?? '',
                                price: (item['price'] as num).toDouble(),
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}




// previous one:
// import 'dart:convert';
// import 'dart:typed_data';
// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:rms_project/user_panel/food_card_detail_page.dart';

// class UserPage extends StatefulWidget {
//   const UserPage({super.key});

//   @override
//   State<UserPage> createState() => _UserPageState();
// }

// class _UserPageState extends State<UserPage> {
//   String selectedCategory = ''; // Stores the currently selected category

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Colors.blue,
//         title: const Text(
//           'Menu',
//           style: TextStyle(color: Colors.white, fontSize: 35),
//         ),
//         centerTitle: true,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(8.0),
//         child: StreamBuilder<QuerySnapshot>(
//           stream:
//               FirebaseFirestore.instance.collection('items').snapshots(),
//           builder: (context, snapshot) {
//             if (snapshot.connectionState == ConnectionState.waiting) {
//               return const Center(child: CircularProgressIndicator());
//             }
      
//             if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//               return const Center(
//                 child: Text(
//                   'No Items Found',
//                   style: TextStyle(color: Colors.black),
//                 ),
//               );
//             }
      
//             // Extract and sort categories alphabetically
//             List<String> categories = [];
//             Map<String, List<Map<String, dynamic>>> itemsByCategory = {};
      
//             for (var doc in snapshot.data!.docs) {
//               var data = doc.data() as Map<String, dynamic>;
//               var category = data['category'] as String?;
//               if (category != null) {
//                 itemsByCategory.putIfAbsent(category, () => []);
//                 itemsByCategory[category]!.add({
//                   'id': doc.id,
//                   ...data,
//                 });
//                 if (!categories.contains(category)) {
//                   categories.add(category);
//                 }
//               }
//             }
      
//             categories.sort(); // Sort categories alphabetically
      
//             // Filter items by selected category
//             List<Map<String, dynamic>> filteredItems = [];
//             if (selectedCategory.isNotEmpty) {
//               filteredItems = itemsByCategory[selectedCategory] ?? [];
//             } else if (categories.isNotEmpty) {
//               selectedCategory = categories[0]; // Default to first category
//               filteredItems = itemsByCategory[selectedCategory] ?? [];
//             }
      
//             return Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // Horizontal Scrollable Chips for Categories
//                 SingleChildScrollView(
//                   scrollDirection: Axis.horizontal,
//                   child: Row(
//                     children: categories.map((category) {
//                       return Padding(
//                         padding: const EdgeInsets.symmetric(horizontal: 4.0),
//                         child: ChoiceChip(
//                           label: Text(
//                             category,
//                             style: TextStyle(
//                               color: selectedCategory == category
//                                   ? Colors.white
//                                   : Colors.black,
//                             ),
//                           ),
//                           selected: selectedCategory == category,
//                           selectedColor: Colors.black,
//                           onSelected: (selected) {
//                             setState(() {
//                               selectedCategory = category;
//                             });
//                           },
//                         ),
//                       );
//                     }).toList(),
//                   ),
//                 ),
//                 const SizedBox(height: 10),
//                 // Items of Selected Category
//                 Expanded(
//                   child: GridView.builder(
//                     gridDelegate:
//                         const SliverGridDelegateWithFixedCrossAxisCount(
//                       crossAxisCount: 2,
//                       childAspectRatio: 0.75,
//                       crossAxisSpacing: 8,
//                       mainAxisSpacing: 8,
//                     ),
//                     itemCount: filteredItems.length,
//                     itemBuilder: (context, index) {
//                       var itemData = filteredItems[index];
//                       return GestureDetector(
//                         onTap: () => Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (context) => FoodCardDetailPage(
//                               productId: itemData['id'],
//                             ),
//                           ),
//                         ),
//                         child: FoodCard(
//                           name: itemData['name'],
//                           imageBase64: itemData['image_base64'],
//                           price: itemData['price'],
//                         ),
//                       );
//                     },
//                   ),
//                 ),
//               ],
//             );
//           },
//         ),
//       ),
//     );
//   }
// }

// class FoodCard extends StatelessWidget {
//   final String name;
//   final String imageBase64;
//   final dynamic price;

//   const FoodCard({
//     super.key,
//     required this.name,
//     required this.imageBase64,
//     required this.price,
//   });

//   @override
//   Widget build(BuildContext context) {
//     Uint8List? decodedImage;
//     if (imageBase64.isNotEmpty) {
//       decodedImage = base64Decode(imageBase64);
//     }

//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.black,
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           decodedImage != null
//               ? Image.memory(decodedImage, height: 80, fit: BoxFit.cover)
//               : const Icon(Icons.image_not_supported, color: Colors.grey),
//           const SizedBox(height: 10),
//           Text(
//             name,
//             style: const TextStyle(
//               fontSize: 16,
//               fontWeight: FontWeight.bold,
//               color: Colors.white,
//             ),
//             maxLines: 1,
//             overflow: TextOverflow.ellipsis,
//           ),
//           const SizedBox(height: 5),
//           Text(
//             'Rs $price',
//             style: const TextStyle(fontSize: 14, color: Colors.green),
//           ),
//         ],
//       ),
//     );
//   }
// }

