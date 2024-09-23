import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import 'chartPage.dart';
import 'expense page.dart';

class StatSection extends StatelessWidget {
  final user = FirebaseAuth.instance.currentUser!;
  final List<String> tabs = ['Refilling Info', 'Charts', 'Expense'];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Your Stats'),
          bottom: TabBar(
            tabs: tabs.map((title) => Tab(text: title)).toList(),
          ),
        ),
        body: TabBarView(
          children: [
            RefillingInfoPage(),
            ChartsPage(),
            ExpensePage(),
          ],
        ),
      ),
    );
  }
}

class RefillingInfoPage extends StatefulWidget {
  @override
  _RefillingInfoPageState createState() => _RefillingInfoPageState();
}

class _RefillingInfoPageState extends State<RefillingInfoPage> {
  late Stream<QuerySnapshot> _refillingsStream;
  String? selectedYearMonth;

  @override
  void initState() {
    super.initState();
    _refillingsStream = FirebaseFirestore.instance
        .collection('refillings')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection('userfillings')
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: _refillingsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No refilling history'));
          }
          var refillings = snapshot.data!.docs;
          refillings.sort((a, b) =>
              (b['date'] as Timestamp).compareTo(a['date'] as Timestamp));

          // Calculate total price
          double totalPrice = refillings.fold(0, (sum, refill) {
            return sum + (refill['liters'] * refill['priceperliter']);
          });

          // Calculate total liters filled per day
          Map<String, double> litersFilledPerDay = {};
          refillings.forEach((refilling) {
            var date = (refilling['date'] as Timestamp).toDate();
            var dateString = '${date.year}-${date.month}-${date.day}';
            litersFilledPerDay[dateString] =
                (litersFilledPerDay[dateString] ?? 0) +
                    (refilling['liters'] as double);
          });

          // Filter refillings based on selected year and month
          var filteredRefillings = selectedYearMonth == null
              ? refillings
              : refillings.where((refilling) {
                  var date = (refilling['date'] as Timestamp).toDate();
                  var yearMonth =
                      '${date.year}-${date.month.toString().padLeft(2, '0')}';
                  return yearMonth == selectedYearMonth;
                }).toList();

          return Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Add year-month selection UI
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: DropdownButton<String>(
                      hint: Text('Select Month'),
                      value: selectedYearMonth,
                      onChanged: (newYearMonth) {
                        setState(() {
                          selectedYearMonth = newYearMonth;
                        });
                      },
                      items: _buildYearMonthDropdownItems(refillings),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filteredRefillings.length,
                      itemBuilder: (context, index) {
                        var data = filteredRefillings[index].data()
                            as Map<String, dynamic>;
                        var documentId =
                            filteredRefillings[index].id; // Get the document ID
                        return Stack(
                          children: [
                            ListTile(
                              leading: Icon(Icons.local_gas_station,
                                  color: Colors.orange, size: 35),
                              title: Text(DateFormat.yMMMd()
                                  .format(data['date'].toDate())),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Station: ${data['refillingDetails']}'),
                                  Text('Liters: ${data['liters']}'),
                                  Text(
                                      'Registered Number: ${data['registeredNumber']}'),
                                ],
                              ),
                            ),
                            Positioned(
                              top: 16.0,
                              right: 16.0,
                              child: Text(
                                'Total Price: RS ${data['totalCost']}',
                                style: TextStyle(
                                    color: Colors.deepOrange, fontSize: 16.0),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: IconButton(
                                icon: Icon(Icons.delete,
                                    color: Colors.redAccent, size: 29),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) {
                                      return AlertDialog(
                                        title: Text('Confirm Deletion'),
                                        content: Text(
                                            'Are you sure you want to delete this entry?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                            child: Text('No'),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              // Delete the entry from Firestore
                                              FirebaseFirestore.instance
                                                  .collection('refillings')
                                                  .doc(FirebaseAuth.instance
                                                      .currentUser!.uid)
                                                  .collection('userfillings')
                                                  .doc(
                                                      documentId) // Use the document ID
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
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  List<DropdownMenuItem<String>> _buildYearMonthDropdownItems(
      List<DocumentSnapshot> refillings) {
    Set<String> yearMonths = refillings.map((refilling) {
      var date = (refilling['date'] as Timestamp).toDate();
      return '${date.year}-${date.month.toString().padLeft(2, '0')}';
    }).toSet();

    return yearMonths
        .map((yearMonth) => DropdownMenuItem<String>(
              value: yearMonth,
              child: Text(DateFormat.yMMM().format(DateTime(
                  int.parse(yearMonth.split('-')[0]),
                  int.parse(yearMonth.split('-')[1])))),
            ))
        .toList();
  }
}
