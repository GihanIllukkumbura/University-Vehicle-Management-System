import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VehicleList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Vehicle List'),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('vehicles').snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var vehicle = snapshot.data!.docs[index].data() as Map<String, dynamic>;
              return Card(
                elevation: 5,
                margin: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: ListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  title: Text(
                    vehicle['make'] + ' ' + vehicle['model'],
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 5),
                      Text('Registered Number: ' + vehicle['registeredNumber']),
                      Text('Km per Liter: ' + vehicle['dpkm'] + 'km'),
                    ],
                  ),
                  leading: CircleAvatar(
                    radius: 30,
                    backgroundImage: NetworkImage(vehicle['imageUrl'][0]),
                    backgroundColor: Colors.grey[200],
                  ),
                  onTap: () {
                    // Handle item tap
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
