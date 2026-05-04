import globals from 'globals';
import pluginJs from '@eslint/js';
import eslintPluginPrettier from 'eslint-plugin-prettier/recommended';

export default [
  { languageOptions: { globals: { ...globals.node, ...globals.jest } } },
  pluginJs.configs.recommended,
  eslintPluginPrettier,
  {
    ignores: ['node_modules/', 'dist/'],
  },
];
