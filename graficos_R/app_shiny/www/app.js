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
    var t = $('#codigo-txt').text(), b = this;
    (navigator.clipboard ? navigator.clipboard.writeText(t) : Promise.reject()).catch(function () {
      var a = document.createElement('textarea'); a.value = t; document.body.appendChild(a); a.select(); document.execCommand('copy'); document.body.removeChild(a);
    }).then(function () { b.textContent = 'Copiado!'; setTimeout(function () { b.textContent = 'Copiar'; }, 1600); });
  });
  // clicar num atalho do índice abre o bloco
  $(document).on('click', '.passos-mini a', function () { var d = document.querySelector($(this).attr('href')); if (d) d.open = true; });

  // ---- caixa da legenda: arrastar (posição) e puxar a alça (largura) sobre a prévia ------------------------------------------
  var geo = null, ar = null;
  function host() { return document.querySelector('.previa-quadro'); }
  function imagem() { return document.querySelector('#previa img'); }
  function medidas() {
    var im = imagem(), h = host(); if (!im || !h || !geo || !geo.ok) return null;
    var r = im.getBoundingClientRect(), hr = h.getBoundingClientRect();
    return { W: r.width, H: r.height, ox: r.left - hr.left + h.scrollLeft, oy: r.top - hr.top + h.scrollTop };
  }
  function colocar() {
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
})();
