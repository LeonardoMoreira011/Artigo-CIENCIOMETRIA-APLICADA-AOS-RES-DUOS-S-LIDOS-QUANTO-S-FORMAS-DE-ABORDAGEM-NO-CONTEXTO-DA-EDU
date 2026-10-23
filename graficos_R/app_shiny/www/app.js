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
  // copiar o modelo (texto da configuração) para a área de transferência
  function copiarTexto(t, cb) {
    (navigator.clipboard ? navigator.clipboard.writeText(t) : Promise.reject()).catch(function () {
      var a = document.createElement('textarea'); a.value = t; document.body.appendChild(a); a.select();
      try { document.execCommand('copy'); } catch (e) {} document.body.removeChild(a);
    }).then(function () { if (cb) cb(); });
  }
  Shiny.addCustomMessageHandler('copiar_texto', function (t) { copiarTexto(t); });
  $(document).on('click', '#copiar-modelo', function () {
    var b = this, orig = b.textContent, ok = $(b).data('copiado') || 'Copiado!', t = $('#modelo-saida').val();
    copiarTexto(t, function () { b.textContent = ok; setTimeout(function () { b.textContent = orig; }, 1600); });
  });
  // idioma: o seletor do cabeçalho recarrega a página com ?idioma=xx (lembra a escolha neste navegador)
  $(document).on('change', '#idioma_sel', function () { try { localStorage.setItem('cinabro_idioma', this.value); } catch (e) {} location.search = '?idioma=' + this.value; });
  try { var salvo = localStorage.getItem('cinabro_idioma');
        if (salvo && salvo !== 'pt' && location.search.indexOf('idioma=') < 0) location.search = '?idioma=' + salvo; } catch (e) {}
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
  function abrirPainel(id, manter) {
    var $p = $('#bloco-' + id); if (!$p.length) return;
    $('.painel').removeClass('ativo'); $p.addClass('ativo');
    $('.trilho-btn').removeClass('ativo').filter('[data-painel="' + id + '"]').addClass('ativo');
    $('.estudio').addClass('gaveta-aberta').removeClass('max'); $('.gaveta').scrollTop(0);
    try { localStorage.setItem('cinabro_painel', id); } catch (e) {}
    if (!manter) avisarPalco();
  }
  $(document).on('click', '.trilho-btn', function () {
    var id = $(this).data('painel');
    if ($(this).hasClass('ativo') && $('.estudio').hasClass('gaveta-aberta')) { $('.estudio').removeClass('gaveta-aberta'); $(this).removeClass('ativo'); avisarPalco(); }
    else abrirPainel(id);
  });
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
  Shiny.addCustomMessageHandler('abrir_painel', function (m) {
    abrirPainel(m.id, true);
    if (m.cartao) setTimeout(function () { var el = document.getElementById(m.cartao); if (!el) return; var $g = $(el).closest('.grupo'); $g[0] && $g[0].scrollIntoView({ block: 'center' }); $g.addClass('flash'); setTimeout(function () { $g.removeClass('flash'); }, 1600); }, 350);
    avisarPalco();
  });
  $(function () { ajustarTopo(); abrirPainel('dados', true); setTimeout(function () { ajustarTopo(); avisarPalco(); }, 700); });
  $(window).on('resize', function () { ajustarTopo(); clearTimeout(window.__rz); window.__rz = setTimeout(function () { var w = $('.previa-quadro').innerWidth(); if (w) Shiny.setInputValue('palco_larg', Math.round(w), { priority: 'event' }); }, 500); });
  $(document).on('shiny:connected', function () { setTimeout(avisarPalco, 600); });

  // ---- caixa da legenda: arrastar (posição) e puxar a alça (largura) sobre a prévia ------------------------------------------
  var geo = null, ar = null;
  function host() { return document.querySelector('.previa-quadro'); }
  function imagem() { return document.querySelector('#previa img'); }
  function medidas() {
    var im = imagem(), h = host(); if (!im || !h || !geo || !geo.ok) return null;
    var r = im.getBoundingClientRect(), hr = h.getBoundingClientRect();
    return { W: r.width, H: r.height, ox: r.left - hr.left + h.scrollLeft, oy: r.top - hr.top + h.scrollTop };
  }
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
    var $z = $('.zona[data-z="' + pop.k + '"]'), $p = $('#popover-edicao'), h = host(); if (!$z.length || !$p.length) return;
    var zl = parseFloat($z.css('left')), zt = parseFloat($z.css('top')), zh = $z.outerHeight();
    var esq = Math.max(6, Math.min(zl, h.scrollLeft + h.clientWidth - $p.outerWidth() - 6)), topo = zt + zh + 6;
    if (topo + $p.outerHeight() > h.scrollTop + h.clientHeight) topo = Math.max(zt - $p.outerHeight() - 6, 6);
    $p.css({ left: esq, top: topo });
  }
  function abrirPopover(k) {
    fecharPopover();
    var $p = $('<div id="popover-edicao"><div class="pop-cab"><b></b><button type="button" class="pop-x">&times;</button></div><div class="pop-corpo"></div></div>');
    $p.find('b').text(rotulo(k)); $p.find('.pop-x').attr('title', rotulo('fechar'));
    var itens = [];
    EDIT[k].forEach(function (id) {
      var node = $('#' + id).closest('.campo')[0]; if (!node) return;
      itens.push({ node: node, parent: node.parentNode, next: node.nextSibling }); $p.find('.pop-corpo').append(node);
    });
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
    if (pop && !$(e.target).closest('#popover-edicao, .zona, .selectize-dropdown, .modal').length) fecharPopover();
  });
  $(document).on('keydown', function (e) { if (e.key === 'Escape' && pop) { fecharPopover(); e.stopImmediatePropagation(); } });

  function colocar() {
    colocarZonas();
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
