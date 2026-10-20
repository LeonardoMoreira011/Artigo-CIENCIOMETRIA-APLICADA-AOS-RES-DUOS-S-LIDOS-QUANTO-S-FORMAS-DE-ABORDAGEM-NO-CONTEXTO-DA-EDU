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
})();
