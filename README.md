# JuegoSuperpro

MVP de un juego 2D de exploración y plataformas, inspirado en la exploración y progresión de **Hollow Knight**, con algunas mecánicas de movimiento estilo **Cuphead** (doble salto y dash).

Esta primera entrega cubre aproximadamente el **30% del mundo** planeado: movimiento, salto, doble salto, dash, un NPC con diálogo y zonas del mapa pensadas para habilidades futuras.

---

## 🎮 Controles

| Acción | Tecla |
|---|---|
| Moverse | `A` / `D` o flechas ← → |
| Saltar | `Espacio` |
| Doble salto | `Espacio` (en el aire) |
| Dash | `Shift` |
| Interactuar / hablar | `E` |

## 🧪 Shortcuts de testing

Para poder probar rápido las habilidades sin tener que jugar desde cero:

| Tecla | Efecto |
|---|---|
| `H` | Activa / desactiva el **doble salto** |
| `J` | Activa / desactiva el **dash** |

Cada vez que se presionan, el estado queda impreso en la consola de salida de Godot (`Doble salto activado/desactivado`, `Dash activado/desactivado`), para verificar en el momento qué habilidad está prendida.

---

## ▶️ Cómo correr el proyecto

1. Abrir **Godot 4.6** (no usar versiones posteriores).
2. `Importar` → seleccionar la carpeta del proyecto (donde está `project.godot`).
3. Correr la escena principal `Scenes/Main.tscn` (F5 o el botón ▶ de play).

## 🗺️ Qué hay en esta entrega

- Exploración de un mapa con distintas alturas, plataformas y huecos.
- Movimiento, salto, doble salto y dash completamente jugables.
- Cámara que sigue al jugador.
- Un NPC con diálogo simple (se abre y se cierra con `E`, bloquea el movimiento mientras está abierto).
- Zonas del mapa intencionalmente inalcanzables con las habilidades actuales, pensadas para desbloquearse en futuras entregas.

## 📁 Estructura

```
Assets/     sprites y tiles del pack usado para el escenario y el personaje
Scenes/     Main, Player, NPC y la caja de diálogo
Scripts/    lógica de cada escena (un script por escena, sin managers extra)
```
