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
    estado((actual) => expect(actual.ayuda).to.equal(true), 60000);
  });

  function cerrarAyuda() {
    tecla(Cypress.Keyboard.Keys.ENTER);
    estado((actual) => expect(actual.ayuda).to.equal(false));
  }

  it('W11 | Valdebronce presenta los controles al arrancar', () => {
    estado((actual) => {
      expect(actual.zona).to.equal('valdebronce');
      expect(actual.ayuda).to.equal(true);
      expect(actual.planta).to.equal(0);
      expect(actual.panel).to.equal(-1);
    });
  });

  it('W12 | Un clic en la plaza mueve al Vinculador', () => {
    cerrarAyuda();
    cy.get('#canvas').click(650, 470);
    estado((actual) => expect(actual.posicion[0]).to.be.greaterThan(600));
  });

  it('W13 | I abre la mochila', () => {
    cerrarAyuda();
    tecla('i');
    estado((actual) => expect(actual.panel).to.equal(5));
  });

  it('W14 | T abre los talentos', () => {
    cerrarAyuda();
    tecla('t');
    estado((actual) => expect(actual.panel).to.equal(4));
  });

  it('W15 | Escape cierra el panel abierto', () => {
    cerrarAyuda();
    tecla('i');
    estado((actual) => expect(actual.panel).to.equal(5));
    tecla(Cypress.Keyboard.Keys.ESC);
    estado((actual) => expect(actual.panel).to.equal(-1));
  });

  it('W16 | M alterna el silencio de la música', () => {
    cerrarAyuda();
    cy.get('html').invoke('attr', 'data-umbral-qa').then((json) => {
      const inicial = JSON.parse(json).silencio;
      tecla('m');
      estado((actual) => expect(actual.silencio).to.equal(!inicial));
      tecla('m');
      estado((actual) => expect(actual.silencio).to.equal(inicial));
    });
  });

  it('W17 | Al recargar se vuelve a Valdebronce', () => {
    cerrarAyuda();
    tecla('i');
    estado((actual) => expect(actual.panel).to.equal(5));
    cy.reload();
    estado((actual) => expect(actual.ayuda).to.equal(true), 60000);
    cerrarAyuda();
    estado((actual) => {
      expect(actual.zona).to.equal('valdebronce');
      expect(actual.panel).to.equal(-1);
    }, 60000);
  });

  it('W18 | La primera expedición entra en la Bocamina', () => {
    cerrarAyuda();
    entrarEnLaMina();
    estado((actual) => expect(actual.planta).to.equal(1));
  });

  it('W19 | La mina empieza sin séquito ni ritual abierto', () => {
    cerrarAyuda();
    entrarEnLaMina();
    estado((actual) => {
      expect(actual.ritual).to.equal(false);
      expect(actual.esbirros).to.deep.equal([]);
    });
  });

  it('W20 | F abre y cierra el círculo de vínculos', () => {
    cerrarAyuda();
    entrarEnLaMina();
    tecla('f');
    estado((actual) => expect(actual.ritual).to.equal(true));
    tecla('f');
    estado((actual) => expect(actual.ritual).to.equal(false));
  });

  it('W21 | Z invoca un sabueso y la recarga bloquea X al instante', () => {
    cerrarAyuda();
    entrarEnLaMina();
    tecla('z');
    estado((actual) => expect(actual.esbirros).to.deep.equal(['sabueso']));
    tecla('x');
    estado((actual) => expect(actual.esbirros).to.deep.equal(['sabueso']));
    cy.press('f');
    estado((actual) => {
      expect(actual.ritual).to.equal(true);
      expect(actual.esbirros).to.deep.equal(['sabueso']);
    });
  });

  it('W22 | El botón del custodio lo invoca sin abrir el círculo', () => {
    cerrarAyuda();
    entrarEnLaMina();
    cy.get('#canvas').click(737, 600);
    estado((actual) => {
      expect(actual.ritual).to.equal(false);
      expect(actual.esbirros).to.deep.equal(['guardian']);
    });
  });

  it('W23 | H recupera la ayuda después de empezar', () => {
    cerrarAyuda();
    tecla('h');
    estado((actual) => expect(actual.ayuda).to.equal(true));
    tecla(Cypress.Keyboard.Keys.ESC);
    estado((actual) => expect(actual.ayuda).to.equal(false));
  });
});
