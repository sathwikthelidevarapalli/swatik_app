# Swastik - Event Management Platform

A comprehensive wedding planning application with Flutter frontend and Node.js backend.

## Features

- **Customer Portal**: Browse vendors, book services, AI assistant
- **Vendor Portal**: Profile management, bookings, earnings tracking
- **Admin Dashboard**: Manage vendors, bookings, and platform operations
- **AI Assistant**: Gemini-powered wedding planning assistant

## Project Structure

- `swastik_app/` - Flutter mobile application
- `swastik_backend/` - Node.js/Express backend API

## Setup Instructions

### Backend Setup

1. Navigate to backend directory:
   ```bash
   cd swastik_backend
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

3. Create `.env` file with required environment variables:
   ```
   PORT=5000
   MONGO_URI=your_mongodb_connection_string
   JWT_SECRET=your_jwt_secret
   ```

4. Start the server:
   ```bash
   npm start
   ```

### Flutter App Setup

1. Navigate to app directory:
   ```bash
   cd swastik_app
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Create `.env` file in `swastik_app/` directory:
   ```
   GEMINI_API_URL=https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent
   GEMINI_API_KEY=your_gemini_api_key_here
   ```

4. Run the app:
   ```bash
   flutter run
   ```

## Tech Stack

- **Frontend**: Flutter, Dart
- **Backend**: Node.js, Express
- **Database**: MongoDB
- **AI**: Google Gemini API
- **Authentication**: JWT

## License

All rights reserved.
