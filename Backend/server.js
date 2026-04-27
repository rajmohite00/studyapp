require('dotenv').config();
const http = require('http');
const app = require('./src/app');
const connectDB = require('./src/config/db');
const { connectRedis } = require('./src/config/redis');
const { initSocket } = require('./src/socket');

const PORT = process.env.PORT || 3000;

const startServer = async () => {
  try {
    await connectDB();
    await connectRedis();

    // Create HTTP server and attach Socket.io
    const httpServer = http.createServer(app);
    initSocket(httpServer);

    httpServer.listen(PORT, '0.0.0.0', () => {
      console.log(`Server running on port ${PORT} [${process.env.NODE_ENV}] — Socket.io enabled`);
    });
  } catch (err) {
    console.error('Failed to start server:', err);
    process.exit(1);
  }
};

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('SIGTERM received. Shutting down gracefully...');
  process.exit(0);
});

process.on('unhandledRejection', (reason) => {
  console.error('Unhandled Rejection:', reason);
  process.exit(1);
});

startServer();
