import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rms_project/authentication/sign_in_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar:AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: const Text('Profile', style: TextStyle(color: Colors.white, fontSize: 35)),
        centerTitle: true,
      ),
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
      
          final user = snapshot.data;
      
          return Center(
            child: user == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'You are not logged in.',
                        style: TextStyle(fontSize: 20,color: Colors.black),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          // Navigate to SignInPage
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const SignInPage()),
                          );
                        },
                        child: const Text('Login'),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Logged in as:',
                        style: TextStyle(fontSize: 20,color: Colors.black),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        user.email ?? 'No email found',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold,color: Colors.black),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () async {
                          await FirebaseAuth.instance.signOut();
                        },
                        child: const Text('Logout'),
                      ),
                    ],
                  ),
          );
        },
      ),
    );
  }
}