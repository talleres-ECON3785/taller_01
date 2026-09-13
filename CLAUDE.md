# CLAUDE.md: reglas del proyecto

## Contexto del proyecto

Taller 1 de Ciencia de Datos y Econometría Aplicada (ECON-3785, 2026-2, Universidad
de los Andes). Cliente ficticio: CheMarket Inc., empresa de comercio electrónico.

- **Pregunta de negocio:** ¿debería CheMarket invertir en impulsar el registro
  (`sign_up`) de sus usuarios para aumentar sus ingresos (`Revenue`)?
- **Dos fuentes de datos**, con roles distintos y no intercambiables:
  - `observacional.Rds`: datos históricos del comportamiento de los usuarios. Permite
    describir/predecir, pero no identifica el efecto causal de aumentar el registro.
  - `experimento.Rds`: prueba A/B con asignación aleatoria a `easier_signup`
    (registro facilitado). Permite estimar el efecto causal de esa intervención.
- El taller consiste en distinguir con cuidado qué puede afirmarse con cada base y
  qué no, y en no confundir correlación (datos históricos) con efecto causal
  (experimento).
- **Entregable final:** una presentación al cliente en `08_Entregables/`, sin
  código, estilo *answer-first* (ver sección "Entregable: presentación al cliente").

## Estructura del proyecto

- `01_Datos/01_Crudos/`      datos originales. NUNCA se modifican
- `01_Datos/02_Procesados/`  datos limpios o transformados
- `01_Datos/03_Listos/`      bases finales que ingresan al análisis
- `02_Scripts/`              scripts de R
- `03_Resultados/`           Tablas/ y Figuras/ generadas
- `04_Presentaciones/`       borradores de la presentación
- `05_Notas/`                notas e ideas preliminares
- `06_Bitacoras/`            documentación de cada sesión de trabajo
- `07_Recursos/`             referencias externas y documentación
- `08_Entregables/`          presentación final y video

## Reglas de trabajo

- Lenguaje principal: R. Utilice `tidyverse` cuando resulte apropiado.
- Explique lo que va a hacer ANTES de editar o crear archivos.
- Utilice rutas relativas ancladas a la carpeta del proyecto.
- Redacte los comentarios del código en español.
- Fije la semilla `set.seed(2026)` en cualquier análisis con componente aleatorio
  (p. ej. partición muestral).
- Evalúe el desempeño predictivo siempre fuera de muestra (train/test), nunca
  dentro de muestra.
- Al cerrar una sesión, escriba una bitácora en `06_Bitacoras/` con lo que se
  hizo, por qué, qué se descubrió y qué problemas se presentaron.

## Regla metodológica: solo regresión lineal

- El único modelo permitido en este taller es la regresión lineal (incluyendo el
  modelo de probabilidad lineal para `sign_up` u otras variables binarias), tanto
  para predecir como para estimar el efecto del experimento.
- No proponga ni ajuste otros modelos (matching, árboles, bosques aleatorios,
  boosting, redes neuronales, etc.), **aunque parezcan más apropiados**. Esta
  restricción es intencional: el objetivo del taller es entender a fondo qué
  puede y no puede estimarse con una regresión.
- Distinga siempre tres cosas al reportar un resultado: el **estimando** (lo que
  se quiere conocer), el **estimador** (la regresión lineal) y la **estimación**
  (el número obtenido).

## Datos

- El flujo es Crudos, Procesados, Listos. Nunca en sentido inverso.
- Reporte siempre cuántas observaciones se pierden al limpiar o filtrar.

## Primero el diseño, después los resultados

- No emita juicios sobre si un resultado es "bueno" o "malo".
- No exprese entusiasmo por un coeficiente ni por su significancia.
- Mientras el diseño no esté resuelto, lo único relevante es si la especificación es correcta.

## Integrantes

| Nombre                    | Rol / responsabilidad                    | Contacto                                                         |
| ------------------------- | ---------------------------------------- | ---------------------------------------------------------------- |
| Samuel Escandón          | Análisis de Datos históricos           | [s.escandoc@uniandes.edu.co](mailto:s.escandoc@uniandes.edu.co)   |
| Douglas Plazas Guzman     | Análisis de Datos históricos           | [d.plazasg@uniandes.edu.co](mailto:d.plazasg@uniandes.edu.co)     |
| Mateo Olmos Becerra       | Análisis de Datos Experimento A/B       | [m.olmosb@uniandes.edu.co](mailto:m.olmosb@uniandes.edu.co)       |
| Santiago Martinez Lopez   | Diseño de Presentación y Análisis A/B | [s.martinezl@uniandes.edu.co](mailto:s.martinezl@uniandes.edu.co) |
| Santiago Muñoz Martínez | Análisis de Datos Experimento A/B       | [s.munozm234@uniandes.edu.co](mailto:s.munozm234@uniandes.edu.co) |

<!-- Miembros del grupo y responsabilidades. Permite identificar al interlocutor
     y a quién corresponde cada decisión. -->

## Decisiones tomadas

<!-- Registro acumulado de decisiones metodológicas y su justificación, para no
     perder de vista por qué se hizo algo varias semanas después. -->

| Fecha      | Decisión                                                                                                                                                                              | Justificación                                                                                                                                   |
| ---------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------ |
| 2026-09-12 | El estimando central del experimento es el ITT de`easier_signup` sobre `Revenue`; el efecto sobre `sign_up` (primer estadio) se reporta como mecanismo, no como respuesta final. | `easier_signup` es la variable que CheMarket puede manipular directamente; `sign_up` es un resultado intermedio, no la palanca de política. |

## Análisis descartados

<!-- Especificaciones, variables o enfoques que se probaron y abandonaron, con
     la razón, para no repetir procedimientos ya infructuosos. -->

| Fecha      | Análisis/especificación descartada                                                                                  | Razón                                                                                                                                                                                                                     |
| ---------- | -------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 2026-09-13 | Hipótesis de sesgo de variable omitida en `itt_sencillo` por `time_spent` (se estimó `log_time_spent ~ easier_signup`) | El coeficiente es positivo y no estadísticamente significativo: no hay evidencia de que `easier_signup` afecte `time_spent`, así que no sostiene la hipótesis de que `time_spent` fuera un mediador/mal control del ITT. |
| 2026-09-13 | Profundizar en IV/LATE usando `easier_signup` como instrumento de `sign_up`                                          | El primer estadio (`sign_up ~ easier_signup`) tiene coeficiente exactamente 1, por la correspondencia perfecta entre `sign_up` y `easier_signup` (ver tabla de contingencia, sección 1 de `06_analisis_experimento.R`). Por lo tanto LATE = ITT / 1 = ITT: no aporta información adicional a la ya obtenida con el ITT. |

## Definición de variables

<!-- Definición operativa de cada variable usada en el análisis: qué incluye,
     unidades, moneda, período y fuente. -->

Definiciones tal como las da el enunciado del taller. Pendiente confirmar al
explorar los datos: unidades y moneda de `Revenue` (¿incluye impuestos?),
período/duración de "la sesión", y si `time_spent` está en segundos o minutos.

| Variable              | Definición                                                                                                                                                                                                                                                                                       | Fuente                                                   |
| --------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------- |
| `Revenue`           | Gasto del usuario en la sesión.                                                                                                                                                                                                                                                                 | `observacional.Rds`, `experimento.Rds`               |
| `sign_up`           | Si el usuario se registró (binaria).                                                                                                                                                                                                                                                             | `observacional.Rds`, `experimento.Rds`               |
| `time_spent`        | Tiempo en el sitio en la sesión.                                                                                                                                                                                                                                                                 | `observacional.Rds`, `experimento.Rds`               |
| `past_sessions`     | Número de sesiones anteriores.                                                                                                                                                                                                                                                                   | `observacional.Rds`, `experimento.Rds`               |
| `device_type`       | Dispositivo usado:`mobile`, `desktop` o `tablet`.                                                                                                                                                                                                                                           | `observacional.Rds`, `experimento.Rds`               |
| `is_returning_user` | Si el usuario ya había visitado antes (binaria).                                                                                                                                                                                                                                                 | `observacional.Rds`, `experimento.Rds`               |
| `easier_signup`     | Asignación al tratamiento del experimento (registro facilitado, binaria).                                                                                                                                                                                                                        | `experimento.Rds` (no existe en `observacional.Rds`) |
| `os_type`           | Sistema operativo:`osx`, `windows` u `other`. No estaba en el enunciado original; se encontró al explorar `datos_historicos.Rds` (2026-09-12). No se limpió ni describió en la sesión de limpieza/descriptivas de `observacional.Rds`; pendiente decidir si se usa en el análisis. | `observacional.Rds`, `experimento.Rds`               |

**Nota (2026-09-12):** los archivos crudos reales se llaman `datos_historicos.Rds`
(observacional) y `datos_experimento.Rds`, no `observacional.Rds`/`experimento.Rds`
como dice el enunciado citado arriba. 

## Restricciones de muestra

<!-- Criterios de exclusión aplicados y el N resultante en cada paso, para que
     el N reportado sea verificable. -->

| Criterio de exclusión                            | N antes | N después |
| ------------------------------------------------- | ------- | ---------- |
| Observaciones con algún NA (`experimento.Rds`) | 10000   | 10000      |

## Entregable: presentación al cliente

<!-- Lineamientos del enunciado para la presentación final, estilo "McKinsey way". -->

- Estilo *answer-first*: la recomendación va al inicio, no al final.
- Principio de la pirámide: mensaje principal arriba, 2-4 argumentos de apoyo
  debajo, evidencia sosteniendo cada argumento.
- Una idea por slide: el título debe comunicar la conclusión, no el tema (evitar
  títulos como "Resultados del experimento").
- MECE: cubrir lo importante sin repetirse.
- Enfocarse en el "so what?": un dato solo si sostiene una conclusión o decisión.
- Cerrar con decisiones y próximos pasos que necesita el cliente.
- Ser explícitos sobre qué respalda la evidencia histórica y qué agrega el
  experimento.
- **No incluir código en la presentación.**

## Estado actual

<!-- Punto de avance del proyecto al cierre de la última sesión: qué está
     hecho, qué sigue, dónde se quedó el trabajo. -->

- Estructura de carpetas y `CLAUDE.md` creados. Aún no se han descargado
  `observacional.Rds` ni `experimento.Rds` (disponibles en Bloque Neón) hacia
  `01_Datos/01_Crudos/`.
- No se ha escrito ningún script todavía.
- **2026-09-12 (rama `limpieza-descriptivas-observacional`):** los archivos
  crudos ya están descargados en `01_Datos/01_Crudos/`, pero con nombres
  distintos a los del enunciado: `datos_historicos.Rds` (base observacional,
  100,000 obs.) y `datos_experimento.Rds` (base del experimento). Se
  crearon `02_Scripts/01_limpieza_observacional.R` (limpieza y reporte de
  calidad de `datos_historicos.Rds`, guarda
  `01_Datos/02_Procesados/observacional_limpio.Rds`) y
  `02_Scripts/02_descriptivas_observacional.R` (estadísticas univariadas,
  por `sign_up`, correlaciones y figuras, todo en `03_Resultados/`). No se
  ajustó ningún modelo. Quedan pendientes de decisión del equipo los
  valores atípicos de `Revenue`, `time_spent` y `past_sessions` (ver
  `03_Resultados/Tablas/reporte_calidad_observacional.csv` y la bitácora
  `06_Bitacoras/2026-09-12_limpieza-descriptivas-observacional.md`).

## Reglas estrictas

<!-- Acciones que requieren autorización previa del equipo antes de ejecutarse. -->

- No modificar ni sobrescribir archivos en `01_Datos/01_Crudos/`.
- No eliminar ni mover archivos fuera de la estructura del proyecto sin autorización.
- No usar modelos distintos a la regresión lineal, aunque el agente los sugiera
  (ver "Regla metodológica: solo regresión lineal").
- No incluir código en la presentación final.
