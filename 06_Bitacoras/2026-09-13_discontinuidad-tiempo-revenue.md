# Bitácora — 2026-09-13: Búsqueda formal del quiebre time_spent-Revenue

## Qué se hizo

- Se formalizó y replicó, con metodología idéntica en ambas bases, la
  exploración ad hoc de la relación `time_spent`-`Revenue` que hasta ahora
  solo existía como gráfica de `07_graficas_experimento.R` (quiebre fijado
  visualmente en 5 minutos, sin buscarlo ni validarlo fuera de muestra).
- `02_Scripts/08_discontinuidad_tiempo_revenue_observacional.R` (parte de
  `observacional_limpio.Rds`) y
  `02_Scripts/09_discontinuidad_tiempo_revenue_experimento.R` (parte de
  `experimento_listos.RDS`), con la misma metodología en los dos:
  - Partición 70/30 entrenamiento/prueba (`set.seed(2026)`).
  - Búsqueda del punto de quiebre `b` SOLO en entrenamiento: rejilla cada
    0.5 minutos entre percentil 5 y 95 de `time_spent`, ajustando
    `Revenue ~ time_spent * I(time_spent > b)` (regresión segmentada
    lineal por partes, construida a mano con `lm()`, sin el paquete
    `segmented`) para cada candidato y quedándose con el que minimiza la
    RSS. Se exporta la curva RSS vs. `b` como tabla y figura.
  - Modelo segmentado final en entrenamiento con el `b` encontrado, y
    validación fuera de muestra: el mismo `b` (fijo, no se vuelve a
    buscar) se usa para reajustar el mismo modelo en prueba. Se reporta el
    coeficiente de salto de nivel y de cambio de pendiente, con su
    significancia, en ambos conjuntos.
  - Comparación de R² entre el modelo segmentado y uno lineal simple
    (`Revenue ~ time_spent`), en entrenamiento y en prueba.
  - Gráfica de dispersión por bins (50 grupos por percentil de
    `time_spent`, escala log-log) marcando el `b` encontrado con línea
    punteada.
  - Criterio explícito de "sobrevive": significativo (p<0.05) en ambos
    conjuntos y mismo signo. Si no se cumple, se imprime explícitamente
    "NO CONFIRMADO" (nunca se descarta en silencio).
- `09_...experimento.R` termina leyendo el resumen de
  `08_...observacional.R` (`observacional_resumen_quiebre.csv`) y
  construye la comparación explícita entre bases pedida por el usuario,
  guardada en
  `03_Resultados/Tablas/comparacion_quiebre_observacional_experimento.csv`.
- Se agregó en ambos scripts (comentarios, mensajes impresos y
  título/subtítulo/pie de las figuras) la advertencia de interpretación
  pedida explícitamente: la relación `time_spent`-`Revenue` es
  correlacional, no causal, en LAS DOS bases (en el experimento solo
  `easier_signup` está aleatorizado, `time_spent` no), y es plausible
  causalidad inversa (generar más `Revenue` puede tomar más tiempo
  mecánicamente). Ninguna salida del script sugiere que aumentar
  `time_spent` causaría más `Revenue`.
- La figura nueva del experimento se guardó como
  `experimento_relacion_tiempo_revenue_quiebre.png` (nombre distinto al de
  `experimento_relacion_tiempo_revenue.png`, que sigue produciendo
  `07_graficas_experimento.R`), para no sobrescribir sin autorización una
  figura de un compañero.
- Se corrieron ambos scripts de principio a fin sin errores antes de
  proponer el commit.

## Por qué

- El usuario pidió reemplazar el quiebre "a ojo" (4/5/6 minutos probados
  informalmente) por una búsqueda formal sobre una rejilla, con validación
  fuera de muestra que distinga un patrón real de un sobreajuste de haber
  probado muchos candidatos `b` en el mismo conjunto donde se buscan.
- Correr la misma metodología en ambas bases permite responder si el
  patrón es una característica estructural del comportamiento de usuario
  (si aparece con `b` similar y sobrevive en ambas) o no hay evidencia
  robusta (si no sobrevive en ninguna).

## Qué se descubrió

- El punto de quiebre encontrado es **b = 5 minutos en ambas bases**
  (idéntico), coincidiendo con lo que el equipo había fijado a ojo.
- El salto de nivel en `b` es grande y significativo en entrenamiento y en
  prueba, en ambas bases:
  - Observacional: 3.13 (entrenamiento, p≈0) vs. 3.19 (prueba, p≈0).
  - Experimento: 3.42 (entrenamiento, p≈2e-85) vs. 3.50 (prueba,
    p≈2e-44).
  - El cambio de pendiente no es significativo en ninguna de las dos
    bases, ni en entrenamiento ni en prueba.
- El quiebre se clasifica como **CONFIRMADO** (sobrevive la validación
  fuera de muestra) en ambas bases, por el salto de nivel.
- El modelo segmentado mejora el R² de forma sustancial y consistente
  entrenamiento→prueba en ambas bases (observacional: 0.170→0.294 en
  entrenamiento, 0.163→0.290 en prueba; experimento: 0.129→0.211 en
  entrenamiento, 0.127→0.224 en prueba), sin caída notable al pasar a
  prueba.
- Conclusión reportada (correlacional, no causal): hay evidencia robusta
  de una discontinuidad en `b≈5` minutos en la relación `time_spent`-
  `Revenue`, consistente entre las dos bases. No se puede ni se intenta
  interpretar como que aumentar `time_spent` causaría más `Revenue` (ver
  advertencia de causalidad inversa en ambos scripts).

## Problemas / pendientes

- Ningún error de ejecución en ninguno de los dos scripts.
- Queda pendiente decidir si el equipo quiere retirar la figura ad hoc de
  `07_graficas_experimento.R` (`experimento_relacion_tiempo_revenue.png`,
  con `b=5` fijado a ojo) a favor de la nueva versión validada
  (`experimento_relacion_tiempo_revenue_quiebre.png`), o mantener ambas.
- Al cerrar esta sesión seguían sin trackear (no generados ni tocados en
  esta sesión): `01_Datos/02_Procesados/observacional_limpio_BACKUP.Rds`,
  `03_Resultados/Tablas/~$descriptivas_experimento.xlsx` (archivo de
  bloqueo de Excel) y
  `06_Bitacoras/2026-09-13_auditoria-pipeline-experimento.md` (de la
  sesión de auditoría anterior). No se incluyeron en los commits de esta
  sesión por no corresponder a esta tarea.
