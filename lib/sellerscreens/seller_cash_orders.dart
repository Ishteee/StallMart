import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get_connect/http/src/utils/utils.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class SellerCashOrdersScreen extends StatelessWidget {
  final String userId;
  const SellerCashOrdersScreen(this.userId);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: StreamBuilder(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .collection('comp_bookings')
                .where('method', isEqualTo: 'cash')
                .snapshots(),
            builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (!snapshot.hasData) {
                return Center(
                  child: CircularProgressIndicator(),
                );
              } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text(
                    'No Cash Orders Yet',
                    style: TextStyle(
                        color: const Color.fromARGB(255, 126, 70, 62),
                        fontWeight: FontWeight.bold,
                        fontSize: 20),
                  ),
                );
              } else {
                final c_bookings = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: c_bookings.length,
                  itemBuilder: (context, index) {
                    final c_book = c_bookings[index];
                    return _buildOrderContainer(context, c_book);
                  },
                );
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildOrderContainer(BuildContext context, DocumentSnapshot c_book) {
    var purchaseTime = c_book['purchaseTime'];
    var purchaseDateTime = DateTime.fromMillisecondsSinceEpoch(purchaseTime);
    var date = DateFormat('dd/MM/yyyy').format(purchaseDateTime);
    var time = DateFormat('h:mm a').format(purchaseDateTime);
    return Container(
      width: MediaQuery.of(context).size.width / 2, // Adjust width as needed
      margin: EdgeInsets.symmetric(vertical: 5.0, horizontal: 5),
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
                        style: TextStyle(fontSize: 15),
                      ),
                      Text(
                        c_book['stallName'],
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 17),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "Date and Time of Purchase",
                        style: TextStyle(fontSize: 15),
                      ),
                      Text(
                        "$date - $time",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 17),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 25),
              RichText(
                text: TextSpan(
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: 18), // Adjust the style as needed
                  children: [
                    TextSpan(text: 'Products: '),
                    TextSpan(
                        text: c_book['products'],
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              SizedBox(height: 25),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    'Total Bill Amount: ',
                    style: TextStyle(fontSize: 17),
                  ),
                  Text(
                    c_book['totalAmount'].toString(),
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
