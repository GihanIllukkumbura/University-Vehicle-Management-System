import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Addexpensepage extends StatefulWidget {
  @override
  _AddexpensepageState createState() => _AddexpensepageState();
}

class AddexpensepageInfo {
  String expensedetails;
  double cost;
  DateTime date;
  String vehicleId;

  AddexpensepageInfo({required this.expensedetails, required this.cost, required this.date, required this.vehicleId});
}

class _AddexpensepageState extends State<Addexpensepage> {
  TextEditingController _detailsController = TextEditingController();
  TextEditingController _priceController = TextEditingController();
  late DateTime _selectedDate;
  String? _selectedVehicleId;
  String? _selectedVehicleImageUrl;
  String? _selectedVehicleName;
  String? _selectedVehicleFuelType;
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
    _priceController.dispose();
    super.dispose();
  }

  void _AddexpensepageInfo(AddexpensepageInfo info) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }

    String? username;
    String? registeredNumber;
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists && userDoc['username'] != null) {
        username = userDoc['username'];
      } else {
        username = user.email;
      }
    } catch (e) {
      username = user.email;
    }

    try {
      DocumentSnapshot vehicleDoc = await FirebaseFirestore.instance
          .collection('vehicles')
          .doc(info.vehicleId)
          .get();

      if (vehicleDoc.exists && vehicleDoc['registeredNumber'] != null) {
        registeredNumber = vehicleDoc['registeredNumber'];
      } else {
        registeredNumber = 'Unknown';
      }
    } catch (e) {
      registeredNumber = 'Unknown';
    }

    FirebaseFirestore.instance
        .collection('expense')
        .doc(user.uid)
        .collection('userexpense')
        .add({
      'expensedetails': info.expensedetails,
      'cost': info.cost,
      'date': info.date,
      'vehicleId': info.vehicleId,
      'username': username,
      'registeredNumber': registeredNumber,
    });

    FirebaseFirestore.instance.collection('expenseforweb').add({
      'expensedetails': info.expensedetails,
      'cost': info.cost,
      'date': info.date,
      'vehicleId': info.vehicleId,
      'userid': user.uid,
      'username': username,
      'registeredNumber': registeredNumber,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Expense Details', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ListTile(
                title: Text('Select Vehicle', style: TextStyle(fontWeight: FontWeight.bold)),
                trailing: Icon(Icons.arrow_forward, color: Colors.teal),
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
                      _selectedVehicleFuelType = vehicle['fuelType'];
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
                            style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
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
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: _detailsController,
                    decoration: InputDecoration(
                      labelText: 'Enter Expense',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16.0),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Enter Cost (Rs)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Date: ${DateFormat.yMMMd().format(_selectedDate)}', style: TextStyle(fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: Icon(Icons.calendar_today, color: Colors.teal),
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () {
                  String details = _detailsController.text;
                  double cost = double.tryParse(_priceController.text) ?? 0;
                  if (cost > 0 && _selectedVehicleId != null) {
                    _AddexpensepageInfo(AddexpensepageInfo(
                        expensedetails: details, cost: cost, date: _selectedDate, vehicleId: _selectedVehicleId!));
                    Navigator.pop(context);
                  }
                },
                child: Text('Save', style: TextStyle(fontSize: 16.0)),
              ),
              SizedBox(height: 16.0),
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
      title: Text('Select Vehicle', style: TextStyle(fontWeight: FontWeight.bold)),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}
