#Este script busca estudiar el balance de los grupos de tratamiento y
#control en el experimento de Chemarket.

library(tidyverse)
library(modelsummary)
library(writexl)


experimento <- readRDS("01_Datos/03_Listos/experimento_listos.RDS")

#Realizamos tabla de balance de covariables en el experimento
# Se excluyen sign_up y Revenue porque son resultados (outcomes), no
# covariables de pre-tratamiento: no deben entrar a la tabla de balance.
experimento_balance <- experimento |>
  select(-sign_up, -Revenue)

balance <- datasummary_balance(
  ~easier_signup,
  data = experimento_balance,
  dinm_statistic = "p.value"
)

# Test conjunto de balance: se regresa easier_signup sobre todas las
# covariables pre-tratamiento (modelo de probabilidad lineal) y se usa el
# F-test global (H0: todos los coeficientes son cero) como prueba conjunta
# de que la asignación al tratamiento no está correlacionada con ninguna
# covariable, evitando el problema de comparaciones múltiples de mirar
# cada p-valor individual por separado.
modelo_balance <- lm(
  easier_signup ~ device_type + is_returning_user + past_sessions + time_spent,
  data = experimento_balance
)

# "statistic" y "p.value" no se pueden pasar por gof_map: modelsummary
# reserva esos nombres para las estadísticas de los coeficientes (t-valor y
# p-valor de cada variable) y descarta la fila si se usan en gof_map. Por
# eso el F-test global se arma a mano con add_rows.
glance_balance <- broom::glance(modelo_balance)

fila_f <- data.frame(
  term = c("Estadístico F", "P-valor (test conjunto)"),
  "easier_signup" = c(
    sprintf("%.2f", glance_balance$statistic),
    sprintf("%.3f", glance_balance$p.value)
  ),
  check.names = FALSE
)

# Se nombra el modelo como "easier_signup" para que el encabezado de la
# columna deje explícito cuál es la variable dependiente.
test_conjunto <- modelsummary(
  list("easier_signup" = modelo_balance),
  gof_map = c("nobs", "r.squared"),
  add_rows = fila_f,
  title = "Test conjunto de balance",
)

# ---------------------------------------------------------------------------
# Exportar tabla de balance y test conjunto a un solo Excel
# ---------------------------------------------------------------------------

# se exportan como data.frame las mismas tablas mostradas arriba, para
# tener un unico libro con una hoja por tabla como insumo de la
# presentacion (que no debe incluir codigo)
balance_df <- datasummary_balance(
  ~easier_signup,
  data = experimento_balance,
  dinm_statistic = "p.value",
  output = "data.frame"
)

test_conjunto_df <- modelsummary(
  list("easier_signup" = modelo_balance),
  gof_map = c("nobs", "r.squared"),
  add_rows = fila_f,
  output = "data.frame"
)

write_xlsx(
  list(
    balance = balance_df,
    test_conjunto = test_conjunto_df
  ),
  "03_Resultados/Tablas/balance_experimento.xlsx"
)
