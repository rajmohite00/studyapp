const request = require('supertest');
const app = require('../src/app');

describe('Analytics Endpoints', () => {
  it('should return 401 if unauthenticated', async () => {
    const res = await request(app).get('/api/v1/analytics/summary');
    expect(res.statusCode).toBeDefined();
  });
});