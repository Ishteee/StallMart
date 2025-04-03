import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:xaviers_market/sellerscreens/seller_product_screen.dart';

import '../consts/rounded_textfield.dart';

class EditStall extends StatefulWidget {
  final String userId;
  final String stallId;
  const EditStall(this.userId, this.stallId);

  @override
  State<EditStall> createState() => _EditStallState();
}

class _EditStallState extends State<EditStall> {
  var nameController = TextEditingController();
  final startDateTimeController = TextEditingController();
  final endDateTimeController = TextEditingController();
  bool _uploading = false;
  String? stallName;
  DateTime? startDateTime;
  DateTime? endDateTime;

  @override
  initState() {
    super.initState();
  }

  Future<void> fetchStallDetails() async {
    try {
      // Fetch the document using stallId
      DocumentSnapshot stallDoc = await FirebaseFirestore.instance
          .collection('stalls')
          .doc(widget.stallId)
          .get();

      if (stallDoc.exists) {
        setState(() {
          stallName = stallDoc.get('name');
          startDateTime = (stallDoc.get('startDateTime') as Timestamp).toDate();
          endDateTime = (stallDoc.get('endDateTime') as Timestamp).toDate();
          _uploading = false;
        });
      } else {
        setState(() {
          _uploading = false;
        });
        // Document doesn't exist
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Stall not found.')),
        );
      }
    } catch (error) {
      setState(() {
        _uploading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch stall details: $error')),
      );
    }
  }

  void _pickStartDateTime(BuildContext context) async {
  startDateTime = await selectDateTime(context);
  if (startDateTime != null) {
    // Update the TextEditingController
    startDateTimeController.text = startDateTime.toString();
  }
}

  void _pickEndDateTime(BuildContext context) async {
  endDateTime = await selectDateTime(context);
  if (endDateTime != null) {
    // Update the TextEditingController
    endDateTimeController.text = endDateTime.toString();
  }
}

  Future<DateTime?> selectDateTime(BuildContext context) async {
  // Show Date Picker
  DateTime? pickedDate = await showDatePicker(
    context: context,
    initialDate: DateTime.now(),
    firstDate: DateTime(2022), // Earliest date allowed
    lastDate: DateTime(2100), // Latest date allowed
  );

  if (pickedDate != null) {
    // Show Time Picker
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime != null) {
      // Combine Date and Time
      DateTime finalDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );

      return finalDateTime; // Return DateTime
    }
  }
  return null; // Return null if nothing is picked
}

  Future<void> editStall() async {
    try {
      // Update product details to Firestore
      DocumentReference stallRef =
          FirebaseFirestore.instance.collection('stalls').doc(widget.stallId);

      Map<String, dynamic> finalDetails = {
      'name': nameController.text,
      'startDateTime': startDateTime,
      'endDateTime': endDateTime,
    };

      stallRef
      .update(finalDetails)
      .then((value) => print("Details Updated"))
      .catchError((error) => print("Failed to update details: $error"));

      print('Product updated successfully');
    } catch (error) {
      print('Error updating product: $error');
    }

    Navigator.push(
      context, 
      MaterialPageRoute(builder: (context) => SellerProductsScreen(widget.userId, widget.stallId))
    );
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 242, 233, 226),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 242, 233, 226),
        leading: BackButton(
          color: const Color.fromARGB(255, 126, 70, 62),
          onPressed: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => SellerProductsScreen(widget.userId, widget.stallId)));
          },
        ),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const SizedBox(height: 20),
                  const Center(
                    child: Text(
                      'Edit Stall Details',
                      style: TextStyle(
                        color: Color.fromARGB(255, 126, 70, 62),
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  RoundedTextField(
                    label: 'Name of Your Stall',
                    textColor: Colors.black87,
                    controller: nameController,
                    isObscure: false,
                    obscureText: false,
                    keyboardType: TextInputType.name,
                    validator: (value) {
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  RoundedTextField(
                    label: 'Start Date and Time',
                    
                    isObscure: false,
                    obscureText: false,
                    textColor: Colors.black87,
                    controller: startDateTimeController,
                    readOnly:
                        true, // Make it read-only so user can only pick date/time
                    onTap: () =>
                        _pickStartDateTime(context),
                  ),
                  SizedBox(height: 16),
                  RoundedTextField(
                    label: 'Start Date and Time',
                    
                    isObscure: false,
                    obscureText: false,
                    textColor: Colors.black87,
                    controller: endDateTimeController,
                    readOnly: true,
                    onTap: () => _pickEndDateTime(context),
                  ),
                  const SizedBox(height: 5),
                  Center(
                    child: SizedBox(
                      width: 150, // Adjust the width as needed
                      child: ElevatedButton(
                        onPressed: _uploading
                            ? null
                            : () async {
                                
                                  setState(() {
                                    _uploading = true;
                                  });

                                  
                                    stallName = nameController.text;
                                    await editStall();
                              },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Color.fromARGB(255, 126, 70, 62),
                        ),
                        child: const Text(
                          'Confirm',
                          style: TextStyle(fontSize: 15),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          if (_uploading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}