# Bitácora — 2026-09-13: Regresión correlacional sign_up/time_spent sobre log(Revenue)

## Qué se hizo

- Se creó `02_Scripts/10_regresion_correlacional_observacional.R`, a partir
  de código provisto por el usuario, que parte de
  `observacional_limpio.Rds` y estima la asociación entre `sign_up` y
  `log(Revenue)` en tres especificaciones (simple, con controles
  observables, y agregando `log(time_spent)` como análisis de
  sensibilidad), con `modelsummary` para la tabla comparativa e
  intervalos de confianza del coeficiente de `sign_up`.
- Se agregó una sección nueva al final del script, delimitada con
  `### Elasticidad time_spent (log-log) ###`, sin modificar nada de las
  tres especificaciones existentes:
  - `log_revenue ~ log_time_spent` (simple).
  - `log_revenue ~ log_time_spent + past_sessions + is_returning_user + device_type + os_type`
    (con controles; `sign_up` deja explícitamente fuera, comentado como
    pendiente de decisión del equipo).
  - Se verificaron valores de `Revenue`/`time_spent` ≤ 0 reutilizando las
    variables que el propio script ya calculaba (`n_revenue_no_positivo`,
    `n_time_no_positivo`), sin releer el `.Rds` por separado: 0 casos en
    ambas variables.
  - Se documentó explícitamente por qué no se hace una versión con
    `log(sign_up)` (binaria, `log(0)` indefinido, la elasticidad no
    aplica a una variable de dos valores).
  - Se reporta en consola, por modelo: coeficiente de `log(time_spent)`
    interpretado como elasticidad, error estándar, p-valor, R² y N, sin
    lenguaje de "bueno/malo" sobre el tamaño del coeficiente.
  - Resultados guardados en
    `03_Resultados/Tablas/tabla_elasticidad_timespent_observacional.csv`
    (nombre distintivo para evitar colisión con tablas del experimento).
- Se corrió el script completo dos veces (antes y después de agregar la
  sección de elasticidad) para confirmar que las tres especificaciones
  originales no cambiaron y que la sección nueva corre sin errores.

## Por qué

- El usuario pidió formalizar, en un script versionado, la asociación
  `sign_up`-`Revenue` en datos históricos (hasta ahora solo explorada de
  forma ad hoc), dejando explícito en todo momento que es correlacional
  y no causal, y separando esa pregunta de la elasticidad
  `time_spent`-`Revenue` (relacionada con el script de discontinuidad de
  la sesión anterior, `08_discontinuidad_tiempo_revenue_observacional.R`).

## Qué se descubrió

- Coeficiente de `sign_up` sobre `log(Revenue)`: 0.102 (simple) → 0.080
  (con controles observables) → 0.047 (agregando `log(time_spent)`),
  significativo en los tres casos (disminuye de magnitud al agregar
  controles, sin cambiar de signo).
- Elasticidad de `Revenue` respecto a `time_spent`: ≈0.169% de cambio en
  Revenue por 1% de cambio en time_spent, estable entre el modelo simple
  (0.1685) y el modelo con controles (0.1686). Estadísticamente
  significativa en ambos (p < 2e-16, subdesborda a 0 en doble precisión
  con t≈140-148 y n=100,000; se verificó que es un subdesbordamiento
  numérico real, no un error de formato).
- R² sube de 0.165 (log-log simple) a 0.250 (con controles).

## Problemas / pendientes

- Ningún error de ejecución.
- Queda pendiente de decisión del equipo si `sign_up` debe entrar como
  control adicional en el modelo log-log con controles (se dejó fuera a
  propósito, documentado en el script).
- `modelo_log_tiempo` (Modelo 3, del código original del usuario) solo se
  define dentro de un `if (n_time_no_positivo == 0)`; si en el futuro
  `time_spent` llegara a tener valores ≤0, el script fallaría más abajo
  (en `modelos_log` y en `confint(modelo_log_tiempo)`) con un error de
  "objeto no encontrado" en vez del mensaje explicativo ya escrito. Con
  los datos actuales no ocurre (0 casos), se señaló al usuario y no se
  modificó sin su aprobación.
- Siguen sin tocar (no son de esta tarea):
  `01_Datos/02_Procesados/observacional_limpio_BACKUP.Rds`,
  `03_Resultados/Tablas/~$balance_experimento.xlsx` (lock de Excel) y
  `06_Bitacoras/2026-09-13_auditoria-pipeline-experimento.md`.
