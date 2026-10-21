#!/usr/bin/env python3
"""Gera graficos_R_completo.R: o projeto inteiro (config + motor + catálogo + estilos + instalador)
num único arquivo .R. Uso (na pasta graficos_R):  python3 ferramentas/gerar_script_unico.py
Só é preciso para quem mantém o código; quem usa o template não precisa deste arquivo."""
import re, sys, pathlib

raiz = pathlib.Path(__file__).resolve().parent.parent
ler = lambda p: (raiz / p).read_text(encoding="utf-8").rstrip("\n")

def trocar(texto, antigo, novo, vezes=1):
    assert texto.count(antigo) == vezes, (texto.count(antigo), antigo[:80])
    return texto.replace(antigo, novo)

# ---- módulos do motor, na ordem do carregador ------------------------------------------
carregador = ler("02_motor.R")
arquivos = re.findall(r'"(\d\d_[a-z_0-9]+\.R)"', carregador.split(".MOTOR_ARQUIVOS <- c(")[1].split(")")[0])
modulos = {a: ler("R/" + a) for a in arquivos}

modulos["01_base.R"] = trocar(modulos["01_base.R"], '''.cfg_ref <- local({
  arq <- file.path(.motor_pasta, "01_config.R")
  if (file.exists(arq)) { e <- new.env(); sys.source(arq, envir = e); e$cfg } else {
    warning("Não achei 01_config.R em '", .motor_pasta, "': a checagem de nomes digitados errado, ",
            "ajuda() e resetar_cfg() ficam desativados.", call. = FALSE, immediate. = TRUE)
    NULL
  }
})''', '.cfg_ref <- .CFG_PADRAO   # cópia do cfg padrão (PARTE 1), antes de qualquer edição sua')
modulos["01_base.R"] = trocar(modulos["01_base.R"], '". Rode primeiro o arquivo 00_instalar_pacotes.R"', '". Rode primeiro: instalar_pacotes()"')
modulos["01_base.R"] = trocar(modulos["01_base.R"], '"Rode 00_instalar_pacotes.R para atualizar."', '"Rode instalar_pacotes() para atualizar."')
modulos["16_exportacao.R"] = trocar(modulos["16_exportacao.R"], "(rode 00_instalar_pacotes.R)", "(rode instalar_pacotes())")
modulos["17_estilos.R"] = trocar(modulos["17_estilos.R"], '''# Nomes dos estilos disponíveis na pasta de estilos.
listar_estilos <- function(pasta = "estilos") {
  pasta <- .pasta_proj(pasta)
  sub("\\\\.R$", "", list.files(pasta, pattern = "\\\\.R$"))
}''', '''# Nomes dos estilos disponíveis: os 3 embutidos neste script e os arquivos da pasta de estilos.
listar_estilos <- function(pasta = "estilos") {
  pasta <- .pasta_proj(pasta)
  sort(unique(c(names(.ESTILOS_EMBUTIDOS), sub("\\\\.R$", "", list.files(pasta, pattern = "\\\\.R$")))))
}''')
modulos["17_estilos.R"] = trocar(modulos["17_estilos.R"], '''# Recarrega o 01_config.R e substitui o cfg do console pelo padrão.
resetar_cfg <- function() {
  e <- new.env(); sys.source(file.path(.motor_pasta, "01_config.R"), envir = e)
  assign("cfg", e$cfg, envir = globalenv())
  message("cfg voltou ao padrão de 01_config.R")
  invisible(e$cfg)
}''', '''# Volta o cfg do console ao padrão da PARTE 1 deste script.
resetar_cfg <- function() {
  assign("cfg", .CFG_PADRAO, envir = globalenv())
  message("cfg voltou ao padrão (PARTE 1 do script)")
  invisible(.CFG_PADRAO)
}''')
modulos["17_estilos.R"] = trocar(modulos["17_estilos.R"], '''  pasta <- .pasta_proj(pasta)
  arq <- if (file.exists(nome)) nome else file.path(pasta, paste0(nome, ".R"))''', '''  pasta <- .pasta_proj(pasta)
  if (!file.exists(nome) && !file.exists(file.path(pasta, paste0(nome, ".R"))) && nome %in% names(.ESTILOS_EMBUTIDOS))
    return(.mesclar(cfg, .ESTILOS_EMBUTIDOS[[nome]]))      # estilo embutido neste script
  arq <- if (file.exists(nome)) nome else file.path(pasta, paste0(nome, ".R"))''')
modulos["17_estilos.R"] = trocar(modulos["17_estilos.R"], '''    disp <- sub("\\\\.R$", "", list.files(pasta, pattern = "\\\\.R$"))''', '''    disp <- listar_estilos(pasta)''')

catalogo = ler("04_catalogo.R")
catalogo = trocar(catalogo, '''  arq <- file.path(.motor_pasta, "01_config.R")
  L <- readLines(arq, encoding = "UTF-8", warn = FALSE)''', '''  L <- .config_linhas()''')

# ---- estilos embutidos ---------------------------------------------------------------------
estilos = sorted((raiz / "estilos").glob("*.R"))
embutidos = ".ESTILOS_EMBUTIDOS <- list(\n" + ",\n".join(
    "  %s = %s" % (e.stem, "\n".join(("  " + l if i else l) for i, l in enumerate(e.read_text(encoding="utf-8").rstrip("\n").split("\n"))))
    for e in estilos) + "\n)"

# ---- instalador como função ------------------------------------------------------------------
inst = ler("00_instalar_pacotes.R").split("# =============================================================================\n", 2)[2].strip("\n")
inst = trocar(inst, 'cat("\\nTudo pronto. Agora abra 03_executar.R e rode linha a linha (Ctrl+Enter).\\n")',
              'cat("\\nTudo pronto. Reinicie a sessão (Ctrl+Shift+F10) e rode este script de novo (Source).\\n")')
inst = trocar(inst, 'ajuste Sys.setenv(https_proxy=...) no topo deste arquivo;', "rode Sys.setenv(https_proxy = 'http://usuario:senha@proxy:8080') e tente de novo;")
instalador = ("# Instala/atualiza os pacotes necessários. Rode UMA vez:  instalar_pacotes()\n"
              "#  (sem permissão de administrador, instala na sua pasta pessoal; com proxy, defina antes\n"
              "#   Sys.setenv(https_proxy = \"http://usuario:senha@proxy.empresa.com:8080\"))\n"
              "instalar_pacotes <- function() {\n" + "\n".join(("  " + l if l.strip() else l) for l in inst.split("\n")) + "\n}")

config = ler("01_config.R")
PAINEL = '# ' + '-' * 77 + '\n#  PAINEL DE AJUSTES (arquivo painel_de_ajustes.R do projeto)\n# ' + '-' * 77 + '\n' + ler("painel_de_ajustes.R") + '\n'
config = trocar(config, "#  01_config.R  —  TODOS OS PARÂMETROS EDITÁVEIS DO GRÁFICO", "#  PARÂMETROS EDITÁVEIS DO GRÁFICO (o cfg)")

# referências a arquivos do projeto, que neste script viram "PARTE 1"
def sem_arquivos(t):
    for a, b in [("Veja o exemplo em 01_config.R.", "Veja o exemplo na PARTE 1 deste script."),
                 ("com os padrões do 01_config.R", "com os padrões da PARTE 1"),
                 ("comparando com o 01_config.R", "comparando com a PARTE 1"),
                 ("lido diretamente do 01_config.R", "lido diretamente da PARTE 1 deste script"),
                 ("\\n  Dica: abra o projeto pelo arquivo graficos_R.Rproj ou use o caminho completo.",
                  "\\n  Dica: use o caminho completo do arquivo (ex.: 'C:/pasta/dados.csv') ou confira a pasta de trabalho com getwd().")]:
        t = t.replace(a, b)
    return t
modulos = {k: sem_arquivos(v) for k, v in modulos.items()}
catalogo = sem_arquivos(catalogo)

CAB = '''# =============================================================================
#  graficos_R_completo.R  —  TEMPLATE DE GRÁFICOS CIENTÍFICOS EM R (ARQUIVO ÚNICO)
# =============================================================================
#  Cinabro: pontos, linhas, áreas, barras, pizza, histograma, densidade,
#  ECDF e boxplot, com controle fino de eixos, ticks, moldura, cores, gradientes,
#  legenda, painéis empilhados, quebra de eixo, eixo de datas e exportação
#  (PNG, TIFF, JPEG, PDF, SVG, EMF). Tudo em um único arquivo.
#
#  COMO USAR (3 passos)
#   1) Só na primeira vez:   instalar_pacotes()      (depois de rodar este arquivo, ver passo 2;
#                            se faltar pacote, o script para e avisa; rode instalar_pacotes() e
#                            depois este arquivo de novo)
#   2) Abra este arquivo no RStudio e clique em  Source  (ou Ctrl+Shift+S).
#   3) Teste:    demonstracao()          # gráfico de exemplo com dados fictícios
#                demonstracao("datas")   # outras: "linha", "barras", "pizza", "boxplot", "datas"
#      Seus dados:   role até a PARTE 3 (PAINEL DE AJUSTES): preencha ARQUIVO_CSV, mude o que quiser
#                    (escala, ticks, grade, quebra, cores, fonte...) e dê Source de novo.
#                    Alternativa: dados <- ler_csv("C:/pasta/dados.csv"); g <- plotar(dados, cfg); salvar(g, cfg)
#
#  AJUDA:  ajuda()  |  ajuda("eixo_x")  |  ajuda("tipos")  |  galeria()
#  (ajuda() lê a PARTE 1 deste arquivo: use Source, ou deixe o arquivo na pasta de trabalho
#   com o nome graficos_R_completo.R)
#
#  Se os acentos aparecerem estranhos: File > Reopen with Encoding > UTF-8.
#  Estrutura:  PARTE 0 instalador | PARTE 1 configuração (cfg) | PARTE 2 motor | PARTE 2B fonte Barlow | PARTE 3 painel
#  Requisitos: R >= 4.2, ggplot2 >= 3.5, scales, patchwork, ragg >= 1.5.
# =============================================================================
'''

P0 = '''
# #############################################################################
#  PARTE 0 — INSTALADOR DE PACOTES
# #############################################################################

''' + instalador + "\n"

P1 = '''
# #############################################################################
#  PARTE 1 — CONFIGURAÇÃO (cfg): TODOS OS PARÂMETROS EDITÁVEIS
# #############################################################################
# @@INICIO_CONFIG@@
''' + config + '''
# @@FIM_CONFIG@@
.CFG_PADRAO <- cfg   # guarda o padrão: resetar_cfg() e a checagem de nomes usam esta cópia
'''

ARQ = '''
# #############################################################################
#  PARTE 2 — MOTOR (não precisa editar)
# #############################################################################

# Caminho deste arquivo (quando rodado com Source) e pasta do projeto.
.achar_arquivo_script <- function() {
  for (i in rev(seq_len(sys.nframe()))) {
    quadro <- tryCatch(sys.frame(i), error = function(e) NULL)
    if (!is.null(quadro) && exists("ofile", envir = quadro, inherits = FALSE)) {
      of <- get("ofile", envir = quadro, inherits = FALSE)
      if (is.character(of) && length(of) == 1 && file.exists(of) && grepl("@@INICIO_CONFIG@@", paste(readLines(of, n = 400, warn = FALSE, encoding = "UTF-8"), collapse = "\\n"), fixed = TRUE))
        return(normalizePath(of, winslash = "/"))
    }
  }
  if (file.exists("graficos_R_completo.R")) return(normalizePath("graficos_R_completo.R", winslash = "/"))
  NULL
}
.ARQUIVO_SCRIPT <- .achar_arquivo_script()
.motor_pasta <- if (!is.null(.ARQUIVO_SCRIPT)) dirname(.ARQUIVO_SCRIPT) else getwd()

# Linhas da PARTE 1 deste arquivo (ajuda() mostra os comentários de cada parâmetro).
.config_linhas <- function() {
  if (is.null(.ARQUIVO_SCRIPT) || !file.exists(.ARQUIVO_SCRIPT))
    stop("ajuda() precisa ler este arquivo. Rode-o com Source (ou deixe-o na pasta de trabalho ",
         "com o nome graficos_R_completo.R).", call. = FALSE)
  L <- readLines(.ARQUIVO_SCRIPT, encoding = "UTF-8", warn = FALSE)
  i <- grep("^# @@INICIO_CONFIG@@", L); f <- grep("^# @@FIM_CONFIG@@", L)
  L[(i[1] + 1):(f[1] - 1)]
}

# Estilos prontos (equivalem aos arquivos da pasta estilos/ do projeto).
''' + embutidos + "\n"

MOD = "".join("\n# " + "-" * 77 + "\n#  " + a + "\n# " + "-" * 77 + "\n" + modulos[a] + "\n" for a in arquivos)
CAT = "\n# " + "-" * 77 + "\n#  04_catalogo.R — ajuda(), galeria(), mostrar_paletas()\n# " + "-" * 77 + "\n" + catalogo + "\n"

# fonte Barlow embutida (4 estilos do Barlow, comprimidos): usada se a pasta fontes/ não estiver junto do script
import base64, zlib
def _b64(nome):
    dados = (raiz / "fontes" / "Barlow" / f"Barlow-{nome}.ttf").read_bytes()
    txt = base64.b64encode(zlib.compress(dados, 9)).decode()
    return "\n".join(txt[i:i + 100] for i in range(0, len(txt), 100))
FONTE = ("\n# " + "#" * 77 + "\n#  PARTE 2B — FONTE OFICIAL BARLOW (embutida; não precisa editar)\n"
         "#  Licença SIL Open Font License 1.1 (veja fontes/Barlow/OFL.txt no repositório). Se a pasta fontes/Barlow estiver\n"
         "#  ao lado deste script, ela é usada no lugar desta cópia.\n# " + "#" * 77 + "\n.BARLOW_EMBUTIDA <- list(\n"
         + ",\n".join(f'  {n} = "\n{_b64(n)}\n"' for n in ["Regular", "Bold", "Italic", "BoldItalic"]) + "\n)\n")

P3 = '''
# #############################################################################
#  PARTE 3 — COMO USAR
# #############################################################################

# Exemplos rápidos com dados fictícios (para testar a instalação e ver o resultado).
# Os arquivos vão para a pasta saida/demonstracao/ dentro da sua pasta de trabalho.
demonstracao <- function(tipo = c("linha", "barras", "pizza", "boxplot", "datas")) {
  tipo <- match.arg(tipo)
  cfg <- .CFG_PADRAO
  cfg$exportacao$pasta <- "saida/demonstracao"; cfg$exportacao$formatos <- c("png", "pdf")
  cfg$exportacao$dpi <- 200; cfg$exportacao$nome_arquivo <- paste0("demo_", tipo)
  dados <- switch(tipo,
    linha = {
      t <- seq(0, 60, by = 5)
      cfg$grafico$tipo <- "linha_pontos"; cfg$eixo_x$titulo <- "Tempo (min)"; cfg$eixo_y$titulo <- "Temperatura (°C)"
      cfg$eixo_x$ticks_modo <- "incremento"; cfg$eixo_x$incremento <- 10
      cfg$caixa$fechada <- TRUE; cfg$caixa$ticks_espelhados <- TRUE; cfg$legenda$posicao <- "dentro"
      cfg$legenda$dentro_x <- 0.04; cfg$legenda$dentro_y <- 0.96
      data.frame(`Tempo (min)` = t, `Amostra A` = 20 + 0.9 * t - 0.004 * t^2,
                 `Amostra B` = 20 + 0.55 * t, `Amostra C` = 20 + 0.3 * t + 3 * sin(t / 8), check.names = FALSE)
    },
    barras = {
      cfg$grafico$tipo <- "barras"; cfg$eixo_y$titulo <- "Resistência (MPa)"; cfg$eixo_x$titulo <- ""
      cfg$eixo_y$inicio <- 0; cfg$barras$rotulos_valor <- TRUE; cfg$barras$rotulos_casas <- 0
      cfg$cores$preenchimento <- "gradiente"; cfg$legenda$posicao <- "dentro"
      data.frame(Material = c("Aço", "Alumínio", "Cobre", "Titânio", "Polímero"),
                 `Ensaio 1` = c(420, 270, 220, 880, 65), `Ensaio 2` = c(405, 262, 231, 861, 58), check.names = FALSE)
    },
    pizza = {
      cfg$grafico$tipo <- "pizza"; cfg$pizza$raio_furo <- 0.45; cfg$pizza$rotulos <- c("categoria", "percentual")
      cfg$pizza$rotulos_separador <- "\\n"; cfg$titulos$titulo <- "Composição da liga (% massa)"
      data.frame(Elemento = c("Ferro", "Carbono", "Cromo", "Níquel", "Manganês", "Silício", "Vanádio"),
                 Massa = c(70, 12, 6, 5, 3, 2.2, 1.8))
    },
    boxplot = {
      set.seed(42)
      cfg$grafico$tipo <- "boxplot"; cfg$boxplot$variacao <- "box_pontos"; cfg$eixo_y$titulo <- "Resposta (u.a.)"
      data.frame(Controle = round(rnorm(20, 50, 5), 1), `Dose 1` = round(rnorm(20, 57, 6), 1),
                 `Dose 2` = round(rnorm(20, 65, 8), 1), check.names = FALSE)
    },
    datas = {
      cfg$grafico$tipo <- "linha_pontos"; cfg$eixo_x$titulo <- "Data da coleta"; cfg$eixo_y$titulo <- "Temperatura (°C)"
      cfg$eixo_x$ticks_modo <- "incremento"; cfg$eixo_x$incremento <- "2 semanas"; cfg$eixo_x$formato_rotulo_data <- "%d/%m"
      cfg$legenda$mostrar <- FALSE                 # só há uma série: dispensa a legenda
      d <- as.Date("2024-03-01") + seq(0, 77, by = 7)
      data.frame(`Data` = format(d, "%d/%m/%Y"), `Temperatura (°C)` = round(22 + 3 * sin(seq(0, 6, length.out = length(d))), 1),
                 check.names = FALSE)
    })
  g <- plotar(dados, cfg)
  visualizar(g, cfg)
  salvar(g, cfg)
  invisible(g)
}

''' + PAINEL + '''
message("\\nTemplate de gráficos carregado. Para um teste rápido rode:  demonstracao()   (ou ajuda())")
'''

saida = CAB + P0 + P1 + ARQ + MOD + CAT + FONTE + P3
(raiz / "graficos_R_completo.R").write_text(saida + "\n", encoding="utf-8")
print("graficos_R_completo.R gerado:", saida.count("\n") + 1, "linhas")
