const Redis = require('ioredis');
const RedisMock = require('ioredis-mock');

let client;

const connectRedis = async () => {
  try {
    client = new Redis(process.env.REDIS_URL, {
      maxRetriesPerRequest: 1,
      enableReadyCheck: true,
      lazyConnect: true,
      connectTimeout: 2000, // Fast timeout
    });

    await client.connect();
    console.log('Redis connected');

    client.on('error', (err) => {});
    client.on('reconnecting', () => {});
  } catch (err) {
    console.warn('Failed to connect to primary Redis. Starting in-memory mock Redis...');
    client = new RedisMock();
    console.log('In-memory Redis Mock connected');
  }
};

const getRedisClient = () => {
  if (!client) throw new Error('Redis client not initialized. Call connectRedis() first.');
  return client;
};

module.exports = { connectRedis, getRedisClient };
