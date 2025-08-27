# Security Setup Instructions

This document outlines the steps to set up secure API key configuration for the Smart Wash application.

## 🔐 Security Changes Made

The following hardcoded API keys have been moved to secure configuration:

1. **Firebase API Key** (was in `lib/main.dart`)
2. **Razorpay API Keys** (was in `backend/server.js` and `lib/user/screens/payment.dart`)

## 🛠️ Backend Setup

### 1. Environment Variables

The backend now uses environment variables for sensitive data. Copy the example file and customize it:

```bash
cd backend
cp .env.example .env
```

Edit `.env` file and update the values:
```env
RAZORPAY_KEY_ID=your_actual_razorpay_key_id
RAZORPAY_KEY_SECRET=your_actual_razorpay_key_secret
PORT=3000
```

### 2. Install Dependencies

The `dotenv` package is already installed. If you need to reinstall:

```bash
cd backend
npm install dotenv
```

### 3. Test Backend

Start the backend server:

```bash
cd backend
npm start
```

The server should load environment variables successfully.

## 📱 Flutter/Dart Setup

### 1. Configuration Class

The app now uses `lib/config/app_config.dart` for centralized configuration management.

### 2. Build with Environment Variables (Optional)

For production builds, you can pass environment variables:

```bash
# Example for production build with custom API keys
flutter build apk --dart-define=FIREBASE_API_KEY=your_production_firebase_key --dart-define=RAZORPAY_KEY_ID=your_production_razorpay_key
```

### 3. Development Fallbacks

The configuration includes fallback values for development, so the app will still work without explicit environment variables.

## 🔒 Security Best Practices

### 1. Never Commit Sensitive Files

The `.env` file is added to `.gitignore` to prevent accidental commits.

### 2. Use Different Keys for Different Environments

- Development: Use test keys
- Production: Use live keys
- Store production keys in secure deployment environments

### 3. Regular Key Rotation

Periodically rotate your API keys for enhanced security.

## 🚀 Deployment

### Backend Deployment

When deploying to production platforms (Heroku, Railway, etc.):

1. Set environment variables in your deployment platform
2. Never include the `.env` file in deployments
3. Use the platform's secure environment variable features

### Flutter Deployment

For Flutter app releases:

1. Use build-time environment variables for sensitive configuration
2. Consider using Flutter's built-in configuration management
3. Test with production keys before final release

## 🧪 Testing the Changes

1. **Backend Test**: Verify API key loading in server logs
2. **Frontend Test**: Ensure Firebase and Razorpay integrations work
3. **Security Test**: Confirm no hardcoded keys remain in source code

## 📝 Files Changed

- `backend/server.js` - Now uses environment variables
- `lib/main.dart` - Uses AppConfig instead of hardcoded keys
- `lib/user/screens/payment.dart` - Uses AppConfig for Razorpay key
- `lib/config/app_config.dart` - New configuration management class
- `backend/.env` - Environment variables file (not committed)
- `backend/.env.example` - Example environment file
- `backend/.gitignore` - Updated to ignore sensitive files

## ⚠️ Important Notes

1. **Keep your .env file secure** and never commit it to version control
2. **Update your team members** about the new configuration setup
3. **Test thoroughly** in all environments before deploying
4. **Monitor logs** to ensure no sensitive data is being logged

## 🔍 Verification

To verify no hardcoded API keys remain, search the codebase for:
- `AIzaSy` (Firebase API key pattern)
- `rzp_` (Razorpay key pattern)
- Any other hardcoded sensitive strings

All such instances should now reference the secure configuration system.
