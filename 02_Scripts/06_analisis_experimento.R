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
itt_controles_nivel <- lm(
  log_revenue ~ easier_signup + log_time_spent +
    device_type + os_type + past_sessions,
  data = experimento
)

modelos_itt <- list(
  "ITT sencillo" = itt_sencillo,
  "ITT con controles" = itt_controles_nivel
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


#evaluamos comparacion de ingresos (Revenue en nivel, no transformado) entre
#grupos
#nota: la media en nivel es sensible a valores extremos; se verifica la
#mediana para no sobre-interpretar una diferencia que puede estar concentrada
#en la cola superior de la distribucion

#colores categoricos fijos del proyecto: control = azul, tratamiento = naranja
color_control <- "#2a78d6"
color_tratamiento <- "#eb6834"

experimento_grupo <- experimento |>
  mutate(Grupo = factor(easier_signup,
    levels = c(0, 1),
    labels = c("Control", "Tratamiento (registro facilitado)")
  ))

resumen_ingresos_grupo <- experimento_grupo |>
  group_by(Grupo) |>
  summarise(
    n = n(),
    media = mean(Revenue),
    mediana = median(Revenue),
    error_estandar = sd(Revenue) / sqrt(n),
    .groups = "drop"
  ) |>
  mutate(
    ci_inferior = media - qt(0.975, n - 1) * error_estandar,
    ci_superior = media + qt(0.975, n - 1) * error_estandar
  )

# tema compartido por las graficas de esta seccion, para mantener la misma
# estetica en todos los exports de la presentacion
tema_presentacion <- theme_minimal(base_size = 13) +
  theme(
    plot.title = element_text(face = "bold", size = 16, color = "#0b0b0b"),
    plot.subtitle = element_text(
      color = "#52514e", size = 11, margin = margin(b = 10)
    ),
    plot.caption = element_text(
      color = "#898781", size = 8.5, hjust = 0, margin = margin(t = 10)
    ),
    axis.text.x = element_text(size = 12, color = "#0b0b0b", face = "bold"),
    axis.text.y = element_text(color = "#52514e"),
    axis.title.y = element_text(color = "#52514e"),
    panel.grid.major.x = element_blank(),
    panel.grid.minor = element_blank(),
    panel.grid.major.y = element_line(color = "#e1e0d9", linewidth = 0.4)
  )

grafica_ingresos_grupo <- ggplot(
  resumen_ingresos_grupo,
  aes(x = Grupo, y = media, fill = Grupo)
) +
  geom_col(width = 0.5, show.legend = FALSE) +
  geom_errorbar(
    aes(ymin = ci_inferior, ymax = ci_superior),
    width = 0.12, color = "#52514e", linewidth = 0.6
  ) +
  geom_text(
    aes(y = ci_superior, label = sprintf("%.2f", media)),
    vjust = -1, color = "#0b0b0b", size = 4.5, fontface = "bold"
  ) +
  scale_fill_manual(values = c(
    "Control" = color_control,
    "Tratamiento (registro facilitado)" = color_tratamiento
  )) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.2))) +
  labs(
    title = "Ingresos promedio por grupo experimental",
    subtitle = sprintf(
      "n = %s (control), %s (tratamiento). Barras de error: intervalo de confianza al 95%%",
      format(resumen_ingresos_grupo$n[1], big.mark = ","),
      format(resumen_ingresos_grupo$n[2], big.mark = ",")
    ),
    x = NULL, y = "Ingresos promedio",
    caption = str_wrap(sprintf(
      paste(
        "Nota: la mediana de los ingresos es similar entre grupos (control:",
        "%.2f, tratamiento: %.2f); la diferencia en la media refleja valores",
        "altos en la cola superior del grupo de tratamiento."
      ),
      resumen_ingresos_grupo$mediana[1], resumen_ingresos_grupo$mediana[2]
    ), width = 95)
  ) +
  tema_presentacion

ggsave(
  "03_Resultados/Figuras/ingresos_promedio_control_tratamiento.png",
  grafica_ingresos_grupo, width = 8, height = 6, dpi = 300, bg = "white"
)

#grafica de distribucion: complementa la de medias mostrando que la mediana
#es similar entre grupos, y que la diferencia en la media viene de los
#valores altos en la cola superior de tratamiento. Se deja solo la nube de
#puntos y una raya de mediana, sin caja, para reducir elementos visuales

grafica_distribucion_ingresos <- ggplot(
  experimento_grupo,
  aes(x = Grupo, y = Revenue, color = Grupo)
) +
  geom_jitter(width = 0.15, alpha = 0.15, size = 0.9, show.legend = FALSE) +
  stat_summary(
    fun = median, geom = "errorbar",
    aes(ymin = after_stat(y), ymax = after_stat(y)),
    width = 0.4, linewidth = 1.1, show.legend = FALSE
  ) +
  geom_text(
    data = resumen_ingresos_grupo,
    aes(x = Grupo, y = mediana, label = sprintf("Mediana: %.2f", mediana)),
    nudge_x = 0.38, color = "#0b0b0b", size = 3.8, fontface = "bold",
    inherit.aes = FALSE
  ) +
  scale_color_manual(values = c(
    "Control" = color_control,
    "Tratamiento (registro facilitado)" = color_tratamiento
  )) +
  labs(
    title = "Distribucion de ingresos por grupo experimental",
    subtitle = sprintf(
      "n = %s (control), %s (tratamiento). Cada punto es una sesion; la raya marca la mediana",
      format(resumen_ingresos_grupo$n[1], big.mark = ","),
      format(resumen_ingresos_grupo$n[2], big.mark = ",")
    ),
    x = NULL, y = "Ingreso",
    caption = str_wrap(paste(
      "Nota: la mediana de ingresos es similar entre grupos; la mayor",
      "densidad de valores altos en tratamiento explica la diferencia en",
      "la media de la grafica anterior."
    ), width = 95)
  ) +
  tema_presentacion

ggsave(
  "03_Resultados/Figuras/distribucion_ingresos_control_tratamiento.png",
  grafica_distribucion_ingresos, width = 8, height = 6, dpi = 300, bg = "white"
)


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
