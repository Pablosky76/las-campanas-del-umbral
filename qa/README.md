# Pruebas de Las Campanas del Umbral

La batería tiene **56 casos**. Godot ejecuta 36 casos de reglas y escenas. Cypress ejecuta 20 casos en Chrome. El smoke público vuelve a ejecutar 10 de esos casos sobre GitHub Pages.

| Casos | Qué comprueban | Archivo |
| --- | --- | --- |
| C01–C14 | Formaciones, ritual, órdenes, virotes, efectos, custodia y pasarela | [suite.gd](godot/suite.gd) |
| P01–P14 | Desbloqueos, XP, recompensas, guardados antiguos, derrota, élite y las dos rutas hasta la −8 | [suite.gd](godot/suite.gd) |
| E01–E08 | Compra, venta, recompra, equipamiento y contratos | [suite.gd](godot/suite.gd) |
| W01–W06 | Documento HTML, título, viewport, canvas y rutas relativas | [01-portada.cy.js](web/cypress/e2e/01-portada.cy.js) |
| W07–W10 | JavaScript, WebAssembly, paquete del juego y arranque con foco | [02-exportacion.cy.js](web/cypress/e2e/02-exportacion.cy.js) |
| W11–W20 | Plaza, movimiento, mochila, talentos, música, recarga, acceso a Bocamina y ritual | [03-partida.cy.js](web/cypress/e2e/03-partida.cy.js) |

## Godot desde cero

GDScript es el lenguaje del juego. Aquí las pruebas son otro script de GDScript que Godot ejecuta con `--headless`, es decir, sin abrir ventana. El script registra casos con nombre, los ejecuta y devuelve código de salida 1 si falla cualquiera. Cada caso crea un perfil nuevo o añade una escena real al árbol de Godot. Se borran las escenas y archivos de prueba al terminar.

Desde la carpeta donde está `project.godot`, en tu Mac:

```bash
GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot qa/godot/run.sh
```

Si el comando `godot` ya está disponible en el PATH, basta con `qa/godot/run.sh`. El script importa texturas y audio y después ejecuta la batería. La salida lleva identificadores, por ejemplo `ok 7 - C07 | El pilar detiene el virote`. Busca `not ok` y el identificador en el código si falla un caso. Si Godot encuentra un error de sintaxis, el script falla antes de ejecutar los casos.

### Cómo leer una prueba

En [C07](godot/suite.gd), `mina(3)` abre la Sala de bombas con un perfil temporal. Se coloca un ballestero y un adversario en lados opuestos del pilar. El caso llama a `shoot()`, avanza el virote durante 0,30 s y comprueba dos cosas: que el virote deje de viajar y que el adversario mantenga sus 60 puntos de vida. Así se reproduce la colisión usando el código del juego.

Las pruebas de recorrido completo avanzan la física en pasos de 1/60 s y dan órdenes al equipo hasta superar cada planta. Sirven para comprobar la progresión y el combate con entradas reproducibles. La iluminación, el sonido percibido y el equilibrio en manos de un jugador se revisan en una partida con ventana.

### Cómo añadir un caso

1. Añade una función que devuelva `bool`, por ejemplo `func c15() -> bool:`.
2. Prepara su estado inicial con `perfil()` o `mina()`. Esos ayudantes asignan una ruta de guardado dentro del directorio temporal.
3. Llama a la función del juego que quieras comprobar y devuelve una expresión con el resultado esperado.
4. Registra la función en la lista `casos` de `run()`, ponle un nombre que explique qué debería ocurrir y ejecuta de nuevo la batería.

## Cypress

Necesitas Node 22, Chrome y una exportación Web servida por HTTP. Para comprobar la web publicada:

```bash
npm ci --prefix qa/web
UMBRAL_WEB_URL=https://pablosky76.github.io/las-campanas-del-umbral/ \
  npm run test:public --prefix qa/web
```

### Los 20 casos en local

Instala las plantillas Web de Godot 4.7.2. Crea un commit local con los cambios que quieras exportar y ejecuta desde la raíz del repositorio:

```bash
temporal="$(mktemp -d)"
mkdir -p "$temporal/proyecto" "$temporal/site"
git archive HEAD | tar -x -C "$temporal/proyecto"
cp qa/web/godot-probe.gd "$temporal/proyecto/godot-probe.gd"
printf '\n[autoload]\n\nUmbralQA="*res://godot-probe.gd"\n' >> "$temporal/proyecto/project.godot"
GODOT=/Applications/Godot.app/Contents/MacOS/Godot
"$GODOT" --headless --path "$temporal/proyecto" --import
"$GODOT" --headless --path "$temporal/proyecto" --export-release Web "$temporal/site/index.html"
python3 -m http.server 4173 --bind 127.0.0.1 --directory "$temporal/site"
```

En otra terminal, desde la raíz, ejecuta `npm test --prefix qa/web`. Con `npx --prefix qa/web cypress open --project qa/web` puedes usar el modo interactivo con la misma exportación.

El autoload de QA muestra en un atributo HTML un resumen de solo lectura de la zona, posición y panel activos. Cypress mueve al personaje con clics y teclas. El atributo le permite verificar el resultado en vez de buscar texto dentro del canvas. La compilación de GitHub Pages se genera desde el proyecto principal sin ese autoload.

## GitHub Actions

Abre **Actions → Probar y publicar juego web**. En un pull request el flujo ejecuta Godot, exporta la compilación temporal y pasa Cypress en Chrome. En `main`, cuando pasan las dos baterías, exporta y publica el juego. Después lee el identificador del commit en `version.txt` y vuelve a probar el arranque público.

En **Artifacts → resultados-qa** están el listado de casos de Godot, los XML de Cypress y las capturas de los fallos si las hay. El smoke posterior guarda su informe en **resultados-smoke-publico**. Las capturas se generan en el navegador de CI y los recorridos de Godot se ejecutan sin ventana. La prueba manual en móvil físico queda fuera de esta batería.
