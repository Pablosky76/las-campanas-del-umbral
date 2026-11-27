describe('Archivos y arranque de la exportación', () => {
  it('W07 | El cargador del motor se sirve como JavaScript', () => {
    cy.request('index.js').then(({ headers, body }) => {
      expect(headers['content-type']).to.match(/javascript|ecmascript/);
      expect(body).to.include('getMissingFeatures');
    });
  });

  it('W08 | El servidor ofrece un módulo WebAssembly con el MIME correcto', () => {
    cy.request({ method: 'HEAD', url: 'index.wasm' }).then(({ headers }) => {
      expect(headers['content-type']).to.include('application/wasm');
      expect(Number(headers['content-length'])).to.be.greaterThan(8);
    });
  });

  it('W09 | El paquete de recursos está disponible', () => {
    cy.request({ method: 'HEAD', url: 'index.pck' }).then(({ headers }) => {
      expect(Number(headers['content-length'])).to.be.greaterThan(4);
    });
  });

  it('W10 | Arranca el motor y el canvas recibe el foco', () => {
    cy.visit('./');
    cy.get('#status', { timeout: 60000 }).should('not.exist');
    cy.get('canvas#canvas').should('be.visible');
    cy.focused().should('have.id', 'canvas');
  });
});
