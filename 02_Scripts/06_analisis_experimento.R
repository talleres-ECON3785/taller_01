#Este script busca analizar a fondo las variables relevantes al experimento,
#los resultados del experimento y producir tablas y graficas que permitan
#comunicar los hallazgos.
library(tidyverse)
library(ggplot2)

experimento <- readRDS("01_Datos/03_Listos/experimento_listos.RDS")

experimento <- experimento |>
  mutate(log_revenue = log(Revenue)) |>
  mutate(log_time_spent = log(time_spent)) |>
  mutate(log_past_sessions = log(past_sessions))
