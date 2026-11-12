# =============================================================================
#  R/02_paletas_dados.R — cores das paletas prontas (dados) e as licenças de cada fonte
# =============================================================================
#  Estas listas de cores vêm de trabalhos publicados com licença livre (veja também o arquivo NOTICE.md, na pasta
#  do projeto, que traz os avisos de cada licença):
#    brewer_*     ColorBrewer — Cynthia A. Brewer, Mark Harrower e The Pennsylvania State University (licença estilo Apache,
#                 http://colorbrewer.org). Mantenha o aviso de autoria ao redistribuir.
#    cmo_*        cmocean — Kristen M. Thyng et al., 2016 (licença MIT).
#    crameri_*    Scientific Colour Maps — Fabio Crameri (licença MIT; https://doi.org/10.5281/zenodo.1243862).
#    viridis, magma, plasma, cividis, inferno, turbo, mako e rocket vêm do pacote viridisLite (MIT/CC0), quando instalado.
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
  crameri_oslo = c("#010101", "#0E1E2E", "#15395B", "#26578C", "#507BBC", "#7D99CA", "#A3B1CA", "#CFD2D8", "#FFFFFF"),
  brewer_Blues = c("#F7FBFF", "#DEEBF7", "#C6DBEF", "#9ECAE1", "#6BAED6", "#4292C6", "#2171B5", "#08519C", "#08306B"),
  brewer_Greens = c("#F7FCF5", "#E5F5E0", "#C7E9C0", "#A1D99B", "#74C476", "#41AB5D", "#238B45", "#006D2C", "#00441B"),
  brewer_Oranges = c("#FFF5EB", "#FEE6CE", "#FDD0A2", "#FDAE6B", "#FD8D3C", "#F16913", "#D94801", "#A63603", "#7F2704"),
  brewer_RdYlBu = c("#A50026", "#D73027", "#F46D43", "#FDAE61", "#FEE090", "#FFFFBF", "#E0F3F8", "#ABD9E9", "#74ADD1", "#4575B4", "#313695"),
  brewer_RdBu = c("#67001F", "#B2182B", "#D6604D", "#F4A582", "#FDDBC7", "#F7F7F7", "#D1E5F0", "#92C5DE", "#4393C3", "#2166AC", "#053061"),
  brewer_BrBG = c("#543005", "#8C510A", "#BF812D", "#DFC27D", "#F6E8C3", "#F5F5F5", "#C7EAE5", "#80CDC1", "#35978F", "#01665E", "#003C30"),
  brewer_PiYG = c("#8E0152", "#C51B7D", "#DE77AE", "#F1B6DA", "#FDE0EF", "#F7F7F7", "#E6F5D0", "#B8E186", "#7FBC41", "#4D9221", "#276419"),
  cmo_thermal = c("#042333", "#19337C", "#563B9C", "#83508F", "#B15F82", "#DF7064", "#F99341", "#F9C641", "#E8FA5B"),
  cmo_haline = c("#2A186C", "#2034A2", "#0F5B90", "#297789", "#3C9387", "#50B07E", "#7ACB67", "#C4DD65", "#FDEF9A"),
  cmo_deep = c("#FDFECC", "#BBE6AC", "#78CEA3", "#55AEA3", "#488E9E", "#3F6E97", "#404C8B", "#3B315A", "#281A2C"),
  crameri_batlow = c("#011959", "#114360", "#226061", "#4D734D", "#828231", "#C09036", "#F29D6D", "#FDB4B6", "#FACCFA")
)
