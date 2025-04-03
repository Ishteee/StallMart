import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:phonepe_payment_sdk/phonepe_payment_sdk.dart';
import 'package:xaviers_market/customerscreens/phonepe.dart';
import 'package:http/http.dart' as http;
import 'package:xaviers_market/customerscreens/successPage.dart';

class Cart extends StatefulWidget {
  final String userId;
  List<QueryDocumentSnapshot<Object?>>? productsList;

  Cart(this.userId);

  @override
  _CartState createState() => _CartState();
}

class _CartState extends State<Cart> {
  bool _isCheckingOut = false;
  Map<String, int> quantities = {};

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
    QueryDocumentSnapshot<Object?> cartDoc,
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

                    await checkStatus(cartDoc, totalAmount);
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
      QueryDocumentSnapshot<Object?> cartDoc, double totalAmount) async {
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
          var productSnapshot = await cartDoc.reference
              .collection('products') // Access the 'products' sub-collection
              .get();

          var products = productSnapshot.docs;

          var productsText = products
              .map((product) => '${product['name']} x ${product['quantity']}')
              .join('\n');

          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.userId)
              .collection('orders')
              .add({
            'purchaseTime': DateTime.now().millisecondsSinceEpoch,
            'products': productsText,
            'totalAmount': totalAmount,
            'stallName': cartDoc['stallName'],
            'method': 'online'
          });
          print("Order added successfully!");

          await FirebaseFirestore.instance
              .collection('users')
              .doc(cartDoc['sellerId'])
              .collection('comp_bookings')
              .add({
            'purchaseTime': DateTime.now().millisecondsSinceEpoch,
            'products': productsText,
            'totalAmount': totalAmount,
            'stallName': cartDoc['stallName'],
            'method': 'online'
          });

          for (var product in products) {
            await product.reference.delete();
          }

          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.userId)
              .collection('carts')
              .doc(cartDoc.id)
              .delete();

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

  Future<void> checkout(
      String stallName,
      double totalAmount,
      List<QueryDocumentSnapshot<Object?>> products,
      QueryDocumentSnapshot<Object?> cartDoc) async {
    setState(() {
      _isCheckingOut = true;
    });

    // Set isBooked to true and store the checkout time in the cartDoc
    var checkoutTime = DateTime.now().millisecondsSinceEpoch;
    await cartDoc.reference.update({
      'isBooked': true,
      'checkoutTime': checkoutTime,
      'stallName': stallName,
      'totalAmount': totalAmount
    });

    for (var product in products) {
      var productId = product.id;
      var quantity = quantities[productId];
      await cartDoc.reference.collection('products').doc(productId).update({
        'quantity': quantity,
      });
    }

    // Retrieve the value of 'userId' from the 'stalls/cartDoc.id' document
    var sellerIdSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('carts')
        .doc(cartDoc.id)
        .get();
    var sellerId = sellerIdSnapshot['sellerId'];

    await FirebaseFirestore.instance
        .collection('users')
        .doc(sellerId)
        .collection('bookings')
        .doc(widget.userId)
        .set({});

    // Start a timer to set isBooked back to false after 15 minutes
    Timer(Duration(minutes: 15), () async {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        var freshCartDoc = await transaction.get(cartDoc.reference);
        if (freshCartDoc.exists) {
          var checkoutTimeInMillis = freshCartDoc['checkoutTime'];
          var fifteenMinutesInMillis = 15 * 60 * 1000;
          var elapsedTimeInMillis =
              DateTime.now().millisecondsSinceEpoch - checkoutTimeInMillis;
          if (elapsedTimeInMillis >= fifteenMinutesInMillis) {
            transaction.update(cartDoc.reference, {
              'isBooked': false,
              'checkoutTime': '',
              'stallName': stallName,
              'totalAmount': ''
            });
          }
        }
      });
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Cash Booking Done'),
      ),
    );

    setState(() {
      _isCheckingOut = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      absorbing: _isCheckingOut,
      child: Stack(
        children: [
          Scaffold(
            backgroundColor: const Color.fromARGB(255, 242, 233, 226),
            appBar: AppBar(
              backgroundColor: const Color.fromARGB(255, 242, 233, 226),
            ),
            body: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: Text(
                    'My Cart',
                    style: GoogleFonts.raleway(
                      fontSize: 27,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 0, 0, 0),
                    ),
                  ),
                ),
                SizedBox(
                  height: 20,
                ),
                Expanded(
                  child: StreamBuilder(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(widget.userId)
                        .collection('carts')
                        .where('bookNow', isEqualTo: false)
                        .snapshots(),
                    builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                      if (!snapshot.hasData) {
                        return Center(
                          child: CircularProgressIndicator(),
                        );
                      } else if (snapshot.data!.docs.isEmpty) {
                        return const Center(
                          child: Text(
                            'Cart is Empty',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      } else {
                        return ListView.builder(
                          itemCount: snapshot.data!.docs.length,
                          itemBuilder: (context, index) {
                            var cartDoc = snapshot.data!.docs[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                vertical: 10,
                                horizontal: 20,
                              ),
                              elevation: 5,
                              color: Color.fromARGB(255, 242, 233, 226),
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text.rich(
                                      TextSpan(
                                        children: [
                                          TextSpan(
                                            text: cartDoc.id ==
                                                    'MERCHaXxrhJ2LZugT6AU'
                                                ? 'Merchandise'
                                                : 'Stall Name: ',
                                            style: GoogleFonts.raleway(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Color.fromARGB(
                                                  255, 128, 69, 60),
                                            ),
                                          ),
                                          TextSpan(
                                            text: cartDoc.id ==
                                                    'MERCHaXxrhJ2LZugT6AU'
                                                ? ''
                                                : cartDoc['stallName'],
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: 10),
                                    FutureBuilder(
                                      future: FirebaseFirestore.instance
                                          .collection('users')
                                          .doc(widget.userId)
                                          .collection('carts')
                                          .doc(cartDoc.id)
                                          .collection('products')
                                          .get(),
                                      builder: (context,
                                          AsyncSnapshot<QuerySnapshot>
                                              productSnapshot) {
                                        if (!productSnapshot.hasData) {
                                          return CircularProgressIndicator();
                                        }
                                        var products =
                                            productSnapshot.data!.docs;
                                        widget.productsList = products;
                                        var totalAmount = 0.0;
                                        var productWidgets = <Widget>[];

                                        for (var product in products) {
                                          var productId = product.id;
                                          var productName = product['name'];
                                          var price = product['price'];
                                          var imageUrl = product['imageUrl'];
                                          var quantity =
                                              quantities[productId] ??
                                                  product['quantity'];
                                          var stock = product['stock'];
                                          totalAmount += price * quantity;
                                          if (quantities[productId] == null) {
                                            quantities[productId] = quantity;
                                          }

                                          productWidgets.add(
                                            Row(
                                              children: [
                                                // Image
                                                Container(
                                                  width: 105,
                                                  height: 130,
                                                  decoration: BoxDecoration(
                                                    image: DecorationImage(
                                                      image: NetworkImage(
                                                        imageUrl,
                                                      ),
                                                      fit: BoxFit.cover,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8.0),
                                                  ),
                                                ),
                                                SizedBox(width: 10),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            'Product Name:',
                                                            style: GoogleFonts
                                                                .raleway(
                                                              fontSize: 17,
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
                                                          Text(
                                                            productName,
                                                            style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize: 17,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      Row(
                                                        children: [
                                                          Text.rich(
                                                            TextSpan(
                                                              children: [
                                                                TextSpan(
                                                                  text:
                                                                      'Price: ',
                                                                  style: GoogleFonts
                                                                      .raleway(
                                                                    fontSize:
                                                                        17,
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
                                                                TextSpan(
                                                                  text:
                                                                      '$price',
                                                                  style:
                                                                      TextStyle(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    fontSize:
                                                                        17,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                          SizedBox(width: 5),
                                                        ],
                                                      ),
                                                      Row(
                                                        children: [
                                                          Text(
                                                            "Quantity",
                                                            style: GoogleFonts
                                                                .raleway(
                                                              fontSize: 16,
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
                                                          IconButton(
                                                            icon: Icon(Icons
                                                                .remove_circle),
                                                            onPressed: () {
                                                              setState(() {
                                                                quantities[
                                                                        productId] =
                                                                    quantity;
                                                                if (quantities[
                                                                            productId] !=
                                                                        null &&
                                                                    quantities[
                                                                            productId]! >
                                                                        1) {
                                                                  quantities[
                                                                          productId] =
                                                                      quantities[
                                                                              productId]! -
                                                                          1;
                                                                }
                                                              });
                                                            },
                                                          ),
                                                          Text(
                                                              quantity
                                                                  .toString(),
                                                              style: TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold)),
                                                          IconButton(
                                                            icon: Icon(Icons
                                                                .add_circle),
                                                            onPressed: () {
                                                              setState(() {
                                                                quantities[
                                                                        productId] =
                                                                    quantity;
                                                                if (quantities[
                                                                        productId]! <
                                                                    stock) {
                                                                  quantities[
                                                                          productId] =
                                                                      (quantities[productId] ??
                                                                              0) +
                                                                          1;
                                                                } else {
                                                                  ScaffoldMessenger.of(
                                                                          context)
                                                                      .showSnackBar(
                                                                    const SnackBar(
                                                                      content: Text(
                                                                          'Quantity cannot be more than Stock'),
                                                                    ),
                                                                  );
                                                                }
                                                              });
                                                            },
                                                          ),
                                                        ],
                                                      ),
                                                      Row(
                                                        children: [
                                                          GestureDetector(
                                                            onTap: () {
                                                              showDialog(
                                                                context:
                                                                    context,
                                                                builder:
                                                                    (BuildContext
                                                                        context) {
                                                                  return AlertDialog(
                                                                    title: Text(
                                                                        "Remove Product", style: GoogleFonts
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
                                                                        "Do you want to remove this product?", style: GoogleFonts
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
                                                                    actions: <Widget>[
                                                                      TextButton(
                                                                        onPressed:
                                                                            () {
                                                                          Navigator.of(context)
                                                                              .pop(false);
                                                                        },
                                                                        child: Text(
                                                                            "No", style: GoogleFonts
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
                                                                        onPressed:
                                                                            () {
                                                                          Navigator.of(context)
                                                                              .pop(true);
                                                                        },
                                                                        child: Text(
                                                                            "Yes", style: GoogleFonts
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
                                                              ).then(
                                                                  (value) async {
                                                                if (value !=
                                                                        null &&
                                                                    value) {
                                                                  // Remove the product
                                                                  FirebaseFirestore
                                                                      .instance
                                                                      .collection(
                                                                          'users')
                                                                      .doc(widget
                                                                          .userId)
                                                                      .collection(
                                                                          'carts')
                                                                      .doc(cartDoc
                                                                          .id)
                                                                      .collection(
                                                                          'products')
                                                                      .doc(
                                                                          productId)
                                                                      .delete();

                                                                  FirebaseFirestore
                                                                      .instance
                                                                      .collection(
                                                                          'users')
                                                                      .doc(widget
                                                                          .userId)
                                                                      .collection(
                                                                          'carts')
                                                                      .doc(cartDoc
                                                                          .id)
                                                                      .collection(
                                                                          'products')
                                                                      .get()
                                                                      .then(
                                                                          (querySnapshot) {
                                                                    if (querySnapshot
                                                                        .docs
                                                                        .isEmpty) {
                                                                      FirebaseFirestore
                                                                          .instance
                                                                          .collection(
                                                                              'users')
                                                                          .doc(widget
                                                                              .userId)
                                                                          .collection(
                                                                              'carts')
                                                                          .doc(cartDoc
                                                                              .id)
                                                                          .delete();
                                                                    }
                                                                  });

                                                                  ScaffoldMessenger.of(
                                                                          context)
                                                                      .showSnackBar(
                                                                    SnackBar(
                                                                      content: Text(
                                                                          'Product Removed from Cart'),
                                                                    ),
                                                                  );
                                                                  setState(
                                                                      () {});
                                                                }
                                                              });
                                                            },
                                                            child: FaIcon(
                                                              FontAwesomeIcons
                                                                  .trash,
                                                              size: 20,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                          productWidgets
                                              .add(SizedBox(height: 10));
                                        }

                                        return Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            ...productWidgets,
                                            Text.rich(
                                              TextSpan(
                                                children: [
                                                  TextSpan(
                                                    text:
                                                        'Total Payable Amount: ',
                                                    style: GoogleFonts.raleway(
                                                      fontSize: 17,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Color.fromARGB(
                                                          255, 128, 69, 60),
                                                    ),
                                                  ),
                                                  TextSpan(
                                                    text: '₹$totalAmount',
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 19,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            SizedBox(height: 10),
                                            cartDoc['isBooked'] == true ? 
                                              Text(
                                                        'Booked',
                                                        style:
                                                            GoogleFonts.raleway(
                                                          fontSize: 22,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Color.fromARGB(
                                                              255, 0, 0, 0),
                                                        ),
                                                      )
                                            : Column(
                                              children: [
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      "Pay via",
                                                      style: GoogleFonts.raleway(
                                                        fontSize: 22,
                                                        fontWeight: FontWeight.bold,
                                                        color: Color.fromARGB(
                                                            255, 128, 69, 60),
                                                      ),
                                                    ),
                                                    SizedBox(
                                                      width: 10,
                                                    ),
                                                    
                                                        ElevatedButton(
                                                            style: ElevatedButton
                                                                .styleFrom(
                                                              backgroundColor:
                                                                  Color.fromARGB(
                                                                      255,
                                                                      128,
                                                                      69,
                                                                      60),
                                                            ),
                                                            onPressed: () {
                                                              if (_isCheckingOut ==
                                                                  null) {
                                                                return null;
                                                              } else if (cartDoc
                                                                      .id ==
                                                                  'MERCHaXxrhJ2LZugT6AU') {
                                                                ScaffoldMessenger
                                                                        .of(context)
                                                                    .showSnackBar(
                                                                  SnackBar(
                                                                    content: Text(
                                                                        'Merchandise booking is under development'),
                                                                  ),
                                                                );
                                                              } else if (cartDoc[
                                                                      'isFnB'] ==
                                                                  true) {
                                                                showDialog(
                                                                  context: context,
                                                                  builder:
                                                                      (BuildContext
                                                                          context) {
                                                                    return AlertDialog(
                                                                      title: Text(
                                                                        'Food & Beverages Stall',
                                                                        style: GoogleFonts
                                                                            .raleway(
                                                                          fontSize:
                                                                              23,
                                                                          fontWeight:
                                                                              FontWeight
                                                                                  .bold,
                                                                          color: Color.fromARGB(
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
                                                                        ),
                                                                      ),
                                                                      actions: [
                                                                        TextButton(
                                                                          onPressed:
                                                                              () {
                                                                            Navigator.of(context)
                                                                                .pop(false); // Close the dialog and return false
                                                                          },
                                                                          child: Text(
                                                                              'OK',
                                                                              style:
                                                                                  GoogleFonts.raleway(
                                                                                fontSize:
                                                                                    15,
                                                                                fontWeight:
                                                                                    FontWeight.bold,
                                                                                color: Color.fromARGB(
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
                                                              } else {
                                                                showDialog(
                                                                  context: context,
                                                                  builder:
                                                                      (BuildContext
                                                                          context) {
                                                                    return AlertDialog(
                                                                      title: Text(
                                                                        'Pay with Cash',
                                                                        style: GoogleFonts
                                                                            .raleway(
                                                                          fontSize:
                                                                              23,
                                                                          fontWeight:
                                                                              FontWeight
                                                                                  .bold,
                                                                          color: Color.fromARGB(
                                                                              255,
                                                                              128,
                                                                              69,
                                                                              60),
                                                                        ),
                                                                      ),
                                                                      content: Text(
                                                                        'Cash Payment must be done to the stall owner directly within 15 minutes. In case of non-payment, booking will get cancelled. Are you sure that you want to proceed?',
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
                                                                        ),
                                                                      ),
                                                                      actions: [
                                                                        TextButton(
                                                                          onPressed:
                                                                              () {
                                                                            Navigator.of(context)
                                                                                .pop(false); // Close the dialog and return false
                                                                          },
                                                                          child: Text(
                                                                              'No',
                                                                              style:
                                                                                  GoogleFonts.raleway(
                                                                                fontSize:
                                                                                    15,
                                                                                fontWeight:
                                                                                    FontWeight.bold,
                                                                                color: Color.fromARGB(
                                                                                    255,
                                                                                    0,
                                                                                    0,
                                                                                    0),
                                                                              )),
                                                                        ),
                                                                        TextButton(
                                                                          onPressed:
                                                                              () {
                                                                            Navigator.of(context)
                                                                                .pop(true); // Close the dialog and return true
                                                                          },
                                                                          child: Text(
                                                                              'Yes',
                                                                              style:
                                                                                  GoogleFonts.raleway(
                                                                                fontSize:
                                                                                    15,
                                                                                fontWeight:
                                                                                    FontWeight.bold,
                                                                                color: Color.fromARGB(
                                                                                    255,
                                                                                    0,
                                                                                    0,
                                                                                    0),
                                                                              )),
                                                                        ),
                                                                      ],
                                                                    );
                                                                  },
                                                                ).then((confirmed) {
                                                                  if (confirmed !=
                                                                          null &&
                                                                      confirmed) {
                                                                    checkout(
                                                                      cartDoc[
                                                                          'stallName'],
                                                                      totalAmount,
                                                                      products,
                                                                      cartDoc,
                                                                    );
                                                                  }
                                                                });
                                                              }
                                                            },
                                                            child: Text(
                                                              'Cash',
                                                              style: TextStyle(
                                                                fontSize: 15,
                                                                color: Colors.white,
                                                              ),
                                                            ),
                                                          ),
                                                    SizedBox(
                                                      width: 8,
                                                    ),
                                                    ElevatedButton(
                                                      style:
                                                          ElevatedButton.styleFrom(
                                                        backgroundColor:
                                                            Color.fromARGB(
                                                                255, 128, 69, 60),
                                                      ),
                                                      onPressed: () {
                                                        showDialog(
                                                          context: context,
                                                          builder: (BuildContext
                                                              context) {
                                                            return AlertDialog(
                                                              title: Text(
                                                                  "Confirmation",
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
                                                                  )),
                                                              content: Text(
                                                                  "Do you want to proceed with online payment using PhonePe?",
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
                                                                  )),
                                                              actions: [
                                                                TextButton(
                                                                  onPressed: () {
                                                                    Navigator.pop(
                                                                        context); // Close the dialog
                                                                  },
                                                                  child: Text("No",
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
                                                                    // Run the specified code
                                                                    print(
                                                                        "BUTTON PRESSED!!!!");
                                                                    body = getChecksum(
                                                                            totalAmount
                                                                                .toInt())
                                                                        .toString();
                                                                    startTransaction(
                                                                        cartDoc,
                                                                        totalAmount);
                                                                  },
                                                                  child: Text("Yes",
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
                                                      child: Text(
                                                        'Online',
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                SizedBox(
                                              height: 10,
                                            ),
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Color.fromARGB(
                                                    255, 128, 69, 60),
                                                fixedSize: Size(
                                                    MediaQuery.of(context)
                                                            .size
                                                            .width /
                                                        1.2,
                                                    20),
                                              ),
                                              onPressed: () {
                                                showDialog(
                                                  context: context,
                                                  builder:
                                                      (BuildContext context) {
                                                    return AlertDialog(
                                                      title: Text(
                                                          'Remove from Cart', style: GoogleFonts
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
                                                          'Are you sure you want to remove this stall from your cart?', style: GoogleFonts
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
                                                            Navigator.of(
                                                                    context)
                                                                .pop(
                                                                    false); // Close the dialog and return false
                                                          },
                                                          child: Text('No', style: GoogleFonts
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
                                                            Navigator.of(
                                                                    context)
                                                                .pop(
                                                                    true); // Close the dialog and return true
                                                          },
                                                          child: Text('Yes', style: GoogleFonts
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
                                                ).then((confirmed) {
                                                  if (confirmed != null &&
                                                      confirmed) {
                                                    // User confirmed removal, proceed with deletion logic
                                                    WriteBatch batch =
                                                        FirebaseFirestore
                                                            .instance
                                                            .batch();
                                                    for (var product in widget
                                                        .productsList!) {
                                                      var productId =
                                                          product.id;
                                                      FirebaseFirestore.instance
                                                          .collection('users')
                                                          .doc(widget.userId)
                                                          .collection('carts')
                                                          .doc(cartDoc.id)
                                                          .collection(
                                                              'products')
                                                          .doc(productId)
                                                          .delete();
                                                    }

                                                    var productsCollectionRef =
                                                        FirebaseFirestore
                                                            .instance
                                                            .collection('users')
                                                            .doc(widget.userId)
                                                            .collection('carts')
                                                            .doc(cartDoc.id)
                                                            .collection(
                                                                'products');

                                                    batch.commit().then((_) {
                                                      productsCollectionRef
                                                          .parent!
                                                          .delete();
                                                    });

                                                    FirebaseFirestore.instance
                                                        .collection('users')
                                                        .doc(widget.userId)
                                                        .collection('carts')
                                                        .doc(cartDoc.id)
                                                        .delete();

                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                            'Stall removed from Cart'),
                                                      ),
                                                    );
                                                  }
                                                });
                                              },
                                              child: Text(
                                                'Remove from Cart',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                ),
                                              ),
                                            )
                                              ],
                                              
                                            ),
                                            
                                          ],
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      }
                    },
                  ),
                ),
              ],
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

// class ThankYou extends StatelessWidget {
//   final String stallName;
//   final String sellerName;
//   const ThankYou(this.stallName, this.sellerName);

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(),
//       body: Center(
//           child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Text(
//             "Thank You for Shopping with",
//             style: GoogleFonts.raleway(
//               fontSize: 24,
//               fontWeight: FontWeight.bold,
//               color: Color.fromARGB(255, 126, 70, 62),
//             ),
//           ),
//           Text(
//             stallName,
//             style: GoogleFonts.raleway(
//               fontSize: 24,
//               fontWeight: FontWeight.bold,
//               color: Color.fromARGB(255, 126, 70, 62),
//             ),
//           ),
//           Text(
//             "The Owner of the Stall",
//             style: GoogleFonts.raleway(
//               fontSize: 24,
//               fontWeight: FontWeight.bold,
//               color: Color.fromARGB(255, 126, 70, 62),
//             ),
//           ),
//           Text(
//             "$sellerName will be very pleased",
//             style: GoogleFonts.raleway(
//               fontSize: 24,
//               fontWeight: FontWeight.bold,
//               color: Color.fromARGB(255, 126, 70, 62),
//             ),
//           ),
//         ],
//       )),
//     );
//   }
// }
