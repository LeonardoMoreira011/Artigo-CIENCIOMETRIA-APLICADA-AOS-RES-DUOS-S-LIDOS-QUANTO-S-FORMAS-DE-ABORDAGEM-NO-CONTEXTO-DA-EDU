# =============================================================================
#  R/06_eixos_tempo.R — eixo de datas e horas (colunas como 15/03/2024 14:30)
# =============================================================================
#  O eixo continua numérico por dentro: dias desde 1970 (só data) ou segundos
#  desde 1970 em UTC (data e hora). Os ticks e os rótulos é que são calculados
#  como datas. Tudo isto é chamado por .calc_eixo() e .construir_xy().
# =============================================================================

# Formatos de data reconhecidos sozinhos (dia antes do mês, como no Excel em português).
# Para outro formato (ex.: mês/dia/ano) use cfg$eixo_x$formato_data <- "%m/%d/%Y".
.FMT_DATAS <- list(
  list(re = "[0-9]{4}-[0-9]{1,2}-[0-9]{1,2}",      f = "%Y-%m-%d"),
  list(re = "[0-9]{1,2}/[0-9]{1,2}/[0-9]{4}",      f = "%d/%m/%Y"),
  list(re = "[0-9]{1,2}-[0-9]{1,2}-[0-9]{4}",      f = "%d-%m-%Y"),
  list(re = "[0-9]{1,2}\\.[0-9]{1,2}\\.[0-9]{4}",  f = "%d.%m.%Y"),
  list(re = "[0-9]{4}/[0-9]{1,2}/[0-9]{1,2}",      f = "%Y/%m/%d"))

# Passos de tick automáticos: nome no formato do seq() e duração aproximada (s).
.PASSOS_TEMPO <- c("1 sec" = 1, "5 sec" = 5, "15 sec" = 15, "30 sec" = 30,
                   "1 min" = 60, "5 min" = 300, "15 min" = 900, "30 min" = 1800,
                   "1 hour" = 3600, "3 hour" = 10800, "6 hour" = 21600, "12 hour" = 43200,
                   "1 day" = 86400, "2 day" = 172800, "1 week" = 604800, "2 week" = 1209600,
                   "1 month" = 2629800, "3 month" = 7889400, "6 month" = 15778800,
                   "1 year" = 31557600, "2 year" = 63115200, "5 year" = 157788000,
                   "10 year" = 315576000, "20 year" = 631152000, "50 year" = 1577880000,
                   "100 year" = 3155760000)

# Unidades aceitas em cfg$eixo_x$incremento (português ou inglês) -> unidade do seq()
.UNIDADES_TEMPO <- c(sec = "sec", secs = "sec", s = "sec", seg = "sec", segundo = "sec", segundos = "sec",
                     min = "min", mins = "min", minuto = "min", minutos = "min",
                     hour = "hour", hours = "hour", h = "hour", hora = "hour", horas = "hour",
                     day = "day", days = "day", d = "day", dia = "day", dias = "day",
                     week = "week", weeks = "week", semana = "week", semanas = "week",
                     month = "month", months = "month", mes = "month", "mês" = "month", meses = "month",
                     year = "year", years = "year", ano = "year", anos = "year")
.SEG_UNIDADE <- c(sec = 1, min = 60, hour = 3600, day = 86400, week = 604800,
                  month = 2629800, year = 31557600)

# Reconhece uma coluna de datas/horas. Entra: vetor (texto, Date ou POSIXct) e, opcional, um
# formato strptime. Sai: NULL (não é data) ou list(classe = "Date"|"POSIXct", num, formato).
# num = posições no eixo (dias para Date, segundos para POSIXct); NA onde o texto é vazio.
.detectar_tempo <- function(v, formato = NULL) {
  if (inherits(v, "Date")) return(list(classe = "Date", num = as.numeric(v), formato = NA_character_))
  if (inherits(v, "POSIXct")) return(list(classe = "POSIXct", num = as.numeric(v), formato = NA_character_))
  if (!is.character(v)) return(NULL)
  vazio <- is.na(v) | !nzchar(trimws(v))
  x <- sub("T", " ", trimws(v[!vazio]), fixed = TRUE)
  if (!length(x)) return(NULL)
  devolver <- function(seg, classe, fmt) {
    num <- rep(NA_real_, length(v))
    num[!vazio] <- if (classe == "Date") seg / 86400 else seg
    list(classe = classe, num = num, formato = fmt)
  }
  if (!is.null(formato) && !is.na(formato) && !identical(formato, "auto")) {
    p <- as.numeric(as.POSIXct(strptime(x, formato, tz = "UTC")))
    if (anyNA(p)) return(NULL)
    return(devolver(p, if (grepl("%[HMSIpTR]", formato)) "POSIXct" else "Date", formato))
  }
  for (fm in .FMT_DATAS) {
    if (!all(grepl(paste0("^", fm$re, "( [0-9]{1,2}:[0-9]{2}(:[0-9]{2})?)?$"), x))) next
    com_seg <- grepl(":[0-9]{2}:[0-9]{2}$", x)
    com_hm <- !com_seg & grepl(":", x, fixed = TRUE)
    so_data <- !com_seg & !com_hm
    seg <- rep(NA_real_, length(x))
    ler <- function(sel, f) as.numeric(as.POSIXct(strptime(x[sel], f, tz = "UTC")))
    if (any(com_seg)) seg[com_seg] <- ler(com_seg, paste(fm$f, "%H:%M:%S"))
    if (any(com_hm))  seg[com_hm]  <- ler(com_hm, paste(fm$f, "%H:%M"))
    if (any(so_data)) seg[so_data] <- ler(so_data, fm$f)
    if (anyNA(seg)) next                         # data impossível (ex.: 31/02): tenta o próximo formato
    return(devolver(seg, if (any(com_seg | com_hm)) "POSIXct" else "Date", fm$f))
  }
  NULL
}

# Interpreta "1 month", "2 semanas", "6 horas"... Sai: NULL ou list(n, un, by, seg).
.passo_tempo <- function(x) {
  if (!is.character(x) || length(x) != 1 || is.na(x)) return(NULL)
  m <- regmatches(tolower(x), regexec("^\\s*([0-9]+)\\s*([^0-9[:space:]]+)\\s*$", tolower(x)))[[1]]
  if (length(m) != 3) return(NULL)
  un <- unname(.UNIDADES_TEMPO[m[3]])
  n <- as.integer(m[2])
  if (is.na(un) || is.na(n) || n < 1) return(NULL)
  list(n = n, un = un, by = paste(n, un), seg = n * unname(.SEG_UNIDADE[un]))
}

# Posição no eixo -> objeto Date ou POSIXct (UTC)
.eixo_para_tempo <- function(v, classe) {
  if (classe == "Date") as.Date(v, origin = "1970-01-01")
  else as.POSIXct(v, origin = "1970-01-01", tz = "UTC")
}

# Converte um limite/tick dado pelo usuário (texto, Date, POSIXct ou número) para a posição
# no eixo. Número é aceito como já está na unidade do eixo (dias ou segundos).
.tempo_num <- function(v, tempo, onde) {
  if (is.null(v)) return(NULL)
  if (is.numeric(v)) return(as.numeric(v))
  d <- .detectar_tempo(v, tempo$formato)
  if (is.null(d) && is.character(v)) d <- .detectar_tempo(v)
  if (is.null(d) || anyNA(d$num))
    .erro(onde, ": não entendi a data '", paste(v, collapse = "', '"),
          "'. Use \"2024-03-15\", \"15/03/2024\" ou \"15/03/2024 14:30\".")
  if (d$classe == tempo$classe) d$num
  else if (tempo$classe == "POSIXct") d$num * 86400   # data -> segundos
  else d$num / 86400                                  # data/hora -> dias
}

# Primeiro tick <= lo alinhado ao passo (início do mês, da semana, do ano, da hora...)
.alinhar_tempo <- function(lo, passo, classe) {
  por_dia <- if (classe == "Date") 1 else 86400
  if (passo$un %in% c("month", "year")) {
    d <- .eixo_para_tempo(lo, classe)
    y <- as.integer(format(d, "%Y")); m <- as.integer(format(d, "%m"))
    ini <- if (passo$un == "month") as.Date(sprintf("%04d-%02d-01", y, ((m - 1L) %/% passo$n) * passo$n + 1L))
           else as.Date(sprintf("%04d-01-01", (y %/% passo$n) * passo$n))
    return(as.numeric(ini) * por_dia)
  }
  u <- passo$seg / (if (classe == "Date") 86400 else 1)    # duração do passo na unidade do eixo
  if (passo$un == "week") return(floor((lo - 4 * por_dia) / u) * u + 4 * por_dia)   # semanas começam na segunda
  floor(lo / u) * u
}

# Sequência de ticks entre ini e fim (posições no eixo) a cada 'passo'
.sequencia_tempo <- function(ini, fim, passo, classe) {
  if (classe == "Date" && passo$un %in% c("sec", "min", "hour"))
    .erro("O eixo tem só datas (sem hora): use passos de dia, semana, mês ou ano em vez de '", passo$by, "'.")
  if (ini > fim) return(numeric(0))
  if ((fim - ini) * (if (classe == "Date") 86400 else 1) / passo$seg > 2000)
    .erro("O passo '", passo$by, "' geraria mais de 2000 ticks no eixo. Use um passo maior.")
  s <- seq(.eixo_para_tempo(ini, classe), .eixo_para_tempo(fim, classe), by = passo$by)
  as.numeric(s)
}

# Ticks automáticos "redondos" (cerca de 'alvo' deles). cobrir = TRUE estende até passar de hi.
.quebras_tempo <- function(lo, hi, classe, alvo = 6, cobrir = FALSE) {
  por_dia <- if (classe == "Date") 1 else 86400
  cand <- .PASSOS_TEMPO
  if (classe == "Date") cand <- cand[cand >= 86400]
  n_ticks <- pmax((hi - lo) / por_dia * 86400 / cand, 1e-9)
  passo <- .passo_tempo(names(cand)[which.min(abs(log(n_ticks / alvo)))])
  ini <- .alinhar_tempo(lo, passo, classe)
  tk <- .sequencia_tempo(ini, hi + passo$seg * 1.1 / (86400 / por_dia), passo, classe)
  if (!cobrir) return(tk[tk <= hi])
  i <- which(tk >= hi)[1]
  if (is.na(i)) tk else tk[seq_len(i)]
}

# Limites automáticos do eixo de tempo: arredonda os dados para fora até um tick redondo
.limites_tempo <- function(faixa, classe) {
  r <- range(faixa[is.finite(faixa)])
  if (diff(r) == 0) r <- r + c(-1, 1) * (if (classe == "Date") 1 else 3600)
  range(.quebras_tempo(r[1], r[2], classe, cobrir = TRUE))
}

# Ticks maiores em eixo de tempo nos modos "auto", "incremento" e "manual".
.maiores_tempo <- function(e, lo, hi, tempo, modo) {
  if (modo == "manual") return(.tempo_num(e$ticks_manuais, tempo, "cfg$eixo_x$ticks_manuais"))
  if (modo == "auto") return(.quebras_tempo(lo, hi, tempo$classe))
  passo <- .passo_tempo(e$incremento)
  ini <- .tempo_num(e$primeiro_tick, tempo, "cfg$eixo_x$primeiro_tick") %||% lo
  if (!is.null(passo)) return(.sequencia_tempo(ini, hi, passo, tempo$classe))
  if (!is.numeric(e$incremento))
    .erro("cfg$eixo_x$incremento = '", e$incremento, "' não é um passo de tempo válido. ",
          "Exemplos: \"1 day\", \"2 semanas\", \"1 mes\", \"6 horas\", \"30 min\".")
  ini + (0:floor((hi - ini) / e$incremento + 1e-9)) * e$incremento
}

# Formatador dos rótulos de um eixo de tempo. O formato automático depende do passo entre os ticks
# (anos -> "2024"; meses -> "03/2024"; dias -> "15/03"; horas -> "14:30"): só números, para não
# depender do idioma do computador. cfg$eixo_x$formato_rotulo_data troca o formato.
# Entra: config do eixo, classe, limites e os ticks maiores (posições no eixo).
.formatador_tempo <- function(e, classe, lim, maiores = NULL) {
  por_dia <- if (classe == "Date") 1 else 86400
  dias <- (lim[2] - lim[1]) / por_dia
  passo <- if (length(maiores) >= 2) stats::median(diff(sort(maiores))) / por_dia * 86400 else dias * 86400 / 5
  fmt <- e$formato_rotulo_data %||% if (passo >= 300 * 86400) "%Y"
    else if (passo >= 25 * 86400) "%m/%Y"
    else if (passo >= 0.9 * 86400) (if (dias > 300) "%d/%m/%y" else "%d/%m")
    else if (passo >= 60) (if (dias >= 1) "%d/%m %H:%M" else "%H:%M")
    else "%H:%M:%S"
  pre <- e$prefixo %||% ""; suf <- e$sufixo %||% ""
  function(x) {
    out <- format(.eixo_para_tempo(x, classe), fmt)
    out <- paste0(pre, out, suf)
    out[is.na(x)] <- ""
    out
  }
}
