// import 'package:flutter/material.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
//
// class Location extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('All Locations'),
//       ),
//       body: AllLocationsMap(),
//     );
//   }
// }
//
// class AllLocationsMap extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return StreamBuilder<QuerySnapshot>(
//       stream: FirebaseFirestore.instance.collection('locations').snapshots(),
//       builder: (context, snapshot) {
//         if (!snapshot.hasData) {
//           return Center(
//             child: CircularProgressIndicator(),
//           );
//         }
//
//         List<DocumentSnapshot> documents = snapshot.data!.docs;
//         Set<Marker> markers = {};
//
//         for (int i = 0; i < documents.length; i++) {
//           final DocumentSnapshot document = documents[i];
//           final Map<String, dynamic> data = document.data() as Map<String, dynamic>;
//
//           if (data.containsKey('latitude') && data.containsKey('longitude')) {
//             final double latitude = data['latitude'] as double;
//             final double longitude = data['longitude'] as double;
//             final String userId = document.id;
//
//             final MarkerId markerId = MarkerId(userId);
//             final Marker marker = Marker(
//               markerId: markerId,
//               position: LatLng(latitude, longitude),
//               infoWindow: InfoWindow(title: userId),
//               icon: BitmapDescriptor.defaultMarker,
//             );
//
//             markers.add(marker);
//           }
//         }
//
//         return GoogleMap(
//           markers: markers,
//           initialCameraPosition: CameraPosition(
//             target: LatLng(7.2, 80.7),
//             zoom: 8.33,
//           ),
//           myLocationEnabled: true,
//         );
//       },
//     );
//   }
// }
