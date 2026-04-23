require('dotenv').config();
const connectDB = require('./src/config/db');
const mongoose = require('mongoose');

const checkConnection = async () => {
  try {
    console.log('Testing connection to:', process.env.MONGO_URL.replace(/:[^:]*@/, ':***@')); // Hide password in log
    await connectDB();
    if (mongoose.connection.readyState === 1) {
      console.log('Successfully confirmed Atlas connection is active.');
      process.exit(0);
    }
  } catch (error) {
    console.error('Connection failed:', error);
    process.exit(1);
  }
};

checkConnection();
