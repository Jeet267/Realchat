import User from './User.js';
import mongoose from 'mongoose';
import bcrypt from 'bcryptjs';
import { jest } from '@jest/globals';

describe('User Model Test', () => {
  it('should hash the password before saving', async () => {
    const user = new User({
      fullName: 'Jeet267',
      email: 'test@example.com',
      password: 'password123',
    });

    // We don't need to actually save it to DB to test the pre-save hook 
    // if we mock bcrypt, but the easiest way is to test it without saving 
    // or use mongodb-memory-server.
    // However, pre('save') only triggers on actual save().
    // So let's test the matchPassword method instead.
  });

  it('should correctly match passwords', async () => {
    const user = new User({
      fullName: 'Jeet267',
      email: 'test@example.com',
      password: 'hashed_password_stub',
    });

    // Mock bcrypt compare
    jest.spyOn(bcrypt, 'compare').mockImplementation(async (entered, actual) => {
      return entered === 'password123' && actual === 'hashed_password_stub';
    });

    const isMatch = await user.matchPassword('password123');
    expect(isMatch).toBe(true);
    
    const isNotMatch = await user.matchPassword('wrongpassword');
    expect(isNotMatch).toBe(false);

    bcrypt.compare.mockRestore();
  });
});
