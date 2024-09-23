import 'dart:async';
import 'dart:ffi';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebasefluttter/screens/assignedTasks.dart';
import 'package:firebasefluttter/screens/auth.dart';
import 'package:firebasefluttter/screens/refilling.dart';
import 'package:firebasefluttter/screens/selectVehical.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import '../Methods/checkAuth.dart';
import '../chat/chatusers.dart';
import 'Dialpadscreen.dart';
import 'EditProfilePage.dart';
import 'MapPage.dart';
import 'Statsection/StatSection.dart';
import 'Statsection/addexpense.dart';
import 'Statsection/expense page.dart';
import 'SupportPage.dart';

import 'AllMap.dart';
import 'Trip History.dart';
import 'Vehicals.dart';
import 'locations.dart';
import 'newsettrip.dart';
import 'package:url_launcher/url_launcher.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final user = FirebaseAuth.instance.currentUser!;
  final DateTime now = DateTime.now();
  final Completer<GoogleMapController> _controller = Completer();
  GoogleMapController? controllerGoogleMap;
  Position? currentPositionOfUser;

  StreamSubscription<Position>? positionStream;
  late Stream<QuerySnapshot> _ongoingTripsStream;
  final AuthChecker _authChecker = AuthChecker();

  @override
  void initState() {
    super.initState();
    _authChecker.startAuthCheck(context);

    getCurrentLiveLocationOfUser();
    _ongoingTripsStream = FirebaseFirestore.instance
        .collection('trips')
        .doc(user.uid)
        .collection('userTrips')
        .where('tripstatus', isEqualTo: 0)
        .snapshots();
  }

  @override
  void dispose() {
    positionStream?.cancel();
    _authChecker.stopAuthCheck();
    super.dispose();
  }

  void getCurrentLiveLocationOfUser() {
    positionStream = Geolocator.getPositionStream().listen((Position position) {
      setState(() {
        currentPositionOfUser = position;
        LatLng positionOfUserInLatLng = LatLng(
            currentPositionOfUser!.latitude, currentPositionOfUser!.longitude);

        CameraPosition cameraPosition =
            CameraPosition(target: positionOfUserInLatLng, zoom: 15);
        controllerGoogleMap
            ?.animateCamera(CameraUpdate.newCameraPosition(cameraPosition));

        // Upload user's live location to Firestore
        FirebaseFirestore.instance.collection('locations').doc(user.uid).set({
          'userid': user.uid,
          'latitude': currentPositionOfUser!.latitude,
          'longitude': currentPositionOfUser!.longitude,
        });
      });
    });
  }

  String _calculateTripTime(Timestamp startTime) {
    DateTime tripStartTime = startTime.toDate();
    Duration tripDuration = DateTime.now().difference(tripStartTime);

    int hours = tripDuration.inHours;
    int minutes = tripDuration.inMinutes.remainder(60);
    int seconds = tripDuration.inSeconds.remainder(60);

    return '$hours h, $minutes min, $seconds sec';
  }

  // void _addRefilling(RefillingInfo info) {
  //   FirebaseFirestore.instance
  //       .collection('refillings')
  //       .doc(user.uid)
  //       .collection('userfillings')
  //       .add({
  //     'refillingDetails': info.refillingDetails,
  //     'mileage': info.mileage,
  //     'date': info.date,
  //     'vehicalid':info.vehicleId
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
        backgroundColor: Color.fromRGBO(209, 239, 178, 1.0),
        actions: [
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Row(
                  children: [
                    CircleAvatar(
                      backgroundImage: AssetImage('assets/profile.png'),
                    ),
                    SizedBox(width: 16),
                    Text('Loading...'),
                    SizedBox(width: 8),
                  ],
                );
              }

              Map<String, dynamic>? userData =
                  snapshot.data!.data() as Map<String, dynamic>?;
              String? username = userData?['username'];
              String? userImageUrl = userData?['image_url'];

              return Row(
                children: [
                  CircleAvatar(
                    backgroundImage: userImageUrl != null
                        ? NetworkImage(userImageUrl)
                        : AssetImage('assets/profile.png') as ImageProvider,
                  ),
                  SizedBox(width: 16),
                  Text(username ?? 'User'),
                  SizedBox(width: 8),
                  // Add some padding to the right edge
                ],
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _ongoingTripsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 120, // Adjust the height as needed
                      child: Image.asset(
                        'assets/images/unilogo.png', // Assuming 'unilogo.png' is your university logo
                        fit: BoxFit.contain, // Adjust the fit as needed
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Wayamba University of Sri Lanka',
                      style: TextStyle(
                        fontSize: 24.0,
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Transportation Department',
                      style: TextStyle(
                        fontSize: 20.0,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 20),
                    StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return CircularProgressIndicator();
                        }

                        Map<String, dynamic>? userData =
                            snapshot.data!.data() as Map<String, dynamic>?;
                        String? username = userData?['username'];

                        return Container(
                          margin: EdgeInsets.all(20),
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Color.fromRGBO(199, 125, 125, 1.0),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Welcome, ${username ?? 'User'}!',
                                style: TextStyle(
                                  fontSize: 24.0,
                                  color: Colors.white,
                                  fontFamily: 'Roboto',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 10),
                              Text(
                                '${now.year} ${DateFormat.MMMM().format(now)} ${now.day}',
                                style: TextStyle(
                                  fontSize: 20.0,
                                  color: Colors.white,
                                  fontFamily: 'Roboto',
                                ),
                              ),
                              SizedBox(height: 10),
                              Text(
                                '${DateFormat('h:mm:ss a').format(now)}',
                                style: TextStyle(
                                  fontSize: 20.0,
                                  color: Colors.white,
                                  fontFamily: 'Roboto',
                                ),
                              ),
                              SizedBox(height: 10),
                              // Text(
                              //   'Email: ${user.email ?? ""}',
                              //   style: TextStyle(
                              //     fontSize: 16.0,
                              //     color: Colors.white,
                              //     fontFamily: 'Roboto',
                              //   ),
                              // ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          } else {
            return Container(
              // decoration: BoxDecoration(
              //   color: Colors.green,
              //   borderRadius: BorderRadius.circular(20),
              // ),
              child: ListView.builder(
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  var trip = snapshot.data!.docs[index];

                  return Card(
                    color: Colors.lightGreen,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ListTile(
                            title: Text(
                              'On Going Trip',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                                color: Colors.red, // Set the text color here
                              ),
                              textAlign: TextAlign
                                  .center, // Set the text alignment here
                            ),
                          ),
                          ListTile(
                            title: Text(
                              'Start: ${trip['startAddress']}',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'End: ${trip['destinationAddress']}',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  'Trip Time: ${_calculateTripTime(trip['startTime'])}',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18),
                                ),
                                Text(
                                  'Estimated fuel consumption : ${(trip['distance'] / double.parse(trip['dpkm'])).ceil()} L',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              ElevatedButton(
                                onPressed: () async {
                                  // Calculate trip duration
                                  DateTime start = trip['startTime'].toDate();
                                  DateTime end = DateTime.now();
                                  Duration tripDuration = end.difference(start);
                                  String formattedDuration =
                                      '${tripDuration.inHours} hours ${tripDuration.inMinutes.remainder(60)} minutes';

                                  // Update trip status to 1 (finished) and set end time
                                  trip.reference.update({
                                    'tripstatus': 1,
                                    'endTime': end,
                                    'tripDuration': formattedDuration,
                                  });

                                  Map<int, String> monthNames = {
                                    1: 'January',
                                    2: 'February',
                                    3: 'March',
                                    4: 'April',
                                    5: 'May',
                                    6: 'June',
                                    7: 'July',
                                    8: 'August',
                                    9: 'September',
                                    10: 'October',
                                    11: 'November',
                                    12: 'December',
                                  };

                                  // Get the month name from the map
                                  String vehicalId = trip['vehicleId'];
                                  double distance = trip['distance'];
                                  String destinationAddress =
                                      trip['destinationAddress'];
                                  String startAddress = trip['startAddress'];
                                  String vehicleName = trip['vehicleName'];
                                  String month =
                                      monthNames[start.month] ?? 'Unknown';
                                  await FirebaseFirestore.instance
                                      .collection('tripsforweb')
                                      .add({
                                    'startTime': start,
                                    'endTime': end,
                                    'tripDuration': formattedDuration,
                                    'userid': user.uid,
                                    'vehicalId': vehicalId,
                                    'month': month,
                                    'distance': distance,
                                    'destinationAddress': destinationAddress,
                                    'startAddress': startAddress,
                                    'vehicleName': vehicleName,

                                    // Add any other details you want to include
                                  });
                                  // Delete the activetrip document by userId
                                  await FirebaseFirestore.instance
                                      .collection('activetrips')
                                      .doc(user
                                          .uid) // Assuming userId is user.uid
                                      .delete();
                                },
                                child: Text('Finish'),
                              ),
                              SizedBox(width: 20),
                              ElevatedButton(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) {
                                      return AlertDialog(
                                        title: Text('Confirm Deletion'),
                                        content: Text(
                                            'Are you sure you want to cancel this trip?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                            child: Text('No'),
                                          ),
                                          TextButton(
                                            onPressed: () async {
                                              // Delete the trip
                                              trip.reference.delete();

                                              // Delete the activetrips document by userId
                                              await FirebaseFirestore.instance
                                                  .collection('activetrips')
                                                  .doc(user
                                                      .uid) // Assuming userId is user.uid
                                                  .delete();

                                              Navigator.of(context).pop();
                                            },
                                            child: Text('Yes'),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                                child: Text('Cancel'),
                              ),
                            ],
                          ),
                          Positioned(
                            left: 0,
                            bottom: 0,
                            child: IconButton(
                              icon: Icon(Icons.map),
                              onPressed: () {
                                launch(
                                    'https://www.google.com/maps/search/?api=1&query=${trip['destinationAddress']}');
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(20.0)),
                ),
                title: Text(
                  'Select an option',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.teal),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.orange,
                        backgroundColor: Colors.orange.shade100,
                        padding: EdgeInsets.symmetric(vertical: 15.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 5,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RefillingDetailsPage(),
                          ),
                        );
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Icon(Icons.local_gas_station,
                              color: Colors.orange, size: 35),
                          SizedBox(width: 15),
                          Text(
                            'Refilling',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.red,
                        backgroundColor: Colors.red.shade100,
                        padding: EdgeInsets.symmetric(vertical: 15.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 5,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Addexpensepage(),
                          ),
                        );
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Icon(Icons.attach_money, color: Colors.red, size: 35),
                          SizedBox(width: 15),
                          Text(
                            'Expense',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
        tooltip: 'Add New Entry',
        child: Icon(Icons.add, size: 30),
        backgroundColor: Colors.teal,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfileEditPage()),
                );
              },
              child: StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(FirebaseAuth.instance.currentUser!.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }

                  Map<String, dynamic>? userData =
                      snapshot.data!.data() as Map<String, dynamic>?;
                  String? username = userData?['username'];

                  return UserAccountsDrawerHeader(
                    accountName:
                        Text(username ?? 'John'), // Replace with actual name
                    accountEmail:
                        Text('${user.email}'), // Replace with actual email
                    currentAccountPicture: CircleAvatar(
                      backgroundImage: NetworkImage(userData?['image_url'] ??
                          ''), // Use image_url from Firestore
                    ),
                    decoration: BoxDecoration(
                      color: Color.fromRGBO(0, 103, 131, 1.0),
                    ),
                  );
                },
              ),
            ),
            ListTile(
              title: Text('Your Location'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MapPage()),
                );
              },
            ),
            ListTile(
              title: Text('Assigned tasks'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AssignTasks()),
                );
              },
            ),
            ListTile(
              title: Text('Trips '),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => TripHistoryPage()),
                );
              },
            ),
            ListTile(
              title: Text('Vehicles'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => VehicleList()),
                );
              },
            ),
            ListTile(
              title: Text('All the Drivers Map'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AllMap()),
                );
              },
              // ), ListTile(
              //   title: Text('locations'),
              //   onTap: () {
              //     Navigator.push(
              //       context,
              //       MaterialPageRoute(builder: (context) => Location()),
              //     );
              //   },
            ),
            ListTile(
              title: Text('Log out'),
              onTap: () {
                FirebaseAuth.instance.signOut();

                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AuthScreen()),
                );
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: ClipRRect(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        child: BottomAppBar(
          color: Color.fromRGBO(
              209, 239, 178, 1.0), // RGB color (red in this case)
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                icon: Icon(Icons.map),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SelectVehicle(),
                    ),
                  ); // Navigate to SelectVehicle
                },
              ),
              IconButton(
                icon: Icon(Icons.phone),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DialPadScreen(),
                    ),
                  ); // Navigate to DialPadScreen
                },
              ),
              IconButton(
                icon: Icon(Icons.chat),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => UserList()),
                  ); // Navigate to UserList
                },
              ),
              IconButton(
                icon: Icon(Icons.analytics),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => StatSection()),
                  ); // Navigate to StatSection
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
