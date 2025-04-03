import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get_connect/http/src/utils/utils.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class CompletedOnlineOrdersScreen extends StatelessWidget {
  final String userId;
  const CompletedOnlineOrdersScreen(this.userId);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: StreamBuilder(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .collection('orders')
                .where('method', isEqualTo: 'online')
                .snapshots(),
            builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (!snapshot.hasData) {
                return Center(
                  child: CircularProgressIndicator(),
                );
              } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text(
                    'No Online Orders Yet',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color.fromARGB(255, 126, 70, 62),
                    ),
                  ),
                );
              } else {
                final orders = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return _buildOrderContainer(context, order);
                  },
                );
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildOrderContainer(BuildContext context, DocumentSnapshot order) {
    var purchaseTime = order['purchaseTime'];
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
                        style: GoogleFonts.raleway(fontSize: 15, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 128, 69, 60),),
                      ),
                      Text(
                        order['stallName'],
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
                        style: GoogleFonts.raleway(fontSize: 15, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 128, 69, 60),),
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
                    TextSpan(text: 'Products: ', style: GoogleFonts.raleway(fontSize: 17, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 128, 69, 60),),),
                    TextSpan(
                        text: order['products'],
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
                    style: GoogleFonts.raleway(fontSize: 17, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 128, 69, 60),),
                  ),
                  Text(
                    order['totalAmount'].toString(),
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
