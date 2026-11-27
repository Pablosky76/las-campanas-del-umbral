describe('Archivos y arranque de la exportación', () => {
  it('W07 | El cargador del motor se sirve como JavaScript', () => {
    cy.request('index.js').then(({ headers, body }) => {
      expect(headers['content-type']).to.match(/javascript|ecmascript/);
      expect(body).to.include('getMissingFeatures');
    });
  });

  it('W08 | El módulo tiene cabecera WebAssembly y MIME válido', () => {
    cy.request({ url: 'index.wasm', headers: { Range: 'bytes=0-7' }, encoding: 'binary' })
      .then(({ headers, body }) => {
        expect(headers['content-type']).to.include('application/wasm');
        expect(body.slice(0, 8)).to.equal('\0asm\x01\x00\x00\x00');
      });
  });

  it('W09 | El paquete tiene la firma de un PCK de Godot', () => {
    cy.request({ url: 'index.pck', headers: { Range: 'bytes=0-3' }, encoding: 'binary' })
      .its('body').should((body) => expect(body.slice(0, 4)).to.equal('GDPC'));
  });

  it('W10 | Arranca el motor y el canvas recibe el foco', () => {
    cy.visit('./');
    cy.get('#status', { timeout: 60000 }).should('not.exist');
    cy.get('canvas#canvas').should('be.visible');
    cy.focused().should('have.id', 'canvas');
  });
});
