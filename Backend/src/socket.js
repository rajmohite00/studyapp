const { Server } = require('socket.io');
const jwt = require('jsonwebtoken');
const libraryService = require('./services/libraryService');

const initSocket = (httpServer) => {
  const io = new Server(httpServer, {
    cors: {
      origin: '*',
      methods: ['GET', 'POST'],
    },
  });

  // Auth middleware for socket
  io.use((socket, next) => {
    const token = socket.handshake.auth?.token;
    if (!token) return next(new Error('Authentication required'));
    try {
      const decoded = jwt.verify(token, process.env.JWT_SECRET);
      socket.user = decoded;
      next();
    } catch (err) {
      next(new Error('Invalid token'));
    }
  });

  io.on('connection', (socket) => {
    const userId = socket.user?.sub || socket.user?.id;
    const userName = socket.user?.name || 'Student';
    console.log(`[Socket] User connected: ${userName} (${userId})`);

    // Get all available rooms
    socket.on('library:getRooms', async () => {
      const rooms = await libraryService.getAvailableRooms();
      socket.emit('library:rooms', rooms);
    });

    // Join a study room
    socket.on('library:join', async ({ subject, room }) => {
      const members = await libraryService.joinRoom(io, socket, {
        userId,
        userName,
        subject: subject || 'General Study',
        room: room || 'General',
      });
      socket.emit('library:joined', { room, members });
    });

    // Leave a room
    socket.on('library:leave', async ({ room }) => {
      await libraryService.leaveRoom(io, socket, userId, room);
    });

    // Handle disconnect (app goes to background / closes)
    socket.on('disconnect', async () => {
      console.log(`[Socket] User disconnected: ${userName}`);
      const { getRedisClient } = require('./config/redis');
      const redis = getRedisClient();
      const room = await redis.get(`library:user:${userId}`);
      if (room) {
        await libraryService.leaveRoom(io, socket, userId, room);
      }
    });
  });

  return io;
};

module.exports = { initSocket };
