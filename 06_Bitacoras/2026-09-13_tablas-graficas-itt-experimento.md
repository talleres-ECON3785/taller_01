# Bitácora — 2026-09-13: Tablas y gráficas del ITT, y descarte de IV/LATE

## Qué se hizo

- Se corrigió un bug en `02_Scripts/06_analisis_experimento.R`: al acortar el
  nombre `contingencia_signup_tratamiento_export` a
  `cont_signup_tratamiento_export`, quedaron dos referencias al nombre viejo
  que rompían la ejecución del script antes de llegar a los modelos del ITT.
- Se agregó `values_fill = 0` al `pivot_wider` de la tabla de contingencia
  `sign_up` x `easier_signup` (sin eso, los combos ausentes quedaban en `NA`
  en vez de 0), y se exportó una versión con etiquetas legibles y totales a
  `03_Resultados/Tablas/tabla_contingencia_signup_easier_signup.csv`.
- Se compararon dos alternativas para controlar por `past_sessions` en el ITT
  con controles, dado que `log(past_sessions)` genera `-Inf` en 519
  observaciones con `past_sessions == 0`: `log1p(past_sessions)` vs.
  `past_sessions` sin transformar. El coeficiente de `easier_signup` no
  cambia de forma relevante entre ambas; se dejó la versión sin transformar
  (`itt_controles_nivel`) en el script.
- Se construyó una tabla `modelsummary` comparando `itt_sencillo` e
  `itt_controles_nivel`, con etiquetas en español, niveles de referencia
  explícitos para las variables categóricas, y solo `Num.Obs.`/`R²` como
  bondad de ajuste. Se exportó a
  `03_Resultados/Tablas/tabla_itt_experimento.docx` (vía `flextable`, ya
  instalado).
- Se agregaron dos chequeos de especificación al final del script: (1)
  `log_time_spent ~ easier_signup`, para evaluar si `time_spent` es un mal
  control (mediador) del ITT; (2) el primer estadio `sign_up ~ easier_signup`,
  para evaluar si tenía sentido profundizar en IV/LATE. Ambos se registraron
  en la tabla "Análisis descartados" de `CLAUDE.md`.
- Se construyeron dos gráficas para la presentación en `03_Resultados/Figuras/`:
  - `ingresos_promedio_control_tratamiento.png`: barras de ingreso promedio
    por grupo, con IC 95% y nota aclaratoria sobre la mediana.
  - `distribucion_ingresos_control_tratamiento.png`: nube de puntos (una
    sesión por punto) con una raya marcando la mediana de cada grupo (se
    descartó una versión inicial con boxplot por tener demasiados elementos
    visuales a la vez).
  - Ambas comparten paleta de color validada por accesibilidad (azul
    control / naranja tratamiento) y un tema visual común
    (`tema_presentacion`), extraído para no repetir código entre las dos.

## Por qué

- Corresponde a la sección 2 del script ("Relación entre `Revenue` y
  `easier_signup`"), que estima y comunica el ITT — el estimando central del
  experimento, según la decisión ya registrada en `CLAUDE.md`
  (2026-09-12).
- Las gráficas y tablas responden al pedido de dejar material listo para
  insertar en la presentación al cliente: sin código, con etiquetas en
  español, colores validados y legibles para público corporativo.

## Qué se descubrió

- El coeficiente del ITT sobre `easier_signup` (variable dependiente
  `log_revenue`) cambia de magnitud según los controles usados (0.0134 sin
  controles a 0.0042 con controles completos), pero ambas estimaciones son
  estadísticamente indistinguibles de cero. La prueba directa
  (`log_time_spent ~ easier_signup`, coeficiente no significativo) no
  sostiene la hipótesis de que `time_spent` sea un mediador/mal control que
  explique ese desplazamiento.
- El primer estadio `sign_up ~ easier_signup` tiene coeficiente exactamente 1
  (por la correspondencia perfecta entre ambas variables ya encontrada en
  sesión previa). Por lo tanto, LATE = ITT / 1 = ITT: profundizar en IV/LATE
  no aportaría información adicional a la ya obtenida con el ITT, y se
  descartó explícitamente esa línea de análisis.
- Al comparar `Revenue` en **nivel** (no transformado) entre grupos, la
  diferencia de medias sí es estadísticamente significativa
  (`lm(Revenue ~ easier_signup)`: coeficiente 0.49, p = 1.8e-11; medias 3.98
  vs. 4.47), en aparente contraste con el ITT sobre `log_revenue` (no
  significativo). Se verificó que las medianas son casi idénticas (3.15 vs.
  3.14) y que la brecha entre grupos aparece en los percentiles altos
  (p99: 14.4 vs. 24.9; máximo: 23.8 vs. 52.2), lo que indica que la
  diferencia en la media está concentrada en la cola superior de `Revenue`
  en el grupo de tratamiento, no en un desplazamiento típico de la
  distribución. La gráfica de distribución se construyó explícitamente para
  mostrar este patrón.

## Problemas / pendientes

- Queda sin resolver una inconsistencia relevante para la presentación
  final: el ITT es significativo en nivel pero no en logaritmo. Falta
  decidir con el equipo cuál transformación de `Revenue` es la que se
  reporta como estimando central, y cómo comunicar esa discrepancia sin
  sobre-interpretar ninguno de los dos resultados.
- Sigue pendiente confirmar unidad/moneda de `Revenue` (ya señalado en
  `CLAUDE.md`); las gráficas de esta sesión se dejaron sin símbolo de
  moneda por esa razón.
- Al cerrar esta sesión, `git status` mostraba además un archivo eliminado
  (`02_Scripts/01_procesar_datos_experimento.R`) y dos archivos nuevos
  (`00_main.R`, `02_Scripts/04_procesar_datos_experimento.R`) que no se
  originaron en esta conversación. No se documentan en detalle aquí porque
  no hay contexto sobre su contenido o propósito; conviene que quien los
  creó los registre en la próxima bitácora.
