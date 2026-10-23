# =============================================================================
#  R/02_paletas_dados.R — cores das paletas prontas (dados) e as licenças de cada fonte
# =============================================================================
#  Estas listas de cores vêm de trabalhos publicados com licença livre (veja também o arquivo NOTICE.md, na pasta
#  do projeto, que traz os avisos de cada licença):
#    brewer_*     ColorBrewer — Cynthia A. Brewer, Mark Harrower e The Pennsylvania State University (licença estilo Apache,
#                 http://colorbrewer.org). Mantenha o aviso de autoria ao redistribuir.
#    cmo_*        cmocean — Kristen M. Thyng et al., 2016 (licença MIT).
#    crameri_*    Scientific Colour Maps — Fabio Crameri (licença MIT; https://doi.org/10.5281/zenodo.1243862).
#    magma, inferno e turbo vêm do pacote viridisLite (MIT/CC0), quando instalado.
#  As cores de degradê (brewer sequenciais/divergentes, cmo_*, crameri_*) são os pontos de apoio da
#  paleta original: o motor interpola entre eles para dar quantas cores forem pedidas.
# =============================================================================
.PALETAS_DADOS <- list(
  brewer_Reds = c("#FFF5F0", "#FEE0D2", "#FCBBA1", "#FC9272", "#FB6A4A", "#EF3B2C", "#CB181D", "#A50F15", "#67000D"),
  brewer_Purples = c("#FCFBFD", "#EFEDF5", "#DADAEB", "#BCBDDC", "#9E9AC8", "#807DBA", "#6A51A3", "#54278F", "#3F007D"),
  brewer_YlGnBu = c("#FFFFD9", "#EDF8B1", "#C7E9B4", "#7FCDBB", "#41B6C4", "#1D91C0", "#225EA8", "#253494", "#081D58"),
  brewer_YlOrRd = c("#FFFFCC", "#FFEDA0", "#FED976", "#FEB24C", "#FD8D3C", "#FC4E2A", "#E31A1C", "#BD0026", "#800026"),
  brewer_RdYlGn = c("#A50026", "#D73027", "#F46D43", "#FDAE61", "#FEE08B", "#FFFFBF", "#D9EF8B", "#A6D96A", "#66BD63", "#1A9850", "#006837"),
  brewer_Spectral = c("#9E0142", "#D53E4F", "#F46D43", "#FDAE61", "#FEE08B", "#FFFFBF", "#E6F598", "#ABDDA4", "#66C2A5", "#3288BD", "#5E4FA2"),
  cmo_algae = c("#D7F9D0", "#AFDDA2", "#84C47A", "#50AD59", "#129450", "#0D7748", "#185B3B", "#193F29", "#122414"),
  crameri_oslo = c("#010101", "#0E1E2E", "#15395B", "#26578C", "#507BBC", "#7D99CA", "#A3B1CA", "#CFD2D8", "#FFFFFF")
)
