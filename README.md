# Taller 1 — CheMarket Inc.: ¿invertir en `easier_signup`?

Taller 1 de Ciencia de Datos y Econometría Aplicada (ECON-3785, 2026-2,
Universidad de los Andes).

**Pregunta de negocio:** ¿debería CheMarket Inc. (empresa ficticia de comercio
electrónico) invertir en impulsar el registro (`sign_up`) de sus usuarios para
aumentar sus ingresos (`Revenue`)?

El taller usa dos bases de datos con roles distintos y no intercambiables:

- **`datos_historicos.Rds`** (observacional, 100,000 obs.): comportamiento
  histórico de los usuarios. Permite describir y predecir, pero **no**
  identifica el efecto causal de aumentar el registro.
- **`datos_experimento.Rds`** (10,000 obs.): prueba A/B con asignación
  aleatoria a `easier_signup` (registro facilitado). Permite estimar el
  **efecto causal** de esa intervención.

El eje del análisis es no confundir correlación (base observacional) con
efecto causal (experimento). El único modelo usado en todo el taller es la
**regresión lineal** (incluyendo el modelo de probabilidad lineal para
variables binarias); es una restricción metodológica intencional del taller,
no una limitación técnica.

## Integrantes

| Nombre                    | Rol / responsabilidad                    | Contacto                                                         |
| ------------------------- | ---------------------------------------- | ---------------------------------------------------------------- |
| Samuel Escandón          | Análisis de datos históricos           | [s.escandoc@uniandes.edu.co](mailto:s.escandoc@uniandes.edu.co)   |
| Douglas Plazas Guzmán    | Análisis de datos históricos           | [d.plazasg@uniandes.edu.co](mailto:d.plazasg@uniandes.edu.co)     |
| Mateo Olmos Becerra       | Análisis de datos del experimento A/B   | [m.olmosb@uniandes.edu.co](mailto:m.olmosb@uniandes.edu.co)       |
| Santiago Martínez López | Diseño de presentación y análisis A/B | [s.martinezl@uniandes.edu.co](mailto:s.martinezl@uniandes.edu.co) |
| Santiago Muñoz Martínez | Análisis de datos del experimento A/B   | [s.munozm234@uniandes.edu.co](mailto:s.munozm234@uniandes.edu.co) |

## Estructura del proyecto

```md
01_Datos/
  01_Crudos/       Datos originales (Rds). Nunca se modifican.
  02_Procesados/   Transformaciones intermedias (vacía por ahora).
  03_Listos/       Bases finales que entran al análisis.
02_Scripts/        Scripts de R, numerados en el orden en que se ejecutan.
03_Resultados/
  Tablas/          Tablas generadas (csv, xlsx, docx).
  Figuras/         Figuras generadas (png).
04_Presentaciones/ Copia de trabajo de la presentación al cliente (idéntica
                   a la entregada en 08_Entregables/).
05_Notas/          Notas e ideas preliminares del equipo.
06_Bitacoras/       Una bitácora por sesión de trabajo: qué se hizo, por qué,
                    qué se descubrió y qué problemas se presentaron.
07_Recursos/        Referencias externas (p. ej. el enunciado del taller).
08_Entregables/     Entregable final: CheMarket_deck.pdf y link_video.md
                    (enlace al video de la presentación).
00_main.R           Corre todo el pipeline en una sola ejecución.
CLAUDE.md           Bitácora viva de decisiones, convenciones y estado del proyecto.
```

## Requisitos

- R (cualquier versión reciente) y RStudio (el proyecto usa `taller1.Rproj`).
- Paquetes de R: `tidyverse`, `writexl`, `modelsummary`, `skimr`.

```r
install.packages(c("tidyverse", "writexl", "modelsummary", "skimr"))
```

## Cómo reproducir todos los resultados

1. Clonar el repositorio y abrir `taller1.Rproj` en RStudio (o, desde una
   sesión de R cualquiera, fijar el directorio de trabajo en la raíz del
   proyecto, donde vive `taller1.Rproj`).
2. Correr `00_main.R`. Este script verifica que el directorio de trabajo sea
   la raíz del proyecto y luego ejecuta, en orden, los 12 scripts de
   `02_Scripts/` (cada uno en su propio entorno), regenerando **todas** las
   tablas de `03_Resultados/Tablas/` y todas las figuras de
   `03_Resultados/Figuras/` a partir de los datos crudos en
   `01_Datos/01_Crudos/`.

No es necesario correr los scripts uno por uno a mano: `00_main.R` es el
único punto de entrada para reproducir el proyecto completo.

## Scripts, qué hacen y qué producen

| #  | Script                                               | Qué hace                                                                                                                                                                                     | Tablas que produce                                                                                                                                                                                                                                                                                           | Figuras que produce                                                                                                                                                                                                                                                                                                               |
| -- | ---------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| — | `00_formato_graficas.R`                            | Define paleta, tema y`guardar_figura()`. No genera resultados por sí mismo; lo cargan con `source()` los scripts que sí grafican.                                                       | —                                                                                                                                                                                                                                                                                                           | —                                                                                                                                                                                                                                                                                                                                |
| 01 | `01_limpieza_observacional.R`                      | Limpia`datos_historicos.Rds` y guarda la base lista en `01_Datos/03_Listos/observacional_limpio.Rds`. Reporta la calidad de los datos y cuántas observaciones se pierden en cada filtro. | `reporte_calidad_observacional.csv`, `reporte_calidad_observacional_embudo.csv`                                                                                                                                                                                                                          | —                                                                                                                                                                                                                                                                                                                                |
| 02 | `02_descriptivas_observacional.R`                  | Univariadas, descriptivas por`sign_up`, correlaciones y distribuciones de la base observacional.                                                                                            | `univariadas_numericas.csv`, `univariadas_sign_up.csv`, `univariadas_is_returning_user.csv`, `univariadas_device_type.csv`, `descriptivas_por_sign_up_numericas.csv`, `descriptivas_por_sign_up_device_type.csv`, `descriptivas_por_sign_up_is_returning_user.csv`, `matriz_correlacion.csv` | `observacional_distribucion_ingresos_signup.png`, `observacional_distribucion_tiempo_signup.png`, `observacional_ingresos_signup.png`, `observacional_tiempo_signup.png`                                                                                                                                                  |
| 03 | `03_procesar_datos_experimento.R`                  | Procesa`datos_experimento.Rds` y guarda la base lista en `01_Datos/03_Listos/experimento_listos.RDS`.                                                                                     | —                                                                                                                                                                                                                                                                                                           | —                                                                                                                                                                                                                                                                                                                                |
| 04 | `04_descriptivas_experimento.R`                    | Descriptivas de la base del experimento.                                                                                                                                                      | `descriptivas_experimento.xlsx`                                                                                                                                                                                                                                                                            | —                                                                                                                                                                                                                                                                                                                                |
| 05 | `05_balance_experimento.R`                         | Balance de covariables entre control y tratamiento (chequeo de la aleatorización).                                                                                                           | `balance_experimento.xlsx`                                                                                                                                                                                                                                                                                 | —                                                                                                                                                                                                                                                                                                                                |
| 06 | `06_analisis_experimento.R`                        | Contingencia`sign_up` × `easier_signup`, ITT de `easier_signup` sobre `Revenue` (en logaritmo y en nivel) y chequeos de especificación.                                                                       | `tabla_contingencia_signup_easier_signup.csv`, `tabla_itt_experimento.docx`, `tabla_itt_nivel_experimento.csv`, `descriptivas_revenue_por_grupo_experimento.csv`                                                                                                                                                                                                                              | —                                                                                                                                                                                                                                                                                                                                |
| 07 | `07_graficas_experimento.R`                        | Figuras del experimento para la presentación (ingresos por grupo, distribuciones, relación tiempo–ingreso).                                                                                | —                                                                                                                                                                                                                                                                                                           | `experimento_ingresos_promedio_control_tratamiento.png`, `experimento_distribucion_ingresos_control_tratamiento.png`, `experimento_distribucion_ingresos_device_type.png`, `experimento_distribucion_ingresos_os_type.png`, `experimento_distribucion_ingresos_signup.png`, `experimento_relacion_tiempo_revenue.png` |
| 08 | `08_discontinuidad_tiempo_revenue_observacional.R` | Búsqueda formal (por rejilla) del quiebre en la relación`time_spent`–`Revenue`, validado fuera de muestra, en la base observacional.                                                   | `observacional_busqueda_b_rss.csv`, `observacional_quiebre_train_test.csv`, `observacional_comparacion_r2_quiebre.csv`, `observacional_resumen_quiebre.csv`                                                                                                                                          | `observacional_rss_vs_b_quiebre.png`, `observacional_relacion_tiempo_revenue.png`                                                                                                                                                                                                                                             |
| 09 | `09_discontinuidad_tiempo_revenue_experimento.R`   | Lo mismo que el script 08 pero en la base del experimento, más la comparación del quiebre entre las dos bases.                                                                              | `experimento_busqueda_b_rss.csv`, `experimento_quiebre_train_test.csv`, `experimento_comparacion_r2_quiebre.csv`, `experimento_resumen_quiebre.csv`, `comparacion_quiebre_observacional_experimento.csv`                                                                                           | `experimento_rss_vs_b_quiebre.png`, `experimento_relacion_tiempo_revenue_quiebre.png`                                                                                                                                                                                                                                         |
| 10 | `10_regresion_correlacional_observacional.R`       | Asociación (correlacional, no causal) entre`sign_up` y `Revenue`, reportada en logaritmo y en nivel, en la base observacional.                                                                                          | `tabla_correlacional_signup_observacional.docx`, `tabla_asociacion_signup_nivel_observacional.csv`, `tabla_elasticidad_timespent_observacional.csv`                                                                                                                                                                                                                                                            | —                                                                                                                                                                                                                                                                                                                                |
| 11 | `11_prediccion_revenue_observacional.R`            | Modelo predictivo de`Revenue` con regresión lineal, evaluado siempre fuera de muestra (train/test, semilla 2026).                                                                          | `desempeno_predictivo_observacional.csv`                                                                                                                                                                                                                                                                   | —                                                                                                                                                                                                                                                                                                                                |
| 12 | `12_representatividad_experimento_vs_historico.R`  | Compara la muestra del experimento contra la población histórica para evaluar si el ITT generaliza.                                                                                         | `representatividad_experimento_vs_historico.xlsx`                                                                                                                                                                                                                                                          | —                                                                                                                                                                                                                                                                                                                                |

Todas las tablas quedan en `03_Resultados/Tablas/` y todas las figuras en
`03_Resultados/Figuras/`, con el prefijo `observacional_` o `experimento_`
según de qué base provienen.

## Bitácoras

Cada sesión de trabajo tiene su bitácora en `06_Bitacoras/`, con fecha y tema
(qué se hizo, por qué, qué se descubrió y qué problemas se presentaron). Es
el mejor punto de partida para entender la evolución de las decisiones del
proyecto; las decisiones vigentes están resumidas en `CLAUDE.md`.

## Entregable al cliente

La presentación para CheMarket sigue un estilo *answer-first* (recomendación
al inicio) y no incluye código. La versión final está en
[`08_Entregables/CheMarket_deck.pdf`](08_Entregables/CheMarket_deck.pdf), y el
video de la presentación en el enlace de
[`08_Entregables/link_video.md`](08_Entregables/link_video.md). 

## Reglas del proyecto

Las reglas de trabajo, convenciones de código, formato de gráficas y el
estado detallado del proyecto (pendientes, decisiones tomadas, análisis
descartados) están documentadas en [`CLAUDE.md`](CLAUDE.md).
