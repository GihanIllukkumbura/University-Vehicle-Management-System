const express = require('express');
const router = express();
const admin = require('firebase-admin');
const db = admin.firestore();
const Vehicle = require('../models/Vehicle');
const serviceAccount = require('../key.json');
const multer = require('multer');
const fs = require('fs');
const path = require('path');




router.get('/Drivers', async (req, res) => {
  try {
    // Retrieve all vehicle data from Firestore
    const snapshot = await db.collection('users').get();

    // Map the snapshot documents to an array of vehicle objects
    const drivers = snapshot.docs
      .map(doc => ({ id: doc.id, ...doc.data() }))
      .filter(driver => driver.role !== 'admin'); // Filter out drivers with role admin

  

    // Render your view or send the retrieved data to the client
    res.render('Drivers', { drivers });
  } catch (error) {
    console.error('Error fetching vehicle data:', error);
    req.flash('error', 'Error fetching vehicle data');
    res.redirect('/'); // Redirect to the desired route or handle the error accordingly
  }
});



// remove user
// router.delete('/del/:id', async (req, res) => {
//   const userid = req.params.id; // Get the user ID from the request parameters

//   try {
//     // Delete the user document from Firestore if it exists
//     await db.collection('users').doc(userid).delete();

//     // Delete other related documents
//     const collectionsToDelete = ['locations','trips', 'refillings', 'chats' ];
//     for (const collectionName of collectionsToDelete) {
//       const docRef = db.collection(collectionName).doc(userid);
//       const docSnapshot = await docRef.get();
//       if (!docSnapshot.exists) {
//         await docRef.delete();
//       }
//     }

//     // Delete the user from authentication
//     await admin.auth().deleteUser(userid);

//     // Redirect to the table or any other page
//     res.redirect('/table');
  
//   } catch (err) {
//     console.error('Error deleting User:', err);
//     req.flash('error', 'Error deleting user');
//     res.redirect('/'); // Redirect to the home page with an error message
//   }
// });


router.delete('/del/:id', async (req, res) => {
  const userid = req.params.id; // Get the user ID from the request parameters

  try {
    const userId = req.session.userId;

  if (!userId) {
    console.log('User ID not found in session');
    res.render('login', { error: 'User ID not found in session, please log in again' });
    return;
  }
    // Delete the user document from Firestore if it exists
    await db.collection('users').doc(userid).delete();

    // Delete the user from other collections
    const collectionsToDelete = ['locations', 'trips', 'refillings']; // Add other collection names here
    await Promise.all(collectionsToDelete.map(async (collectionName) => {
      const collectionRef = db.collection(collectionName);
      const docRef = collectionRef.doc(userid);
      const docSnapshot = await docRef.get();
  
      if (docSnapshot.exists) {
        await docRef.delete();
        console.log(`Deleted document with userid ${userid} from collection ${collectionName}`);
      } else {
        console.log(`No document found with userid ${userid} in collection ${collectionName}`);
      }
    }));

    // Delete the user from authentication
    await admin.auth().deleteUser(userid);

    // Redirect to the table or any other page
    res.redirect('/');

  } catch (err) {
    console.error('Error deleting User:', err);
    req.flash('error', 'Error deleting user');
    res.redirect('/'); // Redirect to the home page with an error message
  }
});






// add user 

router.get('/adduser', (req, res) => {
  res.render('addUsers');
});


// get email and password

router.post('/adduser', async (req, res) => {
  const { email, password, cpassword } = req.body;

  try {
    // Check if email is already registered
    const userExists = await admin.auth().getUserByEmail(email).catch(() => null);
    if (userExists) {
      throw new Error('Email is already registered');
    }

    // Check if password matches confirm password
    if (password !== cpassword) {
      throw new Error('Passwords do not match');
    }

    // Create user in Firebase Authentication
    const userRecord = await admin.auth().createUser({
      email: email,
      password: password,
    });

    // Save user details to Firestore collection
    await db.collection('users').doc(userRecord.uid).set({
      email: email,
    });

    // Redirect to table or any other page
    res.redirect('/');

  } catch (err) {
    console.error('Error creating user:', err);
    req.flash('error', err.message);
    res.render('/', { error: req.flash('error') });
  }
});










// const empDataSnapshot = await db.collection('users').get();
      
// const empData = empDataSnapshot.docs.map(doc => {
//   const data = doc.data();
//   data.id = doc.id;
//   return data;
// });
// console.log(empData);
// empData.forEach(data => {
// console.log(data.id);
// });







// refilling data

router.get('/Driver/:id/refillingDetails', async (req, res) => {
  const userid = req.params.id;

  try {
    const refillingSnapshot = await db.collection('refillingforweb').where('userid', '==', userid).get();
    const refillingDetails = refillingSnapshot.docs.map(doc => doc.data());

    const Tripsanpshot = await db.collection('tripsforweb').where('userid', '==', userid).get();
    const tripdata = Tripsanpshot.docs.map(doc => doc.data());

    res.render('Driverrefilling', { userid, refillingDetails,tripdata });
  } catch (err) {
    console.error('Error fetching refilling details:', err);
    res.status(500).send('Internal server error');
  }
});

































// mapRouter.get('/map', (req, res) => {
//   db.collection('locations').doc('user_location').get()
//     .then((doc) => {
//       if (doc.exists) {
//         const data = doc.data();
//         res.render('map', { latitude: data.latitude, longitude: data.longitude });
//       } else {
//         console.log('No such document');
//         res.status(404).send('Location data not found');
//       }
//     })
//     .catch((error) => {
//       console.error('Error getting document:', error);
//       res.status(500).send('Error getting location data');
//     });
// });



// mapRouter.get('/map', (req, res) => {
//   db.collection('locations').doc('user_location').get()
//     .then((doc) => {
//       if (doc.exists) {
//         const data = doc.data();
//         res.render('map', { latitude: data.latitude, longitude: data.longitude });
//       } else {
//         console.log('No such document');
//         res.status(404).send('Location data not found');
//       }
//     })
//     .catch((error) => {
//       console.error('Error getting document:', error);
//       res.status(500).send('Error getting location data');
//     });

//   // Set up Firestore listener for continuous updates
//   db.collection('locations').doc('user_location').onSnapshot((doc) => {
//     const data = doc.data();
//     // Emit an event or send a message to the client to update the location
//     // For simplicity, let's assume there's a function to send data to the client
//     sendLocationDataToClient({ latitude: data.latitude, longitude: data.longitude });
//   });
// });







module.exports = router;