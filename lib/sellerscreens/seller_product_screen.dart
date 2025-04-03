import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:xaviers_market/sellerscreens/seller_edit_stall.dart';
import 'package:xaviers_market/sellerscreens/seller_productdetails.dart';
import 'package:xaviers_market/sellerscreens/seller_stalls_screen.dart';
import 'package:xaviers_market/sellerscreens/add_product.dart';
import 'package:xaviers_market/sellerscreens/register_stall.dart';

class SellerProductsScreen extends StatefulWidget {
  final String userId;
  final String stallId;
  List<DocumentSnapshot<Object?>>? productsList;
  List<DocumentSnapshot<Object?>>? imagesList;

  SellerProductsScreen(this.userId, this.stallId);

  @override
  State<SellerProductsScreen> createState() => _SellerProductsScreenState();
}

class _SellerProductsScreenState extends State<SellerProductsScreen> {
  List<DocumentSnapshot<Object?>>? productsList;
  List<DocumentSnapshot<Object?>>? imagesList;
  bool _isLoading = false;
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primaryColor: Colors.purple,
        scaffoldBackgroundColor: const Color.fromARGB(255, 63, 5, 73),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color.fromARGB(0, 255, 255, 255),
          elevation: 0,
        ),
      ),
      home: AbsorbPointer(
        absorbing: _isLoading,
        child: Stack(
          children: [
            Scaffold(
              backgroundColor: const Color.fromARGB(255, 242, 233, 226),
              appBar: AppBar(
                backgroundColor: const Color.fromARGB(255, 242, 233, 226),
                leading: BackButton(
                  color: const Color.fromARGB(255, 126, 70, 62),
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => StallsScreen(widget.userId)));
                  },
                ),
                title: const Text(
                  'Products',
                  style: TextStyle(
                      color: Color.fromARGB(255, 126, 70, 62),
                      fontWeight: FontWeight.bold),
                ),
              ),
              body: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20), // Add space from the top
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                AddProduct(widget.userId, widget.stallId),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white, backgroundColor: Colors.brown, // Change text color here
                        padding: const EdgeInsets.symmetric(
                            horizontal: 60,
                            vertical: 16), // Adjust button size here
                      ),
                      child: const Text(
                        'Add Products +',
                        style: TextStyle(fontSize: 18), // Change text size here
                      ),
                    ),
                    const SizedBox(height: 50), // Add space after the button
                    FutureBuilder<QuerySnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('stalls')
                          .doc(widget.stallId)
                          .collection('products')
                          .get(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return CircularProgressIndicator();
                        }

                        List<DocumentSnapshot> products = snapshot.data!.docs;
                        widget.productsList = products;

                        return GridView.builder(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 10.0,
                            mainAxisSpacing: 25.0,
                          ),
                          itemCount: products.length,
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemBuilder: (context, index) {
                            DocumentSnapshot product = products[index];
                            String productName = product.get('name');
                            String productId = product.id;

                            return FutureBuilder<QuerySnapshot>(
                              future: FirebaseFirestore.instance
                                  .collection('stalls')
                                  .doc(widget.stallId)
                                  .collection('products')
                                  .doc(productId)
                                  .collection('images')
                                  .get(),
                              builder: (context, imagesSnapshot) {
                                if (imagesSnapshot.connectionState ==
                                        ConnectionState.waiting ||
                                    imagesSnapshot.data == null ||
                                    imagesSnapshot.data!.docs.isEmpty) {
                                  return CircularProgressIndicator();
                                } else {
                                  List<DocumentSnapshot> images =
                                      imagesSnapshot.data!.docs;
                                  String imageUrl = images.first.get('url');

                                  return GestureDetector(
                                    onTap: () {
                                      //Navigate to ProductDetailsScreen when tapped
                                      // Navigator.push(
                                      //   context,
                                      //   MaterialPageRoute(
                                      //     builder: (context) => SellerProductDetailsScreen(
                                      //       userId,
                                      //       stallId,
                                      //       productId,
                                      //     ),
                                      //   ),
                                      // );
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              SellerProductDetailsScreen(
                                            widget.userId,
                                            widget.stallId,
                                            productId,
                                          ),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 5.0),
                                            child: Container(
                                              width: double.infinity,
                                              height: MediaQuery.of(context).size.height/5.3,
                                              decoration: BoxDecoration(
                                                image: DecorationImage(
                                                  image: NetworkImage(imageUrl),
                                                  fit: BoxFit.cover,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(10.0),
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
                        );
                      },
                    ),
                    SizedBox(height: 50),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditStall(widget.userId, widget.stallId),
                          ),
                        );
                      }, 
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white, backgroundColor: Colors.brown, // Change text color here
                        padding: const EdgeInsets.symmetric(
                            horizontal: 30,
                            vertical: 12), // Adjust button size here
                      ),
                      child: const Text(
                        'Edit Stall Details',
                        style: TextStyle(fontSize: 16), // Change text size here
                      ),
                    ),
                    SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () async {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text('Delete Stall'),
                              content: Text(
                                  'Are you sure you want to delete this stall?'),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                    // Close the dialog
                                  },
                                  child: Text('No'),
                                ),
                                TextButton(
                                  onPressed: () async {
                                     // Close the dialog
                                    setState(() {
                                      _isLoading = true;
                                    });
                                    try {
                                      if (productsList != null &&
                                          imagesList != null) {
                                        for (var product in productsList!) {
                                          var productId = product.id;
                                          for (var image in imagesList!) {
                                            var imageId = image.id;
                                            await FirebaseFirestore.instance
                                                .collection('stalls')
                                                .doc(widget.stallId)
                                                .collection('products')
                                                .doc(productId)
                                                .collection('images')
                                                .doc(imageId)
                                                .delete();
                                          }
                                        }
                                      }

                                      if (productsList != null) {
                                        for (var product in productsList!) {
                                          var productId = product.id;
                                          await FirebaseFirestore.instance
                                              .collection('stalls')
                                              .doc(widget.stallId)
                                              .collection('products')
                                              .doc(productId)
                                              .delete();
                                        }
                                      }

                                      await FirebaseFirestore.instance
                                          .collection('stalls')
                                          .doc(widget.stallId)
                                          .delete();

                                      setState(() {
                                      _isLoading = false;
                                    });
                                      // Navigate to the desired screen
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  StallsScreen(widget.userId)));
                                    } catch (e) {
                                      print('Error deleting stall: $e');
                                      // Handle the error, e.g., show a snackbar or dialog
                                    }
                                    
                                  },
                                  child: Text('Yes'),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white, backgroundColor: Colors.brown, // Change text color here
                        padding: const EdgeInsets.symmetric(
                            horizontal: 30,
                            vertical: 12), // Adjust button size here
                      ),
                      child: const Text(
                        'Delete this Stall',
                        style: TextStyle(fontSize: 16), // Change text size here
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_isLoading)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
