# Bitácora — 2026-09-12: Descriptivas de `experimento_listos.RDS`

## Qué se hizo

- Se construyó `02_Scripts/03_descriptivas_experimento.r`, que carga
  `01_Datos/03_Listos/experimento_listos.RDS` y calcula:
  - Descriptivas de las variables numéricas (`Revenue`, `time_spent`,
    `past_sessions`) con `skimr::skim()`: n, missing, media, sd, cuartiles e
    histograma por variable.
  - Frecuencias (conteo y proporción) de las variables categóricas
    `device_type` y `os_type`.
  - Frecuencias (conteo y proporción) de las variables binarias `sign_up`,
    `is_returning_user` y `easier_signup`.
- Se exportaron las seis tablas resultantes a un único libro de Excel,
  `03_Resultados/Tablas/descriptivas_experimento.xlsx` (una hoja por tabla),
  usando `writexl::write_xlsx()`.
- Se agregaron `skimr` y `writexl` como dependencias del script; no estaban
  usadas antes en el proyecto.

## Por qué

- Antes de estimar cualquier regresión (LPM sobre `sign_up`, o sobre
  `Revenue`) es necesario caracterizar la distribución y composición de las
  variables del experimento (dispersión de las numéricas, proporciones de
  las categóricas y binarias).
- Exportar a Excel deja tablas reutilizables por el equipo y como insumo
  directo para la presentación al cliente, que no debe incluir código.

## Qué se descubrió

- `Revenue`: media 4.22, sd 3.66, rango 0.665–52.2.
- `time_spent`: media 5.03, sd 5.01, rango 0.000259–42.2.
- `past_sessions`: media 3.02, sd 1.74, rango 0–11.
- `device_type`: desktop 40.3%, mobile 49.8%, tablet 10.0%.
- `os_type`: osx 30.1%, windows 59.9%, other 10.0%.
- `is_returning_user`: 94.8% recurrentes, 5.2% nuevos.
- `sign_up` y `easier_signup` tienen exactamente la misma distribución
  agregada (50.4% / 49.6%); no se verificó si coinciden también a nivel de
  observación individual.

## Problemas / pendientes

- `skimr` y `writexl` no estaban documentados como dependencias del
  proyecto; falta que el resto del equipo las instale.
- Este script no compara `Revenue` ni `sign_up` entre los grupos de
  `easier_signup`: eso corresponde a la etapa de estimación (regresión), no
  a la descriptiva, y queda pendiente para el script correspondiente.
- Falta confirmar si la coincidencia entre las distribuciones agregadas de
  `sign_up` y `easier_signup` refleja una relación a nivel de observación.
