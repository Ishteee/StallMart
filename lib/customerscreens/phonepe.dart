import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phonepe_payment_sdk/phonepe_payment_sdk.dart';
import 'package:http/http.dart' as http;
import 'package:xaviers_market/customerscreens/CustomerNavbar.dart';

class PhonePePayment extends StatefulWidget {
  final String userId;
  final QueryDocumentSnapshot<Object?> cartDoc;
  final double totalAmount;
  const PhonePePayment(this.userId, this.cartDoc, this.totalAmount);

  @override
  State<PhonePePayment> createState() => _PhonePePaymentState();
}

class _PhonePePaymentState extends State<PhonePePayment> {
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
    body = getChecksum().toString();
    startTransaction();
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

  void startTransaction() {
    PhonePePaymentSdk.startTransaction(body, callback, checksum, packageName)
        .then((response) => {
              setState(() async {
                if (response != null) {
                  String status = response['status'].toString();
                  String error = response['error'].toString();
                  if (status == 'SUCCESS') {
                    result = "Flow Completed - Status: Success!";

                    await checkStatus();
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

  checkStatus() async {
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

          var productSnapshot = await widget.cartDoc.reference
            .collection('products') // Access the 'products' sub-collection
            .get();

          var productsText = productSnapshot.docs
            .map((product) =>
                '${product['name']} x ${product['quantity']}')
            .join('\n');

          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.userId)
              .collection('orders')
              .add({
            'purchaseTime': DateTime.now().millisecondsSinceEpoch,
            'products': productsText,
            'totalAmount': widget.totalAmount,
            'stallName': widget.cartDoc['stallName'],
          });
          print("Order added successfully!");


        } catch (e) {}
      } else {
        Fluttertoast.showToast(msg: "Something went wrong!");
      }
    });
  }

  getChecksum() {
    final reqData = {
      "merchantId": merchantId,
      "merchantTransactionId": transactionId,
      "merchantUserId": "MUID123",
      "amount": 1000,
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
    return MaterialApp(
      title: "Payment went wrong",
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
              Text(
                'Payment Failed',
                style: GoogleFonts.raleway(
                  fontSize: 35,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 126, 70, 62),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Pressing the back button or closing the app may be the reason of payment failure.',
                  style: GoogleFonts.raleway(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 126, 70, 62),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Color.fromARGB(255, 128, 69, 60)),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => customerBottomNavigation(
                            widget.userId,
                            2), // Pass document ID to SellerHomeScreen
                      ),
                    );
                  },
                  child: Text(
                    "Redirect to Cart",
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
