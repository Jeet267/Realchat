import { render, screen } from '@testing-library/react';
import { describe, it, expect } from 'vitest';

import NoFriendsFound from './NoFriendsFound';
import ChatLoader from './ChatLoader';
import NoNotificationsFound from './NoNotificationsFound';

// ─────────────────────────────────────────────
// NoFriendsFound
// ─────────────────────────────────────────────
describe('NoFriendsFound', () => {
  it('renders the "No friends yet" heading', () => {
    render(<NoFriendsFound />);
    expect(screen.getByText('No friends yet')).toBeInTheDocument();
  });

  it('renders the helper text', () => {
    render(<NoFriendsFound />);
    expect(
      screen.getByText(/Connect with language partners/i)
    ).toBeInTheDocument();
  });
});

// ─────────────────────────────────────────────
// ChatLoader
// ─────────────────────────────────────────────
describe('ChatLoader', () => {
  it('renders the connecting message', () => {
    render(<ChatLoader />);
    expect(screen.getByText(/Connecting to chat/i)).toBeInTheDocument();
  });
});

// ─────────────────────────────────────────────
// NoNotificationsFound
// ─────────────────────────────────────────────
describe('NoNotificationsFound', () => {
  it('renders the "No notifications yet" heading', () => {
    render(<NoNotificationsFound />);
    expect(screen.getByText('No notifications yet')).toBeInTheDocument();
  });

  it('renders the helper text', () => {
    render(<NoNotificationsFound />);
    expect(
      screen.getByText(/friend requests or messages/i)
    ).toBeInTheDocument();
  });
});
