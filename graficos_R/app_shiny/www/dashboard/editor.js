/* Dashboard do Cinabro — editor da folha (mover, esticar, alinhar, desfazer), HTML final e PDF.
   A página é autônoma: o estado (layout) e os gráficos vão dentro dela. */
(function () {
  'use strict';
  var raiz = document.documentElement;
  var E = JSON.parse(document.getElementById('estado').textContent);
  var GRAF_EL = document.getElementById('graficos');
  var GRAF_TXT = GRAF_EL ? GRAF_EL.textContent : '[]';
  E.graficos = JSON.parse(GRAF_TXT || '[]');
  var FORMATOS = { a4h: { w: 297, h: 210, nome: 'A4 paisagem' }, a4v: { w: 210, h: 297, nome: 'A4 retrato' } };
  var CAB_MM = 22, ROD_MM = 9, MARG_MM = 8, GAP_MM = 4, GRADE_MM = 5;
  var modo = raiz.getAttribute('data-modo') || 'editar';
  var sel = [], pagAtual = 0, zoom = 'ajustar', escala = 1, seq = 0, hist = [], hpos = -1, arrasto = null;
  var emApp = false; try { emApp = window.parent !== window && !!window.parent.Shiny; } catch (e) { emApp = false; }
  var app = document.getElementById('app'), tela = null, lateral = null, props = null;

  // ---- utilidades ------------------------------------------------------------------------------------------------------------------
  function el(tag, cls, html) { var d = document.createElement(tag); if (cls) d.className = cls; if (html != null) d.innerHTML = html; return d; }
  function esc(t) { return String(t == null ? '' : t).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;'); }
  function F() { return FORMATOS[E.formato] || FORMATOS.a4h; }
  function mmx(v) { return v / F().w; } function mmy(v) { return v / F().h; }
  function mm1(v) { return Math.round(v * 10) / 10; }
  function ref(id) { for (var i = 0; i < E.graficos.length; i++) if (E.graficos[i].id === id) return E.graficos[i]; return null; }
  function bloco(id) { for (var p = 0; p < E.paginas.length; p++) for (var i = 0; i < E.paginas[p].blocos.length; i++) if (E.paginas[p].blocos[i].id === id) return E.paginas[p].blocos[i]; return null; }
  function paginaDe(id) { for (var p = 0; p < E.paginas.length; p++) for (var i = 0; i < E.paginas[p].blocos.length; i++) if (E.paginas[p].blocos[i].id === id) return p; return -1; }
  function novoId() { return 'b' + (++seq); }
  function novo(tipo, o) { var b = { id: novoId(), tipo: tipo, borda: 'fina' }; for (var k in o) b[k] = o[k]; return b; }
  function toast(msg, erro) { var t = el('div', 'toast' + (erro ? ' erro' : ''), esc(msg)); document.body.appendChild(t); setTimeout(function () { t.remove(); }, erro ? 6000 : 3200); }
  function lum(h) { var m = /^#?([0-9a-f]{2})([0-9a-f]{2})([0-9a-f]{2})$/i.exec(h || ''); if (!m) return 0; var c = [1, 2, 3].map(function (i) { return parseInt(m[i], 16) / 255; }); return 0.2126 * c[0] + 0.7152 * c[1] + 0.0722 * c[2]; }
  function pct(v) { return (v * 100).toFixed(4) + '%'; }
  function limitar(v, a, b) { return Math.max(a, Math.min(b, v)); }

  // ---- estado padrão -----------------------------------------------------------------------------------------------------------
  E.formato = FORMATOS[E.formato] ? E.formato : 'a4h';
  if (E.cab === undefined) E.cab = true; if (E.grade === undefined) E.grade = true; if (E.guias === undefined) E.guias = true;
  E.paginas = E.paginas || []; E.identidade = E.identidade || { modo: 'cinabro' };
  E.titulo = E.titulo == null ? 'Painel de acompanhamento' : E.titulo; E.subtitulo = E.subtitulo == null ? '' : E.subtitulo; E.rodape = E.rodape == null ? 'Cinabro' : E.rodape;
  E.paginas.forEach(function (p) { p.blocos.forEach(function (b) { var n = parseInt(String(b.id).replace(/\D/g, ''), 10); if (n > seq) seq = n; }); });

  // ---- identidade: cores padrão do Cinabro ou logo e cores da instituição --------------------------------------------------------------
  var LS = 'cinabro.dashboard.identidade';
  function lerIdentidadeSalva() { try { var t = window.localStorage.getItem(LS); return t ? JSON.parse(t) : null; } catch (e) { return null; } }
  function guardarIdentidade() { try { window.localStorage.setItem(LS, JSON.stringify(E.identidade)); } catch (e) { /* sem armazenamento: tudo bem */ } }
  function aplicarIdentidade() {
    var I = E.identidade, s = raiz.style, nomes = ['--cab', '--cab-texto', '--cab-sub', '--dest', '--tit'];
    if (I.modo === 'institucional') {
      var cp = I.cor_principal || '#20242B', cd = I.cor_destaque || '#B3262E', claro = lum(cp) > 0.6;
      s.setProperty('--cab', cp); s.setProperty('--dest', cd); s.setProperty('--cab-texto', claro ? '#20242B' : '#fff');
      s.setProperty('--cab-sub', claro ? 'rgba(32,36,43,.75)' : 'rgba(255,255,255,.8)'); s.setProperty('--tit', lum(cp) < 0.75 ? cp : cd);
    } else nomes.forEach(function (n) { s.removeProperty(n); });
  }

  // ---- disposição automática -------------------------------------------------------------------------------------------------------------
  function area() {
    var f = F(), y0 = (E.cab ? CAB_MM : 0) + MARG_MM * 0.75;
    return { x0: MARG_MM / f.w, x1: 1 - MARG_MM / f.w, y0: y0 / f.h, y1: 1 - (ROD_MM + MARG_MM * 0.6) / f.h };
  }
  function celulas(k, r) {
    var gx = mmx(GAP_MM), gy = mmy(GAP_MM), larga = r.w * F().w >= r.h * F().h * 1.1;
    function grade(c, l) { var cw = (r.w - gx * (c - 1)) / c, ch = (r.h - gy * (l - 1)) / l, o = []; for (var i = 0; i < l; i++) for (var j = 0; j < c; j++) o.push({ x: r.x + j * (cw + gx), y: r.y + i * (ch + gy), w: cw, h: ch }); return o; }
    if (k <= 1) return grade(1, 1);
    if (k === 2) return larga ? grade(2, 1) : grade(1, 2);
    if (k === 3) { var cw = (r.w - gx) / 2, ch = (r.h - gy) / 2;
      return larga ? [{ x: r.x, y: r.y, w: cw, h: r.h }, { x: r.x + cw + gx, y: r.y, w: cw, h: ch }, { x: r.x + cw + gx, y: r.y + ch + gy, w: cw, h: ch }]
                   : [{ x: r.x, y: r.y, w: r.w, h: ch }, { x: r.x, y: r.y + ch + gy, w: cw, h: ch }, { x: r.x + cw + gx, y: r.y + ch + gy, w: cw, h: ch }]; }
    if (k === 4) return grade(2, 2);
    return larga ? grade(3, 2) : grade(2, 3);
  }
  function blocoGrafico(g, c) { return novo('grafico', { ref: g.id, titulo: g.nome, x: c.x, y: c.y, w: c.w, h: c.h }); }
  function autoLayout() {
    var gs = E.graficos || [], A = area(), larga = E.formato !== 'a4v', frases = [];
    var resto = gs.slice(), p1 = { blocos: [] }, primeiros = resto.splice(0, Math.min(resto.length, 4));       // a 1ª página leva os 4 primeiros gráficos, com os números-chave e os destaques deles
    var kp = primeiros.filter(function (g) { return g.kpi; }), lim = Math.min(4, Math.max(2, Math.floor(8 / Math.max(primeiros.length, 1))));
    primeiros.forEach(function (g) { (g.frases || []).slice(0, lim).forEach(function (t) { frases.push(t); }); });
    var esq = A.x0, dir = A.x1, topo = A.y0, gx = mmx(GAP_MM), gy = mmy(GAP_MM);
    if (frases.length && larga) { var wd = mmx(78); p1.blocos.push(novo('destaques', { x: A.x1 - wd, y: A.y0, w: wd, h: A.y1 - A.y0, itens: frases })); dir = A.x1 - wd - gx; }
    if (kp.length) { var kh = mmy(larga ? 26 : 24), kw = (dir - esq - gx * (kp.length - 1)) / kp.length;
      kp.forEach(function (g, i) { p1.blocos.push(novo('kpi', { x: esq + i * (kw + gx), y: topo, w: kw, h: kh, valor: g.kpi.valor, rotulo: g.kpi.rotulo })); }); topo += kh + gy; }
    if (frases.length && !larga) { var dh = Math.min(mmy(75), mmy(14 + 9 * frases.length)); p1.blocos.push(novo('destaques', { x: esq, y: topo, w: dir - esq, h: dh, itens: frases })); topo += dh + gy; }
    var cs = celulas(primeiros.length, { x: esq, y: topo, w: dir - esq, h: A.y1 - topo });
    primeiros.forEach(function (g, i) { p1.blocos.push(blocoGrafico(g, cs[i])); });
    var paginas = [p1];
    while (resto.length) { var lote = resto.splice(0, 6), cc = celulas(lote.length, { x: A.x0, y: A.y0, w: A.x1 - A.x0, h: A.y1 - A.y0 }), p = { blocos: [] };
      lote.forEach(function (g, i) { p.blocos.push(blocoGrafico(g, cc[i])); }); paginas.push(p); }
    if (!gs.length) p1.blocos.push(novo('texto', { x: A.x0, y: A.y0, w: A.x1 - A.x0, h: mmy(30), html: 'Nenhum gráfico. Volte ao Cinabro, carregue os dados de uma aba e monte o dashboard de novo.', tam: 16 }));
    E.paginas = paginas; sel = []; pagAtual = 0;
  }

  // ---- histórico (desfazer / refazer) -------------------------------------------------------------------------------------------------------
  function snap() { var c = {}; for (var k in E) if (k !== 'graficos') c[k] = E[k]; return JSON.stringify(c); }
  function commit() { var s = snap(); if (hist[hpos] === s) return; hist = hist.slice(0, hpos + 1); hist.push(s); if (hist.length > 100) hist.shift(); hpos = hist.length - 1; botoesHist(); }
  function restaurar(s) { var o = JSON.parse(s); for (var k in o) E[k] = o[k]; sel = sel.filter(function (id) { return !!bloco(id); }); if (pagAtual >= E.paginas.length) pagAtual = E.paginas.length - 1; tudo(); }
  function desfazer() { if (hpos > 0) { hpos--; restaurar(hist[hpos]); } }
  function refazer() { if (hpos < hist.length - 1) { hpos++; restaurar(hist[hpos]); } }
  function botoesHist() { var a = document.getElementById('bt-desfazer'), b = document.getElementById('bt-refazer'); if (a) a.disabled = hpos <= 0; if (b) b.disabled = hpos >= hist.length - 1; }

  // ---- desenho da folha ---------------------------------------------------------------------------------------------------------------
  var NOMES_TIPO = { grafico: 'Gráfico', kpi: 'Número-chave', destaques: 'Destaques', texto: 'Texto', imagem: 'Imagem', resumo: 'Resumo estatístico' };
  function conteudoBloco(b, d, fora) {
    var tam = b.tam ? 'font-size:' + b.tam + 'px;' : '';
    function titulo(padrao) { var t = b.titulo == null ? padrao : b.titulo; if (t === '') return null; var e = el('div', 'bk-t', esc(t)); e.setAttribute('data-edit', 'titulo'); d.appendChild(e); return e; }
    if (b.tipo === 'grafico') { var g = ref(b.ref); titulo(g ? g.nome : ''); var c = el('div', 'bk-c');
      if (!g) c.textContent = '(gráfico não encontrado)'; else if (g.formato === 'svg') c.innerHTML = g.conteudo; else { var im = el('img'); im.src = g.conteudo; im.draggable = false; c.appendChild(im); }
      d.appendChild(c); }
    else if (b.tipo === 'kpi') { var n = el('div', 'n', esc(b.valor)); n.setAttribute('data-edit', 'valor'); if (b.cor) n.style.color = b.cor; var r = el('div', 'd', esc(b.rotulo)); r.setAttribute('data-edit', 'rotulo'); d.appendChild(n); d.appendChild(r); }
    else if (b.tipo === 'destaques') { titulo('Destaques'); var ul = el('ul'); ul.setAttribute('style', tam); (b.itens || []).forEach(function (t) { ul.appendChild(el('li', null, t)); }); if (!ul.children.length) ul.appendChild(el('li', null, '')); ul.setAttribute('data-edit', 'itens'); d.appendChild(ul); }
    else if (b.tipo === 'resumo') { titulo('Resumo estatístico'); var l = el('div', 'lin'); l.setAttribute('style', tam); (b.linhas || []).forEach(function (t) { l.appendChild(el('div', null, esc(t))); }); l.setAttribute('data-edit', 'linhas'); d.appendChild(l); }
    else if (b.tipo === 'texto') { var t2 = el('div', null, b.html || ''); t2.setAttribute('data-edit', 'html'); t2.setAttribute('style', 'font-size:' + (b.tam || 14) + 'px;text-align:' + (b.alinh || 'left') + ';' + (b.cor ? 'color:' + b.cor + ';' : '') + (b.negrito ? 'font-weight:700;' : '')); d.appendChild(t2); }
    else if (b.tipo === 'imagem') { if (b.src) { var i2 = el('img'); i2.src = b.src; i2.draggable = false; d.appendChild(i2); } else { fora.className += ' vazio-img'; d.textContent = 'Imagem: escolha o arquivo no painel da direita'; } }
  }
  function elBloco(b) {
    var d = el('div', 'bk ' + b.tipo + ' b-' + (b.borda || 'fina') + (b.travado ? ' trava' : '') + (sel.indexOf(b.id) >= 0 ? ' sel' : '') + (sel.length === 1 && sel[0] === b.id ? ' unico' : ''));
    d.setAttribute('data-id', b.id); d.style.left = pct(b.x); d.style.top = pct(b.y); d.style.width = pct(b.w); d.style.height = pct(b.h);
    var inn = el('div', 'bk-in'); d.appendChild(inn); conteudoBloco(b, inn, d);
    if (modo === 'editar') { ['nw', 'n', 'ne', 'e', 'se', 's', 'sw', 'w'].forEach(function (h) { var a = el('i', 'alca'); a.setAttribute('data-h', h); d.appendChild(a); }); d.appendChild(el('span', 'selo', NOMES_TIPO[b.tipo] + (b.travado ? ' · travado' : ''))); }
    return d;
  }
  function elFolha(p, i) {
    var f = F(), fo = el('div', 'folha'); fo.setAttribute('data-p', i);
    if (modo === 'editar' && E.grade) fo.appendChild(el('div', 'grade-fundo'));
    if (E.cab) { var cab = el('div', 'cab'); cab.style.height = CAB_MM + 'mm';
      var t = el('div', 't', esc(E.titulo)); t.setAttribute('data-edit', 'cab-titulo'); cab.appendChild(t);
      var s = el('div', 's', esc(E.subtitulo)); s.setAttribute('data-edit', 'cab-sub'); cab.appendChild(s);
      if (E.identidade.modo === 'institucional' && E.identidade.logo && E.identidade.mostrar_logo !== false) { var lg = el('img'); lg.src = E.identidade.logo; lg.draggable = false; cab.appendChild(lg); }
      fo.appendChild(cab); }
    var rod = el('div', 'rod'); rod.style.height = ROD_MM + 'mm';
    var r1 = el('span', null, esc(E.rodape)); r1.setAttribute('data-edit', 'rodape'); rod.appendChild(r1); rod.appendChild(el('span', null, 'página ' + (i + 1) + ' de ' + E.paginas.length)); fo.appendChild(rod);
    p.blocos.forEach(function (b) { fo.appendChild(elBloco(b)); });
    return fo;
  }
  function desenharFolhas() {
    if (!tela) return; var rolagem = tela.scrollTop; tela.innerHTML = '';
    raiz.style.setProperty('--wmm', F().w); raiz.style.setProperty('--hmm', F().h);
    document.getElementById('pagina-css').textContent = '@page{size:' + F().w + 'mm ' + F().h + 'mm;margin:0}';
    E.paginas.forEach(function (p, i) {
      var w = el('div', 'pagina-wrap'), rot = el('div', 'pagina-rot', 'Página ' + (i + 1));
      if (modo === 'editar') { if (E.paginas.length > 1) { var x = el('button', null, 'excluir esta página'); x.onclick = function () { if (window.confirm('Excluir a página ' + (i + 1) + ' e o que há nela?')) { E.paginas.splice(i, 1); sel = []; pagAtual = Math.max(0, Math.min(pagAtual, E.paginas.length - 1)); commit(); tudo(); } }; rot.appendChild(x); } w.appendChild(rot); }
      var esc1 = el('div', 'escala'); esc1.appendChild(elFolha(p, i)); w.appendChild(esc1); tela.appendChild(w);
    });
    ajustarEscala(); tela.scrollTop = rolagem;
  }
  function ajustarEscala() {
    var f = F(), wpx = f.w * 96 / 25.4, hpx = f.h * 96 / 25.4, disp = (modo === 'editar' ? tela.clientWidth - 44 : document.documentElement.clientWidth - 24);
    if (modo === 'pdf') escala = 1; else escala = zoom === 'ajustar' ? Math.min(modo === 'editar' ? 1.25 : 1.6, Math.max(0.2, disp / wpx)) : zoom;
    var es = document.querySelectorAll('.escala'); for (var i = 0; i < es.length; i++) { es[i].style.width = wpx * escala + 'px'; es[i].style.height = hpx * escala + 'px'; es[i].firstChild.style.transform = 'scale(' + escala + ')'; }
    var z = document.getElementById('sel-zoom'); if (z) z.value = zoom === 'ajustar' ? 'ajustar' : String(zoom);
  }

  // ---- barra, biblioteca de blocos e propriedades --------------------------------------------------------------------------------------------
  function botao(txt, id, fn, cls) { var b = el('button', cls || 'bt', txt); if (id) b.id = id; b.type = 'button'; b.onclick = fn; return b; }
  function montarUI() {
    app.innerHTML = '';
    if (modo !== 'editar') {
      tela = el('div', 'tela'); app.appendChild(tela);
      if (modo === 'ver') { var be = botao('✎ Editar', null, function () { modo = 'editar'; raiz.setAttribute('data-modo', 'editar'); montarUI(); }, 'btn-editar'); document.body.appendChild(be); }
      return;
    }
    var old = document.querySelector('.btn-editar'); if (old) old.remove();
    if (!hist.length) { hist = [snap()]; hpos = 0; }
    var barra = el('div', 'barra'); barra.appendChild(el('span', 'marca', '▦ Dashboard'));
    var fm = el('select'); fm.id = 'sel-formato'; Object.keys(FORMATOS).forEach(function (k) { var o = el('option', null, FORMATOS[k].nome); o.value = k; fm.appendChild(o); }); fm.value = E.formato;
    fm.title = 'Formato da página'; fm.onchange = function () { mudarFormato(fm.value); }; barra.appendChild(fm);
    barra.appendChild(botao('Identidade ▾', 'bt-ident', function (ev) { ev.stopPropagation(); abrirIdentidade(); }));
    barra.appendChild(botao('Grade ' + (E.grade ? '✓' : ''), 'bt-grade', function () { E.grade = !E.grade; commit(); tudo(); }, 'bt' + (E.grade ? ' on' : '')));
    barra.appendChild(botao('Guias ' + (E.guias ? '✓' : ''), 'bt-guias', function () { E.guias = !E.guias; commit(); tudo(); }, 'bt' + (E.guias ? ' on' : '')));
    barra.appendChild(botao('↶ Desfazer', 'bt-desfazer', desfazer)); barra.appendChild(botao('↷ Refazer', 'bt-refazer', refazer));
    var z = el('select'); z.id = 'sel-zoom'; z.title = 'Zoom (Ctrl + roda do mouse)'; [['ajustar', 'Ajustar'], ['0.5', '50%'], ['0.75', '75%'], ['1', '100%'], ['1.25', '125%']].forEach(function (a) { var o = el('option', null, a[1]); o.value = a[0]; z.appendChild(o); });
    z.onchange = function () { zoom = z.value === 'ajustar' ? 'ajustar' : parseFloat(z.value); ajustarEscala(); }; barra.appendChild(z);
    barra.appendChild(el('span', 'sep'));
    barra.appendChild(botao('Salvar HTML', 'bt-html', salvarHTML)); barra.appendChild(botao('Exportar PDF', 'bt-pdf', exportarPDF, 'bt forte'));
    if (emApp) barra.appendChild(botao('Voltar ao Cinabro', 'bt-voltar', function () { try { window.parent.cinabroDashFechar(); } catch (e) { /* fora do app */ } }));
    app.appendChild(barra);
    var corpo = el('div', 'corpo-ed'); lateral = el('div', 'lateral'); tela = el('div', 'tela'); props = el('div', 'props');
    corpo.appendChild(lateral); corpo.appendChild(tela); corpo.appendChild(props); app.appendChild(corpo);
    tela.addEventListener('pointerdown', aoApertar); tela.addEventListener('dblclick', aoDuploClique);
    tela.addEventListener('wheel', function (ev) { if (ev.ctrlKey) { ev.preventDefault(); var z0 = zoom === 'ajustar' ? escala : zoom; zoom = limitar(Math.round((z0 + (ev.deltaY < 0 ? 0.1 : -0.1)) * 20) / 20, 0.3, 2); ajustarEscala(); } }, { passive: false });
    tudo();
  }
  function tudo() { if (modo === 'editar') { var g = document.getElementById('bt-grade'), u = document.getElementById('bt-guias'); if (g) { g.textContent = 'Grade ' + (E.grade ? '✓' : ''); g.className = 'bt' + (E.grade ? ' on' : ''); } if (u) { u.textContent = 'Guias ' + (E.guias ? '✓' : ''); u.className = 'bt' + (E.guias ? ' on' : ''); } var f = document.getElementById('sel-formato'); if (f) f.value = E.formato; }
    aplicarIdentidade(); desenharFolhas(); if (modo === 'editar') { desenharLateral(); desenharProps(); botoesHist(); } }
  function item(cor, sinal, nome, nota, fn, off) { var b = el('button', 'item'); b.type = 'button'; b.innerHTML = '<i style="background:' + cor + '">' + sinal + '</i><span class="nome">' + esc(nome) + '</span>' + (nota ? '<small>' + esc(nota) + '</small>' : ''); b.onclick = fn; if (off) b.style.opacity = 0.6; return b; }
  function desenharLateral() {
    lateral.innerHTML = ''; lateral.appendChild(el('h4', null, 'Blocos'));
    lateral.appendChild(item('#B3262E', '#', 'Número-chave', '', function () { adicionar('kpi'); }));
    lateral.appendChild(item('#C96A4A', '≡', 'Destaques', '', function () { adicionar('destaques'); }));
    lateral.appendChild(item('#6B6358', 'T', 'Texto livre', '', function () { adicionar('texto'); }));
    lateral.appendChild(item('#8A7A5C', '▣', 'Imagem / logo', '', function () { adicionar('imagem'); }));
    lateral.appendChild(el('h4', null, 'Gráficos das abas'));
    var colocados = {}; E.paginas.forEach(function (p) { p.blocos.forEach(function (b) { if (b.tipo === 'grafico') colocados[b.ref] = (colocados[b.ref] || 0) + 1; }); });
    E.graficos.forEach(function (g) { lateral.appendChild(item('#2F6670', '▤', g.nome, colocados[g.id] ? 'na folha' : '', function () { adicionar('grafico', g); }, !!colocados[g.id])); });
    if (!E.graficos.length) lateral.appendChild(el('p', 'dica', 'Nenhum gráfico veio das abas.'));
    var com = E.graficos.filter(function (g) { return g.resumo && g.resumo.length; });
    if (com.length) { lateral.appendChild(el('h4', null, 'Resumo estatístico')); com.forEach(function (g) { lateral.appendChild(item('#20242B', 'σ', g.nome, '', function () { adicionar('resumo', g); })); }); }
    lateral.appendChild(el('p', 'dica', 'Clique para pôr na folha. Arraste para mover, puxe os quadradinhos para esticar. Duplo clique no texto edita.'));
  }
  function campo(rot, ctrl) { var c = el('label', 'campo'); c.appendChild(el('span', null, rot)); c.appendChild(ctrl); return c; }
  function numero(v, passo, fn) { var i = el('input'); i.type = 'number'; i.step = passo || 1; i.value = v; i.onchange = function () { var n = parseFloat(i.value); if (isFinite(n)) fn(n); }; return i; }
  function texto(v, fn) { var i = el('input'); i.type = 'text'; i.value = v == null ? '' : v; i.onchange = function () { fn(i.value); }; return i; }
  function selecao(v, ops, fn) { var s = el('select'); ops.forEach(function (o) { var x = el('option', null, o[1]); x.value = o[0]; s.appendChild(x); }); s.value = v; s.onchange = function () { fn(s.value); }; return s; }
  function cor(v, fn) { var i = el('input'); i.type = 'color'; i.value = v || '#000000'; i.oninput = function () { fn(i.value); }; i.onchange = function () { commit(); }; return i; }
  function linhaBt() { var d = el('div', 'linha-bt'); for (var i = 0; i < arguments.length; i++) d.appendChild(arguments[i]); return d; }
  function bt2(txt, fn, cls, dica) { var b = el('button', 'bt2' + (cls ? ' ' + cls : ''), txt); b.type = 'button'; b.onclick = fn; if (dica) b.title = dica; return b; }
  function desenharProps() {
    props.innerHTML = '';
    var bs = sel.map(bloco).filter(Boolean);
    if (!bs.length) {
      props.appendChild(el('h4', null, 'Folha'));
      props.appendChild(campo('Cabeçalho', (function () { var c = el('input'); c.type = 'checkbox'; c.checked = !!E.cab; c.onchange = function () { E.cab = c.checked; commit(); tudo(); }; return c; })()));
      var c1 = campo('Título', texto(E.titulo, function (v) { E.titulo = v; commit(); tudo(); })); c1.className += ' col'; props.appendChild(c1);
      var c2 = campo('Subtítulo', texto(E.subtitulo, function (v) { E.subtitulo = v; commit(); tudo(); })); c2.className += ' col'; props.appendChild(c2);
      var c3 = campo('Rodapé', texto(E.rodape, function (v) { E.rodape = v; commit(); tudo(); })); c3.className += ' col'; props.appendChild(c3);
      props.appendChild(el('h4', null, 'Páginas'));
      props.appendChild(linhaBt(bt2('+ Página em branco', function () { E.paginas.push({ blocos: [] }); pagAtual = E.paginas.length - 1; commit(); tudo(); }),
                                bt2('Reorganizar tudo', function () { if (window.confirm('Refazer a disposição automática? As posições que você ajustou serão perdidas (dá para desfazer).')) { autoLayout(); commit(); tudo(); } }, '', 'Refaz a disposição automática no formato escolhido')));
      props.appendChild(el('p', 'dica', 'Clique num bloco para ver as opções dele. Shift + clique seleciona vários (aparecem as opções de alinhar). Alt ao soltar um bloco sobre outro troca os dois de lugar.'));
      return;
    }
    if (bs.length > 1) {
      props.appendChild(el('h4', null, bs.length + ' blocos selecionados'));
      props.appendChild(el('h4', null, 'Alinhar'));
      props.appendChild(linhaBt(bt2('⇤ Esquerda', function () { alinhar('esq'); }), bt2('⇔ Centro', function () { alinhar('cx'); }), bt2('⇥ Direita', function () { alinhar('dir'); })));
      props.appendChild(linhaBt(bt2('⤒ Topo', function () { alinhar('topo'); }), bt2('⇕ Meio', function () { alinhar('cy'); }), bt2('⤓ Base', function () { alinhar('base'); })));
      props.appendChild(el('h4', null, 'Distribuir'));
      props.appendChild(linhaBt(bt2('↔ Na horizontal', function () { distribuir('h'); }, '', 'Mesmo espaço entre os blocos (3 ou mais)'), bt2('↕ Na vertical', function () { distribuir('v'); })));
      props.appendChild(el('h4', null, 'Ações'));
      props.appendChild(linhaBt(bt2('Duplicar', duplicar), bt2('Apagar', apagar, 'perigo')));
      return;
    }
    var b = bs[0];
    props.appendChild(el('h4', null, NOMES_TIPO[b.tipo]));
    var f = F();
    props.appendChild(campo('X (mm)', numero(mm1(b.x * f.w), 1, function (v) { b.x = limitar(v / f.w, 0, 1 - b.w); commit(); tudo(); })));
    props.appendChild(campo('Y (mm)', numero(mm1(b.y * f.h), 1, function (v) { b.y = limitar(v / f.h, 0, 1 - b.h); commit(); tudo(); })));
    props.appendChild(campo('Largura (mm)', numero(mm1(b.w * f.w), 1, function (v) { b.w = limitar(v / f.w, 0.03, 1 - b.x); commit(); tudo(); })));
    props.appendChild(campo('Altura (mm)', numero(mm1(b.h * f.h), 1, function (v) { b.h = limitar(v / f.h, 0.03, 1 - b.y); commit(); tudo(); })));
    if (b.tipo === 'grafico' || b.tipo === 'destaques' || b.tipo === 'resumo') { var ct = campo('Título', texto(b.titulo == null ? ({ destaques: 'Destaques', resumo: 'Resumo estatístico', grafico: (ref(b.ref) || {}).nome }[b.tipo]) : b.titulo, function (v) { b.titulo = v; commit(); tudo(); })); ct.className += ' col'; props.appendChild(ct); }
    if (b.tipo === 'texto' || b.tipo === 'destaques' || b.tipo === 'resumo') props.appendChild(campo('Tamanho da letra', numero(b.tam || (b.tipo === 'texto' ? 14 : 12.5), 0.5, function (v) { b.tam = limitar(v, 6, 80); commit(); tudo(); })));
    if (b.tipo === 'texto') {
      props.appendChild(linhaBt(bt2('B', function () { b.negrito = !b.negrito; commit(); tudo(); }, b.negrito ? 'on' : '', 'Negrito no bloco todo (para trechos: selecione o texto e use Ctrl+B)'),
        bt2('⇤', function () { b.alinh = 'left'; commit(); tudo(); }, (b.alinh || 'left') === 'left' ? 'on' : ''), bt2('⇔', function () { b.alinh = 'center'; commit(); tudo(); }, b.alinh === 'center' ? 'on' : ''), bt2('⇥', function () { b.alinh = 'right'; commit(); tudo(); }, b.alinh === 'right' ? 'on' : '')));
      props.appendChild(campo('Cor do texto', cor(b.cor || '#20242B', function (v) { b.cor = v; var t = document.querySelector('.bk[data-id="' + b.id + '"] [data-edit=html]'); if (t) t.style.color = v; })));
    }
    if (b.tipo === 'kpi') props.appendChild(campo('Cor do número', cor(b.cor || (E.identidade.modo === 'institucional' ? E.identidade.cor_destaque : '#B3262E'), function (v) { b.cor = v; var t = document.querySelector('.bk[data-id="' + b.id + '"] .n'); if (t) t.style.color = v; })));
    if (b.tipo === 'imagem') { var inp = el('input'); inp.type = 'file'; inp.accept = 'image/*'; inp.style.display = 'none'; inp.onchange = function () { lerImagem(inp.files[0], function (src) { b.src = src; commit(); tudo(); }); }; props.appendChild(inp); props.appendChild(linhaBt(bt2(b.src ? 'Trocar a imagem' : 'Escolher a imagem...', function () { inp.click(); }))); }
    props.appendChild(campo('Borda', selecao(b.borda || 'fina', [['nenhuma', 'sem borda'], ['fina', 'fina'], ['sombra', 'com sombra']], function (v) { b.borda = v; commit(); tudo(); })));
    props.appendChild(el('h4', null, 'Ordem'));
    props.appendChild(linhaBt(bt2('Para a frente', function () { ordem(b, 1); }), bt2('Para trás', function () { ordem(b, -1); })));
    props.appendChild(campo('Travar posição', (function () { var c = el('input'); c.type = 'checkbox'; c.checked = !!b.travado; c.onchange = function () { b.travado = c.checked; commit(); tudo(); }; return c; })()));
    props.appendChild(el('h4', null, 'Ações'));
    props.appendChild(linhaBt(bt2('Duplicar (Ctrl+D)', duplicar), bt2('Apagar (Del)', apagar, 'perigo')));
  }
  function atualizarCamposPosicao() { if (sel.length === 1) desenharProps(); }

  // ---- identidade (popover) ---------------------------------------------------------------------------------------------------------------------
  function lerImagem(arq, fn) { if (!arq) return; var r = new FileReader(); r.onload = function () { fn(r.result); }; r.readAsDataURL(arq); }
  function abrirIdentidade() {
    var ant = document.getElementById('pop-ident'); if (ant) { ant.remove(); return; }
    var I = E.identidade, p = el('div', 'pop'); p.id = 'pop-ident'; p.addEventListener('click', function (e) { e.stopPropagation(); });
    p.appendChild(el('h4', null, 'Identidade do painel'));
    function mudar(fn) { fn(); guardarIdentidade(); commit(); aplicarIdentidade(); desenharFolhas(); desenharProps(); }
    var l1 = el('label', 'opc', '<input type="radio" name="idm"> <span><b>Cores padrão do Cinabro</b><br><span class="dica">Faixa tinta, destaque vermelho.</span></span>');
    var l2 = el('label', 'opc', '<input type="radio" name="idm"> <span><b>Logo e cores institucionais</b><br><span class="dica">Use o logo e as cores da sua instituição.</span></span>');
    var r1 = l1.firstChild, r2 = l2.firstChild; r1.checked = I.modo !== 'institucional'; r2.checked = I.modo === 'institucional';
    r1.onchange = function () { mudar(function () { I.modo = 'cinabro'; }); fechar(); abrirIdentidade(); }; r2.onchange = function () { mudar(function () { I.modo = 'institucional'; }); fechar(); abrirIdentidade(); };
    p.appendChild(l1); p.appendChild(l2);
    if (I.modo === 'institucional') {
      p.appendChild(campo('Cor da faixa', cor(I.cor_principal || '#20242B', function (v) { I.cor_principal = v; aplicarIdentidade(); guardarIdentidade(); }))); p.lastChild.querySelector('input').onchange = function () { commit(); };
      p.appendChild(campo('Cor de destaque', cor(I.cor_destaque || '#B3262E', function (v) { I.cor_destaque = v; aplicarIdentidade(); guardarIdentidade(); }))); p.lastChild.querySelector('input').onchange = function () { commit(); };
      var fi = el('input'); fi.type = 'file'; fi.accept = 'image/*'; fi.style.display = 'none'; fi.onchange = function () { lerImagem(fi.files[0], function (src) { mudar(function () { I.logo = src; I.mostrar_logo = true; }); fechar(); abrirIdentidade(); }); };
      p.appendChild(fi);
      var bl = [bt2(I.logo ? 'Trocar o logo...' : 'Escolher o logo...', function () { fi.click(); })]; if (I.logo) bl.push(bt2('Tirar o logo', function () { mudar(function () { I.logo = null; }); fechar(); abrirIdentidade(); })); p.appendChild(linhaBt.apply(null, bl));
      if (I.logo) { var im = el('img'); im.src = I.logo; im.style.cssText = 'max-height:38px;max-width:100%;display:block;margin:4px 0 8px;background:#eee;border-radius:6px;padding:3px'; p.appendChild(im); }
      p.appendChild(el('p', 'dica', 'O logo aparece no canto direito do cabeçalho. Fica guardado neste computador para os próximos painéis.'));
    }
    p.appendChild(linhaBt(bt2('Fechar', fechar)));
    function fechar() { var q = document.getElementById('pop-ident'); if (q) q.remove(); }
    document.querySelector('.barra').appendChild(p);
    var bi = document.getElementById('bt-ident'); if (bi) { var rc = bi.getBoundingClientRect(); p.style.left = Math.min(rc.left, window.innerWidth - 310) + 'px'; p.style.right = 'auto'; }
  }
  document.addEventListener('click', function (e) { var q = document.getElementById('pop-ident'); if (q && !e.target.closest('#bt-ident')) q.remove(); });

  // ---- operações nos blocos -----------------------------------------------------------------------------------------------------------------------
  function adicionar(tipo, g) {
    var f = F(), A = area(), p = E.paginas[Math.min(pagAtual, E.paginas.length - 1)], w = 0.3, h = 0.25, b;
    function centro(w, h) { return { x: limitar((A.x0 + A.x1) / 2 - w / 2, 0, 1 - w), y: limitar((A.y0 + A.y1) / 2 - h / 2, 0, 1 - h) }; }
    if (tipo === 'grafico') { var wm = Math.min(130, 100 * g.ar), hm = wm / g.ar + 8; w = mmx(wm); h = mmy(hm); b = novo('grafico', { ref: g.id, titulo: g.nome, w: w, h: h }); }
    else if (tipo === 'kpi') { w = mmx(52); h = mmy(26); b = novo('kpi', { w: w, h: h, valor: '0', rotulo: 'descrição do número' }); }
    else if (tipo === 'destaques') { w = mmx(80); h = mmy(60); b = novo('destaques', { w: w, h: h, itens: ['Escreva aqui um destaque.'] }); }
    else if (tipo === 'texto') { w = mmx(90); h = mmy(24); b = novo('texto', { w: w, h: h, html: 'Duplo clique para escrever.', tam: 14, borda: 'nenhuma' }); }
    else if (tipo === 'imagem') { w = mmx(40); h = mmy(26); b = novo('imagem', { w: w, h: h, borda: 'nenhuma' }); }
    else if (tipo === 'resumo') { w = mmx(75); h = mmy(14 + 5.5 * g.resumo.length); b = novo('resumo', { w: w, h: h, titulo: 'Resumo: ' + g.nome, linhas: g.resumo.slice() }); }
    var c = centro(w, h), n = p.blocos.length % 6; b.x = limitar(c.x + n * mmx(4), 0, 1 - w); b.y = limitar(c.y + n * mmy(4), 0, 1 - h);
    p.blocos.push(b); sel = [b.id]; commit(); tudo();
  }
  function duplicar() { var novos = []; sel.slice().forEach(function (id) { var b = bloco(id), p = paginaDe(id); if (!b) return; var c = JSON.parse(JSON.stringify(b)); c.id = novoId(); c.x = limitar(b.x + mmx(5), 0, 1 - b.w); c.y = limitar(b.y + mmy(5), 0, 1 - b.h); c.travado = false; E.paginas[p].blocos.push(c); novos.push(c.id); }); if (novos.length) { sel = novos; commit(); tudo(); } }
  function apagar() { sel.forEach(function (id) { var p = paginaDe(id); if (p >= 0) E.paginas[p].blocos = E.paginas[p].blocos.filter(function (b) { return b.id !== id; }); }); sel = []; commit(); tudo(); }
  function ordem(b, d) { var p = E.paginas[paginaDe(b.id)], i = p.blocos.indexOf(b); p.blocos.splice(i, 1); if (d > 0) p.blocos.push(b); else p.blocos.unshift(b); commit(); tudo(); }
  function selecionados() { return sel.map(bloco).filter(function (b) { return b && !b.travado; }); }
  function alinhar(como) {
    var bs = selecionados(); if (bs.length < 2) return;
    var x0 = Math.min.apply(null, bs.map(function (b) { return b.x; })), x1 = Math.max.apply(null, bs.map(function (b) { return b.x + b.w; })), y0 = Math.min.apply(null, bs.map(function (b) { return b.y; })), y1 = Math.max.apply(null, bs.map(function (b) { return b.y + b.h; }));
    bs.forEach(function (b) { if (como === 'esq') b.x = x0; else if (como === 'dir') b.x = x1 - b.w; else if (como === 'cx') b.x = (x0 + x1) / 2 - b.w / 2; else if (como === 'topo') b.y = y0; else if (como === 'base') b.y = y1 - b.h; else if (como === 'cy') b.y = (y0 + y1) / 2 - b.h / 2; });
    commit(); tudo();
  }
  function distribuir(eixo) {
    var bs = selecionados(); if (bs.length < 3) { toast('Para distribuir, selecione 3 blocos ou mais.'); return; }
    var h = eixo === 'h', pos = h ? 'x' : 'y', tam = h ? 'w' : 'h'; bs.sort(function (a, b) { return a[pos] - b[pos]; });
    var ini = bs[0][pos], fim = bs[bs.length - 1][pos] + bs[bs.length - 1][tam], soma = 0; bs.forEach(function (b) { soma += b[tam]; });
    var vao = (fim - ini - soma) / (bs.length - 1), cur = ini; bs.forEach(function (b) { b[pos] = cur; cur += b[tam] + vao; });
    commit(); tudo();
  }
  function mudarFormato(k) {
    if (k === E.formato) return; var tinha = E.paginas.some(function (p) { return p.blocos.length; });
    E.formato = k;
    if (tinha && window.confirm('Mudou o formato da página. Refazer a disposição automática? (Cancelar mantém as posições, esticadas à nova página.)')) autoLayout();
    commit(); tudo();
  }

  // ---- mouse: selecionar, mover, esticar, guias ----------------------------------------------------------------------------------------------------
  function folhaDe(elm) { return elm.closest('.folha'); }
  function aoApertar(e) {
    if (e.button !== 0) return;
    if (e.target.closest('.editando')) return;
    var ae = document.activeElement; if (ae && ae.classList && ae.classList.contains('editando')) { ae.blur(); return; }       // sair da edição de texto: só confirma
    var alca = e.target.closest('.alca'), bk = e.target.closest('.bk'), fo = folhaDe(e.target);
    if (!bk) { if (!e.shiftKey && (fo || e.target === tela || e.target.classList.contains('pagina-wrap'))) { sel = []; marcarSel(); desenharProps(); } if (fo) pagAtual = parseInt(fo.getAttribute('data-p'), 10) || 0; return; }
    var id = bk.getAttribute('data-id'), b = bloco(id); if (!b) return;
    pagAtual = paginaDe(id);
    if (e.shiftKey) { var i = sel.indexOf(id); if (i >= 0) sel.splice(i, 1); else sel.push(id); marcarSel(); desenharProps(); return; }
    if (sel.indexOf(id) < 0) { sel = [id]; marcarSel(); desenharProps(); }
    if (b.travado) return;
    var rect = fo.getBoundingClientRect(), bs = selecionados();
    arrasto = { modo: alca ? 'esticar' : 'mover', h: alca ? alca.getAttribute('data-h') : null, x0: e.clientX, y0: e.clientY, rect: rect, fo: fo, b: b, moveu: false, shift: e.shiftKey,
                ini: bs.map(function (z) { return { b: z, x: z.x, y: z.y, w: z.w, h: z.h }; }), pag: paginaDe(id) };
    e.preventDefault();
    window.addEventListener('pointermove', aoMover); window.addEventListener('pointerup', aoSoltar);
  }
  function marcarSel() { var todos = document.querySelectorAll('.bk'); for (var i = 0; i < todos.length; i++) { var id = todos[i].getAttribute('data-id'), s = sel.indexOf(id) >= 0; todos[i].classList.toggle('sel', s); todos[i].classList.toggle('unico', s && sel.length === 1); } }
  function candidatos(pag, fora) {
    var A = area(), xs = [0, 0.5, 1, A.x0, A.x1], ys = [0, 0.5, 1, A.y0, A.y1];
    E.paginas[pag].blocos.forEach(function (b) { if (fora.indexOf(b.id) >= 0) return; xs.push(b.x, b.x + b.w / 2, b.x + b.w); ys.push(b.y, b.y + b.h / 2, b.y + b.h); });
    return { xs: xs, ys: ys };
  }
  function encaixar(bordas, cands, tol) { var m = null; bordas.forEach(function (v) { cands.forEach(function (c) { var d = c - v; if (Math.abs(d) <= tol && (!m || Math.abs(d) < Math.abs(m.d))) m = { d: d, c: c }; }); }); return m; }
  function guias(fo, vx, hy) {
    var a = fo.querySelectorAll('.guia-v, .guia-h'); for (var i = 0; i < a.length; i++) a[i].remove();
    if (!E.guias) return;
    vx.forEach(function (x) { var g = el('div', 'guia-v'); g.style.left = pct(x); fo.appendChild(g); }); hy.forEach(function (y) { var g = el('div', 'guia-h'); g.style.top = pct(y); fo.appendChild(g); });
  }
  function posicionar(b) { var d = document.querySelector('.bk[data-id="' + b.id + '"]'); if (!d) return; d.style.left = pct(b.x); d.style.top = pct(b.y); d.style.width = pct(b.w); d.style.height = pct(b.h); }
  function aoMover(e) {
    var a = arrasto; if (!a) return;
    var dx = (e.clientX - a.x0) / a.rect.width, dy = (e.clientY - a.y0) / a.rect.height;
    if (!a.moveu && Math.hypot(e.clientX - a.x0, e.clientY - a.y0) < 3) return; a.moveu = true;
    var fx = mmx(GRADE_MM), fy = mmy(GRADE_MM), tx = 6 / a.rect.width, ty = 6 / a.rect.height, vx = [], hy = [];
    var cands = candidatos(a.pag, a.ini.map(function (z) { return z.b.id; }));
    if (a.modo === 'mover') {
      var ux0 = Math.min.apply(null, a.ini.map(function (z) { return z.x; })), ux1 = Math.max.apply(null, a.ini.map(function (z) { return z.x + z.w; })), uy0 = Math.min.apply(null, a.ini.map(function (z) { return z.y; })), uy1 = Math.max.apply(null, a.ini.map(function (z) { return z.y + z.h; }));
      var sx = E.guias ? encaixar([ux0 + dx, (ux0 + ux1) / 2 + dx, ux1 + dx], cands.xs, tx) : null, sy = E.guias ? encaixar([uy0 + dy, (uy0 + uy1) / 2 + dy, uy1 + dy], cands.ys, ty) : null;
      if (sx) { dx += sx.d; vx.push(sx.c); } else if (E.grade) dx = Math.round((ux0 + dx) / fx) * fx - ux0;
      if (sy) { dy += sy.d; hy.push(sy.c); } else if (E.grade) dy = Math.round((uy0 + dy) / fy) * fy - uy0;
      dx = limitar(dx, -ux0, 1 - ux1); dy = limitar(dy, -uy0, 1 - uy1);
      a.ini.forEach(function (z) { z.b.x = z.x + dx; z.b.y = z.y + dy; posicionar(z.b); });
    } else {
      var z0 = a.ini[0], h = a.h, x = z0.x, y = z0.y, w = z0.w, hh = z0.h, mw = 0.04, mh = 0.04;
      var dir = h.indexOf('e') >= 0, esq = h.indexOf('w') >= 0, bai = h.indexOf('s') >= 0, cim = h.indexOf('n') >= 0;
      var cx = function (v) { var s = E.guias ? encaixar([v], cands.xs, tx) : null; if (s) { vx.push(s.c); return s.c; } return E.grade ? Math.round(v / fx) * fx : v; };
      var cy = function (v) { var s = E.guias ? encaixar([v], cands.ys, ty) : null; if (s) { hy.push(s.c); return s.c; } return E.grade ? Math.round(v / fy) * fy : v; };
      if (dir) w = cx(z0.x + z0.w + dx) - x; if (esq) { var nx = cx(z0.x + dx); w = z0.x + z0.w - nx; x = nx; }
      if (bai) hh = cy(z0.y + z0.h + dy) - y; if (cim) { var ny = cy(z0.y + dy); hh = z0.y + z0.h - ny; y = ny; }
      if (e.shiftKey && h.length === 2) { var ar = (z0.w * F().w) / (z0.h * F().h), ww = w * F().w, hw = hh * F().h; if (ww / hw > ar) ww = hw * ar; else hw = ww / ar; var nw = ww / F().w, nh = hw / F().h; if (esq) x = z0.x + z0.w - nw; if (cim) y = z0.y + z0.h - nh; w = nw; hh = nh; }
      if (w < mw) { if (esq) x = z0.x + z0.w - mw; w = mw; } if (hh < mh) { if (cim) y = z0.y + z0.h - mh; hh = mh; }
      x = limitar(x, 0, 1 - w); y = limitar(y, 0, 1 - hh); w = Math.min(w, 1 - x); hh = Math.min(hh, 1 - y);
      z0.b.x = x; z0.b.y = y; z0.b.w = w; z0.b.h = hh; posicionar(z0.b);
    }
    guias(a.fo, vx, hy);
  }
  function aoSoltar(e) {
    window.removeEventListener('pointermove', aoMover); window.removeEventListener('pointerup', aoSoltar);
    var a = arrasto; arrasto = null; if (!a) return; guias(a.fo, [], []);
    if (!a.moveu) return;
    if (a.modo === 'mover' && e.altKey && a.ini.length === 1) {                      // Alt ao soltar sobre outro bloco: troca os dois de lugar
      var b = a.ini[0].b, cx = b.x + b.w / 2, cy = b.y + b.h / 2;
      var alvo = E.paginas[a.pag].blocos.filter(function (o) { return o !== b && cx >= o.x && cx <= o.x + o.w && cy >= o.y && cy <= o.y + o.h && !o.travado; })[0];
      if (alvo) { var o0 = a.ini[0]; var t = { x: alvo.x, y: alvo.y, w: alvo.w, h: alvo.h }; alvo.x = o0.x; alvo.y = o0.y; alvo.w = o0.w; alvo.h = o0.h; b.x = t.x; b.y = t.y; b.w = t.w; b.h = t.h; }
    }
    commit(); tudo();
  }

  // ---- edição de texto na folha (duplo clique) --------------------------------------------------------------------------------------------------------
  function aoDuploClique(e) {
    var alvo = e.target.closest('[data-edit]'); if (!alvo || modo !== 'editar') return;
    var bk = alvo.closest('.bk'), b = bk ? bloco(bk.getAttribute('data-id')) : null; if (b && b.travado) return;
    var campo = alvo.getAttribute('data-edit'), simples = ['titulo', 'valor', 'rotulo', 'cab-titulo', 'cab-sub', 'rodape'].indexOf(campo) >= 0;
    alvo.contentEditable = 'true'; alvo.classList.add('editando'); alvo.focus();
    var r = document.createRange(); r.selectNodeContents(alvo); var s = window.getSelection(); s.removeAllRanges(); s.addRange(r);
    function fim() {
      alvo.removeEventListener('blur', fim); alvo.removeEventListener('keydown', tecla); alvo.removeEventListener('paste', colar);
      alvo.contentEditable = 'false'; alvo.classList.remove('editando');
      var t = alvo.innerText.replace(/ /g, ' ').replace(/\n+$/, '');
      if (campo === 'titulo') b.titulo = t; else if (campo === 'valor') b.valor = t; else if (campo === 'rotulo') b.rotulo = t;
      else if (campo === 'html') b.html = alvo.innerHTML; else if (campo === 'itens') b.itens = [].map.call(alvo.children, function (li) { return li.innerHTML; }).filter(function (x) { return x.replace(/<br>/g, '').trim() !== ''; });
      else if (campo === 'linhas') b.linhas = t.split('\n'); else if (campo === 'cab-titulo') E.titulo = t; else if (campo === 'cab-sub') E.subtitulo = t; else if (campo === 'rodape') E.rodape = t;
      commit(); tudo();
    }
    function tecla(ev) { if (ev.key === 'Escape' || (simples && ev.key === 'Enter')) { ev.preventDefault(); alvo.blur(); } ev.stopPropagation(); }
    function colar(ev) { ev.preventDefault(); var t = (ev.clipboardData || window.clipboardData).getData('text/plain'); document.execCommand('insertText', false, simples ? t.replace(/\s*\n\s*/g, ' ') : t); }
    alvo.addEventListener('blur', fim); alvo.addEventListener('keydown', tecla); alvo.addEventListener('paste', colar);
  }

  // ---- teclado ------------------------------------------------------------------------------------------------------------------------------------------------------
  document.addEventListener('keydown', function (e) {
    if (modo !== 'editar') return; var t = e.target;
    if (t && (t.closest && (t.closest('.editando') || t.tagName === 'INPUT' || t.tagName === 'SELECT' || t.tagName === 'TEXTAREA'))) return;
    var ctrl = e.ctrlKey || e.metaKey, k = e.key;
    if (ctrl && (k === 'z' || k === 'Z')) { e.preventDefault(); if (e.shiftKey) refazer(); else desfazer(); }
    else if (ctrl && (k === 'y' || k === 'Y')) { e.preventDefault(); refazer(); }
    else if (ctrl && (k === 'd' || k === 'D')) { e.preventDefault(); duplicar(); }
    else if (ctrl && (k === 'a' || k === 'A')) { e.preventDefault(); sel = E.paginas[pagAtual].blocos.map(function (b) { return b.id; }); marcarSel(); desenharProps(); }
    else if (k === 'Delete' || k === 'Backspace') { if (sel.length) { e.preventDefault(); apagar(); } }
    else if (k === 'Escape') { sel = []; marcarSel(); desenharProps(); }
    else if (k.indexOf('Arrow') === 0 && sel.length) {
      e.preventDefault(); var passo = e.shiftKey ? 10 : 1, dx = (k === 'ArrowLeft' ? -1 : k === 'ArrowRight' ? 1 : 0) * mmx(passo), dy = (k === 'ArrowUp' ? -1 : k === 'ArrowDown' ? 1 : 0) * mmy(passo);
      selecionados().forEach(function (b) { b.x = limitar(b.x + dx, 0, 1 - b.w); b.y = limitar(b.y + dy, 0, 1 - b.h); posicionar(b); });
      clearTimeout(aoSoltarSetas.t); aoSoltarSetas.t = setTimeout(aoSoltarSetas, 350);
    }
  });
  function aoSoltarSetas() { commit(); atualizarCamposPosicao(); }
  window.addEventListener('resize', function () { if (zoom === 'ajustar' && tela) ajustarEscala(); });

  // ---- saída: HTML final e PDF ------------------------------------------------------------------------------------------------------------------------------------------------
  function nomeArquivo() { return (E.titulo || 'dashboard').replace(/[^A-Za-z0-9À-ÿ_.-]+/g, '_').replace(/^_+|_+$/g, '') || 'dashboard'; }
  function baixar(texto, nome, tipo) { var blob = new Blob([texto], { type: tipo }), a = document.createElement('a'); a.href = URL.createObjectURL(blob); a.download = nome; document.body.appendChild(a); a.click(); setTimeout(function () { URL.revokeObjectURL(a.href); a.remove(); }, 800); }
  function estadoSemGraficos() { var c = {}; for (var k in E) if (k !== 'graficos') c[k] = E[k]; return JSON.stringify(c); }
  function htmlFinal() {
    var clone = document.documentElement.cloneNode(true); clone.setAttribute('data-modo', 'ver');
    var a = clone.querySelector('#app'); a.innerHTML = ''; var b = clone.querySelector('.btn-editar'); if (b) b.remove();
    var p = clone.querySelector('.pop'); if (p) p.remove(); var ts = clone.querySelectorAll('.toast'); for (var i = 0; i < ts.length; i++) ts[i].remove();
    clone.querySelector('#estado').textContent = estadoSemGraficos().replace(/<\//g, '<\\/');
    var g = clone.querySelector('#graficos'); if (!g) { g = clone.ownerDocument.createElement('script'); g.id = 'graficos'; g.type = 'application/json'; clone.querySelector('body').insertBefore(g, clone.querySelector('#js')); }
    g.textContent = GRAF_TXT.replace(/<\//g, '<\\/');
    clone.style.removeProperty('--wmm'); clone.style.removeProperty('--hmm');
    return '<!doctype html>\n' + clone.outerHTML;
  }
  function salvarHTML() { baixar(htmlFinal(), nomeArquivo() + '.html', 'text/html'); toast('HTML salvo. Ele abre em qualquer computador (o botão "Editar" no canto volta a editar).'); }
  function exportarPDF() {
    if (emApp) { toast('Gerando o PDF... (pode levar alguns segundos)'); var b = document.getElementById('bt-pdf'); if (b) b.disabled = true;
      window.parent.Shiny.setInputValue('dash_pdf', { id: E.id || '', estado: estadoSemGraficos(), nome: nomeArquivo(), t: Date.now() }, { priority: 'event' }); }
    else { toast('Na janela de impressão que vai abrir, escolha "Salvar como PDF" e desmarque "Cabeçalhos e rodapés".'); setTimeout(function () { window.print(); }, 600); }
  }
  window.cinabroDash = { pdfPronto: function (m) {
    var b = document.getElementById('bt-pdf'); if (b) b.disabled = false;
    if (m && m.ok) { var a = document.createElement('a'); a.href = m.url; a.download = m.nome; document.body.appendChild(a); a.click(); a.remove(); toast('PDF pronto: ' + m.nome); }
    else { toast('Não achei o Edge nem o Chrome para gerar o PDF sozinho. Vou abrir a impressão: escolha "Salvar como PDF".', true); setTimeout(function () { window.print(); }, 1500); } } };

  // ---- início -------------------------------------------------------------------------------------------------------------------------------------------------------------------
  if (!E.paginas.length) { var salva = lerIdentidadeSalva(); if (salva && modo === 'editar' && E.identidade.modo === 'cinabro' && salva.modo === 'institucional') E.identidade = salva; autoLayout(); }
  if (modo === 'editar') { hist = [snap()]; hpos = 0; }
  montarUI(); if (modo !== 'editar') { aplicarIdentidade(); desenharFolhas(); }
  window.__dash = { estado: E, sel: function () { return sel; }, autoLayout: autoLayout };       // (para os testes automáticos)
}());
