// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
//
// class AddExpensePage extends StatefulWidget {
//   @override
//   _AddExpensePageState createState() => _AddExpensePageState();
// }
//
// class _AddExpensePageState extends State<AddExpensePage> {
//   final _formKey = GlobalKey<FormState>();
//   final TextEditingController _expenseTypeController = TextEditingController();
//   final TextEditingController _amountController = TextEditingController();
//   final TextEditingController _dateController = TextEditingController();
//
//   void _addExpense() async {
//     if (_formKey.currentState!.validate()) {
//       User? user = FirebaseAuth.instance.currentUser;
//       if (user != null) {
//         FirebaseFirestore.instance.collection('expenses').add({
//           'userId': user.uid,
//           'expenseType': _expenseTypeController.text,
//           'amount': double.parse(_amountController.text),
//           'date': _dateController.text,
//         });
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Expense Added')),
//         );
//         _expenseTypeController.clear();
//         _amountController.clear();
//         _dateController.clear();
//       }
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('Add Expense')),
//       body: Padding(
//         padding: EdgeInsets.all(16.0),
//         child: SingleChildScrollView(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Form(
//                 key: _formKey,
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     TextFormField(
//                       controller: _expenseTypeController,
//                       decoration: InputDecoration(labelText: 'Expense Type'),
//                       validator: (value) {
//                         if (value!.isEmpty) {
//                           return 'Please enter expense type';
//                         }
//                         return null;
//                       },
//                     ),
//                     TextFormField(
//                       controller: _amountController,
//                       decoration: InputDecoration(labelText: 'Amount'),
//                       keyboardType: TextInputType.number,
//                       validator: (value) {
//                         if (value!.isEmpty) {
//                           return 'Please enter amount';
//                         }
//                         if (double.tryParse(value) == null) {
//                           return 'Please enter a valid number';
//                         }
//                         return null;
//                       },
//                     ),
//                 GestureDetector(
//                   onTap: () async {
//                     final DateTime? picked = await showDatePicker(
//                       context: context,
//                       initialDate: DateTime.now(),
//                       firstDate: DateTime(2015, 8),
//                       lastDate: DateTime(2101),
//                     );
//                     if (picked != null) {
//                       _dateController.text = picked.toString();
//                     }
//                   },
//                   child: AbsorbPointer(
//                     child: TextFormField(
//                       controller: _dateController,
//                       decoration: InputDecoration(labelText: 'Date'),
//                       validator: (value) {
//                         if (value!.isEmpty) {
//                           return 'Please enter date';
//                         }
//                         return null;
//                       },
//                     ),
//                   ),
//                 ),
//
//
//                     SizedBox(height: 20),
//                     ElevatedButton(
//                       onPressed: _addExpense,
//                       child: Text('Add Expense'),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
