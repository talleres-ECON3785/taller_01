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

# paleta, tema, subtitulos por base y funcion de guardado de las figuras
source("02_Scripts/00_formato_graficas.R")

set.seed(2026)

obs <- readRDS("01_Datos/03_Listos/observacional_limpio.Rds")

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

# las figuras siguen el formato compartido del proyecto (paleta, tema y
# parametros de exportacion definidos en '00_formato_graficas.R'), el mismo
# que usan las graficas del experimento. Se mantiene el mismo color por
# categoria en ambas bases (No registrado = azul, Registrado = ocre) para
# que las figuras de las dos fuentes se puedan leer una al lado de la otra

obs_fig <- obs |>
  mutate(Registro = factor(sign_up,
    levels = c(0, 1),
    labels = c("No registrado", "Registrado")
  ))

color_registro <- c(
  "No registrado" = paleta_categorica[1],
  "Registrado"    = paleta_categorica[2]
)

resumen_registro <- obs_fig |>
  group_by(Registro) |>
  summarise(
    n = n(),
    mediana_revenue = median(Revenue),
    mediana_time_spent = median(time_spent),
    .groups = "drop"
  )

# la nota de tamano de muestra es la misma para las cuatro figuras
nota_n_registro <- sprintf(
  "Nota: n = %s (No registrado), %s (Registrado).",
  format(resumen_registro$n[1], big.mark = ","),
  format(resumen_registro$n[2], big.mark = ",")
)

# se grafica la densidad (distribucion continua) y no un histograma, igual que
# en las graficas del experimento: asi las distribuciones de las dos bases se
# leen con la misma convencion. Se usan paneles (uno por grupo) en vez de
# leyenda porque las dos distribuciones superpuestas se distinguen mal.
# Ambas variables tienen cola larga a la derecha, por lo que el eje x va en
# escala logaritmica (misma decision que en el experimento); los ejes
# mantienen las unidades originales
densidad_revenue <- ggplot(
  obs_fig,
  aes(x = Revenue, fill = Registro, color = Registro)
) +
  geom_density(alpha = 0.55, linewidth = 0.8, show.legend = FALSE) +
  geom_vline(
    data = resumen_registro,
    aes(xintercept = mediana_revenue),
    inherit.aes = FALSE, linetype = "dashed",
    color = gris_secundario, linewidth = 0.6
  ) +
  scale_x_log10(breaks = c(1, 2, 5, 10, 20, 50)) +
  scale_fill_manual(values = color_registro) +
  scale_color_manual(values = color_registro) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.1))) +
  facet_wrap(vars(Registro), ncol = 1) +
  labs(
    title = "Distribucion de ingresos por estado de registro",
    subtitle = subtitulo_observacional,
    x = "Ingreso (escala log)", y = "Densidad",
    caption = paste(
      nota_n_registro,
      sprintf(
        paste(
          "La linea punteada marca la mediana de ingreso por estado de",
          "registro: No registrado %.2f, Registrado %.2f."
        ),
        resumen_registro$mediana_revenue[1],
        resumen_registro$mediana_revenue[2]
      ),
      sep = "\n"
    )
  ) +
  tema_presentacion +
  tema_paneles

guardar_figura(
  "observacional_distribucion_ingresos_signup.png",
  densidad_revenue
)

# time_spent llega hasta valores de 0.0001 minutos, casi cinco ordenes de
# magnitud por debajo de la mediana, asi que los cortes del eje cubren un
# rango mas amplio que los de la grafica de ingresos
densidad_time_spent <- ggplot(
  obs_fig,
  aes(x = time_spent, fill = Registro, color = Registro)
) +
  geom_density(alpha = 0.55, linewidth = 0.8, show.legend = FALSE) +
  geom_vline(
    data = resumen_registro,
    aes(xintercept = mediana_time_spent),
    inherit.aes = FALSE, linetype = "dashed",
    color = gris_secundario, linewidth = 0.6
  ) +
  # las etiquetas se escriben explicitas para evitar que R las muestre en
  # notacion cientifica (1e-03), que rompe la convencion del resto de figuras
  scale_x_log10(
    breaks = c(0.001, 0.01, 0.1, 1, 10, 50),
    labels = c("0.001", "0.01", "0.1", "1", "10", "50")
  ) +
  scale_fill_manual(values = color_registro) +
  scale_color_manual(values = color_registro) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.1))) +
  facet_wrap(vars(Registro), ncol = 1) +
  labs(
    title = "Distribucion del tiempo en el sitio por estado de registro",
    subtitle = subtitulo_observacional,
    x = "Tiempo en el sitio en minutos (escala log)", y = "Densidad",
    caption = paste(
      nota_n_registro,
      sprintf(
        paste(
          "La linea punteada marca la mediana de tiempo en el sitio por",
          "estado de registro: No registrado %.2f, Registrado %.2f."
        ),
        resumen_registro$mediana_time_spent[1],
        resumen_registro$mediana_time_spent[2]
      ),
      sep = "\n"
    )
  ) +
  tema_presentacion +
  tema_paneles

guardar_figura(
  "observacional_distribucion_tiempo_signup.png",
  densidad_time_spent
)

# en los boxplot las categorias ya estan en el eje x, asi que la leyenda seria
# redundante (misma convencion que las graficas del experimento)
box_revenue <- ggplot(
  obs_fig,
  aes(x = Registro, y = Revenue, fill = Registro)
) +
  geom_boxplot(width = 0.5, outlier.alpha = 0.15, show.legend = FALSE) +
  scale_fill_manual(values = color_registro) +
  labs(
    title = "Ingresos por estado de registro",
    subtitle = subtitulo_observacional,
    x = NULL, y = "Ingreso",
    caption = nota_n_registro
  ) +
  tema_presentacion

guardar_figura("observacional_ingresos_signup.png", box_revenue)

box_time_spent <- ggplot(
  obs_fig,
  aes(x = Registro, y = time_spent, fill = Registro)
) +
  geom_boxplot(width = 0.5, outlier.alpha = 0.15, show.legend = FALSE) +
  scale_fill_manual(values = color_registro) +
  labs(
    title = "Tiempo en el sitio por estado de registro",
    subtitle = subtitulo_observacional,
    x = NULL, y = "Tiempo en el sitio en minutos",
    caption = nota_n_registro
  ) +
  tema_presentacion

guardar_figura("observacional_tiempo_signup.png", box_time_spent)

cat("\nListo. Tablas guardadas en 03_Resultados/Tablas/ y figuras en 03_Resultados/Figuras/.\n")
cat("Recordatorio: las diferencias por sign_up reportadas aqui son descriptivas,\n")
cat("no estimaciones de efecto causal (no hay asignacion aleatoria en datos_historicos.Rds).\n")
