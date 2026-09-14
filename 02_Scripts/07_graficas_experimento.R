#Este script busca generar graficas relevantes para el analisis.
#de los resultados del experimento.
#Originalmente las graficas se generaban en '06_analisis_experimento.R' pero
#para mantener una organizacion clara dada la cantidad de graficos se decide
#migrar la responsabilidad a este script

library(tidyverse)
library(ggplot2)

# paleta, tema, subtitulos por base y funcion de guardado: el formato de las
# figuras vive en un solo lugar para que no se desincronice entre scripts
source("02_Scripts/00_formato_graficas.R")

experimento <- readRDS("01_Datos/03_Listos/experimento_listos.RDS")

# todas las graficas de este script usan la base del experimento (prueba
# A/B con asignacion aleatoria a easier_signup); se deja explicito en el
# subtitulo de cada grafica (subtitulo_experimento) para no confundirlas con
# la base observacional


#------------------------------------------------------
# 1. Ingresos por grupo experimental (control vs. tratamiento)
#------------------------------------------------------

#evaluamos comparacion de ingresos (Revenue en nivel, no transformado) entre
#grupos
#nota: la media en nivel es sensible a valores extremos; se verifica la
#mediana para no sobre-interpretar una diferencia que puede estar concentrada
#en la cola superior de la distribucion

color_control <- paleta_categorica[1]
color_tratamiento <- paleta_categorica[2]

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

grafica_ingresos_grupo <- ggplot(
  resumen_ingresos_grupo,
  aes(x = Grupo, y = media, fill = Grupo)
) +
  geom_col(width = 0.5, show.legend = FALSE) +
  geom_errorbar(
    aes(ymin = ci_inferior, ymax = ci_superior),
    width = 0.12, color = gris_secundario, linewidth = 0.6
  ) +
  geom_text(
    aes(y = ci_superior, label = sprintf("%.2f", media)),
    vjust = -1, color = gris_texto, size = 4.5, fontface = "bold"
  ) +
  scale_fill_manual(values = c(
    "Control" = color_control,
    "Tratamiento (registro facilitado)" = color_tratamiento
  )) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.2))) +
  labs(
    title = "Ingresos promedio por grupo experimental",
    subtitle = str_wrap(sprintf(
      "%s n = %s (control), %s (tratamiento). Barras de error: intervalo de confianza al 95%%",
      subtitulo_experimento,
      format(resumen_ingresos_grupo$n[1], big.mark = ","),
      format(resumen_ingresos_grupo$n[2], big.mark = ",")
    ), width = 80),
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

guardar_figura(
  "experimento_ingresos_promedio_control_tratamiento.png",
  grafica_ingresos_grupo
)

#grafica de distribucion: complementa la de medias mostrando que la mediana
#es similar entre grupos, y que la diferencia en la media viene de los
#valores altos en la cola superior de tratamiento. Misma logica de densidad
#por panel que el resto de graficas de este script

nota_n_grupo <- sprintf(
  "Nota: n = %s (Control), %s (Tratamiento).",
  format(resumen_ingresos_grupo$n[1], big.mark = ","),
  format(resumen_ingresos_grupo$n[2], big.mark = ",")
)
nota_medianas_grupo <- sprintf(
  paste(
    "La linea punteada marca la mediana de ingreso por grupo:",
    "Control %.2f, Tratamiento %.2f."
  ),
  resumen_ingresos_grupo$mediana[1],
  resumen_ingresos_grupo$mediana[2]
)

grafica_distribucion_ingresos <- ggplot(
  experimento_grupo,
  aes(x = Revenue, fill = Grupo, color = Grupo)
) +
  geom_density(alpha = 0.55, linewidth = 0.8, show.legend = FALSE) +
  geom_vline(
    data = resumen_ingresos_grupo,
    aes(xintercept = mediana),
    inherit.aes = FALSE, linetype = "dashed",
    color = gris_secundario, linewidth = 0.6
  ) +
  scale_x_log10(breaks = c(1, 2, 5, 10, 20, 50)) +
  scale_fill_manual(values = c(
    "Control" = color_control,
    "Tratamiento (registro facilitado)" = color_tratamiento
  )) +
  scale_color_manual(values = c(
    "Control" = color_control,
    "Tratamiento (registro facilitado)" = color_tratamiento
  )) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.1))) +
  facet_wrap(vars(Grupo), ncol = 1) +
  labs(
    title = "Distribucion de ingresos por grupo experimental",
    subtitle = subtitulo_experimento,
    x = "Ingreso (escala log)", y = "Densidad",
    caption = paste(nota_n_grupo, nota_medianas_grupo, sep = "\n")
  ) +
  tema_presentacion +
  tema_paneles

guardar_figura(
  "experimento_distribucion_ingresos_control_tratamiento.png",
  grafica_distribucion_ingresos
)


#------------------------------------------------------
# 2. Distribucion de ingresos por tipo de dispositivo
#------------------------------------------------------

# graficamos la densidad de Revenue por device_type para contrastar sus
# distribuciones. Revenue tiene cola larga a la derecha, por lo que se usa
# escala logaritmica en el eje x para distinguir mejor la forma de cada
# distribucion; los ejes mantienen las unidades originales. Se separan las
# distribuciones en paneles (una por dispositivo) porque se sobreponen
# demasiado para distinguirlas en un solo panel

color_device <- c(
  "Escritorio" = paleta_categorica[1],
  "Movil"      = paleta_categorica[2],
  "Tablet"     = paleta_categorica[3]
)

experimento_device <- experimento |>
  mutate(Dispositivo = factor(device_type,
    levels = c("desktop", "tablet", "mobile"),
    labels = c("Escritorio", "Tablet", "Movil")
  ))

resumen_ingresos_device <- experimento_device |>
  group_by(Dispositivo) |>
  summarise(n = n(), mediana = median(Revenue), .groups = "drop")

# nota en dos lineas explicitas (en vez de un unico parrafo con str_wrap)
# para que la oracion de medianas no se corte a la mitad de su informacion
nota_n_device <- sprintf(
  "Nota: n = %s (Escritorio), %s (Tablet), %s (Movil).",
  format(resumen_ingresos_device$n[1], big.mark = ","),
  format(resumen_ingresos_device$n[2], big.mark = ","),
  format(resumen_ingresos_device$n[3], big.mark = ",")
)
nota_medianas_device <- sprintf(
  paste(
    "La linea punteada marca la mediana de ingreso por dispositivo:",
    "Escritorio %.2f, Tablet %.2f, Movil %.2f."
  ),
  resumen_ingresos_device$mediana[1],
  resumen_ingresos_device$mediana[2],
  resumen_ingresos_device$mediana[3]
)

grafica_densidad_revenue_device <- ggplot(
  experimento_device,
  aes(x = Revenue, fill = Dispositivo, color = Dispositivo)
) +
  geom_density(alpha = 0.55, linewidth = 0.8, show.legend = FALSE) +
  geom_vline(
    data = resumen_ingresos_device,
    aes(xintercept = mediana),
    inherit.aes = FALSE, linetype = "dashed",
    color = gris_secundario, linewidth = 0.6
  ) +
  scale_x_log10(breaks = c(1, 2, 5, 10, 20, 50)) +
  scale_fill_manual(values = color_device) +
  scale_color_manual(values = color_device) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.1))) +
  facet_wrap(vars(Dispositivo), ncol = 1) +
  labs(
    title = "Distribucion de ingresos por tipo de dispositivo",
    subtitle = subtitulo_experimento,
    x = "Ingreso (escala log)", y = "Densidad",
    caption = paste(nota_n_device, nota_medianas_device, sep = "\n")
  ) +
  tema_presentacion +
  tema_paneles

guardar_figura(
  "experimento_distribucion_ingresos_device_type.png",
  grafica_densidad_revenue_device
)


#------------------------------------------------------
# 3. Distribucion de ingresos por sistema operativo
#------------------------------------------------------

# misma logica que la seccion anterior, pero contrastando por os_type

color_os <- c(
  "OSX"     = paleta_categorica[1],
  "Otro"    = paleta_categorica[2],
  "Windows" = paleta_categorica[3]
)

experimento_os <- experimento |>
  mutate(SistemaOperativo = factor(os_type,
    levels = c("osx", "windows", "other"),
    labels = c("OSX", "Windows", "Otro")
  ))

resumen_ingresos_os <- experimento_os |>
  group_by(SistemaOperativo) |>
  summarise(n = n(), mediana = median(Revenue), .groups = "drop")

nota_n_os <- sprintf(
  "Nota: n = %s (OSX), %s (Windows), %s (Otro).",
  format(resumen_ingresos_os$n[1], big.mark = ","),
  format(resumen_ingresos_os$n[2], big.mark = ","),
  format(resumen_ingresos_os$n[3], big.mark = ",")
)
nota_medianas_os <- sprintf(
  paste(
    "La linea punteada marca la mediana de ingreso por sistema operativo:",
    "OSX %.2f, Windows %.2f, Otro %.2f."
  ),
  resumen_ingresos_os$mediana[1],
  resumen_ingresos_os$mediana[2],
  resumen_ingresos_os$mediana[3]
)

grafica_densidad_revenue_os <- ggplot(
  experimento_os,
  aes(x = Revenue, fill = SistemaOperativo, color = SistemaOperativo)
) +
  geom_density(alpha = 0.55, linewidth = 0.8, show.legend = FALSE) +
  geom_vline(
    data = resumen_ingresos_os,
    aes(xintercept = mediana),
    inherit.aes = FALSE, linetype = "dashed",
    color = gris_secundario, linewidth = 0.6
  ) +
  scale_x_log10(breaks = c(1, 2, 5, 10, 20, 50)) +
  scale_fill_manual(values = color_os) +
  scale_color_manual(values = color_os) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.1))) +
  facet_wrap(vars(SistemaOperativo), ncol = 1) +
  labs(
    title = "Distribucion de ingresos por sistema operativo",
    subtitle = subtitulo_experimento,
    x = "Ingreso (escala log)", y = "Densidad",
    caption = paste(nota_n_os, nota_medianas_os, sep = "\n")
  ) +
  tema_presentacion +
  tema_paneles

guardar_figura(
  "experimento_distribucion_ingresos_os_type.png",
  grafica_densidad_revenue_os
)


#------------------------------------------------------
# 4. Distribucion de ingresos por estado de registro (sign_up)
#------------------------------------------------------

# misma logica que las secciones anteriores, pero contrastando por sign_up
# (usuario registrado vs. no registrado)

color_signup <- c(
  "No registrado" = paleta_categorica[1],
  "Registrado"    = paleta_categorica[2]
)

experimento_signup <- experimento |>
  mutate(Registro = factor(sign_up,
    levels = c(0, 1),
    labels = c("No registrado", "Registrado")
  ))

resumen_ingresos_signup <- experimento_signup |>
  group_by(Registro) |>
  summarise(n = n(), mediana = median(Revenue), .groups = "drop")

nota_n_signup <- sprintf(
  "Nota: n = %s (No registrado), %s (Registrado).",
  format(resumen_ingresos_signup$n[1], big.mark = ","),
  format(resumen_ingresos_signup$n[2], big.mark = ",")
)
nota_medianas_signup <- sprintf(
  paste(
    "La linea punteada marca la mediana de ingreso por estado de registro:",
    "No registrado %.2f, Registrado %.2f."
  ),
  resumen_ingresos_signup$mediana[1],
  resumen_ingresos_signup$mediana[2]
)

grafica_densidad_revenue_signup <- ggplot(
  experimento_signup,
  aes(x = Revenue, fill = Registro, color = Registro)
) +
  geom_density(alpha = 0.55, linewidth = 0.8, show.legend = FALSE) +
  geom_vline(
    data = resumen_ingresos_signup,
    aes(xintercept = mediana),
    inherit.aes = FALSE, linetype = "dashed",
    color = gris_secundario, linewidth = 0.6
  ) +
  scale_x_log10(breaks = c(1, 2, 5, 10, 20, 50)) +
  scale_fill_manual(values = color_signup) +
  scale_color_manual(values = color_signup) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.1))) +
  facet_wrap(vars(Registro), ncol = 1) +
  labs(
    title = "Distribucion de ingresos por estado de registro",
    subtitle = subtitulo_experimento,
    x = "Ingreso (escala log)", y = "Densidad",
    caption = paste(nota_n_signup, nota_medianas_signup, sep = "\n")
  ) +
  tema_presentacion +
  tema_paneles

guardar_figura(
  "experimento_distribucion_ingresos_signup.png",
  grafica_densidad_revenue_signup
)


#------------------------------------------------------
# 5. Relacion entre tiempo en el sitio e ingresos (binned scatter)
#------------------------------------------------------

# un scatter crudo con n = 10,000 se satura de puntos y no es legible. Se
# usa un "binned scatter": se agrupan las sesiones en grupos de tamano
# similar segun su time_spent (percentiles) y se grafica el promedio de
# Revenue de cada grupo. Se usan mas bins que en un binned scatter tipico
# para mostrar mejor la granularidad de la relacion. Sin recta de ajuste:
# el objetivo es solo visualizar la forma de la relacion. Se marca con una
# linea vertical el punto (time_spent = 5) donde se observa una discontinuidad

n_bins_scatter <- 50

bins_tiempo_revenue <- experimento |>
  mutate(bin = ntile(time_spent, n_bins_scatter)) |>
  group_by(bin) |>
  summarise(
    n = n(),
    time_spent_medio = mean(time_spent),
    revenue_medio = mean(Revenue),
    .groups = "drop"
  )

umbral_discontinuidad <- 5

grafica_tiempo_revenue <- ggplot(
  bins_tiempo_revenue,
  aes(x = time_spent_medio, y = revenue_medio)
) +
  geom_vline(
    xintercept = umbral_discontinuidad,
    linetype = "dashed", color = gris_secundario, linewidth = 0.6
  ) +
  geom_point(color = paleta_categorica[1], size = 2.2) +
  scale_x_log10() +
  scale_y_log10() +
  labs(
    title = "Relacion entre tiempo en el sitio e ingresos",
    subtitle = str_wrap(sprintf(
      paste(
        "%s Cada punto es el promedio de ~%s sesiones (%s grupos de",
        "tamano similar segun tiempo en el sitio)."
      ),
      subtitulo_experimento,
      format(round(nrow(experimento) / n_bins_scatter)),
      n_bins_scatter
    ), width = 90),
    x = "Tiempo en el sitio en minutos (escala log)",
    y = "Ingreso promedio del grupo (escala log)",
    caption = str_wrap(sprintf(
      paste(
        "Nota: la linea punteada marca un tiempo en el sitio de %s minutos,",
        "donde se observa una discontinuidad en el ingreso promedio de los",
        "grupos."
      ),
      umbral_discontinuidad
    ), width = 95)
  ) +
  tema_presentacion

guardar_figura(
  "experimento_relacion_tiempo_revenue.png",
  grafica_tiempo_revenue
)


