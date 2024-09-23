// import 'dart:async';
//
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:firebasefluttter/screens/auth.dart';
// import 'package:firebasefluttter/screens/selectVehical.dart';
// import 'package:flutter/material.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import '../chat/chatusers.dart';
// import 'Dialpadscreen.dart';
// import 'EditProfilePage.dart';
// import 'MapPage.dart';
// import 'SupportPage.dart';
//
// import 'AllMap.dart';
// import 'Trip History.dart';
// import 'Vehicals.dart';
// import 'locations.dart';
// import 'newsettrip.dart';
//
// class Home extends StatefulWidget {
//   const Home({Key? key}) : super(key: key);
//
//   @override
//   _HomeState createState() => _HomeState();
// }
//
// class _HomeState extends State<Home> {
//   final user = FirebaseAuth.instance.currentUser!;
//   final DateTime now = DateTime.now();
//   final Completer<GoogleMapController> _controller = Completer();
//   GoogleMapController? controllerGoogleMap;
//   Position? currentPositionOfUser;
//
//   StreamSubscription<Position>? positionStream;
//
//   @override
//   void initState() {
//     super.initState();
//     getCurrentLiveLocationOfUser();
//   }
//
//   @override
//   void dispose() {
//     positionStream?.cancel();
//     super.dispose();
//   }
//
//   void getCurrentLiveLocationOfUser() {
//     positionStream =
//         Geolocator.getPositionStream().listen((Position position) {
//           setState(() {
//             currentPositionOfUser = position;
//             LatLng positionOfUserInLatLng =
//             LatLng(currentPositionOfUser!.latitude, currentPositionOfUser!.longitude);
//
//             CameraPosition cameraPosition =
//             CameraPosition(target: positionOfUserInLatLng, zoom: 15);
//             controllerGoogleMap?.animateCamera(
//                 CameraUpdate.newCameraPosition(cameraPosition));
//
//             // Upload user's live location to Firestore
//             FirebaseFirestore.instance
//                 .collection('locations')
//                 .doc(user.uid)
//                 .set({
//               'userid': user.uid,
//               'latitude': currentPositionOfUser!.latitude,
//               'longitude': currentPositionOfUser!.longitude,
//             });
//           });
//         });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Home'),
//       ),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Text(
//               'Welcome, ${user.displayName ?? 'User'}!',
//               style: TextStyle(fontSize: 20.0),
//             ),
//             SizedBox(height: 10),
//             Text(
//               'Email: ${user.email}',
//               style: TextStyle(fontSize: 16.0),
//             ),
//             SizedBox(height: 20),
//             Text(
//               '${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute}:${now.second}',
//               style: TextStyle(
//                 fontSize: 24.0,
//                 color: Colors.blue,
//               ),
//             ),
//           ],
//         ),
//       ),
//       drawer: Drawer(
//         child: ListView(
//           padding: EdgeInsets.zero,
//           children: [
//             GestureDetector(
//               onTap: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (context) => ProfileEditPage()),
//                 );
//               },
//               child: StreamBuilder<DocumentSnapshot>(
//                 stream: FirebaseFirestore.instance
//                     .collection('users')
//                     .doc(FirebaseAuth.instance.currentUser!.uid)
//                     .snapshots(),
//                 builder: (context, snapshot) {
//                   if (!snapshot.hasData) {
//                     return Center(child: CircularProgressIndicator());
//                   }
//
//                   Map<String, dynamic>? userData = snapshot.data!.data() as Map<String, dynamic>?;
//                   String? username = userData?['username'];
//
//                   return UserAccountsDrawerHeader(
//                     accountName: Text(username ?? 'John'), // Replace with actual name
//                     accountEmail: Text('${user.email}'), // Replace with actual email
//                     currentAccountPicture: CircleAvatar(
//                       backgroundImage: NetworkImage(userData?['image_url'] ?? ''), // Use image_url from Firestore
//                     ),
//                     decoration: BoxDecoration(
//                       color: Colors.blue,
//                     ),
//                   );
//                 },
//               ),
//             ),
//             ListTile(
//               title: Text('Your Location'),
//               onTap: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (context) => MapPage()),
//                 );
//               },
//             ),
//             ListTile(
//               title: Text('Trips '),
//               onTap: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (context) => TripHistoryPage()),
//                 );
//               },
//             ),
//             ListTile(
//               title: Text('Vehicles'),
//               onTap: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (context) => VehicleList()),
//                 );
//               },
//             ),
//             ListTile(
//               title: Text('All the Drivers Map'),
//               onTap: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (context) => AllMap()),
//                 );
//               },
//               // ), ListTile(
//               //   title: Text('locations'),
//               //   onTap: () {
//               //     Navigator.push(
//               //       context,
//               //       MaterialPageRoute(builder: (context) => Location()),
//               //     );
//               //   },
//             ),
//             ListTile(
//               title: Text('Log out'),
//               onTap: () {
//                 FirebaseAuth.instance.signOut();
//
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (context) => AuthScreen()),
//                 );
//               },
//             ),
//           ],
//         ),
//       ),
//       bottomNavigationBar: BottomAppBar(
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.spaceAround,
//           children: [
//             IconButton(
//               icon: Icon(Icons.map),
//               onPressed: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (context) => SelectVehicle(),
//                   ),
//                 ); // Navigate to SelectVehicle
//               },
//             ),
//
//             IconButton(
//               icon: Icon(Icons.phone),
//               onPressed: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (context) => DialPadScreen(),
//                   ),
//                 ); // Navigate to HelpPage
//               },
//             ),
//             IconButton(
//               icon: Icon(Icons.chat), // Use chat icon
//               onPressed: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (context) => UserList()),
//                 );
//               },
//             ),
//             IconButton(
//               icon: Icon(Icons.menu),
//               onPressed: () {
//                 Scaffold.of(context).openDrawer();
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
