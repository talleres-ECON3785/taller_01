#este script lee los datos del experimento, descargados de BN
#y realiza limpieza y verificaciones para asegurar que esta listo para
#utilizarse en analisis. Guarda el resultado en 03_Listos.

require(tidyverse)


data_experimento <- readRDS("01_Datos/01_Crudos/datos_experimento.Rds")


str(data_experimento)

#variables 'device_type' y 'os_type' categoricas ya son factor
#variables binarias 'easier_signup', 'is_returning_user' y 'sign_up' se
#representan con 0 y 1, no es necesario cambiarlas.
#'time_spent', 'past_sessions' y 'easier_signup' son numericas continuas
#' Time spent en minutos
#' Ingresos en dolares



#limpiamos posibles na
data_experimento_limpio <- drop_na(data_experimento)

nrow(data_experimento)
nrow(data_experimento_limpio)

#no se borraron observaciones por na, n=10000 para ambas bases.

#revisamos que las variables se comporten como se espera

#tiempo mayor a 0
summary(data_experimento_limpio$time_spent)
#min es 0.000259, se comporta bien

#revenue mayor o igual a 0

summary(data_experimento_limpio$Revenue)
#min es 0.6649, se comporta bien

#past_sessions mayor o igual a 0
summary(data_experimento_limpio$past_sessions)
#min es 0, se comporta bien

#Binarias realmente solo son 1 o 0

summary(data_experimento_limpio$is_returning_user)
summary(data_experimento_limpio$sign_up)
summary(data_experimento_limpio$easier_signup)

unique(data_experimento_limpio$is_returning_user)
unique(data_experimento_limpio$sign_up)
unique(data_experimento_limpio$easier_signup)

#todas las binarias solo tienen como valores presentes 1 o 0

#Revisar que las categoricas tengan las categorias establecidas

unique(data_experimento_limpio$os_type)
unique(data_experimento_limpio$device_type)

#ambas variables tienen como valores los establecidos por la guia
#todas las variables concuerdan con las descripciones y chequeos

#guardamos base como lista

saveRDS(data_experimento_limpio, "01_Datos/03_Listos/experimento_listos.RDS")
