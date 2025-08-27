class AppConfig {
  // Firebase Configuration
  static const String firebaseApiKey = String.fromEnvironment(
    'FIREBASE_API_KEY',
    defaultValue: 'AIzaSyDBXwnO8b0OYrc7d8ndv0J28bDNC6aZlNw', // Fallback for development
  );
  
  static const String firebaseAuthDomain = String.fromEnvironment(
    'FIREBASE_AUTH_DOMAIN',
    defaultValue: 'fir-auth-f1931.firebaseapp.com',
  );
  
  static const String firebaseProjectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID', 
    defaultValue: 'fir-auth-f1931',
  );
  
  static const String firebaseStorageBucket = String.fromEnvironment(
    'FIREBASE_STORAGE_BUCKET',
    defaultValue: 'fir-auth-f1931.appspot.com',
  );
  
  static const String firebaseMessagingSenderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
    defaultValue: '760988528329',
  );
  
  static const String firebaseAppId = String.fromEnvironment(
    'FIREBASE_APP_ID',
    defaultValue: '1:760988528329:web:5f2e69aa3d4eec67512718',
  );
  
  // Razorpay Configuration
  static const String razorpayKeyId = String.fromEnvironment(
    'RAZORPAY_KEY_ID',
    defaultValue: 'rzp_test_6JdX7oPFCEpYn7', // Fallback for development
  );
  
  // Backend Configuration
  static const String backendUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'http://localhost:3000', // Fallback for development
  );
}
