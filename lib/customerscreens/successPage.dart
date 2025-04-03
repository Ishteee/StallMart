import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:xaviers_market/customerscreens/CustomerNavbar.dart';

class SuccessPage extends StatelessWidget {
  final String userId;
  const SuccessPage(this.userId);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Purchase Successful",
      theme: ThemeData(
        primaryColor: Colors.purple,
        scaffoldBackgroundColor: Color.fromARGB(255, 242, 233, 226),
        appBarTheme: AppBarTheme(
          backgroundColor: Color.fromARGB(0, 112, 112, 112),
          elevation: 0,
          iconTheme: IconThemeData(color: Color.fromARGB(255, 126, 70, 62)),
        ),
      ),
      home: Scaffold(
        backgroundColor: const Color.fromARGB(255, 242, 233, 226),
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: Colors.brown,
              size: 25,
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.only(top: 15.0, bottom: 30, left: 15),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 15.0, bottom: 7, left: 10, right: 10),
                child: Text(
                  'Purchase Successful',
                  style: GoogleFonts.raleway(
                    fontSize: 35,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 126, 70, 62),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 10.0, bottom: 7, left: 10, right: 20),
                child: Text(
                  'Thank you for shopping with us on StallMart.\nPlease show your payment reciept from the \"Orders\" section to the stall owner and collect your order.\n\nDhanyawad.',
                  style: GoogleFonts.raleway(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 126, 70, 62),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 10.0, bottom: 7, left: 5, right: 20),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Color.fromARGB(255, 128, 69, 60)),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => customerBottomNavigation(
                            userId,
                            1), // Pass document ID to SellerHomeScreen
                      ),
                    );
                  },
                  child: Text(
                    "Redirect to Orders",
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}