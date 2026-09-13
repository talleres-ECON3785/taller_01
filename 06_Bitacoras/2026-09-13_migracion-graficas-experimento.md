# Bitácora — 2026-09-13: Migración y ampliación de gráficas del experimento

## Qué se hizo

- Autor: Santiago Muñoz Martínez.
- Se migró toda la generación de gráficas del experimento desde
  `02_Scripts/06_analisis_experimento.R` hacia un script nuevo,
  `02_Scripts/07_graficas_experimento.R`, dejando `06_analisis_experimento.R`
  enfocado solo en tablas de contingencia, modelos y chequeos de
  especificación.
- Se rediseñaron las dos gráficas migradas (ingreso promedio y distribución
  de ingresos por grupo control/tratamiento) y se agregaron cuatro gráficas
  nuevas, todas con un estilo común (`tema_presentacion`, leyenda o paneles
  por categoría, línea punteada de mediana donde aplica, subtítulo que
  aclara "Datos del experimento A/B"):
  - `experimento_ingresos_promedio_control_tratamiento.png`: barras de
    ingreso promedio por grupo con IC 95%.
  - `experimento_distribucion_ingresos_control_tratamiento.png`: densidad de
    `Revenue` (escala log) por grupo, en paneles separados en vez del
    scatter/jitter original.
  - `experimento_distribucion_ingresos_device_type.png`: densidad de
    `Revenue` por `device_type` (Escritorio, Tablet, Móvil).
  - `experimento_distribucion_ingresos_os_type.png`: densidad de `Revenue`
    por `os_type` (OSX, Windows, Otro).
  - `experimento_distribucion_ingresos_signup.png`: densidad de `Revenue`
    por `sign_up` (Registrado / No registrado).
  - `experimento_relacion_tiempo_revenue.png`: binned scatter (50 grupos por
    percentil de `time_spent`) de `time_spent` vs. `Revenue`, con línea
    vertical punteada en 5 minutos.
- Se definió una paleta categórica sobria de 3 colores (azul, ocre,
  verde-azulado), validada con el script `validate_palette.js` de la skill
  `dataviz` del entorno (banda de luminosidad, piso de croma, separación
  CVD, contraste), en reemplazo de una paleta inicial más saturada. Se
  reutiliza la misma terna en las cinco gráficas categóricas del script para
  mantener una identidad visual única.
- Se exploraron y descartaron dentro de la misma sesión: etiquetas de texto
  directas sobre las curvas de densidad (se prefirió leyenda arriba +
  paneles separados), y una versión de scatter sin agrupar para la relación
  tiempo–ingreso (se dejó solo el binned scatter, considerado suficiente).
- Se renombraron los seis archivos generados por `07_graficas_experimento.R`
  con el prefijo `experimento_`, para distinguirlos de las figuras que
  produce `02_descriptivas_observacional.R` sobre la base observacional. Se
  eliminaron del disco los seis archivos con el nombre anterior.

## Por qué

- La separación de responsabilidades entre limpieza/modelos (`06_...R`) y
  graficación (`07_...R`) responde a que el número de gráficas para la
  presentación creció más de lo previsto originalmente en el script único.
- Las gráficas de `device_type`, `os_type` y `sign_up` se agregaron para
  explorar si la distribución de `Revenue` varía de forma descriptiva según
  esas dimensiones, como insumo para decidir qué se incluye en la
  presentación (no implican causalidad).
- El binned scatter de tiempo vs. ingreso responde a la pregunta de cómo
  visualizar la relación entre dos variables continuas con n = 10,000 y
  ambas con cola larga a la derecha, donde un scatter crudo se satura de
  puntos.
- El renombrado de archivos busca que cualquiera que revise
  `03_Resultados/Figuras/` identifique de inmediato qué gráficas vienen del
  experimento vs. de la base observacional, sin tener que abrir cada script.

## Qué se descubrió

- La gráfica de `sign_up` (registrado/no registrado) resultó ser, en n y en
  medianas, idéntica a la de `easier_signup` (control/tratamiento) — ya
  documentado en sesión previa (correspondencia perfecta entre ambas
  variables). Se mantiene igualmente en el script porque el equipo puede
  necesitarla con ese rótulo específico para la presentación.
- El binned scatter de `time_spent` vs. `Revenue` mostró un patrón no lineal
  que no se había explorado antes: el ingreso promedio por grupo se mantiene
  casi plano (~2.9–3.0) para `time_spent` entre ~0.1 y 5 minutos, y salta a
  una meseta más alta (~6.3–6.5) a partir de 5 minutos, con una transición
  muy abrupta. Se verificó que el patrón no es un artefacto del agrupamiento
  (se revisó también con un scatter de las 10,000 sesiones individuales,
  posteriormente descartado del script pero confirmando el mismo salto). Una
  regresión lineal log-log simple sobre esta relación no captura bien esa
  discontinuidad.

## Problemas / pendientes

- Queda pendiente que el equipo decida qué hacer, metodológicamente, con el
  hallazgo de la discontinuidad en `time_spent = 5`: el taller solo permite
  regresión lineal como estimador, por lo que no se ajustó ningún modelo que
  capture el quiebre; la gráfica se dejó como evidencia puramente
  descriptiva.
- Sigue sin confirmarse en `CLAUDE.md` la unidad de `time_spent`; esta
  sesión asumió minutos para la gráfica de tiempo vs. ingreso (asunción ya
  confirmada por el usuario durante la sesión, pero no está registrada
  todavía como decisión formal en la tabla de `CLAUDE.md`).
- No se decidió todavía cuáles de las seis gráficas nuevas entran a la
  presentación final; varias (device_type, os_type, signup) se construyeron
  como material exploratorio.
