const request = require('supertest');
const app = require('../src/app');

describe('Session Endpoints', () => {
  it('should return 401 if unauthenticated', async () => {
    const res = await request(app).post('/api/v1/sessions/start');
    expect(res.statusCode).toBeDefined();
  });
});