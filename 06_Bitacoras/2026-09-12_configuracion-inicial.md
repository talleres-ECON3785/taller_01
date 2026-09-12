# Bitácora — 2026-09-12: Configuración inicial del proyecto

## Qué se hizo
- Se creó la estructura de carpetas del proyecto (`01_Datos` con subcarpetas
  Crudos/Procesados/Listos, `02_Scripts`, `03_Resultados` con Tablas/Figuras,
  `04_Presentaciones`, `05_Notas`, `06_Bitacoras`, `07_Recursos`,
  `08_Entregables`), con `.gitkeep` en las carpetas vacías.
- Se redactó `CLAUDE.md` con las reglas de trabajo del proyecto y se agregaron
  las secciones para trabajo colaborativo: Integrantes, Decisiones tomadas,
  Análisis descartados, Definición de variables, Restricciones de muestra,
  Estado actual y Reglas estrictas.
- Se contextualizó `CLAUDE.md` con el enunciado del Taller 1 (ECON-3785): la
  pregunta de negocio de CheMarket, el rol distinto de `observacional.Rds` y
  `experimento.Rds`, la regla de usar solo regresión lineal, la semilla de
  reproducibilidad (2026) y los lineamientos de la presentación final
  (estilo *answer-first*, sin código).
- Se completó la tabla de Integrantes con los cinco miembros del grupo y sus
  responsabilidades.
- Se prellenó la tabla de Definición de variables con las 7 variables del
  enunciado (`Revenue`, `sign_up`, `time_spent`, `past_sessions`,
  `device_type`, `is_returning_user`, `easier_signup`), marcando como
  pendientes de confirmar la moneda/impuestos de `Revenue` y la unidad de
  `time_spent`.

## Por qué
- El taller lo trabajarán varias personas durante varias semanas; documentar
  desde el inicio las reglas, la estructura y las definiciones evita
  ambigüedad y decisiones no justificadas más adelante.

## Qué se descubrió
- El enunciado no especifica unidades para `Revenue` (moneda, si incluye
  impuestos) ni para `time_spent` (segundos/minutos); queda pendiente
  confirmarlo al inspeccionar los datos reales.

## Problemas / pendientes
- Aún no se han descargado `observacional.Rds` ni `experimento.Rds` desde
  Bloque Neón hacia `01_Datos/01_Crudos/`.
- No se ha escrito ningún script todavía.
- Las tablas de Decisiones tomadas, Análisis descartados y Restricciones de
  muestra quedan vacías hasta que empiece el análisis.
