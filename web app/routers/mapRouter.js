const express = require('express');
const router = express();
const admin = require('firebase-admin');
const db = admin.firestore();
const Vehicle = require('../models/Vehicle');
const serviceAccount = require('../key.json');
const multer = require('multer');
const fs = require('fs');
const path = require('path');


// const WebSocket = require('ws');
// const expressWs = require('express-ws');
// expressWs(router);

// // WebSocket server
// const wss = new WebSocket.Server({ noServer: true });

// // WebSocket connection
// wss.on('connection', (ws) => {
//   console.log('WebSocket connected');

//   // Firestore listener for location updates
//   const docRef = db.collection('locations').doc('user_location');
//   const listener = docRef.onSnapshot((doc) => {
//     const data = doc.data();
//     if (data) {
//       ws.send(JSON.stringify({ latitude: data.latitude, longitude: data.longitude }));
//     }
//   });

//   // WebSocket close event
//   ws.on('close', () => {
//     console.log('WebSocket disconnected');
//     listener(); // Stop Firestore listener when WebSocket is closed
//   });
// });


// // Express route
// router.get('/map', (req, res) => {
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
// // Upgrade HTTP to WebSocket
// // WebSocket route
// router.ws('/map', (ws, req) => {
//   ws.on('message', (message) => {
//     console.log('Received message from client:', message);
//   });

//   // Firestore listener for location updates
//   const docRef = db.collection('locations').doc('user_location');
//   const listener = docRef.onSnapshot((doc) => {
//     const data = doc.data();
//     if (data) {
//       ws.send(JSON.stringify({ latitude: data.latitude, longitude: data.longitude }));
//     }
//   });

//   // WebSocket close event
//   ws.on('close', () => {
//     console.log('WebSocket disconnected');
//     listener(); // Stop Firestore listener when WebSocket is closed
//   });
// });




const WebSocket = require('ws');
const expressWs = require('express-ws');
expressWs(router);

// WebSocket server
const wss = new WebSocket.Server({ noServer: true });

// WebSocket connection
wss.on('connection', (ws) => {
  console.log('WebSocket connected');

  // Extracting the id from the URL
  const url = new URL(ws.upgradeReq.url, 'http://localhost:200');
  const userId = url.searchParams.get('id');

  // Firestore listener for location updates
  const docRef = db.collection('locations').doc(userId);
  const listener = docRef.onSnapshot((doc) => {
    const data = doc.data();
    if (data) {
      ws.send(JSON.stringify({ latitude: data.latitude, longitude: data.longitude }));
    }
  });

  // WebSocket close event
  ws.on('close', () => {
    console.log('WebSocket disconnected');
    listener(); // Stop Firestore listener when WebSocket is closed
  });
});


// Express route
router.get('/map/:id', (req, res) => {
  const userId = req.params.id;
  res.render('maplocation', { userId });
});

// WebSocket route
router.ws('/map/:id', (ws, req) => {
  const userId = req.params.id;
  const docRef = db.collection('locations').doc(userId);
  const listener = docRef.onSnapshot((doc) => {
    const data = doc.data();
    if (data) {
      ws.send(JSON.stringify({ latitude: data.latitude, longitude: data.longitude }));
    }
  });

  ws.on('close', () => {
    console.log('WebSocket disconnected');
    listener(); // Stop Firestore listener when WebSocket is closed
  });
});



// router.get('/locations', async (req, res) => {

    
//   try {
//     const userId = req.session.userId;
  
//     if (!userId) {
//       console.log('User ID not found in session');
//       res.render('login', { error: 'User ID not found in session, please log in again' });
//       return;
//     }
  
//     const userRef = db.collection('users').doc(userId);
//     const userSnapshot = await userRef.get();
  
//     if (!userSnapshot.exists) {
//       console.log('User document not found');
//       res.render('login', { error: 'User document not found, please log in again' });
//       return;
//     }
  
//     const locationsSnapshot = await db.collection('locations').get();
//     const locations = locationsSnapshot.docs.map(doc => doc.data());
  
//     res.render('allusersMap', { locations });
//   } catch (error) {
//     console.error('Error retrieving user locations:', error);
//     res.status(500).send('Internal server error');
//   }
  
// });



















router.get('/locations', async (req, res) => {
  try {
    const userId = req.session.userId;

    if (!userId) {
      console.log('User ID not found in session');
      res.render('login', { error: 'User ID not found in session, please log in again' });
      return;
    }

    // Step 1: Fetch document IDs from activetrips collection
    const activetripsSnapshot = await db.collection('activetrips').get();
    const activetripDocIds = activetripsSnapshot.docs.map(doc => doc.id);

    // Step 2: Fetch locations and additional fields using doc IDs from activetrips
    const locationsPromises = activetripDocIds.map(async docId => {
      const locationsSnapshot = await db.collection('locations').doc(docId).get();
      const activetripDoc = await db.collection('activetrips').doc(docId).get();
      const usersSnap = await db.collection('users').doc(docId).get();
      


      if (locationsSnapshot.exists && activetripDoc.exists) {
        const locationsData = locationsSnapshot.data();
        const activetripData = activetripDoc.data();
        const usersData = usersSnap.data();

        return {
          latitude: locationsData.latitude,
          longitude: locationsData.longitude,
          userid: locationsData.userid,
          destinationAddress: activetripData.destinationAddress,
          distance:activetripData.distance,
          dpkm: activetripData.dpkm,
          vehicleId: activetripData.vehicleId,
          vehicleName: activetripData.vehicleName,
          startAddress: activetripData.startAddress,
          startTime: activetripData.startTime,

          username:usersData.username,
          userimage:usersData.image_url,
        };
      } else {
        console.log(`Locations or activetrip data not found for activetrip with ID: ${docId}`);
        return null; // or handle as needed
      }
    });

    // Execute all promises and filter out any null results
    const locations = (await Promise.all(locationsPromises)).filter(location => location !== null);

    // Step 3: Proceed with existing logic to add usernames if needed
    // For example, continue with the existing code to add usernames to locations

    // Render the EJS template with the locations including usernames
    res.render('allusersMap', { locations });

  } catch (error) {
    console.error('Error retrieving user locations:', error);
    res.status(500).send('Internal server error');
  }
});























// router.get('/locations', async (req, res) => {
//   try {
//     const userId = req.session.userId;

//     if (!userId) {
//       console.log('User ID not found in session');
//       res.render('login', { error: 'User ID not found in session, please log in again' });
//       return;
//     }

//     // Step 1: Fetch document IDs from activetrips collection
//     const activetripsSnapshot = await db.collection('activetrips').get();
//     const activetripDocIds = activetripsSnapshot.docs.map(doc => doc.id);

//     // Step 2: Fetch locations and additional fields using doc IDs from activetrips
//     const locationsPromises = activetripDocIds.map(async docId => {
//       const locationsSnapshot = await db.collection('locations').doc(docId).get();
//       const activetripDoc = await db.collection('activetrips').doc(docId).get();
//       const usersSnap = await db.collection('users').doc(docId).get();
      


//       if (locationsSnapshot.exists && activetripDoc.exists) {
//         const locationsData = locationsSnapshot.data();
//         const activetripData = activetripDoc.data();
//         const usersData = usersSnap.data();

//         return {
//           latitude: locationsData.latitude,
//           longitude: locationsData.longitude,
//           userid: locationsData.userid,
//           destinationAddress: activetripData.destinationAddress,
//           distance:activetripData.distance,
//           dpkm: activetripData.dpkm,
//           vehicleId: activetripData.vehicleId,
//           vehicleName: activetripData.vehicleName,

//           username:usersData.username,
//           userimage:usersData.image_url,
//         };
//       } else {
//         console.log(`Locations or activetrip data not found for activetrip with ID: ${docId}`);
//         return null; // or handle as needed
//       }
//     });

//     // Execute all promises and filter out any null results
//     const locations = (await Promise.all(locationsPromises)).filter(location => location !== null);

//     // Step 3: Proceed with existing logic to add usernames if needed
//     // For example, continue with the existing code to add usernames to locations

//     // Render the EJS template with the locations including usernames
//     res.render('allusersMap', { locations });

//   } catch (error) {
//     console.error('Error retrieving user locations:', error);
//     res.status(500).send('Internal server error');
//   }
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