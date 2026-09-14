# =============================================================================
# Busqueda formal de un punto de quiebre en la relacion time_spent -> Revenue
# BASE DEL EXPERIMENTO (experimento_listos.RDS)
# Taller 1 - ECON-3785
#
# ADVERTENCIA DE INTERPRETACION (identica a la de
# 08_discontinuidad_tiempo_revenue_observacional.R, se repite a proposito):
# La relacion entre time_spent y Revenue es CORRELACIONAL, no causal, en
# NINGUNA de las dos bases del taller. Que estos datos vengan del
# experimento NO hace causal esta relacion en particular: lo unico
# aleatorizado en experimento_listos.RDS es easier_signup; time_spent NO
# fue asignado aleatoriamente. Es plausible causalidad inversa: generar mas
# Revenue en la sesion (explorar catalogo, pasar por checkout) puede
# mecanicamente tomar mas tiempo. Ningun resultado de este script debe
# leerse como "aumentar time_spent causaria mas Revenue".
#
# Este script formaliza y reemplaza, con busqueda de b y validacion fuera de
# muestra, la exploracion ad hoc de '07_graficas_experimento.R' (que fijaba
# el quiebre visualmente en 5 minutos sin buscarlo ni validarlo). La figura
# resultante se guarda con un nombre distinto
# ('experimento_relacion_tiempo_revenue_quiebre.png') para no sobrescribir
# la figura original de '07_graficas_experimento.R'.
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

experimento <- readRDS("01_Datos/03_Listos/experimento_listos.RDS")

# -----------------------------------------------------------------------------
# 1. Particion entrenamiento (70%) / prueba (30%)
# -----------------------------------------------------------------------------

n_exp <- nrow(experimento)
idx_train <- sample(seq_len(n_exp), size = floor(0.7 * n_exp))
train <- experimento[idx_train, ]
test <- experimento[-idx_train, ]

cat("n entrenamiento:", nrow(train), "| n prueba:", nrow(test), "\n")

# -----------------------------------------------------------------------------
# 2. Busqueda del punto de quiebre b, SOLO en entrenamiento
# -----------------------------------------------------------------------------

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

write_csv(busqueda_b, "03_Resultados/Tablas/experimento_busqueda_b_rss.csv")

grafico_rss <- ggplot(busqueda_b, aes(x = b, y = rss)) +
  geom_line(color = "#2B5FA3") +
  geom_point(size = 1, color = "#2B5FA3") +
  geom_vline(xintercept = b_encontrado, linetype = "dashed", color = "#B8863B") +
  labs(
    title = "Busqueda del punto de quiebre en time_spent (base del experimento)",
    subtitle = paste(
      "RSS del modelo segmentado en ENTRENAMIENTO para cada candidato b.",
      "Relacion correlacional, no causal (time_spent no esta aleatorizado)."
    ),
    x = "Candidato a punto de quiebre b (minutos)",
    y = "Suma de cuadrados residual (RSS) en entrenamiento"
  ) +
  theme_minimal()

ggsave("03_Resultados/Figuras/experimento_rss_vs_b_quiebre.png",
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
          "03_Resultados/Tablas/experimento_quiebre_train_test.csv")

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
          "03_Resultados/Tablas/experimento_comparacion_r2_quiebre.csv")

# -----------------------------------------------------------------------------
# 6. Tabla resumen (para la comparacion conjunta con observacional, abajo)
# -----------------------------------------------------------------------------

resumen_quiebre <- tibble(
  base = "experimento",
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

write_csv(resumen_quiebre, "03_Resultados/Tablas/experimento_resumen_quiebre.csv")

# -----------------------------------------------------------------------------
# 7. Grafica descriptiva de dispersion por bins, marcando b_encontrado
# -----------------------------------------------------------------------------
# grafica puramente descriptiva (usa toda la base lista, no solo
# entrenamiento). Se guarda con nombre distinto al de
# '07_graficas_experimento.R' (que uso b=5 fijado a ojo) para no sobrescribir
# esa figura sin autorizacion del equipo.

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
      subtitulo_experimento,
      format(round(nrow(experimento) / n_bins_scatter)), n_bins_scatter
    ), width = 90),
    x = "Tiempo en el sitio (minutos, escala log)",
    y = "Ingreso promedio del grupo (escala log)",
    caption = sprintf(
      "Nota: la linea punteada marca un tiempo en el sitio de %s minutos.",
      b_encontrado
    )
  ) +
  tema_presentacion

guardar_figura("experimento_relacion_tiempo_revenue_quiebre.png", grafica_tiempo_revenue)

cat("\n=== ADVERTENCIA FINAL ===\n")
cat("La relacion time_spent - Revenue en la base del experimento es",
    "CORRELACIONAL, no causal, exactamente igual que en observacional: solo",
    "easier_signup esta aleatorizado, time_spent no. Es plausible",
    "causalidad inversa (generar mas Revenue en la sesion puede tomar mas",
    "tiempo mecanicamente). No se debe concluir que 'aumentar time_spent'",
    "causaria mas Revenue.\n")

# =============================================================================
# 8. COMPARACION EXPLICITA: observacional vs. experimento
# =============================================================================
# requiere que 08_discontinuidad_tiempo_revenue_observacional.R ya se haya
# corrido (su resumen se lee de disco). Si no existe, se reporta el problema
# en vez de fallar en silencio.

cat("\n============================================================\n")
cat("COMPARACION: punto de quiebre en observacional vs. experimento\n")
cat("============================================================\n")

ruta_resumen_obs <- "03_Resultados/Tablas/observacional_resumen_quiebre.csv"

if (!file.exists(ruta_resumen_obs)) {
  cat("No se encontro", ruta_resumen_obs, "- corra primero",
      "08_discontinuidad_tiempo_revenue_observacional.R antes de esta",
      "seccion para poder comparar.\n")
} else {
  resumen_obs <- read_csv(ruta_resumen_obs, show_col_types = FALSE)
  comparacion <- bind_rows(resumen_obs, resumen_quiebre)

  cat("\nb encontrado por base:\n")
  print(comparacion |> select(base, b_encontrado, quiebre_confirmado))

  diferencia_b <- abs(resumen_obs$b_encontrado - resumen_quiebre$b_encontrado)
  cat(sprintf("\nDiferencia entre los b encontrados: %.1f minutos\n",
              diferencia_b))

  ambas_confirman <- resumen_obs$quiebre_confirmado && resumen_quiebre$quiebre_confirmado
  ninguna_confirma <- !resumen_obs$quiebre_confirmado && !resumen_quiebre$quiebre_confirmado

  if (ambas_confirman) {
    cat("\nEl quiebre SOBREVIVE la validacion fuera de muestra en AMBAS",
        "bases. Si ademas los valores de b son similares (ver arriba), esto",
        "es evidencia de una caracteristica estructural del comportamiento",
        "de usuario -EN TERMINOS CORRELACIONALES, no causales: en ninguna",
        "de las dos bases time_spent esta aleatorizado, y sigue siendo",
        "plausible causalidad inversa (mas Revenue generado puede tomar",
        "mas tiempo mecanicamente) en ambas.\n")
  } else if (ninguna_confirma) {
    cat("\nEl quiebre NO sobrevive la validacion fuera de muestra en NINGUNA",
        "de las dos bases. Este es un hallazgo valido en si mismo: no se",
        "encuentra evidencia robusta de una discontinuidad en la relacion",
        "time_spent-Revenue; se reporta como tal, no se descarta en",
        "silencio.\n")
  } else {
    base_confirma <- if (resumen_obs$quiebre_confirmado) "observacional" else "experimento"
    base_no_confirma <- if (resumen_obs$quiebre_confirmado) "experimento" else "observacional"
    cat(sprintf(
      paste0(
        "\nEl quiebre sobrevive la validacion fuera de muestra SOLO en la",
        " base %s, no en %s. No se puede concluir que sea una",
        " caracteristica estructural compartida; queda como hallazgo",
        " especifico de una base, pendiente de mas evidencia.\n"
      ),
      base_confirma, base_no_confirma
    ))
  }

  write_csv(comparacion,
            "03_Resultados/Tablas/comparacion_quiebre_observacional_experimento.csv")
}

cat("\nListo. Tablas en 03_Resultados/Tablas/experimento_*quiebre*.csv y",
    "comparacion_quiebre_observacional_experimento.csv; figuras en",
    "03_Resultados/Figuras/experimento_*quiebre*.png\n")
