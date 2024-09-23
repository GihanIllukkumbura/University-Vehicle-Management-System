import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class TripHistoryPage extends StatefulWidget {
  const TripHistoryPage({Key? key}) : super(key: key);

  @override
  _TripHistoryPageState createState() => _TripHistoryPageState();
}

class _TripHistoryPageState extends State<TripHistoryPage> {
  late Future<List<DocumentSnapshot>?> _tripHistoryFuture;
  List<Map<String, dynamic>> _allTrips = [];
  List<Map<String, dynamic>> _filteredTrips = [];
  List<String> _filterOptions = [];

  @override
  void initState() {
    super.initState();
    _loadTripHistory();
  }

  Future<void> _loadTripHistory() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userId = user.uid;
      final snapshot = await FirebaseFirestore.instance
          .collection('trips')
          .doc(userId)
          .collection('userTrips')
          .orderBy('startTime', descending: true)
          .get();

      // Extract and set filter options (distinct year-month combinations)
      Set<String> filterSet = snapshot.docs.map((doc) {
        DateTime startTime = (doc['startTime'] as Timestamp).toDate();
        return '${startTime.year}-${startTime.month}';
      }).toSet();
      _filterOptions = filterSet.toList()..sort((a, b) => b.compareTo(a));

      setState(() {
        _allTrips = snapshot.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList();
        _filteredTrips =
            List.from(_allTrips); // Initialize _filteredTrips with all trips
      });
    }
  }

  Widget _buildTripInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _showTripDetails(BuildContext context, Map<String, dynamic> trip) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(trip['date'] ?? ''),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTripInfo('Start Address', trip['startAddress'] ?? ''),
            _buildTripInfo(
                'Destination Address', trip['destinationAddress'] ?? ''),
            _buildTripInfo(
              'Distance',
              trip['distance'] != null
                  ? '${(trip['distance'] as double).round()} km'
                  : '',
            ),
            _buildTripInfo(
              'Start Date',
              trip['startTime'] != null
                  ? DateFormat('MMMM d, yyyy')
                      .format(trip['startTime'].toDate())
                  : '',
            ),
            _buildTripInfo(
              'Start Time',
              trip['startTime'] != null
                  ? DateFormat.Hm().format(trip['startTime'].toDate())
                  : '',
            ),
            _buildTripInfo('Vehicle Used', trip['vehicleName'] ?? ''),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _filterTrips(String selectedFilter) {
    setState(() {
      _filteredTrips = _allTrips.where((trip) {
        DateTime startTime = (trip['startTime'] as Timestamp).toDate();
        String filterString = '${startTime.year}-${startTime.month}';
        return filterString == selectedFilter;
      }).toList();
    });
  }

  void _resetFilter() {
    setState(() {
      _filteredTrips = List.from(_allTrips);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Trip History'),
      ),
      body: Container(
        color: Colors.grey.shade100,
        child: Column(
          children: [
            if (_filterOptions.isNotEmpty)
              DropdownButtonFormField<String>(
                value: _filterOptions.isNotEmpty ? _filterOptions[0] : null,
                items: _filterOptions.map((option) {
                  return DropdownMenuItem<String>(
                    value: option,
                    child: Text(option),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    if (value == 'All') {
                      _resetFilter();
                    } else {
                      _filterTrips(value);
                    }
                  }
                },
              ),
            Expanded(
              child: ListView.builder(
                itemCount: _filteredTrips.length,
                itemBuilder: (context, index) {
                  var trip = _filteredTrips[index];
                  return GestureDetector(
                    onTap: () => _showTripDetails(context, trip),
                    child: Card(
                      color: Color.fromRGBO(229, 253, 207, 1.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      margin: EdgeInsets.all(8.0),
                      elevation: 2.0,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ListTile(
                          title: Text(
                            trip['date'] ?? '',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildTripInfo(
                                  'Start Address', trip['startAddress'] ?? ''),
                              _buildTripInfo('Destination Address',
                                  trip['destinationAddress'] ?? ''),
                              _buildTripInfo(
                                'Distance',
                                trip['distance'] != null
                                    ? '${(trip['distance'] as double).round()} km'
                                    : '',
                              ),
                              _buildTripInfo(
                                'Start Date',
                                trip['startTime'] != null
                                    ? DateFormat('MMMM d, yyyy')
                                        .format(trip['startTime'].toDate())
                                    : '',
                              ),
                              _buildTripInfo(
                                'Start Time',
                                trip['startTime'] != null
                                    ? DateFormat.Hm()
                                        .format(trip['startTime'].toDate())
                                    : '',
                              ),
                              _buildTripInfo(
                                  'Vehicle Used', trip['vehicleName'] ?? ''),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
