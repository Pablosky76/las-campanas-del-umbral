function estado(comprobar, timeout = 10000) {
  return cy.get('html[data-umbral-qa]', { timeout }).should(($html) => {
    comprobar(JSON.parse($html.attr('data-umbral-qa')));
  });
}

function tecla(nombre) {
  cy.get('#canvas').should('be.focused');
  cy.press(nombre);
}

function entrarEnLaMina() {
  // El juego tiene un viewport de 1152 × 648. Clic en la entrada oriental.
  cy.get('#canvas').click(930, 313);
  estado((actual) => expect(actual.panel).to.equal(2));
  tecla('1');
  estado((actual) => expect(actual.zona).to.equal('mina'));
}

describe('Partida en el navegador con la compilación QA', () => {
  beforeEach(() => {
    cy.visit('./');
    estado((actual) => expect(actual.zona).to.equal('valdebronce'), 60000);
  });

  it('W11 | La partida empieza en Valdebronce', () => {
    estado((actual) => {
      expect(actual.planta).to.equal(0);
      expect(actual.panel).to.equal(-1);
    });
  });

  it('W12 | Un clic en la plaza mueve al Vinculador', () => {
    cy.get('#canvas').click(650, 470);
    estado((actual) => expect(actual.posicion[0]).to.be.greaterThan(600));
  });

  it('W13 | I abre la mochila', () => {
    tecla('i');
    estado((actual) => expect(actual.panel).to.equal(5));
  });

  it('W14 | T abre los talentos', () => {
    tecla('t');
    estado((actual) => expect(actual.panel).to.equal(4));
  });

  it('W15 | Escape cierra el panel abierto', () => {
    tecla('i');
    estado((actual) => expect(actual.panel).to.equal(5));
    tecla(Cypress.Keyboard.Keys.ESC);
    estado((actual) => expect(actual.panel).to.equal(-1));
  });

  it('W16 | M alterna el silencio de la música', () => {
    cy.get('html').invoke('attr', 'data-umbral-qa').then((json) => {
      const inicial = JSON.parse(json).silencio;
      tecla('m');
      estado((actual) => expect(actual.silencio).to.equal(!inicial));
      tecla('m');
      estado((actual) => expect(actual.silencio).to.equal(inicial));
    });
  });

  it('W17 | Al recargar se vuelve a Valdebronce', () => {
    tecla('i');
    estado((actual) => expect(actual.panel).to.equal(5));
    cy.reload();
    estado((actual) => {
      expect(actual.zona).to.equal('valdebronce');
      expect(actual.panel).to.equal(-1);
    }, 60000);
  });

  it('W18 | La primera expedición entra en la Bocamina', () => {
    entrarEnLaMina();
    estado((actual) => expect(actual.planta).to.equal(1));
  });

  it('W19 | La entrada a la mina abre el ritual inicial', () => {
    entrarEnLaMina();
    estado((actual) => expect(actual.ritual).to.equal(true));
  });

  it('W20 | F permite cerrar y volver a abrir el ritual', () => {
    entrarEnLaMina();
    estado((actual) => expect(actual.ritual).to.equal(true));
    tecla('f');
    estado((actual) => expect(actual.ritual).to.equal(false));
    tecla('f');
    estado((actual) => expect(actual.ritual).to.equal(true));
  });
});
