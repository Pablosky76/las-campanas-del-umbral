const { defineConfig } = require('cypress');

module.exports = defineConfig({
  viewportWidth: 1152,
  viewportHeight: 648,
  defaultCommandTimeout: 8000,
  video: false,
  reporter: 'junit',
  reporterOptions: {
    mochaFile: 'resultados/cypress-[hash].xml',
    toConsole: true,
  },
  e2e: {
    baseUrl: process.env.UMBRAL_WEB_URL || 'http://127.0.0.1:4173',
    supportFile: false,
    setupNodeEvents(on) {
      on('before:browser:launch', (browser, launchOptions) => {
        if (browser.family === 'chromium' && browser.isHeadless) {
          launchOptions.args = launchOptions.args.filter((arg) => arg !== '--disable-gpu');
          launchOptions.args.push('--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader');
        }
        return launchOptions;
      });
    },
  },
});
