let express = require('express');
let userRouter = express();
const admin = require('firebase-admin');
const db = admin.firestore();
const User = require('../models/usermodel');
const Vehicle = require('../models/Vehicle');




userRouter.get('/', async (req, res) => {
  try {
    const userId = req.session.userId;

  if (!userId) {
    
    res.render('login', { error: 'please log in again' });
    return;
  }
   

    const userRef = db.collection('users').doc(userId);
    const result = await userRef.get();

    if (!result.exists) {
    
      res.render('login', { error: 'please log again' });
      return;
    }

    const userData = result.data();

    if (userData.role === 'admin') {
      const empDataSnapshot = await db.collection('users').get();
      const empData = empDataSnapshot.docs.map(doc => doc.data());

      const roleCounts = empData.reduce((acc, curr) => {
        if (curr.role === 'company') {
          acc.company++;
        } else if (curr.role === 'admin') {
          acc.admin++;
        }else{
          acc.user++;
        }
        return acc;
      }, { user: 0, company: 0, admin: 0 });

      const monthCountsSnapshot = await db.collection('tripsforweb').get(); // Get all users

      const countsByMonth = {};
      monthCountsSnapshot.forEach(doc => {
        const user = doc.data();
        if (!countsByMonth[user.month]) {
          countsByMonth[user.month] = 0;
        }
        countsByMonth[user.month]++;
      });
     
      const vehiclesCollection = await db.collection('vehicles').get();

    // Count the number of documents in the vehicles collection
    const vehicleCount = vehiclesCollection.size;

    const tripsSnapshot = await db.collection('tripsforweb').get();
    const tripsCount = tripsSnapshot.size;


      res.render('adminPanel', { result, empData, roleCounts, count: empData.length, countsByMonth ,vehicleCount,tripsCount });

    } else if (userData.role === 'company') {
      res.render('company', { userData });
    } else {
      res.render('user', { userData });
    }

  } catch (error) {
    console.error(error);
    res.status(500).send('Internal server error');
  }
});





userRouter.get('/register', (req, res) => {
  res.render('register');
});

// userRouter.post('/register', async (req, res) => {
//   const { email, password, cpassword } = req.body;
//   try {
//     const user = new User(email, password);
//     await user.save();
//     res.redirect('/login');
//   } catch (err) {
//     req.flash('error', err.message);
//     res.render('register', { error: req.flash('error') });
//   }
// });
userRouter.post('/register', async (req, res) => {
  const { email, password, cpassword } = req.body;
  try {
    if (password !== cpassword) {
      throw new Error('Passwords do not match');
    }

    // Create user with email and password using Firebase Authentication
    const userRecord = await admin.auth().createUser({
      email: email,
      password: password
    });
    const userId = userRecord.uid;

    // Add user details to Firestore users collection
    await db.collection('users').doc(userId).set({
      email: email,
      password : password,
      role: 'admin' 
    });

    res.redirect('/login');
  } catch (err) {
    req.flash('error', err.message);
    res.render('register', { error: req.flash('error') });
  }
});







// Login route
userRouter.get('/login', (req, res) => {
  res.render('login');
});

// userRouter.get('/login', (req, res) => {
//   res.render('login');
// });

userRouter.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    const userRef = db.collection('users').where('email', '==', email).where('password', '==', password);
    const snapshot = await userRef.get();

    if (snapshot.empty) {
      res.send('Invalid email or password');
      return;
    }
    
    let result;
    snapshot.forEach(doc => {
      result = doc.id;
    });

    req.session.userId = result; // Store user ID in session upon successful login
    
    
    if (result.role === 'company') {
      res.render('company', { userId: result.id }); // Pass the user ID to the home page

    } else if (result.role === 'admin') {
      const empDataSnapshot = await db.collection('users').get();
      const empData = empDataSnapshot.docs.map(doc => doc.data());

      const roleCounts = empData.reduce((acc, curr) => {
        if (curr.role === 'company') {
          acc.company++;
        } else if (curr.role === 'admin') {
          acc.user++;
        }else{
          acc.user++;
        }
        return acc;
      }, { user: 0, company: 0, admin: 0 });

      const monthCountsSnapshot = await db.collection('tripsforweb').get(); // Get all users
      const countsByMonth = {};
      monthCountsSnapshot.forEach(doc => {
        const user = doc.data();
        if (!countsByMonth[user.month]) {
          countsByMonth[user.month] = 0;
        }
        countsByMonth[user.month]++;
      });

      const vehiclesCollection = await db.collection('vehicles').get();

      // Count the number of documents in the vehicles collection
      const vehicleCount = vehiclesCollection.size;
  
     
  
  
      const tripsSnapshot = await db.collection('tripsforweb').get();
      const tripsCount = tripsSnapshot.size;
  
  
        res.render('adminPanel', { result, empData, roleCounts, count: empData.length, countsByMonth ,vehicleCount,tripsCount });
  
    } else {
      res.redirect('/'); // Redirect to home page for users
    }
  } catch (error) {
    console.error('Error checking user credentials', error);
    res.status(500).send('Error checking user credentials');
  }
});


userRouter.get('/home', (req, res) => {
  res.render('home', { error: req.flash('error') });
});


//Admin Assigned trips


userRouter.get('/adminTrips', async (req, res) => {
  try {
    const vehiclesSnapshot = await db.collection('vehicles').get();
    const usersSnapshot = await db.collection('users').get();
    
    const assignedTripsSnapshot = await db.collection('adminTrips').where('unassign', '==', 0).get();
    const unassignedTripsSnapshot = await db.collection('adminTrips').where('unassign', '==', 1).get();

    const drivers = usersSnapshot.docs
      .map(doc => ({ id: doc.id, ...doc.data() }))
      .filter(driver => driver.role !== 'admin');

    const driversMap = new Map(drivers.map(driver => [driver.id, driver]));

    const vehicles = vehiclesSnapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data()
    }));

    const vehiclesMap = new Map(vehicles.map(vehicle => [vehicle.id, vehicle]));

    const assignedTrips = assignedTripsSnapshot.docs.map(doc => {
      const tripData = doc.data();
      return {
        id: doc.id,
        ...tripData,
        driver: driversMap.get(tripData.driver),
        vehicle: vehiclesMap.get(tripData.vehicle)
      };
    });

    const unassignedTrips = unassignedTripsSnapshot.docs.map(doc => {
      const tripData = doc.data();
      return {
        id: doc.id,
        ...tripData,
        driver: driversMap.get(tripData.driver),
        vehicle: vehiclesMap.get(tripData.vehicle)
      };
    });

    res.render('zadminTrips', { drivers, vehicles, assignedTrips, unassignedTrips, error: req.flash('error') });
  } catch (error) {
    console.error('Error fetching data', error);
    res.status(500).send('Internal server error');
  }
});
userRouter.post('/adminTrips', async (req, res) => {
  const { driver, destination, date, time, vehicle, description } = req.body;

  try {
    const tripData = {
      driver,
      destination,
      date,
      time,
      vehicle,
      description,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      unassign: 0,
    };

    await db.collection('adminTrips').add(tripData);

    res.redirect('/adminTrips');
  } catch (error) {
    console.error('Error creating trip', error);
    req.flash('error', 'Error creating trip');
    res.redirect('/adminTrips');
  }
});



const bodyParser = require('body-parser');

userRouter.use(bodyParser.json());

userRouter.post('/adminTrips/:id/unassign', async (req, res) => {
  const { id } = req.params;
  const { reason } = req.body;

  if (!reason) {
    req.flash('error', 'Unassign reason is required');
    return res.redirect('/adminTrips');
  }

  try {
    await db.collection('adminTrips').doc(id).update({
      unassign: 1,
      unassignReason: reason,
      unassignedAt: admin.firestore.FieldValue.serverTimestamp()
    });

    res.redirect('/adminTrips');
  } catch (error) {
    console.error('Error unassigning trip', error);
    req.flash('error', 'Error unassigning trip');
    res.redirect('/adminTrips');
  }
});


  



// Statistics route

userRouter.get('/statistics', async (req, res) => {
  try {
    const driversSnapshot = await db.collection('users').get();
    const vehiclesSnapshot = await db.collection('vehicles').get();
    const refillingSnapshot = await db.collection('refillingforweb').get();

    const drivers = driversSnapshot.docs
      .map(doc => ({ id: doc.id, ...doc.data() }))
      .filter(driver => driver.role !== 'admin');

    const vehicles = vehiclesSnapshot.docs
      .map(doc => ({ id: doc.id, ...doc.data() }));

    const refillingDetails = refillingSnapshot.docs
      .map(doc => ({ id: doc.id, ...doc.data() }));

    // Extract query parameters
    const { driverId, vehicleId } = req.query;

    // Filter refilling details
    const filteredRefillings = refillingDetails.filter(detail => {
      let matchesDriver = true;
      let matchesVehicle = true;

      if (driverId) {
        console.log(driverId)
        matchesDriver = detail.driverId === driverId;
      }

      if (vehicleId) {
        console.log(vehicleId)

        matchesVehicle = detail.vehicleId === vehicleId;
      }

      return matchesDriver && matchesVehicle;
    });

    // Render the statistics page
    res.render('statistics', {
      drivers,
      vehicles,
      refillingDetails: filteredRefillings,
      driverId, // Pass the driverId to keep the dropdown selected
      vehicleId // Pass the vehicleId to keep the dropdown selected
    });
  } catch (error) {
    console.error('Error fetching data:', error);
    res.status(500).send('Internal server error');
  }
});






userRouter.delete('/adminTrips/:tripId/remove', async (req, res) => {
  try {
    const tripId = req.params.tripId;

    // Reference the document in the Firestore collection and delete it
    const tripRef = db.collection('adminTrips').doc(tripId);

    // Try to get the document to check if it exists
    const tripDoc = await tripRef.get();

    if (!tripDoc.exists) {
      return res.status(404).send({ message: 'Trip not found' });
    }

    // Delete the document
    await tripRef.delete();

    res.status(200).send({ message: 'Trip removed successfully' });
  } catch (error) {
    console.error('Error removing trip:', error);
    res.status(500).send({ message: 'Error removing trip' });
  }
});






module.exports = userRouter;



// userRouter.get('/login', (req, res) => {
//   res.render('login');
// });

// userRouter.post('/login', async (req, res) => {
//   try {
//     const { email, password } = req.body;

//     const userRef = db.collection('users').where('email', '==', email).where('password', '==', password);
//     const snapshot = await userRef.get();

//     if (snapshot.empty) {
//       res.send('Invalid email or password');
//       return;
//     }

//     let result;
//     snapshot.forEach(doc => {
//       result = doc.data();
//     });

//     req.session.userId = result.id; // Store user ID in session upon successful login

//     if (result.role === 'company') {
//       res.render('company', { userId: result.id }); // Pass the user ID to the home page
//     } else if (result.role === 'admin') {
//       const empDataSnapshot = await db.collection('users').get();
//       const empData = empDataSnapshot.docs.map(doc => doc.data());

//       const roleCounts = empData.reduce((acc, curr) => {
//         if (curr.role === 'user') {
//           acc.user++;
//         } else if (curr.role === 'company') {
//           acc.company++;
//         } else if (curr.role === 'admin') {
//           acc.admin++;
//         }
//         return acc;
//       }, { user: 0, company: 0, admin: 0 });

//       const monthCountsSnapshot = await db.collection('users').get(); // Get all users
//       const countsByMonth = {};
//       monthCountsSnapshot.forEach(doc => {
//         const user = doc.data();
//         if (!countsByMonth[user.month]) {
//           countsByMonth[user.month] = 0;
//         }
//         countsByMonth[user.month]++;
//       });

//       // Render your view or send the retrieved data to the client
//       res.render('adminPanel', { result, empData, roleCounts, count: empData.length, countsByMonth });
//     } else {
//       res.redirect('/'); // Redirect to home page for users
//     }
//   } catch (error) {
//     console.error('Error checking user credentials', error);
//     res.status(500).send('Error checking user credentials');
//   }
// });


// userRouter.get('/home', (req, res) => {
//   res.render('home', { error: req.flash('error') });
// });
















// userRouter.get('/', async (req, res) => {
//   try {
//     const empDpshot = await db.collection('users').get();
   

//     const data = empDpshot.docs.map(doc => ({
//       id: doc.id,
//       ...doc.data()
//     }));
//     console.log(data)


//     req.session.userId = 'vZz580Gcy85ZEIqfhEyS'; 
//     const userId = req.session.userId;

   

// const userRef = db.collection('users').doc(userId);
// const result = await userRef.get();
    
//     if (!result.exists) {
//       console.log('User document not found');
//       // Handle the case where the user document is not found
//     } else {
//       // User document exists, you can access its data using userDoc.data()
//       const userData = result.data();
    
//     }
   
//     if (!result.exists) {
//       // User document not found, render an error page or redirect to login
//       res.render('login', { error: 'User not found' });
//       return;
//     }

//     const userData = result.data();

//     if (userData.role === 'admin') {
//       const empDataSnapshot = await db.collection('users').get();
//       const empData = empDataSnapshot.docs.map(doc => doc.data());

//       const roleCounts = empData.reduce((acc, curr) => {
//         if (curr.role === 'user') {
//           acc.user++;
//         } else if (curr.role === 'company') {
//           acc.company++;
//         } else if (curr.role === 'admin') {
//           acc.admin++;
//         }
//         return acc;
//       }, { user: 0, company: 0, admin: 0 });

//       const monthCountsSnapshot = await db.collection('users').get(); // Get all users
//       const countsByMonth = {};
//       monthCountsSnapshot.forEach(doc => {
//         const user = doc.data();
//         if (!countsByMonth[user.month]) {
//           countsByMonth[user.month] = 0;
//         }
//         countsByMonth[user.month]++;
//       });
//       res.render('adminPanel', { result, empData, roleCounts, count: empData.length, countsByMonth });

//     } else if (userData.role === 'company') {
//       // User is a company, render the company page
//       res.render('company', { userData });
//     } else {
//       // User is a regular user, render a user-specific page
//       res.render('user', { userData });
//     }

//   } catch (error) {
//     console.error(error);
//     res.status(500).send('Internal server error');
//   }
// });
