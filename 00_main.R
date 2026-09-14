# =============================================================================
# Script maestro: ejecuta todo el pipeline del Taller 1 en una sola corrida
# Taller 1 - ECON-3785
#
# Corre los scripts de 02_Scripts/ en el orden de su numeracion (01 a 12).
# Cada script asume que el directorio de trabajo es la raiz del proyecto
# (donde vive taller1.Rproj), por eso este script verifica esa raiz antes
# de sourcear nada y no cambia el working directory de cada script.
# =============================================================================

# -----------------------------------------------------------------------------
# 1. Verificar que el directorio de trabajo es la raiz del proyecto
# -----------------------------------------------------------------------------

if (!file.exists("taller1.Rproj")) {
  stop(
    "Este script debe ejecutarse con el directorio de trabajo en la raiz ",
    "del proyecto (donde esta taller1.Rproj). Directorio actual: ", getwd()
  )
}

# -----------------------------------------------------------------------------
# 2. Orden de ejecucion de los scripts (segun su numeracion)
# -----------------------------------------------------------------------------

scripts <- c(
  "02_Scripts/01_limpieza_observacional.R",
  "02_Scripts/02_descriptivas_observacional.R",
  "02_Scripts/03_procesar_datos_experimento.R",
  "02_Scripts/04_descriptivas_experimento.R",
  "02_Scripts/05_balance_experimento.R",
  "02_Scripts/06_analisis_experimento.R",
  "02_Scripts/07_graficas_experimento.R",
  "02_Scripts/08_discontinuidad_tiempo_revenue_observacional.R",
  "02_Scripts/09_discontinuidad_tiempo_revenue_experimento.R",
  "02_Scripts/10_regresion_correlacional_observacional.R",
  "02_Scripts/11_prediccion_revenue_observacional.R",
  "02_Scripts/12_representatividad_experimento_vs_historico.R"
)

# nota: '00_formato_graficas.R' no aparece en esta lista porque no produce
# resultados por si mismo; solo define el formato de las figuras y lo cargan
# con source() los scripts que las generan

# -----------------------------------------------------------------------------
# 3. Ejecutar cada script en su propio entorno, en orden
# -----------------------------------------------------------------------------

for (script in scripts) {
  mensaje <- paste0("Ejecutando: ", script)
  message(strrep("=", nchar(mensaje)))
  message(mensaje)
  message(strrep("=", nchar(mensaje)))

  source(script, local = new.env(), encoding = "UTF-8")
}

message("Pipeline completo: los 12 scripts se ejecutaron sin errores.")
