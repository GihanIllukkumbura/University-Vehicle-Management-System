let express = require('express');
const admin = require('firebase-admin');
let app = express();
let methodoverwride = require('method-override')
let dotenv = require('dotenv')
let bodyParser = require('body-parser')
const serviceAccount = require('./key.json');

const WebSocket = require('ws');
const expressWs = require('express-ws');
expressWs(app);

// WebSocket server
const wss = new WebSocket.Server({ noServer: true });

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
// app.get('/map', (req, res) => {
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
// app.ws('/map', (ws, req) => {
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











admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  storageBucket: "gs://wybvehicals.appspot.com"
});



const db = admin.firestore();


let session = require('express-session');
let flash = require('connect-flash')

dotenv.config({ path: './config.env' })
// mongoose.connect(process.env.mongodburl);
app.set('view engine', 'ejs')

app.use(methodoverwride('_method'))
app.use(bodyParser.urlencoded({ extended: true }))
app.use(express.static('public'))

app.use('/upload', express.static('upload'));
// session middleweare
app.use(session({
  secret: 'nodejs',
  resave: true,
  saveUninitialized: true
}))
//flash middleweare
app.use(flash())

















const userRouter = require("./routers/userRouter.js");
const vehicalRouter = require("./routers/vehicalRouter.js");
const mapRouter = require("./routers/mapRouter.js");
const DriverRouter = require("./routers/driverRoute.js");



app.use(userRouter)
app.use(vehicalRouter)
app.use(mapRouter)
app.use(DriverRouter)




//globaly variable set for operation (like sucess , error) message
app.use((req, res, next) => {
  res.locals.sucess = req.flash('sucess'),
    res.locals.err = req.flash('err')
  next()
})


app.use('/upload', express.static('upload'));



app.listen(process.env.PORT, () => {
  console.log(process.env.PORT, "Port Working");
})