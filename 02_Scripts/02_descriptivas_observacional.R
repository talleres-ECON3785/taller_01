# =============================================================================
# Estadisticas descriptivas de la base observacional (observacional_limpio.Rds)
# Taller 1 - ECON-3785
#
# IMPORTANTE: este script es puramente descriptivo. Las diferencias por
# sign_up que se calculan aqui son correlacionales, NO estimaciones de efecto
# causal: en datos observacionales no hay asignacion aleatoria a sign_up, asi
# que los usuarios que se registran pueden diferir sistematicamente de los que
# no se registran por razones distintas al registro mismo. Este script NO
# concluye si CheMarket deberia invertir en aumentar el registro; esa pregunta
# se resuelve integrando el experimento (datos_experimento.Rds), en otra
# sesion. Tampoco se ajusta ningun modelo aqui.
# =============================================================================

library(tidyverse)

set.seed(2026)

obs <- readRDS("01_Datos/02_Procesados/observacional_limpio.Rds")

dir.create("03_Resultados/Tablas", recursive = TRUE, showWarnings = FALSE)
dir.create("03_Resultados/Figuras", recursive = TRUE, showWarnings = FALSE)

# -----------------------------------------------------------------------------
# 1. Estadisticas univariadas de las 6 variables del taller
# -----------------------------------------------------------------------------

univariadas_numericas <- obs |>
  select(Revenue, time_spent, past_sessions) |>
  pivot_longer(everything(), names_to = "variable", values_to = "valor") |>
  group_by(variable) |>
  summarise(
    n = n(),
    media = mean(valor),
    mediana = median(valor),
    desv_estandar = sd(valor),
    minimo = min(valor),
    q1 = quantile(valor, 0.25),
    q3 = quantile(valor, 0.75),
    maximo = max(valor),
    .groups = "drop"
  )

univariadas_numericas

univariadas_sign_up <- obs |>
  count(sign_up) |>
  mutate(proporcion = n / sum(n))

univariadas_is_returning <- obs |>
  count(is_returning_user) |>
  mutate(proporcion = n / sum(n))

univariadas_device_type <- obs |>
  count(device_type) |>
  mutate(proporcion = n / sum(n))

write_csv(univariadas_numericas, "03_Resultados/Tablas/univariadas_numericas.csv")
write_csv(univariadas_sign_up, "03_Resultados/Tablas/univariadas_sign_up.csv")
write_csv(univariadas_is_returning, "03_Resultados/Tablas/univariadas_is_returning_user.csv")
write_csv(univariadas_device_type, "03_Resultados/Tablas/univariadas_device_type.csv")

# -----------------------------------------------------------------------------
# 2. Mismas estadisticas desagregadas por sign_up (comparacion descriptiva)
# -----------------------------------------------------------------------------

# Revenue, time_spent, past_sessions por sign_up
por_signup_numericas <- obs |>
  select(sign_up, Revenue, time_spent, past_sessions) |>
  pivot_longer(-sign_up, names_to = "variable", values_to = "valor") |>
  group_by(sign_up, variable) |>
  summarise(
    n = n(),
    media = mean(valor),
    mediana = median(valor),
    desv_estandar = sd(valor),
    minimo = min(valor),
    q1 = quantile(valor, 0.25),
    q3 = quantile(valor, 0.75),
    maximo = max(valor),
    .groups = "drop"
  ) |>
  arrange(variable, sign_up)

por_signup_numericas

# device_type por sign_up
por_signup_device_type <- obs |>
  count(sign_up, device_type) |>
  group_by(sign_up) |>
  mutate(proporcion = n / sum(n)) |>
  ungroup()

# is_returning_user por sign_up
por_signup_is_returning <- obs |>
  count(sign_up, is_returning_user) |>
  group_by(sign_up) |>
  mutate(proporcion = n / sum(n)) |>
  ungroup()

write_csv(por_signup_numericas, "03_Resultados/Tablas/descriptivas_por_sign_up_numericas.csv")
write_csv(por_signup_device_type, "03_Resultados/Tablas/descriptivas_por_sign_up_device_type.csv")
write_csv(por_signup_is_returning, "03_Resultados/Tablas/descriptivas_por_sign_up_is_returning_user.csv")

# -----------------------------------------------------------------------------
# 3. Matriz de correlacion entre variables numericas
# -----------------------------------------------------------------------------

# sign_up e is_returning_user son binarias (0/1); se incluyen como numericas
# para ver su correlacion lineal con el resto, sin que esto implique nada
# causal
matriz_correlacion <- obs |>
  select(Revenue, time_spent, past_sessions, sign_up, is_returning_user) |>
  cor(use = "complete.obs")

matriz_correlacion

matriz_correlacion_df <- as_tibble(matriz_correlacion, rownames = "variable")

write_csv(matriz_correlacion_df, "03_Resultados/Tablas/matriz_correlacion.csv")

# -----------------------------------------------------------------------------
# 4. Figuras: Revenue y time_spent por sign_up
# -----------------------------------------------------------------------------

obs_fig <- obs |>
  mutate(sign_up_lab = if_else(sign_up == 1, "Registrado", "No registrado"))

hist_revenue <- ggplot(obs_fig, aes(x = Revenue, fill = sign_up_lab)) +
  geom_histogram(position = "identity", alpha = 0.5, bins = 40) +
  labs(
    title = "Distribucion de Revenue por sign_up (descriptivo, no causal)",
    x = "Revenue", y = "Frecuencia", fill = "sign_up"
  ) +
  theme_minimal()

ggsave("03_Resultados/Figuras/histograma_revenue_por_sign_up.png",
       hist_revenue, width = 8, height = 5)

hist_time_spent <- ggplot(obs_fig, aes(x = time_spent, fill = sign_up_lab)) +
  geom_histogram(position = "identity", alpha = 0.5, bins = 40) +
  labs(
    title = "Distribucion de time_spent por sign_up (descriptivo, no causal)",
    x = "time_spent", y = "Frecuencia", fill = "sign_up"
  ) +
  theme_minimal()

ggsave("03_Resultados/Figuras/histograma_time_spent_por_sign_up.png",
       hist_time_spent, width = 8, height = 5)

box_revenue <- ggplot(obs_fig, aes(x = sign_up_lab, y = Revenue, fill = sign_up_lab)) +
  geom_boxplot() +
  labs(
    title = "Revenue por sign_up (descriptivo, no causal)",
    x = NULL, y = "Revenue", fill = "sign_up"
  ) +
  theme_minimal()

ggsave("03_Resultados/Figuras/boxplot_revenue_por_sign_up.png",
       box_revenue, width = 8, height = 5)

box_time_spent <- ggplot(obs_fig, aes(x = sign_up_lab, y = time_spent, fill = sign_up_lab)) +
  geom_boxplot() +
  labs(
    title = "time_spent por sign_up (descriptivo, no causal)",
    x = NULL, y = "time_spent", fill = "sign_up"
  ) +
  theme_minimal()

ggsave("03_Resultados/Figuras/boxplot_time_spent_por_sign_up.png",
       box_time_spent, width = 8, height = 5)

cat("\nListo. Tablas guardadas en 03_Resultados/Tablas/ y figuras en 03_Resultados/Figuras/.\n")
cat("Recordatorio: las diferencias por sign_up reportadas aqui son descriptivas,\n")
cat("no estimaciones de efecto causal (no hay asignacion aleatoria en datos_historicos.Rds).\n")
