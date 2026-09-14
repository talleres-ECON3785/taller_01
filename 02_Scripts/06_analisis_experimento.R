# Este script busca analizar a fondo las variables relevantes al experimento,
# los resultados del experimento y producir tablas y graficas que permitan
# comunicar los hallazgos.
library(tidyverse)
library(ggplot2)
library(modelsummary)

experimento <- readRDS("01_Datos/03_Listos/experimento_listos.RDS")

experimento <- experimento |>
  mutate(log_revenue = log(Revenue)) |>
  mutate(log_time_spent = log(time_spent)) |>
  mutate(log_past_sessions = log(past_sessions))
# nota: 'past_sessions' toma el valor 0 en 519 observaciones, por lo que
# 'log_past_sessions' tiene -Inf en esos casos. 'log1p_past_sessions' evita
# ese problema; ver comparacion de alternativas mas abajo


#------------------------------------------------------
# 1. Relacion entre 'sign_up' y 'easier_signup'
#------------------------------------------------------

# evaluar ATE sobre 'sign_up'

modelo_signup_sencillo <- lm(sign_up ~ easier_signup, data = experimento)
modelsummary(modelo_signup_sencillo)
# coeficiente resultado es 1, revisamos tabla de contingencia para
# entender relacion entre variables


cont_signup_tratamiento <- experimento |>
  count(easier_signup, sign_up) |>
  pivot_wider(
    names_from = sign_up, values_from = n, names_prefix = "sign_up_",
    values_fill = 0
  )

# observamos que hay correspondencia perfecta entre 'sign_up' y 'easier_signup'
# todas los asignados al tratamiento (easier_signup=1) se registraron (sign_up = 1) # nolint: line_length_linter.
# todas las observaciones en el control (easier_signup = 0) no se registraron (sign_up = 0) # nolint: line_length_linter.

# version con etiquetas legibles y totales, para exportar como tabla de reporte
cont_signup_tratamiento_export <- cont_signup_tratamiento |>
  mutate(easier_signup = factor(easier_signup,
    levels = c(0, 1),
    labels = c("Control", "Tratamiento (registro facilitado)")
  )) |>
  rename(
    Grupo = easier_signup,
    "No registrado" = sign_up_0,
    "Registrado" = sign_up_1
  ) |>
  mutate(Grupo = as.character(Grupo), Total = `No registrado` + Registrado)

fila_total <- cont_signup_tratamiento_export |>
  summarise(across(where(is.numeric), sum)) |>
  mutate(Grupo = "Total", .before = 1)

cont_signup_tratamiento_export <- bind_rows(cont_signup_tratamiento_export,
                                            fila_total)

write_csv(
  cont_signup_tratamiento_export,
  "03_Resultados/Tablas/tabla_contingencia_signup_easier_signup.csv"
)


#------------------------------------------------------
# 2. Relacion entre 'Revenue' y 'easier_signup'
#------------------------------------------------------

# estimamos ITT sencillo entre variables

itt_sencillo <- lm(log_revenue ~ easier_signup, data = experimento)
modelsummary(itt_sencillo)

#estimamos ITT con controles
# nota: este modelo corre sobre 'log_revenue', igual que 'itt_sencillo'. Antes
# se llamaba 'itt_controles_nivel', nombre que sugeria erroneamente que la
# variable dependiente estaba en nivel; el ITT en nivel se estima en la
# seccion 2b
itt_controles_log <- lm(
  log_revenue ~ easier_signup + log_time_spent +
    device_type + os_type + past_sessions,
  data = experimento
)

modelos_itt <- list(
  "ITT sencillo" = itt_sencillo,
  "ITT con controles" = itt_controles_log
)

# etiquetas en espanol para reportar; el nivel de referencia de cada
# variable categorica se deja explicito en la etiqueta
etiquetas_itt <- c(
  "easier_signup"     = "Registro facilitado (tratamiento)",
  "log_time_spent"    = "Log(tiempo en el sitio)",
  "device_typemobile" = "Dispositivo: movil (ref. desktop)",
  "device_typetablet" = "Dispositivo: tablet (ref. desktop)",
  "os_typeother"      = "Sistema operativo: otro (ref. osx)",
  "os_typewindows"    = "Sistema operativo: windows (ref. osx)",
  "past_sessions"     = "Sesiones anteriores",
  "(Intercept)"       = "Intercepto"
)

# se muestra en pantalla para revisar antes de exportar
modelsummary(
  modelos_itt,
  coef_map = etiquetas_itt,
  gof_map = c("nobs", "r.squared"),
  stars = c("*" = 0.1, "**" = 0.05, "***" = 0.01),
  title = "Efecto del registro facilitado sobre log(Revenue) (ITT)"
)

# version lista para la presentacion (sin codigo, con etiquetas y formato)
modelsummary(
  modelos_itt,
  coef_map = etiquetas_itt,
  gof_map = c("nobs", "r.squared"),
  stars = c("*" = 0.1, "**" = 0.05, "***" = 0.01),
  title = "Efecto del registro facilitado sobre log(Revenue) (ITT)",
  output = "03_Resultados/Tablas/tabla_itt_experimento.docx"
)


#------------------------------------------------------
# 2b. ITT sobre 'Revenue' en nivel y forma de la distribucion
#------------------------------------------------------

# el ITT en logaritmo (seccion anterior) responde "en que porcentaje cambia el
# ingreso"; el ITT en nivel responde "en cuantos dolares por sesion cambia".
# Se reportan los dos porque no coinciden en significancia, y esa discrepancia
# es en si misma un resultado: el nivel esta dominado por la cola alta de
# 'Revenue' y el logaritmo es mas robusto a esos valores extremos.
# Ambas especificaciones son regresion lineal; solo cambia la transformacion
# de la variable dependiente.

itt_nivel_sencillo <- lm(Revenue ~ easier_signup, data = experimento)

itt_nivel_controles <- lm(
  Revenue ~ easier_signup + log_time_spent +
    device_type + os_type + past_sessions,
  data = experimento
)

modelos_itt_nivel <- list(
  "ITT nivel sencillo" = itt_nivel_sencillo,
  "ITT nivel con controles" = itt_nivel_controles
)

# se exporta el coeficiente de 'easier_signup' de cada especificacion para que
# el numero que se cita en la presentacion tenga respaldo en un archivo
tabla_itt_nivel <- tibble(
  modelo = names(modelos_itt_nivel),
  coef_easier_signup = c(
    coef(itt_nivel_sencillo)["easier_signup"],
    coef(itt_nivel_controles)["easier_signup"]
  ),
  error_estandar = c(
    summary(itt_nivel_sencillo)$coefficients["easier_signup", "Std. Error"],
    summary(itt_nivel_controles)$coefficients["easier_signup", "Std. Error"]
  ),
  p_valor = c(
    summary(itt_nivel_sencillo)$coefficients["easier_signup", "Pr(>|t|)"],
    summary(itt_nivel_controles)$coefficients["easier_signup", "Pr(>|t|)"]
  ),
  ic_inferior = c(
    confint(itt_nivel_sencillo)["easier_signup", 1],
    confint(itt_nivel_controles)["easier_signup", 1]
  ),
  ic_superior = c(
    confint(itt_nivel_sencillo)["easier_signup", 2],
    confint(itt_nivel_controles)["easier_signup", 2]
  ),
  r2 = c(
    summary(itt_nivel_sencillo)$r.squared,
    summary(itt_nivel_controles)$r.squared
  ),
  n = c(
    length(residuals(itt_nivel_sencillo)),
    length(residuals(itt_nivel_controles))
  )
)

write_csv(
  tabla_itt_nivel,
  "03_Resultados/Tablas/tabla_itt_nivel_experimento.csv"
)

# el promedio y la mediana de 'Revenue' cuentan historias distintas entre
# grupos, asi que se exportan juntos con los percentiles altos: es la evidencia
# de que la diferencia en nivel se concentra en la cola y no en el usuario
# tipico
descriptivas_revenue_grupo <- experimento |>
  group_by(easier_signup) |>
  summarise(
    n = n(),
    media = mean(Revenue),
    mediana = median(Revenue),
    desv_estandar = sd(Revenue),
    p90 = unname(quantile(Revenue, 0.90)),
    p99 = unname(quantile(Revenue, 0.99)),
    maximo = max(Revenue),
    .groups = "drop"
  ) |>
  mutate(
    grupo = if_else(
      easier_signup == 1, "Tratamiento (registro facilitado)", "Control"
    ),
    .before = 1
  ) |>
  select(-easier_signup)

write_csv(
  descriptivas_revenue_grupo,
  "03_Resultados/Tablas/descriptivas_revenue_por_grupo_experimento.csv"
)


# las graficas de ingresos por grupo (promedio y distribucion) se movieron a
# '07_graficas_experimento.R' para mantener este script enfocado en modelos
# y tablas


#------------------------------------------------------
# 3. Analisis adicionales
#------------------------------------------------------

#evaluamos si easier_signup afecta al tiempo en sesion
#si hay efecto, itt_sencillo tiene sesgo de variable omitida

modelsummary(lm(log_time_spent ~ easier_signup, data = experimento),
  stars = c("*" = 0.1, "**" = 0.05, "***" = 0.01)
)

#el coeficiente es positivo (via contraria a lo que esperariamos), y no es
#estadisticamente significativo. Se descarta hipotesis de itt_sencillo con svo
#para tiempo en sesion


#evaluamos si tiene sentido estimar LATE via IV (2SLS), usando easier_signup
#como instrumento de sign_up. El estimador de Wald es:
#LATE = (ITT sobre Revenue) / (ITT sobre sign_up, primer estadio)

primer_estadio <- lm(sign_up ~ easier_signup, data = experimento)
modelsummary(primer_estadio,
  stars = c("*" = 0.1, "**" = 0.05, "***" = 0.01)
)

#el coeficiente del primer estadio es exactamente 1 (cumplimiento perfecto,
#ver tabla de contingencia de la seccion 1: todo asignado a easier_signup=1
#se registra, y todo asignado a easier_signup=0 no se registra). Por lo tanto
#LATE = ITT / 1 = ITT: el mismo coeficiente, error estandar y significancia
#que ya tenemos en itt_sencillo. IV no aporta informacion adicional con esta
#base y se descarta profundizar en esta linea.
