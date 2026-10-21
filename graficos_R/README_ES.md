# Cinabro — un laboratorio de gráficos científicos en R

*A punctis ad curvam: ubi data colorem accipiunt.* (De los puntos a la curva: donde los datos cobran color.)

Cinabro convierte un archivo CSV en figuras listas para publicar (PNG, TIFF, JPEG, SVG, PDF, EMF) con control fino de ejes, marcas, marco, colores, leyendas, paneles, un segundo eje Y e interrupciones de eje. Tiene dos caras que comparten el mismo motor:

- **La aplicación** (en el navegador, sin código): ábrela, carga un CSV y ajusta todo con clics.
- **El script** (`painel_de_ajustes.R` / `graficos_R_completo.R`): los mismos ajustes como variables simples, para trabajo repetible.

> Esta es una guía corta. La referencia completa (cada ajuste, con ejemplos) es `LEIAME.md`, escrita en portugués. Los comentarios dentro de `01_config.R` y `painel_de_ajustes.R` también están en portugués.

## Idiomas
La aplicación habla **Português (BR)**, **English** y **Español**. Elige el idioma en el selector de arriba a la derecha (recarga la página y recuerda tu elección), o abre `http://cinabro.localhost:8421/?idioma=es` (`en`, `pt`). En los scripts usa `idioma <- "es"` en el panel de ajustes (afecta los mensajes y los textos automáticos dentro del gráfico). Los mensajes del motor se traducen con un diccionario; un mensaje que no esté en el diccionario aparece en portugués.

## Cómo abrir la aplicación
1. Instala R (https://cran.r-project.org). RStudio es opcional.
2. Extrae el ZIP **completo** en una carpeta (no ejecutes archivos desde dentro del ZIP).
3. Windows: haz doble clic en `abrir_app.bat` (la primera vez instala los paquetes y necesita internet). Para tener un acceso directo en el escritorio sin ventana de consola, haz doble clic una vez en `Criar_atalho_na_area_de_trabalho.bat`.
4. Otros sistemas, o dentro de R: `shiny::runApp("app_shiny")` desde la carpeta del proyecto.

La página se abre en `http://cinabro.localhost:8421`. El proceso de R se cierra unos segundos después de cerrar la pestaña del navegador.

## Qué puedes hacer
- **Tipos de gráfico:** líneas, líneas con puntos, dispersión, áreas, áreas apiladas, barras, circular/anillo, histograma, densidad, distribución acumulada, diagrama de cajas.
- **Ejes:** inicio/fin, separación de marcas, marcas secundarias, primera marca, marcas manuales, escalas logarítmicas y otras, formato de los números, rotación, factor de división, títulos con exponentes y subíndices (`m^{2}`, `CO_{2}`).
- **Eje Y derecho (Y2):** las mismas opciones que el eje izquierdo, con escala, color e intervalos propios.
- **Interrupción del eje:** dos estilos (marcos separados o marco continuo), separación de marcas y marcas secundarias por tramo, y un botón que encuentra el mayor hueco en tus datos.
- **Colores:** 64 paletas listas (ver abajo), tu propia paleta (pega códigos de color, edita las muestras, guárdala con un nombre), color/forma/tamaño por serie.
- **Leyenda:** dentro o fuera, vertical u horizontal, columnas y filas, se arrastra sobre la vista previa, fondo, borde, sombra, ancho exacto.
- **Área del gráfico:** de tamaño fijo, de modo que todas las figuras tengan la misma área; la página se ajusta para que quepan números, títulos y leyenda.
- **Exportación:** elige uno o más tipos de archivo; fondo transparente; resolución; guardar/cargar configuración (JSON); "código equivalente" para el script.

## Paletas y licencias
Solo se incluyen paletas de trabajos con licencia libre — ninguna con nombre de programa, marca o revista: la original `cinabro` (por defecto) y `marca`, Okabe-Ito, Paul Tol, Brewer (cualitativas, secuenciales, divergentes; incluye `brewer_RdYlGn`, de rojo oscuro a verde), la familia viridis, cmocean y los mapas de color científicos de Crameri. Los créditos y avisos de licencia están en `NOTICE.md`. La fuente es Barlow (SIL Open Font License; `fontes/Barlow/OFL.txt`).

## Pruebas
`Rscript 06_testes.R` (motor) y `Rscript app_shiny/testes_app.R` (aplicación). Probado en Linux con ggplot2 3.5.2 y 4.0.3; **no probado en Windows**: ejecuta una vez `07_verificar_windows.R`.
