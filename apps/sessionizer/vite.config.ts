import { defineConfig } from 'vite-plus';

export default defineConfig({
  pack: {
    entry: ['index.ts'],
    exe: true,
    dts: false,
    format: 'esm',
    sourcemap: false,
    platform: 'node',
    shims: true,
    deps: {
      alwaysBundle: [/.*/],
    },
  },
});
