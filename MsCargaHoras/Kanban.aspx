<%@ Page Title="Kanban" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="Kanban.aspx.cs" Inherits="MsCargaHoras.Kanban" %>

<asp:Content ID="BodyContent" ContentPlaceHolderID="MainContent" runat="server">

    <div class="py-4">
        <!-- Toolbar de búsqueda global (igual a la de Inicio) -->
        <div id="toolbarSearch" class="toolbar sticky-top search bg-body-tertiary border-bottom" style="height: var(--toolbar-h);">
            <div class="container-fluid px-3 px-md-4 px-lg-5 py-2">
                <div class="controls d-flex flex-nowrap align-items-center gap-2 overflow-auto">
                    <input id="globalSearch" type="text" class="form-control flex-grow-1" placeholder="Buscar en todo el tablero..." />
                    <button id="btnGlobalClear" type="button" class="btn btn-outline-secondary btn-sm">Limpiar</button>
                </div>
            </div>
        </div>
            <div class="d-flex flex-wrap align-items-end justify-content-between gap-3 mb-3">
            <div>
                <h1 class="h4 mb-0">Tablero Kanban</h1>
                <p class="text-muted mb-0">Organiza tus tareas pendientes por estado. Arrastra y suelta las tarjetas entre columnas.</p>
            </div>
            <div class="d-flex align-items-end gap-2">
                <div class="pb-1 d-none">
                    <asp:Button ID="btnAplicar" runat="server" Text="Actualizar" CssClass="btn btn-primary d-none" OnClick="btnAplicar_Click" />
                </div>
                <div class="pb-1 d-flex gap-2">
                    <button type="button" class="btn btn-outline-primary" id="btnViewKanban">Vista Kanban</button>
                    <button type="button" class="btn btn-outline-secondary" id="btnViewGrid">Vista Grilla</button>
                </div>
            </div>
        </div>

        <asp:UpdatePanel ID="upKanban" runat="server" UpdateMode="Conditional">
            <ContentTemplate>
                <style>
                    .kanban-board{ display:grid; grid-template-columns: repeat(5, minmax(220px, 1fr)); gap: 12px; align-items:start; }
                    .kanban-col{ background: var(--surface-1); border: 1px solid var(--bs-border-color); border-radius: .5rem; min-height: 40vh; max-height: 70vh; display:flex; flex-direction:column; }
                    .kanban-col-header{ padding:.5rem .75rem; border-bottom:1px solid var(--bs-border-color); font-weight:600; background: var(--surface-2); }
                    .kanban-list{ padding:.5rem; overflow:auto; flex:1; display:flex; flex-direction:column; gap:.5rem; }
                    .kanban-card{ background: var(--bs-card-bg); border:1px solid var(--bs-border-color); border-radius:.5rem; padding:.5rem .5rem; cursor:grab; box-shadow:0 1px 1px rgba(0,0,0,.04); }
                    .kanban-card.dragging{ opacity:.6; }
                    .kanban-drop-hover{ outline:2px dashed var(--bs-primary); outline-offset:-4px; }
                    .kanban-card .title{ font-weight:600; margin-bottom:.25rem; }
                    .kanban-card .meta{ font-size:.85rem; color: var(--bs-secondary-color); display:flex; flex-wrap:wrap; gap:.5rem; }
                    .kanban-card .meta .badge{ font-weight:500; }
                    @media (max-width: 991.98px){ .kanban-board{ grid-template-columns: 1fr; } }
                </style>

                <asp:SqlDataSource ID="dsKanban" runat="server" ConnectionString="<%$ ConnectionStrings:LABTRACConnectionString %>"
                    SelectCommand="AGLTRAC_ObtenerTareasAsignadas" SelectCommandType="StoredProcedure" OnSelecting="dsKanban_Selecting" OnSelected="SqlDataSource_Selected" CancelSelectOnNullParameter="true" EnableCaching="true" CacheDuration="60" CacheExpirationPolicy="Sliding">
                </asp:SqlDataSource>

                <!-- Resumen -->
                <div class="card shadow-sm mb-3">
                    <div class="card-header h5 mb-0 d-flex justify-content-between align-items-center">
                        <span>Resumen</span>
                        <div class="d-flex align-items-center gap-2 small text-muted">
                            <span>Total: <span id="lblTotalTareas" class="badge bg-secondary-subtle text-secondary-emphasis">0</span></span>
                            <span>Vencidas: <span id="lblVencidas" class="badge bg-danger">0</span></span>
                        </div>
                    </div>
                    <div class="card-body">
                        <div class="text-muted">Usá la búsqueda global para filtrar tarjetas y la grilla. En la grilla disponés de filtros por columna y ordenamiento.</div>
                    </div>
                </div>

                <!-- Lista oculta de items para clonar en columnas via JS -->
                <asp:Repeater ID="rptItems" runat="server" DataSourceID="dsKanban">
                    <HeaderTemplate>
                        <div id="kanbanAllItems" class="d-none">
                    </HeaderTemplate>
                    <ItemTemplate>
                        <div class="kanban-card" draggable="true"
                             data-link="<%# Eval("Link") %>"
                             data-title="<%# Eval("Titulo") %>"
                             data-tipo="<%# Eval("type") %>"
                             data-cliente="<%# Eval("Cliente") %>"
                             data-proyecto="<%# Eval("Proyecto") %>"
                             data-fecha="<%# Eval("FechaComprometida","{0:yyyy-MM-dd HH:mm}") %>"
                             data-fuente="<%# Eval("Fuente") %>">
                            <div class="title">
                                <a href="<%# Eval("Link") %>" target="_blank" rel="noopener noreferrer"><%# Eval("Titulo") %></a>
                            </div>
                            <div class="meta">
                                <span class="badge bg-secondary-subtle text-secondary-emphasis"><%# Eval("type") %></span>
                                <span><i class="bi bi-building"></i> <%# Eval("Cliente") %></span>
                                <span><i class="bi bi-diagram-3"></i> <%# Eval("Proyecto") %></span>
                                <span class="text-nowrap"><i class="bi bi-calendar-event"></i> <%# Eval("FechaComprometida","{0:dd/MM/yyyy HH:mm}") %></span>
                                <span class="badge bg-dark-subtle text-dark-emphasis"><%# Eval("Fuente") %></span>
                            </div>
                        </div>
                    </ItemTemplate>
                    <FooterTemplate>
                        </div>
                    </FooterTemplate>
                </asp:Repeater>

                <!-- Columnas Kanban -->
                <div class="kanban-board" id="kanbanBoard">
                    <div class="kanban-col" data-col="backlog">
                        <div class="kanban-col-header">Backlog <span class="badge bg-secondary-subtle text-secondary-emphasis ms-1" data-counter="backlog">0</span></div>
                        <div class="kanban-list" id="col-backlog"></div>
                    </div>
                    <div class="kanban-col" data-col="todo">
                        <div class="kanban-col-header">Por hacer <span class="badge bg-secondary-subtle text-secondary-emphasis ms-1" data-counter="todo">0</span></div>
                        <div class="kanban-list" id="col-todo"></div>
                    </div>
                    <div class="kanban-col" data-col="doing">
                        <div class="kanban-col-header">En curso <span class="badge bg-secondary-subtle text-secondary-emphasis ms-1" data-counter="doing">0</span></div>
                        <div class="kanban-list" id="col-doing"></div>
                    </div>
                    <div class="kanban-col" data-col="testing">
                        <div class="kanban-col-header">En pruebas <span class="badge bg-secondary-subtle text-secondary-emphasis ms-1" data-counter="testing">0</span></div>
                        <div class="kanban-list" id="col-testing"></div>
                    </div>
                    <div class="kanban-col" data-col="done">
                        <div class="kanban-col-header">Hecho <span class="badge bg-secondary-subtle text-secondary-emphasis ms-1" data-counter="done">0</span></div>
                        <div class="kanban-list" id="col-done"></div>
                    </div>
                </div>

                <!-- Grilla alternativa -->
                <div id="gridContainer" class="card shadow-sm d-none">
                    <div class="card-header h5 mb-0">Tareas (Grilla)</div>
                    <div class="card-body">
                        <div class="table-responsive grid-scroll">
                            <asp:GridView ID="grdTrac" runat="server" CssClass="table table-striped table-hover align-middle" GridLines="None" AutoGenerateColumns="False" DataSourceID="dsKanban" OnDataBound="grdTrac_DataBound" UseAccessibleHeader="true">
                                <HeaderStyle CssClass="table-dark" />
                                <Columns>
                                    <asp:HyperLinkField DataTextField="Titulo" HeaderText="Título" DataNavigateUrlFields="Link" DataNavigateUrlFormatString="{0}" Target="_blank" />
                                    <asp:BoundField DataField="type" HeaderText="Tipo" />
                                    <asp:BoundField DataField="Cliente" HeaderText="Cliente" />
                                    <asp:BoundField DataField="Proyecto" HeaderText="Proyecto" />
                                    <asp:BoundField DataField="FechaInicio" HeaderText="Fecha inicio" DataFormatString="{0:dd/MM/yyyy HH:mm}" HtmlEncode="false" />
                                    <asp:BoundField DataField="FechaComprometida" HeaderText="Fecha comprometida" DataFormatString="{0:dd/MM/yyyy HH:mm}" HtmlEncode="false" />
                                    <asp:BoundField DataField="Fuente" HeaderText="Fuente" />
                                </Columns>
                            </asp:GridView>
                        </div>
                    </div>
                </div>

                <asp:HiddenField ID="hidUserKey" runat="server" />

                <script type="text/javascript">
                    (function(){
                        var board, lists, storageKey;
                        function keyForUser(){
                            try{
                                var user = (document.getElementById('<%= hidUserKey.ClientID %>')?.value || '').trim();
                                return 'kanban:states:' + (user || 'anon');
                            }catch(e){ return 'kanban:states:anon'; }
                        }
                        function parseDate(val){
                            if(!val) return null;
                            try{ var s = (val||'').toString().replace(' ','T'); var d = new Date(s); return isNaN(d.getTime())?null:d; }catch(_){ return null; }
                        }
                        function now(){ return new Date(); }
                        function loadState(){
                            try{ return JSON.parse(localStorage.getItem(storageKey) || '{}'); }catch(e){ return {}; }
                        }
                        function saveState(state){
                            try{ localStorage.setItem(storageKey, JSON.stringify(state||{})); }catch(e){}
                        }
                        function cardKey(el){ return el && el.getAttribute('data-link') || ''; }
                        function wireDnD(card){
                            card.addEventListener('dragstart', function(ev){ card.classList.add('dragging'); ev.dataTransfer.setData('text/plain', cardKey(card)); ev.dataTransfer.effectAllowed='move'; });
                            card.addEventListener('dragend', function(){ card.classList.remove('dragging'); lists.forEach(function(l){ l.classList.remove('kanban-drop-hover'); }); });
                        }
                        function wireList(list){
                            list.addEventListener('dragover', function(ev){ ev.preventDefault(); ev.dataTransfer.dropEffect='move'; list.classList.add('kanban-drop-hover'); });
                            list.addEventListener('dragleave', function(){ list.classList.remove('kanban-drop-hover'); });
                            list.addEventListener('drop', function(ev){ ev.preventDefault(); list.classList.remove('kanban-drop-hover');
                                var k = ev.dataTransfer.getData('text/plain'); if(!k) return;
                                var card = document.querySelector('.kanban-card[data-link="' + CSS.escape(k) + '"]');
                                if(card){
                                    var originParent = card.parentElement;
                                    var originNext = card.nextElementSibling;
                                    var after = getDragAfterElement(list, ev.clientY);
                                    if(after==null){ list.appendChild(card); } else { list.insertBefore(card, after); }
                                    // Abrir modal de horas; si Cancelar, revertimos
                                    openHoursModal(card, function(result){
                                        if(result && result.action === 'cancel'){
                                            try{ if(originParent){ if(originNext){ originParent.insertBefore(card, originNext); } else { originParent.appendChild(card); } } }catch(e){}
                                            updateCounters();
                                            return;
                                        }
                                        if(result && result.action === 'register'){
                                            try{ UiCommon.showToast('Horas registradas localmente (' + (result.horas||'0') + ' hs).','success'); }catch(_){ }
                                        }
                                        persistOrderFromDom();
                                        updateCounters();
                                    }, {
                                        titulo: card.getAttribute('data-title')||'',
                                        tipo: card.getAttribute('data-tipo')||'',
                                        cliente: card.getAttribute('data-cliente')||'',
                                        proyecto: card.getAttribute('data-proyecto')||'',
                                        fecha: card.getAttribute('data-fecha')||''
                                    });
                                }
                            });
                        }
                        function getDragAfterElement(container, y){
                            var els = Array.prototype.slice.call(container.querySelectorAll('.kanban-card:not(.dragging)'));
                            var closest = { offset: Number.NEGATIVE_INFINITY, element: null };
                            els.forEach(function(child){
                                var box = child.getBoundingClientRect();
                                var offset = y - box.top - (box.height/2);
                                if(offset < 0 && offset > closest.offset){ closest = { offset: offset, element: child }; }
                            });
                            return closest.element;
                        }
                        function persistOrderFromDom(){
                            var st = loadState();
                            var byCard = st.byCard || {}; var order = st.order || {};
                            lists.forEach(function(list){
                                var ids = [];
                                Array.prototype.forEach.call(list.children, function(card){ if(card.classList && card.classList.contains('kanban-card')){ var k=cardKey(card); byCard[k] = list.id; ids.push(k); }});
                                order[list.id] = ids;
                            });
                            st.byCard = byCard; st.order = order; saveState(st);
                        }
                        function datasetFromAll(){
                            var all = document.getElementById('kanbanAllItems'); if(!all) return [];
                            var cards = all.querySelectorAll('.kanban-card');
                            var data = [];
                            cards.forEach(function(c){
                                data.push({
                                    link: c.getAttribute('data-link')||'',
                                    titulo: c.getAttribute('data-title')||'',
                                    tipo: c.getAttribute('data-tipo')||'',
                                    cliente: c.getAttribute('data-cliente')||'',
                                    proyecto: c.getAttribute('data-proyecto')||'',
                                    fecha: c.getAttribute('data-fecha')||'',
                                    fuente: c.getAttribute('data-fuente')||''
                                });
                            });
                            return data;
                        }
                        function selectedText(){ return (document.getElementById('globalSearch')?.value||'').trim().toLowerCase(); }
                        function cardMatchesText(card, text){
                            if(!text) return true;
                            var title = (card.getAttribute('data-title')||'').toLowerCase();
                            var c = (card.getAttribute('data-cliente')||'').toLowerCase();
                            var p = (card.getAttribute('data-proyecto')||'').toLowerCase();
                            var f = (card.getAttribute('data-fuente')||'').toLowerCase();
                            var t = (card.getAttribute('data-tipo')||'').toLowerCase();
                            return title.indexOf(text)>=0 || c.indexOf(text)>=0 || p.indexOf(text)>=0 || f.indexOf(text)>=0 || t.indexOf(text)>=0;
                        }
                        function applyFilters(){
                            var txt = selectedText();
                            var cards = document.querySelectorAll('.kanban-board .kanban-card');
                            cards.forEach(function(card){
                                var ok = cardMatchesText(card, txt);
                                card.classList.toggle('d-none', !ok);
                            });
                            updateCounters();
                        }
                        function isOverdue(card){
                            try{
                                var d = parseDate(card.getAttribute('data-fecha')); if(!d) return false;
                                var inDone = card.parentElement && card.parentElement.id === 'col-done';
                                return !inDone && d < now();
                            }catch(_){ return false; }
                        }
                        function updateCounters(){
                            var listsMap = { backlog: 'col-backlog', todo:'col-todo', doing:'col-doing', testing:'col-testing', done:'col-done' };
                            var total = 0, vencidas = 0;
                            Object.keys(listsMap).forEach(function(k){
                                var list = document.getElementById(listsMap[k]); if(!list) return;
                                var visible = Array.prototype.filter.call(list.children, function(el){ return el.classList && !el.classList.contains('d-none'); });
                                total += visible.length;
                                var span = document.querySelector('[data-counter="' + k + '"]'); if(span){ span.textContent = visible.length; }
                                visible.forEach(function(card){ card.classList.toggle('border-danger', false); if(isOverdue(card)) { vencidas++; card.classList.add('border-danger'); } });
                            });
                            var lblTot = document.getElementById('lblTotalTareas'); if(lblTot){ lblTot.textContent = total; }
                            var lblV = document.getElementById('lblVencidas'); if(lblV){ lblV.textContent = vencidas; }
                        }
                        function distribute(){
                            var all = document.getElementById('kanbanAllItems'); if(!all) return;
                            storageKey = keyForUser();
                            var state = loadState();
                            var byCard = state.byCard || state; // compat
                            var order = state.order || {};
                            var cards = all.querySelectorAll('.kanban-card');
                            cards.forEach(function(c){ wireDnD(c); });
                            // Por defecto: Por hacer
                            cards.forEach(function(c){
                                var k = cardKey(c); var targetId = byCard[k] || 'col-todo';
                                var target = document.getElementById(targetId) || document.getElementById('col-todo');
                                if(target) target.appendChild(c);
                            });
                            // Aplicar orden por columna si existe
                            Object.keys(order).forEach(function(listId){
                                var list = document.getElementById(listId); if(!list) return;
                                var seq = order[listId] || [];
                                seq.forEach(function(k){
                                    var card = document.querySelector('.kanban-card[data-link="' + CSS.escape(k) + '"]');
                                    if(card && card.parentElement === list){ list.appendChild(card); }
                                });
                            });
                            applyFilters();
                        }
                        function applyGlobalSearchSync(){
                            try{
                                var tb = document.getElementById('globalSearch');
                                var clear = document.getElementById('btnGlobalClear');
                                if(tb){ tb.addEventListener('input', function(){ try{ if(window.GridEnhancer){ GridEnhancer.filter(tb.value||''); } }catch(e){} applyFilters(); }); }
                                if(clear){ clear.addEventListener('click', function(){ try{ if(window.GridEnhancer){ GridEnhancer.filter(''); } }catch(e){} try{ tb.value=''; }catch(_){} applyFilters(); }); }
                            }catch(e){}
                        }
                        function switchView(view){
                            var boardEl = document.getElementById('kanbanBoard');
                            var gridEl = document.getElementById('gridContainer');
                            var kbBtn = document.getElementById('btnViewKanban');
                            var grBtn = document.getElementById('btnViewGrid');
                            var v = (view==='grid') ? 'grid' : 'kanban';
                            if(boardEl && gridEl){
                                boardEl.classList.toggle('d-none', v==='grid');
                                gridEl.classList.toggle('d-none', v!=='grid');
                            }
                            if(kbBtn && grBtn){
                                kbBtn.classList.toggle('btn-outline-primary', v!=='kanban');
                                kbBtn.classList.toggle('btn-primary', v==='kanban');
                                grBtn.classList.toggle('btn-outline-secondary', v!=='grid');
                                grBtn.classList.toggle('btn-secondary', v==='grid');
                            }
                            try{ localStorage.setItem('kanban:view', v); }catch(_){ }
                            // Reaplicar filtros por si cambia la vista
                            applyFilters();
                            try{ if(window.GridEnhancer){ GridEnhancer.enhanceAll(); GridEnhancer.filter(document.getElementById('globalSearch')?.value||''); } }catch(e){}
                        }
                        document.addEventListener('DOMContentLoaded', function(){
                            board = document.getElementById('kanbanBoard');
                            lists = Array.prototype.slice.call(document.querySelectorAll('.kanban-list'));
                            lists.forEach(wireList);
                            distribute();
                            applyGlobalSearchSync();
                            var kbBtn = document.getElementById('btnViewKanban'); if(kbBtn){ kbBtn.addEventListener('click', function(){ switchView('kanban'); }); }
                            var grBtn = document.getElementById('btnViewGrid'); if(grBtn){ grBtn.addEventListener('click', function(){ switchView('grid'); }); }
                            try{ var saved = localStorage.getItem('kanban:view') || 'kanban'; switchView(saved); }catch(_){ switchView('kanban'); }
                            // Hook postbacks: re-enhance grilla y mantener búsqueda
                            try{
                                if(window.Sys && Sys.WebForms){
                                    Sys.WebForms.PageRequestManager.getInstance().add_endRequest(function(){
                                        try{ if(window.GridEnhancer){ GridEnhancer.enhanceAll(); GridEnhancer.filter(document.getElementById('globalSearch')?.value||''); } }catch(e){}
                                        try{ lists = Array.prototype.slice.call(document.querySelectorAll('.kanban-list')); lists.forEach(wireList); }catch(e){}
                                        try{ distribute(); }catch(e){}
                                        try{ updateCounters(); }catch(e){}
                                    });
                                }
                            }catch(e){}
                        });

                        // ---------------- Modal de carga de horas (cliente) -----------------
                        function ensureModal(){
                            var el = document.getElementById('hoursModal');
                            if(el) return el;
                            var div = document.createElement('div');
                            div.innerHTML = '\
<div class="modal fade" id="hoursModal" tabindex="-1" aria-hidden="true">\
  <div class="modal-dialog">\
    <div class="modal-content">\
      <div class="modal-header">\
        <h5 class="modal-title">Registrar horas</h5>\
        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>\
      </div>\
      <div class="modal-body">\
        <div class="mb-2"><small class="text-muted">Podés registrar horas ahora u omitir para solo mover la tarjeta.</small></div>\
        <div class="row g-3">\
          <div class="col-6">\
            <label class="form-label">Fecha</label>\
            <input id="hmFecha" type="date" class="form-control" />\
          </div>\
          <div class="col-6">\
            <label class="form-label">Horas</label>\
            <input id="hmHoras" type="number" step="0.25" min="0" class="form-control" placeholder="0" />\
          </div>\
          <div class="col-12">\
            <label class="form-label">Título</label>\
            <input id="hmTitulo" type="text" class="form-control" readonly />\
          </div>\
          <div class="col-6">\
            <label class="form-label">Cliente</label>\
            <input id="hmCliente" type="text" class="form-control" readonly />\
          </div>\
          <div class="col-6">\
            <label class="form-label">Proyecto</label>\
            <input id="hmProyecto" type="text" class="form-control" readonly />\
          </div>\
          <div class="col-6">\
            <label class="form-label">Tipo</label>\
            <input id="hmTipo" type="text" class="form-control" readonly />\
          </div>\
          <div class="col-6">\
            <label class="form-label">Actividad</label>\
            <input id="hmActividad" type="text" class="form-control" placeholder="(opcional)" />\
          </div>\
          <div class="col-12">\
            <label class="form-label">Tarea / Observaciones</label>\
            <textarea id="hmObs" class="form-control" rows="2" placeholder="(opcional)"></textarea>\
          </div>\
        </div>\
      </div>\
      <div class="modal-footer">\
        <button type="button" class="btn btn-outline-secondary" id="hmBtnSkip">Omitir y mover</button>\
        <button type="button" class="btn btn-primary" id="hmBtnSave">Registrar</button>\
        <button type="button" class="btn btn-outline-danger" data-bs-dismiss="modal" id="hmBtnCancel">Cancelar</button>\
      </div>\
    </div>\
  </div>\
</div>';
                            document.body.appendChild(div.firstChild);
                            return document.getElementById('hoursModal');
                        }
                        function todayStr(){ var d=new Date(); var mm=('0'+(d.getMonth()+1)).slice(-2); var dd=('0'+d.getDate()).slice(-2); return d.getFullYear()+'-'+mm+'-'+dd; }
                        function openHoursModal(card, callback, data){
                            var el = ensureModal(); if(!el) { if(callback) callback({action:'skip'}); return; }
                            var fecha = document.getElementById('hmFecha');
                            var horas = document.getElementById('hmHoras');
                            var titulo = document.getElementById('hmTitulo');
                            var cliente = document.getElementById('hmCliente');
                            var proyecto = document.getElementById('hmProyecto');
                            var tipo = document.getElementById('hmTipo');
                            var actividad = document.getElementById('hmActividad');
                            var obs = document.getElementById('hmObs');
                            try{
                                fecha.value = todayStr();
                                horas.value = '';
                                titulo.value = (data && data.titulo) || '';
                                cliente.value = (data && data.cliente) || '';
                                proyecto.value = (data && data.proyecto) || '';
                                tipo.value = (data && data.tipo) || '';
                                actividad.value = '';
                                obs.value = '';
                            }catch(e){}
                            var m = null;
                            try{ if(window.bootstrap){ m = bootstrap.Modal.getOrCreateInstance(el, {backdrop:'static'}); m.show(); } }catch(e){ }
                            var btnSave = document.getElementById('hmBtnSave');
                            var btnSkip = document.getElementById('hmBtnSkip');
                            var btnCancel = document.getElementById('hmBtnCancel');
                            function cleanup(){ try{ btnSave.onclick = btnSkip.onclick = btnCancel.onclick = null; }catch(e){} }
                            btnSave.onclick = function(){ try{ if(m) m.hide(); }catch(e){} cleanup(); if(callback) callback({ action:'register', fecha: fecha.value, horas: horas.value, actividad: actividad.value, obs: obs.value }); };
                            btnSkip.onclick = function(){ try{ if(m) m.hide(); }catch(e){} cleanup(); if(callback) callback({ action:'skip' }); };
                            btnCancel.onclick = function(){ cleanup(); if(callback) callback({ action:'cancel' }); };
                        }
                    })();
                </script>
            </ContentTemplate>
            <Triggers>
                <asp:AsyncPostBackTrigger ControlID="btnAplicar" EventName="Click" />
            </Triggers>
        </asp:UpdatePanel>
    </div>

</asp:Content>


