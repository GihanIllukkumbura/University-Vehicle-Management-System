import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'SettingTrip.dart';

class SelectVehicle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Vehicle'),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('vehicles').snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> vehicleSnapshot) {
          if (!vehicleSnapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          return StreamBuilder(
            stream: FirebaseFirestore.instance.collection('activetrips').snapshots(),
            builder: (context, AsyncSnapshot<QuerySnapshot> activeTripsSnapshot) {
              if (!activeTripsSnapshot.hasData) {
                return Center(child: CircularProgressIndicator());
              }

              // Collect all vehicleIds that are currently in use
              List<String> vehiclesInUse = activeTripsSnapshot.data!.docs
                  .map((doc) => doc['vehicleId'] as String)
                  .toList();

              return ListView.builder(
                itemCount: vehicleSnapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  var vehicle = vehicleSnapshot.data!.docs[index].data() as Map<String, dynamic>;
                  String vehicleId = vehicleSnapshot.data!.docs[index].id;
                  bool isInUse = vehiclesInUse.contains(vehicleId); // Check if the vehicle is in use

                  return ListTile(
                    tileColor: isInUse ? Colors.green[100] : null, // Green background for in-use vehicles
                    title: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(vehicle['make'] + ' ' + vehicle['model']),
                              Text('Registered Number: ' + vehicle['registeredNumber']),
                              Text('Km per Liter: ' + vehicle['dpkm'] + 'km'),
                            ],
                          ),
                        ),
                        if (isInUse)
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              'In Use',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                      ],
                    ),
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(vehicle['imageUrl'][0]),
                    ),
                    onTap: isInUse
                        ? null // Disable selection for vehicles in use
                        : () {
                      // Navigate to the set trip page with the selected vehicle ID and name
                      String selectedVehicleId = vehicleId;
                      String selectedVehicleName = vehicle['make'] + ' ' + vehicle['model'];
                      String selectedVehicledpkm = vehicle['dpkm'];

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NewSettingTrip(
                            selectedVehicleId: selectedVehicleId,
                            selectedVehicleName: selectedVehicleName,
                            selectedVehicledpkm: selectedVehicledpkm,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
