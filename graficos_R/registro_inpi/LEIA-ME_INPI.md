# Registro do Cinabro no INPI (programa de computador): roteiro e textos prontos

> Isto é um roteiro prático, **não é parecer jurídico**. Confira valores e telas no site do INPI (gov.br/inpi, "Programas de computador") antes de pagar e enviar. Esta pasta não vai no ZIP do programa (fica só no repositório).

## 0. Antes de começar

1. **Titular.** Você escolheu pedir **em seu nome (pessoa física)**. Isso só é seguro se o Cinabro **não foi feito dentro das suas atividades na empresa/instituição** (equipamento, horário, atribuição do cargo). Se foi, o titular pode ser o empregador: confirme por escrito com o jurídico ou o NIT antes de enviar.
2. **Autoria e IA.** O pedido leva uma **Declaração de Veracidade**: quem assina responde pelo que declara. Declare o que é verdade (veja o texto na seção 4): concepção, direção, revisão e testes são seus; o código foi desenvolvido com assistência de IA generativa. Guarde o histórico do git e as conversas: são a prova da sua contribuição.
3. **O que o registro dá:** prova de data e de autoria declarada, certificado em seu nome, validade de 50 anos. **O que não dá:** exclusividade garantida nem proteção do **nome** ou do **emblema** (isso é pedido de **marca**, à parte).

## 1. O que você precisa ter em mãos

- **Login no e-INPI** (cadastro de pessoa física no portal do INPI). É pré-requisito do serviço.
- **Certificado digital ICP-Brasil** (ou assinatura que o INPI aceite no e-Software) para assinar a Declaração de Veracidade.
- **O hash** (resumo criptográfico) da versão do programa: veja a seção 3. O INPI **não recebe o código-fonte**: só o hash.
- **GRU paga** (guia do serviço "Pedido de Registro de Programa de Computador", código 730). A página oficial listava R$ 210,00; a tabela mudou em 20/12/2025, então confira o valor e se existe desconto para você.

## 2. Passo a passo

1. Entre no e-INPI e gere a **GRU** do "Pedido de Registro de Programa de Computador (RPC), por meio eletrônico, e-Software". Pague.
2. Abra o **e-Software** e preencha o formulário com os dados da seção 4.
3. Informe o **hash** (algoritmo SHA-512, se a lista oferecer) e anexe a **Declaração de Veracidade** assinada digitalmente.
4. Envie e guarde o **número do pedido**. O certificado sai com o despacho de concessão.
5. Depois de concedido, acrescente o número do registro no `LEIAME.md` e faça uma nova versão no repositório.

## 3. Como gerar o hash da versão

> **Atenção:** a versão **0.3.0** (idiomas em inglês e espanhol e gráficos 3D) tem um `Cinabro.zip` novo, portanto um **hash novo**. Se o pedido ainda não foi enviado, use o hash do ZIP desta versão; se já foi, o registro anterior vale para a 0.2.0 e a 0.3.0 pode ser incluída num pedido de nova versão.

O hash prova **qual era o conteúdo do programa naquela data**. Use sempre o **mesmo arquivo** que vai ser distribuído:

- Pegue o **`Cinabro.zip`** da versão e gere o SHA-512 dele.
  - **Windows:** `certutil -hashfile Cinabro.zip SHA512` (no Prompt de Comando, na pasta do arquivo).
  - **Linux/macOS:** `sha512sum Cinabro.zip` (ou `shasum -a 512 Cinabro.zip`).
- Anote o hash (128 caracteres), o **nome do arquivo**, o **tamanho** e a **data**. Guarde uma **cópia do `Cinabro.zip` exato** em um lugar seguro (nuvem, disco externo): sem o arquivo, o hash não prova nada.
- Se você alterar o programa depois, é outra versão, com outro hash. Mudanças pequenas não exigem novo registro; mudanças grandes (novas funções importantes) podem exigir um novo pedido.

## 4. Textos prontos para o formulário

| Campo | Sugestão |
|---|---|
| **Título** | Cinabro: laboratório de gráficos científicos |
| **Versão** | 0.3.0 |
| **Linguagem de programação** | R (com HTML, CSS e JavaScript no aplicativo no navegador) |
| **Data de criação** | A sua. O primeiro registro no controle de versão é de 21/10/2026; se o trabalho começou antes, use a data real. |
| **Publicação** | Informe a data só se já divulgou o programa publicamente (repositório público, e-mail a terceiros). |
| **Programa derivado?** | Não. (O Cinabro usa pacotes de terceiros de código aberto, sem alterá-los: ggplot2, shiny, vegan, sf e outros, listados em `NOTICE.md`.) |
| **Tipo / campo de aplicação** | Escolha, nas listas do formulário, o mais próximo de "aplicativo" e "pesquisa científica / visualização de dados". |
| **Titular / autor** | Leonardo Moreira (pessoa física) |

**Resumo do programa (para o campo de descrição):**
> O Cinabro é um programa em R, com aplicativo no navegador e interface em português, inglês e espanhol, que transforma planilhas CSV em figuras científicas editáveis: gráficos de linhas, pontos, áreas, barras com barras de erro, pizza, histograma, densidade, boxplot, mapa de calor, PCA, CA e CCA, mapa-múndi, mapa do Brasil, mapa de cor (X, Y, Z), superfície 3D, barras 3D e dispersão 3D. Oferece ajuste de curva com equação e R², média ± desvio padrão, testes estatísticos (normalidade, ANOVA, Kruskal-Wallis), edição visual de legenda, rótulos e caixas de texto e estatística, um Dashboard que reúne os gráficos e os resumos numa folha editável e a exportação em PNG, TIFF, JPEG, SVG e PDF.

**Texto sugerido para a Declaração de Veracidade / descrição da autoria** (ajuste ao que for verdade para você):
> O programa foi concebido e especificado por Leonardo Moreira, que definiu os requisitos, as funcionalidades e o comportamento do sistema, tomou as decisões de design, revisou e testou o resultado. O código-fonte foi desenvolvido com a assistência de ferramentas de inteligência artificial generativa (Claude, da Anthropic), sob a direção e a revisão do autor. O programa utiliza, sem alteração, pacotes de código aberto de terceiros, com os avisos de licença preservados.

## 5. Para os amigos cientistas poderem citar (sem esperar o INPI)

1. **Licença e citação já estão no projeto:** `LICENSE` (MIT) e `CITATION.cff`.
2. **DOI com a sua autoria e a data:** publique o repositório (público) no GitHub e ative a integração do **Zenodo** (zenodo.org, login com o GitHub). A cada versão publicada (release), o Zenodo gera um DOI citável. Depois coloque o DOI em `CITATION.cff` e no `LEIAME.md`.
3. **Se quiser publicar um artigo sobre o programa:** revistas como *Journal of Open Source Software* e *SoftwareX* aceitam softwares científicos (exigem repositório público, licença aberta, testes e documentação, que o Cinabro já tem).

## 6. Marca (nome e emblema), se um dia quiser

O registro de software **não** protege o nome "Cinabro" nem o emblema. Para isso há o **pedido de marca** no INPI (outro serviço, com busca de anterioridade e prazo maior). Como "cinabro" é também o nome de um mineral, a proteção do nome pode ser mais fraca; o emblema (desenho) costuma proteger melhor.
