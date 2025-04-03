import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:dots_indicator/dots_indicator.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phonepe_payment_sdk/phonepe_payment_sdk.dart';
import 'package:xaviers_market/customerscreens/cart.dart';
import 'package:xaviers_market/customerscreens/successPage.dart';
import 'package:http/http.dart' as http;

class ProductDetailsScreen extends StatefulWidget {
  final String userId;
  final String stallId;
  final String productId;

  ProductDetailsScreen(this.userId, this.stallId, this.productId);

  @override
  _ProductDetailsScreenState createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  late PageController _pageController;
  double _currentPage = 0;
  GlobalKey<_QuantitySelectorState> quantitySelectorKey =
      GlobalKey<_QuantitySelectorState>();

  bool _isCheckingOut = false;

  String environmentValue = "SANDBOX";
  String appId = "";
  String merchantId = "PGTESTPAYUAT86";
  bool enableLogging = true;
  String transactionId = DateTime.now().millisecondsSinceEpoch.toString();

  String saltKey = "96434309-7796-489d-8924-ab56988a6076";
  String saltIndex = "1";

  String body = "";
  String callback = "https://webhook.site/14d3b80d-ab28-4c01-afdb-8d84e459eaba";
  String checksum = "";
  String packageName = "";
  String apiEndPoint = "/pg/v1/pay";

  Object? result;

  @override
  void initState() {
    initPayment();
    super.initState();
    _pageController = PageController(
      viewportFraction: 0.1,
    );
  }

  void initPayment() {
    PhonePePaymentSdk.init(environmentValue, appId, merchantId, enableLogging)
        .then((val) => {
              setState(() {
                result = 'PhonePe SDK Initialized - $val';
              })
            })
        .catchError((error) {
      handleError(error);
      return <dynamic>{};
    });
  }

  void handleError(error) {
    result = error;
  }

  void startTransaction(
    String productName,
    int selectedQuantity,
    String stallName,
    String sellerId,
    double totalAmount,
  ) {
    PhonePePaymentSdk.startTransaction(body, callback, checksum, packageName)
        .then((response) => {
              setState(() async {
                if (response != null) {
                  String status = response['status'].toString();
                  String error = response['error'].toString();
                  if (status == 'SUCCESS') {
                    result = "Flow Completed - Status: Success!";

                    await checkStatus(productName, selectedQuantity, stallName, sellerId, totalAmount);
                  } else {
                    result =
                        "Flow Completed - Status: $status and Error: $error";
                  }
                } else {
                  result = "Flow Incomplete";
                }
              })
            })
        .catchError((error) {
      // handleError(error)
      return <dynamic>{};
    });
  }

  checkStatus(
      String productName, int selectedQuantity, String stallName, String sellerId, double totalAmount) async {
    setState(() {
      _isCheckingOut = true;
    });
    String url =
        "https://api-preprod.phonepe.com/apis/pg-sandbox/pg/v1/status/$merchantId/$transactionId";

    String concatString = "/pg/v1/status/$merchantId/$transactionId$saltKey";

    var bytes = utf8.encode(concatString);

    var digest = sha256.convert(bytes).toString();

    String xVerify = "$digest###$saltIndex";

    Map<String, String> headers = {
      "Content-Type": "application/json",
      "X-VERIFY": xVerify,
      "X-MERCHANT-ID": merchantId
    };

    await http.get(Uri.parse(url), headers: headers).then((value) async {
      Map<String, dynamic> res = jsonDecode(value.body);

      if (res["success"] &&
          res["code"] == "PAYMENT_SUCCESS" &&
          res['data']['state'] == "COMPLETED") {
        Fluttertoast.showToast(msg: res["message"]);

        try {
          var productsText = '$productName x $selectedQuantity';
              

          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.userId)
              .collection('orders')
              .add({
            'purchaseTime': DateTime.now().millisecondsSinceEpoch,
            'products': productsText,
            'totalAmount': totalAmount,
            'stallName': stallName,
            'method': 'online'
          });
          print("Order added successfully!");

          await FirebaseFirestore.instance
              .collection('users')
              .doc(sellerId)
              .collection('comp_bookings')
              .add({
            'purchaseTime': DateTime.now().millisecondsSinceEpoch,
            'products': productsText,
            'totalAmount': totalAmount,
            'stallName': stallName,
            'method': 'online'
          });

          

          setState(() {
            _isCheckingOut = false;
          });

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => SuccessPage(
                  widget.userId), // Pass document ID to SellerHomeScreen
            ),
          );
        } catch (e) {}
      } else {
        Fluttertoast.showToast(msg: "Something went wrong!");
      }
    });
  }

  getChecksum(int totalAmount) {
    final reqData = {
      "merchantId": merchantId,
      "merchantTransactionId": transactionId,
      "merchantUserId": "MUID123",
      "amount": totalAmount * 100,
      "callbackUrl": callback,
      "mobileNumber": "9999999999",
      "paymentInstrument": {"type": "PAY_PAGE"}
    };

    String base64body = base64.encode(utf8.encode(json.encode(reqData)));

    checksum =
        '${sha256.convert(utf8.encode(base64body + apiEndPoint + saltKey)).toString()}###$saltIndex';

    return base64body;
  }

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      absorbing: _isCheckingOut,
      child: Stack(
        children: [
          Scaffold(
            appBar: AppBar(
              title: Text('Product Details'),
            ),
            body: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('stalls')
                  .doc(widget.stallId)
                  .collection('products')
                  .doc(widget.productId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                }

                if (!snapshot.hasData) {
                  return Text('No data available');
                }

                var productData = snapshot.data!.data() as Map<String, dynamic>;
                var productName = productData['name'] ??
                    'No Product Name'; // Default if name is not available
                var price = productData['price'] ?? 'Price not Defined';
                var stock = productData['stock'];
                QuantitySelector quantitySelector =
                    QuantitySelector(stock, key: quantitySelectorKey);

                // Assuming 'images' is a subcollection
                var imagesCollection = FirebaseFirestore.instance
                    .collection('stalls')
                    .doc(widget.stallId)
                    .collection('products')
                    .doc(widget.productId)
                    .collection('images')
                    .snapshots();

                return StreamBuilder<QuerySnapshot>(
                  stream: imagesCollection,
                  builder: (context, imagesSnapshot) {
                    if (imagesSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return CircularProgressIndicator();
                    }
                    var imageDocs = imagesSnapshot.data?.docs;

                    if (imageDocs == null || imageDocs.isEmpty) {
                      return Text('No images available');
                    }

                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('stalls')
                          .doc(widget.stallId)
                          .get(),
                      builder: (context, stallSnapshot) {
                        if (stallSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return CircularProgressIndicator();
                        }

                        if (!stallSnapshot.hasData) {
                          return Text('No stall data available');
                        }

                        var stallData =
                            stallSnapshot.data!.data() as Map<String, dynamic>;
                        var stallName = stallData['name'] ??
                            'No Stall Name'; // Default if name is not available
                        var isFnB = stallData['isFnB'];
                        var sellerId =
                            stallData['userId'] ?? 'No User Id Found';

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: MediaQuery.of(context).size.height / 2,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: imageDocs.length,
                                controller: _pageController,
                                itemBuilder: (context, index) {
                                  var imageUrl = imageDocs[index]['url'];
                                  return Container(
                                    height: double.infinity,
                                    width: MediaQuery.of(context).size.width,
                                    child: Image.network(
                                      imageUrl,
                                      fit: BoxFit.cover,
                                    ),
                                  );
                                },
                              ),
                            ),
                            SizedBox(height: 5),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.center, // Center the dots
                              children: [
                                DotsIndicator(
                                  dotsCount: imageDocs.length,
                                  position: _currentPage.toInt(),
                                  decorator: DotsDecorator(
                                    size: const Size.square(8.0),
                                    activeSize: const Size(20.0, 8.0),
                                    color: Colors.black26,
                                    activeColor: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.only(top: 20.0, left: 15),
                              child: RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'Item Name: ',
                                      style: TextStyle(
                                        fontSize: 18.0,
                                        fontWeight: FontWeight.normal,
                                        color: Color.fromARGB(255, 126, 70,
                                            62), // Set the fontWeight to normal for 'Item Name'
                                      ),
                                    ),
                                    TextSpan(
                                      text: productName,
                                      style: TextStyle(
                                        fontSize: 18.0,
                                        fontWeight: FontWeight.bold,
                                        color: Color.fromARGB(255, 126, 70,
                                            62), // Set the fontWeight to bold for the productName
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.only(top: 3.0, left: 15),
                              child: RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'Stall Name: ',
                                      style: TextStyle(
                                        fontSize: 18.0,
                                        fontWeight: FontWeight.normal,
                                        color: Color.fromARGB(255, 126, 70,
                                            62), // Set the fontWeight to normal for 'Stall Name'
                                      ),
                                    ),
                                    TextSpan(
                                      text: stallName,
                                      style: TextStyle(
                                        fontSize: 18.0,
                                        fontWeight: FontWeight.bold,
                                        color: Color.fromARGB(255, 126, 70,
                                            62), // Set the fontWeight to bold for the stallName
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(
                                  top: 3.0, left: 15, bottom: 10),
                              child: RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'Units in Stock: ',
                                      style: TextStyle(
                                        fontSize: 18.0,
                                        fontWeight: FontWeight.normal,
                                        color: Color.fromARGB(255, 126, 70,
                                            62), // Set the fontWeight to normal for 'Stall Name'
                                      ),
                                    ),
                                    TextSpan(
                                      text: stock.toString(),
                                      style: TextStyle(
                                        fontSize: 18.0,
                                        fontWeight: FontWeight.bold,
                                        color: Color.fromARGB(255, 126, 70,
                                            62), // Set the fontWeight to bold for the stallName
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(
                              height: 10,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: 'Price: ',
                                        style: TextStyle(
                                          fontSize: 18.0,
                                          fontWeight: FontWeight.normal,
                                          color: Color.fromARGB(255, 126, 70,
                                              62), // Set the fontWeight to normal for 'Stall Name'
                                        ),
                                      ),
                                      TextSpan(
                                        text: price.toString(),
                                        style: TextStyle(
                                          fontSize: 18.0,
                                          fontWeight: FontWeight.bold,
                                          color: Color.fromARGB(255, 126, 70,
                                              62), // Set the fontWeight to bold for the stallName
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                quantitySelector,
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton(
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title: Text("Cash or Online",
                                              style: GoogleFonts.raleway(
                                                fontSize: 23,
                                                fontWeight: FontWeight.bold,
                                                color: Color.fromARGB(
                                                    255, 128, 69, 60),
                                              )),
                                          content: Text(
                                              "Do you want to proceed with Cash payment or Online payment?",
                                              style: GoogleFonts.raleway(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                color: Color.fromARGB(
                                                    255, 0, 0, 0),
                                              )),
                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.pop(context);

                                                stallData['isFnB'] == false
                                                    ? showDialog(
                                                        context: context,
                                                        builder: (BuildContext
                                                            context) {
                                                          return AlertDialog(
                                                            title: Text(
                                                                "Cash Payment",
                                                                style:
                                                                    GoogleFonts
                                                                        .raleway(
                                                                  fontSize: 23,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  color: Color
                                                                      .fromARGB(
                                                                          255,
                                                                          128,
                                                                          69,
                                                                          60),
                                                                )),
                                                            content: Text(
                                                                "Cash Payment must be done to the stall owner directly within 15 minutes. In case of non-payment, booking will get cancelled. Are you sure that you want to proceed?",
                                                                style:
                                                                    GoogleFonts
                                                                        .raleway(
                                                                  fontSize: 15,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  color: Color
                                                                      .fromARGB(
                                                                          255,
                                                                          0,
                                                                          0,
                                                                          0),
                                                                )),
                                                            actions: [
                                                              TextButton(
                                                                onPressed: () {
                                                                  Navigator.pop(
                                                                      context);
                                                                },
                                                                child: Text(
                                                                    "No",
                                                                    style: GoogleFonts
                                                                        .raleway(
                                                                      fontSize:
                                                                          15,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                      color: Color
                                                                          .fromARGB(
                                                                              255,
                                                                              0,
                                                                              0,
                                                                              0),
                                                                    )),
                                                              ),
                                                              TextButton(
                                                                onPressed: () {
                                                                  Navigator.pop(
                                                                      context); // Close the dialog
                                                                  try {

                                                                    
                                                                    // Fetching the URL of the first image
                                                                    var imageUrl = imageDocs
                                                                            .isNotEmpty
                                                                        ? imageDocs
                                                                            .first['url']
                                                                        : 'No image available';

                                                                    int selectedQuantity =
                                                                        quantitySelectorKey.currentState?.getQuantity() ??
                                                                            1;
                                                                    var bookingTime =
                                                                        DateTime.now()
                                                                            .millisecondsSinceEpoch;
                                                                    var totalAmount =
                                                                        price *
                                                                            selectedQuantity;
                                                                    FirebaseFirestore
                                                                        .instance
                                                                        .collection(
                                                                            'users')
                                                                        .doc(widget
                                                                            .userId)
                                                                        .collection(
                                                                            'carts')
                                                                        .add({
                                                                      'bookNow':
                                                                          true,
                                                                      'isBooked':
                                                                          true,
                                                                      'checkoutTime':
                                                                          bookingTime,
                                                                      'stallName':
                                                                          stallName,
                                                                      'totalAmount':
                                                                          totalAmount,
                                                                      'sellerId':
                                                                          sellerId,
                                                                      'isFnB':
                                                                          stallData[
                                                                              'isFnB']
                                                                    }).then((cartDoc) {
                                                                      cartDoc
                                                                          .collection(
                                                                              'products')
                                                                          .doc(widget
                                                                              .productId)
                                                                          .set({
                                                                        'name':
                                                                            productName,
                                                                        'price':
                                                                            price,
                                                                        'imageUrl':
                                                                            imageUrl,
                                                                        'quantity':
                                                                            selectedQuantity,
                                                                        'stock':
                                                                            stock,
                                                                      });
                                                                      // Set up a timer to update isBooked to false after 15 minutes
                                                                      Timer(
                                                                          Duration(
                                                                              minutes: 15),
                                                                          () async {
                                                                        await cartDoc
                                                                            .update({
                                                                          'isBooked':
                                                                              false
                                                                        });
                                                                        await cartDoc
                                                                            .collection('products')
                                                                            .doc(widget.productId)
                                                                            .delete();
                                                                        await cartDoc
                                                                            .delete();
                                                                      });
                                                                    });

                                                                    

                                                                    Fluttertoast.showToast(msg: "Cash Booking Successful");

                                                                    // Show a success message or navigate to the cart screen
                                                                    ScaffoldMessenger.of(
                                                                            context)
                                                                        .showSnackBar(
                                                                      SnackBar(
                                                                        content:
                                                                            Text('Cash Booking Successful'),
                                                                      ),
                                                                    );
                                                                  } catch (error) {
                                                                    // Handle errors
                                                                    print(
                                                                        'Error booking product: $error');
                                                                  }
                                                                },
                                                                child: Text(
                                                                    "Yes",
                                                                    style: GoogleFonts
                                                                        .raleway(
                                                                      fontSize:
                                                                          15,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                      color: Color
                                                                          .fromARGB(
                                                                              255,
                                                                              0,
                                                                              0,
                                                                              0),
                                                                    )),
                                                              ),
                                                            ],
                                                          );
                                                        },
                                                      )
                                                    : showDialog(
                                                        context: context,
                                                        builder: (BuildContext
                                                            context) {
                                                          return AlertDialog(
                                                            title: Text(
                                                              'Food & Beverages Stall',
                                                              style: GoogleFonts
                                                                  .raleway(
                                                                fontSize: 23,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color: Color
                                                                    .fromARGB(
                                                                        255,
                                                                        128,
                                                                        69,
                                                                        60),
                                                              ),
                                                            ),
                                                            content: Text(
                                                              'Advance Booking without online payment is not allowed in Food & Beverages stalls to avoid losses of stall owners.',
                                                              style: GoogleFonts
                                                                  .raleway(
                                                                fontSize: 15,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color: Color
                                                                    .fromARGB(
                                                                        255,
                                                                        0,
                                                                        0,
                                                                        0),
                                                              ),
                                                            ),
                                                            actions: [
                                                              TextButton(
                                                                onPressed: () {
                                                                  Navigator.of(
                                                                          context)
                                                                      .pop(
                                                                          false); // Close the dialog and return false
                                                                },
                                                                child: Text(
                                                                    'OK',
                                                                    style: GoogleFonts
                                                                        .raleway(
                                                                      fontSize:
                                                                          15,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                      color: Color
                                                                          .fromARGB(
                                                                              255,
                                                                              0,
                                                                              0,
                                                                              0),
                                                                    )),
                                                              ),
                                                            ],
                                                          );
                                                        },
                                                      );
                                              },
                                              child: Text("Cash",
                                                  style: GoogleFonts.raleway(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color.fromARGB(
                                                        255, 0, 0, 0),
                                                  )),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                Navigator.pop(
                                                    context); // Close the dialog
                                                print("BUTTON PRESSED!!!!");
                                                int selectedQuantity =
                                                    quantitySelectorKey
                                                            .currentState
                                                            ?.getQuantity() ??
                                                        1;

                                                double totalAmount =
                                                    price * selectedQuantity;
                                                body = getChecksum(totalAmount.toInt()).toString();
                                                startTransaction(
                                                    productName, selectedQuantity, stallName, sellerId, totalAmount);
                                              },
                                              child: Text("Online",
                                                  style: GoogleFonts.raleway(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color.fromARGB(
                                                        255, 0, 0, 0),
                                                  )),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                  child: Text("Buy Now",
                                      style: TextStyle(color: Colors.white)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        Color.fromARGB(255, 126, 70, 62),
                                    fixedSize: Size(
                                                    MediaQuery.of(context)
                                                            .size
                                                            .width /
                                                        1.1,
                                                    20),
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton(
                                  onPressed: () async {
                                    try {
                                      // Check if the user's cart document exists
                                      var cartDoc = await FirebaseFirestore
                                          .instance
                                          .collection('users')
                                          .doc(widget.userId)
                                          .collection('carts')
                                          .doc(widget.stallId)
                                          .get();

                                      // If the cart document doesn't exist, create a new one
                                      if (!cartDoc.exists) {
                                        await FirebaseFirestore.instance
                                            .collection('users')
                                            .doc(widget.userId)
                                            .collection('carts')
                                            .doc(widget.stallId)
                                            .set({
                                          'bookNow': false,
                                          'isBooked': false,
                                          'checkoutTime': '',
                                          'stallName': stallName,
                                          'totalAmount': '',
                                          'sellerId': sellerId,
                                          'isFnB': isFnB
                                        });
                                      }

                                      // Add the product details to the cart
                                      // Fetching the URL of the first image
                                      var imageUrl = imageDocs.isNotEmpty
                                          ? imageDocs.first['url']
                                          : 'No image available';

                                      int selectedQuantity = quantitySelectorKey
                                              .currentState
                                              ?.getQuantity() ??
                                          1;
                                      await FirebaseFirestore.instance
                                          .collection('users')
                                          .doc(widget.userId)
                                          .collection('carts')
                                          .doc(widget.stallId)
                                          .collection('products')
                                          .doc(widget.productId)
                                          .set({
                                        'name': productName,
                                        'price': price,
                                        'imageUrl':
                                            imageUrl, // Adding imageUrl field with the URL of the first image
                                        'quantity': selectedQuantity,
                                        'stock': stock,
                                      });

                                      // Show a success message or navigate to the cart screen
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content:
                                              Text('Product added to cart'),
                                        ),
                                      );
                                    } catch (error) {
                                      // Handle errors
                                      print(
                                          'Error adding product to cart: $error');
                                    }
                                  },
                                  child: Text("Add to Cart",
                                      style: TextStyle(color: Colors.white)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        Color.fromARGB(255, 126, 70, 62),
                                    fixedSize: Size(
                                                    MediaQuery.of(context)
                                                            .size
                                                            .width /
                                                        1.1,
                                                    20),
                                  ),
                                ),
                              ],
                            )
                          ],
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          if (_isCheckingOut)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}

class QuantitySelector extends StatefulWidget {
  final stock;
  final Key key;

  QuantitySelector(this.stock, {required this.key});

  @override
  _QuantitySelectorState createState() => _QuantitySelectorState();
}

class _QuantitySelectorState extends State<QuantitySelector> {
  var quantity = 1;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          "Quantity",
          style: TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.normal,
            color: Color.fromARGB(255, 126, 70, 62),
          ),
        ),
        IconButton(
          icon: Icon(
            Icons.remove,
            color: Colors.brown,
          ),
          onPressed: () {
            setState(() {
              if (quantity > 1) {
                quantity = quantity - 1;
              }
            });
          },
        ),
        Text(
          quantity.toString(),
          style: const TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 126, 70, 62),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add, color: Colors.brown),
          onPressed: () {
            setState(() {
              if (quantity == widget.stock) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Cannot Book more than Units in Stock'),
                  ),
                );
              } else {
                quantity += 1;
              }
            });
          },
        ),
      ],
    );
  }

  int getQuantity() {
    return quantity;
  }
}
