import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:xaviers_market/consts/firebase_consts.dart';
import 'package:flutter/material.dart';
import 'package:xaviers_market/customerscreens/CustomerNavbar.dart';
import 'package:xaviers_market/customerscreens/customer_homescreen.dart';
import 'package:xaviers_market/sellerscreens/SellerNavbar.dart';
import 'package:xaviers_market/sellerscreens/home_screen.dart';
import 'package:xaviers_market/sellerscreens/seller_get_started.dart';
import 'package:hive/hive.dart';

class HiveBoxes {
  static Box<String> userBox = Hive.box<String>('userBox');

  Future<void> signIn(String authToken) async {
    HiveBoxes.userBox.put('authToken', authToken);
  }
}

Future<User?> signUpAsSeller(
    String email, String password, String name, String mob) async {
  try {
    UserCredential userCredential = await FirebaseAuth.instance
        .createUserWithEmailAndPassword(email: email, password: password);

    // Add a boolean field to the user's document indicating their role
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userCredential.user!.uid)
        .set({
      'email': email,
      'password': password,
      'name': name,
      'mob': mob,
      'isSeller': true,
      // Other user details
    });

    return userCredential.user;
  } catch (error) {
    print('Error signing up: $error');
    return null;
  }
}

Future<User?> signUpAsCustomer(
    String email, String password, String name, String mob) async {
  try {
    UserCredential userCredential = await FirebaseAuth.instance
        .createUserWithEmailAndPassword(email: email, password: password);

    // Add a boolean field to the user's document indicating their role
    await firestore.collection('users').doc(userCredential.user!.uid).set({
      'email': email,
      'password': password,
      'name': name,
      'mob': mob,
      'isSeller': false,
      // Other user details
    });

    return userCredential.user;
  } catch (error) {
    print('Error signing up: $error');
    return null;
  }
}

Future<void> signInAsSeller(String email, String password, BuildContext context,
    bool rememberMe) async {
  try {
    UserCredential userCredential = await FirebaseAuth.instance
        .signInWithEmailAndPassword(email: email, password: password);

    String? authToken = userCredential.user?.refreshToken;
    if (authToken != null) {
      print('Authentication token: $authToken');
    } else {
      print('Authentication token not found');
    }

    // Retrieve user data from Firestore
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userCredential.user!.uid)
        .get();
    String userId = userDoc.id;

    // Check the boolean field to determine the user's role
    bool isSeller = userDoc.get('isSeller') ?? false;

    if (isSeller) {
      // The user is a seller, proceed with sign-in
      print('User is a seller');
      if (rememberMe == true) {
        await FirebaseMessaging.instance.subscribeToTopic('customers');
        // Open the Hive box to store user data
        var box = await Hive.openBox('userBox');
        box.put('userId', userId);
        box.put('isSignedIn', true);
        box.put('isSeller', true);

        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Success'),
              content: Text("Log In Successful"),
              actions: [
                TextButton(
                  onPressed: () {
                    // Navigate to the seller home screen and pass the document ID
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BottomNavigation(
                            userId), // Pass document ID to SellerHomeScreen
                      ),
                    );
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      } else {
        await FirebaseMessaging.instance.subscribeToTopic('customers');
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Success'),
              content: Text("Log In Successful"),
              actions: [
                TextButton(
                  onPressed: () {
                    // Navigate to the seller home screen and pass the document ID
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BottomNavigation(
                            userId), // Pass document ID to SellerHomeScreen
                      ),
                    );
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      }
    } else {
      // The user is not a seller, sign them out
      await FirebaseAuth.instance.signOut();
      print('User is not a seller. Sign-in denied.');
      throw Exception('User is not a seller. Sign-in denied.');
    }
  } catch (error) {
    print('Error signing in as seller: $error');
    throw Exception('Error signing in as seller: $error');
  }
}

// During user sign-in as customer
Future<void> signInAsCustomer(String email, String password,
    BuildContext context, bool rememberMe) async {
  try {
    UserCredential userCredential = await FirebaseAuth.instance
        .signInWithEmailAndPassword(email: email, password: password);

    // Retrieve user data from Firestore
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userCredential.user!.uid)
        .get();
    String userId = userDoc.id;

    // Check the boolean field to determine the user's role
    bool isSeller = userDoc.get('isSeller') ?? false;

    if (!isSeller) {
      // The user is not a seller, proceed with sign-in
      print('User is a customer');
      if (rememberMe == true) {
        // Open the Hive box to store user data
        var box = await Hive.openBox('userBox');
        box.put('userId', userId);
        box.put('isSignedIn', true);
        box.put('isSeller', false);
        await FirebaseMessaging.instance.subscribeToTopic('customers');

        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Success'),
              content: Text("Log In Successful"),
              actions: [
                TextButton(
                  onPressed: () {
                    // Navigate to the seller home screen and pass the document ID
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => customerBottomNavigation(
                            userId, 0), // Pass document ID to SellerHomeScreen
                      ),
                    );
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      } else {
        await FirebaseMessaging.instance.subscribeToTopic('customers');
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Success'),
              content: Text("Log In Successful"),
              actions: [
                TextButton(
                  onPressed: () {
                    // Navigate to the seller home screen and pass the document ID
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => customerBottomNavigation(
                            userId, 0), // Pass document ID to SellerHomeScreen
                      ),
                    );
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      }
    } else {
      // The user is a seller, sign them out
      await FirebaseAuth.instance.signOut();
      print('User is a seller. Customer sign-in only.');
      throw Exception('User is a seller. Customer sign-in only.');
    }
  } catch (error) {
    print('Error signing in as customer: $error');
    throw Exception('Error signing in: $error');
  }
}
