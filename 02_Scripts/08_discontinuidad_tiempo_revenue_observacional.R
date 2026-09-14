# =============================================================================
# Busqueda formal de un punto de quiebre en la relacion time_spent -> Revenue
# BASE OBSERVACIONAL (observacional_limpio.Rds)
# Taller 1 - ECON-3785
#
# ADVERTENCIA DE INTERPRETACION (aplica igual en la base del experimento,
# ver 09_discontinuidad_tiempo_revenue_experimento.R):
# La relacion entre time_spent y Revenue es CORRELACIONAL, no causal, en
# NINGUNA de las dos bases del taller. En observacional no hay asignacion
# aleatoria de nada. Es plausible causalidad inversa: generar mas Revenue
# en la sesion (explorar catalogo, pasar por checkout) puede mecanicamente
# tomar mas tiempo. Ningun resultado de este script debe leerse como
# "aumentar time_spent causaria mas Revenue".
#
# REGLA METODOLOGICA: solo regresion lineal. El posible quiebre se modela
# con una interaccion de time_spent con un indicador de umbral dentro de
# lm() (regresion segmentada lineal por partes), sin usar el paquete
# 'segmented' ni ningun metodo no lineal.
#
# Un quiebre que no sobrevive la validacion fuera de muestra se reporta
# como "NO CONFIRMADO", no se descarta en silencio.
# =============================================================================

library(tidyverse)
source("02_Scripts/00_formato_graficas.R")

set.seed(2026)

obs <- readRDS("01_Datos/02_Procesados/observacional_limpio.Rds")

# -----------------------------------------------------------------------------
# 1. Particion entrenamiento (70%) / prueba (30%)
# -----------------------------------------------------------------------------

n_obs <- nrow(obs)
idx_train <- sample(seq_len(n_obs), size = floor(0.7 * n_obs))
train <- obs[idx_train, ]
test <- obs[-idx_train, ]

cat("n entrenamiento:", nrow(train), "| n prueba:", nrow(test), "\n")

# -----------------------------------------------------------------------------
# 2. Busqueda del punto de quiebre b, SOLO en entrenamiento
# -----------------------------------------------------------------------------

# grilla de candidatos cada 0.5 minutos entre el percentil 5 y el percentil 95
# de time_spent en entrenamiento, para evitar candidatos con pocas
# observaciones a alguno de los dos lados
p5_train <- quantile(train$time_spent, 0.05)
p95_train <- quantile(train$time_spent, 0.95)
grilla_b <- seq(
  from = ceiling(p5_train / 0.5) * 0.5,
  to = floor(p95_train / 0.5) * 0.5,
  by = 0.5
)

calcular_rss <- function(b, datos) {
  modelo <- lm(Revenue ~ time_spent * I(time_spent > b), data = datos)
  sum(residuals(modelo)^2)
}

rss_por_b <- map_dbl(grilla_b, calcular_rss, datos = train)
busqueda_b <- tibble(b = grilla_b, rss = rss_por_b)

b_encontrado <- busqueda_b$b[which.min(busqueda_b$rss)]

cat("\nPunto de quiebre encontrado (minimiza RSS en entrenamiento):",
    b_encontrado, "minutos\n")

write_csv(busqueda_b, "03_Resultados/Tablas/observacional_busqueda_b_rss.csv")

grafico_rss <- ggplot(busqueda_b, aes(x = b, y = rss)) +
  geom_line(color = "#2B5FA3") +
  geom_point(size = 1, color = "#2B5FA3") +
  geom_vline(xintercept = b_encontrado, linetype = "dashed", color = "#B8863B") +
  labs(
    title = "Busqueda del punto de quiebre en time_spent (base observacional)",
    subtitle = paste(
      "RSS del modelo segmentado en ENTRENAMIENTO para cada candidato b.",
      "Relacion correlacional, no causal."
    ),
    x = "Candidato a punto de quiebre b (minutos)",
    y = "Suma de cuadrados residual (RSS) en entrenamiento"
  ) +
  theme_minimal()

ggsave("03_Resultados/Figuras/observacional_rss_vs_b_quiebre.png",
       grafico_rss, width = 8, height = 5, dpi = 300, bg = "white")

# -----------------------------------------------------------------------------
# 3. Modelo segmentado final en ENTRENAMIENTO, con b fijo en b_encontrado
# -----------------------------------------------------------------------------

modelo_segmentado_train <- lm(
  Revenue ~ time_spent * I(time_spent > b_encontrado),
  data = train
)

cat("\n--- Modelo segmentado en ENTRENAMIENTO (b =", b_encontrado, ") ---\n")
print(summary(modelo_segmentado_train)$coefficients)

# -----------------------------------------------------------------------------
# 4. VALIDACION FUERA DE MUESTRA: mismo b fijo, reajustado en PRUEBA
# -----------------------------------------------------------------------------
# el punto de quiebre NO se vuelve a buscar aqui: se usa el mismo b_encontrado
# de entrenamiento. Esto es lo que permite distinguir un quiebre real de un
# sobreajuste de haber probado muchos candidatos en entrenamiento.

modelo_segmentado_test <- lm(
  Revenue ~ time_spent * I(time_spent > b_encontrado),
  data = test
)

cat("\n--- Modelo segmentado en PRUEBA (mismo b, no se volvio a buscar) ---\n")
print(summary(modelo_segmentado_test)$coefficients)

extraer_fila <- function(modelo, patron) {
  coefs <- summary(modelo)$coefficients
  fila <- coefs[grepl(patron, rownames(coefs)), , drop = FALSE]
  if (nrow(fila) == 0) return(c(estimate = NA_real_, p_value = NA_real_))
  c(estimate = fila[1, "Estimate"], p_value = fila[1, "Pr(>|t|)"])
}

patron_salto <- "^I\\(time_spent > b_encontrado\\)TRUE$"
patron_pendiente <- "^time_spent:I\\(time_spent > b_encontrado\\)TRUE$"

salto_train <- extraer_fila(modelo_segmentado_train, patron_salto)
pendiente_train <- extraer_fila(modelo_segmentado_train, patron_pendiente)
salto_test <- extraer_fila(modelo_segmentado_test, patron_salto)
pendiente_test <- extraer_fila(modelo_segmentado_test, patron_pendiente)

tabla_quiebre_train_test <- tibble(
  parametro = c("Salto de nivel en b", "Cambio de pendiente en b"),
  coef_entrenamiento = c(salto_train["estimate"], pendiente_train["estimate"]),
  p_entrenamiento = c(salto_train["p_value"], pendiente_train["p_value"]),
  coef_prueba = c(salto_test["estimate"], pendiente_test["estimate"]),
  p_prueba = c(salto_test["p_value"], pendiente_test["p_value"])
)

cat("\n--- Resumen del quiebre: entrenamiento vs. prueba ---\n")
print(tabla_quiebre_train_test)

write_csv(tabla_quiebre_train_test,
          "03_Resultados/Tablas/observacional_quiebre_train_test.csv")

# criterio explicito (no implica que el equipo deba adoptarlo sin revisar los
# numeros de arriba): se considera que un coeficiente "sobrevive" si es
# significativo (p < 0.05) en AMBOS conjuntos y con el mismo signo
umbral_p <- 0.05
sobrevive <- function(fila_train, fila_test) {
  !is.na(fila_train["p_value"]) && !is.na(fila_test["p_value"]) &&
    fila_train["p_value"] < umbral_p && fila_test["p_value"] < umbral_p &&
    sign(fila_train["estimate"]) == sign(fila_test["estimate"])
}

salto_sobrevive <- sobrevive(salto_train, salto_test)
pendiente_sobrevive <- sobrevive(pendiente_train, pendiente_test)
quiebre_confirmado <- salto_sobrevive || pendiente_sobrevive

if (quiebre_confirmado) {
  cat("\nEl quiebre encontrado en entrenamiento SE MANTIENE en prueba",
      "(p <", umbral_p, "en ambos conjuntos, mismo signo) para al menos uno",
      "de los dos coeficientes (salto y/o cambio de pendiente).\n")
} else if (salto_train["p_value"] < umbral_p || pendiente_train["p_value"] < umbral_p) {
  cat("\nEl quiebre era significativo en ENTRENAMIENTO pero no se replica en",
      "PRUEBA bajo el criterio usado: se reporta como discontinuidad NO",
      "CONFIRMADA (no se descarta en silencio; ver los p-valores exactos",
      "arriba para juicio propio del equipo).\n")
} else {
  cat("\nEl quiebre no fue significativo ni siquiera en entrenamiento:",
      "discontinuidad NO CONFIRMADA.\n")
}

# -----------------------------------------------------------------------------
# 5. Comparacion de R^2: modelo segmentado vs. modelo lineal simple
# -----------------------------------------------------------------------------

modelo_simple_train <- lm(Revenue ~ time_spent, data = train)
modelo_simple_test <- lm(Revenue ~ time_spent, data = test)

comparacion_r2 <- tibble(
  conjunto = c("Entrenamiento", "Entrenamiento", "Prueba", "Prueba"),
  modelo = c(
    "Simple (sin quiebre)", "Segmentado (con quiebre)",
    "Simple (sin quiebre)", "Segmentado (con quiebre)"
  ),
  r2 = c(
    summary(modelo_simple_train)$r.squared,
    summary(modelo_segmentado_train)$r.squared,
    summary(modelo_simple_test)$r.squared,
    summary(modelo_segmentado_test)$r.squared
  )
)

cat("\n--- Comparacion de R^2: simple vs. segmentado, por conjunto ---\n")
print(comparacion_r2)

write_csv(comparacion_r2,
          "03_Resultados/Tablas/observacional_comparacion_r2_quiebre.csv")

# -----------------------------------------------------------------------------
# 6. Tabla resumen (para lectura conjunta con el experimento en el script 09)
# -----------------------------------------------------------------------------

resumen_quiebre <- tibble(
  base = "observacional",
  b_encontrado = b_encontrado,
  salto_coef_train = salto_train["estimate"],
  salto_p_train = salto_train["p_value"],
  salto_coef_test = salto_test["estimate"],
  salto_p_test = salto_test["p_value"],
  pendiente_coef_train = pendiente_train["estimate"],
  pendiente_p_train = pendiente_train["p_value"],
  pendiente_coef_test = pendiente_test["estimate"],
  pendiente_p_test = pendiente_test["p_value"],
  r2_simple_train = summary(modelo_simple_train)$r.squared,
  r2_segmentado_train = summary(modelo_segmentado_train)$r.squared,
  r2_simple_test = summary(modelo_simple_test)$r.squared,
  r2_segmentado_test = summary(modelo_segmentado_test)$r.squared,
  quiebre_confirmado = quiebre_confirmado
)

write_csv(resumen_quiebre, "03_Resultados/Tablas/observacional_resumen_quiebre.csv")

# -----------------------------------------------------------------------------
# 7. Grafica descriptiva de dispersion por bins, marcando b_encontrado
# -----------------------------------------------------------------------------
# grafica puramente descriptiva (usa toda la base limpia, no solo
# entrenamiento): el objetivo es visualizar la forma de la relacion, no
# estimar nada aqui. La significancia del quiebre ya se evaluo arriba con
# la particion entrenamiento/prueba.

n_bins_scatter <- 50

bins_tiempo_revenue <- obs |>
  mutate(bin = ntile(time_spent, n_bins_scatter)) |>
  group_by(bin) |>
  summarise(
    n = n(),
    time_spent_medio = mean(time_spent),
    revenue_medio = mean(Revenue),
    .groups = "drop"
  )

grafica_tiempo_revenue <- ggplot(
  bins_tiempo_revenue,
  aes(x = time_spent_medio, y = revenue_medio)
) +
  geom_vline(
    xintercept = b_encontrado,
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
      subtitulo_observacional,
      format(round(nrow(obs) / n_bins_scatter)), n_bins_scatter
    ), width = 90),
    x = "Tiempo en el sitio (minutos, escala log)",
    y = "Ingreso promedio del grupo (escala log)",
    caption = sprintf(
      "Nota: la linea punteada marca un tiempo en el sitio de %s minutos.",
      b_encontrado
    )
  ) +
  tema_presentacion

guardar_figura("observacional_relacion_tiempo_revenue.png", grafica_tiempo_revenue)

cat("\n=== ADVERTENCIA FINAL ===\n")
cat("La relacion time_spent - Revenue en la base observacional es",
    "CORRELACIONAL, no causal. Es plausible causalidad inversa (generar mas",
    "Revenue en la sesion puede tomar mas tiempo mecanicamente). No se debe",
    "concluir que 'aumentar time_spent' causaria mas Revenue.\n")

cat("\nListo. Tablas en 03_Resultados/Tablas/observacional_*quiebre*.csv y",
    "figuras en 03_Resultados/Figuras/observacional_*quiebre*.png /",
    "observacional_relacion_tiempo_revenue.png\n")
