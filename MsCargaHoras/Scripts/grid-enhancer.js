(function(global){
  'use strict';

  // ---- Helpers ----
  function getGridId(tbl){ return tbl && tbl.id ? tbl.id : (tbl._gid || (tbl._gid = 'grid-'+Math.random().toString(36).slice(2))); }
  function stateKey(tbl, colIndex){ return 'ge:'+ getGridId(tbl) +':c:'+colIndex; }
  function saveColState(tbl, colIndex, state){ try{ localStorage.setItem(stateKey(tbl,colIndex), JSON.stringify(state||{})); }catch(e){} }
  function loadColState(tbl, colIndex){ try{ var t = localStorage.getItem(stateKey(tbl,colIndex)); return t? JSON.parse(t): null; }catch(e){ return null; } }

  function parseMaybeNumberOrDate(text){
    var t = (text||'').trim();
    // Date dd/MM/yyyy HH:mm or dd/MM/yyyy
    var m = t.match(/^(\d{2})\/(\d{2})\/(\d{4})(?:\s+(\d{2}):(\d{2})(?::(\d{2}))?)?$/);
    if(m){
      var d = new Date(parseInt(m[3],10), parseInt(m[2],10)-1, parseInt(m[1],10), parseInt(m[4]||'0',10), parseInt(m[5]||'0',10), parseInt(m[6]||'0',10));
      return d.getTime();
    }
    var n = parseFloat(t.replace(/[^0-9.:-]/g,''));
    return isNaN(n) ? t.toLowerCase() : n;
  }

  function enhanceTable(tbl, options){
    if(!tbl || tbl.classList.contains('enhanced')) return;
    tbl.classList.add('enhanced');
    options = options || {};

    var thead = tbl.tHead; if(!thead || thead.rows.length === 0){ return; }
    var headerRow = thead.rows[0];

    // Capturar universo completo de valores por columna (sin filtros) una única vez
    try{
      if(!tbl._allValues){
        tbl._allValues = [];
        Array.prototype.forEach.call(headerRow.cells, function(_th, idx){
          // Mantener todas las opciones originales (sin limitar por visibles)
          tbl._allValues[idx] = buildUniqueValues(tbl, idx, false);
        });
      }
    }catch(e){}

    // Create or reuse summary badge for active filters + result count
    var badge = tbl._filterBadge;
    if(!badge){
      badge = document.createElement('div');
      badge.className = 'grid-filter-summary text-muted small d-flex align-items-center gap-2 ms-auto';
      badge.style.display = 'none';
      var btnClearAll = document.createElement('button'); btnClearAll.type='button'; btnClearAll.className='btn btn-sm btn-outline-secondary'; btnClearAll.innerHTML='<i class="bi bi-eraser"></i>'; btnClearAll.title='Limpiar todos los filtros'; btnClearAll.setAttribute('data-bs-toggle','tooltip');
      btnClearAll.addEventListener('click', function(ev){ ev.preventDefault(); ev.stopPropagation(); try{ clearAllFilters(tbl); }catch(e){} });
      var txt = document.createElement('span'); txt.className='me-1';
      var sep = document.createElement('span'); sep.textContent = '·'; sep.className='mx-1 opacity-50';
      var results = document.createElement('span'); results.className='badge bg-secondary-subtle text-secondary-emphasis'; results.textContent = '0';
      // Botón a la izquierda para evitar movimiento cuando cambia el texto
      badge.appendChild(btnClearAll);
      badge.appendChild(txt);
      badge.appendChild(sep);
      var resLbl = document.createElement('span'); resLbl.textContent = 'Resultados:'; resLbl.className='me-1'; badge.appendChild(resLbl);
      badge.appendChild(results);
      badge._txt = txt; badge._btnClearAll = btnClearAll;
      badge._results = results;
      // Insertar en cabecera de card si existe, de lo contrario antes de la tabla
      try{
        var card = tbl.closest('.card');
        if(card){
          var header = card.querySelector('.card-header');
          if(header){
            // Alinear a la derecha dentro del header de la card
            header.classList.add('d-flex','align-items-center');
            header.appendChild(badge);
          }
          else { card.insertBefore(badge, card.firstChild); }
        } else {
          tbl.parentNode.insertBefore(badge, tbl);
        }
      }catch(e){}
      tbl._filterBadge = badge;
    }

    // Utilities: ensure header layout (icons + title)
    function ensureHeaderLayout(th){
      if(th._prepared) return;
      var titleText = (th.textContent||'').trim();
      // clear text nodes, keep existing children (e.g., placed menus) temporarily
      while(th.firstChild){ th.removeChild(th.firstChild); }
      var inner = document.createElement('div'); inner.className='th-inner';
      var left = document.createElement('span'); left.className='th-icons-left';
      var right = document.createElement('span'); right.className='th-icons-right';
      var sortInd = document.createElement('span'); sortInd.className='sort-indicator'; sortInd.setAttribute('aria-hidden','true');
      var title = document.createElement('span'); title.className='th-title'; title.textContent = titleText;
      right.appendChild(sortInd);
      inner.appendChild(left); inner.appendChild(title); inner.appendChild(right);
      th.appendChild(inner);
      th._iconsLeft = left; th._iconsRight = right; th._sortInd = sortInd; th._prepared = true;
    }

    // Sorting
    var sortState = { col: 0, dir: 'asc' };
    function applySort(colIndex, dir){
      var tbody = tbl.tBodies[0]; if(!tbody) return;
      var rows = Array.prototype.slice.call(tbody.rows);
      rows.sort(function(a,b){
        var ta = a.cells[colIndex] ? a.cells[colIndex].textContent : '';
        var tb = b.cells[colIndex] ? b.cells[colIndex].textContent : '';
        var pa = parseMaybeNumberOrDate(ta);
        var pb = parseMaybeNumberOrDate(tb);
        var cmp = (typeof pa === 'number' && typeof pb === 'number') ? (pa - pb) : (''+pa).localeCompare(''+pb);
        return dir === 'asc' ? cmp : -cmp;
      });
      rows.forEach(function(r){ tbody.appendChild(r); });
      Array.prototype.forEach.call(headerRow.cells, function(h, idx){
        h.classList.remove('th-sort-asc','th-sort-desc');
        if(h._sortInd){ h._sortInd.textContent = ''; }
        if(idx === colIndex){
          h.classList.add(dir === 'asc' ? 'th-sort-asc' : 'th-sort-desc');
          if(h._sortInd){ h._sortInd.textContent = (dir === 'asc' ? '▲' : '▼'); }
        }
      });
      sortState.col = colIndex; sortState.dir = dir;
      // ensure menus get current values after sort
      try{ applyAllFiltersOnTable(tbl); }catch(e){}
    }
    Array.prototype.forEach.call(headerRow.cells, function(h, idx){
      ensureHeaderLayout(h);
      h.style.cursor = 'pointer';
      h.addEventListener('click', function(){
        var dir = (sortState.col === idx && sortState.dir === 'asc') ? 'desc' : 'asc';
        applySort(idx, dir);
      });
    });
    
    // Reactivar menús por columna de forma controlada
    try{ buildColumnMenus(tbl); }catch(e){}

    // Orden inicial por la primera columna
    applySort(0, 'asc');
    // Apply any existing filters + current global query
    try{ applyAllFiltersOnTable(tbl); }catch(e){}
  }

  function enhanceAll(){
    var tables = document.querySelectorAll('table.table:not(.ge-no)');
    tables.forEach(function(tbl){ try{ if(window.UiCommon){ UiCommon.standardizeGridView(tbl); } }catch(e){} enhanceTable(tbl); });
  }

  // Global quick filter (single textbox to filter all tables)
  var currentGlobalQuery = '';
  function applyGlobalFilter(query){
    currentGlobalQuery = (query||'').toLowerCase();
    var tables = document.querySelectorAll('table.table:not(.ge-no)');
    tables.forEach(function(tbl){ applyAllFiltersOnTable(tbl); });
  }

  function wireGlobalSearch(){
    var inp = document.getElementById('globalSearch');
    var btn = document.getElementById('btnGlobalClear');
    if(inp){ inp.addEventListener('input', function(){ applyGlobalFilter(this.value); }); }
    if(btn){ btn.addEventListener('click', function(){ if(inp){ inp.value=''; } applyGlobalFilter(''); }); }
  }

  // Fuente local (TRAC/ACT/TODOS) — filtra por columna "Fuente" sin postback
  function wireFuenteLocalFilter(){
    var ddl = document.getElementById('ddlFuente');
    if(!ddl) return;
    ddl.addEventListener('change', function(){
      var val = (ddl.value||'').toUpperCase();
      // Guardar preferencia
      try{ localStorage.setItem('ge:fuente', val); }catch(e){}
      // Para cada tabla, aplicar filtro de columna "Fuente"
      var tables = document.querySelectorAll('table.table');
      tables.forEach(function(tbl){
        try{
          var thead = tbl.tHead; if(!thead) return; var headerRow = thead.rows[0]; if(!headerRow) return;
          // buscar índice de columna Fuente
          var fuenteIdx = -1;
          Array.prototype.forEach.call(headerRow.cells, function(th, idx){ if(fuenteIdx===-1){ var t=(th.textContent||'').trim().toLowerCase(); if(t==='fuente'){ fuenteIdx = idx; } } });
          if(fuenteIdx===-1){ return; }
          // setear estado del filtro de columna
          tbl._filters = tbl._filters || {};
          if(val==='TODOS' || val==='') { tbl._filters[fuenteIdx] = []; }
          else { tbl._filters[fuenteIdx] = [val]; }
          // feedback visual en header si existe botón
          var th = headerRow.cells[fuenteIdx];
          if(th){
            if(val==='TODOS' || val===''){
              th.classList.remove('filter-active');
              var b = th.querySelector('.filter-btn'); if(b){ b.innerHTML='<i class="bi bi-funnel"></i>'; }
            } else {
              th.classList.add('filter-active');
              var b2 = th.querySelector('.filter-btn'); if(b2){ b2.innerHTML='<i class="bi bi-funnel-fill"></i>'; }
            }
          }
          applyAllFiltersOnTable(tbl);
        }catch(e){}
      });
    });
    // Restaurar preferencia guardada
    try{ var saved = localStorage.getItem('ge:fuente'); if(saved && ddl.value !== saved){ ddl.value = saved; ddl.dispatchEvent(new Event('change')); } }catch(e){}
  }

  // ---- Per-column multi-select filter menus ----
  function buildUniqueValues(tbl, colIndex, onlyVisible){
    var set = Object.create(null);
    var rows = tbl.tBodies[0] ? tbl.tBodies[0].rows : [];
    Array.prototype.forEach.call(rows, function(r){
      if(onlyVisible && r.style && r.style.display === 'none') return;
      var txt = (r.cells[colIndex] ? r.cells[colIndex].textContent : '').trim();
      set[txt] = true;
    });
    var vals = Object.keys(set).sort(function(a,b){ return a.localeCompare(b); });
    return vals;
  }

  function createMenu(th, values, onChange, opt){
    var container = document.createElement('div');
    container.className = 'filter-menu shadow p-2 bg-body rounded';
    container.style.display = 'none';
    container.innerHTML = '';
    // Header row: search + icon-only buttons
    var header = document.createElement('div');
    header.className = 'd-flex align-items-center gap-2 mb-2';
    var search = document.createElement('input');
    search.type = 'text'; search.className = 'form-control form-control-sm flex-grow-1'; search.placeholder = 'Buscar...';
    var btnAll = document.createElement('button'); btnAll.type='button'; btnAll.className='btn btn-sm btn-outline-primary ms-auto'; btnAll.innerHTML='<i class="bi bi-check2-all"></i>'; btnAll.title='Seleccionar todos'; btnAll.setAttribute('data-bs-toggle','tooltip');
    var btnNone = document.createElement('button'); btnNone.type='button'; btnNone.className='btn btn-sm btn-outline-secondary'; btnNone.innerHTML='<i class="bi bi-slash-circle"></i>'; btnNone.title='Ninguno'; btnNone.setAttribute('data-bs-toggle','tooltip');
    var btnClear = document.createElement('button'); btnClear.type='button'; btnClear.className='btn btn-sm btn-outline-danger'; btnClear.innerHTML='<i class="bi bi-eraser"></i>'; btnClear.title='Limpiar filtro'; btnClear.setAttribute('data-bs-toggle','tooltip');
    var btnClose = document.createElement('button'); btnClose.type='button'; btnClose.className='btn btn-sm btn-outline-dark'; btnClose.innerHTML='<i class="bi bi-x-lg"></i>'; btnClose.title='Cerrar'; btnClose.setAttribute('data-bs-toggle','tooltip');
    header.appendChild(search); header.appendChild(btnAll); header.appendChild(btnNone); header.appendChild(btnClear); header.appendChild(btnClose);
    container.appendChild(header);
    // List
    var list = document.createElement('div'); list.className = 'filter-list'; list.style.maxHeight='240px'; list.style.overflow='auto';
    container.appendChild(list);
    var selectedSet = new Set((opt && opt.selected) || []);
    var allValues = (values||[]).slice();
    if(opt && opt.search){ search.value = opt.search; }
    function renderList(){
      list.innerHTML='';
      var q = (search.value||'').toLowerCase();
      allValues.forEach(function(v){
        if(q && v.toLowerCase().indexOf(q)===-1) return;
        var id = 'chk_'+Math.random().toString(36).slice(2);
        var wrap = document.createElement('div'); wrap.className = 'form-check';
        var cb = document.createElement('input'); cb.type='checkbox'; cb.className='form-check-input'; cb.id=id; cb.value=v;
        var lb = document.createElement('label'); lb.className='form-check-label'; lb.setAttribute('for',id); lb.textContent = v || '(vacío)';
        cb.checked = selectedSet.has(v);
        wrap.appendChild(cb); wrap.appendChild(lb); list.appendChild(wrap);
        cb.addEventListener('change', function(){ if(cb.checked){ selectedSet.add(v); } else { selectedSet.delete(v); } onChange(); });
      });
    }
    renderList();
    search.addEventListener('input', renderList);
    // Actions events
    function setSelectedVisible(all){
      var boxes = list.querySelectorAll('input[type="checkbox"]');
      boxes.forEach(function(cb){ cb.checked = !!all; if(all){ selectedSet.add(cb.value);} else { selectedSet.delete(cb.value);} });
      onChange();
    }
    btnAll.addEventListener('click', function(ev){ ev.preventDefault(); ev.stopPropagation(); setSelectedVisible(true); });
    btnNone.addEventListener('click', function(ev){ ev.preventDefault(); ev.stopPropagation(); setSelectedVisible(false); });
    btnClear.addEventListener('click', function(ev){ ev.preventDefault(); ev.stopPropagation(); selectedSet.clear(); search.value=''; renderList(); onChange(true); });
    btnClose.addEventListener('click', function(ev){ ev.preventDefault(); ev.stopPropagation(); if(container._onReflow){ window.removeEventListener('scroll', container._onReflow, true); window.removeEventListener('resize', container._onReflow); container._onReflow=null; } container.style.display='none'; });
    // Evitar que clicks dentro del menú lo cierren por el manejador global
    container.addEventListener('click', function(ev){ ev.stopPropagation(); });
    th.appendChild(container);
    // Tooltips deshabilitados globalmente
    return {container: container, list: list, search: search,
            getSelected: function(){ return Array.from(selectedSet); },
            updateValues: function(newVals){ allValues = (newVals||[]).slice(); renderList(); },
            clearAll: function(){ selectedSet.clear(); search.value=''; renderList(); }
           };
  }

  function placeMenu(th, menu){
    var r = th.getBoundingClientRect();
    var mw = Math.max(320, menu.container.offsetWidth || 320);
    var top = r.bottom + 4;
    var left = Math.min(window.innerWidth - mw - 8, r.right - mw);
    if(left < 8) left = 8;
    var maxH = Math.max(120, window.innerHeight - top - 16);
    menu.container.style.position = 'fixed';
    menu.container.style.left = left + 'px';
    menu.container.style.top = top + 'px';
    menu.container.style.maxHeight = maxH + 'px';
  }

  function toggleMenu(th, menu){
    var willOpen = menu.container.style.display === 'none' || !menu.container.style.display;
    document.querySelectorAll('.filter-menu').forEach(function(m){ m.style.display='none'; });
    if(willOpen){
      try{ if(menu.updateValues && th){ var tbl = th.closest('table'); var idx = Array.prototype.indexOf.call(th.parentNode.children, th); var vals = buildUniqueValues(tbl, idx, true); if(!vals || vals.length===0){ vals = buildUniqueValues(tbl, idx, false); } menu.updateValues(vals); } }catch(e){}
      menu.container.style.display = 'block';
      placeMenu(th, menu);
      function onReflow(){ placeMenu(th, menu); }
      menu._onReflow = onReflow;
      window.addEventListener('scroll', onReflow, true);
      window.addEventListener('resize', onReflow);
    } else {
      menu.container.style.display = 'none';
      if(menu._onReflow){ window.removeEventListener('scroll', menu._onReflow, true); window.removeEventListener('resize', menu._onReflow); menu._onReflow=null; }
    }
  }

  function collectSelections(menu){
    var sel = [];
    menu.container.querySelectorAll('.filter-list input[type="checkbox"]').forEach(function(cb){ if(cb.checked) sel.push(cb.value); });
    return sel;
  }

  function applyAllFiltersOnTable(tbl){
    var rows = tbl.tBodies[0] ? tbl.tBodies[0].rows : [];
    var filters = tbl._filters || {};
    var visibleCount = 0;
    Array.prototype.forEach.call(rows, function(r){
      // global query
      var matchGlobal = true;
      if(currentGlobalQuery){
        matchGlobal = false;
        for(var i=0;i<r.cells.length;i++){
          var txt = (r.cells[i] ? r.cells[i].textContent : '').toLowerCase();
          if(txt.indexOf(currentGlobalQuery)!==-1){ matchGlobal = true; break; }
        }
      }
      // column filters (AND)
      var matchCols = true;
      for(var col in filters){ if(!filters.hasOwnProperty(col)) continue; var arr = filters[col]; if(!arr || arr.length===0) continue; var cellTxt = (r.cells[col] ? r.cells[col].textContent : ''); if(arr.indexOf(cellTxt)===-1){ matchCols = false; break; } }
      var vis = (matchGlobal && matchCols);
      r.style.display = vis ? '' : 'none';
      if(vis) visibleCount++;
    });
    // Update badge with active filters count
    var activeCols = 0; for(var k in filters){ if(filters.hasOwnProperty(k) && filters[k] && filters[k].length>0) activeCols++; }
    if(tbl._filterBadge){
      if(activeCols>0){
        tbl._filterBadge.style.display = '';
        if(tbl._filterBadge._txt){ tbl._filterBadge._txt.textContent = 'Filtros: ' + activeCols; }
      } else {
        if(tbl._filterBadge._txt){ tbl._filterBadge._txt.textContent = ''; }
        // ocultar y asegurar que el tooltip no quede colgado
        if(tbl._filterBadge._btnClearAll && tbl._filterBadge._btnClearAll._tt){ try{ tbl._filterBadge._btnClearAll._tt.hide(); }catch(e){} }
        // Mantener visible si queremos mostrar resultados aunque no haya filtros
        tbl._filterBadge.style.display = '';
      }
      // Resultados visibles
      if(tbl._filterBadge._results){ tbl._filterBadge._results.textContent = String(visibleCount); }
      // Inicializar tooltip una sola vez
      try{
        if(window.bootstrap && tbl._filterBadge._btnClearAll && !tbl._filterBadge._btnClearAll._tt){
          tbl._filterBadge._btnClearAll._tt = new bootstrap.Tooltip(tbl._filterBadge._btnClearAll, {placement:'top', trigger:'hover focus'});
        }
      }catch(e){}
    }

    // No modificar el universo del menú: debe mantener todas las opciones originales
  }

  function clearAllFilters(tbl){
    try{
      var thead = tbl.tHead; if(!thead) return; var headerRow = thead.rows[0]; if(!headerRow) return;
      tbl._filters = {};
      Array.prototype.forEach.call(headerRow.cells, function(th, idx){
        if(th.classList.contains('no-filter')) return;
        // reset visual state
        th.classList.remove('filter-active');
        var btn = th.querySelector('.filter-btn');
        if(btn){ btn.innerHTML = '<i class="bi bi-funnel"></i>'; }
        // reset menu state if available
        if(th._menu && th._menu.clearAll){ th._menu.clearAll(); }
        // persist cleared state
        saveColState(tbl, idx, {selected: [], search: ''});
      });
      applyAllFiltersOnTable(tbl);
    }catch(e){}
  }

  function buildColumnMenus(tbl){
    // Feature toggle: permitir activar menús más adelante sin tocar el resto
    if (window.GridEnhancerConfig && window.GridEnhancerConfig.enableColumnMenus === false) {
      return;
    }
    var thead = tbl.tHead; if(!thead) return;
    var headerRow = thead.rows[0]; if(!headerRow) return;
    tbl._filters = tbl._filters || {};
    Array.prototype.forEach.call(headerRow.cells, function(th, colIndex){
      // skip select column
      if(((th.textContent||'').trim().toLowerCase())==='sel' || th.classList.contains('no-filter')) return;
      th.classList.add('th-filter');
      // Prepare consistent layout containers
      if(!th._prepared){ ensureHeaderLayout(th); }
      // button
      var btn = document.createElement('button'); btn.type='button'; btn.className='btn btn-sm btn-outline-secondary me-1 filter-btn'; btn.innerHTML='<i class="bi bi-funnel"></i>';
      // Place button in left icon area
      if(th._iconsLeft){ th._iconsLeft.appendChild(btn); } else { th.insertBefore(btn, th.firstChild); }
      // menu
      var values = buildUniqueValues(tbl, colIndex);
      var prev = loadColState(tbl, colIndex) || {};
      var menu = createMenu(th, values, function(clear){
        var arr = clear ? [] : (menu.getSelected ? menu.getSelected() : collectSelections(menu));
        tbl._filters[colIndex] = clear ? [] : arr;
        // visual feedback
        var active = arr && arr.length>0;
        th.classList.toggle('filter-active', active);
        btn.innerHTML = active ? '<i class="bi bi-funnel-fill"></i>' : '<i class="bi bi-funnel"></i>';
        saveColState(tbl, colIndex, {selected: arr, search: menu.search.value||''});
        applyAllFiltersOnTable(tbl);
      }, {selected: prev.selected||[], search: prev.search||''});
      // Persist search text while escribe
      menu.search.addEventListener('input', function(){ saveColState(tbl, colIndex, {selected: (menu.getSelected? menu.getSelected(): []), search: menu.search.value||''}); });
      // Restore filter to table state on init
      if(prev.selected && prev.selected.length>0){
        tbl._filters[colIndex] = prev.selected.slice();
        th.classList.add('filter-active');
        btn.innerHTML = '<i class="bi bi-funnel-fill"></i>';
      }
      // store menu reference for later updates
      th._menu = menu; menu._tbl = tbl; menu._col = colIndex;
      btn.addEventListener('click', function(ev){ ev.stopPropagation();
        // Siempre presentar el universo completo original de la columna
        try{
          if(tbl._allValues && tbl._allValues[colIndex] && menu.updateValues){ menu.updateValues(tbl._allValues[colIndex]); }
        }catch(e){}
        toggleMenu(th, menu);
      });
    });
    function onDocPointer(e){
      var isInsideMenu = !!e.target.closest('.filter-menu');
      var isFilterBtn = !!e.target.closest('.filter-btn');
      if(!isInsideMenu && !isFilterBtn){
        document.querySelectorAll('.filter-menu').forEach(function(m){ m.style.display='none'; });
      }
    }
    document.addEventListener('pointerdown', onDocPointer);
    document.addEventListener('keydown', function(e){ if(e.key==='Escape'){ document.querySelectorAll('.filter-menu').forEach(function(m){ m.style.display='none'; }); } });
  }

  document.addEventListener('DOMContentLoaded', enhanceAll);
  document.addEventListener('DOMContentLoaded', wireGlobalSearch);
  document.addEventListener('DOMContentLoaded', wireFuenteLocalFilter);
  try{
    if(window.Sys && Sys.WebForms){
      Sys.WebForms.PageRequestManager.getInstance().add_endRequest(function(){ enhanceAll(); wireGlobalSearch(); wireFuenteLocalFilter(); });
    }
  }catch(e){}

  // Export simple API for future use
  // Utilidad: envolver en card y mejorar en un paso
  function wrapAndEnhance(grid, title){ try{ if(window.UiCommon){ UiCommon.wrapGridInCard(grid, title||'Datos'); } }catch(e){} enhanceTable(grid); }

  global.GridEnhancer = { enhance: enhanceTable, enhanceAll: enhanceAll, filter: applyGlobalFilter, wrapAndEnhance: wrapAndEnhance };

})(window);


