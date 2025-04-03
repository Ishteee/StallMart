import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class PendingBookingsScreen extends StatefulWidget {
  final String userId;

  PendingBookingsScreen(this.userId);

  @override
  _PendingBookingsScreenState createState() => _PendingBookingsScreenState();
}

class _PendingBookingsScreenState extends State<PendingBookingsScreen> {
  late Timer _timer;
  List<QueryDocumentSnapshot>? _bookedDocs;
  Map<String, List<DocumentSnapshot>> _productsMap = {};

  @override
  void initState() {
    super.initState();

    // Start the countdown timer
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _fetchBookedDocs();
      setState(() {});
    });
  }

  Future<void> _fetchBookedDocs() async {
    // Fetch all documents where isBooked is true
    var querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('carts')
        .where('isBooked', isEqualTo: true)
        .get();

    setState(() {
      _bookedDocs = querySnapshot.docs;
    });

    _fetchProductsForDocs();
  }

  Future<void> _fetchProductsForDocs() async {
    if (_bookedDocs != null) {
      for (var doc in _bookedDocs!) {
        var productsSnapshot = await doc.reference.collection('products').get();
        _productsMap[doc.id] = productsSnapshot.docs;
      }
      setState(() {});
    }
  }

  @override
  void dispose() {
    _timer.cancel(); // Cancel the timer when the widget is disposed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: _bookedDocs != null
          ? ListView.builder(
              itemCount: _bookedDocs?.length,
              itemBuilder: (context, index) {
                var doc = _bookedDocs?[index];
                int checkoutTime = doc?['checkoutTime'];
                var checkoutDateTime =
                    DateTime.fromMillisecondsSinceEpoch(checkoutTime);
                String date = DateFormat('dd/MM/yyyy').format(checkoutDateTime);
                String time = DateFormat('h:mm a').format(checkoutDateTime);
                int fifteenMinutesInMillis = 15 * 60 * 1000;
                int timeElapsedInMillis =
                    DateTime.now().millisecondsSinceEpoch - checkoutTime;
                int remainingTimeInMillis =
                    fifteenMinutesInMillis - timeElapsedInMillis;

                int remainingMinutes =
                    (remainingTimeInMillis / (60 * 1000)).floor();
                int remainingSeconds =
                    ((remainingTimeInMillis % (60 * 1000)) / 1000).floor();

                String productsText = _productsMap[doc?.id] != null
                    ? _productsMap[doc?.id]!
                        .map((product) =>
                            '${product['name']} x ${product['quantity']}')
                        .join('\n')
                    : '';

                var stallName = doc?['stallName'];
                var sellerId = doc?['sellerId'];

                if (timeElapsedInMillis >= fifteenMinutesInMillis) {
                  FirebaseFirestore.instance
                      .collection('users')
                      .doc(widget.userId)
                      .collection('carts')
                      .doc(doc?.id)
                      .set({
                    'isBooked': false,
                    'checkoutTime': '',
                    'stallName': stallName,
                    'totalAmount': ''
                  });
                  setState(() {});
                }

                return Container(
                  width: MediaQuery.of(context).size.width /
                      2, // Adjust width as needed
                  margin: EdgeInsets.symmetric(vertical: 5.0, horizontal: 3),
                  child: Card(
                    elevation: 5.0, // Add elevation for a shadow effect
                    color: Color.fromARGB(255, 242, 233, 226),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Stall Name",
                                    style: GoogleFonts.raleway(fontSize: 15, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 128, 69, 60),),
                                  ),
                                  Text(
                                    doc?['stallName'],
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 17),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    "Date and Time",
                                    style: GoogleFonts.raleway(fontSize: 15, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 128, 69, 60),),
                                  ),
                                  Text(
                                    "${date} - ${time}",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 17),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(height: 25),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Column(
                                children: [
                                  Text(
                                    'Products',
                                    style: GoogleFonts.raleway(fontSize: 18, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 128, 69, 60),),
                                  ),
                                  Text(
                                    productsText,
                                    style: TextStyle(
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(height: 25),
                          Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Total Bill Amount: ',
                                    style: GoogleFonts.raleway(fontSize: 17, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 128, 69, 60),),
                                  ),
                                  Text(
                                    doc!['totalAmount'].toString(),
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text.rich(
                                    TextSpan(
                                      children: [
                                        TextSpan(
                                          text: 'Booking Auto-Cancel: ',
                                          style: GoogleFonts.raleway(fontSize: 17, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 128, 69, 60),),
                                        ),
                                        TextSpan(
                                          text:
                                              '$remainingMinutes:${remainingSeconds.toString().padLeft(2, '0')}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 19,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(
                                height: 10,
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.brown,
                                    ),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            title: Text('Cancel Booking'),
                                            content: Text(
                                                'Are you sure you want to cancel this booking?'),
                                            actions: [
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.of(context).pop(
                                                      false); // Close the dialog and return false
                                                },
                                                child: Text('No'),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.of(context).pop(
                                                      true); // Close the dialog and return true
                                                },
                                                child: Text('Yes'),
                                              ),
                                            ],
                                          );
                                        },
                                      ).then((confirmed) async {
                                        if (confirmed != null && confirmed) {
                                          if (doc['bookNow'] == true) {
                                            var productsSnapshot = await doc
                                                .reference
                                                .collection('products')
                                                .get();
                                            if (productsSnapshot
                                                .docs.isNotEmpty) {
                                              var productDoc =
                                                  productsSnapshot.docs.first;
                                              await productDoc.reference
                                                  .delete();
                                            }
                                            await doc.reference.delete();
                                          } else {
                                            await FirebaseFirestore.instance
                                                .collection('users')
                                                .doc(widget.userId)
                                                .collection('carts')
                                                .doc(doc.id)
                                                .set({
                                              'bookNow': false,
                                              'checkoutTime': '',
                                              'isBooked': false,
                                              'sellerId': sellerId,
                                              'stallName': stallName,
                                              'totalAmount': '',
                                              'isFnB': doc?['isFnB']
                                            });

                                            await FirebaseFirestore.instance
                                              .collection('users')
                                              .doc(sellerId)
                                              .collection('bookings')
                                              .doc(widget.userId)
                                              .delete();
                                          }
                                        }
                                      });
                                    },
                                    child: Text(
                                      "Cancel Booking",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            )
          : CircularProgressIndicator(),
    );
  }
}
