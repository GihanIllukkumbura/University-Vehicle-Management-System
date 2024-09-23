import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'SettingTrip.dart';

class AssignTasks extends StatefulWidget {
  @override
  _AssignTasksState createState() => _AssignTasksState();
}

class _AssignTasksState extends State<AssignTasks> {
  String _selectedFilter = 'All'; // Default filter option

  Future<void> _showDeclineDialog(BuildContext context, String tripId) async {
    final TextEditingController reasonController = TextEditingController();

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Decline Trip'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Please enter a reason for declining the trip:'),
                TextField(
                  controller: reasonController,
                  decoration: InputDecoration(hintText: 'Reason'),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Submit'),
              onPressed: () async {
                final reason = reasonController.text.trim();
                if (reason.isNotEmpty) {
                  await FirebaseFirestore.instance
                      .collection('adminTrips')
                      .doc(tripId)
                      .update({
                    'unassign': 0, // Indicate the trip is declined
                    'userStatus': 'declined', // Set userStatus to declined
                    'declined': reason,
                  });
                }
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _acceptTrip(String tripId) async {
    await FirebaseFirestore.instance
        .collection('adminTrips')
        .doc(tripId)
        .update({
      'unassign': 0,
      'userStatus': 'accepted', // Set userStatus to accepted
      'unassignReason': FieldValue.delete(), // Optionally remove the reason
    });
  }

  Future<void> _deleteTrip(BuildContext context, String tripId) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Trip'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Are you sure you want to delete this trip? This action cannot be undone.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Delete'),
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('adminTrips')
                    .doc(tripId)
                    .delete();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final String? userId = FirebaseAuth.instance.currentUser?.uid;
    final DateTime today = DateTime.now();

    if (userId == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Assigned Tasks'),
        ),
        body: Center(child: Text('No user logged in.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Assigned Tasks'),
      ),
      body: Column(
        children: [
          // Dropdown for filtering
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: DropdownButton<String>(
              value: _selectedFilter,
              onChanged: (String? newValue) {
                setState(() {
                  _selectedFilter = newValue!;
                });
              },
              items: <String>['All', 'Accepted', 'Declined', 'Unassigned', 'Processing']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('adminTrips')
                  .where('driver', isEqualTo: userId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final trips = snapshot.data?.docs ?? [];

                if (trips.isEmpty) {
                  return Center(child: Text('No tasks assigned for this user.'));
                }

                final futureTrips = trips.where((doc) {
                  final tripData = doc.data() as Map<String, dynamic>;
                  final tripDate = DateTime.parse(tripData['date']);
                  return tripDate.isAfter(today) || tripDate.isAtSameMomentAs(today);
                }).toList();

                if (futureTrips.isEmpty) {
                  return Center(child: Text('No future tasks assigned for this user.'));
                }

                futureTrips.sort((a, b) {
                  final tripDateA = DateTime.parse((a.data() as Map<String, dynamic>)['date']);
                  final tripDateB = DateTime.parse((b.data() as Map<String, dynamic>)['date']);
                  return tripDateA.compareTo(tripDateB);
                });

                // Filter trips based on the selected filter
                final filteredTrips = futureTrips.where((trip) {
                  final tripData = trip.data() as Map<String, dynamic>;
                  final userStatus = tripData['userStatus'] ?? 'processing';

                  switch (_selectedFilter) {
                    case 'Accepted':
                      return userStatus == 'accepted';
                    case 'Declined':
                      return userStatus == 'declined';
                    case 'Unassigned':
                      return userStatus == 'unassigned' || userStatus == null;
                    case 'Processing':
                      return userStatus == 'processing';
                    default:
                      return true; // 'All' option
                  }
                }).toList();

                return ListView.builder(
                  itemCount: filteredTrips.length,
                  itemBuilder: (context, index) {
                    final taskData = filteredTrips[index].data() as Map<String, dynamic>;
                    final vehicleId = taskData['vehicle'];
                    final tripDate = DateTime.parse(taskData['date']);
                    final tripTime = taskData['time'];
                    final countdown = tripDate.difference(today);
                    final userStatus = taskData['userStatus'] ?? 'processing'; // Default to processing if not set
                    final tripId = filteredTrips[index].id;

                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance.collection('vehicles').doc(vehicleId).get(),
                      builder: (context, vehicleSnapshot) {
                        if (vehicleSnapshot.connectionState == ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        }

                        if (vehicleSnapshot.hasError) {
                          return Center(child: Text('Error: ${snapshot.error}'));
                        }

                        if (!vehicleSnapshot.hasData || !vehicleSnapshot.data!.exists) {
                          return Center(child: Text('Vehicle data not found.'));
                        }

                        final vehicleData = vehicleSnapshot.data!.data() as Map<String, dynamic>;

                        // Inside the itemBuilder where the trip cards are created
                        return Card(
                          margin: EdgeInsets.all(10),
                          color: taskData['unassign'] == 1 ? Colors.red[100] : Colors.white, // Set red color for unassigned trips
                          child: Stack(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(15.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: userStatus == 'declined'
                                                ? Colors.red
                                                : (userStatus == 'accepted'
                                                ? Colors.green
                                                : Colors.yellow),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Column(
                                            children: [
                                              Text(
                                                '${countdown.inDays}d',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Text(
                                                '${countdown.inHours % 24}h ${countdown.inMinutes % 60}m',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                taskData['destination'] ?? '',
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              SizedBox(height: 10),
                                              Text(taskData['description'] ?? ''),
                                              SizedBox(height: 10),
                                              Text('Date: ${DateFormat.yMMMd().format(tripDate)}'),
                                              SizedBox(height: 10),
                                              Text('Time: $tripTime'),
                                              SizedBox(height: 10),
                                              Text('Vehicle: ${vehicleData['model'] ?? 'Unknown'}'),
                                              if (userStatus == 'declined') ...[
                                                SizedBox(height: 10),
                                                Text('Declined Reason: ${taskData['declined'] ?? 'No reason provided'}'),
                                              ],
                                              if (taskData['unassign'] == 1) ...[
                                                SizedBox(height: 10),
                                                Text('Unassigned Reason: ${taskData['unassignReason'] ?? 'No reason provided'}'),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 10),
                                    // If unassign is 1 or the trip is still processing, don't show Decline/Accept buttons, otherwise show them
                                    if (taskData['unassign'] != 1 && userStatus == 'processing')
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          ElevatedButton(
                                            onPressed: () {
                                              _showDeclineDialog(context, tripId);
                                            },
                                            child: Text('Decline'),
                                          ),
                                          SizedBox(width: 10),
                                          ElevatedButton(
                                            onPressed: () async {
                                              await _acceptTrip(tripId);
                                            },
                                            child: Text('Accept'),
                                          ),
                                        ],
                                      ),
                                    // If the user has accepted the trip and it's not unassigned, show the "Start Trip" button
                                    if (userStatus == 'accepted' && taskData['unassign'] != 1)
                                      ElevatedButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => NewSettingTrip(
                                                selectedVehicleId: vehicleId,
                                                selectedVehicleName: vehicleData['model'] ?? 'Unknown',
                                                selectedVehicledpkm: vehicleData['dpkm'] ?? 'Unknown',
                                              ),
                                            ),
                                          );
                                        },
                                        child: Text('Start Trip'),
                                      ),
                                  ],
                                ),
                              ),
                              if (userStatus == 'declined')
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: Container(
                                    padding: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.only(
                                        bottomLeft: Radius.circular(15),
                                      ),
                                    ),
                                    child: Text(
                                      'Declined',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              if (userStatus == 'accepted')
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: Container(
                                    padding: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      borderRadius: BorderRadius.only(
                                        bottomLeft: Radius.circular(15),
                                      ),
                                    ),
                                    child: Text(
                                      'Accepted',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              // Display the bin icon for both declined and unassigned trips
                              if (userStatus == 'declined' || taskData['unassign'] == 1)
                                Positioned(
                                  bottom: 10,
                                  right: 10,
                                  child: IconButton(
                                    icon: Icon(Icons.delete, color: Colors.red),
                                    onPressed: () {
                                      _deleteTrip(context, tripId);
                                    },
                                  ),
                                ),
                            ],
                          ),
                        );


                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
