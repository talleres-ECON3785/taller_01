# Bitácora — 2026-09-13: Base observacional a `03_Listos/` y actualización de `00_main.R`

## Qué se hizo

- Se movió `observacional_limpio.Rds` de `01_Datos/02_Procesados/` a
  `01_Datos/03_Listos/` (con `git mv`, para conservar el historial). La carpeta
  `02_Procesados/` queda vacía (solo `.gitkeep`), disponible para
  transformaciones intermedias futuras.
- Se modificó `01_limpieza_observacional.R` para que guarde la base limpia
  directamente en `03_Listos/` en vez de en `02_Procesados/`.
- Se actualizaron los cuatro scripts que leían la base observacional para que
  apunten a la ruta nueva: `02_descriptivas_observacional.R`,
  `08_discontinuidad_tiempo_revenue_observacional.R`,
  `10_regresion_correlacional_observacional.R` y
  `11_prediccion_revenue_observacional.R`.
- Se actualizó `00_main.R`, que solo listaba los scripts 01–07, para incluir
  los scripts 08 a 12 (el pipeline completo hasta ahora). Al revisar
  `12_representatividad_experimento_vs_historico.R` (creado en una sesión
  anterior, no en esta) para agregarlo a la lista, se encontró que también
  leía la base observacional de la ruta vieja (`02_Procesados/`); se corrigió
  a `03_Listos/` en el mismo cambio.
- Se corrió `00_main.R` completo dos veces (antes y después de agregar el
  script 12) para confirmar que los 12 scripts se ejecutan sin errores de
  principio a fin con las rutas nuevas.
- Se actualizó la sección "Estado actual" de `CLAUDE.md` para reflejar la
  ubicación nueva de la base observacional y remover el pendiente que ya
  quedaba resuelto.

## Por qué

- El proyecto define `03_Listos/` como la carpeta de "bases finales que
  ingresan al análisis". La base observacional limpia se usa directamente en
  el análisis (descriptivas, regresión correlacional, predicción,
  discontinuidad, representatividad) sin ningún paso adicional de
  transformación, así que corresponde a `03_Listos/`, no a `02_Procesados/`.
  Antes de este cambio, cuatro scripts distintos leían directamente de
  `02_Procesados/`, lo que dejaba el flujo Crudos → Procesados → Listos
  incompleto para esta base (ver pendiente ya registrado en `CLAUDE.md`).
- `00_main.R` debe permitir reproducir *todo* el pipeline en una sola corrida;
  que solo cubriera 7 de 12 scripts significaba que los scripts 08–12 nunca se
  habían probado en secuencia limpia desde `00_main.R`.

## Qué se descubrió

- `12_representatividad_experimento_vs_historico.R` tenía una ruta de lectura
  rota en potencia: apuntaba a `01_Datos/02_Procesados/observacional_limpio.Rds`,
  que dejó de existir al mover el archivo. No fallaba antes porque nadie lo
  había corrido desde el movimiento; se detectó al revisar el script para
  agregarlo a `00_main.R`, no por una corrida fallida.
- No se perdieron observaciones por el movimiento: la corrida de
  `01_limpieza_observacional.R` después del cambio reprodujo la misma base
  (100,000 obs., sin pérdidas por NA ni duplicados).

## Problemas / pendientes

- Al correr el pipeline completo se regeneraron varias tablas en
  `03_Resultados/Tablas/` (`balance_experimento.xlsx`,
  `descriptivas_experimento.xlsx`, `desempeno_predictivo_observacional.csv`,
  `representatividad_experimento_vs_historico.xlsx`,
  `tabla_elasticidad_timespent_observacional.csv`,
  `tabla_itt_experimento.docx`). Son resultados recalculados por la corrida,
  no ediciones manuales; quedan tal cual las dejó el pipeline porque no se
  pidió revisarlas antes de aceptarlas.
- Ningún script verifica que sus archivos de entrada existan antes de leerlos
  (pendiente ya señalado en `CLAUDE.md`); el error de ruta en el script 12
  habría aparecido como un `readRDS` fallido sin contexto si se hubiera corrido
  antes de esta sesión.
- Al cerrar esta sesión, `git status` mostraba un archivo nuevo sin
  seguimiento, `04_Presentaciones/CheMarket_deck.pdf`, que no se originó en
  esta conversación. No se documenta en detalle aquí porque no hay contexto
  sobre su contenido o propósito; conviene que quien lo generó lo registre en
  la próxima bitácora.
