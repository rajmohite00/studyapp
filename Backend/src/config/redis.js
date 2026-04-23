const Redis = require('ioredis');
const RedisMock = require('ioredis-mock');

let client;

const connectRedis = async () => {
  console.log('Attempting to connect to Redis at:', process.env.REDIS_URL);
  try {
    const realClient = new Redis(process.env.REDIS_URL, {
      maxRetriesPerRequest: 1,
      enableReadyCheck: true,
      lazyConnect: true,
      connectTimeout: 2000,
      retryStrategy: () => null, // Stop reconnecting on error
    });

    realClient.on('error', (err) => {
      // Suppress unhandled error events
    });

    // Don't await forever, if it's down, it will catch in next tick or error event
    realClient.connect().then(() => {
      client = realClient;
      console.log('Redis connected successfully.');
    }).catch((err) => {
      console.warn('Redis connection failed async, using mock.');
      realClient.disconnect();
      client = new RedisMock();
    });
    
    // Assign immediately so it's available while connecting
    client = realClient;
    console.log('Redis client initialized (checking connection...)');
  } catch (err) {
    console.warn('Failed to initialize Redis client. Using mock.');
    client = new RedisMock();
  }
};

const getRedisClient = () => {
  if (!client) throw new Error('Redis client not initialized. Call connectRedis() first.');
  return client;
};

module.exports = { connectRedis, getRedisClient };
