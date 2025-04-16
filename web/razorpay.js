function openRazorpay(amount, bookingId) {
    var options = {
     "key": "rzp_test_YourApiKeyHere", // Replace with your test/live key
     "amount": amount, // amount in paise
     "currency": "INR",
    "name": "Smart Wash",
     "description": "Car Wash Booking",
     "handler": function (response) {
     alert("Payment successful! Payment ID: " + response.razorpay_payment_id);
     // You can trigger a Dart callback here using JS interop if needed
     },
     "prefill": {
     "email": "testuser@email.com",
     "contact": "9876543210"
     },
    "theme": {
     "color": "#3399cc"
     }
    };
    
     var rzp = new Razorpay(options);
     rzp.open();
    }
    