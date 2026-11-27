describe('Documento de la demo Web', () => {
  let html;

  before(() => {
    cy.request('./').then((respuesta) => {
      html = new DOMParser().parseFromString(respuesta.body, 'text/html');
    });
  });

  it('W01 | Sirve la demo como HTML', () => {
    cy.request('./').then(({ status, headers }) => {
      expect(status).to.equal(200);
      expect(headers['content-type']).to.include('text/html');
    });
  });

  it('W02 | Identifica el juego en el título', () => {
    expect(html.title).to.equal('Las Campanas del Umbral');
  });

  it('W03 | Declara UTF-8 para los textos en español', () => {
    expect(html.querySelector('meta[charset]').getAttribute('charset')).to.equal('utf-8');
  });

  it('W04 | Adapta el viewport al dispositivo', () => {
    expect(html.querySelector('meta[name="viewport"]').content).to.include('width=device-width');
  });

  it('W05 | Contiene un único canvas para el juego', () => {
    const canvases = html.querySelectorAll('canvas');
    expect(canvases).to.have.length(1);
    expect(canvases[0].id).to.equal('canvas');
  });

  it('W06 | El cargador JS usa una ruta relativa compatible con Pages', () => {
    const loader = html.querySelector('script[src="index.js"]');
    expect(loader).not.to.be.null;
  });
});
