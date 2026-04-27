const { getRedisClient } = require('../config/redis');

const ROOM_PREFIX = 'library:room:';
const USER_ROOMS_PREFIX = 'library:user:';
const ROOM_TTL = 3600; // 1 hour

const getRoomKey = (room) => `${ROOM_PREFIX}${room}`;
const getUserKey = (userId) => `${USER_ROOMS_PREFIX}${userId}`;

const joinRoom = async (io, socket, { userId, userName, subject, room }) => {
  const redis = getRedisClient();

  // Leave any previous room
  const prevRoom = await redis.get(getUserKey(userId));
  if (prevRoom) {
    await leaveRoom(io, socket, userId, prevRoom);
  }

  // Add user to room data
  socket.join(room);
  const userEntry = JSON.stringify({ userId, userName, subject, joinedAt: Date.now() });
  await redis.hset(getRoomKey(room), userId, userEntry);
  await redis.expire(getRoomKey(room), ROOM_TTL);
  await redis.setex(getUserKey(userId), ROOM_TTL, room);

  // Broadcast updated room list to everyone in room
  const members = await getRoomMembers(room);
  io.to(room).emit('room:update', { room, members });

  return members;
};

const leaveRoom = async (io, socket, userId, room) => {
  const redis = getRedisClient();

  socket.leave(room);
  await redis.hdel(getRoomKey(room), userId);
  await redis.del(getUserKey(userId));

  const members = await getRoomMembers(room);
  io.to(room).emit('room:update', { room, members });
};

const getRoomMembers = async (room) => {
  const redis = getRedisClient();
  const raw = await redis.hgetall(getRoomKey(room));
  if (!raw) return [];
  return Object.values(raw).map((v) => {
    try { return JSON.parse(v); } catch { return null; }
  }).filter(Boolean);
};

const getAvailableRooms = async () => {
  const redis = getRedisClient();
  // Scan for all room keys
  const keys = await redis.keys(`${ROOM_PREFIX}*`);
  const rooms = [];
  for (const key of keys) {
    const count = await redis.hlen(key);
    if (count > 0) {
      const roomName = key.replace(ROOM_PREFIX, '');
      rooms.push({ room: roomName, count });
    }
  }
  return rooms;
};

module.exports = { joinRoom, leaveRoom, getRoomMembers, getAvailableRooms };
