# JuegoSuperpro v0.1

Primera versión jugable y acotada de JuegoSuperpro: un juego 2D de exploración y plataformas inspirado en **Hollow Knight**, con doble salto y dash estilo **Cuphead**.

Esta versión incluye dos salas, un enemigo común y un jefe. Se abre y se juega sola, sin depender del proyecto completo.

## Cómo abrirlo

1. Abrir la carpeta con **Godot 4.6** (probado con 4.6.1).
2. Ejecutar con `F5`. El juego empieza en la Pradera.

## Controles

| Acción | Tecla |
|---|---|
| Moverse | `A` / `D` o flechas ← → |
| Saltar | `Espacio` |
| Doble salto | `Espacio` (en el aire) |
| Dash | `Shift` |
| Atacar | `K` o click izquierdo |
| Interactuar | `E` |

Shortcuts de testing: `H` activa/desactiva el doble salto y `J` el dash (el estado se imprime en la consola de Godot).

## Contenido

- **Pradera** (sala inicial): caracoles que patrullan y un murciélago que persigue al jugador. Por el techo se sube al Bosque.
- **Bosque**: pelea encerrada contra el **Guardián de Musgo**. Salta hacia el jugador y al caer manda ondas por el piso; cada tanto hace caer rocas del techo. En la segunda mitad de vida encadena dos saltos antes de descansar.

Ganarle al Guardián abre las rejas y recupera toda la vida. Esta versión no tiene pantalla de victoria.

## Combate

- 5 corazones. Los enemigos, los ataques del jefe y caer por un hueco quitan uno.
- Al recibir un golpe hay retroceso y un segundo de invulnerabilidad frente a los enemigos. Caer al vacío quita un corazón igual.
- Al morir se recarga la sala y se aparece en la última puerta por la que se entró, con la vida completa.

## Estructura

```
Assets/          sprites usados por estas dos salas
Scenes/          jugador, HUD, caja de diálogo, puertas, tileset y animaciones
Scenes/Rooms/    Pradera y Bosque
Scenes/Enemies/  caracol, murciélago, Guardián de Musgo y sus ataques
Scripts/         lógica del juego y el autoload GameManager
Scripts/Enemies/ enemigos y jefe (base común en enemy.gd y boss.gd)
```

## Origen

Armado el 2026-10-26 a partir del proyecto principal JuegoSuperpro (commit `63b1cd2` más cambios sin commitear de esa fecha, incluidas las correcciones de la auditoría). Respecto de esos archivos, solo cambian:

- `project.godot`: nombre del proyecto y escena inicial (Pradera).
- `Scenes/Rooms/Pradera.tscn` y `Scenes/Rooms/Bosque.tscn`: se quitaron las puertas hacia salas que no forman parte de esta versión y se cerraron sus huecos en el mapa.
