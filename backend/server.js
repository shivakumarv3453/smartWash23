// server.js (Node.js Example)

const express = require('express');
const Razorpay = require('razorpay');
const cors = require('cors');
const app = express();
app.use(cors());

const razorpay = new Razorpay({
  key_id: 'rzp_test_6JdX7oPFCEpYn7',
  key_secret: 'utsfm9OH2Ec4h7d8re0KT0VG',
});

app.post('/create-order', async (req, res) => {
  const options = {
    amount: 25000, // Amount in paisa (₹250 = 25000)
    currency: 'INR',
    receipt: 'order_receipt_1',
  };

  try {
    const order = await razorpay.orders.create(options);
    res.json(order);
  } catch (error) {
    console.error(error);
    res.status(500).send('Error creating order');
  }
});

app.post('/verify-payment', async (req, res) => {
  const paymentId = req.body.paymentId;
  const orderId = req.body.orderId;
  const signature = req.body.signature;

  const isValid = razorpay.verifyPaymentSignature({
    payment_id: paymentId,
    order_id: orderId,
    signature: signature,
  });

  if (isValid) {
    res.send('Payment verified');
  } else {
    res.status(400).send('Invalid payment signature');
  }
});

app.listen(3000, () => {
  console.log('Server running on port 3000');
});
