(function(global){
  'use strict';

  // Spinner overlay API (usa el overlay definido en Site.Master)
  function showLoading(){ try{ var o=document.getElementById('loadingOverlay'); if(o) o.classList.add('active'); }catch(e){} }
  function hideLoading(){ try{ var o=document.getElementById('loadingOverlay'); if(o) o.classList.remove('active'); }catch(e){} }

  // Botón estándar: crea un botón con clase y comportamiento coherente
  function createButton(opts){
    opts = opts||{};
    var b = document.createElement('button');
    b.type = opts.type||'button';
    b.className = opts.className||'btn btn-primary d-flex align-items-center gap-1';
    if(opts.title){ b.title = opts.title; b.setAttribute('data-bs-toggle','tooltip'); }
    if(opts.icon){ var i=document.createElement('i'); i.className = opts.icon; b.appendChild(i); }
    if(opts.text){ var s=document.createElement('span'); s.textContent = opts.text; b.appendChild(s); }
    if(typeof opts.onClick === 'function'){
      b.addEventListener('click', function(ev){ try{ ev.preventDefault(); showLoading(); }catch(e){} finally { try{ opts.onClick(ev); }catch(e){} } });
    }
    return b;
  }

  // Toast/alert simple (usa Bootstrap Toast si está, sino fallback a alert)
  function showToast(message, type){
    try{ if(global.AppUi && global.AppUi.enableToasts === false){ return; } }catch(e){}
    try{
      type = type || 'info';
      var container = document.getElementById('toastContainer');
      if(!container){ alert(message); return; }
      // Limitar el número de toasts simultáneos para evitar acumulación visual
      try{
        var exists = container.querySelectorAll('.toast');
        if(exists && exists.length >= 3){
          // eliminar los más antiguos
          var removeCount = exists.length - 2;
          for(var i=0;i<removeCount;i++){ try{ exists[i].parentNode.removeChild(exists[i]); }catch(e){} }
        }
      }catch(e){}

      var wrapper = document.createElement('div');
      var bg = (type==='danger'?'danger':type==='success'?'success':type==='warning'?'warning':'primary');
      wrapper.className = 'toast align-items-center text-bg-' + bg + ' border-0';
      wrapper.setAttribute('role','alert');
      wrapper.setAttribute('aria-live','assertive');
      wrapper.setAttribute('aria-atomic','true');
      wrapper.innerHTML = '<div class="d-flex"><div class="toast-body"></div><button type="button" class="btn-close btn-close-white me-2 m-auto" data-bs-dismiss="toast" aria-label="Close"></button></div>';
      wrapper.querySelector('.toast-body').textContent = message;
      container.appendChild(wrapper);
      try{
        if(window.bootstrap && bootstrap.Toast){
          var t = new bootstrap.Toast(wrapper, { delay: 3500, autohide: true });
          // Seguridad extra: limpiar si por algún motivo no se oculta
          var safety = setTimeout(function(){ try{ wrapper.classList.remove('show'); }catch(e){} try{ wrapper.parentNode && wrapper.parentNode.removeChild(wrapper); }catch(e){} }, 6000);
          wrapper.addEventListener('hidden.bs.toast', function(){ try{ clearTimeout(safety); }catch(e){} try{ container.removeChild(wrapper); }catch(e){} });
          t.show();
        } else {
          // Fallback
          setTimeout(function(){ try{ container.removeChild(wrapper); }catch(e){} }, 4000);
        }
      }catch(e){ setTimeout(function(){ try{ container.removeChild(wrapper); }catch(_){} }, 3500); }
    }catch(e){ try{ alert(message); }catch(_){} }
  }

  // Config por defecto de grillas
  var defaultGridOptions = {
    classes: 'table table-striped table-hover align-middle',
    headerClass: 'table-dark',
    pageSize: 10,
    allowSorting: true,
    emptyText: 'Sin datos para mostrar.'
  };

  // Aplica estilos/atributos estándar a GridView renderizado
  function standardizeGridView(grid){
    if(!grid) return;
    grid.classList.add('table','table-striped','table-hover','align-middle');
    try{
      var thead = grid.tHead; if(thead && thead.rows[0]){ thead.rows[0].classList.add('table-dark'); }
    }catch(e){}
  }

  // Crea un group box (card) para una grilla existente: mueve el grid dentro de la card
  function wrapGridInCard(grid, title){
    try{
      if(!grid || grid._wrapped) return;
      var container = grid.closest('.table-responsive') || grid.parentElement;
      if(!container) return;
      var outer = document.createElement('fieldset'); outer.className = 'card shadow-sm mb-3';
      var legend = document.createElement('legend'); legend.className = 'card-header h5 mb-0'; legend.textContent = title || 'Datos';
      var body = document.createElement('div'); body.className = 'card-body';
      grid.parentElement.insertBefore(outer, container);
      outer.appendChild(legend);
      outer.appendChild(body);
      body.appendChild(container);
      grid._wrapped = true;
    }catch(e){}
  }

  global.UiCommon = {
    showLoading: showLoading,
    hideLoading: hideLoading,
    createButton: createButton,
    standardizeGridView: standardizeGridView,
    wrapGridInCard: wrapGridInCard,
    showToast: showToast,
    defaults: defaultGridOptions
  };
})(window);


