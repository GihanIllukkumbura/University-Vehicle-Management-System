import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ExpensePage extends StatefulWidget {
  @override
  _ExpensePageState createState() => _ExpensePageState();
}

class _ExpensePageState extends State<ExpensePage> {
  late Stream<QuerySnapshot> _expensesStream;
  String? selectedYearMonth;

  @override
  void initState() {
    super.initState();
    _expensesStream = FirebaseFirestore.instance
        .collection('expense')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection('userexpense')
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: _expensesStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No expenses found'));
          }

          var expenses = snapshot.data!.docs;
          expenses.sort((a, b) =>
              (b['date'] as Timestamp).compareTo(a['date'] as Timestamp));

          // Calculate total cost
          double totalCost =
              expenses.fold(0, (sum, expense) => sum + expense['cost']);

          // Filter expenses based on selected year and month
          var filteredExpenses = selectedYearMonth == null
              ? expenses
              : expenses.where((expense) {
                  var date = (expense['date'] as Timestamp).toDate();
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
                      items: _buildYearMonthDropdownItems(expenses),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filteredExpenses.length,
                      itemBuilder: (context, index) {
                        var data = filteredExpenses[index].data()
                            as Map<String, dynamic>;
                        var documentId =
                            filteredExpenses[index].id; // Get the document ID
                        return Card(
                          margin: EdgeInsets.symmetric(
                              vertical: 8.0, horizontal: 16.0),
                          elevation: 4.0,
                          child: ListTile(
                            leading: Icon(Icons.attach_money,
                                color: Colors.green, size: 35),
                            title: Text(DateFormat.yMMMd()
                                .format(data['date'].toDate())),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Details: ${data['expensedetails']}'),
                                // Text('Vehicle ID: ${data['vehicleId']}'),
                                Text(
                                    'Registered Number: ${data['registeredNumber']}'),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'RS ${data['cost']}',
                                  style: TextStyle(
                                      color: Colors.red, fontSize: 16.0),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete,
                                      color: Colors.redAccent),
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
                                                FirebaseFirestore.instance
                                                    .collection('expense')
                                                    .doc(FirebaseAuth.instance
                                                        .currentUser!.uid)
                                                    .collection('userexpense')
                                                    .doc(documentId)
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
                              ],
                            ),
                            isThreeLine: true,
                          ),
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
      List<DocumentSnapshot> expenses) {
    Set<String> yearMonths = expenses.map((expense) {
      var date = (expense['date'] as Timestamp).toDate();
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
