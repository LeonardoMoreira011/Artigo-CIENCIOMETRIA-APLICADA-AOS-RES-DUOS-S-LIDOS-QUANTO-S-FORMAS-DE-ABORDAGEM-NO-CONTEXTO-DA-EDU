# =============================================================================
#  R/02_paletas_dados.R — cores das paletas prontas (dados) e as licenças de cada fonte
# =============================================================================
#  Estas listas de cores vêm de trabalhos publicados com licença livre (veja também o arquivo NOTICE.md, na pasta
#  do projeto, que traz os avisos de cada licença):
#    brewer_*     ColorBrewer — Cynthia A. Brewer, Mark Harrower e The Pennsylvania State University (licença estilo Apache,
#                 http://colorbrewer.org). Mantenha o aviso de autoria ao redistribuir.
#    tol_*        Paul Tol, "Colour Schemes", SRON (https://personal.sron.nl/~pault/), licença BSD de 3 cláusulas.
#    cmo_*        cmocean — Kristen M. Thyng et al., 2016 (licença MIT).
#    crameri_*    Scientific Colour Maps — Fabio Crameri (licença MIT; https://doi.org/10.5281/zenodo.1243862).
#    Okabe-Ito    Masataka Okabe e Kei Ito, "Color Universal Design" (2002/2008): paleta publicada para daltonismo.
#    viridis etc. (viridis, magma, plasma, cividis, inferno, turbo, mako, rocket) vêm do pacote viridisLite (MIT/CC0), quando instalado.
#  As cores de degradê (brewer sequenciais/divergentes, tol_por_do_sol..., cmo_*, crameri_*) são os pontos de apoio da
#  paleta original: o motor interpola entre eles para dar quantas cores forem pedidas.
# =============================================================================
.PALETAS_DADOS <- list(
  brewer_Set1 = c("#E41A1C", "#377EB8", "#4DAF4A", "#984EA3", "#FF7F00", "#FFFF33", "#A65628", "#F781BF", "#999999"),
  brewer_Set2 = c("#66C2A5", "#FC8D62", "#8DA0CB", "#E78AC3", "#A6D854", "#FFD92F", "#E5C494", "#B3B3B3"),
  brewer_Dark2 = c("#1B9E77", "#D95F02", "#7570B3", "#E7298A", "#66A61E", "#E6AB02", "#A6761D", "#666666"),
  brewer_Paired = c("#A6CEE3", "#1F78B4", "#B2DF8A", "#33A02C", "#FB9A99", "#E31A1C", "#FDBF6F", "#FF7F00", "#CAB2D6", "#6A3D9A", "#FFFF99", "#B15928"),
  brewer_Accent = c("#7FC97F", "#BEAED4", "#FDC086", "#FFFF99", "#386CB0", "#F0027F", "#BF5B17", "#666666"),
  brewer_Pastel1 = c("#FBB4AE", "#B3CDE3", "#CCEBC5", "#DECBE4", "#FED9A6", "#FFFFCC", "#E5D8BD", "#FDDAEC", "#F2F2F2"),
  brewer_Pastel2 = c("#B3E2CD", "#FDCDAC", "#CBD5E8", "#F4CAE4", "#E6F5C9", "#FFF2AE", "#F1E2CC", "#CCCCCC"),
  brewer_Set3 = c("#8DD3C7", "#FFFFB3", "#BEBADA", "#FB8072", "#80B1D3", "#FDB462", "#B3DE69", "#FCCDE5", "#D9D9D9", "#BC80BD", "#CCEBC5", "#FFED6F"),
  brewer_Blues = c("#F7FBFF", "#DEEBF7", "#C6DBEF", "#9ECAE1", "#6BAED6", "#4292C6", "#2171B5", "#08519C", "#08306B"),
  brewer_Greens = c("#F7FCF5", "#E5F5E0", "#C7E9C0", "#A1D99B", "#74C476", "#41AB5D", "#238B45", "#006D2C", "#00441B"),
  brewer_Oranges = c("#FFF5EB", "#FEE6CE", "#FDD0A2", "#FDAE6B", "#FD8D3C", "#F16913", "#D94801", "#A63603", "#7F2704"),
  brewer_Reds = c("#FFF5F0", "#FEE0D2", "#FCBBA1", "#FC9272", "#FB6A4A", "#EF3B2C", "#CB181D", "#A50F15", "#67000D"),
  brewer_Purples = c("#FCFBFD", "#EFEDF5", "#DADAEB", "#BCBDDC", "#9E9AC8", "#807DBA", "#6A51A3", "#54278F", "#3F007D"),
  brewer_YlGnBu = c("#FFFFD9", "#EDF8B1", "#C7E9B4", "#7FCDBB", "#41B6C4", "#1D91C0", "#225EA8", "#253494", "#081D58"),
  brewer_YlOrRd = c("#FFFFCC", "#FFEDA0", "#FED976", "#FEB24C", "#FD8D3C", "#FC4E2A", "#E31A1C", "#BD0026", "#800026"),
  brewer_RdYlGn = c("#A50026", "#D73027", "#F46D43", "#FDAE61", "#FEE08B", "#FFFFBF", "#D9EF8B", "#A6D96A", "#66BD63", "#1A9850", "#006837"),
  brewer_Spectral = c("#9E0142", "#D53E4F", "#F46D43", "#FDAE61", "#FEE08B", "#FFFFBF", "#E6F598", "#ABDDA4", "#66C2A5", "#3288BD", "#5E4FA2"),
  brewer_RdYlBu = c("#A50026", "#D73027", "#F46D43", "#FDAE61", "#FEE090", "#FFFFBF", "#E0F3F8", "#ABD9E9", "#74ADD1", "#4575B4", "#313695"),
  brewer_RdBu = c("#67001F", "#B2182B", "#D6604D", "#F4A582", "#FDDBC7", "#F7F7F7", "#D1E5F0", "#92C5DE", "#4393C3", "#2166AC", "#053061"),
  brewer_BrBG = c("#543005", "#8C510A", "#BF812D", "#DFC27D", "#F6E8C3", "#F5F5F5", "#C7EAE5", "#80CDC1", "#35978F", "#01665E", "#003C30"),
  brewer_PiYG = c("#8E0152", "#C51B7D", "#DE77AE", "#F1B6DA", "#FDE0EF", "#F7F7F7", "#E6F5D0", "#B8E186", "#7FBC41", "#4D9221", "#276419"),
  brewer_PRGn = c("#40004B", "#762A83", "#9970AB", "#C2A5CF", "#E7D4E8", "#F7F7F7", "#D9F0D3", "#A6DBA0", "#5AAE61", "#1B7837", "#00441B"),
  tol_brilhante = c("#4477AA", "#EE6677", "#228833", "#CCBB44", "#66CCEE", "#AA3377", "#BBBBBB"),
  tol_alto_contraste = c("#004488", "#BB5566", "#DDAA33"),
  tol_vibrante = c("#EE7733", "#0077BB", "#33BBEE", "#EE3377", "#CC3311", "#009988", "#BBBBBB"),
  tol_suave = c("#CC6677", "#332288", "#DDCC77", "#117733", "#88CCEE", "#882255", "#44AA99", "#999933", "#AA4499"),
  tol_medio_contraste = c("#6699CC", "#004488", "#EECC66", "#997700", "#EE99AA", "#994455"),
  tol_claro = c("#77AADD", "#EE8866", "#EEDD88", "#FFAABB", "#99DDFF", "#44BB99", "#BBCC33", "#AAAA00", "#DDDDDD"),
  tol_escuro = c("#222255", "#663333", "#225522", "#666633", "#225555", "#555555"),
  tol_palido = c("#BBCCEE", "#FFCCCC", "#CCDDAA", "#EEEEBB", "#CCEEFF", "#DDDDDD"),
  tol_por_do_sol = c("#364B9A", "#5386BD", "#83B8D7", "#B8DEEC", "#EAECCB", "#FECF81", "#F99758", "#E24B33", "#A50026"),
  tol_iridescente = c("#FEFBE9", "#EDF1B8", "#C9E5CE", "#A4D6DD", "#81C4E7", "#86A8DE", "#9C83BA", "#8B5F80", "#46353A"),
  tol_BuRd = c("#2166AC", "#4393C3", "#92C5DE", "#D1E5F0", "#F7F7F6", "#FDDAC6", "#F3A381", "#D55E4C", "#B2182B"),
  cmo_thermal = c("#042333", "#19337C", "#563B9C", "#83508F", "#B15F82", "#DF7064", "#F99341", "#F9C641", "#E8FA5B"),
  cmo_haline = c("#2A186C", "#2034A2", "#0F5B90", "#297789", "#3C9387", "#50B07E", "#7ACB67", "#C4DD65", "#FDEF9A"),
  cmo_algae = c("#D7F9D0", "#AFDDA2", "#84C47A", "#50AD59", "#129450", "#0D7748", "#185B3B", "#193F29", "#122414"),
  cmo_matter = c("#FEEDB0", "#F9C187", "#F29567", "#E66A54", "#CE4356", "#AB2960", "#821C63", "#571756", "#2F0F3E"),
  cmo_deep = c("#FDFECC", "#BBE6AC", "#78CEA3", "#55AEA3", "#488E9E", "#3F6E97", "#404C8B", "#3B315A", "#281A2C"),
  cmo_balance = c("#181C43", "#2548B0", "#3888BA", "#98BAC5", "#F1ECEB", "#D7A290", "#BF573A", "#8D1029", "#3C0912"),
  cmo_delta = c("#112040", "#1C529D", "#3391A9", "#97C5BE", "#FFFCCC", "#C8BA43", "#5E910D", "#0B5E2D", "#172313"),
  cmo_curl = c("#151D44", "#1B5968", "#2D9580", "#A3C2A3", "#FDF5F4", "#E2A68E", "#C35861", "#841F60", "#340D35"),
  crameri_batlow = c("#011959", "#114360", "#226061", "#4D734D", "#828231", "#C09036", "#F29D6D", "#FDB4B6", "#FACCFA"),
  crameri_roma = c("#7E1700", "#9D5818", "#B68C32", "#D0CA72", "#C0EAC3", "#76D1D7", "#389CC6", "#2269B0", "#033198"),
  crameri_bam = c("#65024B", "#A5438C", "#D17FBC", "#ECC6E2", "#F6F1F0", "#D6E7BF", "#8AB363", "#4B7F2E", "#0D4C00"),
  crameri_vik = c("#001261", "#034481", "#307DA6", "#94BED2", "#ECE5E0", "#DBAA8D", "#C27041", "#912D06", "#590008"),
  crameri_lajolla = c("#191900", "#372411", "#67342A", "#A64644", "#D9604E", "#E58851", "#EDAE54", "#F7DA74", "#FFFECB"),
  crameri_bilbao = c("#4C0001", "#78292F", "#994E51", "#A36B59", "#A9825E", "#B19C67", "#BFB999", "#CFCEC9", "#FFFFFF"),
  crameri_oslo = c("#010101", "#0E1E2E", "#15395B", "#26578C", "#507BBC", "#7D99CA", "#A3B1CA", "#CFD2D8", "#FFFFFF"),
  crameri_lapaz = c("#1A0C64", "#24327E", "#2D5393", "#3D71A0", "#5C8CA3", "#869E9B", "#B5AD96", "#EBCFBB", "#FEF2F3"),
  crameri_hawaii = c("#8C0273", "#922E55", "#974E3E", "#9B6F28", "#9C961C", "#89BD4A", "#6BD48E", "#67E9D5", "#B3F2FD"),
  crameri_tokyo = c("#1C0E34", "#512446", "#6C4750", "#715D52", "#747053", "#798D57", "#87B867", "#BAEAA4", "#EFFCDD"),
  crameri_berlin = c("#9EB0FF", "#519FD3", "#286886", "#14303E", "#190C09", "#411201", "#7D341E", "#BE6F63", "#FFADAD")
)
