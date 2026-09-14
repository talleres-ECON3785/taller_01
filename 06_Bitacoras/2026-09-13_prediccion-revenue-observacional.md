# Bitácora — 2026-09-13: Modelo predictivo de Revenue (observacional)

## Qué se hizo

- Se creó `02_Scripts/11_prediccion_revenue_observacional.R`, a partir de
  código provisto por el usuario, que evalúa qué tan bien se puede
  predecir `Revenue` con las variables disponibles de
  `observacional_limpio.Rds`, usando regresión lineal (único modelo
  permitido en el taller), evaluada fuera de muestra con partición
  entrenamiento/prueba 80/20 y `set.seed(2026)`.
- Se corrigió una referencia desactualizada en el encabezado del código
  provisto: mencionaba `08_regresion_correlacional_observacional.R`, pero
  ese script quedó numerado `10_` (08 y 09 los ocupó la discontinuidad
  tiempo-revenue de una sesión anterior). Se actualizó la referencia al
  nombre real del archivo.
- El script compara dos modelos, ambos evaluados solo en el conjunto de
  prueba (RMSE y MAE):
  - Referencia ingenua: predice la media de `Revenue` en entrenamiento
    para toda observación de prueba.
  - Regresión lineal: `Revenue ~ sign_up + time_spent + past_sessions + is_returning_user + device_type + os_type`,
    entrenada solo con el conjunto de entrenamiento.
- Guarda la comparación en
  `03_Resultados/Tablas/desempeno_predictivo_observacional.csv`.
- El script deja explícito (comentarios y mensajes impresos) que es un
  ejercicio de predicción, no de inferencia causal ni de asociación:
  `sign_up` se usa aquí solo como predictor, sin implicar nada sobre el
  efecto de registrarse. Remite a `10_regresion_correlacional_observacional.R`
  para la pregunta correlacional y a `06_analisis_experimento.R` para la
  causal.
- Se corrió el script completo sin errores.

## Por qué

- El usuario pidió formalizar en un script versionado un ejercicio
  predictivo separado de los ejercicios correlacional (script 10) y
  causal (experimento), evaluando el desempeño siempre fuera de muestra
  como exige `CLAUDE.md`.

## Qué se descubrió

- N entrenamiento: 80,000; N prueba: 20,000.
- Referencia ingenua (media de train): RMSE 2.716, MAE 1.830 en prueba.
- Regresión lineal con las 6 variables: RMSE 2.314, MAE 1.552 en prueba
  (R² en entrenamiento: 0.272).
- Mejora en RMSE frente a la referencia: 14.8%.
- Todos los coeficientes de la regresión son significativos (p<2e-16 en
  los ocho), sin que esto se interprete como relevancia causal o de
  negocio: es un modelo predictivo.

## Problemas / pendientes

- Ningún error de ejecución.
- Este script no se coordinó con la sesión de "estandarización de
  gráficas" ocurrida en paralelo (`00_formato_graficas.R`, ver CLAUDE.md
  sección "Formato de las gráficas"): no aplica porque
  `11_prediccion_revenue_observacional.R` no genera ninguna figura, solo
  una tabla.
- Sigue sin tocar `01_Datos/02_Procesados/observacional_limpio_BACKUP.Rds`
  (archivo sin trackear de origen desconocido, no es de esta tarea).
