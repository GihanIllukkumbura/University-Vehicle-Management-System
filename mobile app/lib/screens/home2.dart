// import 'dart:async';
//
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:firebasefluttter/screens/auth.dart';
// import 'package:firebasefluttter/screens/refilling.dart';
// import 'package:firebasefluttter/screens/selectVehical.dart';
// import 'package:flutter/material.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:intl/intl.dart';
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
// class RefillingInfo {
//   String refillingDetails;
//   int mileage;
//   DateTime date;
//
//   RefillingInfo({required this.refillingDetails, required this.mileage, required this.date});
// }
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
//
//   void _addRefilling(RefillingInfo info) {
//     FirebaseFirestore.instance
//         .collection('refillings')
//         .doc(user.uid)
//         .collection('info')
//         .add({
//       'refillingDetails': info.refillingDetails,
//       'mileage': info.mileage,
//       'date': info.date,
//     });
//   }
//
//   Widget _buildRefillingList() {
//     return StreamBuilder<QuerySnapshot>(
//       stream: FirebaseFirestore.instance
//           .collection('refillings')
//           .doc(user.uid)
//           .collection('info')
//           .orderBy('date', descending: true)
//           .snapshots(),
//       builder: (context, snapshot) {
//         if (!snapshot.hasData) {
//           return Center(child: CircularProgressIndicator());
//         }
//
//         List<RefillingInfo> refillings = [];
//         snapshot.data!.docs.forEach((doc) {
//           refillings.add(RefillingInfo(
//             refillingDetails: doc['refillingDetails'],
//             mileage: doc['mileage'],
//             date: doc['date'].toDate(),
//           ));
//         });
//
//         return ListView.builder(
//           itemCount: refillings.length,
//           itemBuilder: (context, index) {
//             final item = refillings[index];
//             final formattedDate = DateFormat.yMMMd().format(item.date);
//             final monthColor = Colors.primaries[item.date.month % Colors.primaries.length];
//             final daysAgo = DateTime.now().difference(item.date).inDays;
//             return Column(
//               children: [
//                 ListTile(
//                   leading: Container(
//                     padding: EdgeInsets.all(8.0),
//                     decoration: BoxDecoration(
//                       color: Colors.orange,
//                       shape: BoxShape.circle,
//                     ),
//                     child: Icon(Icons.local_gas_station, color: Colors.white), // Fuel pump icon
//                   ),
//                   title: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         item.refillingDetails,
//                         style: TextStyle(color: monthColor),
//                       ),
//                       Text(
//                         'Mileage: ${item.mileage}',
//                         style: TextStyle(color: monthColor),
//                       ),
//                     ],
//                   ),
//                   subtitle: Column(
//                     crossAxisAlignment: CrossAxisAlignment.end,
//                     children: [
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.end,
//                         children: [
//                           Text(
//                             formattedDate,
//                             style: TextStyle(color: monthColor),
//                           ),
//                         ],
//                       ),
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.end,
//                         children: [
//                           Text(
//                             '$daysAgo days ago',
//                             style: TextStyle(color: item.date.month == DateTime.now().month ? Colors.green : Colors.red),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                   onTap: () {
//                     // Handle onTap
//                   },
//                 ),
//                 Divider(), // Add a horizontal line
//               ],
//             );
//           },
//         );
//       },
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Refilling App'),
//       ),
//       body: _buildRefillingList(),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () {
//           showDialog(
//             context: context,
//             builder: (BuildContext context) {
//               return AlertDialog(
//                 title: Text('Select an Option'),
//                 content: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: <Widget>[
//                     TextButton(
//                       onPressed: () {
//                         Navigator.pop(context);
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (context) => RefillingDetailsPage(
//                               onAddRefilling: _addRefilling,
//                             ),
//                           ),
//                         );
//                       },
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Icon(Icons.local_gas_station, color: Colors.orange),
//                           Text('Refilling'),
//                         ],
//                       ),
//                     ),
//                     TextButton(
//                       onPressed: () {
//                         // Navigate to expense page
//                       },
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Icon(Icons.attach_money, color: Colors.red),
//                           Text('Expense'),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               );
//             },
//           );
//         },
//         tooltip: 'Increment',
//         child: Icon(Icons.add),
//       ),
//       floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
//     );
//   }
// }
//
// class RefillingDetailsPage extends StatefulWidget {
//   final Function(RefillingInfo) onAddRefilling;
//
//   RefillingDetailsPage({required this.onAddRefilling});
//
//   @override
//   _RefillingDetailsPageState createState() => _RefillingDetailsPageState();
// }
//
// class _RefillingDetailsPageState extends State<RefillingDetailsPage> {
//   TextEditingController _detailsController = TextEditingController();
//   TextEditingController _mileageController = TextEditingController();
//   late DateTime _selectedDate;
//
//   @override
//   void initState() {
//     super.initState();
//     _selectedDate = DateTime.now();
//   }
//
//   @override
//   void dispose() {
//     _detailsController.dispose();
//     _mileageController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Refilling Details'),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             TextField(
//               controller: _detailsController,
//               decoration: InputDecoration(
//                 labelText: 'Enter refilling details',
//               ),
//             ),
//             SizedBox(height: 16.0),
//             TextField(
//               controller: _mileageController,
//               keyboardType: TextInputType.number,
//               decoration: InputDecoration(
//                 labelText: 'Enter mileage',
//               ),
//             ),
//             SizedBox(height: 16.0),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text('Date: ${DateFormat.yMMMd().format(_selectedDate)}'),
//                 IconButton(
//                   icon: Icon(Icons.calendar_today),
//                   onPressed: () async {
//                     final DateTime? pickedDate = await showDatePicker(
//                       context: context,
//                       initialDate: _selectedDate,
//                       firstDate: DateTime(2000),
//                       lastDate: DateTime.now(),
//                     );
//                     if (pickedDate != null && pickedDate != _selectedDate) {
//                       setState(() {
//                         _selectedDate = pickedDate;
//                       });
//                     }
//                   },
//                 ),
//               ],
//             ),
//             SizedBox(height: 16.0),
//             ElevatedButton(
//               onPressed: () {
//                 String details = _detailsController.text;
//                 int mileage = int.tryParse(_mileageController.text) ?? 0;
//                 if (details.isNotEmpty && mileage > 0) {
//                   widget.onAddRefilling(RefillingInfo(refillingDetails: details,
//                       mileage: mileage,
//                       date: _selectedDate));
//                   Navigator.pop(context);
//                 }
//               },
//               child: Text('Save'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
