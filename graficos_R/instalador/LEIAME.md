# Instalador do Windows (Cinabro-Setup)

Um único arquivo `Cinabro-Setup-<versão>.exe`. Quem usa só dá dois cliques: **não precisa instalar R, RStudio nem pacotes, nem ter internet, nem ser administrador.**

## O que o instalador faz
- Instala em `%LOCALAPPDATA%\Programs\Cinabro` (só para o usuário atual) um **R 4.5 portátil**, os **pacotes nas versões fixas** e o app.
- Cria o atalho **Cinabro** (com o ícone) no menu Iniciar e, se a pessoa marcar, na área de trabalho. Também cria "Cinabro (com janela, para diagnóstico)" e "registro de uso (para suporte)".
- O R do Cinabro é separado: **não mexe** no R, no RStudio nem nas bibliotecas que a pessoa já tenha.
- Atualizar = rodar o instalador novo por cima (a pasta antiga do programa é trocada por inteiro; os registros e as configurações salvas ficam).
- Desinstalar: Configurações do Windows > Aplicativos > Cinabro.
- Registros de uso (só nomes de campos e tempos, sem dados): `%LOCALAPPDATA%\Cinabro\log\app.log` e `inicio.log` (o que o R escreveu ao abrir).

## Como o instalador é feito (GitHub Actions)
O fluxo `.github/workflows/instalador-windows.yml` roda num Windows limpo a cada envio ao GitHub e **testa antes de entregar**:
1. instala o R 4.5 e os pacotes **da mesma foto do CRAN** (`FOTO_CRAN` no fluxo; todo mundo recebe as mesmas versões);
2. roda os testes do motor e do app com esse R e esses pacotes;
3. gera um gráfico (PNG, PDF e SVG, com a fonte Barlow) e abre o app pelo mesmo lançador dos atalhos;
4. compila o instalador (Inno Setup), **instala em silêncio, testa a cópia instalada e desinstala**;
5. guarda o `.exe` como "artefato" do fluxo (aba Actions > a execução > Artifacts). Em uma tag `v1.0.0` ele também anexa o `.exe` à versão (Releases).

Para gerar uma versão numerada: `git tag v0.1.0 && git push origin v0.1.0`. Sem tag, a versão é `0.1.0.<número da execução>` (o `0.1.0` vem de `instalador/VERSAO.txt`).

## Arquivos
| arquivo | para quê |
|---|---|
| `Cinabro.iss` | roteiro do Inno Setup (atalhos, pastas, desinstalação, português) |
| `montar.ps1` | monta a carga em `instalador/stage` (R portátil + pacotes + app) |
| `instalar_pacotes.R` | instala os pacotes da foto fixa do CRAN |
| `lancador/Cinabro.vbs` | abre o app sem janela de comando; se já estiver aberto, só abre o navegador; se não subir em 30 s, avisa e aponta o registro |
| `lancador/Cinabro_com_janela.cmd` | o mesmo, com janela (diagnóstico; não depende do VBScript) |
| `testar_instalacao.ps1`, `teste_motor_instalado.R` | testes de fumaça usados pelo fluxo (e que você pode rodar numa cópia instalada) |

## Avisos honestos
- **O `.exe` não é assinado.** O Windows (SmartScreen) mostra "O Windows protegeu o computador": clique em **Mais informações > Executar assim mesmo**. Assinatura digital de código custa por ano e só vale a pena se o programa sair do time.
- Antivírus corporativos podem implicar com `.vbs`. Se o atalho normal não abrir, use "Cinabro (com janela...)" (sem VBScript) e mande o `inicio.log`.
- Tamanho: o instalador tem algumas dezenas de MB (o R vai dentro).
