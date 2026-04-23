const mongoose = require('mongoose');
const { MongoMemoryServer } = require('mongodb-memory-server');

const connectDB = async () => {
  let uri = process.env.MONGODB_URI;
  if (!uri) throw new Error('MONGODB_URI is not defined in environment variables');

  try {
    // Attempt normal connection
    await mongoose.connect(uri, {
      maxPoolSize: 10,
      serverSelectionTimeoutMS: 2000, // Fast timeout for local test
    });
    console.log(`MongoDB connected: ${mongoose.connection.host}`);
  } catch (err) {
    console.warn('Failed to connect to primary MongoDB. Starting in-memory fallback database...');
    const mongoServer = await MongoMemoryServer.create();
    uri = mongoServer.getUri();
    await mongoose.connect(uri);
    console.log(`In-memory MongoDB connected: ${uri}`);
  }

  mongoose.connection.on('error', (err) => {
    console.error('MongoDB connection error:', err);
  });
};

module.exports = connectDB;
