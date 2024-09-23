const admin = require('firebase-admin');
const db = admin.firestore();

class Vehicle {
  constructor(make, model, year, registeredNumber, fuelCapacity, dpkm, fuelType, imageUrl) {
    this.make = make;
    this.model = model;
    this.year = year;
    this.registeredNumber = registeredNumber;
    this.fuelCapacity = fuelCapacity;
    this.dpkm = dpkm;
    this.fuelType = fuelType;
    this.imageUrl = imageUrl;
  }
  async save() {
    try {
      
      await db.collection('vehicles').add({
        make: this.make,
        model: this.model,
        year: this.year,
        registeredNumber: this.registeredNumber,
        fuelCapacity: this.fuelCapacity,
        dpkm: this.dpkm,
        fuelType: this.fuelType,
        imageUrl: this.imageUrl
      });
     
    } catch (err) {
      console.error('Error saving vehicle:', err);
      throw new Error('Internal server error');
    }
  }
}

module.exports = Vehicle;

