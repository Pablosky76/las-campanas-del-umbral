# Las Campanas del Umbral

ARPG en GDScript para Godot 4. Abre `project.godot` con **Importar** en el gestor de proyectos y pulsa **F5**. Probado con Godot 4.7.2 estándar.

| Acción | Teclado y ratón | Táctil en horizontal |
| --- | --- | --- |
| Moverse | WASD o flechas. En Valdebronce también puedes hacer clic en el suelo. | Joystick. En Valdebronce también puedes tocar el suelo. |
| Entrar en un edificio | E o clic | Toca el edificio o Entrar |
| Seleccionar opción | 1, 2, 3 o clic | Toca la opción |
| Abrir talentos y mochila en el pueblo | T e I | Botones Talentos y Mochila |
| Atacar | Espacio | Ataque |
| Marcar y dar la orden de atacar | Clic en el enemigo y E | Toca al enemigo y pulsa Orden |
| Elegir tus invocaciones | F, luego + o − junto a cada tipo | Invocaciones, luego + o − |
| Reponer esbirros caídos | Q | Toque en Campana |
| Reagrupar | R | Mantén Campana pulsada y suéltala |
| Defenderse | Mayús | Defensa |

La forja de Mara prepara una formación inicial que puedes modificar al entrar en la mina. Hay seis vínculos disponibles. El guardián ocupa dos y solo puedes llevar uno. Durante el combate puedes cambiar el grupo con F. Las nuevas invocaciones comparten la recarga de la campana. Q recupera las bajas de la composición que elegiste.

En el pueblo, abre la mochila con I. Arrastra el objeto a su ranura o selecciónalo y pulsa Equipar. Para quitarlo, arrástralo a la mochila o pulsa Quitar. Los tintes debajo del retrato se guardan y se ven tanto en Valdebronce como al combatir.

Los enemigos marcan en el suelo dónde van a golpear. Sal del área y reúne a tus esbirros con R si hay riesgo de que les alcance el golpe. Los acechadores, teñidos de rojo, buscan al Vinculador. Marcar un objetivo aumenta el daño coordinado de los esbirros sobre él. La defensa reduce el golpe durante 0,6 s y tarda 3,2 s en recargarse.

 En la entrada de la mina, selecciona cualquier planta desbloqueada. Tu primer descenso empieza en la Bocamina. Si limpias una planta, puedes seguir o volver a Valdebronce para gastar puntos y equiparte. Los accesos, la XP, los talentos, el equipo, el plano y las victorias contra el capataz se conservan al volver, morir o cerrar el juego. Las recompensas son de primera entrega. Continuar mantiene la reliquia y repone al grupo. Un nuevo intento reinicia los encuentros y la reliquia.

- **−1 · Bocamina.** Marca al minero que viene por el lateral y reagrupa cuando se dividan tus esbirros. La primera victoria da un bastón y un punto de talento.
- **−2 · Raíles partidos.** Coloca a los ballesteros en los pasos estrechos. El desvío opcional anuncia su amuleto y su XP.
- **−3 · Sala de bombas.** Recupera el plano de Mara, elige una reliquia y vigila la compuerta y la carga del capataz. Vencerlo desbloquea la bendición de Elías.
- **−4 · Viviendas ciegas.** Responde a la primera pareja de mineros y usa el aviso para preparar la llegada de refuerzos por el norte.
- **−5 · Osario de cal.** Interrumpe la reanimación derrotando al enterrador. El amuleto de cal convierte los disparos de tus ballesteros en virotes perforantes que ralentizan.

La configuración de los encuentros vive en `plantas.gd`. El perfil usa `user://valdebronce.cfg`, el mismo archivo que la versión anterior. Los perfiles de la Sala de bombas conservan su progreso de personaje y comienzan la nueva ruta en la −1.

## Descenso profundo

| Planta | Encuentro | Botín de primera victoria |
| --- | --- | --- |
| −6 · Coro de sal | El corista sana a los enemigos cercanos al terminar el cántico. | Vara del coro |
| −7 · Fundición sepultada | El verdugo carga mientras franjas alternas del suelo expulsan brasas. | Cota de la fundición |
| −8 · Campanario hundido | El Campanero anuncia una onda a su alrededor y llama a dos ecos al quedar herido. | Corazón de la campana |

Si ya completaste la −5, la −6 se desbloquea al cargar tu perfil. Puedes volver al pueblo entre plantas y retomar el tramo desde el ascensor.

### Contenido añadido

- **Horno sellado.** Desvío opcional tras limpiar la −7. Un verdugo y un corista guardan el Talismán del horno.
- **Equipo adicional.** Tres recompensas del descenso profundo y el nuevo Broquel de Mara, a la venta al acceder a la −6. La mochila y la tienda admiten páginas.
- **Contratos de Inés.** La hospedería paga tres encargos de primera entrega: silenciar el coro, abrir el horno y derrotar al Campanero. Las victorias anteriores también cuentan.
- **Cuaderno de Inés.** Describe los ataques de los tres nuevos enemigos. Las páginas se abren al desbloquear sus plantas.

## Tienda de Mara

Entra en la forja de Valdebronce y elige **Comprar y vender** (tecla 4). Mara vende una vara de fresno, una cota y un sello para ballesteros. Empiezas con 26 de cobre y recibes más al cobrar por primera vez las recompensas de la mina. Si ya habías completado plantas antes de esta actualización, recibes su cobre al cargar el perfil.

Para vender una pieza equipada, quítatela en la mochila. Las piezas vendidas aparecen en Comprar y puedes recuperarlas por el mismo importe. El saldo y cada trato se guardan junto a tu equipo. Se comprobaron compra, venta, recompra, saldo insuficiente, carga de un perfil anterior y recompensas sin duplicar.

## Personajes

El Vinculador empieza con el aspecto Nigromante. Pulsa el botón de aspecto en la mochila para alternar con Capa azul. Se guarda junto al tinte.

El Vinculador, el sabueso, el ballestero y el guardián se construyen con mallas 3D articuladas de Godot. Giran hacia el movimiento y al atacar. Las ilustraciones se usan en la mochila y en el panel de invocaciones. En el modelo, Capa azul cambia el acabado de la tela. Los anillos de suelo distinguen al Vinculador (turquesa), al sabueso (gris claro), al ballestero (lila) y al guardián (dorado).

Las figuras se balancean ligeramente al andar y se apoyan sobre la pasarela elevada de la Sala de bombas. El farol está anclado al bastón y gira con él. Se comprobaron las mallas, sus articulaciones, el giro y el anclaje del farol, y se repitieron los recorridos automatizados. La revisión visual en ventana sigue pendiente.

## Séquito del Vinculador

El farol del Nigromante ilumina el escenario y aumenta su brillo al atacar o dar la orden de concentrar el fuego. Invocar hace aparecer un círculo de restos espectrales bajo cada esbirro. El círculo de vínculos muestra qué aporta cada criatura.

- **Sabueso osario.** Corre más rápido hacia la presa marcada. Hace un 40 % más de daño si está por debajo del 35 % de vida y recupera 10 de vida al rematarla.
- **Ballestero de cripta.** Cada tercer virote es un grillete visible que ralentiza durante 1,45 s si impacta. Puede fallar o chocar contra cobertura como cualquier otro virote.
- **Custodio sepulcral.** Ocupa dos vínculos. Intercepta cargas y absorbe un 28 % del daño dirigido al Vinculador cuando está cerca y tiene línea directa. El daño absorbido le resta vida al custodio.

## Música

Dos bucles originales de ambiente acompañan la plaza y las minas. La transición entre ambos es gradual. Pulsa M para silenciar o recuperar la música. En pantallas táctiles, toca Música en Valdebronce. El ajuste se guarda entre sesiones.

## Escenarios 3D

Valdebronce recupera la ilustración original y superpone una capa 3D transparente con chispas en la forja y accesorios junto a la mina. Las cinco plantas se renderizan con cámara ortográfica e iluminación 3D. Las minas reutilizan `GridMap` y `MeshLibrary` para sus suelos. Cada planta tiene sus propias estructuras y materiales. En la −3, la bomba y la compuerta se animan durante el combate. La pasarela permite cruzar el canal inundado y los pilares de las minas bloquean físicamente el paso y la línea de tiro. El personaje y sus esbirros usan modelos con volumen. Los enemigos también tienen mallas articuladas: los mineros llevan pico y casco con lámpara, los acechadores llevan garras, y los coristas, verdugos y campaneros tienen equipo propio. Reciben la iluminación de la sala, tienen sombra de contacto y pueden quedar parcialmente ocultos por paredes y pilares. Los avisos y la interfaz se dibujan por encima para que sigan siendo legibles.

Los ballesteros lanzan virotes con malla 3D de astil, punta y plumas. Recorren la trayectoria antes de aplicar daño. Pueden fallar si el objetivo se aparta o si chocan con cobertura. Los virotes perforantes atraviesan varios enemigos y el amuleto de cal aplica la ralentización al impactar.

Las minas usan una contraluz fría y los modelos proyectan sombras a partir de un número limitado de piezas articuladas. Si un pilar tapa al Vinculador, su parte superior se recoge visualmente. La base conserva sus colisiones y sigue bloqueando los disparos.

## Verificación

**Automatizada en Godot 4.7.2.** Se simularon recorridos completos hasta la −8 desde perfiles nuevos con formación mixta y enjambre, usando movimiento, marcas, órdenes, ataque y reposición. Se comprobó el desvío de élite, desbloqueos en orden, recompensas sin duplicar, regreso a Valdebronce, aprendizaje y equipamiento, efecto de ralentización, derrota, reapertura del proceso y carga y escritura de un perfil con el formato anterior. También se verificaron el arrastre de piezas, la persistencia de tintes, los límites de invocación y la recarga al cambiar la composición. En simulaciones pasivas, el Vinculador perdió en la Bocamina y en el Osario. En la −3 se comprobó la alineación entre cámara y sprites, la elevación de la compuerta, el daño en el canal, el paso seguro por la pasarela y la transición a la −4. También se comprobó la creación de la plaza y las cinco plantas 3D, y que los virotes aplican daño al llegar, perforan, ralentizan con el amuleto y chocan contra un pilar. Se comprobó también la migración desde la −5, las mallas de enemigos, el cántico de curación, las brasas, la campanada, el Horno sellado, el cobro único de encargos y la paginación. También se comprobaron el recorte visual de los pilares, sus colisiones, el vuelo y la retirada de las mallas de virote y la configuración de sombras. Las pruebas escribieron perfiles aislados porque el entorno de ejecución restringe el acceso a la carpeta de partidas de macOS.

**Juego manual y móvil físico.** Pendientes. La simulación comprueba que se puede llegar a la −5 con ambas formaciones sin repetir plantas, pero el ritmo y la legibilidad táctil requieren una partida manual.

## Pruebas automatizadas

La [guía de QA](qa/README.md) explica las 36 pruebas de Godot y los 20 casos de Cypress desde cero, cómo ejecutarlas en local y cómo leer GitHub Actions.
