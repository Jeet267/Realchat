import { render, screen } from '@testing-library/react';
import { describe, it, expect, vi } from 'vitest';
import ThemeSelector from './ThemeSelector';
import { useThemeStore } from '../store/useThemeStore';
import { THEMES } from '../constants';

// Mock the store
vi.mock('../store/useThemeStore', () => ({
  useThemeStore: vi.fn(),
}));

// Mock the constants
vi.mock('../constants', () => ({
  THEMES: [
    { name: 'light', label: 'Light', colors: ['#ffffff', '#000000'] },
    { name: 'dark', label: 'Dark', colors: ['#000000', '#ffffff'] },
  ],
}));

describe('ThemeSelector', () => {
  it('renders the theme selector button', () => {
    // Setup mock store return value
    useThemeStore.mockReturnValue({
      theme: 'light',
      setTheme: vi.fn(),
    });

    render(<ThemeSelector />);
    const button = screen.getByRole('button', { name: '' }); // The trigger button
    expect(button).toBeInTheDocument();
  });

  it('renders theme options', () => {
    useThemeStore.mockReturnValue({
      theme: 'light',
      setTheme: vi.fn(),
    });

    render(<ThemeSelector />);
    const lightOption = screen.getByText('Light');
    const darkOption = screen.getByText('Dark');

    expect(lightOption).toBeInTheDocument();
    expect(darkOption).toBeInTheDocument();
  });
});
