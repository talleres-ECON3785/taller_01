# Bitácora — 2026-09-13: Script `00_main.R` para correr todo el pipeline

## Qué se hizo

- Se creó `00_main.R` en la raíz del proyecto: un script maestro que corre
  los scripts de `02_Scripts/` en el orden de su numeración, cada uno en un
  entorno (`environment`) propio para que las variables de un script no
  contaminen el siguiente. Antes de sourcear nada, verifica que el directorio
  de trabajo sea la raíz del proyecto (busca `taller1.Rproj`) y detiene la
  ejecución con un mensaje claro si no lo es.
- Se corrió el pipeline completo (`Rscript -e 'source("00_main.R")'`) para
  confirmar que los 6 scripts corren sin errores ni warnings de principio a
  fin, y que generan las tablas y figuras esperadas en `03_Resultados/`.
- Al revisar la corrida se encontró una dependencia de datos entre scripts
  que no correspondía a su numeración: el script que hacía las descriptivas
  del experimento leía `01_Datos/03_Listos/experimento_listos.RDS`, un
  archivo que produce el script de procesamiento, pero el de descriptivas
  tenía un número menor. Esto no causaba error porque el `.RDS` ya estaba
  guardado en disco de una corrida anterior, pero sí habría fallado en una
  corrida desde cero. Se reportó el hallazgo al usuario en vez de reordenar
  los scripts unilateralmente.
- El usuario renombró los scripts para resolver la inconsistencia:
  `03_descriptivas_experimento.R` → `04_descriptivas_experimento.R` y
  `04_procesar_datos_experimento.R` → `03_procesar_datos_experimento.R` (así
  el procesamiento corre antes que las descriptivas que dependen de él). Se
  actualizó la lista de scripts en `00_main.R` para reflejar los nombres
  nuevos y se volvió a correr el pipeline completo para confirmar que sigue
  ejecutándose sin errores con el nuevo orden.

## Por qué

- El taller requiere poder reproducir todo el análisis (limpieza,
  descriptivas, procesamiento del experimento, balance, ITT) en una sola
  ejecución, sin pasos manuales ni depender del orden en que cada persona del
  equipo corrió los scripts originalmente.
- Corregir la numeración (en vez de, por ejemplo, hacer que `00_main.R`
  ignorara el orden numérico) mantiene el principio de que el número de cada
  script indica su lugar real en el flujo Crudos → Procesados → Listos, que
  es lo que el resto del equipo usa para orientarse.

## Qué se descubrió

- La dependencia entre el script de descriptivas del experimento y el de
  procesamiento no estaba explícita en el código (no hay una verificación de
  que el `.RDS` de entrada exista o esté actualizado); solo se hizo visible
  al forzar una corrida completa y ordenada desde `00_main.R`. Sirve como
  recordatorio de que los scripts individuales no se habían probado antes en
  una secuencia limpia de principio a fin.

## Problemas / pendientes

- Ningún script verifica explícitamente que sus archivos de entrada existan
  antes de leerlos (por ejemplo, con `stopifnot(file.exists(...))`); si en el
  futuro se vuelve a romper el orden de dependencias, el error solo aparecerá
  como un `readRDS` fallido sin contexto. Queda como posible mejora, no se
  implementó en esta sesión por no ser parte de lo pedido.
- Al cerrar esta sesión, `git status` mostraba un archivo nuevo sin
  seguimiento, `02_Scripts/07_graficas_experimento.R`, que no se originó en
  esta conversación. No se documenta en detalle aquí porque no hay contexto
  sobre su contenido o propósito; conviene que quien lo creó lo registre en
  la próxima bitácora.
