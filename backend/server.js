require('dotenv').config();
const express = require('express');
const Razorpay = require('razorpay');
const cors = require('cors');

const app = express();
app.use(cors());
app.use(express.json());

// Initialize Razorpay with environment variables
const razorpay = new Razorpay({
  key_id: process.env.RAZORPAY_KEY_ID,
  key_secret: process.env.RAZORPAY_KEY_SECRET,
});

app.post('/create-order', async (req, res) => {
  const { amount, currency = 'INR', receipt } = req.body;

  try {
    const order = await razorpay.orders.create({
      amount,
      currency,
      receipt,
      payment_capture: 1,
    });

    res.json(order);
  } catch (err) {
    console.error('Order creation failed', err);
    res.status(500).json({ error: 'Failed to create Razorpay order' });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
