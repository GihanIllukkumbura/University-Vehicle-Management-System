// class ProfileEditPage extends StatefulWidget {
//   @override
//   _ProfileEditPageState createState() => _ProfileEditPageState();
// }
//
// class _ProfileEditPageState extends State<ProfileEditPage> {
//   String _username = '';
//   String _email = '';
//   String _phoneNumber = '';
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Edit Profile'),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Center(
//               child: Stack(
//                 children: [
//                   CircleAvatar(
//                     radius: 50,
//                     backgroundImage: AssetImage('assets/images/profile.jpg'), // Replace with actual image path
//                   ),
//                   Positioned(
//                     bottom: 0,
//                     right: 0,
//                     child: IconButton(
//                       icon: Icon(Icons.edit),
//                       onPressed: () {
//                         // Implement logic to edit profile picture
//                       },
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             SizedBox(height: 16.0),
//             TextFormField(
//               decoration: InputDecoration(
//                 labelText: 'Username',
//               ),
//               onChanged: (value) {
//                 setState(() {
//                   _username = value;
//                 });
//               },
//             ),
//             SizedBox(height: 16.0),
//             TextFormField(
//               decoration: InputDecoration(
//                 labelText: 'Email',
//               ),
//               onChanged: (value) {
//                 setState(() {
//                   _email = value;
//                 });
//               },
//             ),
//             SizedBox(height: 16.0),
//             TextFormField(
//               decoration: InputDecoration(
//                 labelText: 'Phone Number',
//               ),
//               onChanged: (value) {
//                 setState(() {
//                   _phoneNumber = value;
//                 });
//               },
//             ),
//             SizedBox(height: 16.0),
//             Center(
//               child: ElevatedButton(
//                 onPressed: () {
//                   // Save the changes to Firestore
//                   // You can implement this part based on your Firestore setup
//                   Navigator.pop(context);
//                 },
//                 child: Text('Save Changes'),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
