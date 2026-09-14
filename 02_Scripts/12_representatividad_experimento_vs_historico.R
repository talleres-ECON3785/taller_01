# Este script compara la muestra del experimento (datos_experimento.Rds,
# n=10,000) contra la poblacion historica (datos_historicos.Rds, n=100,000)
# para evaluar representatividad: si ambas muestras se parecen en sus
# caracteristicas, el resultado del ITT (06_analisis_experimento.R)
# probablemente generaliza a la base completa de usuarios de CheMarket; si
# no, hay que acotar para quien aplica.
#
# Misma logica que el balance de tratamiento/control de
# '05_balance_experimento.R', pero aqui la comparacion es muestra del
# experimento vs. poblacion historica, no tratamiento vs. control dentro
# del experimento.
#
# ADVERTENCIA de escala: con n=100,000 vs. n=10,000, hasta diferencias muy
# pequenas salen "estadisticamente significativas". Por eso este script
# reporta tambien la MAGNITUD de cada diferencia (puntos porcentuales o
# unidades), no solo el p-valor -- la magnitud es lo que hay que evaluar
# para decidir si una falta de representatividad importa en la practica.

library(tidyverse)
library(modelsummary)
library(writexl)

# -----------------------------------------------------------------------------
# 1. Cargar y combinar las dos bases limpias (nunca las crudas)
# -----------------------------------------------------------------------------

obs <- readRDS("01_Datos/03_Listos/observacional_limpio.Rds")
exp <- readRDS("01_Datos/03_Listos/experimento_listos.RDS")

# variables que comparten ambas bases ('easier_signup' solo existe en el
# experimento por diseno -- es la asignacion al tratamiento -- y no aplica
# a una comparacion de representatividad de la muestra)
vars_comunes <- c(
  "Revenue", "sign_up", "time_spent", "past_sessions",
  "device_type", "is_returning_user", "os_type"
)

combinado <- bind_rows(
  obs |> select(all_of(vars_comunes)) |> mutate(en_experimento = 0),
  exp |> select(all_of(vars_comunes)) |> mutate(en_experimento = 1)
) |>
  mutate(
    device_type = relevel(factor(device_type), ref = "desktop"),
    os_type = relevel(factor(os_type), ref = "osx"),
    muestra = factor(en_experimento,
      levels = c(0, 1),
      labels = c("Historico", "Experimento")
    )
  )
# categorias de referencia fijadas explicitamente (desktop/osx), igual que
# en '10_regresion_correlacional_observacional.R', en vez de depender del
# orden alfabetico por defecto de R. Esto asume que 'device_type'/'os_type'
# usan las mismas categorias, con la misma capitalizacion, en ambas bases
# -- si relevel() da error o las categorias no calzan, revisar antes de
# interpretar la tabla.

cat("N historico:", sum(combinado$en_experimento == 0), "\n")
cat("N experimento:", sum(combinado$en_experimento == 1), "\n")

# -----------------------------------------------------------------------------
# 2. Tabla de comparacion por caracteristica (excluye Revenue y sign_up:
#    son resultados/outcomes, no caracteristicas de composicion de la
#    muestra -- misma razon por la que 05_balance_experimento.R los
#    excluyo de su tabla de balance)
# -----------------------------------------------------------------------------

tabla_representatividad <- datasummary_balance(
  ~muestra,
  data = combinado |> select(-Revenue, -sign_up, -en_experimento),
  dinm_statistic = "p.value"
)

tabla_representatividad

# -----------------------------------------------------------------------------
# 3. Test conjunto: ¿la pertenencia a la muestra del experimento es
#    predecible a partir de las caracteristicas? Mismo enfoque que el
#    F-test de 05_balance_experimento.R (modelo de probabilidad lineal +
#    F-test global, para evitar comparaciones multiples variable por
#    variable)
# -----------------------------------------------------------------------------

modelo_representatividad <- lm(
  en_experimento ~ device_type + os_type + is_returning_user +
    past_sessions + time_spent,
  data = combinado
)

glance_representatividad <- broom::glance(modelo_representatividad)

fila_f <- data.frame(
  term = c("Estadistico F", "P-valor (test conjunto)"),
  "en_experimento" = c(
    sprintf("%.2f", glance_representatividad$statistic),
    sprintf("%.3f", glance_representatividad$p.value)
  ),
  check.names = FALSE
)

# mismas etiquetas y categorias de referencia que
# '10_regresion_correlacional_observacional.R', para mantener consistencia
# de terminologia entre los dos scripts que usan estas variables
etiquetas_representatividad <- c(
  "device_typemobile" = "Movil (ref. desktop)",
  "device_typetablet" = "Tablet (ref. desktop)",
  "os_typeother"      = "Otro OS (ref. OSX)",
  "os_typewindows"    = "Windows (ref. OSX)",
  "is_returning_user" = "Usuario recurrente",
  "past_sessions"     = "Sesiones anteriores",
  "time_spent"        = "Tiempo en el sitio",
  "(Intercept)"       = "Intercepto"
)

test_conjunto_representatividad <- modelsummary(
  list("en_experimento" = modelo_representatividad),
  coef_map = etiquetas_representatividad,
  gof_map = c("nobs", "r.squared"),
  add_rows = fila_f,
  title = "Test conjunto: pertenencia a la muestra del experimento ~ caracteristicas"
)

test_conjunto_representatividad

# -----------------------------------------------------------------------------
# 4. Magnitud de las diferencias (no solo el p-valor -- ver advertencia del
#    encabezado sobre el tamano de muestra)
# -----------------------------------------------------------------------------

diferencias_categoricas <- combinado |>
  select(muestra, device_type, os_type, is_returning_user) |>
  mutate(across(c(device_type, os_type, is_returning_user), as.character)) |>
  pivot_longer(-muestra, names_to = "variable", values_to = "valor") |>
  count(muestra, variable, valor) |>
  group_by(muestra, variable) |>
  mutate(proporcion = n / sum(n)) |>
  ungroup() |>
  select(-n) |>
  pivot_wider(names_from = muestra, values_from = proporcion, values_fill = 0) |>
  mutate(diferencia_pp = round((Experimento - Historico) * 100, 2)) |>
  arrange(variable, valor)

diferencias_categoricas

diferencias_numericas <- combinado |>
  select(muestra, time_spent, past_sessions) |>
  pivot_longer(-muestra, names_to = "variable", values_to = "valor") |>
  group_by(muestra, variable) |>
  summarise(media = mean(valor), .groups = "drop") |>
  pivot_wider(names_from = muestra, values_from = media) |>
  mutate(diferencia = round(Experimento - Historico, 3))

diferencias_numericas

# -----------------------------------------------------------------------------
# 5. Referencia: Revenue y sign_up promedio en cada base (no entran al test
#    de representatividad porque son resultados, no caracteristicas de
#    composicion de la muestra)
# -----------------------------------------------------------------------------

comparacion_outcomes <- combinado |>
  select(muestra, Revenue, sign_up) |>
  pivot_longer(-muestra, names_to = "variable", values_to = "valor") |>
  group_by(muestra, variable) |>
  summarise(media = mean(valor), .groups = "drop") |>
  pivot_wider(names_from = muestra, values_from = media)

comparacion_outcomes

# -----------------------------------------------------------------------------
# 6. Exportar todo a un solo Excel, como insumo de la presentacion (que no
#    debe incluir codigo)
# -----------------------------------------------------------------------------

write_xlsx(
  list(
    balance_caracteristicas = datasummary_balance(
      ~muestra,
      data = combinado |> select(-Revenue, -sign_up, -en_experimento),
      dinm_statistic = "p.value",
      output = "data.frame"
    ),
    test_conjunto = modelsummary(
      list("en_experimento" = modelo_representatividad),
      coef_map = etiquetas_representatividad,
      gof_map = c("nobs", "r.squared"),
      add_rows = fila_f,
      output = "data.frame"
    ),
    diferencias_categoricas = diferencias_categoricas,
    diferencias_numericas = diferencias_numericas,
    comparacion_outcomes = comparacion_outcomes
  ),
  "03_Resultados/Tablas/representatividad_experimento_vs_historico.xlsx"
)

cat("\nListo. Tabla exportada a 03_Resultados/Tablas/representatividad_experimento_vs_historico.xlsx\n")
cat("Recordatorio: revisar la MAGNITUD de las diferencias (seccion 4), no\n")
cat("solo el p-valor del test conjunto -- con estos tamanos de muestra casi\n")
cat("cualquier diferencia sale 'significativa'.\n")
