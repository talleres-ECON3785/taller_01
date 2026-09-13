# Bitácora — 2026-09-12: Diseño del estimando para el efecto de `easier_signup`

## Qué se hizo

- Se dejó planteado el archivo `02_Scripts/06_analisis_experimento.R`, con el
  seteo inicial del análisis del experimento: carga de `tidyverse` y
  `ggplot2`, lectura de `01_Datos/03_Listos/experimento_listos.RDS`, y
  creación de tres variables transformadas (`log_revenue`, `log_time_spent`,
  `log_past_sessions`) a partir de `Revenue`, `time_spent` y `past_sessions`.
  No se corrió ninguna regresión todavía.
- Se sostuvo una discusión conceptual (sin código nuevo) sobre qué variable de
  resultado debe ser el foco de la parte experimental del análisis: `sign_up`
  o `Revenue`.
- En esa discusión se repasaron y corrigieron los conceptos de efecto de
  intención de tratar (ITT), efecto causal de `sign_up` sobre `Revenue`,
  estimador IV/Wald, LATE y monotonicidad (compliers, always-takers,
  never-takers, defiers).

## Por qué

- Por la regla de "primero el diseño, después los resultados" del proyecto,
  antes de correr cualquier regresión sobre `experimento_listos.RDS` es
  necesario fijar qué estimando responde la pregunta de negocio ("¿debería
  CheMarket invertir en impulsar `sign_up` para aumentar `Revenue`?") y qué
  supuestos hacen falta para interpretar cada número como causal.
- `easier_signup` es la única variable que CheMarket puede manipular
  directamente (es la política); `sign_up` es un resultado intermedio, no la
  palanca de decisión. Eso determina cuál debe ser el estimando central.

## Qué se descubrió

- El estimando central que responde la pregunta de negocio es el ITT: el
  efecto de `easier_signup` sobre `Revenue`. El efecto de `easier_signup`
  sobre `sign_up` (primer estadio) es un mecanismo que explica el ITT, no la
  respuesta en sí misma.
- El efecto causal de `sign_up` sobre `Revenue` (lo que en la conversación se
  llamó "el efecto de tratamiento como tal") no es identificable
  directamente, porque en el experimento se asignó aleatoriamente
  `easier_signup`, no `sign_up`.
- El cociente ITT(`Revenue`) / primer estadio (efecto sobre `sign_up`) es un
  estimador tipo Wald/IV de ese efecto. Que la asignación de `easier_signup`
  haya sido aleatoria solo garantiza su **exogeneidad**; para interpretar el
  cociente como causal hacen falta además:
  - **Relevancia**: que `easier_signup` mueva `sign_up` de forma no trivial
    (testeable con el primer estadio).
  - **Exclusión**: que `easier_signup` afecte `Revenue` únicamente a través
    de `sign_up`, sin efecto directo (no testeable con los datos; requiere
    argumento sustantivo).
  - Si se quiere interpretar como LATE (efecto sobre compliers), además
    **monotonicidad** (no hay "defiers").
- Se corrigió una confusión sobre monotonicidad: que existan usuarios que se
  registran sin tener `easier_signup` (always-takers) o que no se registran
  teniéndolo (never-takers) **no** viola monotonicidad. Solo la violaría un
  tipo "defier" (se registraría si NO tiene `easier_signup`, pero no si lo
  tiene), que no es lo que se había planteado como objeción.
- Esta decisión de diseño (ITT sobre `Revenue` como estimando central,
  `sign_up` como mecanismo) se registró en la tabla "Decisiones tomadas" de
  `CLAUDE.md`.

## Problemas / pendientes

- Falta argumentar explícitamente el supuesto de exclusión antes de reportar
  el cociente IV/Wald como el efecto causal de `sign_up` sobre `Revenue`.
- Siguen pendientes las regresiones señaladas en la bitácora anterior
  (`2026-09-12_balance-experimento.md`): `sign_up ~ easier_signup` (primer
  estadio, LPM) y `Revenue ~ easier_signup` (ITT), que son las que deben
  correrse en `06_analisis_experimento.R`.
- Falta confirmar si conviene reportar el cociente IV/Wald en la
  presentación final o limitarse al ITT sobre `Revenue`, dado que el supuesto
  de exclusión no es verificable.
