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
  código, estilo *answer-first* (ver sección "Entregable: presentación al
  cliente"). Ya está publicada en `08_Entregables/CheMarket_deck.pdf`, con el
  video en `08_Entregables/link_video.md`.

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
  hizo, por qué, qué se descubrió y qué problemas se presentaron (ver skill
  `cerrar-sesion` abajo).

## Skill de Claude Code: `cerrar-sesion`

Definida en `.claude/skills/cerrar-sesion/SKILL.md`. Se invoca al terminar una
sesión de trabajo (pidiendo "cerrar sesión", "escribir la bitácora" o
"guardar la conversación") y hace dos cosas, en orden:

1. Escribe la bitácora de la sesión en `06_Bitacoras/`, replicando el formato
   de las bitácoras existentes (encabezados: Qué se hizo, Por qué, Qué se
   descubrió, Problemas/pendientes).
2. Copia el registro crudo (`.jsonl`) de la conversación a una carpeta fuera
   del repo (`Conversaciones_Claude/`, un nivel arriba de `taller1/`), nunca
   versionada con git.

Si algo no es inferible con certeza (p. ej. quién de los integrantes trabajó
en la sesión), la skill pregunta al usuario en vez de adivinar.

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

## Formato de las gráficas

Todas las figuras del proyecto siguen un mismo formato, para que se vean como
una sola familia al insertarlas en la presentación. El formato está definido en
un único lugar, `02_Scripts/00_formato_graficas.R`; ese script no genera
figuras, solo define paleta, tema y exportación.

- **Regla:** cualquier script que produzca figuras debe empezar con
  `source("02_Scripts/00_formato_graficas.R")` y usar lo que ahí se define.
  No redefina colores, temas ni tamaños dentro de un script de análisis: si
  algo del formato debe cambiar, cámbielo en `00_formato_graficas.R` para que
  el cambio aplique a todas las figuras a la vez.
- **Paleta:** `paleta_categorica`, terna sobria de azul (`#2B5FA3`), ocre
  (`#B8863B`) y verde-azulado (`#0E8A6C`), distinguibles entre sí incluso con
  daltonismo. Los grises (`gris_texto`, `gris_secundario`, `gris_nota`,
  `gris_grilla`) son estructura, no categorías: se usan para texto, líneas de
  referencia y grilla. Una misma categoría conserva su color entre bases (p.
  ej. "No registrado" es azul y "Registrado" es ocre tanto en la base
  observacional como en la del experimento), para poder leer dos figuras lado
  a lado.
- **Tema:** `tema_presentacion` (más `tema_paneles` si la gráfica usa facetas).
- **Título:** describe qué muestra la figura, en español y sin tecnicismos del
  código (no se nombran variables como `Revenue` o `sign_up`). La regla de
  "el título comunica la conclusión" aplica a los títulos de las diapositivas,
  no a los de las figuras.
- **Subtítulo:** declara siempre de qué base viene la figura, usando
  `subtitulo_experimento` o `subtitulo_observacional`. Esto es deliberado: las
  dos bases no permiten afirmar lo mismo, y quien vea la figura suelta debe
  poder saber si está viendo un efecto causal o una asociación descriptiva.
- **Nota al pie (`caption`):** reporta el `n` de cada grupo y, cuando hay una
  línea de referencia punteada, qué marca (normalmente la mediana del grupo).
- **Convenciones:** los ejes van en español y con unidades explícitas
  (p. ej. "Tiempo en el sitio en minutos", "Ingreso (escala log)"). Se prefieren
  paneles (`facet_wrap`) sobre leyendas; cuando las categorías ya están en el
  eje x o en los paneles, se omite la leyenda con `show.legend = FALSE`.
- **Distribuciones:** se grafican como densidad continua (`geom_density`, con
  `alpha = 0.55` y `linewidth = 0.8`), nunca como histograma, con un panel por
  categoría y la mediana de cada grupo marcada con una línea punteada gris.
  `Revenue` y `time_spent` tienen cola larga a la derecha, así que el eje x va
  en escala logarítmica (los valores siguen en sus unidades originales; solo
  cambia el espaciado del eje). Esto aplica a las dos bases, para que una
  distribución observacional y una del experimento se puedan comparar sin
  tener que reaprender cómo leer la figura.
- **Nombres de archivo:** `03_Resultados/Figuras/<base>_<contenido>.png`, donde
  `<base>` es `experimento` u `observacional` (p. ej.
  `observacional_distribucion_ingresos_signup.png`). El prefijo permite saber
  de un vistazo qué base sostiene cada figura.
- **Exportación:** siempre con `guardar_figura()`, que fija 8×6 pulgadas,
  300 dpi y fondo blanco explícito (ggplot lo deja transparente por defecto y
  eso se ve mal sobre una diapositiva).

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

| Fecha      | Decisión                                                                                                                                                                              | Justificación                                                                                                                                                                             |
| ---------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| 2026-09-12 | El estimando central del experimento es el ITT de`easier_signup` sobre `Revenue`; el efecto sobre `sign_up` (primer estadio) se reporta como mecanismo, no como respuesta final. | `easier_signup` es la variable que CheMarket puede manipular directamente; `sign_up` es un resultado intermedio, no la palanca de política.                                           |
| 2026-09-13 | `time_spent` está en minutos, en las dos bases.                                                                                                                                     | La base no trae metadatos de unidades; por los rangos observados minutos es lo plausible, y el usuario confirmó la lectura durante la sesión de migración de gráficas del experimento. |

## Análisis descartados

<!-- Especificaciones, variables o enfoques que se probaron y abandonaron, con
     la razón, para no repetir procedimientos ya infructuosos. -->

| Fecha      | Análisis/especificación descartada                                                                                          | Razón                                                                                                                                                                                                                                                                                                                            |
| ---------- | ----------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 2026-09-13 | Hipótesis de sesgo de variable omitida en`itt_sencillo` por `time_spent` (se estimó `log_time_spent ~ easier_signup`) | El coeficiente es positivo y no estadísticamente significativo: no hay evidencia de que`easier_signup` afecte `time_spent`, así que no sostiene la hipótesis de que `time_spent` fuera un mediador/mal control del ITT.                                                                                                  |
| 2026-09-13 | Profundizar en IV/LATE usando`easier_signup` como instrumento de `sign_up`                                                | El primer estadio (`sign_up ~ easier_signup`) tiene coeficiente exactamente 1, por la correspondencia perfecta entre `sign_up` y `easier_signup` (ver tabla de contingencia, sección 1 de `06_analisis_experimento.R`). Por lo tanto LATE = ITT / 1 = ITT: no aporta información adicional a la ya obtenida con el ITT. |

## Definición de variables

<!-- Definición operativa de cada variable usada en el análisis: qué incluye,
     unidades, moneda, período y fuente. -->

Definiciones tal como las da el enunciado del taller, con las unidades ya
confirmadas al explorar los datos.

| Variable              | Definición                                                                                                                                                                                                                                                                                                                                                                  | Fuente                                                   |
| --------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------- |
| `Revenue`           | Gasto del usuario en la sesión.                                                                                                                                                                                                                                                                                                                                             | `observacional.Rds`, `experimento.Rds`               |
| `sign_up`           | Si el usuario se registró (binaria).                                                                                                                                                                                                                                                                                                                                        | `observacional.Rds`, `experimento.Rds`               |
| `time_spent`        | Tiempo en el sitio en la sesión, en minutos.                                                                                                                                                                                                                                                                                                                                | `observacional.Rds`, `experimento.Rds`               |
| `past_sessions`     | Número de sesiones anteriores.                                                                                                                                                                                                                                                                                                                                              | `observacional.Rds`, `experimento.Rds`               |
| `device_type`       | Dispositivo usado:`mobile`, `desktop` o `tablet`.                                                                                                                                                                                                                                                                                                                      | `observacional.Rds`, `experimento.Rds`               |
| `is_returning_user` | Si el usuario ya había visitado antes (binaria).                                                                                                                                                                                                                                                                                                                            | `observacional.Rds`, `experimento.Rds`               |
| `easier_signup`     | Asignación al tratamiento del experimento (registro facilitado, binaria).                                                                                                                                                                                                                                                                                                   | `experimento.Rds` (no existe en `observacional.Rds`) |
| `os_type`           | Sistema operativo:`osx`, `windows` u `other`. No estaba en el enunciado original; se encontró al explorar `datos_historicos.Rds` (2026-09-12). No se limpió ni describió univariadamente en la sesión de descriptivas de `observacional.Rds`, pero sí se usa como control en las regresiones correlacional (10), predictiva (11) y de representatividad (12). | `observacional.Rds`, `experimento.Rds`               |

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

**Última actualización: 2026-09-13 (rama `main`).**

### Datos

- Los dos archivos crudos están en `01_Datos/01_Crudos/`, con nombres distintos
  a los del enunciado: `datos_historicos.Rds` (observacional, 100,000 obs.) y
  `datos_experimento.Rds` (experimento, 10,000 obs.).
- Base observacional lista: `01_Datos/03_Listos/observacional_limpio.Rds`
  (100,000 obs.; la limpieza no pierde observaciones, ver
  `03_Resultados/Tablas/reporte_calidad_observacional_embudo.csv`). El script
  `01_limpieza_observacional.R` la guarda directamente en `03_Listos/`; todos
  los scripts que la usan (02, 08, 10, 11, 12) leen de ahí. `02_Procesados/`
  queda vacía (solo `.gitkeep`) para transformaciones intermedias futuras.
- Base del experimento lista: `01_Datos/03_Listos/experimento_listos.RDS`
  (10,000 obs.; tampoco se pierden observaciones por NA).

### Pipeline

`00_main.R` (raíz del proyecto) corre el pipeline completo en una sola
ejecución, cada script en su propio entorno, verificando antes que el
directorio de trabajo sea la raíz. Scripts en `02_Scripts/`:

| Script                                               | Qué hace                                                                                                 |
| ---------------------------------------------------- | --------------------------------------------------------------------------------------------------------- |
| `00_formato_graficas.R`                            | Paleta, tema y`guardar_figura()`. No genera figuras; lo cargan con `source()` los scripts que sí.    |
| `01_limpieza_observacional.R`                      | Limpia`datos_historicos.Rds` y reporta calidad.                                                         |
| `02_descriptivas_observacional.R`                  | Univariadas, descriptivas por`sign_up`, correlaciones y 4 figuras.                                      |
| `03_procesar_datos_experimento.R`                  | Procesa`datos_experimento.Rds` → `experimento_listos.RDS`.                                           |
| `04_descriptivas_experimento.R`                    | Descriptivas de la base del experimento.                                                                  |
| `05_balance_experimento.R`                         | Balance de covariables entre control y tratamiento.                                                       |
| `06_analisis_experimento.R`                        | Contingencia`sign_up` x `easier_signup`, ITT (en log y en nivel) y chequeos de especificación.                           |
| `07_graficas_experimento.R`                        | Seis figuras del experimento para la presentación.                                                       |
| `08_discontinuidad_tiempo_revenue_observacional.R` | Búsqueda formal del quiebre`time_spent`–`Revenue` con validación fuera de muestra.                 |
| `09_discontinuidad_tiempo_revenue_experimento.R`   | Lo mismo en el experimento, más la comparación entre bases.                                             |
| `10_regresion_correlacional_observacional.R`       | Asociación (correlacional) entre`sign_up`, `time_spent` y `Revenue` (en log y en nivel) en la base observacional. |
| `11_prediccion_revenue_observacional.R`            | Modelo predictivo de`Revenue` con regresión lineal, evaluado fuera de muestra (train/test 80/20).      |
| `12_representatividad_experimento_vs_historico.R`  | Compara la muestra del experimento contra la población histórica para evaluar si el ITT generaliza.     |

- `00_main.R` corre los 12 scripts en orden en una sola ejecución.
- Ningún script verifica que sus archivos de entrada existan antes de leerlos.

### Resultados ya obtenidos

- **Correspondencia perfecta entre `sign_up` y `easier_signup`** en el
  experimento: los 5,043 del control no se registran y los 4,957 del
  tratamiento sí (`tabla_contingencia_signup_easier_signup.csv`). Por eso el
  primer estadio vale exactamente 1 y LATE = ITT (IV/LATE descartado).
- **ITT sobre `log_revenue`:** 0.0134 sin controles y 0.0042 con controles;
  ninguno estadísticamente distinguible de cero
  (`tabla_itt_experimento.docx`).
- **ITT sobre `Revenue` en nivel:** coeficiente 0.49 (p = 1.8e-11); medias 3.98
  vs. 4.47, pero medianas casi idénticas (3.15 vs. 3.14). La diferencia se
  concentra en la cola alta (p99: 14.4 vs. 24.9)
  (`tabla_itt_nivel_experimento.csv`,
  `descriptivas_revenue_por_grupo_experimento.csv`).
- **Quiebre en `time_spent` = 5 minutos** en la relación con `Revenue`,
  encontrado por rejilla en entrenamiento y confirmado fuera de muestra en
  **ambas bases** (salto de nivel ≈3.13 obs. / ≈3.42 exp., significativo en
  entrenamiento y prueba; cambio de pendiente no significativo). Es
  **correlacional, no causal**, en las dos bases: `time_spent` no está
  aleatorizado y es plausible causalidad inversa
  (`comparacion_quiebre_observacional_experimento.csv`).
- **Asociación `sign_up`–`log(Revenue)` en la base observacional**
  (correlacional, no causal): coeficiente 0.102 sin controles, 0.080 con
  controles observables, 0.047 al agregar `log(time_spent)`; significativo en
  los tres casos (`tabla_correlacional_signup_observacional.docx`). La misma
  asociación en nivel (dólares por sesión), que es como se reporta en la
  presentación: 0.548 sin controles y 0.210 al controlar además por
  `time_spent` (`tabla_asociacion_signup_nivel_observacional.csv`).
- **Elasticidad `Revenue`–`time_spent`** en la base observacional: ≈0.169% de
  cambio en `Revenue` por 1% de cambio en `time_spent`, estable entre el
  modelo simple y el modelo con controles, significativa en ambos
  (`tabla_elasticidad_timespent_observacional.csv`).
- **Modelo predictivo de `Revenue`** (regresión lineal, evaluado fuera de
  muestra, 80,000/20,000): RMSE 2.314 vs. 2.716 de la referencia ingenua
  (media de entrenamiento), mejora de 14.8% en RMSE
  (`desempeno_predictivo_observacional.csv`).
- **Representatividad de la muestra del experimento** frente a la población
  histórica: test conjunto F=0.65 (p=0.712) y diferencias de magnitud
  pequeñas en todas las características observables compartidas
  (`representatividad_experimento_vs_historico.xlsx`); es decir, no hay
  evidencia de que la muestra del experimento sea distinta de la población
  histórica en esas características.
- En `03_Resultados/` hay 14 figuras y 30 tablas, todas regenerables desde los
  scripts.
- La presentación final para CheMarket ya está en
  `08_Entregables/CheMarket_deck.pdf`, con el link al video en
  `08_Entregables/link_video.md`.

## Reglas estrictas

<!-- Acciones que requieren autorización previa del equipo antes de ejecutarse. -->

- No modificar ni sobrescribir archivos en `01_Datos/01_Crudos/`.
- No eliminar ni mover archivos fuera de la estructura del proyecto sin autorización.
- No usar modelos distintos a la regresión lineal, aunque el agente los sugiera
  (ver "Regla metodológica: solo regresión lineal").
- No incluir código en la presentación final.
