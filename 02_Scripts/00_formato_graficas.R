# =============================================================================
# Formato compartido de las graficas del proyecto
# Taller 1 - ECON-3785
#
# Este script NO genera figuras: solo define la paleta, el tema y los
# parametros de exportacion que deben usar TODAS las graficas del taller.
# Se creo para que el formato deje de estar copiado en cada script (y por
# lo tanto no se pueda desincronizar entre ellos).
#
# Uso: al inicio de cualquier script que produzca figuras,
#   source("02_Scripts/00_formato_graficas.R")
# y despues construir cada grafica con `tema_presentacion` (mas
# `tema_paneles` si usa facetas) y guardarla con `guardar_figura()`.
#
# El formato de referencia es el que quedo en '07_graficas_experimento.R'.
# =============================================================================

library(ggplot2)

# -----------------------------------------------------------------------------
# 1. Paleta categorica
# -----------------------------------------------------------------------------

# paleta categorica sobria del proyecto: tonos desaturados de azul, ocre y
# verde-azulado, validados para diferenciarse entre si (incluyendo daltonismo)
# a pesar del bajo croma. Se reutiliza la misma terna en todas las graficas
# del proyecto para mantener una identidad visual unica y consistente
paleta_categorica <- c(
  "#2B5FA3", # azul
  "#B8863B", # ocre
  "#0E8A6C"  # verde-azulado
)

# grises de apoyo: texto principal, texto secundario / lineas de referencia,
# notas al pie y lineas de la grilla. No son categorias, son estructura
gris_texto      <- "#0b0b0b"
gris_secundario <- "#52514e"
gris_nota       <- "#898781"
gris_grilla     <- "#e1e0d9"

# -----------------------------------------------------------------------------
# 2. Subtitulos por base de datos
# -----------------------------------------------------------------------------

# cada grafica declara en su subtitulo de que base viene, porque las dos
# bases no permiten afirmar lo mismo: el experimento identifica un efecto
# causal y los datos historicos solo describen asociaciones
subtitulo_experimento <- "Datos del experimento A/B (asignacion aleatoria)."
subtitulo_observacional <- paste(
  "Datos historicos (sin asignacion aleatoria):",
  "las diferencias son descriptivas, no causales."
)

# -----------------------------------------------------------------------------
# 3. Tema
# -----------------------------------------------------------------------------

# tema compartido por todas las graficas del proyecto, para mantener la misma
# estetica en todos los exports de la presentacion
tema_presentacion <- theme_minimal(base_size = 13) +
  theme(
    plot.title = element_text(face = "bold", size = 16, color = gris_texto),
    plot.subtitle = element_text(
      color = gris_secundario, size = 11, margin = margin(b = 10)
    ),
    plot.caption = element_text(
      color = gris_nota, size = 8.5, hjust = 0, margin = margin(t = 10)
    ),
    axis.text.x = element_text(size = 12, color = gris_texto, face = "bold"),
    axis.text.y = element_text(color = gris_secundario),
    axis.title.y = element_text(color = gris_secundario),
    panel.grid.major.x = element_blank(),
    panel.grid.minor = element_blank(),
    panel.grid.major.y = element_line(color = gris_grilla, linewidth = 0.4)
  )

# complemento para las graficas con facetas: el titulo de cada panel hace de
# etiqueta de la categoria, asi que va en negrita y sin caja de fondo
tema_paneles <- theme(
  strip.background = element_blank(),
  strip.text = element_text(face = "bold", size = 12, color = gris_texto)
)

# -----------------------------------------------------------------------------
# 4. Exportacion
# -----------------------------------------------------------------------------

# todas las figuras se exportan con el mismo tamano y resolucion para que se
# vean homogeneas al insertarlas en la presentacion. El fondo blanco es
# explicito porque ggplot lo deja transparente por defecto y eso se ve mal
# sobre el fondo de una diapositiva.
# Convencion de nombres: 03_Resultados/Figuras/<base>_<contenido>.png, donde
# <base> es 'experimento' u 'observacional', para saber de un vistazo que
# base sostiene cada figura.
guardar_figura <- function(nombre_archivo, grafica,
                           width = 8, height = 6, dpi = 300) {
  ggsave(
    file.path("03_Resultados/Figuras", nombre_archivo),
    grafica,
    width = width, height = height, dpi = dpi, bg = "white"
  )
}
