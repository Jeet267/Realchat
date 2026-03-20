import request from 'supertest';
import app from '../server.js';
import User from '../models/User.js';
import { jest } from '@jest/globals';

describe('Auth Routes Integration', () => {
  it('should reject login with wrong credentials (API + DB interaction)', async () => {
    // Mock the DB interaction to simulate a non-existent user
    jest.spyOn(User, 'findOne').mockResolvedValue(null);

    const res = await request(app)
      .post('/api/auth/login')
      .send({ email: 'test@example.com', password: 'password123' });

    // The API should handle the null user and return a 400 or 401 client error
    expect(res.statusCode).toBeGreaterThanOrEqual(400);
    expect(res.statusCode).toBeLessThan(500);

    User.findOne.mockRestore();
  });
});
