# Modelo predictivo de Revenue a partir de datos historicos.
#
# Objetivo: evaluar que tan bien se puede predecir Revenue con las
# variables disponibles, usando regresion lineal (unico modelo permitido
# en este taller), evaluada siempre FUERA DE MUESTRA -- nunca dentro de
# muestra -- con semilla fija para reproducibilidad (enunciado, seccion
# "Reproducibilidad": semilla 2026).
#
# IMPORTANTE: este es un ejercicio de PREDICCION, no de inferencia causal
# ni de asociacion. 'sign_up' se usa aqui como un predictor mas, util para
# predecir Revenue, sin que eso implique nada sobre el efecto de
# registrarse. Para la pregunta correlacional ver
# '10_regresion_correlacional_observacional.R'; para la causal, ver
# '06_analisis_experimento.R'.

library(tidyverse)

set.seed(2026)

obs <- readRDS("01_Datos/02_Procesados/observacional_limpio.Rds")

# -----------------------------------------------------------------------------
# 1. Particion train/test (80/20), semilla 2026
# -----------------------------------------------------------------------------

n <- nrow(obs)
indices_train <- sample(seq_len(n), size = round(0.8 * n))

train <- obs[indices_train, ]
test <- obs[-indices_train, ]

cat("N entrenamiento:", nrow(train), "\n")
cat("N prueba:", nrow(test), "\n")

# -----------------------------------------------------------------------------
# 2. Referencia simple (naive): predice la media de Revenue en train para
#    toda observacion de test, sin usar ninguna variable. Es la vara con
#    la que se mide si el modelo realmente aporta algo.
# -----------------------------------------------------------------------------

prediccion_referencia <- mean(train$Revenue)

error_referencia <- test$Revenue - prediccion_referencia
rmse_referencia <- sqrt(mean(error_referencia^2))
mae_referencia <- mean(abs(error_referencia))

cat("\nReferencia (media de train) -> RMSE:", round(rmse_referencia, 3),
    "| MAE:", round(mae_referencia, 3), "\n")

# -----------------------------------------------------------------------------
# 3. Regresion lineal (Revenue en nivel -- mismas unidades del negocio,
#    igual que en '10_regresion_correlacional_observacional.R'),
#    entrenada SOLO con train
# -----------------------------------------------------------------------------

modelo_prediccion <- lm(
  Revenue ~ sign_up + time_spent + past_sessions + is_returning_user +
    device_type + os_type,
  data = train
)

summary(modelo_prediccion)

predicciones_test <- predict(modelo_prediccion, newdata = test)

error_modelo <- test$Revenue - predicciones_test
rmse_modelo <- sqrt(mean(error_modelo^2))
mae_modelo <- mean(abs(error_modelo))

cat("\nRegresión lineal -> RMSE:", round(rmse_modelo, 3),
    "| MAE:", round(mae_modelo, 3), "\n")

mejora_pct <- 100 * (rmse_referencia - rmse_modelo) / rmse_referencia
cat("\nMejora en RMSE frente a la referencia:", round(mejora_pct, 1), "%\n")

# -----------------------------------------------------------------------------
# 4. Guardar tabla resumen
# -----------------------------------------------------------------------------

tabla_prediccion <- tibble(
  Modelo = c("Referencia (media de train)", "Regresión lineal"),
  RMSE = c(rmse_referencia, rmse_modelo),
  MAE = c(mae_referencia, mae_modelo)
)

write_csv(tabla_prediccion, "03_Resultados/Tablas/desempeno_predictivo_observacional.csv")

cat("\nListo. Tabla exportada a 03_Resultados/Tablas/desempeno_predictivo_observacional.csv\n")
cat("Recordatorio: esto es un ejercicio predictivo -- no identifica el\n")
cat("efecto causal ni corrige sesgo de seleccion. 'sign_up' se usa aqui\n")
cat("solo como predictor, no como variable de interes causal.\n")
