import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RefillingInfo {
  String refillingDetails;
  int mileage;
  DateTime date;
  String vehicleId;

  RefillingInfo({required this.refillingDetails, required this.mileage, required this.date, required this.vehicleId});
}

class RefillingDetailsPage extends StatefulWidget {
  @override
  _RefillingDetailsPageState createState() => _RefillingDetailsPageState();
}

class _RefillingDetailsPageState extends State<RefillingDetailsPage> {
  TextEditingController _detailsController = TextEditingController();
  TextEditingController _mileageController = TextEditingController();
  late DateTime _selectedDate;
  String? _selectedVehicleId;
  final user = FirebaseAuth.instance.currentUser!;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  @override
  void dispose() {
    _detailsController.dispose();
    _mileageController.dispose();
    super.dispose();
  }

  void _addRefilling(RefillingInfo info) {
    FirebaseFirestore.instance
        .collection('refillings')
        .doc(user.uid)
        .collection('userfillings')
        .add({
      'refillingDetails': info.refillingDetails,
      'mileage': info.mileage,
      'date': info.date,
      'vehicleId': info.vehicleId
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
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: _detailsController,
                    decoration: InputDecoration(
                      labelText: 'Enter refilling details',
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16.0),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: _mileageController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Enter mileage',
                    ),
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
              ListTile(
                title: Text('Select Vehicle'),
                trailing: Icon(Icons.arrow_forward),
                onTap: () async {
                  String? selectedVehicleId = await showDialog(
                    context: context,
                    builder: (context) => SelectVehiclePopup(),
                  );
                  if (selectedVehicleId != null) {
                    setState(() {
                      _selectedVehicleId = selectedVehicleId;
                    });
                  }
                },
              ),
              if (_selectedVehicleId != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text('Selected Vehicle: $_selectedVehicleId'),
                ),
              SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: () {
                  String details = _detailsController.text;
                  int mileage = int.tryParse(_mileageController.text) ?? 0;
                  if (details.isNotEmpty && mileage > 0 && _selectedVehicleId != null) {
                    _addRefilling(RefillingInfo(refillingDetails: details, mileage: mileage, date: _selectedDate, vehicleId: _selectedVehicleId!));
                    Navigator.pop(context);
                  }
                },
                child: Text('Save'),
              ),
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
