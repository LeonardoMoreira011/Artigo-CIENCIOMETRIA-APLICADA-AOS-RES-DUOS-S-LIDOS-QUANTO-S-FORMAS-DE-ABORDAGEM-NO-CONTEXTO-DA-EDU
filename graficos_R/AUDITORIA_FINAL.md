# Auditoria final do Cinabro (Dashboard e modelos de planilha incluídos)

Data: 29/10/2026 · Versão auditada: `0.2.0` (histórico no git, branch `ccr-d5f3c304-yrbrd1`)

## 1. Parecer

**Aprovado para uso, sem pendências bloqueantes.** Todas as ferramentas de teste do projeto passam, a bateria nova (fuzz dos tipos novos, casos extremos do Dashboard, desempenho) não achou falha que o usuário pudesse ver sem aviso em português, e os 11 achados da auditoria foram corrigidos. Os testes também passam em um **Windows de verdade** (CI do GitHub: `windows-latest`, R 4.5.3, instalador compilado, instalado e desinstalado em silêncio).

Restam três itens que **eu não consigo provar aqui** e que o time deve conferir uma vez no Windows (seção 6): o PDF do Dashboard saindo pelo Edge de um computador real, o logo/cores institucionais no cabeçalho e a leitura do manual impresso. Nenhum deles tem indício de problema; são os pontos de menor cobertura.

## 2. O que foi rodado

| Ferramenta | Resultado |
|---|---|
| Higiene estática: sintaxe dos 58 arquivos `.R`, `node --check` nos scripts JS, UTF-8 e BOM, CRLF dos `.bat/.cmd/.vbs` no ZIP, imagens do manual, restos de depuração | 0 problemas |
| `06_testes.R` (motor), ggplot2 4.x e 3.5 | **282/282** nas duas |
| Script único (`graficos_R_completo.R`) com o mesmo teste, ggplot2 4.x e 3.5 | 281/282 nas duas (a falha restante é do arranjo do teste: ele confere `idiomas_arquivados/`, que não existe numa pasta só com o arquivo único) |
| `app_shiny/testes_app.R`, ggplot2 4.x e 3.5 | **119/119** nas duas |
| `05_exemplos.R` (32 figuras), 4.x e 3.5 | 32 PNG nas duas, sem erro |
| Navegador (Playwright): caixas móveis | 24 OK |
| Navegador: novos gráficos (PCA, CA, CCA, mapas, mapa de calor) | 17 OK |
| Navegador: Dashboard no app (3 abas, janela, editor, PDF pelo servidor, voltar ao último) | 15 OK |
| Navegador: editor do Dashboard (disposição, mover com guias, esticar, alinhar, desfazer, texto, identidade, retrato, HTML final, PDF) | 35 OK |
| Navegador: painéis/cartões/abas e arquivo grande/Sair | sem erro de página |
| Fuzz dos tipos novos (PCA, CA, CCA, mapa de calor, mapa-múndi, mapa do Brasil, boxplot, barras, pizza), todos os campos da tela com valores alternativos | ~13 mil combinações; 1 erro real (achado 2), o resto são avisos de validação em português |
| Casos extremos do Dashboard: 50 mil pontos, gradiente, figura anexada, coluna toda vazia, 2 linhas, 1 a 9 gráficos em paisagem e retrato, nome de aba/título com HTML e `<script>` | todos OK; nada executa, o texto aparece literal |
| `ferramentas/diagnostico_cinabro.R` | sem vazamento: memória e pasta temporária estáveis em 25 usos; todos os cenários abaixo de 1,3 s |
| CI do GitHub no Windows (motor 282/282, app 119/119, instalador compila, instala e desinstala, o app sobe pelo atalho) | verde no commit `dbac307` |

## 3. Achados e correções

| # | Gravidade | Achado | Correção |
|---|---|---|---|
| 1 | Média | `graficos_R_completo.R` (versão de arquivo único) estava atrás do motor (`R/24`) | Regenerado; agora é regenerado a cada mudança do motor (o CI do Windows também o gera) |
| 2 | Média | **Início ou fim do eixo em eixos de categorias** (barras, boxplot, mapa de calor) dava o erro `breaks and labels must have the same length` (em inglês, sem pista do que fazer) | O valor é ignorado com um aviso em português que diz por quê e o que fazer; teste novo no motor (achado pelo fuzz) |
| 3 | Baixa | Nome do PDF do Dashboard com acento: o `iconv` do Windows troca por `?` | `nome_de_arquivo()` troca por letra sem acento; teste novo |
| 4 | Baixa (desempenho) | Dispersão de 50 mil pontos: o SVG era montado e depois descartado (17 s) | Gráficos com muitos pontos vão direto como imagem leve (14 s só de desenho do ggplot); limites: 30 mil pontos em dispersão, 150 mil em linhas |
| 5 | Baixa | Ao cair para imagem, o usuário não era avisado | Aviso curto na montagem do Dashboard |
| 6 | Baixa | `Rplots.pdf` perdido na raiz do projeto (e dentro do ZIP) | Removido; entrou no `.gitignore` |
| 7 | Otimização | Imagens do manual com 7,1 MB | 2,5 MB sem diferença visível (PSNR acima de 40 dB; `ferramentas/manual/otimizar_imagens.py`); o PDF do manual caiu de 5,7 para 4,7 MB |
| 8 | Otimização | 32 PNG de saída de teste e a galeria de referência (1,9 MB) iam no ZIP | Ficam fora do ZIP (o `05_exemplos.R` as refaz) |
| 9 | Documentação | LEIAME dizia "24 páginas" e "capturar_1..5"; `VERSAO.txt` em 0.1.0 | Atualizados (35 páginas; `capturar_1..7`; versão 0.2.0) |
| 10 | Teste | Meu teste novo do achado 2 deixava um dispositivo gráfico aberto e quebrava outro teste | Corrigido (visto no motor, nas duas versões, e no CI do Windows) |
| 11 | Ferramenta | O arranjo de teste do arquivo único estava defasado em relação ao `06_testes.R` | Refeito a partir do `06_testes.R` atual |

**ZIP:** 9,7 MB e 200 arquivos antes da auditoria; **7,9 MB e 183 arquivos** depois.

## 4. Desempenho (medido nesta máquina de teste, sem outros processos)

- Montar o gráfico: 0,4 s (linhas), 0,3 s (barras), 0,8 s (ajuste + caixa + forma), 1,2 s (dois eixos + quebra, o cenário mais pesado).
- Ler os 745 campos da tela a cada alteração: 19,5 ms. HTML da página: 257 KB. Motor carrega em 0,7 s.
- Uso repetido (25 gráficos): memória do R estável em 138 MB; processo em 321 MB; pasta temporária estável (21 arquivos, 1 MB).
- Dashboard: 9 gráficos vetoriais em 6 s, página de 776 KB; 3 abas pelo app em 3,5 s; PDF pelo navegador em cerca de 6 s.

## 5. Segurança e robustez (parte nova)

- Nenhum texto vindo da planilha, do nome da aba ou do título entra na página como HTML: tudo passa por escape no R e no editor, e `</script>` dentro de um texto não fecha a página. Testado com `<img onerror>` e `<script>`: nada executa.
- O servidor só serve a pasta temporária do Dashboard (`/painel/`), e o nome do PDF é sanitizado.
- O Dashboard não usa internet: fonte Barlow, gráficos e editor vão dentro do HTML.
- O PDF usa um perfil temporário do navegador, separado do perfil do usuário, e cai para a janela de impressão se não houver Edge/Chrome.

## 6. O que o time deve conferir uma vez no Windows (não consigo provar daqui)

1. **Exportar PDF** do Dashboard em um computador real: o CI do Windows já gera o PDF pelo Edge dentro do `testes_app` (119/119), mas é uma máquina de CI, sem a política do antivírus e do navegador da empresa. Se não sair, o Cinabro abre a impressão do navegador (Salvar como PDF).
2. **Identidade institucional:** logo (PNG/JPEG) e duas cores no cabeçalho (testado no navegador de teste; vale uma olhada com o logo real).
3. Observação do CI: ao terminar, o Edge deixou processos auxiliares (`msedge`) que o próprio CI encerrou; no computador de um usuário eles somem sozinhos e o perfil temporário é apagado ao fechar o R. Se algum dia aparecer lentidão, é onde olhar.

## 7. O que ainda poderia ser otimizado (nenhum é defeito)

- **Dashboard, etapa 2** (veja `planejamento/DASHBOARD_PROPOSTA.html`): tabelas como bloco, tema preto e branco, modelos de disposição para o time, seleção por laço, atualizar o painel quando os dados mudam, painel interativo com filtros, salvar a disposição dentro do `.cinabro`.
- **PCA/CA/CCA com duas divisões ao mesmo tempo** (cor por uma coluna e símbolo por outra), hoje é uma coluna de grupo por gráfico (contornável com uma aba por divisão, como o manual ensina).
- **Manual:** o PDF tem 4,7 MB; baixar as capturas para 150 dpi o levaria a cerca de 3 MB. Há 10 capturas antigas em `manual/img/` que o texto não usa mais (só no repositório, não entram no ZIP).
- **Teste do arquivo único:** a falha do idioma é do arranjo; copiar `idiomas_arquivados/` para a pasta do teste a elimina.
- **CI:** rodar `dashboard_editor.js` (Playwright) no GitHub Actions daria uma proteção a mais para o editor do Dashboard.
- **Fuzz:** a bateria completa dos tipos novos leva cerca de 1 hora em 4 núcleos; vale rodá-la antes de versões grandes (`ferramentas/fuzz_tipos.R`, com instruções no cabeçalho).
