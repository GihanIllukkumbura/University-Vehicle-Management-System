import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

const String googleApiKey = '';

class AllMap extends StatefulWidget {
  const AllMap({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends State<AllMap> {
  GoogleMapController? mapController;
  Map<MarkerId, Marker> markers = {};
  Set<Circle> circles = {};
  LatLngBounds? bounds;
  late Position currentLocation;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _fetchUsersLocations();
  }

  void _getCurrentLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        currentLocation = position;
      });
    } else {
      print('Location permission not granted');
    }
  }

  void _fetchUsersLocations() {
    FirebaseFirestore.instance
        .collection('locations')
        .snapshots()
        .listen((snapshot) {
      snapshot.docChanges.forEach((change) {
        final DocumentSnapshot document = change.doc;
        final String userId = document.id;
        final Map<String, dynamic> data =
            document.data() as Map<String, dynamic>;

        if (data.containsKey('latitude') && data.containsKey('longitude')) {
          final double latitude = data['latitude'] as double;
          final double longitude = data['longitude'] as double;

          // Get the username from the "users" collection
          String username = 'User'; // Default username if not found
          FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get()
              .then((userSnapshot) {
            if (userSnapshot.exists) {
              Map<String, dynamic> userData =
                  userSnapshot.data() as Map<String, dynamic>;
              if (userData.containsKey('username')) {
                username = userData['username'] as String;
              }
            }

            final MarkerId markerId = MarkerId(userId);
            final Marker marker = Marker(
              markerId: markerId,
              position: LatLng(latitude, longitude),
              infoWindow: InfoWindow(title: username),
              icon: BitmapDescriptor.defaultMarker,
            );

            setState(() {
              markers[markerId] = marker;
            });
          });
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      markers: Set<Marker>.of(markers.values),
      circles: circles,
      initialCameraPosition: CameraPosition(
        target: LatLng(7.2, 80.7),
        zoom: 8.33,
      ),
      myLocationEnabled: true,
      onMapCreated: (GoogleMapController controller) {
        mapController = controller;
      },
    );
  }
}
