// Seletor de cor: envia o valor ao Shiny; "×" volta ao padrão do template.
(function () {
  function marcar(el, hex) {
    var $c = $(el).closest('.cor-input'), id = $c.data('id'), padrao = $c.data('padrao') || '';
    if (hex) { $c.addClass('mudou'); $c.find('.cor-estado').removeClass('vazio').text(hex); }
    else { $c.removeClass('mudou'); var $e = $c.find('.cor-estado'); if (padrao) $e.removeClass('vazio').text(padrao); else $e.addClass('vazio').text('padrão');
           $c.find('.cor-seletor').val(padrao || '#cccccc'); }
    Shiny.setInputValue(id, hex || '', { priority: 'event' });
  }
  $(document).on('input change', '.cor-seletor', function () { marcar(this, this.value); });
  $(document).on('click', '.cor-limpar', function () { marcar(this, ''); });
  Shiny.addCustomMessageHandler('set_cor', function (m) {
    var $c = $('.cor-input[data-id="' + m.id + '"]'); if (!$c.length) return;
    if (m.valor) { $c.find('.cor-seletor').val(m.valor); marcar($c.find('.cor-seletor')[0], m.valor); } else { marcar($c.find('.cor-seletor')[0], ''); }
  });
  $(document).on('click', '#copiar-codigo', function () {
    var t = $('#codigo-txt').text(), b = this, ok = $(b).data('copiado') || 'Copiado!', orig = b.textContent;
    (navigator.clipboard ? navigator.clipboard.writeText(t) : Promise.reject()).catch(function () {
      var a = document.createElement('textarea'); a.value = t; document.body.appendChild(a); a.select(); document.execCommand('copy'); document.body.removeChild(a);
    }).then(function () { b.textContent = ok; setTimeout(function () { b.textContent = orig; }, 1600); });
  });
  // botão "Sair": o R encerra e esta aba mostra um aviso de despedida
  Shiny.addCustomMessageHandler('adeus', function (m) {
    document.body.innerHTML = '<div style="font-family:Barlow,sans-serif;max-width:520px;margin:18vh auto;padding:0 24px;text-align:center;color:#20242B">' +
      '<h2 style="color:#B3262E">Cinabro encerrado</h2><p>Pode fechar esta aba. Para voltar a usar, abra o Cinabro pelo atalho ou pelo <b>abrir_app.bat</b>.</p></div>';
    document.body.style.background = '#F5EBDD';
  });
  // (idioma: só português; o seletor foi retirado. Inglês e espanhol estão arquivados em idiomas_arquivados/.)
  try { localStorage.removeItem('cinabro_idioma'); } catch (e) {}
  // "Selecionar todas" / "Limpar" nas listas de colunas
  function seletor(id) { var el = document.getElementById(id); return el && el.selectize; }
  $(document).on('click', '[data-sel-todas]', function (e) {
    e.preventDefault(); var s = seletor($(this).data('sel-todas')); if (!s) return;
    s.setValue(Object.keys(s.options), false);
  });
  $(document).on('click', '[data-sel-limpar]', function (e) {
    e.preventDefault(); var s = seletor($(this).data('sel-limpar')); if (s) s.clear(false);
  });
  // ---- estúdio: trilho de ícones, gaveta de painéis, faixa de ferramentas, maximizar ----------------------------------------------
  function ajustarTopo() {
    var h = ($('.topo').outerHeight() || 0) + ($('.abas-barra').outerHeight() || 0);
    document.documentElement.style.setProperty('--alt-topo', h + 'px'); document.documentElement.style.setProperty('--alt-cab', ($('.topo').outerHeight() || 0) + 'px');
  }
  function avisarPalco() { setTimeout(function () { $(window).trigger('resize'); var w = $('.previa-quadro').innerWidth(); if (w) Shiny.setInputValue('palco_larg', Math.round(w), { priority: 'event' }); }, 380); }
  // os 14 blocos viraram seções de 7 painéis; um id antigo de bloco abre o painel dele, abre a seção e rola até ela
  var PAINEL_DO_BLOCO = { dados: 'dados', intervalos: 'eixos', escala: 'eixos', numeros: 'eixos', grade: 'eixos', quebra: 'eixos', y2: 'eixos', cores: 'series', fonte: 'texto',
                          legenda: 'legenda', estatistica: 'analise', formas: 'analise', moldura: 'exportar', exportacao: 'exportar' };
  function abrirPainel(id, manter) {
    var pid = PAINEL_DO_BLOCO[id] || id, $p = $('#painel-' + pid); if (!$p.length) return;
    var $sec = $('details.secao#bloco-' + id);
    $('.painel').removeClass('ativo'); $p.addClass('ativo'); id = pid;
    $('.trilho-btn').removeClass('ativo').filter('[data-painel="' + id + '"]').addClass('ativo');
    if ($sec.length) { $sec.attr('open', 'open'); setTimeout(function () { $sec[0].scrollIntoView({ block: 'start' }); }, 80); }
    $('.estudio').addClass('gaveta-aberta').removeClass('max'); $('.gaveta').scrollTop(0);
    try { localStorage.setItem('cinabro_painel', id); } catch (e) {}
    if (!manter) avisarPalco();
  }
  $(document).on('click', '.trilho-btn', function () {
    var id = $(this).data('painel');
    if ($(this).hasClass('ativo') && $('.estudio').hasClass('gaveta-aberta')) { $('.estudio').removeClass('gaveta-aberta'); $(this).removeClass('ativo'); avisarPalco(); }
    else abrirPainel(id);
  });
  $(document).on('click', 'summary .cong', function (e) { e.stopPropagation(); });            // marcar "Congelar" não abre nem fecha a seção
  // seções recolhidas que escondem um recurso ligado (eixo da direita, quebra de eixo) ganham o aviso "ligado"
  function marcarLigados() {
    $('#bloco-quebra').toggleClass('ligado', $('#quebra_ativar').is(':checked'));
    var y2 = $('#y2_series').val(); $('#bloco-y2').toggleClass('ligado', !!(y2 && y2.length));
  }
  $(document).on('shiny:inputchanged', function (e) { if (e.name === 'quebra_ativar' || e.name === 'y2_series') setTimeout(marcarLigados, 30); });
  $(document).on('shiny:connected', function () { setTimeout(marcarLigados, 400); });
  $(document).on('click', 'a[href^="#bloco-"]', function (e) { e.preventDefault(); abrirPainel(String($(this).attr('href')).replace('#bloco-', '')); });
  $(document).on('click', '[data-abrir]', function () { abrirPainel($(this).data('abrir')); });
  $(document).on('click', '.faixa-lista .faixa-btn', function () { $(this).closest('details').removeAttr('open'); });
  $(document).on('click', function (e) { if (!$(e.target).closest('.faixa-menu').length) $('.faixa-menu').removeAttr('open'); });
  $(document).on('click', '[data-rapido]', function () {
    var d = $(this).data('rapido'); d.t = Date.now(); Shiny.setInputValue('rapido', d, { priority: 'event' });
  });
  function maximizar(ligar) {
    var $e = $('.estudio'); if (ligar === undefined) ligar = !$e.hasClass('max');
    $e.toggleClass('max', ligar); $('#maximizar').text(ligar ? ($('#maximizar').data('sair') || 'Mostrar painéis') : ($('#maximizar').data('max') || 'Maximizar'));
    avisarPalco();
  }
  $(document).on('click', '#maximizar', function () { if (!$(this).data('max')) { $(this).data('max', $(this).text()); } maximizar(); });
  $(document).on('keydown', function (e) { if (e.key === 'Escape' && $('.estudio').hasClass('max')) maximizar(false); });
  function irParaCartao(painel, cartao) {
    abrirPainel(painel, true);
    if (cartao) setTimeout(function () { var el = document.getElementById(cartao); if (!el) return; $(el).closest('details.secao').attr('open', 'open'); var $g = $(el).closest('.grupo'); $g[0] && $g[0].scrollIntoView({ block: 'center' }); $g.addClass('flash'); setTimeout(function () { $g.removeClass('flash'); }, 1600); }, 350);
    avisarPalco();
  }
  Shiny.addCustomMessageHandler('abrir_painel', function (m) { irParaCartao(m.id, m.cartao); });
  $(function () { ajustarTopo(); abrirPainel('dados', true); setTimeout(function () { ajustarTopo(); avisarPalco(); }, 700); });
  $(window).on('resize', function () { ajustarTopo(); clearTimeout(window.__rz); window.__rz = setTimeout(function () { var w = $('.previa-quadro').innerWidth(); if (w) Shiny.setInputValue('palco_larg', Math.round(w), { priority: 'event' }); }, 500); });
  $(document).on('shiny:connected', function () { setTimeout(avisarPalco, 600); });

  // ---- caixa da legenda: arrastar (posição) e puxar a alça (largura) sobre a prévia ------------------------------------------
  var geo = null, ar = null;
  function host() { return document.querySelector('.previa-quadro'); }
  function imagem() { return document.querySelector('#previa img'); }
  function medidasImg() {
    var im = imagem(), h = host(); if (!im || !h || !geo) return null;
    var r = im.getBoundingClientRect(), hr = h.getBoundingClientRect();
    return { W: r.width, H: r.height, ox: r.left - hr.left + h.scrollLeft, oy: r.top - hr.top + h.scrollTop };
  }
  function medidas() { return geo && geo.ok ? medidasImg() : null; }
  // ---- edição dentro do gráfico: zonas clicáveis sobre os títulos; clicar abre uma caixa com o texto, o negrito e o tamanho ----------------
  var EDIT = { titulo: ['titulo_grafico', 'titulo_grafico_negrito', 'titulo_grafico_tamanho_pt'],
               xlab: ['x_titulo', 'eixos_titulo_negrito', 'x_titulo_tamanho_pt'],
               ylab: ['y_titulo', 'eixos_titulo_negrito', 'y_titulo_tamanho_pt'] };
  var pop = null;
  function rotulo(k) { return $('#edicao-rotulos [data-z="' + k + '"]').text(); }
  function fecharPopover() {
    if (!pop) return;
    pop.itens.forEach(function (it) { if (it.next && it.next.parentNode === it.parent) it.parent.insertBefore(it.node, it.next); else it.parent.appendChild(it.node); });
    $('#popover-edicao').remove(); pop = null;
  }
  function reposicionarPopover() {
    if (!pop) return;
    var $z = pop.k.indexOf('caixa:') === 0 ? $('.caixa-movel[data-id="' + pop.k.slice(6) + '"]') : $('.zona[data-z="' + pop.k + '"]'), $p = $('#popover-edicao'), h = host(); if (!$z.length || !$p.length) return;
    var zl = parseFloat($z.css('left')), zt = parseFloat($z.css('top')), zh = $z.outerHeight();
    var esq = Math.max(6, Math.min(zl, h.scrollLeft + h.clientWidth - $p.outerWidth() - 6)), topo = zt + zh + 6;
    if (topo + $p.outerHeight() > h.scrollTop + h.clientHeight) topo = Math.max(zt - $p.outerHeight() - 6, 6);
    $p.css({ left: esq, top: topo });
  }
  function abrirPopover(k, ids, titulo, cartao) {
    fecharPopover();
    var $p = $('<div id="popover-edicao"><div class="pop-cab"><b></b><button type="button" class="pop-x">&times;</button></div><div class="pop-corpo"></div></div>');
    $p.find('b').text(titulo || rotulo(k)); $p.find('.pop-x').attr('title', rotulo('fechar'));
    var itens = [];
    (ids || EDIT[k]).forEach(function (id) {
      var node = $('#' + id).closest('.campo')[0]; if (!node) return;
      itens.push({ node: node, parent: node.parentNode, next: node.nextSibling }); $p.find('.pop-corpo').append(node);
    });
    if (cartao) $('<button type="button" class="pop-mais"></button>').text(rotulo('cx_mais')).on('click', function () { fecharPopover(); irParaCartao(cartao.painel, cartao.ativo); }).appendTo($p.find('.pop-corpo'));
    $(host()).append($p); pop = { k: k, itens: itens }; reposicionarPopover();
    setTimeout(function () { $p.find('input[type=text], input:not([type])').first().focus(); }, 60);
  }
  function colocarZonas() {
    var h = host(), im = imagem(); $('.zona').remove();
    if (!h || !im || !geo || !geo.zonas) { fecharPopover(); return; }
    var r = im.getBoundingClientRect(), hr = h.getBoundingClientRect(), ox = r.left - hr.left + h.scrollLeft, oy = r.top - hr.top + h.scrollTop;
    Object.keys(geo.zonas).forEach(function (k) {
      var z = geo.zonas[k]; if (!EDIT[k] || !z) return;
      $('<div class="zona" data-z="' + k + '"></div>').css({ left: ox + z[0] * r.width, top: oy + z[1] * r.height, width: z[2] * r.width, height: Math.max(z[3] * r.height, 16) })
        .attr('title', rotulo('dica')).appendTo(h);
    });
    reposicionarPopover();
  }
  $(document).on('click', '.zona', function (e) { abrirPopover($(this).data('z')); e.stopPropagation(); });
  $(document).on('click', '.pop-x', fecharPopover);
  $(document).on('mousedown', function (e) {
    if (pop && !$(e.target).closest('#popover-edicao, .zona, .caixa-movel, .selectize-dropdown, .modal').length) fecharPopover();
    if (cmAtiva && !$(e.target).closest('#popover-edicao, .caixa-movel, .selectize-dropdown, .modal').length) desselecionar();
  });
  $(document).on('keydown', function (e) { if (e.key === 'Escape' && pop) { fecharPopover(); e.stopImmediatePropagation(); } });

  // ---- caixas móveis (estatística, texto, forma, figura): arrastar, puxar as alças (tamanho), setas (ajuste fino) e clicar (editar) --------
  // Uma moldura fina já aparece sobre cada caixa; clicar seleciona (alças nos cantos e nos lados); arrastar move com uma "sombra" do conteúdo,
  // que acompanha o mouse; ao soltar, os valores caem nos campos do cartão (em fração do gráfico ou nas unidades dos eixos).
  var PAINEL_DE = { cx: 'estatistica', fm: 'formas', im: 'formas' };
  var CAMPOS_RAPIDOS = { estatistica: ['itens', 'tamanho_pt', 'negrito', 'casas'], texto: ['texto', 'tamanho_pt', 'negrito', 'fundo'],
                         forma: ['texto', 'tamanho_pt', 'fundo', 'borda_cor'], figura: ['largura', 'opacidade', 'angulo'] };
  var ALCAS_CANTO = ['nw', 'ne', 'sw', 'se'], ALCAS_TODAS = ['nw', 'n', 'ne', 'e', 'se', 's', 'sw', 'w'];
  var cm = null, cmAtiva = null, ng = null;                          // gesto em andamento, caixa selecionada, ajuste fino pelas setas
  function setCampo(id, v) { var $e = $('#' + id); if ($e.length) $e.val(v).trigger('input').trigger('change'); }
  function arred(v, n) { var f = Math.pow(10, n); return Math.round(v * f) / f; }
  function casasDe(faixa) { return Math.max(0, Math.min(8, 3 - Math.floor(Math.log10(Math.max(Math.abs(faixa[1] - faixa[0]), 1e-9))))); }
  function pixelsPainel(m) { var p = geo.caixas.painel; return { l: m.ox + p[0] * m.W, t: m.oy + p[1] * m.H, w: p[2] * m.W, h: p[3] * m.H }; }
  function colocarCaixas() {
    $('.caixa-movel').remove();
    var m = medidasImg(); if (!m || !geo.caixas || !geo.caixas.itens || !$('#arrastar').is(':checked')) { return; }
    // as menores por cima: uma caixa grande (polígono, caixa de estatística) nunca esconde o texto ou a figura que está sobre ela
    var ordem = geo.caixas.itens.slice().sort(function (a, b) { return b.rect[2] * b.rect[3] - a.rect[2] * a.rect[3]; });
    ordem.forEach(function (it) {
      var ehRot = it.tipo === 'rotulo';
      var $b = $('<div class="caixa-movel' + (ehRot ? ' rotulo' : '') + '" data-id="' + it.id + '"><b class="cm-fant"></b><span class="cm-rot"></span></div>');
      if (!ehRot) ALCAS_TODAS.forEach(function (h) { $b.append('<i class="cm-alca" data-h="' + h + '"></i>'); });
      $b.find('.cm-rot').text(ehRot ? it.chave : rotulo('cx_' + it.tipo)); $b.attr('title', ehRot ? rotulo('cx_dica_nome') : rotulo('cx_dica')).data('it', it);
      $b.css({ left: m.ox + it.rect[0] * m.W, top: m.oy + it.rect[1] * m.H, width: Math.max(it.rect[2] * m.W, 14), height: Math.max(it.rect[3] * m.H, 14) });
      if (it.id === cmAtiva) $b.addClass('ativa');
      $(host()).append($b);
    });
    reposicionarPopover();
  }
  function desselecionar() { cmAtiva = null; $('.caixa-movel').removeClass('ativa'); }
  // a "sombra": o próprio recorte da prévia, esticado junto com a moldura (mistura multiplicando, então o branco não esconde o gráfico por baixo)
  function sombra($b, g, l, t, w, h) {
    var sx = w / g.w0, sy = h / g.h0, im = imagem();
    $b.find('.cm-fant').css({ backgroundImage: 'url("' + im.src + '")', backgroundSize: (g.m.W * sx) + 'px ' + (g.m.H * sy) + 'px',
                              backgroundPosition: (-(g.l0 - g.m.ox) * sx) + 'px ' + (-(g.t0 - g.m.oy) * sy) + 'px' });
  }
  // novo retângulo (l, t, w, h em px) para o gesto: mover, ou esticar por uma alça (nw, n, ne, e, se, s, sw, w); 'prop' = mantém a proporção
  function retangulo(g, dx, dy) {
    var P = pixelsPainel(g.m), l0 = g.l0, t0 = g.t0, w0 = g.w0, h0 = g.h0, r = l0 + w0, b = t0 + h0, MW = 16, MH = 12;
    if (g.modo === 'mover') return { l: Math.min(Math.max(l0 + dx, P.l), Math.max(P.l, P.l + P.w - w0)), t: Math.min(Math.max(t0 + dy, P.t), Math.max(P.t, P.t + P.h - h0)), w: w0, h: h0 };
    var H = g.alca, tw = H.indexOf('w') >= 0, te = H.indexOf('e') >= 0, tn = H.indexOf('n') >= 0, ts = H.indexOf('s') >= 0;
    if (g.prop && H.length === 2) {                                  // canto com proporção fixa: a largura manda, a altura segue
      var s = (tw ? (r - (l0 + dx)) : (r - l0 + dx)) / w0;
      var dispW = tw ? (r - P.l) : (P.l + P.w - l0), dispH = tn ? (b - P.t) : (P.t + P.h - t0);
      s = Math.max(MW / w0, Math.min(s, dispW / w0, dispH / h0));
      return { l: tw ? r - w0 * s : l0, t: tn ? b - h0 * s : t0, w: w0 * s, h: h0 * s };
    }
    var nl = l0, nr = r, nt = t0, nb = b;
    if (tw) nl = Math.min(Math.max(l0 + dx, P.l), r - MW);
    if (te) nr = Math.max(Math.min(r + dx, P.l + P.w), l0 + MW);
    if (tn) nt = Math.min(Math.max(t0 + dy, P.t), b - MH);
    if (ts) nb = Math.max(Math.min(b + dy, P.t + P.h), t0 + MH);
    return { l: nl, t: nt, w: nr - nl, h: nb - nt };
  }
  function colocarRet($b, R) { $b.css({ left: R.l + 'px', top: R.t + 'px', width: R.w + 'px', height: R.h + 'px' }); }
  // grava nos campos do cartão o que o gesto deixou (l, t, w, h em px); g guarda o retângulo de antes
  // nomes arrastáveis (PCA/CA/CCA e mapas): o campo guarda "Nome=x,y; Nome2=x,y" (centro do nome, nas unidades dos eixos)
  function lerPosicoes(campo) {
    var out = [], v = String($('#' + campo).val() || '');
    v.split(';').forEach(function (z) { var k = z.lastIndexOf('='); if (k > 0 && z.trim()) out.push([z.slice(0, k).trim(), z.slice(k + 1).trim()]); });
    return out;
  }
  function gravarPosicoes(campo, lista) { setCampo(campo, lista.map(function (e) { return e[0] + '=' + e[1]; }).join('; ')); }
  function gravarRotulo(it, R, P) {
    var fxr = (R.l + R.w / 2 - P.l) / P.w, fyr = ((P.t + P.h) - (R.t + R.h / 2)) / P.h;
    var X = it.lx[0] + fxr * (it.lx[1] - it.lx[0]), Y = it.ly[0] + fyr * (it.ly[1] - it.ly[0]);
    var txt = arred(X, casasDe(it.lx) + 1) + ',' + arred(Y, casasDe(it.ly) + 1), lista = lerPosicoes(it.campo), achou = false;
    lista.forEach(function (e) { if (e[0] === it.chave) { e[1] = txt; achou = true; } });
    if (!achou) lista.push([it.chave, txt]);
    gravarPosicoes(it.campo, lista);
  }
  $(document).on('dblclick', '.caixa-movel.rotulo', function () {                  // duplo clique: o nome volta a se posicionar sozinho
    var it = $(this).data('it'); if (!it) return;
    gravarPosicoes(it.campo, lerPosicoes(it.campo).filter(function (e) { return e[0] !== it.chave; }));
  });
  function gravarCaixa(g, R) {
    var it = g.it, m = g.m, P = pixelsPainel(m), F = geo.caixas.faixa, dados = !!it.dados && F, redim = g.modo === 'tam';
    if (it.tipo === 'rotulo') { gravarRotulo(it, R, P); return; }
    var livre = !it.auto || !!g.lado;                                 // tamanho próprio (largura e altura) em vez de proporção / tamanho da letra
    var fx = function (px) { return (px - P.l) / P.w; }, fy = function (py) { return ((P.t + P.h) - py) / P.h; };        // fração do painel (y de baixo para cima)
    var X = function (f) { return dados ? arred(F.x[0] + f * (F.x[1] - F.x[0]), casasDe(F.x)) : arred(f, 3); };
    var Y = function (f) { return dados ? arred(F.y[0] + f * (F.y[1] - F.y[0]), casasDe(F.y)) : arred(f, 3); };
    var LX = function (px) { return dados ? arred(px / P.w * (F.x[1] - F.x[0]), casasDe(F.x)) : arred(px / P.w, 3); };   // comprimentos
    var LY = function (px) { return dados ? arred(px / P.h * (F.y[1] - F.y[0]), casasDe(F.y)) : arred(px / P.h, 3); };
    if (it.forma === 'poligono' && it.vert) {
      var nv = it.vert.map(function (v) {
        var px = P.l + v[0] * P.w, py = P.t + (1 - v[1]) * P.h;
        return X(fx(R.l + (px - g.l0) * (R.w / g.w0))) + ',' + Y(fy(R.t + (py - g.t0) * (R.h / g.h0)));
      });
      setCampo(it.id + '_vertices', nv.join('; ')); return;
    }
    if (dados && (it.regiao || (redim && livre))) {                                       // retângulo/figura em unidades dos eixos: x, y = centro; largura e altura = tamanho
      setCampo(it.id + '_x', X(fx(R.l + R.w / 2))); setCampo(it.id + '_y', Y(fy(R.t + R.h / 2)));
      if (redim) { setCampo(it.id + '_largura', LX(R.w)); setCampo(it.id + '_altura', LY(R.h)); }
      return;
    }
    setCampo(it.id + '_x', X(fx(R.l + it.jx * R.w))); setCampo(it.id + '_y', Y(fy(R.t + (1 - it.jy) * R.h)));
    if (!redim) return;
    if (it.tipo === 'figura') {
      setCampo(it.id + '_largura', arred(R.w / P.w, 3)); if (livre) setCampo(it.id + '_altura', arred(R.h / P.h, 3));
    } else if (!livre) {
      setCampo(it.id + '_tamanho_pt', Math.max(4, arred((it.tam || 11) * (R.w / g.w0), 1)));
    } else {
      setCampo(it.id + '_largura', arred(R.w / P.w, 3)); setCampo(it.id + '_altura', arred(R.h / P.h, 3));
    }
  }
  $(document).on('pointerdown', '.caixa-movel', function (e) {
    var m = medidasImg(); if (!m || !geo.caixas) return;
    var $b = $(this), it = $b.data('it'), $al = $(e.target).closest('.cm-alca'), alca = $al.length ? String($al.data('h')) : null;
    if (ng) { clearTimeout(ng.timer); ng = null; }
    cm = { modo: alca ? 'tam' : 'mover', alca: alca, lado: !!alca && alca.length === 1,
           prop: !!alca && alca.length === 2 && (it.auto ? !e.shiftKey : e.shiftKey), x0: e.clientX, y0: e.clientY,
           l0: parseFloat($b.css('left')), t0: parseFloat($b.css('top')), w0: $b.outerWidth(), h0: $b.outerHeight(), m: m, it: it, moveu: false };
    cmAtiva = it.id; $('.caixa-movel').removeClass('ativa'); $b.addClass('ativa');
    this.setPointerCapture(e.pointerId); e.preventDefault();
  });
  $(document).on('pointermove', '.caixa-movel', function (e) {
    if (!cm || cm.it.id !== $(this).data('it').id) return;
    var dx = e.clientX - cm.x0, dy = e.clientY - cm.y0, $b = $(this);
    if (!cm.moveu && Math.abs(dx) + Math.abs(dy) > 3) { cm.moveu = true; $b.addClass('arrastando'); }
    if (!cm.moveu) return;
    var R = retangulo(cm, dx, dy); colocarRet($b, R); sombra($b, cm, R.l, R.t, R.w, R.h);
  });
  $(document).on('pointerup pointercancel', '.caixa-movel', function (e) {
    if (!cm) return;
    var g = cm, $b = $(this), it = g.it; cm = null; $b.removeClass('arrastando');
    if (!g.moveu && it.tipo === 'rotulo') return;                       // um clique num nome: nada (arraste para mover, duplo clique para soltar)
    if (!g.moveu) {                                                   // um clique: abre a edição rápida
      var pref = it.id.replace(/[0-9]+$/, ''), ids = (CAMPOS_RAPIDOS[it.tipo] || []).map(function (c) { return it.id + '_' + c; });
      abrirPopover('caixa:' + it.id, ids, rotulo('cx_' + it.tipo), { painel: PAINEL_DE[pref], ativo: it.id + '_ativo' });
      return;
    }
    gravarCaixa(g, { l: parseFloat($b.css('left')), t: parseFloat($b.css('top')), w: $b.outerWidth(), h: $b.outerHeight() });
  });
  // setas: ajuste fino da caixa selecionada (2 px; com Shift, 10 px); grava quando a pessoa para de apertar
  $(document).on('keydown', function (e) {
    if (!/^Arrow(Left|Right|Up|Down)$/.test(e.key) || $(e.target).is('input, textarea, select, [contenteditable]') || $(e.target).closest('.selectize-control').length) return;
    var $b = $('.caixa-movel.ativa'); if (!$b.length || cm) return;
    var m = medidasImg(); if (!m || !geo.caixas) return;
    if (!ng) ng = { modo: 'mover', m: m, it: $b.data('it'), l0: parseFloat($b.css('left')), t0: parseFloat($b.css('top')), w0: $b.outerWidth(), h0: $b.outerHeight() };
    var p = e.shiftKey ? 10 : 2, dx = e.key === 'ArrowLeft' ? -p : e.key === 'ArrowRight' ? p : 0, dy = e.key === 'ArrowUp' ? -p : e.key === 'ArrowDown' ? p : 0;
    var P = pixelsPainel(ng.m), l = Math.min(Math.max(parseFloat($b.css('left')) + dx, P.l), Math.max(P.l, P.l + P.w - ng.w0)), t = Math.min(Math.max(parseFloat($b.css('top')) + dy, P.t), Math.max(P.t, P.t + P.h - ng.h0));
    $b.css({ left: l + 'px', top: t + 'px' }); e.preventDefault();
    clearTimeout(ng.timer);
    ng.timer = setTimeout(function () { var g = ng; ng = null; var $a = $('.caixa-movel.ativa'); if ($a.length && g) gravarCaixa(g, { l: parseFloat($a.css('left')), t: parseFloat($a.css('top')), w: g.w0, h: g.h0 }); }, 450);
  });

  function colocar() {
    colocarZonas(); colocarCaixas();
    var $b = $('#legenda-caixa'), m = medidas();
    if (!m || !$('#arrastar').is(':checked')) { $b.hide(); return; }
    $b.css({ display: 'block', left: (m.ox + geo.legenda[0] * m.W) + 'px', top: (m.oy + geo.legenda[1] * m.H) + 'px',
             width: (geo.legenda[2] * m.W) + 'px', height: (geo.legenda[3] * m.H) + 'px' });
  }
  Shiny.addCustomMessageHandler('legenda_geom', function (m) { geo = m; setTimeout(colocar, 60); });
  $(document).on('shiny:value', function (e) { if (e.name === 'previa') setTimeout(colocar, 120); });
  $(document).on('change', '#arrastar', colocar);
  $(window).on('resize', colocar);
  $(document).on('pointerdown', '#legenda-caixa', function (e) {
    var m = medidas(); if (!m) return;
    var $b = $('#legenda-caixa');
    ar = { modo: $(e.target).hasClass('legenda-alca') ? 'largura' : 'mover', x0: e.clientX, y0: e.clientY, l0: parseFloat($b.css('left')),
           t0: parseFloat($b.css('top')), w0: $b.width(), h0: $b.height(), m: m };
    this.setPointerCapture(e.pointerId); e.preventDefault();
  });
  $(document).on('pointermove', '#legenda-caixa', function (e) {
    if (!ar) return;
    var $b = $(this), m = ar.m, dx = e.clientX - ar.x0, dy = e.clientY - ar.y0;
    var pl = m.ox + geo.painel[0] * m.W, pt = m.oy + geo.painel[1] * m.H, pw = geo.painel[2] * m.W, ph = geo.painel[3] * m.H;
    if (ar.modo === 'mover') {
      $b.css({ left: Math.min(Math.max(ar.l0 + dx, pl), pl + pw - ar.w0) + 'px', top: Math.min(Math.max(ar.t0 + dy, pt), pt + ph - ar.h0) + 'px' });
    } else {
      $b.css({ width: Math.min(Math.max(ar.w0 + dx, 24), pl + pw - ar.l0) + 'px' });
    }
  });
  $(document).on('pointerup pointercancel', '#legenda-caixa', function (e) {
    if (!ar) return;
    var $b = $(this), m = ar.m, modo = ar.modo; ar = null;
    var pl = m.ox + geo.painel[0] * m.W, pt = m.oy + geo.painel[1] * m.H, pw = geo.painel[2] * m.W, ph = geo.painel[3] * m.H;
    if (modo === 'mover') {
      var esq = (parseFloat($b.css('left')) - pl) / pw, base = ((pt + ph) - (parseFloat($b.css('top')) + $b.height())) / ph;
      Shiny.setInputValue('legenda_arrastada', { esq: esq, base: base, t: Date.now() }, { priority: 'event' });
    } else {
      Shiny.setInputValue('legenda_redimensionada', { largura: $b.width() / m.W, t: Date.now() }, { priority: 'event' });
    }
  });

  // ---- paletas: editor de cores, paletas guardadas no navegador ---------------------------------------------------------------------
  var CHAVE = 'gerador_paletas';
  window.PALETAS_SALVAS = {};
  function quadradinhos(cores) {
    return '<span class="op-cores">' + (cores || []).slice(0, 8).map(function (c) { return '<i style="background:' + c + '"></i>'; }).join('') + '</span>';
  }
  window.renderPaleta = {
    option: function (item, escape) {
      var v = item.value, cores = (window.PALETAS || {})[v] || (v.indexOf('salva:') === 0 ? window.PALETAS_SALVAS[v.slice(6)] : null);
      return '<div class="op-pal">' + quadradinhos(cores) + '<span>' + escape(item.label) + '</span></div>';
    },
    item: function (item, escape) { return '<div>' + escape(item.label) + '</div>'; }
  };
  function normHex(t) {
    t = (t || '').trim();
    if (/^[0-9a-fA-F]{3}$/.test(t)) t = '#' + t.split('').map(function (c) { return c + c; }).join('');
    else if (/^[0-9a-fA-F]{6}$/.test(t)) t = '#' + t;
    return /^#[0-9a-fA-F]{6}$/.test(t) ? t.toUpperCase() : (/^#[0-9a-fA-F]{3}$/.test(t) ? normHex(t.slice(1)) : null);
  }
  function listaHex() { return ($('#paleta_propria').val() || '').split(/[\s,;]+/).map(normHex).filter(Boolean); }
  function gravar(lista) { $('#paleta_propria').val(lista.join(', ')).trigger('input'); desenharChips(lista); }
  function desenharChips(lista) {
    var $c = $('#paleta-chips').empty();
    lista.forEach(function (h, i) {
      var $s = $('<span class="chip-cor">'), $i = $('<input type="color">').val(h).attr('data-i', i), $x = $('<button type="button" class="chip-x" title="Remover">&times;</button>').attr('data-i', i);
      $s.append($i, $('<em>').text(h), $x); $c.append($s);
    });
  }
  $(document).on('shiny:inputchanged', function (e) { if (e.name === 'paleta_propria') desenharChips((e.value || '').split(/[\s,;]+/).map(normHex).filter(Boolean)); });
  $(document).on('change', '#paleta-chips input[type=color]', function () { var l = listaHex(); l[+$(this).attr('data-i')] = this.value.toUpperCase(); gravar(l); });
  $(document).on('click', '#paleta-chips .chip-x', function () { var l = listaHex(); l.splice(+$(this).attr('data-i'), 1); gravar(l); });
  $(document).on('click', '#paleta-mais', function () { var l = listaHex(); l.push(l.length ? l[l.length - 1] : '#B3262E'); gravar(l); });
  $(document).on('click', '#paleta-inverter', function () { gravar(listaHex().reverse()); });
  $(document).on('click', '#paleta-limpar', function () { gravar([]); });
  $(document).on('shiny:connected', function () {
    var o = {}; try { o = JSON.parse(localStorage.getItem(CHAVE) || '{}') || {}; } catch (e) { o = {}; }
    if (Array.isArray(o)) o = {};
    window.PALETAS_SALVAS = o;
    Shiny.setInputValue('paletas_do_navegador', o, { priority: 'event' });
  });
  Shiny.addCustomMessageHandler('guardar_paletas', function (txt) {
    try { var o = JSON.parse(txt); if (Array.isArray(o)) o = {}; window.PALETAS_SALVAS = o; localStorage.setItem(CHAVE, JSON.stringify(o)); } catch (e) {}
  });
})();


// A conexão com o R caiu (computador suspenso, R encerrado...): mostra o que fazer, em vez de só deixar a tela cinza.
$(document).on('shiny:disconnected', function () {
  if (document.getElementById('cb-desconectado')) return;
  var d = document.createElement('div'); d.id = 'cb-desconectado';
  d.innerHTML = '<b>A conexão com o Cinabro caiu.</b> O seu último gráfico foi guardado sozinho. ' +
                '<button type="button" onclick="location.reload()">Recarregar e retomar</button> ' +
                '<span>(se não voltar, abra o Cinabro de novo pelo atalho)</span>';
  document.body.appendChild(d);
});
