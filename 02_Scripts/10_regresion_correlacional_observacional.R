# =============================================================================
# 10_regresion_correlacional_observacional.R
#
# Objetivo:
# Estimar la asociacion entre estar registrado (sign_up) y log(Revenue)
# en los datos historicos de CheMarket.
#
# IMPORTANTE:
# Estas regresiones son CORRELACIONALES, NO CAUSALES.
#
# En los datos historicos, sign_up no fue asignado aleatoriamente:
# los usuarios decidieron registrarse. Por lo tanto, registrados y
# no registrados pueden diferir sistematicamente en otras caracteristicas.
#
# El experimento responde una pregunta diferente:
# el efecto causal de ofrecer easier_signup sobre Revenue.
# =============================================================================


library(tidyverse)
library(modelsummary)


# -----------------------------------------------------------------------------
# 1. Cargar datos historicos limpios
# -----------------------------------------------------------------------------

obs <- readRDS(
  "01_Datos/03_Listos/observacional_limpio.Rds"
)

dim(obs)
names(obs)

obs <- obs |>
  mutate(
    device_type = relevel(factor(device_type), ref = "desktop"),
    os_type = relevel(factor(os_type), ref = "osx")
  )


# =============================================================================
# 2. Validar que log() sea aplicable
# =============================================================================

n_revenue_no_positivo <- sum(obs$Revenue <= 0)
n_time_no_positivo <- sum(obs$time_spent <= 0)

cat("\nRevenue <= 0:", n_revenue_no_positivo, "de", nrow(obs), "\n")
cat("time_spent <= 0:", n_time_no_positivo, "de", nrow(obs), "\n")

if (n_revenue_no_positivo > 0) {
  stop("Revenue contiene valores <= 0. No se puede estimar log(Revenue).")
}


# =============================================================================
# 3. Asociacion entre sign_up y log(Revenue)
# =============================================================================

obs <- obs |>
  mutate(log_revenue = log(Revenue))


# -----------------------------------------------------------------------------
# Modelo 1: asociacion bruta
# -----------------------------------------------------------------------------

modelo_log_simple <- lm(
  log_revenue ~ sign_up,
  data = obs
)

summary(modelo_log_simple)


# -----------------------------------------------------------------------------
# Modelo 2: asociacion controlando por caracteristicas observables
# -----------------------------------------------------------------------------
#
# past_sessions, is_returning_user, device_type y os_type son mas
# plausibles como caracteristicas preexistentes que time_spent.
#
# IMPORTANTE: incluir controles NO convierte esta regresion en causal.

modelo_log_controles <- lm(
  log_revenue ~ sign_up +
    past_sessions +
    is_returning_user +
    device_type +
    os_type,
  data = obs
)

summary(modelo_log_controles)


# -----------------------------------------------------------------------------
# Modelo 3: analisis de sensibilidad incluyendo log(time_spent)
# -----------------------------------------------------------------------------
#
# time_spent se mide durante la misma sesion que sign_up y Revenue.
# No conocemos con certeza el orden causal, por eso NO se usa como
# control principal. Se agrega solo para ver cuanto cambia la
# asociacion de sign_up al condicionar tambien por intensidad de uso.

if (n_time_no_positivo == 0) {

  obs <- obs |>
    mutate(log_time_spent = log(time_spent))

  modelo_log_tiempo <- lm(
    log_revenue ~ sign_up +
      log_time_spent +
      past_sessions +
      is_returning_user +
      device_type +
      os_type,
    data = obs
  )

  summary(modelo_log_tiempo)

} else {
  message(
    "time_spent contiene valores <= 0.",
    " No se estima el modelo con log(time_spent)."
  )
}


# -----------------------------------------------------------------------------
# Comparar los modelos
# -----------------------------------------------------------------------------

modelos_log <- list(
  "Asociacion simple" = modelo_log_simple,
  "Controles observables" = modelo_log_controles,
  "Incluye tiempo en sitio" = modelo_log_tiempo
)

etiquetas_log <- c(
  "sign_up" = "Registrado (sign_up)",
  "log_time_spent" = "Log(tiempo en el sitio)",
  "past_sessions" = "Sesiones anteriores",
  "is_returning_user" = "Usuario recurrente",
  "device_typemobile" = "Movil (ref. desktop)",
  "device_typetablet" = "Tablet (ref. desktop)",
  "os_typeother" = "Otro OS (ref. OSX)",
  "os_typewindows" = "Windows (ref. OSX)",
  "(Intercept)" = "Intercepto"
)

# se muestra en pantalla para revisar antes de exportar
modelsummary(
  modelos_log,
  coef_map = etiquetas_log,
  gof_map = c("nobs", "r.squared", "adj.r.squared"),
  stars = c("*" = 0.10, "**" = 0.05, "***" = 0.01),
  title = paste(
    "Asociacion entre registro y log(Revenue) en datos historicos",
    "(correlacional, no causal)"
  )
)

# version en archivo: al correr el pipeline con Rscript (00_main.R) las tablas
# que solo se imprimen en pantalla no quedan registradas en ningun lado, y
# estos coeficientes se citan en la presentacion
modelsummary(
  modelos_log,
  coef_map = etiquetas_log,
  gof_map = c("nobs", "r.squared", "adj.r.squared"),
  stars = c("*" = 0.10, "**" = 0.05, "***" = 0.01),
  title = paste(
    "Asociacion entre registro y log(Revenue) en datos historicos",
    "(correlacional, no causal)"
  ),
  output = "03_Resultados/Tablas/tabla_correlacional_signup_observacional.docx"
)


# -----------------------------------------------------------------------------
# Intervalos de confianza del coeficiente de sign_up
# -----------------------------------------------------------------------------

cat("\nIC 95% - Modelo simple:\n")
print(confint(modelo_log_simple)["sign_up", ])

cat("\nIC 95% - Modelo con controles:\n")
print(confint(modelo_log_controles)["sign_up", ])

cat("\nIC 95% - Modelo incluyendo log(time_spent):\n")
print(confint(modelo_log_tiempo)["sign_up", ])


# -----------------------------------------------------------------------------
# Asociacion en nivel (dolares por sesion)
# -----------------------------------------------------------------------------
#
# Los modelos de arriba estan en log(Revenue) y se leen en porcentaje. La
# presentacion al cliente reporta la brecha en dolares por sesion, asi que se
# estiman aqui las mismas especificaciones en nivel y se exportan, para que
# cada cifra citada tenga respaldo en un archivo.
#
# Igual que arriba: CORRELACIONAL, NO CAUSAL.
#
# Se incluyen dos variantes con tiempo en el sitio: con log(time_spent), que
# es la que corre en paralelo al Modelo 3, y con time_spent en nivel. La
# distincion importa porque cambia la magnitud del coeficiente, y time_spent
# es justamente el control discutible (se mide en la misma sesion).

modelos_nivel <- list(
  "Asociacion simple" = lm(Revenue ~ sign_up, data = obs),
  "Controles observables" = lm(
    Revenue ~ sign_up + past_sessions + is_returning_user +
      device_type + os_type,
    data = obs
  ),
  "Controles + log(tiempo)" = lm(
    Revenue ~ sign_up + log_time_spent + past_sessions + is_returning_user +
      device_type + os_type,
    data = obs
  ),
  "Controles + tiempo en nivel" = lm(
    Revenue ~ sign_up + time_spent + past_sessions + is_returning_user +
      device_type + os_type,
    data = obs
  )
)

# base de comparacion para expresar la brecha en porcentaje: el gasto promedio
# de los usuarios NO registrados
media_no_registrados <- mean(obs$Revenue[obs$sign_up == 0])

tabla_asociacion_nivel <- tibble(
  modelo = names(modelos_nivel),
  coef_sign_up = vapply(
    modelos_nivel, function(m) unname(coef(m)["sign_up"]), numeric(1)
  ),
  error_estandar = vapply(
    modelos_nivel,
    function(m) summary(m)$coefficients["sign_up", "Std. Error"],
    numeric(1)
  ),
  p_valor = vapply(
    modelos_nivel,
    function(m) summary(m)$coefficients["sign_up", "Pr(>|t|)"],
    numeric(1)
  ),
  r2 = vapply(modelos_nivel, function(m) summary(m)$r.squared, numeric(1)),
  n = vapply(
    modelos_nivel, function(m) length(residuals(m)), integer(1)
  )
) |>
  mutate(
    pct_sobre_media_no_registrados = 100 * coef_sign_up / media_no_registrados
  )

cat("\nGasto promedio de usuarios no registrados:",
    round(media_no_registrados, 4), "\n")
print(as.data.frame(tabla_asociacion_nivel))

write_csv(
  tabla_asociacion_nivel,
  "03_Resultados/Tablas/tabla_asociacion_signup_nivel_observacional.csv"
)


# =============================================================================
# 4. Recordatorio de interpretacion
# =============================================================================

cat("\n------------------------------------------------------------\n")
cat("INTERPRETACION\n")
cat("------------------------------------------------------------\n")
cat("Esta regresion describe una asociacion en datos historicos.\n")
cat("No identifica el efecto causal de registrarse.\n\n")
cat(
  "El experimento identifica causalmente el efecto de ofrecer ",
  "easier_signup sobre Revenue.\n"
)
cat(
  "Interpretar ese efecto exclusivamente como el efecto causal de ",
  "sign_up requiere supuestos adicionales.\n"
)
cat("------------------------------------------------------------\n")

# =============================================================================


### Elasticidad time_spent (log-log) ###

# =============================================================================
# 5. Elasticidad de Revenue respecto a time_spent (log-log)
# =============================================================================
#
# CORRELACIONAL, NO CAUSAL: igual que el resto de este script, y que
# 08_discontinuidad_tiempo_revenue_observacional.R. time_spent no esta
# aleatorizado en los datos historicos, y es plausible causalidad inversa
# (generar mas Revenue en la sesion -explorar catalogo, checkout- puede
# tomar mas tiempo mecanicamente). Ningun resultado de esta seccion debe
# leerse como "aumentar time_spent causaria mas Revenue".
#
# No se hace una version con log(sign_up): sign_up es binaria (0/1), por
# lo que log(0) no esta definido, y ademas la interpretacion de
# elasticidad ("cambio % en Revenue ante un cambio % en sign_up") no
# aplica a una variable que solo toma dos valores. Se documenta aqui para
# no repetir la pregunta.
#
# PENDIENTE DE DECISION DEL EQUIPO: si 'sign_up' deberia entrar como
# control adicional en el modelo con controles de esta seccion. Se deja
# fuera a proposito (no es una decision que le corresponda a este script
# tomar); el objetivo aqui es unicamente la elasticidad respecto a
# time_spent.
#
# 'log_revenue' y 'log_time_spent' reutilizan las mismas columnas que ya
# se crearon arriba en 'obs' (Modelo 1 y Modelo 3); no se vuelve a leer
# el .Rds ni se recalculan por separado. Se confirmo arriba (seccion 2)
# que no hay valores de Revenue ni time_spent <= 0 en esta base
# (Revenue <= 0: 0 de 100000; time_spent <= 0: 0 de 100000), asi que
# log_time_spent esta definido para todas las observaciones.

# -----------------------------------------------------------------------------
# Modelo log-log simple
# -----------------------------------------------------------------------------

modelo_loglog_simple <- lm(
  log_revenue ~ log_time_spent,
  data = obs
)

summary(modelo_loglog_simple)

# -----------------------------------------------------------------------------
# Modelo log-log con controles
# -----------------------------------------------------------------------------
# past_sessions, is_returning_user, device_type y os_type quedan en nivel
# (sin loguear): el objetivo es solo la elasticidad respecto a
# time_spent, no reinterpretar estos controles como elasticidades.

modelo_loglog_controles <- lm(
  log_revenue ~ log_time_spent +
    past_sessions +
    is_returning_user +
    device_type +
    os_type,
  data = obs
)

summary(modelo_loglog_controles)

# -----------------------------------------------------------------------------
# Reporte en consola: elasticidad, error estandar, p-valor, R^2 y N
# -----------------------------------------------------------------------------
# se reporta la especificacion sin juicio sobre si el resultado es
# "bueno" o "malo", ni entusiasmo sobre el tamano del coeficiente

reportar_elasticidad <- function(modelo, nombre) {
  s <- summary(modelo)
  fila <- s$coefficients["log_time_spent", ]

  cat("\n---", nombre, "---\n")
  cat(sprintf(
    "Un aumento de 1%% en time_spent se asocia con un cambio de %.3f%% en Revenue.\n",
    fila["Estimate"]
  ))
  cat(sprintf("Coeficiente (elasticidad) de log(time_spent): %.4f\n",
              fila["Estimate"]))
  cat(sprintf("Error estandar: %.4f\n", fila["Std. Error"]))
  cat(sprintf("P-valor: %.4g\n", fila["Pr(>|t|)"]))
  cat(sprintf("R2: %.4f\n", s$r.squared))
  cat(sprintf("N: %d\n", length(residuals(modelo))))
}

reportar_elasticidad(modelo_loglog_simple, "Modelo log-log simple")
reportar_elasticidad(modelo_loglog_controles, "Modelo log-log con controles")

# -----------------------------------------------------------------------------
# Guardar tabla de resultados
# -----------------------------------------------------------------------------
# nombre distintivo para evitar colision con tablas del experimento
# (ver auditoria de 2026-09-13 sobre nombres de archivo genericos)

tabla_elasticidad_timespent <- tibble(
  modelo = c("Log-log simple", "Log-log con controles"),
  coef_log_time_spent = c(
    coef(modelo_loglog_simple)["log_time_spent"],
    coef(modelo_loglog_controles)["log_time_spent"]
  ),
  error_estandar = c(
    summary(modelo_loglog_simple)$coefficients["log_time_spent", "Std. Error"],
    summary(modelo_loglog_controles)$coefficients["log_time_spent", "Std. Error"]
  ),
  p_valor = c(
    summary(modelo_loglog_simple)$coefficients["log_time_spent", "Pr(>|t|)"],
    summary(modelo_loglog_controles)$coefficients["log_time_spent", "Pr(>|t|)"]
  ),
  r2 = c(
    summary(modelo_loglog_simple)$r.squared,
    summary(modelo_loglog_controles)$r.squared
  ),
  n = c(
    length(residuals(modelo_loglog_simple)),
    length(residuals(modelo_loglog_controles))
  )
)

write_csv(
  tabla_elasticidad_timespent,
  "03_Resultados/Tablas/tabla_elasticidad_timespent_observacional.csv"
)

# =============================================================================
