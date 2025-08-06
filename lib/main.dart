import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:rms_project/cart/cart_provider.dart';
import 'package:rms_project/cart/cart_page.dart';
import 'package:rms_project/authentication/profile_page.dart';
import 'package:rms_project/user_panel/order_status_screen.dart';
import 'package:rms_project/user_panel/user_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  // Initialize Firebase
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: dotenv.env["APIKey"]!,
      appId: dotenv.env["appId"]!,
      messagingSenderId: dotenv.env["messagingSenderId"]!,
      projectId: dotenv.env["projectId"]!,
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => CartProvider(), // Provide CartProvider
      child: MaterialApp(
        theme: ThemeData.light(useMaterial3: true),
        debugShowCheckedModeBanner: false,
        home: const MainScreen(),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // List of pages for each tab
  final List<Widget> _pages = [
    const UserPage(),
    const CartPage(),
    const OrderStatusScreen(),
    const ProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Load the cart here when the app starts or when the user logs in
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    cartProvider.loadCart(); // Load cart from Firebase

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color.fromARGB(188, 0, 0, 0),
        selectedItemColor: const Color.fromRGBO(136, 127, 252, 1),
        unselectedItemColor: const Color.fromARGB(255, 255, 255, 255),
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Cart',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_restaurant_sharp),
            label: 'My Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
