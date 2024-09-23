const express = require('express');
const router = express();
const admin = require('firebase-admin');
const db = admin.firestore();
const Vehicle = require('../models/Vehicle');
const serviceAccount = require('../key.json');
const multer = require('multer');
const fs = require('fs');
const path = require('path');

// image upload

const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, 'upload/'); // Set the destination folder for uploaded files
  },
  filename: function (req, file, cb) {
    cb(null, file.fieldname + '-' + Date.now()) // Set the filename to be unique
  },
});

const upload = multer({ storage: storage });


var bucket = admin.storage().bucket();




// const filePath = 'c:/Users/pc/Downloads/k820RUm6KHRtm8G3huGJY2Z4bjN2.jpg';

// // Destination path in the storage bucket (e.g., 'images/my-image.jpg')
// const destinationPath = 'vehicals/my-image.jpg';

// Upload the file to the storage bucket
// bucket.upload(filePath, {
//   destination: destinationPath
// }).then((file) => {
//   console.log('File uploaded successfully.');

//   // Get the download URL
//   return file[0].getSignedUrl({
//     action: 'read',
//     expires: '01-01-2100' // Optional expiration date
//   });
// }).then((url) => {
//   console.log('Download URL:', url);
// }).catch((error) => {
//   console.error('Error uploading file:', error);
// });











// Route to get all vehicles
router.get('/vehicles', async (req, res) => {
  try {
    // Retrieve all vehicle data from Firestore
    const snapshot = await db.collection('vehicles').get();

   

    // Map the snapshot documents to an array of vehicle objects
    const vehicles = snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data()
    }));

    // Render your view or send the retrieved data to the client
    res.render('UniversityVehicals', { vehicles });
  } catch (error) {
    console.error('Error fetching vehicle data:', error);
    req.flash('error', 'Error fetching vehicle data');
    res.redirect('/'); // Redirect to the desired route or handle the error accordingly
  }
});


// Add more routes as needed

router.get('/addvehical', (req, res) => {
  res.render('addvehical');
});


router.post('/addvehical', upload.single('vehicalImage'), async (req, res) => {
  const { make, model, year, registeredNumber, fuelCapacity, fuelType,dpkm } = req.body;
  const imageFile = req.file; // Get the uploaded file

  try {
    if (!imageFile) {
      throw new Error('Please upload an image');
    }

    const filePath = imageFile.path;
    const destinationPath = `vehicals/${imageFile.originalname}`;

    await bucket.upload(filePath, {
      destination: destinationPath
    });

    const imageUrl = await bucket.file(destinationPath).getSignedUrl({
      action: 'read',
      expires: '01-01-2100'
    });

    const vehicle = new Vehicle(make, model, year, registeredNumber, fuelCapacity, fuelType, dpkm , imageUrl);
    await vehicle.save();

// reder to table
    const snapshot = await db.collection('vehicles').get();
    const vehicles = snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data()
    }));
    res.render('UniversityVehicals', { vehicles });


  } catch (err) {
    req.flash('error', err.message);
    res.render('addvehical', { error: req.flash('error') });
  }
});


// delete vehical 


router.delete('/delete/:id', async (req, res) => {
  const vehicleId = req.params.id; // Get the vehicle ID from the request parameters

  try {
    // Delete the vehicle document from Firestore
    await db.collection('vehicles').doc(vehicleId).delete();

  // reder to table
  const snapshot = await db.collection('vehicles').get();
  const vehicles = snapshot.docs.map(doc => ({
    id: doc.id,
    ...doc.data()
  }));
  res.render('UniversityVehicals', { vehicles });

  
  } catch (err) {
    console.error('Error deleting vehicle:', err);
    req.flash('error', 'Error deleting vehicle');
    res.redirect('/home'); // Redirect to the home page with an error message
  }
});












router.get('/update/:id', async (req, res) => {
  const vehicleId = req.params.id;
  console.log(vehicleId)
  try {
    const vehicleDoc = await db.collection('vehicles').doc(vehicleId).get();
    if (!vehicleDoc.exists) {
      throw new Error('Vehicle not found');
    }

    const vehicle = vehicleDoc.data();
    res.render('updateUNivehicles', { vehicle, vehicleId, error: null }); // Pass null for error
  } catch (err) {
    req.flash('error', err.message);
    res.redirect('/');
  }
});


router.post('/update/:id', upload.single('vehicalImage'), async (req, res) => {
  const vehicleId = req.params.id;
  const { make, model, year, registeredNumber, fuelCapacity, fuelType,dpkm } = req.body;
  const imageFile = req.file; // Get the uploaded file

  try {
    const vehicleDoc = await db.collection('vehicles').doc(vehicleId).get();
    if (!vehicleDoc.exists) {
      throw new Error('Vehicle not found');
    }

    const vehicle = vehicleDoc.data();

    // Log current vehicle data for debugging


    let imageUrl = vehicle.imageUrl; // Default to existing imageUrl

    if (imageFile) {
      const filePath = imageFile.path;
      const destinationPath = `vehicals/${imageFile.originalname}`;
      await bucket.upload(filePath, { destination: destinationPath });
      const signedUrls = await bucket.file(destinationPath).getSignedUrl({
        action: 'read',
        expires: '01-01-2100'
      });
      imageUrl = signedUrls;  // Update imageUrl with the new uploaded URL
    }

    const updatedVehicle = {
      make: make || vehicle.make,
      model: model || vehicle.model,
      year: year || vehicle.year,
      registeredNumber: registeredNumber || vehicle.registeredNumber,
      fuelCapacity: fuelCapacity || vehicle.fuelCapacity,
      dpkm:dpkm || vehicle.dpkm,
      fuelType: fuelType || vehicle.fuelType,
      imageUrl // Use the updated or existing imageUrl
    };

    // Log updated vehicle data for debugging
    

    await db.collection('vehicles').doc(vehicleId).update(updatedVehicle);

    // Fetch and render the updated list of vehicles
    const snapshot = await db.collection('vehicles').get();
    const vehicles = snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data()
    }));
    
    res.render('UniversityVehicals', { vehicles });

  } catch (err) {
    console.error('Error updating vehicle:', err);
    res.redirect('/');
  }
});















router.get('/vehicles/:id/refillingDetails', async (req, res) => {
  const vehicleId = req.params.id;

  try {
    const refillingSnapshot = await db.collection('refillingforweb').where('vehicleId', '==', vehicleId).get();
    const refillingDetails = refillingSnapshot.docs.map(doc => doc.data());

    res.render('refillingDetails', { vehicleId, refillingDetails });
  } catch (err) {
    console.error('Error fetching refilling details:', err);
    res.status(500).send('Internal server error');
  }
});

// router.post('/vehicles/:id/addRefillingDetail', async (req, res) => {
//   const vehicleId = req.params.id;
//   const { refillDate, amount, cost, note } = req.body;

//   try {
//     const newRefillingDetail = {
//       vehicleId,
//       refillDate,
//       amount,
//       cost,
//       note,
//     };

//     await db.collection('refillingforweb').add(newRefillingDetail);
//     res.redirect(`/vehicles/${vehicleId}/refillingDetails`);
//   } catch (err) {
//     console.error('Error adding refilling detail:', err);
//     res.status(500).send('Internal server error');
//   }
// });



















module.exports = router;
