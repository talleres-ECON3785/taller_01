# Bitácora — 2026-09-12: Balance de covariables en `experimento_listos.RDS`

## Qué se hizo

- Se construyó `02_Scripts/05_balance_experimento.R`, que carga
  `01_Datos/03_Listos/experimento_listos.RDS` y produce dos verificaciones de
  balance entre los grupos de `easier_signup`:
  - Una tabla de balance por covariable (`datasummary_balance()` de
    `modelsummary`), sobre `device_type`, `os_type`, `is_returning_user`,
    `past_sessions` y `time_spent`. Se excluyeron explícitamente `sign_up` y
    `Revenue` del set de covariables porque son resultados (outcomes) del
    experimento, no covariables de pre-tratamiento. Se configuró
    `dinm_statistic = "p.value"` para reportar el p-valor de la diferencia de
    medias (en vez del error estándar, que es el valor por defecto).
  - Un test conjunto de balance: un modelo de probabilidad lineal
    `easier_signup ~ device_type + is_returning_user + past_sessions +
    time_spent`, usando el F-test global de esa regresión (H0: todos los
    coeficientes son cero) como prueba única de que la asignación al
    tratamiento no está correlacionada con el conjunto de covariables. Esto
    evita el problema de comparaciones múltiples de evaluar cada covariable
    por separado.
- Se encontró y documentó una limitación de `modelsummary`: los nombres
  `"statistic"` y `"p.value"` no se pueden usar como `raw` dentro de
  `gof_map`, porque el paquete los reserva para las estadísticas de
  incertidumbre de los coeficientes (t-valor y p-valor por variable) y
  descarta la fila si se usan ahí. El F-test global (extraído con
  `broom::glance()`) se agregó en cambio como fila manual con `add_rows`.
- Se exportaron ambas tablas (balance por covariable y test conjunto) a
  `03_Resultados/Tablas/balance_experimento.xlsx`, un único libro con una
  hoja por tabla (`balance`, `test_conjunto`), usando `writexl::write_xlsx()`
  sobre las mismas tablas obtenidas con `output = "data.frame"`.
- Se agregó `writexl` como dependencia del script (ya se usaba en
  `03_descriptivas_experimento.R`).

## Por qué

- Antes de interpretar cualquier resultado del experimento A/B es necesario
  verificar que la asignación a `easier_signup` fue efectivamente aleatoria:
  que las covariables de pre-tratamiento no difieren sistemáticamente entre
  los grupos de tratamiento y control. Sin esa verificación, cualquier
  comparación posterior de `sign_up` o `Revenue` entre grupos sería difícil
  de interpretar como efecto causal.
- El test conjunto complementa la tabla de balance por covariable: la tabla
  responde "¿esta covariable en particular está balanceada?" (una prueba por
  variable), mientras que el F-test responde "¿el conjunto de covariables,
  tomado en conjunto, predice el tratamiento?" (una sola prueba, sin inflar
  la probabilidad de un falso positivo por comparaciones múltiples).
- Exportar a Excel deja las tablas disponibles para el equipo y como insumo
  de la presentación al cliente, que no debe incluir código.

## Qué se descubrió

- El F-test conjunto de las covariables sobre `easier_signup` no aporta
  evidencia de desbalance (N = 10.000, R² = 0.001).
- Se aclaró una duda que había quedado abierta en la bitácora de
  descriptivas (`2026-09-12_descriptivas-experimento.md`): la tabla de
  balance **no** responde si `easier_signup` y `sign_up` están
  relacionados, porque `sign_up` fue excluido a propósito de esa tabla (es
  un resultado, no una covariable de pre-tratamiento). Esa pregunta —el
  efecto de `easier_signup` sobre `sign_up`— es el estimando central del
  experimento y requiere una regresión aparte (`sign_up ~ easier_signup`,
  LPM) que todavía no se ha corrido en el proyecto.

## Problemas / pendientes

- Falta el script que estime el efecto de `easier_signup` sobre `sign_up`
  (y sobre `Revenue`), que es la pregunta pendiente identificada arriba.
- La limitación de `gof_map` con `"statistic"`/`"p.value"` en `modelsummary`
  no está documentada en ningún lugar del proyecto fuera de esta bitácora;
  si se vuelve a necesitar un test conjunto en otro script, revisar aquí el
  patrón usado (`add_rows` con `broom::glance()`).
