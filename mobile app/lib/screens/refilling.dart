import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RefillingDetailsPage extends StatefulWidget {
  @override
  _RefillingDetailsPageState createState() => _RefillingDetailsPageState();
}

class RefillingInfo {
  String refillingDetails;
  double  liters;
  double  priceperliter;// Changed from int mileage to String fuelType
  DateTime date;
  String vehicleId;

  RefillingInfo({required this.refillingDetails, required this.liters,required this.priceperliter, required this.date, required this.vehicleId});
}


class _RefillingDetailsPageState extends State<RefillingDetailsPage> {
  TextEditingController _detailsController = TextEditingController();
  TextEditingController _litersController = TextEditingController();
  TextEditingController _priceController = TextEditingController();
  late DateTime _selectedDate;
  String? _selectedVehicleId;
  String? _selectedVehicleImageUrl;
  String? _selectedVehicleName;
  String? _selectedVehicleFuelType; // Added variable for fuel type
  final user = FirebaseAuth.instance.currentUser!;
  double totalCost = 0.0;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  @override
  void dispose() {
    _detailsController.dispose();
    _litersController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _addRefilling(RefillingInfo info) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Handle the case when there is no authenticated user
      return;
    }

    String? username;
    String? registeredNumber;
    try {
      // Fetch the username from the users collection
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists && userDoc['username'] != null) {
        username = userDoc['username'];
      } else {
        // If username is not available, use email
        username = user.email;
      }
    } catch (e) {
      // If there is an error or username is not found, use email
      username = user.email;
    }

    try {
      // Fetch the registeredNumber from the vehicles collection
      DocumentSnapshot vehicleDoc = await FirebaseFirestore.instance
          .collection('vehicles')
          .doc(info.vehicleId)
          .get();

      if (vehicleDoc.exists && vehicleDoc['registeredNumber'] != null) {
        registeredNumber = vehicleDoc['registeredNumber'];
      } else {
        registeredNumber = 'Unknown'; // or handle appropriately if not found
      }
    } catch (e) {
      registeredNumber = 'Unknown'; // or handle appropriately if an error occurs
    }






    FirebaseFirestore.instance
        .collection('refillings')
        .doc(user.uid)
        .collection('userfillings')
        .add({
      'refillingDetails': info.refillingDetails,
      'liters': info.liters,
      'priceperliter' : info.priceperliter,
      'date': info.date,
      'vehicleId': info.vehicleId,
      'totalCost': totalCost,
      'username': username,
      'registeredNumber':registeredNumber,

    });
    FirebaseFirestore.instance.collection('refillingforweb').add({
      'refillingDetails': info.refillingDetails,
      'liters': info.liters,
      'priceperliter': info.priceperliter,
      'date': info.date,
      'vehicleId': info.vehicleId,
      'totalCost': totalCost,
      'userid': user.uid,
      'username': username,
      'registeredNumber':registeredNumber,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Refilling Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ListTile(
                title: Text('Select Vehicle'),
                trailing: Icon(Icons.arrow_forward),
                onTap: () async {
                  String? selectedVehicleId = await showDialog(
                    context: context,
                    builder: (context) => SelectVehiclePopup(),
                  );
                  if (selectedVehicleId != null) {
                    var vehicle = await FirebaseFirestore.instance
                        .collection('vehicles')
                        .doc(selectedVehicleId)
                        .get();
                    setState(() {
                      _selectedVehicleId = selectedVehicleId;
                      _selectedVehicleImageUrl = vehicle['imageUrl'][0];
                      _selectedVehicleName = vehicle['make'] + ' ' + vehicle['model'];
                      _selectedVehicleFuelType = vehicle['fuelType']; // Get and set fuel type
                    });
                  }
                },
              ),
              if (_selectedVehicleImageUrl != null && _selectedVehicleName != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 25,
                        backgroundImage: NetworkImage(_selectedVehicleImageUrl!),
                      ),
                      SizedBox(width: 16.0),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Selected Vehicle: $_selectedVehicleName',
                            style: TextStyle(fontSize: 16.0),
                          ),
                          if (_selectedVehicleFuelType != null)
                            Text(
                              'Fuel Type: $_selectedVehicleFuelType',
                              style: TextStyle(fontSize: 14.0, color: Colors.grey),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: _detailsController,
                    decoration: InputDecoration(
                      labelText: 'refilling station location',
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16.0),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _litersController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'number of liters',
                          ),
                        ),
                      ),
                      SizedBox(width: 16.0),
                      Expanded(
                        child: TextField(
                          controller: _priceController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'price per liter',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Date: ${DateFormat.yMMMd().format(_selectedDate)}'),
                  IconButton(
                    icon: Icon(Icons.calendar_today),
                    onPressed: () async {
                      final DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (pickedDate != null && pickedDate != _selectedDate) {
                        setState(() {
                          _selectedDate = pickedDate;
                        });
                      }
                    },
                  ),
                ],
              ),
              SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: () {
                  String details = _detailsController.text;
                  double liters = double.tryParse(_litersController.text) ?? 0;
                  double pricePerLiter = double.tryParse(_priceController.text) ?? 0;
                  if (details.isNotEmpty && liters > 0 && pricePerLiter > 0 && _selectedVehicleId != null) {
                    totalCost = liters * pricePerLiter;
                    _addRefilling(RefillingInfo(refillingDetails: details, liters: liters,priceperliter: pricePerLiter, date: _selectedDate, vehicleId: _selectedVehicleId!));
                    Navigator.pop(context);
                  }
                },
                child: Text('Save'),
              ),
              SizedBox(height: 16.0),
              if (totalCost > 0) Text('Total Cost: $totalCost'),
            ],
          ),
        ),
      ),
    );
  }
}

class SelectVehiclePopup extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Select Vehicle'),
      content: SizedBox(
        width: double.maxFinite,
        height: 300,
        child: StreamBuilder(
          stream: FirebaseFirestore.instance.collection('vehicles').snapshots(),
          builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (!snapshot.hasData) {
              return Center(child: CircularProgressIndicator());
            }

            return ListView.builder(
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                var vehicle = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                return ListTile(
                  title: Text(vehicle['make'] + ' ' + vehicle['model']),
                  subtitle: Text('Registered Number: ' + vehicle['registeredNumber']),
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(vehicle['imageUrl'][0]),
                  ),
                  onTap: () {
                    Navigator.pop(context, snapshot.data!.docs[index].id);
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
