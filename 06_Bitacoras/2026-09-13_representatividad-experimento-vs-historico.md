# Bitácora — 2026-09-13: Representatividad de la muestra del experimento

## Qué se hizo

- Se creó `02_Scripts/12_representatividad_experimento_vs_historico.R`, a
  partir de código provisto por el usuario, que compara la muestra del
  experimento (`experimento_listos.RDS`, n=10,000) contra la población
  histórica (`observacional_limpio.Rds`, n=100,000) en las variables que
  comparten ambas bases (`time_spent`, `past_sessions`, `device_type`,
  `is_returning_user`, `os_type`), con la misma lógica que la tabla de
  balance tratamiento/control de `05_balance_experimento.R`.
- Se corrigieron dos referencias desactualizadas en los comentarios del
  código provisto: mencionaban `08_regresion_correlacional_observacional.R`,
  pero ese script quedó numerado `10_` (08 y 09 los ocupó la discontinuidad
  tiempo-revenue).
- El script produce: tabla de balance por característica
  (`datasummary_balance`), un test conjunto (modelo de probabilidad lineal
  `en_experimento ~ características` + F-test global, mismo enfoque que
  `05_balance_experimento.R`), magnitud de cada diferencia (puntos
  porcentuales para categóricas, unidades para numéricas — no solo
  p-valores, dado el desbalance de tamaños de muestra 100,000 vs. 10,000),
  y una tabla de referencia con `Revenue`/`sign_up` promedio en cada base
  (excluidos del test de representatividad por ser resultados, no
  características de composición).
- Todo se exporta a un único Excel:
  `03_Resultados/Tablas/representatividad_experimento_vs_historico.xlsx`.
- Se corrió el script completo sin errores.

## Por qué

- El usuario pidió evaluar si la muestra del experimento se parece a la
  población histórica de usuarios de CheMarket, como insumo para saber si
  el ITT estimado en `06_analisis_experimento.R` generaliza a toda la base
  de usuarios o si hay que acotar la conclusión a un subconjunto.

## Qué se descubrió

- N histórico: 100,000. N experimento: 10,000.
- Test conjunto: F=0.65, p=0.712 — no hay evidencia de que la pertenencia
  a la muestra del experimento sea predecible a partir de las
  características observables.
- Magnitud de las diferencias, todas pequeñas: `time_spent` +0.038,
  `past_sessions` +0.016; categóricas todas por debajo de 0.4 puntos
  porcentuales (`device_type`, `os_type`, `is_returning_user`).
- Referencia (outcomes, no entran al test): `Revenue` promedio 3.98
  (histórico) vs. 4.22 (experimento); `sign_up` 77.1% (histórico) vs.
  49.6% (experimento) — esta última diferencia es esperable por diseño
  (en el experimento la mitad recibe `easier_signup`), no indica falta de
  representatividad de las características de la muestra.
- Conclusión (tal como la deja el script, sin juicio de valor añadido):
  la muestra del experimento se parece a la población histórica en las
  características observables disponibles, tanto en significancia
  conjunta como en magnitud.

## Problemas / pendientes

- Ningún error de ejecución.
- Este script no usa `00_formato_graficas.R` porque no genera ninguna
  figura, solo tablas (igual que `11_prediccion_revenue_observacional.R`).
- Al revisar `git log` de esta sesión se encontró que un commit de
  "estandarización" (`6989d7d`, no originado en esta conversación) quitó
  la advertencia de causalidad inversa y el estado "CONFIRMADO/NO
  CONFIRMADO" del pie de figura de
  `08_discontinuidad_tiempo_revenue_observacional.R`
  (`observacional_relacion_tiempo_revenue.png`), como parte de
  estandarizar el formato de las figuras. No se modificó nada al respecto
  en esta sesión (no es parte de esta tarea); se deja anotado para que el
  equipo lo revise si le parece relevante.
