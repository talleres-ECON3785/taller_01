---
name: cerrar-sesion
description: Cierra una sesión de trabajo del taller — escribe la bitácora en 06_Bitacoras/ siguiendo el formato ya usado en el proyecto, y copia el registro crudo (.jsonl) de la conversación actual a una carpeta fuera del repo, en la carpeta local que contiene a taller1/. Usar cuando el usuario pida "cerrar sesión", "escribir la bitácora" o "guardar la conversación".
---

# Cerrar sesión de trabajo

Esta skill se usa al terminar una sesión de trabajo en este taller. Hace dos
cosas, en este orden:

1. Escribir la bitácora de la sesión en `06_Bitacoras/`.
2. Copiar el registro crudo (`.jsonl`) de la conversación actual a una carpeta
   fuera del repositorio (no se versiona con git).

No asumas contenido: básate solo en lo que realmente ocurrió en esta
conversación (usa `git status` / `git diff` para confirmar qué archivos
cambiaron si hay dudas). Si algo no es inferible con certeza — por ejemplo,
quién de los integrantes trabajó en la sesión, o un hallazgo ambiguo —
pregúntale al usuario en vez de adivinar.

## Paso 1: escribir la bitácora

Antes de escribir, abre 1-2 bitácoras existentes en `06_Bitacoras/` para
replicar el formato exacto (encabezados, tono, nivel de detalle). El formato
observado es:

```markdown
# Bitácora — YYYY-MM-DD: <descripción corta de la sesión>

## Qué se hizo

- ...

## Por qué

- ...

## Qué se descubrió

- ...

## Problemas / pendientes

- ...
```

Convención de nombre de archivo: `YYYY-MM-DD_slug-descriptivo.md` (minúsculas,
palabras separadas por guiones), igual que las bitácoras existentes. Usa la
fecha real de la sesión, no una relativa.

Contenido mínimo de cada sección:

- **Qué se hizo**: tareas realizadas, archivos creados/modificados, decisiones
  de especificación tomadas.
- **Por qué**: a qué pregunta del taller o parte del flujo (Crudos → Procesados
  → Listos, LPM, diseño del experimento, etc.) responde lo hecho.
- **Qué se descubrió**: hallazgos de datos o de diseño. Si se tomó una
  decisión metodológica relevante, regístrala también en la tabla "Decisiones
  tomadas" de `CLAUDE.md` (o en "Análisis descartados" si se descartó algo).
- **Problemas / pendientes**: errores, bloqueos, supuestos aún sin confirmar,
  tareas que quedan para la próxima sesión.

Respeta las reglas de `CLAUDE.md`: no juicios de valor sobre resultados, no
código en la bitácora si no aporta, reportar cuántas observaciones se pierden
en cualquier limpieza mencionada, etc.

## Paso 2: copiar el registro crudo de la conversación

El registro de la conversación actual vive como un archivo `.jsonl` dentro de
`~/.claude/projects/<slug-del-proyecto>/`. El destino es una carpeta **fuera
del repo git**, ubicada en la carpeta local que contiene a `taller1/` (un
nivel arriba de la raíz del repo) — nunca dentro del repositorio ni agregada a
git.

```bash
# 1. Ubicar la carpeta de proyecto de Claude Code para este repo
SLUG=$(pwd | sed -E 's/[^A-Za-z0-9]/-/g')
PROJDIR="$HOME/.claude/projects/$SLUG"

# 2. Identificar el archivo .jsonl de la sesión actual: es el modificado
#    más recientemente (la sesión activa se sigue escribiendo mientras
#    conversas)
SESSION_FILE=$(ls -t "$PROJDIR"/*.jsonl | head -1)

# 3. Determinar la carpeta madre del repo y crear ahí, si no existe,
#    la carpeta de conversaciones
REPO_ROOT=$(git rev-parse --show-toplevel)
PARENT_DIR=$(dirname "$REPO_ROOT")
DEST_DIR="$PARENT_DIR/Conversaciones_Claude"
mkdir -p "$DEST_DIR"

# 4. Copiar (nunca mover) el archivo crudo, con nombre que incluya la fecha
cp "$SESSION_FILE" "$DEST_DIR/$(date +%Y-%m-%d)_$(basename "$SESSION_FILE")"
```

Reglas para este paso:

- Es una copia, no un movimiento: el archivo original en
  `~/.claude/projects/...` no se toca.
- El archivo copiado nunca se agrega a git ni se referencia desde la
  presentación o los scripts del taller.
- Si `PROJDIR` no existe o no hay ningún `.jsonl`, informa al usuario en vez de
  fallar en silencio o de improvisar una ruta distinta.

## Notas

- Sigue todas las reglas de `CLAUDE.md` (rutas relativas ancladas al proyecto,
  nunca modificar `01_Datos/01_Crudos/`, comentarios de código en español,
  etc.) al crear cualquier archivo.
- Si el usuario solo pide una de las dos partes (por ejemplo, "solo escribe la
  bitácora"), haz solo esa parte.
