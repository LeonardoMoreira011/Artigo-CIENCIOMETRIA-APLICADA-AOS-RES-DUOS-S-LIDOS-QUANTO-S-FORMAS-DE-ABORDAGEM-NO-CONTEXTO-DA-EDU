# Cinabro — a chart laboratory for scientific figures in R

*A punctis ad curvam: ubi data colorem accipiunt.* (From the points to the curve: where data take on color.)

Cinabro turns a CSV file into publication-ready figures (PNG, TIFF, JPEG, SVG, PDF, EMF) with fine control of axes, ticks, frame, colors, legends, panels, a second Y axis and axis breaks. It has two faces that share the same engine:

- **The app** (in the browser, no code): open it, load a CSV and adjust everything with clicks.
- **The script** (`painel_de_ajustes.R` / `graficos_R_completo.R`): the same settings as plain variables, for repeatable work.

> This file is a short guide. The complete reference (every setting, with examples) is `LEIAME.md`, which is written in Portuguese. Comments inside `01_config.R` and `painel_de_ajustes.R` are also in Portuguese.

## Languages
The app speaks **Português (BR)**, **English** and **Español**. Pick the language in the selector at the top right (it reloads the page and remembers your choice), or open `http://cinabro.localhost:8421/?idioma=en` (`es`, `pt`). In scripts, use `idioma <- "en"` in the adjustments panel (it affects messages and the automatic texts inside the chart). Messages written by the engine are translated by a dictionary; a message that is not in the dictionary appears in Portuguese.

## Running the app
1. Install R (https://cran.r-project.org). RStudio is optional.
2. Extract the **whole** ZIP into a folder (do not run files from inside the ZIP).
3. Windows: double-click `abrir_app.bat` (first run installs the packages and needs internet). To get a desktop shortcut without a console window, double-click `Criar_atalho_na_area_de_trabalho.bat` once.
4. Other systems, or inside R: `shiny::runApp("app_shiny")` from the project folder.

The page opens at `http://cinabro.localhost:8421`. The R process closes a few seconds after you close the browser tab.

## What you can do
- **Chart types:** line, line with points, scatter, area, stacked area, bars, pie/donut, histogram, density, cumulative distribution, boxplot.
- **Axes:** start/end, tick spacing, minor ticks, first tick, manual ticks, log and other scales, number format, rotation, a divide-by factor, titles with exponents and subscripts (`m^{2}`, `CO_{2}`).
- **Right Y axis (Y2):** same options as the left axis, with its own scale, color and intervals.
- **Axis break:** two styles (separate or continuous frame), per-part tick spacing and minor ticks, a button that finds the largest gap in your data.
- **Colors:** 65 ready palettes (see below), your own palette (paste color codes, edit the swatches, save it with a name), color/shape/size per series.
- **Legend:** inside or outside, vertical or horizontal, columns and rows, drag it on the preview, background, border, shadow, exact width.
- **Plot box:** fixed size (like a plot area), so every figure has the same box; the page adjusts to fit numbers, titles and legend.
- **Export:** choose one or more file types; transparent background; resolution; save/load settings (JSON); "equivalent code" for the script.

## New layout: the chart comes first
An icon rail on the left opens one panel at a time (no more list of 14 blocks); *Maximize* gives the whole screen to the chart, which is drawn at the stage width. A strip above the chart turns on a curve fit, mean ± SD, a statistics box, text, shapes or a picture with one click. Click the title or an axis name right on the chart to edit its text, bold and size. Dragging statistics boxes, shapes and pictures with the mouse is not available yet.

## New visual identity
Colors `#B3262E` (cinnabar red), `#F5EBDD` (cream: page background; white only inside the chart box), `#20242B` (ink), `#C96A4A` (terracotta), `#2F6670` (teal). The emblem was vectorized (`identidade/emblema.svg`) and is used in the app header, tab icon and Windows shortcut. A chart palette `identidade` has the same colors.

## Fits, statistics, shapes, frozen blocks and tabs (third round)

- **Block 13 — Fits and statistics:** curve fits (linear, exponential, power, logarithmic, polynomial, loess, **free formula** such as `a*exp(-b*x) + c`; only math functions are accepted), each with color, line type (solid/dashed...), thickness and an optional confidence band; **mean/median lines with SD, SE, 95% CI or min–max bands** (or per-X error bars) with color, thickness and line type; free **statistics boxes** (like the legend) with n, mean, median, SD, SE, sum, R², equation, p-values, Pearson/Spearman/Kendall, Shapiro-Wilk, t test, Wilcoxon, ANOVA, Kruskal-Wallis, Tukey, Bartlett..., with background, rounded or square border, shadow and position. Everything uses base R (`lm`, `nls`, `loess`, `aov`...). In scripts: `estatisticas(dados, cfg)`.
- **Attached pictures** (block 14, "Picture" cards): an upload field for a PNG or JPEG (logo, diagram, photo) placed on the chart, with position/size in plot-box fractions or axis units, aspect ratio kept, anchor point, opacity, rotation, outline and layer. Needs the `png` and `jpeg` packages. Pictures live only in the app session (not in copied/saved settings).
- **Block 14 — Text boxes and polygons:** text box, rectangle, rounded rectangle, ellipse, triangle, diamond, hexagon, star and free polygon, with border color/width/type, fill, shadow, rotation, and position in plot-box fractions or axis units.
- **Freeze** (tick in each block header): frozen blocks survive *Restore all*, pasted settings and carry over to new tabs. **Copy settings / Paste settings...** move all settings between charts or computers.
- **Tabs:** one chart per tab (own data and settings); *+ New tab* (keeps only frozen blocks), *Duplicate*, *Rename*, close; *Show another tab alongside* draws a second chart under the preview. You edit one chart at a time; switching tabs saves and restores everything.
- The `marca` palette was reordered so the first four colors are the most distinct (also for color-blind viewers).

## Palettes and licenses
Figures, texts, shapes, statistics boxes and the legend move with the mouse: drag to move, pull the red square in the corner to resize, click to edit. A curve fit or Mean ± SD gets its own statistics box (equation, R², mean, SD), separate from the line. *External curve* (Curve fit menu): draw a curve you already have (pasted X,Y points, or a formula with ready parameter values) over the data without fitting anything.

Only palettes from freely licensed work are included — no palettes named after programs, brands or journals. 12 palettes: the original `cinabro` (default; the brand colors and variations of them), six gradients (Brewer Reds, Purples, YlGnBu, YlOrRd; cmocean algae; Crameri oslo), two diverging (Brewer `brewer_RdYlGn`, dark red to green, and Spectral) and three continuous (magma, inferno, turbo from viridisLite). Names of removed palettes still work: the closest remaining one is used, with a warning. Credits and license notices are in `NOTICE.md`. The font is Barlow (SIL Open Font License; `fontes/Barlow/OFL.txt`).

## Tests
`Rscript 06_testes.R` (engine) and `Rscript app_shiny/testes_app.R` (app). Tested on Linux with ggplot2 3.5.2 and 4.0.3; **not tested on Windows** — run `07_verificar_windows.R` once.
