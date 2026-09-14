# Bitácora — 2026-09-13: Verificación de replicación y trazabilidad de las cifras del entregable

## Qué se hizo

- Se corrió `00_main.R` completo tres veces desde la raíz del proyecto (R
  4.5.2), tomando el hash SHA-1 de los 42 archivos de `03_Resultados/` y
  `01_Datos/03_Listos/` antes y después de cada corrida, para verificar que el
  pipeline replica exactamente y no solo "corre sin errores".
- Se auditó la documentación del proyecto (`CLAUDE.md`, `README.md`, las
  bitácoras y el texto del deck extraído de `08_Entregables/CheMarket_deck.pdf`)
  contra lo que realmente hay en disco: conteo de figuras y tablas, qué script
  produce cada archivo, y de dónde sale cada cifra citada en la presentación.
- Se corrigió el bloque de estructura del `README.md`: `08_Entregables/` decía
  "Presentación final y video (pendiente)" cuando ya están ambos, y
  `04_Presentaciones/` decía "Borradores de la presentación al cliente" cuando
  el PDF que contiene es byte-idéntico al entregado (mismo SHA `ccbb7c76`).
- Se renombró `itt_controles_nivel` a `itt_controles_log` en
  `06_analisis_experimento.R`, con un comentario que explica el cambio para que
  no se revierta por error.
- Se agregó la sección 2b a `06_analisis_experimento.R`, que estima el ITT sobre
  `Revenue` en nivel (sencillo y con controles) y las descriptivas de `Revenue`
  por grupo, y exporta ambos a `tabla_itt_nivel_experimento.csv` y
  `descriptivas_revenue_por_grupo_experimento.csv`.
- Se agregó a `10_regresion_correlacional_observacional.R` la exportación de la
  tabla correlacional en logaritmo
  (`tabla_correlacional_signup_observacional.docx`, antes solo se imprimía en
  pantalla) y una tabla nueva con la misma asociación en nivel, en cuatro
  especificaciones (`tabla_asociacion_signup_nivel_observacional.csv`).
- Se actualizaron `README.md` (filas 06 y 10 de la tabla de scripts) y
  `CLAUDE.md` (conteo de tablas 26 → 30, y los bullets del ITT en nivel y de la
  asociación correlacional, que ahora citan el archivo que los respalda en vez
  de citar el script o nada).
- A mitad de sesión el usuario hizo el commit `d1d078b` ("commit final") y
  eliminó la sección "Pendientes abiertos" de `CLAUDE.md`; se verificó que la
  eliminación quedó limpia, sin referencias sueltas a esa sección.

## Por qué

- El proyecto entra en cierre, y el criterio de replicación del taller no es
  solo que el pipeline termine sin error: es que otra persona pueda clonar el
  repositorio, correr `00_main.R` y obtener los mismos resultados que sostienen
  la presentación.
- Una cifra que aparece frente al cliente y que no queda en ningún archivo de
  `03_Resultados/` no es verificable ni por el equipo ni por quien califica. Las
  tablas nuevas no agregan análisis: dejan en disco números que ya se estaban
  reportando.
- El nombre `itt_controles_nivel` para un modelo cuya variable dependiente es
  `log_revenue` confunde el estimando: hace parecer que el ITT en nivel ya
  estaba estimado cuando no lo estaba.

## Qué se descubrió

- La replicación es exacta. De los 42 archivos, 38 (todos los `.csv` y los 14
  `.png`) salen byte-idénticos entre corridas. Los otros 4 son `.xlsx`/`.docx`:
  al descomprimirlos, el XML de contenido es idéntico y solo cambia el timestamp
  de creación que empotra el formato.
- Los dos `.csv` que `git` marcaba como modificados respecto a HEAD
  (`desempeno_predictivo_observacional.csv`,
  `tabla_elasticidad_timespent_observacional.csv`) difieren en el dígito ~13,
  es decir ruido de punto flotante de la librería de álgebra lineal, no un
  cambio de resultado.
- `modelsummary()` sin argumento `output=` no imprime nada cuando el pipeline
  corre con `Rscript`: `source()` evalúa con `print.eval = FALSE`. En la
  práctica, `06_analisis_experimento.R` no producía **ninguna** salida de
  consola en la corrida del pipeline (sí escribía sus dos archivos). Lo mismo
  ocurría con la tabla principal del script 10.
- Tres cifras que se citaban en `CLAUDE.md` y en el deck no las producía ningún
  script: el ITT en nivel (0.4909, p = 1.84e-11), las medianas y percentiles
  altos de `Revenue` por grupo (medianas 3.150 vs. 3.144; p99 14.40 vs. 24.88),
  y la tabla correlacional en logaritmo (0.102 / 0.080 / 0.047). Con los
  cambios de esta sesión las tres quedan en archivo, y los valores regenerados
  coinciden con los que ya estaban documentados.
- La cifra de la slide 4 del deck, "+0,20 (5,6%) diferencia con controles
  (sesiones previas, recurrencia, dispositivo, SO)", no se reproduce con los
  controles que la slide enumera: con exactamente esos controles el coeficiente
  es 0.401 (11.29% de la media de los no registrados). El 0.20 corresponde a la
  especificación que además incluye `time_spent` (0.210, 5.91%), que es
  justamente el control que el propio deck señala como discutible en la slide 5
  porque se mide en la misma sesión que el registro. La diferencia bruta sí
  reproduce: 0.5475 (15.40%).
- El deck y `CLAUDE.md` reportan el salto del quiebre en `time_spent` = 5 min
  con coeficientes distintos: el deck usa los de la muestra de prueba (3.19
  observacional / 3.50 experimento) y `CLAUDE.md` los de entrenamiento (3.13 /
  3.42). Ambos están en
  `comparacion_quiebre_observacional_experimento.csv`; no son cifras en
  conflicto, sino dos columnas distintas de la misma tabla.
- Ninguna base pierde observaciones: la observacional se mantiene en 100,000 y
  la del experimento en 10,000 a lo largo de todo el pipeline, como ya
  reportaban `reporte_calidad_observacional_embudo.csv` y las bitácoras previas.
- No se registró ninguna decisión nueva en la tabla "Decisiones tomadas" de
  `CLAUDE.md`: esta sesión no resolvió ningún estimando ni descartó ninguna
  especificación, solo dejó en archivo cifras que ya se reportaban.
