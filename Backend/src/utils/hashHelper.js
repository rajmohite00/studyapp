const bcrypt = require('bcryptjs');

const hashPassword = async (plain, rounds = 12) => bcrypt.hash(plain, rounds);

const comparePassword = async (plain, hashed) => bcrypt.compare(plain, hashed);

module.exports = { hashPassword, comparePassword };
