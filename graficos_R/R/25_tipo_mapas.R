# =============================================================================
#  R/25_tipo_mapas.R — mapa de calor (eixo Z em gradiente), mapa-múndi e mapa do Brasil
# =============================================================================
#  Os contornos ficam na pasta mapas/ (GeoJSON do Natural Earth + tabelas CSV editáveis). Precisam do pacote sf.
#  A cor vem de cfg$mapa_calor (esquema_cor, cores_escala, limites, centro...), igual nos três tipos.
# =============================================================================

# ---- escala de cor do eixo Z -------------------------------------------------------------------
.ESQUEMAS_Z <- list(
  cinabro    = c("#F4ECDD", "#E8B49A", "#CF6F4E", "#B3262E", "#7E1B22"),
  petroleo   = c("#F4ECDD", "#BFD9DB", "#6FA5AC", "#2F6670", "#13343A"),
  divergente = c("#2F6670", "#8FC3CC", "#F4ECDD", "#E9A58A", "#B3262E"))

# Cores do gradiente. Entra: cfg. Sai: vetor de cores (do menor para o maior valor).
.cores_z <- function(cfg) {
  H <- cfg$mapa_calor
  cores <- if (!is.null(H$cores_escala)) vapply(H$cores_escala, .cor, "", "cfg$mapa_calor$cores_escala")
    else if (H$esquema_cor %in% names(.ESQUEMAS_Z)) .ESQUEMAS_Z[[H$esquema_cor]]
    else if (.tem("viridisLite")) viridisLite::viridis(7, option = switch(H$esquema_cor, viridis = "D", magma = "A", inferno = "B", turbo = "H"))
    else { .aviso("O esquema \"", H$esquema_cor, "\" precisa do pacote viridisLite; usando \"cinabro\"."); .ESQUEMAS_Z$cinabro }
  if (isTRUE(H$inverter_cores)) rev(cores) else cores
}

# Escala contínua de preenchimento (com barra de cores). Entra: cfg e os valores Z. Sai: list(escala, limites, cor_de).
.escala_z <- function(cfg, z, nome) {
  H <- cfg$mapa_calor; z <- z[is.finite(z)]
  if (!length(z)) .erro("Não há valores numéricos para colorir.")
  lim <- c(H$limite_min %||% min(z), H$limite_max %||% max(z))
  if (lim[1] == lim[2]) lim <- lim + c(-0.5, 0.5)
  cores <- .cores_z(cfg)
  meio <- H$centro %||% (if (identical(H$esquema_cor, "divergente") && is.null(H$cores_escala)) 0 else NULL)
  if (!is.null(meio) && (meio <= lim[1] || meio >= lim[2])) {
    .aviso("O centro (", meio, ") está fora dos limites (", lim[1], " a ", lim[2], "); ele será ignorado.")
    meio <- NULL
  }
  resc <- if (is.null(meio)) scales::rescale else function(x, to = c(0, 1), from = range(x, na.rm = TRUE)) scales::rescale_mid(x, to, from, mid = meio)
  barra <- guide_colourbar(theme = theme(legend.key.height = unit(H$barra_altura_cm, "cm"), legend.key.width = unit(H$barra_largura_cm, "cm")),
                           ticks.colour = "white", frame.colour = NA)
  esc <- scale_fill_gradientn(colours = cores, limits = lim, rescaler = resc, oob = scales::squish, na.value = .cor(H$cor_sem_dado),
                              name = .texto(H$titulo_barra %||% nome), guide = barra)
  pal <- scales::pal_gradient_n(cores)
  list(escala = esc, limites = lim, titulo = H$titulo_barra %||% nome, cor_de = function(v) pal(resc(v, from = lim)))
}

# Rótulo de contraste (preto ou branco) para escrever sobre uma cor.
.cor_contraste <- function(cores) ifelse(vapply(cores, function(k) if (is.na(k)) 1 else .luminancia(k), 0) < 0.5, "white", "black")

# ---- mapa de calor -----------------------------------------------------------------------------
# Matriz de valores (linhas x colunas) a partir dos dados, no formato "matriz" ou "longo". Sai: list(Z, linhas, colunas, nome_linhas, nome_colunas, nome_valor).
.matriz_mapa_calor <- function(dados, cfg) {
  H <- cfg$mapa_calor; G <- cfg$grafico
  xcol <- .coluna(dados, G$coluna_x %||% 1, "cfg$grafico$coluna_x")
  if (identical(H$formato, "longo")) {
    gcol <- .coluna(dados, G$coluna_grupo, "cfg$grafico$coluna_grupo")
    if (is.null(gcol)) .erro("Mapa de calor no formato \"longo\": defina a coluna das colunas do mapa em cfg$grafico$coluna_grupo.")
    vcol <- .colunas_y(dados, cfg, excluir = c(xcol, gcol))[1]
    lin <- as.character(dados[[xcol]]); col <- as.character(dados[[gcol]])
    nl <- unique(lin[!is.na(lin)]); nc <- unique(col[!is.na(col)])
    if (anyDuplicated(paste(lin, col))) .aviso("Há linhas repetidas para o mesmo par (", xcol, ", ", gcol, "): usei a média.")
    Z <- tapply(dados[[vcol]], list(factor(lin, nl), factor(col, nc)), mean, na.rm = TRUE)
    Z <- matrix(as.numeric(Z), length(nl), length(nc), dimnames = list(nl, nc))
    return(list(Z = Z, nome_linhas = xcol, nome_colunas = gcol, nome_valor = vcol))
  }
  ycols <- .colunas_y(dados, cfg, excluir = xcol)
  if (length(ycols) < 2) .erro("O mapa de calor precisa de pelo menos 2 colunas numéricas (além da coluna dos nomes das linhas).")
  nl <- as.character(dados[[xcol]])
  if (anyDuplicated(nl)) { .aviso("Nomes de linha repetidos em '", xcol, "': acrescentei números para diferenciar."); nl <- make.unique(nl) }
  Z <- as.matrix(dados[ycols]); storage.mode(Z) <- "double"; dimnames(Z) <- list(nl, ycols)
  list(Z = Z, nome_linhas = xcol, nome_colunas = "", nome_valor = NULL)
}

# Mapa de calor. Entra: dados e cfg. Sai: list(camadas, info).
.construir_mapa_calor <- function(dados, cfg) {
  H <- cfg$mapa_calor
  m <- .matriz_mapa_calor(dados, cfg); Z <- m$Z
  if (H$normalizar == "linha") Z <- t(apply(Z, 1, function(v) { s <- stats::sd(v, na.rm = TRUE); if (is.na(s) || s == 0) v * 0 else (v - mean(v, na.rm = TRUE)) / s }))
  if (H$normalizar == "coluna") Z <- apply(Z, 2, function(v) { s <- stats::sd(v, na.rm = TRUE); if (is.na(s) || s == 0) v * 0 else (v - mean(v, na.rm = TRUE)) / s })
  dimnames(Z) <- dimnames(m$Z)
  if (H$agrupar != "nenhum") {
    Zc <- Z; Zc[is.na(Zc)] <- 0
    ord <- function(M) if (nrow(M) > 2) stats::hclust(stats::dist(M))$order else seq_len(nrow(M))
    ir <- if (H$agrupar %in% c("linhas", "ambos")) ord(Zc) else seq_len(nrow(Z))
    ic <- if (H$agrupar %in% c("colunas", "ambos")) ord(t(Zc)) else seq_len(ncol(Z))
    Z <- Z[ir, ic, drop = FALSE]
  }
  nr <- nrow(Z); nc <- ncol(Z)
  d <- data.frame(x = rep(seq_len(nc), each = nr), y = rep(nr:1, times = nc), z = as.vector(Z))
  esc <- .escala_z(cfg, d$z, m$nome_valor %||% if (H$normalizar != "nenhum") .rot("Nota z") else .rot("Valor"))
  cam <- list(geom_tile(data = d, aes(x = x, y = y, fill = z), width = 1, height = 1,
                        colour = if (is.na(H$contorno_cor)) NA else .cor(H$contorno_cor), linewidth = .lw(H$contorno_espessura_pt), na.rm = FALSE),
              esc$escala)
  if (isTRUE(H$valores_nas_celulas)) {
    dd <- d[is.finite(d$z), ]
    dd$rot <- .fmt_num(dd$z, H$casas)
    dd$cor <- .cor_contraste(esc$cor_de(dd$z))
    cam[[length(cam) + 1]] <- geom_text(data = dd, aes(x = x, y = y, label = rot), colour = dd$cor, size = .tx(H$tamanho_valores_pt %||% cfg$texto$tamanho_base_pt * 0.8),
                                        family = .fonte(cfg$texto$fonte), fontface = if (.neg(cfg)) "bold" else "plain", show.legend = FALSE)
  }
  ax_x <- .calc_eixo(cfg$eixo_x, c(0.5, nc + 0.5), categorias = colnames(Z), forcar = cfg$.interno$forcar_x)
  ax_y <- .calc_eixo(cfg$eixo_y, c(0.5, nr + 0.5), categorias = rev(rownames(Z)), forcar = cfg$.interno$forcar_y)
  list(camadas = cam,
       info = list(ax_x = ax_x, ax_y = ax_y, flip = FALSE, titulo_x = cfg$eixo_x$titulo %||% m$nome_colunas, titulo_y = cfg$eixo_y$titulo %||% m$nome_linhas,
                   legenda_auto = TRUE, faixa_x = c(0.5, nc + 0.5), faixa_y = c(0.5, nr + 0.5), titulo_barra = esc$titulo))
}

# ---- mapas geográficos --------------------------------------------------------------------------
.cache_mapas <- new.env()

# Chave de comparação de nomes: sem acento, maiúsculas, pontuação nem artigo "the".
.chave_local <- function(x) {
  x <- iconv(as.character(x), to = "ASCII//TRANSLIT"); x[is.na(x)] <- ""
  x <- tolower(gsub("[^A-Za-z0-9]+", "", sub("^\\s*the\\s+", "", x, ignore.case = TRUE)))
  x
}

.exigir_sf <- function() if (!.tem("sf")) .erro("Os mapas precisam do pacote sf. Instale com install.packages(\"sf\") (ou rode o 00_instalar_pacotes.R).")

# Lê um GeoJSON de mapas/ (com cache por arquivo e data). Sai: objeto sf.
.ler_geojson <- function(arq) {
  .exigir_sf()
  caminho <- .arquivo_proj(arq)
  if (!file.exists(caminho)) .erro("Não achei o arquivo de mapa '", arq, "'. Ele vem na pasta mapas/ do Cinabro (mantenha a pasta junto do programa).")
  chave <- paste(normalizePath(caminho, winslash = "/"), file.mtime(caminho))
  if (!is.null(.cache_mapas[[chave]])) return(.cache_mapas[[chave]])
  g <- suppressWarnings(sf::st_read(caminho, quiet = TRUE))
  .cache_mapas[[chave]] <- g
  g
}

# Mundo com a região comercial de cada país (a tabela mapas/mundo_regioes.csv, editável, manda sobre o GeoJSON).
.mapa_base_mundo <- function(cfg) {
  g <- .ler_geojson(cfg$mapa$mundo_geojson %||% "mapas/mundo_paises.geojson")
  csv <- .arquivo_proj(cfg$mapa$mundo_regioes_csv %||% "mapas/mundo_regioes.csv")
  if (file.exists(csv)) {
    t <- utils::read.csv2(csv, stringsAsFactors = FALSE, encoding = "UTF-8", check.names = FALSE, fileEncoding = "UTF-8-BOM")
    if (all(c("country", "region") %in% names(t))) {
      r <- t$region[match(g$name, t$country)]
      g$region <- ifelse(is.na(r) | !nzchar(trimws(r)), g$region, trimws(r))
    } else .aviso("O arquivo ", basename(csv), " precisa das colunas 'country' e 'region'; usei as regiões do próprio mapa.")
  }
  g
}

# Procura os locais do usuário nos nomes do mapa. Entra: nomes, tabela de chaves (lista chave -> índice). Sai: vetor de índices (NA = não achou).
.casar_locais <- function(locais, chaves) {
  k <- .chave_local(locais)
  idx <- unname(chaves[k]); idx[!nzchar(k)] <- NA
  as.integer(idx)
}

# Chaves de nomes do mundo (nome, nome longo, formal, sigla, ISO 3 e os apelidos de mapas/mundo_apelidos.csv).
.chaves_mundo <- function(g, cfg) {
  ch <- character(0); idx <- integer(0)
  add <- function(v, i) { v <- .chave_local(v); ok <- nzchar(v) & !v %in% ch; ch <<- c(ch, v[ok]); idx <<- c(idx, i[ok]) }
  for (campo in c("name", "admin", "name_long", "formal", "abbrev")) if (campo %in% names(g)) add(g[[campo]], seq_len(nrow(g)))
  add(g$iso3, seq_len(nrow(g)))
  ap <- .arquivo_proj("mapas/mundo_apelidos.csv")
  if (file.exists(ap)) {
    t <- tryCatch(utils::read.csv2(ap, stringsAsFactors = FALSE, encoding = "UTF-8", check.names = FALSE, fileEncoding = "UTF-8-BOM"), error = function(e) NULL)
    if (!is.null(t) && all(c("alias", "country") %in% names(t))) { i <- match(t$country, g$name); ok <- !is.na(i); add(t$alias[ok], i[ok]) }
  }
  stats::setNames(idx, ch)
}

# Chaves dos estados (sigla, nome sem acento).
.chaves_brasil <- function(g) {
  ch <- c(.chave_local(g$uf), .chave_local(g$name)); idx <- c(seq_len(nrow(g)), seq_len(nrow(g)))
  ok <- !duplicated(ch); stats::setNames(idx[ok], ch[ok])
}

# Une os polígonos por região (ou outro grupo). Sai: sf com uma linha por grupo.
.unir_por <- function(g, grupo) {
  usava <- suppressMessages(sf::sf_use_s2()); suppressMessages(sf::sf_use_s2(FALSE))     # união plana: o s2 reclama de vértices repetidos nos contornos
  on.exit(suppressMessages(sf::sf_use_s2(usava)), add = TRUE)
  partes <- split(seq_len(nrow(g)), grupo)
  geo0 <- suppressWarnings(sf::st_make_valid(sf::st_geometry(g)))
  geo <- do.call(base::c, lapply(partes, function(i) suppressMessages(sf::st_union(geo0[i]))))
  sf::st_sf(grupo = names(partes), geometry = geo)
}

# Recortes do mundo (caixa em longitude/latitude).
.RECORTES <- list(america = c(-170, -58, -30, 75), europa = c(-25, 34, 45, 72), asia_pacifico = c(60, -50, 180, 60))

# Projeção do mapa-múndi.
.crs_mapa <- function(nome) switch(nome, robinson = "+proj=robin +lon_0=0 +datum=WGS84 +units=m +no_defs", equal_earth = "+proj=eqearth +lon_0=0 +datum=WGS84 +units=m +no_defs",
                                    mercator = "+proj=merc +lon_0=0 +datum=WGS84 +units=m +no_defs", plana = "EPSG:4326")

# Converte as geometrias em tabela de polígonos (com furos) para o ggplot. Sai: data.frame(x, y, grp, anel, item).
.sf_em_tabela <- function(g) {
  geo <- sf::st_geometry(g); out <- list(); k <- 0L
  for (i in seq_along(geo)) {
    ps <- tryCatch(suppressWarnings(sf::st_cast(sf::st_collection_extract(geo[i], "POLYGON"), "POLYGON")), error = function(e) suppressWarnings(sf::st_cast(geo[i], "POLYGON")))
    for (j in seq_along(ps)) {
      k <- k + 1L; m <- sf::st_coordinates(ps[j])
      out[[k]] <- data.frame(x = m[, 1], y = m[, 2], anel = m[, "L1"], grp = k, item = i)
    }
  }
  do.call(rbind, out)
}

# Mapa-múndi e mapa do Brasil. Entra: dados e cfg. Sai: list(camadas, info) (info$mapa = TRUE).
.construir_mapa <- function(dados, cfg) {
  .exigir_sf()
  H <- cfg$mapa_calor; Mp <- cfg$mapa; tipo <- cfg$grafico$tipo; mundo <- tipo == "mapa_mundo"
  xcol <- .coluna(dados, cfg$grafico$coluna_x %||% 1, "cfg$grafico$coluna_x")
  vcol <- .colunas_y(dados, cfg, excluir = xcol)[1]
  locais <- as.character(dados[[xcol]]); val <- dados[[vcol]]
  g <- if (mundo) .mapa_base_mundo(cfg) else .ler_geojson(Mp$brasil_geojson %||% "mapas/brasil_estados.geojson")
  chaves <- if (mundo) .chaves_mundo(g, cfg) else .chaves_brasil(g)
  idx <- .casar_locais(locais, chaves)
  falhou <- is.na(idx) & !is.na(locais) & !is.na(val)
  if (any(falhou)) {
    ref <- if (mundo) g$name else g$uf
    sug <- vapply(locais[falhou], function(l) { d <- utils::adist(l, ref, ignore.case = TRUE); if (min(d) <= max(1, nchar(l) %/% 4)) paste0(" (", ref[which.min(d)], "?)") else "" }, "")
    .aviso(sum(falhou), if (mundo) " país(es) da planilha não foram achados no mapa e ficaram de fora: " else " estado(s) da planilha não foram achados no mapa e ficaram de fora: ",
           paste0("'", locais[falhou], "'", sug, collapse = ", "),
           if (mundo) ". Use o nome em inglês (veja mapas/mundo_regioes.csv) ou acrescente um apelido em mapas/mundo_apelidos.csv." else ". Use a sigla (SP) ou o nome do estado.")
  }
  ok <- !is.na(idx) & !is.na(val)
  if (!any(ok)) .erro("Nenhum local da coluna '", xcol, "' casou com o mapa; confira os nomes (", if (mundo) "em inglês" else "sigla ou nome do estado", ").")
  agg <- switch(Mp$agregacao %||% "soma", soma = function(v) sum(v, na.rm = TRUE), media = function(v) mean(v, na.rm = TRUE), maximo = function(v) max(v, na.rm = TRUE))
  nivel <- Mp$nivel %||% "pais"
  if (!mundo && nivel == "pais") nivel <- "estado"
  if (mundo && nivel == "estado") nivel <- "pais"
  ordem_regiao <- NULL
  if (nivel == "regiao") {
    reg <- g$region[idx[ok]]
    res <- tapply(val[ok], reg, agg)
    sf_plot <- .unir_por(g, g$region); sf_plot$valor <- as.numeric(res[sf_plot$grupo]); sf_plot$rotulo <- sf_plot$grupo
  } else {
    res <- tapply(val[ok], idx[ok], agg)
    sf_plot <- g; sf_plot$valor <- NA_real_; sf_plot$valor[as.integer(names(res))] <- as.numeric(res)
    sf_plot$rotulo <- if (mundo) sf_plot$name else sf_plot$uf
  }
  if (mundo && Mp$recorte %in% names(.RECORTES)) {
    suppressMessages(sf::sf_use_s2(FALSE)); on.exit(suppressMessages(sf::sf_use_s2(TRUE)), add = TRUE)
    bx <- .RECORTES[[Mp$recorte]]
    sf_plot <- suppressWarnings(sf::st_crop(sf::st_make_valid(sf_plot), xmin = bx[1], ymin = bx[2], xmax = bx[3], ymax = bx[4]))
    sf_plot <- sf_plot[!sf::st_is_empty(sf_plot), ]
  }
  crs <- if (mundo) .crs_mapa(Mp$projecao %||% "robinson") else "+proj=aea +lat_1=-5 +lat_2=-33 +lat_0=-15 +lon_0=-54 +datum=WGS84 +units=m +no_defs"
  if (!identical(crs, "EPSG:4326")) sf_plot <- sf::st_transform(sf_plot, crs)
  tab <- .sf_em_tabela(sf_plot); tab$valor <- sf_plot$valor[tab$item]
  esc <- .escala_z(cfg, sf_plot$valor, vcol)
  cam <- list(geom_polygon(data = tab, aes(x = x, y = y, group = grp, subgroup = anel, fill = valor),
                           colour = if (is.na(H$contorno_cor)) NA else .cor(H$contorno_cor), linewidth = .lw(H$contorno_espessura_pt)), esc$escala)
  # rótulos (nome e/ou valor) no ponto do maior pedaço de cada local com valor; os que colidem saem para o lado, com um fio; dá para arrastar
  bb <- c(range(tab$x), range(tab$y)); fx <- diff(bb[1:2]) * 0.01; fy <- diff(bb[3:4]) * 0.01
  xlim <- bb[1:2] + c(-fx, fx); ylim <- bb[3:4] + c(-fy, fy)
  rotulos_info <- NULL
  if (!identical(Mp$rotulos %||% "nenhum", "nenhum")) {
    maior <- do.call(rbind, lapply(seq_len(nrow(sf_plot)), function(i) {
      ps <- tryCatch(suppressWarnings(sf::st_cast(sf::st_collection_extract(sf::st_geometry(sf_plot)[i], "POLYGON"), "POLYGON")),
                     error = function(e) suppressWarnings(sf::st_cast(sf::st_geometry(sf_plot)[i], "POLYGON")))
      a <- as.numeric(sf::st_area(ps)); j <- which.max(a)
      xy <- sf::st_coordinates(suppressWarnings(sf::st_point_on_surface(ps[j]))); data.frame(x = xy[1], y = xy[2])
    }))
    tem <- is.finite(sf_plot$valor)
    dl <- data.frame(maior[tem, , drop = FALSE], nome = sf_plot$rotulo[tem], valor = sf_plot$valor[tem], stringsAsFactors = FALSE)
    casas <- if (all(abs(dl$valor - round(dl$valor)) < 1e-9)) 0 else H$casas        # valores inteiros: sem ",0" à toa
    dl$rot <- switch(Mp$rotulos, nome = dl$nome, valor = .fmt_num(dl$valor, casas), nome_valor = paste0(dl$nome, "\n", .fmt_num(dl$valor, casas)))
    dl <- dl[order(-dl$valor), , drop = FALSE]
    est_t <- list(fonte = .fonte(Mp$rotulos_fonte %||% cfg$texto$fonte), pt = Mp$rotulos_tamanho_pt %||% cfg$texto$tamanho_base_pt * 0.75,
                  face = { n <- .neg(cfg, Mp$rotulos_negrito); i <- isTRUE(Mp$rotulos_italico); if (n && i) "bold.italic" else if (n) "bold" else if (i) "italic" else "plain" })
    pw_cm <- cfg$caixa$painel_largura_cm %||% 12; ph_cm <- cfg$caixa$painel_altura_cm %||% pw_cm * diff(ylim) / diff(xlim)
    sx <- pw_cm / 2.54 / diff(xlim); sy <- ph_cm / 2.54 / diff(ylim)
    me <- .medir_textos(dl$rot, est_t$pt, est_t$fonte, est_t$face)
    pos <- .posicionar_rotulos(dl[c("x", "y")], me$w, me$h, sx, sy, c(xlim, ylim), pref = rep(pi / 4, nrow(dl)), fixas = lapply(dl$nome, function(r) .ler_posicoes(Mp$rotulos_posicoes)[[r]]), raio_ancora = 0.02, centro = TRUE)
    dl$px <- pos$x; dl$py <- pos$y
    dl$cor <- ifelse(pos$longe, cfg$texto$cor, .cor_contraste(esc$cor_de(dl$valor)))
    if (!is.null(Mp$rotulos_cor)) dl$cor <- .cor(Mp$rotulos_cor, "cfg$mapa$rotulos_cor")
    cam[[length(cam) + 1]] <- geom_text(data = dl, aes(x = px, y = py, label = rot), colour = dl$cor, size = .tx(est_t$pt), lineheight = 0.9, family = est_t$fonte,
                                        fontface = est_t$face, show.legend = FALSE)
    if (isTRUE(Mp$linha_guia %||% TRUE) && any(pos$longe)) {
      f <- .fios_rotulos(dl[c("x", "y")], pos, me$w, me$h, sx, sy)
      if (!is.null(f)) cam <- c(list(), cam, list(geom_segment(data = f, aes(x = x, y = y, xend = xend, yend = yend), colour = cfg$texto$cor, linewidth = .lw(0.35), show.legend = FALSE)))
    }
    rotulos_info <- list(campo = "mapa_rotulos_posicoes", itens = data.frame(chave = dl$nome, x = pos$x, y = pos$y, w_in = me$w, h_in = me$h, conj = "mapa", stringsAsFactors = FALSE),
                         lim_x = xlim, lim_y = ylim)
  }
  list(camadas = cam,
       info = list(mapa = TRUE, xlim = xlim, ylim = ylim, legenda_auto = TRUE, flip = FALSE, titulo_barra = esc$titulo, rotulos = rotulos_info,
                   locais_sem_par = if (any(falhou)) locais[falhou] else character(0)))
}
