import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

// https://vite.dev/config/
export default defineConfig({
  plugins: [react()],
  test: {
    environment: 'jsdom',
    globals: true,
    setupFiles: './src/setupTests.js',
    // JUnit XML reporter — consumed by GitHub Actions artifact upload (Phase 1)
    reporters: ['default', 'junit'],
    outputFile: {
      junit: './test-results/frontend-junit.xml',
    },
  },
});
