# =============================================================================
# Limpieza de la base observacional (datos_historicos.Rds)
# Taller 1 - ECON-3785
#
# Este script SOLO limpia y documenta calidad de datos. No ajusta ningun
# modelo. La base cruda NUNCA se modifica ni se sobrescribe.
# =============================================================================

library(tidyverse)

set.seed(2026)

# -----------------------------------------------------------------------------
# 1. Cargar datos crudos
# -----------------------------------------------------------------------------

# la base observacional del taller esta guardada como "datos_historicos.Rds"
obs_crudo <- readRDS("01_Datos/01_Crudos/datos_historicos.Rds")

n_inicial <- nrow(obs_crudo)

# embudo de observaciones: se va llenando en cada paso de este script
embudo <- tibble(
  paso = "01. Base cruda (datos_historicos.Rds)",
  n_obs = n_inicial,
  n_perdidas = 0L
)

# -----------------------------------------------------------------------------
# 2. Inspeccion de estructura
# -----------------------------------------------------------------------------

cat("Dimensiones de la base cruda:", dim(obs_crudo), "\n")
str(obs_crudo)
head(obs_crudo)

# la base tiene una variable adicional no documentada en CLAUDE.md: os_type
# (factor). Se conserva sin modificar; no hace parte de las 6 variables que
# pide el taller, pero se reporta su existencia.

# -----------------------------------------------------------------------------
# 3. Revision variable por variable
# -----------------------------------------------------------------------------

# contenedor de hallazgos para el reporte de calidad
hallazgos <- tibble(
  variable = character(),
  problema = character(),
  n_afectadas = integer(),
  alternativas_de_tratamiento = character(),
  decision_aplicada = character()
)

agregar_hallazgo <- function(tabla, variable, problema, n_afectadas,
                              alternativas, decision) {
  bind_rows(
    tabla,
    tibble(
      variable = variable,
      problema = problema,
      n_afectadas = n_afectadas,
      alternativas_de_tratamiento = alternativas,
      decision_aplicada = decision
    )
  )
}

# función auxiliar: límites de valores atípicos por rango intercuartílico (IQR)
limites_iqr <- function(x) {
  q1 <- quantile(x, 0.25, na.rm = TRUE)
  q3 <- quantile(x, 0.75, na.rm = TRUE)
  iqr <- q3 - q1
  # unname() evita que quantile() arrastre su propio nombre ("25%"/"75%")
  # y choque con los nombres inferior/superior al indexar el vector despues
  c(inferior = unname(q1 - 1.5 * iqr), superior = unname(q3 + 1.5 * iqr))
}

## --- Revenue, time_spent, past_sessions ------------------------------------

for (var in c("Revenue", "time_spent", "past_sessions")) {
  x <- obs_crudo[[var]]

  n_na <- sum(is.na(x))
  n_negativos <- sum(x < 0, na.rm = TRUE)
  lims <- limites_iqr(x)
  n_atipicos <- sum(x < lims["inferior"] | x > lims["superior"], na.rm = TRUE)

  cat("\n--- ", var, " ---\n", sep = "")
  cat("NAs:", n_na, "| Negativos:", n_negativos,
      "| Atipicos (IQR 1.5x):", n_atipicos, "\n")
  print(summary(x))

  if (n_na > 0) {
    hallazgos <- agregar_hallazgo(
      hallazgos, var, "Valores faltantes (NA)", n_na,
      "1) Excluir filas con NA; 2) Imputar con media/mediana y marcar con indicador",
      "Pendiente de decision del equipo"
    )
  }
  if (n_negativos > 0) {
    hallazgos <- agregar_hallazgo(
      hallazgos, var, "Valores negativos (imposibles para esta variable)",
      n_negativos,
      "1) Excluir observaciones; 2) Revisar si es error de signo y corregir con valor absoluto",
      "Pendiente de decision del equipo"
    )
  }
  if (n_atipicos > 0) {
    hallazgos <- agregar_hallazgo(
      hallazgos, var,
      paste0("Valores extremos fuera de [Q1-1.5*IQR, Q3+1.5*IQR] = [",
             round(lims["inferior"], 2), ", ", round(lims["superior"], 2), "]"),
      n_atipicos,
      "1) Mantener (pueden ser usuarios/sesiones legitimas de alto valor); 2) Marcar con indicador sin excluir; 3) Excluir si se confirma que son errores de captura",
      "Pendiente de decision del equipo"
    )
  }
}

## --- sign_up, is_returning_user (binarias) ---------------------------------

for (var in c("sign_up", "is_returning_user")) {
  x <- obs_crudo[[var]]

  n_na <- sum(is.na(x))
  n_fuera_rango <- sum(!(x %in% c(0, 1)) & !is.na(x))

  cat("\n--- ", var, " ---\n", sep = "")
  cat("NAs:", n_na, "| Fuera de {0,1}:", n_fuera_rango, "\n")
  print(table(x, useNA = "ifany"))

  if (n_na > 0) {
    hallazgos <- agregar_hallazgo(
      hallazgos, var, "Valores faltantes (NA)", n_na,
      "1) Excluir filas con NA; 2) Marcar como categoria aparte si tiene sentido",
      "Pendiente de decision del equipo"
    )
  }
  if (n_fuera_rango > 0) {
    hallazgos <- agregar_hallazgo(
      hallazgos, var, "Valores fuera de {0,1}", n_fuera_rango,
      "1) Excluir observaciones; 2) Revisar si son errores de codificacion recuperables",
      "Pendiente de decision del equipo"
    )
  }
}

## --- device_type (categorica) ----------------------------------------------

categorias_validas <- c("mobile", "desktop", "tablet")
device_x <- as.character(obs_crudo$device_type)

n_na_device <- sum(is.na(device_x))
n_fuera_categorias <- sum(!(device_x %in% categorias_validas) & !is.na(device_x))

cat("\n--- device_type ---\n")
cat("NAs:", n_na_device, "| Fuera de {mobile, desktop, tablet}:",
    n_fuera_categorias, "\n")
print(table(obs_crudo$device_type, useNA = "ifany"))

if (n_na_device > 0) {
  hallazgos <- agregar_hallazgo(
    hallazgos, "device_type", "Valores faltantes (NA)", n_na_device,
    "1) Excluir filas con NA; 2) Marcar como categoria 'desconocido'",
    "Pendiente de decision del equipo"
  )
}
if (n_fuera_categorias > 0) {
  hallazgos <- agregar_hallazgo(
    hallazgos, "device_type", "Categorias fuera de {mobile, desktop, tablet}",
    n_fuera_categorias,
    "1) Excluir observaciones; 2) Reclasificar manualmente si el valor es reconocible",
    "Pendiente de decision del equipo"
  )
}

# -----------------------------------------------------------------------------
# 4. Duplicados exactos de fila
# -----------------------------------------------------------------------------

n_duplicados <- sum(duplicated(obs_crudo))
cat("\nFilas duplicadas exactas:", n_duplicados, "\n")

if (n_duplicados > 0) {
  hallazgos <- agregar_hallazgo(
    hallazgos, "(fila completa)", "Duplicados exactos de fila", n_duplicados,
    "No aplica: se eliminan automaticamente por ser una decision inequivoca",
    "Corregido automaticamente (se conserva la primera ocurrencia)"
  )
}

obs_sin_duplicados <- distinct(obs_crudo)

embudo <- bind_rows(
  embudo,
  tibble(
    paso = "02. Eliminar duplicados exactos de fila",
    n_obs = nrow(obs_sin_duplicados),
    n_perdidas = nrow(obs_crudo) - nrow(obs_sin_duplicados)
  )
)

# -----------------------------------------------------------------------------
# 5. Combinaciones inconsistentes entre variables
# -----------------------------------------------------------------------------

# is_returning_user == 0 pero past_sessions > 0: un usuario nuevo no deberia
# tener sesiones previas
n_incons_returning <- obs_sin_duplicados |>
  filter(is_returning_user == 0, past_sessions > 0) |>
  nrow()

cat("\nInconsistencia is_returning_user==0 & past_sessions>0:",
    n_incons_returning, "\n")

if (n_incons_returning > 0) {
  hallazgos <- agregar_hallazgo(
    hallazgos, "is_returning_user / past_sessions",
    "is_returning_user == 0 con past_sessions > 0 (usuario 'nuevo' con historial)",
    n_incons_returning,
    "1) Mantener y reportar como limitacion de los datos; 2) Marcar con indicador de inconsistencia; 3) Excluir si se confirma error de captura",
    "Pendiente de decision del equipo"
  )
}

# sign_up == 1 pero time_spent == 0: un usuario registrado con cero tiempo en
# el sitio es, al menos, sospechoso
n_incons_signup_tiempo <- obs_sin_duplicados |>
  filter(sign_up == 1, time_spent == 0) |>
  nrow()

cat("Inconsistencia sign_up==1 & time_spent==0:",
    n_incons_signup_tiempo, "\n")

if (n_incons_signup_tiempo > 0) {
  hallazgos <- agregar_hallazgo(
    hallazgos, "sign_up / time_spent",
    "sign_up == 1 con time_spent == 0 (registro sin tiempo registrado en el sitio)",
    n_incons_signup_tiempo,
    "1) Mantener y reportar como limitacion de los datos; 2) Marcar con indicador de inconsistencia; 3) Excluir si se confirma error de captura",
    "Pendiente de decision del equipo"
  )
}

# -----------------------------------------------------------------------------
# 6. Correcciones automaticas inequivocas (solo tipos de columna)
# -----------------------------------------------------------------------------

# is_returning_user y sign_up llegan como numeric/integer con valores 0/1;
# se estandarizan a integer para que ambas queden con el mismo tipo
obs_final <- obs_sin_duplicados |>
  mutate(
    is_returning_user = as.integer(is_returning_user),
    sign_up = as.integer(sign_up)
  )

cat("\nCorreccion automatica aplicada: is_returning_user y sign_up",
    "estandarizadas a tipo integer (antes mezclaban numeric/integer).\n")

embudo <- bind_rows(
  embudo,
  tibble(
    paso = "03. Estandarizar tipos de columna (sin perdida de observaciones)",
    n_obs = nrow(obs_final),
    n_perdidas = 0L
  )
)

cat("\n=== Tabla de embudo de observaciones ===\n")
print(embudo)

# -----------------------------------------------------------------------------
# 7. Guardar base lista para analisis
# -----------------------------------------------------------------------------

saveRDS(obs_final, "01_Datos/03_Listos/observacional_limpio.Rds")

# -----------------------------------------------------------------------------
# 8. Guardar reporte de calidad de datos
# -----------------------------------------------------------------------------

# se guarda el embudo y los hallazgos en un solo csv, en secciones, para
# lectura del equipo (sin jerga de codigo)
reporte_embudo <- embudo |>
  rename(
    Paso = paso,
    `Observaciones restantes` = n_obs,
    `Observaciones perdidas en este paso` = n_perdidas
  )

reporte_hallazgos <- hallazgos |>
  rename(
    Variable = variable,
    Problema = problema,
    `Observaciones afectadas` = n_afectadas,
    `Alternativas de tratamiento` = alternativas_de_tratamiento,
    `Decision aplicada` = decision_aplicada
  )

write_csv(reporte_embudo, "03_Resultados/Tablas/reporte_calidad_observacional_embudo.csv")
write_csv(reporte_hallazgos, "03_Resultados/Tablas/reporte_calidad_observacional.csv")

cat("\nListo. Base limpia guardada en 01_Datos/03_Listos/observacional_limpio.Rds\n")
cat("Reportes guardados en 03_Resultados/Tablas/reporte_calidad_observacional*.csv\n")
