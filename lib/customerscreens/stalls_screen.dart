import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'products_screen.dart';

class StallsScreen extends StatelessWidget {
  final String userId;
  const StallsScreen(this.userId);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
        body: FutureBuilder<QuerySnapshot>(
          future: FirebaseFirestore.instance.collection('stalls').get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData) {
              return Center(child: Text('No data available.'));
            }

            List<DocumentSnapshot> allStalls = snapshot.data!.docs;

            // Filter stalls based on current DateTime
            DateTime currentTime = DateTime.now();
            List<DocumentSnapshot> activeStalls = allStalls.where((stall) {
              DateTime startDateTime = (stall.get('startDateTime') as Timestamp).toDate();
              DateTime endDateTime = (stall.get('endDateTime') as Timestamp).toDate();
              return currentTime.isAfter(startDateTime) && currentTime.isBefore(endDateTime);
            }).toList();

            if (activeStalls.isEmpty) {
              return Center(child: Text('No active stalls at the moment.'));
            }

            return ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 10.0, bottom: 30),
                  child: Center(
                    child: Text(
                      'Stalls on Campus',
                      style: GoogleFonts.raleway(
                        fontSize: 35,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 126, 70, 62),
                      ),
                    ),
                  ),
                ),
                GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, // 2 items in each row
                    crossAxisSpacing: 10.0,
                    mainAxisSpacing: 25.0,
                  ),
                  itemCount: activeStalls.length,
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    DocumentSnapshot stall = activeStalls[index];
                    String stallName = stall.get('name');
                    String imageUrl = stall.get('imageUrl');

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProductsScreen(userId, stall.id),
                          ),
                        );
                      },
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10.0),
                            child: Container(
                              width: double.infinity,
                              height: MediaQuery.of(context).size.height / 5.3,
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10.0),
                                child: Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                          Text(
                            stallName,
                            style: TextStyle(
                              fontSize: 18.0,
                              color: Colors.black, // Brown color
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                SizedBox(height: 10),
              ],
            );
          },
        ),
      ),
    );
  }
}
