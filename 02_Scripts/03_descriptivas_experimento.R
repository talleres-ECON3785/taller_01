#este script busca hacer un análisis descriptivo de las variables
#de la base del experimento.
#se incluye en el análisis:
#    - Estadisticas descriptivas
#    - Ingreso promedio por grupos


library(tidyverse)
library(skimr)
library(writexl)

experimento <- readRDS("01_Datos/03_Listos/experimento_listos.RDS")

# ---------------------------------------------------------------------------
# 1. Descriptivas numéricas
# ---------------------------------------------------------------------------

# n, missing, media, sd, min, max, cuartiles e histograma por variable
descriptivas_numericas <- experimento |>
  select(Revenue, time_spent, past_sessions) |>
  skim()

descriptivas_numericas

# ---------------------------------------------------------------------------
# 2. Descriptivas categoricas
# ---------------------------------------------------------------------------

frecuencias_device_type <- experimento |>
  count(device_type) |>
  mutate(proporcion = n / sum(n))

frecuencias_device_type

frecuencias_os_type <- experimento |>
  count(os_type) |>
  mutate(proporcion = n / sum(n))

frecuencias_os_type

# ---------------------------------------------------------------------------
# 3. Descriptivas binarias
# ---------------------------------------------------------------------------

descriptiva_signup <- experimento |>
  count(sign_up) |>
  mutate(proporcion = n / sum(n))

descriptiva_signup

descriptiva_returning <- experimento |>
  count(is_returning_user) |>
  mutate(proporcion = n / sum(n))

descriptiva_returning

descriptiva_tratamiento <- experimento |>
  count(easier_signup) |>
  mutate(proporcion = n / sum(n))

descriptiva_tratamiento


# ---------------------------------------------------------------------------
# 4. Exportar tablas a Excel
# ---------------------------------------------------------------------------

# se exporta un unico libro con una hoja por tabla, para uso del equipo
# y como insumo de la presentacion (que no debe incluir codigo)
tablas_descriptivas <- list(
  numericas         = as_tibble(descriptivas_numericas),
  device_type       = frecuencias_device_type,
  os_type           = frecuencias_os_type,
  sign_up           = descriptiva_signup,
  is_returning_user = descriptiva_returning,
  easier_signup     = descriptiva_tratamiento
)

write_xlsx(
  tablas_descriptivas,
  "03_Resultados/Tablas/descriptivas_experimento.xlsx"
)
