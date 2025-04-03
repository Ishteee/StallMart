import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:xaviers_market/consts/consts.dart';
import 'package:xaviers_market/customerscreens/merch_details_screen.dart';
import 'package:xaviers_market/customerscreens/product_details.dart';
import 'package:xaviers_market/sellerscreens/register_stall.dart';
import 'package:xaviers_market/customerscreens/signin_screen.dart';

class MerchProductsScreen extends StatelessWidget {
  final String userId;
  final String merchId;
  final String merchCategoryName;

  MerchProductsScreen(this.userId, this.merchId, this.merchCategoryName);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        theme: ThemeData(
          primaryColor: Colors.purple,
          scaffoldBackgroundColor: Color.fromARGB(255, 242, 233, 226),
          appBarTheme: AppBarTheme(
            backgroundColor: Color.fromARGB(0, 255, 255, 255),
            elevation: 0,
          ),
        ),
        home: Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ),
          body: FutureBuilder<QuerySnapshot>(
            future: FirebaseFirestore.instance
                .collection('merchandise')
                .doc(merchId)
                .collection('products')
                .get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator();
              }
              List<DocumentSnapshot> products = snapshot.data!.docs;

              return ListView(children: [
                Padding(
                  padding: const EdgeInsets.only(top: 30.0, bottom: 50),
                  child: Center(
                    child: Text(
                      merchCategoryName,
                      style: GoogleFonts.raleway(
                        fontSize: 27,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 126, 70, 62),
                      ),
                    ),
                  ),
                ),
                GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10.0,
                    mainAxisSpacing: 25.0,
                  ),
                  itemCount: products.length, // Use the length of products list
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    DocumentSnapshot product = products[index];
                    String productName = product.get('name');
                    String productId = product.id; // Unique product ID

                    return FutureBuilder<QuerySnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('merchandise')
                          .doc(merchId)
                          .collection('products')
                          .doc(productId)
                          .collection('images')
                          .get(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                                ConnectionState.waiting ||
                            snapshot.data == null ||
                            snapshot.data!.docs.isEmpty) {
                          // If the snapshot is still loading or no images found, show a placeholder container
                          return CircularProgressIndicator();
                        } else {
                          // Get the URL of the first image
                          String imageUrl =
                              snapshot.data!.docs.first.get('url');

                          return GestureDetector(
                            onTap: () {
                              //Navigate to ProductDetailsScreen when tapped
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MerchDetailsScreen(
                                      userId, merchId, productId),
                                ),
                              );
                            },
                            child: Container(
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 5.0),
                                    child: Container(
                                      width: double.infinity,
                                      height: MediaQuery.of(context).size.height/5.3,
                                      decoration: BoxDecoration(
                                        image: DecorationImage(
                                          image: NetworkImage(imageUrl),
                                          fit: BoxFit.cover,
                                        ),
                                        borderRadius: BorderRadius.circular(10.0),
                                      ),
                                    ),
                                  ),
                                  Text(
                                    productName,
                                    style: TextStyle(
                                      fontSize: 18.0,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                      },
                    );
                  },
                )
              ]);
            },
          ),
        ));
  }
}
