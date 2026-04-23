const mongoose = require('mongoose');
const { MongoMemoryServer } = require('mongodb-memory-server');

const connectDB = async () => {
  let uri = process.env.MONGO_URL || process.env.MONGODB_URI;
  if (!uri) throw new Error('MONGO_URL is not defined in environment variables');

  try {
    // Attempt normal connection
    await mongoose.connect(uri, {
      maxPoolSize: 10,
      serverSelectionTimeoutMS: 5000, 
    });
    console.log(`✅ Success: MongoDB connected to ${mongoose.connection.host}`);
  } catch (err) {
    console.error('❌ Error: Failed to connect to primary MongoDB.', err.message);
    console.warn('Starting in-memory fallback database...');
    try {
      const mongoServer = await MongoMemoryServer.create();
      uri = mongoServer.getUri();
      await mongoose.connect(uri);
      console.log(`✅ Success: In-memory MongoDB connected: ${uri}`);
    } catch(fallbackErr) {
      console.error('❌ Error: Failed to start in-memory database.', fallbackErr);
      process.exit(1);
    }
  }

  mongoose.connection.on('error', (err) => {
    console.error('❌ MongoDB connection error:', err);
  });

  mongoose.connection.on('disconnected', () => {
    console.warn('⚠️ MongoDB disconnected.');
  });
};

module.exports = connectDB;
