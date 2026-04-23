const Redis = require('ioredis');
const RedisMock = require('ioredis-mock');

let client;

const connectRedis = async () => {
  console.log('Attempting to connect to Redis at:', process.env.REDIS_URL);
  try {
    client = new Redis(process.env.REDIS_URL, {
      maxRetriesPerRequest: 1,
      enableReadyCheck: true,
      lazyConnect: true,
      connectTimeout: 2000,
    });

    // Don't await forever, if it's down, it will catch in next tick or error event
    client.connect().catch((err) => {
      console.warn('Redis connection failed async, using mock.');
      client = new RedisMock();
    });
    
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
