const functions = require("firebase-functions");
const admin = require("firebase-admin");
const cors = require("cors")({origin: true});

admin.initializeApp();
const db = admin.firestore();

exports.getServices = functions.https.onRequest(async (req, res) => {
    try {
      const snapshot = await db.collection("service").get();
      const services = snapshot.docs.map(doc => doc.data());
      res.status(200).json(services);
    } catch (error) {
      console.error("Error fetching services:", error);
      res.status(500).send("Internal Server Error");
    }
  });