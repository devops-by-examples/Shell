import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import { configDefaults } from 'vitest/config'; // <-- Import configDefaults

export default defineConfig({
  plugins: [react()],
  test: {
    globals: true,
    environment: 'jsdom',
    setupFiles: './src/test/setup.js',
    reporters: ['default', 'json'],
    outputFile: 'test.json',
    // ADD THIS EXCLUDE ARRAY 👇
    exclude: [
      ...configDefaults.exclude, 
      '**/tests/events-api.spec.js', // Exclude this specific file
      '**/e2e/**',                    // Or exclude your entire E2E folder if you have one
    ],
  },
});