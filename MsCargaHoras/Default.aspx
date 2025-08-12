<%@ Page Title="" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="Default.aspx.cs" Inherits="MsCargaHoras._Default" %>

<asp:Content ID="BodyContent" ContentPlaceHolderID="MainContent" runat="server">

    <div class="py-4">
        <asp:HiddenField ID="hidActiveTab" runat="server" />

        <!-- Toolbar de acciones (tickets/actividad) -->
        <div id="toolbarActions" class="toolbar sticky-top bg-body-tertiary border-bottom" style="height: var(--toolbar-h);">
            <div class="container-fluid px-3 px-md-4 px-lg-5 py-2">
                <div class="controls d-flex flex-nowrap align-items-center gap-2 overflow-auto">
                    <asp:TextBox ID="txtConsulta" runat="server" CssClass="form-control flex-grow-1" placeholder="Ticket o Actividad" style="min-width:200px;" />
                    <button type="button" class="btn btn-primary btn-sm d-inline-flex align-items-center gap-1" onclick="try{ UiCommon.showLoading(); }catch(e){} return abrirVistaPreviaTicket();"><i class="bi bi-eye-fill"></i><span class="d-none d-sm-inline">Ver ticket</span></button>
                    <button type="button" class="btn btn-outline-primary btn-sm d-inline-flex align-items-center gap-1" onclick="try{ UiCommon.showLoading(); }catch(e){} return abrirConsultaTicket();"><i class="bi bi-search"></i><span class="d-none d-sm-inline">Horas ticket</span></button>
                    <button type="button" class="btn btn-success btn-sm d-inline-flex align-items-center gap-1" onclick="try{ UiCommon.showLoading(); }catch(e){} return abrirNuevoTicket();"><i class="bi bi-plus-circle"></i><span class="d-none d-sm-inline">Nuevo Ticket</span></button>
                    <button type="button" class="btn btn-outline-info btn-sm d-inline-flex align-items-center gap-1" onclick="try{ UiCommon.showLoading(); }catch(e){} return abrirConsultaActividad();"><i class="bi bi-clipboard-check"></i><span class="d-none d-sm-inline">Consultar actividad</span></button>
                    <button type="button" class="btn btn-warning btn-sm d-inline-flex align-items-center gap-1" onclick="try{ UiCommon.showLoading(); }catch(e){} return abrirTimelineTickets();"><i class="bi bi-list-task"></i><span class="d-none d-sm-inline">Últimos Cambios</span></button>
                    <button type="button" class="btn btn-dark btn-sm d-inline-flex align-items-center gap-1" onclick="try{ UiCommon.showLoading(); }catch(e){} return abrirTimelineTrac();"><i class="bi bi-git"></i><span class="d-none d-sm-inline">Commits SVN</span></button>
                            </div>
                        </div>
                    </div>

        <!-- Toolbar de búsqueda global -->
        <div id="toolbarSearch" class="toolbar sticky-top search bg-body-tertiary border-bottom" style="height: var(--toolbar-h);">
            <div class="container-fluid px-3 px-md-4 px-lg-5 py-2">
                <div class="controls d-flex flex-nowrap align-items-center gap-2 overflow-auto">
                    <input id="globalSearch" type="text" class="form-control flex-grow-1" placeholder="Buscar en todas las tablas..." />
                    <button id="btnGlobalClear" type="button" class="btn btn-outline-secondary btn-sm">Limpiar</button>
                </div>
            </div>
        </div>

        
        <asp:UpdatePanel ID="upMain" runat="server" UpdateMode="Conditional">
            <ContentTemplate>
        <div class="mb-2">
        <ul class="nav nav-tabs" id="tabsCargaHoras" role="tablist" aria-label="Vistas de carga de horas">
            <li class="nav-item" role="presentation">
                <button class="nav-link active" id="faltantes-tab" data-bs-toggle="tab" data-bs-target="#tab-faltantes" type="button" role="tab" aria-controls="tab-faltantes" aria-selected="true">Resumen</button>
            </li>
            <li class="nav-item" role="presentation">
                <button class="nav-link" id="carga-tab" data-bs-toggle="tab" data-bs-target="#tab-carga" type="button" role="tab" aria-controls="tab-carga" aria-selected="false">Carga de Horas</button>
            </li>
            <li class="nav-item" role="presentation">
                <button class="nav-link" id="trac-tab" data-bs-toggle="tab" data-bs-target="#tab-trac" type="button" role="tab" aria-controls="tab-trac" aria-selected="false">Tareas Pendientes</button>
            </li>
        </ul>
            
        </div>

        <div class="tab-content" id="tabsCargaHorasContent">
            <div class="tab-pane fade show active" id="tab-faltantes" role="tabpanel" aria-labelledby="faltantes-tab" tabindex="0">
                <div class="row g-4 mt-1">
                    <div class="col-lg-4">
                        <fieldset class="card shadow-sm">
                            <legend class="card-header h5 mb-0 d-flex justify-content-between align-items-center">
                                <span>Horas Faltantes</span>
                                <span class="d-flex align-items-center gap-2">
                                    <asp:Label ID="lblDiasFaltantes" runat="server" CssClass="badge bg-secondary-subtle text-dark" />
                                    <asp:Label ID="lblHorasFaltantes" runat="server" CssClass="badge bg-secondary-subtle text-dark" />
                                </span>
                            </legend>
                            <div class="card-body">
                                
                                <div class="table-responsive grid-scroll">
                                    <asp:GridView ID="grdDatos" runat="server" CssClass="table table-striped table-hover align-middle" DataSourceID="SqlDataSource1" GridLines="None" AutoGenerateColumns="False" EnableEventValidation="true" OnSelectedIndexChanged="grdDatos_SelectedIndexChanged" OnDataBound="grdDatos_DataBound" OnRowDataBound="grdDatos_RowDataBound" UseAccessibleHeader="true">
                                <HeaderStyle CssClass="table-dark" />
                                <Columns>
                                    <asp:CommandField ShowSelectButton="True" SelectText="Sel" HeaderStyle-CssClass="no-filter" />
                                    <asp:BoundField DataField="Dia" HeaderText="Día" />
                                    <asp:BoundField DataField="FechaCarga" HeaderText="Fecha" />
                                    <asp:BoundField DataField="Falta Cargar" HeaderText="Falta" />
                                </Columns>
                            </asp:GridView>
                        </div>
                                <asp:Label ID="total" runat="server" CssClass="text-muted d-none"></asp:Label>
                            </div>
                        </fieldset>
                        <asp:SqlDataSource ID="SqlDataSource1" runat="server" ConnectionString="<%$ ConnectionStrings:LABTRACConnectionString %>" SelectCommand="AGLTRAC_BuscarHsPendientesDeCarga" SelectCommandType="StoredProcedure" CancelSelectOnNullParameter="true" EnableCaching="true" CacheDuration="60" CacheExpirationPolicy="Absolute" OnSelected="SqlDataSource_Selected" OnSelecting="SqlDataSource_Selecting">
                            <SelectParameters>
                                <asp:ControlParameter ControlID="txtLegajo" Name="Filtro" PropertyName="Text" Type="String" ConvertEmptyStringToNull="true" />
                            </SelectParameters>
                        </asp:SqlDataSource>
                    </div>
                    <div class="col-lg-8">
                        <fieldset class="card shadow-sm">
                            <legend class="card-header h5 mb-0">Horas Sugeridas</legend>
                            <div class="card-body">
                        <div class="d-flex justify-content-between align-items-center mb-2">
                            <div class="d-flex flex-wrap align-items-center gap-2">
                                
                                <span class="badge bg-dark-subtle text-dark">Día</span>
                                <span class="badge bg-primary-subtle text-dark"><asp:Label ID="lblDiaSeleccionado" runat="server" Text="-" /></span>
                                <span class="badge bg-primary-subtle text-dark"><asp:Label ID="lblFechaSeleccionada" runat="server" Text="--/--/----" /></span>
                            </div>
                            <div class="badge bg-secondary-subtle text-dark">Falta <strong><asp:Label ID="lblFaltaSeleccionada" runat="server" Text="0" /></strong> hs</div>
                        </div>
                        <div class="table-responsive grid-scroll">
                             <asp:GridView ID="grdSugeridas" runat="server" CssClass="table table-striped table-hover align-middle"
                                 GridLines="None" AutoGenerateColumns="False" EmptyDataText="Sin datos para mostrar."
                                 AllowPaging="true" PageSize="10" AllowSorting="true"
                                 OnPageIndexChanging="grdSugeridas_PageIndexChanging" OnSorting="grdSugeridas_Sorting" OnRowDataBound="grdSugeridas_RowDataBound" OnDataBound="grdSugeridas_DataBound" UseAccessibleHeader="true">
                                <HeaderStyle CssClass="table-dark" />
                                 <Columns>
                                     <asp:HyperLinkField DataTextField="Titulo" HeaderText="Título" DataNavigateUrlFields="Link" DataNavigateUrlFormatString="{0}" Target="_blank" />
                                     <asp:BoundField DataField="type" HeaderText="type" />
                                     <asp:BoundField DataField="Cliente" HeaderText="Cliente" />
                                     <asp:BoundField DataField="Proyecto" HeaderText="Proyecto" />
                                     <asp:BoundField DataField="FechaComprometida" HeaderText="Fecha comprometida" DataFormatString="{0:dd/MM/yyyy HH:mm}" HtmlEncode="false" />
                                 </Columns>
                                 <PagerStyle CssClass="pagination" />
                            </asp:GridView>
                        </div>
                            </div>
                        </fieldset>
                    </div>
                </div>
            </div>

            <div class="tab-pane fade" id="tab-carga" role="tabpanel" aria-labelledby="carga-tab" tabindex="0">
 <%--               <div class="mb-4 mt-3">
                    <h2 class="h4 mb-1">Carga de Horas</h2>
                    <p class="text-muted">Grilla editable para registrar horas reales según la especificación de UX. Contenido inicial a modo de estructura base.</p>
                </div>--%>

                <link rel="stylesheet" href="https://unpkg.com/tabulator-tables@5.5.2/dist/css/tabulator.min.css" />
                <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/flatpickr/dist/flatpickr.min.css" />
                <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/tom-select/dist/css/tom-select.bootstrap5.min.css" />
                <link rel="stylesheet" href="https://unpkg.com/tippy.js@6/dist/tippy.css" />

                <fieldset class="card shadow-sm mb-3">
                    <legend class="card-header h5 mb-0">Parámetros</legend>
                    <div class="card-body">
                        <div class="row g-3 align-items-end">
                            <div class="col-sm-3">
                                <label class="form-label" for="<%= dtpFechaCarga.ClientID %>">Fecha</label>
                                <asp:TextBox ID="dtpFechaCarga" runat="server" CssClass="form-control" TextMode="Date" />
                            </div>
                            <div class="col-auto d-flex align-items-end">
                                <asp:Button ID="btnAplicarCarga" runat="server" CssClass="btn btn-primary" Text="Aplicar" OnClick="btnAplicarCarga_Click" />
                            </div>
                            <div class="col-sm"></div>
                        </div>
                    </div>
                </fieldset>

                <fieldset class="card shadow-sm mb-3">
                    <legend class="card-header h5 mb-0 d-flex justify-content-between align-items-center">
                        <span>Grilla editable</span>
                        <span class="text-muted small" id="lblSugeridasResumen"></span>
                    </legend>
                    <div class="card-body">
                    <div id="gridHorasReales" class="table-sticky"></div>
                        <div class="table-responsive grid-scroll mt-3">
                    <asp:GridView ID="grdHoras" runat="server" CssClass="table table-striped table-hover align-middle" GridLines="None"
                        AutoGenerateColumns="False" EmptyDataText="Sin datos para la fecha seleccionada." DataKeyNames="Id"
                        AllowSorting="true" OnSelectedIndexChanged="grdHoras_SelectedIndexChanged" OnDataBound="grdHoras_DataBound" UseAccessibleHeader="true">
                        <HeaderStyle CssClass="table-dark" />
                        <Columns>
                            <asp:CommandField ShowSelectButton="True" SelectText="Sel" HeaderStyle-CssClass="no-filter" />
                            <asp:BoundField DataField="Cliente" HeaderText="Cliente" SortExpression="Cliente" />
                            <asp:BoundField DataField="Proyecto" HeaderText="Proyecto" SortExpression="Proyecto" />
                            <asp:BoundField DataField="Actividad" HeaderText="Actividad" SortExpression="Actividad" />
                            <asp:BoundField DataField="Tarea" HeaderText="Tarea" SortExpression="Tarea" />
                            <asp:BoundField DataField="Desde" HeaderText="Desde" SortExpression="Desde" />
                            <asp:BoundField DataField="Hasta" HeaderText="Hasta" SortExpression="Hasta" />
                            <asp:BoundField DataField="Horas" HeaderText="Horas" SortExpression="Horas" />
                            <asp:CheckBoxField DataField="Fuera" HeaderText="Fuera" ReadOnly="true" />
                            <asp:BoundField DataField="TipoDoc" HeaderText="Tipo Doc" SortExpression="TipoDoc" />
                            <asp:BoundField DataField="NroDoc" HeaderText="Nro Doc" SortExpression="NroDoc" />
                            <asp:BoundField DataField="Observaciones" HeaderText="Observaciones" SortExpression="Observaciones" />
                        </Columns>
                    </asp:GridView>
                    <asp:HiddenField ID="hidSelHoraIdx" runat="server" />
                    <asp:HiddenField ID="hidSelNroDocClientId" runat="server" />
                    <asp:HiddenField ID="hidTracAuthor" runat="server" />
                </div>
                    </div>
                </fieldset>



                <fieldset class="card shadow-sm">
                    <legend class="card-header h5 mb-0">Acciones</legend>
                    <div class="card-body">
                        <div class="row g-2 align-items-center">
                            <div class="col-auto">
                                <asp:Button ID="btnInsertar" runat="server" Text="Insertar Línea" CssClass="btn btn-outline-secondary" OnClick="btnInsertar_Click" />
                            </div>
                            <div class="col-auto">
                                <asp:Button ID="btnEliminar" runat="server" Text="Eliminar Línea" CssClass="btn btn-outline-secondary" OnClick="btnEliminar_Click" />
                            </div>
                            <div class="col-auto">
                                <asp:Button ID="btnDuplicar" runat="server" Text="Duplicar Línea" CssClass="btn btn-outline-secondary" OnClick="btnDuplicar_Click" />
                            </div>

                            <div class="col-sm ms-auto d-flex justify-content-end align-items-center flex-wrap gap-3">
                                <div class="text-muted small">Total dentro: <asp:Label ID="lblTotDentro" runat="server" CssClass="fw-semibold" Text="00:00" /></div>
                                <div class="text-muted small">Total fuera: <asp:Label ID="lblTotFuera" runat="server" CssClass="fw-semibold" Text="00:00" /></div>
                                <div class="text-dark fw-bold">Total de Horas: <asp:Label ID="lblTotGeneral" runat="server" Text="00:00" /></div>
                                <asp:Button ID="btnGuardar" runat="server" Text="Guardar" CssClass="btn btn-success" OnClick="btnGuardar_Click" />
                                <asp:Button ID="btnDescartar" runat="server" Text="Cancelar" CssClass="btn btn-outline-danger" OnClick="btnDescartar_Click" />
                            </div>
                        </div>
                    </div>
                </fieldset>
                <!-- Cargas opcionales sin atributo integrity para evitar bloqueos por hash mismatcheado -->
                <script src="https://unpkg.com/tabulator-tables@5.5.2/dist/js/tabulator.min.js" crossorigin="anonymous"></script>
                <script src="https://cdn.jsdelivr.net/npm/flatpickr" crossorigin="anonymous"></script>
                <script src="https://cdn.jsdelivr.net/npm/tom-select/dist/js/tom-select.complete.min.js" crossorigin="anonymous"></script>
                <!-- Bootstrap bundle ya incluye Popper; evitamos duplicarlo. Tippy opcional, desactivado por ahora. -->
                <!-- <script src="https://unpkg.com/@popperjs/core@2" crossorigin="anonymous"></script> -->
                <!-- <script src="https://unpkg.com/tippy.js@6" crossorigin="anonymous"></script> -->
                <script type="text/javascript">
                    (function(){
                        var initialized = false;
                        function initGrid(){
                            if(initialized) return;
                            if(!window.Tabulator) return;
                            var el = document.getElementById('gridHorasReales');
                            if(!el) return;
                            var columns = [
                                {title:'Estado', field:'estado', width:90},
                                {title:'Cliente', field:'cliente'},
                                {title:'Proyecto', field:'proyecto'},
                                {title:'Actividad', field:'actividad'},
                                {title:'Tarea', field:'tarea'},
                                {title:'Desde', field:'desde'},
                                {title:'Hasta', field:'hasta'},
                                {title:'Horas', field:'horas', hozAlign:'right'},
                                {title:'Fuera', field:'fuera', hozAlign:'center'},
                                {title:'Observaciones', field:'obs'}
                            ];
                            var grid = new Tabulator(el, {
                                layout: 'fitColumns',
                                placeholder: 'Grilla editable en preparación',
                                columns: columns,
                                reactiveData: true,
                                columnDefaults: { headerHozAlign: 'center' }
                            });
                            initialized = true;
                        }
                        document.addEventListener('DOMContentLoaded', function(){
                            var tabBtn = document.getElementById('carga-tab');
                            if(tabBtn){
                                tabBtn.addEventListener('shown.bs.tab', initGrid);
                            }
                            if(tabBtn && tabBtn.classList.contains('active')){ initGrid(); }
                        });
                    })();
                </script>
                <script type="text/javascript">
                    function obtenerNumeroConsulta(){
                        var tb = document.getElementById('<%= txtConsulta.ClientID %>');
                        if(!tb) return '';
                        var val = (tb.value || '').toString();
                        // Extrae solo dígitos (soporta entradas como "#12345" o "(12345)")
                        var digits = val.replace(/\D+/g, '');
                        if(!digits){
                            // Si está vacío, intenta leer el Nro Doc de la fila seleccionada
                            var idxEl = document.getElementById('<%= hidSelHoraIdx.ClientID %>');
                            var idx = idxEl && idxEl.value ? parseInt(idxEl.value, 10) : -1;
                            if(!isNaN(idx) && idx >= 0){
                                try{
                                    // Busca el textbox Nro Doc en la fila seleccionada
                                    var grid = document.getElementById('<%= grdHoras.ClientID %>');
                                    if(grid){
                                        var rows = grid.getElementsByTagName('tr');
                                        // +1 por header
                                        var row = rows && rows[idx + 1];
                                        if(row){
                                            var inputs = row.getElementsByTagName('input');
                                            for(var i=0;i<inputs.length;i++){
                                                if(inputs[i].id && inputs[i].id.indexOf('txtNroDoc') !== -1){
                                                    var v = (inputs[i].value || '').toString();
                                                    digits = v.replace(/\D+/g, '');
                                                    break;
                                                }
                                            }
                                        }
                                    }
                                }catch(e){/* noop */}
                            }
                        }
                        return digits;
                    }
                    function abrirConsultaTicket(){
                        var n = obtenerNumeroConsulta();
                        var url = 'https://desarrollo.mastersoft.com.ar/WebConsultaHsAplicadas/?nrotk=' + n;
                        window.open(url, '_blank');
                        return false;
                    }
                    function abrirConsultaActividad(){
                        var n = obtenerNumeroConsulta();
                        var base = 'https://desarrollo.mastersoft.com.ar/DatosActividad/?ActividadID=';
                        var url = n ? (base + n) : base;
                        window.open(url, '_blank');
                        return false;
                    }
                </script>
                <script type="text/javascript">
                    // Teclas de acceso rápido (Enter) para acciones comunes
                    document.addEventListener('DOMContentLoaded', function(){
                        try{
                            // Enter en login => click Log In
                            var tbLogin = document.getElementById('<%= txtLegajo.ClientID %>');
                            var btnLogin = document.getElementById('<%= btnBuscar.ClientID %>');
                            if(tbLogin && btnLogin){
                                tbLogin.addEventListener('keydown', function(ev){ if(ev.key==='Enter'){ ev.preventDefault(); btnLogin.click(); }});
                            }
                        }catch(e){}
                        try{
                            // Enter en Ticket/Actividad => abrir consulta de ticket
                            var tbTicket = document.getElementById('<%= txtConsulta.ClientID %>');
                            if(tbTicket){
                                tbTicket.addEventListener('keydown', function(ev){ if(ev.key==='Enter'){ ev.preventDefault(); abrirConsultaTicket(); }});
                            }
                        }catch(e){}
                        try{
                            // Enter en fecha de carga => aplicar
                            var dtp = document.getElementById('<%= dtpFechaCarga.ClientID %>');
                            var btnAp = document.getElementById('<%= btnAplicarCarga.ClientID %>');
                            if(dtp && btnAp){ dtp.addEventListener('keydown', function(ev){ if(ev.key==='Enter'){ ev.preventDefault(); btnAp.click(); }}); }
                        }catch(e){}
                    });
                </script>
                <script type="text/javascript">
                    function abrirTicketTrac(){
                        var n = '';
                        try{
                            var hid = document.getElementById('<%= hidTracSelTicketId.ClientID %>');
                            if(hid && hid.value){ n = hid.value; }
                        }catch(e){}
                        if(!n){ n = obtenerNumeroConsulta(); }
                        if(!n){ alert('Ingrese un número de ticket o seleccione uno.'); return false; }
                        var url = 'https://ticket.mastersoft.com.ar/trac/incidentes/ticket/' + n;
                        window.open(url, '_blank');
                        return false;
                    }
                    function abrirNuevoTicket(){
                        window.open('https://ticket.mastersoft.com.ar/trac/incidentes/newticket', '_blank');
                        return false;
                    }
                    function abrirVistaPreviaTicket(){
                        var n = '';
                        try{
                            var hid = document.getElementById('<%= hidTracSelTicketId.ClientID %>');
                            if(hid && hid.value){ n = hid.value; }
                        }catch(e){}
                        if(!n){ n = obtenerNumeroConsulta(); }
                        if(!n){ alert('Ingrese un número de ticket o seleccione uno.'); return false; }
                        var url = 'https://ticket.mastersoft.com.ar/trac/incidentes/ticket/' + n;
                        var w = Math.min(1100, window.innerWidth - 80), h = Math.min(700, window.innerHeight - 80);
                        var y = Math.max(0, Math.round((window.innerHeight - h)/2));
                        var x = Math.max(0, Math.round((window.innerWidth - w)/2));
                        window.open(url, 'vista_previa_ticket', 'width=' + w + ',height=' + h + ',left=' + x + ',top=' + y + ',resizable=yes,scrollbars=yes');
                        return false;
                    }
                    function abrirTimelineTrac(){
                        var author = '';
                        try{
                            var hid = document.getElementById('<%= hidTracAuthor.ClientID %>');
                            if(hid && hid.value){ author = hid.value; }
                        }catch(e){}
                        if(!author){ author = 'alipshitz'; }

                        var now = new Date();
                        var dd = String(now.getDate()).padStart(2, '0');
                        var mm = String(now.getMonth() + 1).padStart(2, '0');
                        var yyyy = String(now.getFullYear());
                        var from = encodeURIComponent(dd + '/' + mm + '/' + yyyy);

                        var url = 'https://ticket.mastersoft.com.ar/trac/incidentes/timeline'
                            + '?from=' + from
                            + '&daysback=15'
                            + '&authors=' + encodeURIComponent(author)
                            + '&changeset=on'
                            + '&update=Actualizar';
                        window.open(url, '_blank');
                        return false;
                    }
                    function abrirTimelineTickets(){
                        var author = '';
                        try{
                            var hid = document.getElementById('<%= hidTracAuthor.ClientID %>');
                            if(hid && hid.value){ author = hid.value; }
                        }catch(e){}
                        if(!author){ author = 'alipshitz'; }

                        var now = new Date();
                        var dd = String(now.getDate()).padStart(2, '0');
                        var mm = String(now.getMonth() + 1).padStart(2, '0');
                        var yyyy = String(now.getFullYear());
                        var from = encodeURIComponent(dd + '/' + mm + '/' + yyyy);

                        var url = 'https://ticket.mastersoft.com.ar/trac/incidentes/'
                            + '?from=' + from
                            + '&daysback=30'
                            + '&authors=' + encodeURIComponent(author)
                            + '&ticket=on'
                            + '&ticket_details=on'
                            + '&update=Actualizar';
                        window.open(url, '_blank');
                        return false;
                    }
                </script>
            </div>
            <div class="tab-pane fade" id="tab-trac" role="tabpanel" aria-labelledby="trac-tab" tabindex="0">
                <div class="row g-3 mt-3">
                    <div class="col-12">
                        <fieldset class="card shadow-sm">
                            <legend class="card-header h5 mb-0">Tareas</legend>
                            <div class="card-body">
                        <div class="d-flex justify-content-between align-items-center mb-2 flex-wrap gap-2">
                            <div class="d-flex align-items-center gap-3">
                                <h2 class="h4 mb-0">Tareas Pendientes</h2>
                                <div class="d-flex align-items-center gap-2">
                                    <label for="<%= ddlFuente.ClientID %>" class="form-label mb-0">Fuente</label>
                                    <asp:DropDownList ID="ddlFuente" runat="server" CssClass="form-select form-select-sm" AutoPostBack="false">
                                        <asp:ListItem Text="Todas" Value="TODOS" Selected="True" />
                                        <asp:ListItem Text="TRAC" Value="TRAC" />
                                        <asp:ListItem Text="Actividades" Value="ACTIVIDADES" />
                                    </asp:DropDownList>
                                </div>
                            </div>
                            <span class="text-muted">Fuente: TRAC / Actividades / Todas</span>
                        </div>
                        <div class="table-responsive grid-scroll">
                            <asp:GridView ID="grdTrac" runat="server" CssClass="table table-striped table-hover align-middle" GridLines="None" AutoGenerateColumns="False" DataSourceID="dsTrac" OnSelectedIndexChanged="grdTrac_SelectedIndexChanged" OnRowDataBound="grdTrac_RowDataBound" OnDataBound="grdTrac_DataBound" UseAccessibleHeader="true">
                                <HeaderStyle CssClass="table-dark" />
                                <Columns>
                                    <asp:CommandField ShowSelectButton="True" SelectText="Sel" HeaderStyle-CssClass="no-filter" />
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
                        <asp:SqlDataSource ID="dsTrac" runat="server" ConnectionString="<%$ ConnectionStrings:LABTRACConnectionString %>"
                            SelectCommand="AGLTRAC_ObtenerTareasAsignadas" SelectCommandType="StoredProcedure" OnSelecting="dsTrac_Selecting" OnSelected="SqlDataSource_Selected" CancelSelectOnNullParameter="true" EnableCaching="true" CacheDuration="60" CacheExpirationPolicy="Sliding">
                        </asp:SqlDataSource>
                        <asp:HiddenField ID="hidTracSelTicketId" runat="server" />
                        <asp:HiddenField ID="hidLegajoNum" runat="server" />
                            </div>
                        </fieldset>
                    </div>
                </div>
            </div>
        </div>
        <script type="text/javascript">
            (function () {
                var tabsEl = document.getElementById('tabsCargaHoras');
                var hidden = document.getElementById('<%= hidActiveTab.ClientID %>');
                var storageKey = 'tabsCargaHorasActive';
                function currentActiveId(){
                    var active = document.querySelector('#tabsCargaHoras .nav-link.active');
                    return active ? active.getAttribute('data-bs-target') : null;
                }
                function activate(id) {
                    var trigger = document.querySelector('[data-bs-target="' + id + '"]');
                    if (trigger && window.bootstrap) {
                        var tab = new bootstrap.Tab(trigger);
                        tab.show();
                    }
                }
                document.addEventListener('DOMContentLoaded', function () {
                    var saved = hidden && hidden.value ? hidden.value : localStorage.getItem(storageKey);
                    if (saved) activate(saved);
                    try{
                        // Mostrar modal de login si no hay usuario guardado
                        var logged = localStorage.getItem('app:loggedUser') || '';
                        if(!logged && window.bootstrap){
                            forceCloseLoginModal();
                            var lm = document.getElementById('loginModal'); if(lm){ var inst = new bootstrap.Modal(lm, {backdrop:'static', keyboard:false}); inst.show(); }
                        } else {
                            var acts = document.getElementById('loginActions'); if(acts){ acts.style.display='flex'; var l=document.getElementById('lblLoginUsuario'); if(l){ l.innerText = logged; } }
                        }
                        // Estándar: envolver grids en cards si no lo están
                        try{ var g1=document.getElementById('<%= grdSugeridas.ClientID %>'); if(g1){ UiCommon.wrapGridInCard(g1,'Horas Sugeridas'); } }catch(e){}
                        try{ var g2=document.getElementById('<%= grdHoras.ClientID %>'); if(g2){ UiCommon.wrapGridInCard(g2,'Grilla editable'); } }catch(e){}
                        try{ var g3=document.getElementById('<%= grdTrac.ClientID %>'); if(g3){ UiCommon.wrapGridInCard(g3,'Tareas'); } }catch(e){}
                        try{ var g4=document.getElementById('<%= grdDatos.ClientID %>'); if(g4){ UiCommon.wrapGridInCard(g4,'Horas Faltantes'); } }catch(e){}
                    }catch(e){}
                });
                if (tabsEl) {
                    tabsEl.addEventListener('shown.bs.tab', function (e) {
                        var id = e.target.getAttribute('data-bs-target');
                        if (hidden) hidden.value = id;
                        try { localStorage.setItem(storageKey, id); } catch (ex) { }
                    });
                }
                // Inicializa el módulo reutilizable de mejora de grillas
                function initInteractiveTables(){ if(window.GridEnhancer){ window.GridEnhancer.enhanceAll(); GridEnhancer.filter(document.getElementById('globalSearch')?.value||''); } }
                 // Desactivado temporalmente el enhancer automático

                // Sincroniza búsqueda de ticket con filtro global
                function wireGlobalSync(){
                    var tbTicket = document.getElementById('<%= txtConsulta.ClientID %>');
                    var tbGlobal = document.getElementById('globalSearch');
                    if(tbTicket){
                        tbTicket.addEventListener('input', function(){
                            if(tbGlobal){ tbGlobal.value = tbTicket.value; }
                            try{ if(window.GridEnhancer){ GridEnhancer.filter(tbTicket.value); } }catch(e){}
                        });
                    }
                    if(tbGlobal){
                        tbGlobal.addEventListener('input', function(){
                            if(tbTicket){ tbTicket.value = tbGlobal.value; }
                        });
                    }
                }
                document.addEventListener('DOMContentLoaded', wireGlobalSync);
                try{ if(window.Sys && Sys.WebForms){ Sys.WebForms.PageRequestManager.getInstance().add_endRequest(function(){ wireGlobalSync(); }); } }catch(e){}
            })();
        </script>
        <script type="text/javascript">
            // helper robusto para cerrar el modal si coincidiera una instancia previa
            function forceCloseLoginModal(){
                try{
                    var lm = document.getElementById('loginModal');
                    if(!lm || !window.bootstrap) return;
                    var inst = bootstrap.Modal.getInstance(lm) || new bootstrap.Modal(lm);
                    try{ inst.hide(); }catch(e){}
                    // Limpieza agresiva por si quedó un backdrop/estado pegado
                    document.body.classList.remove('modal-open');
                    var backdrops = document.querySelectorAll('.modal-backdrop');
                    backdrops.forEach(function(b){ try{ b.parentNode && b.parentNode.removeChild(b); }catch(e){} });
                    // restaurar estilos que bootstrap ajusta
                    document.body.style.removeProperty('padding-right');
                    document.body.style.removeProperty('overflow');
                }catch(e){}
            }
        </script>
    </div>
            <!-- Botón oculto para fallback de bind TRAC (debe estar dentro del ContentTemplate) -->
            <asp:Button ID="btnBindTrac" runat="server" OnClick="btnBindTrac_Click" Style="display:none" />
            </ContentTemplate>
            <Triggers>
                <asp:AsyncPostBackTrigger ControlID="btnBuscar" EventName="Click" />
                <asp:AsyncPostBackTrigger ControlID="grdDatos" EventName="SelectedIndexChanged" />
                <asp:AsyncPostBackTrigger ControlID="btnAplicarCarga" EventName="Click" />
                <asp:AsyncPostBackTrigger ControlID="grdHoras" EventName="SelectedIndexChanged" />
                 <asp:AsyncPostBackTrigger ControlID="btnBindTrac" EventName="Click" />
            </Triggers>
        </asp:UpdatePanel>

        <!-- Modal de Login -->
        <div class="modal fade" id="loginModal" tabindex="-1" aria-labelledby="loginModalLabel" aria-hidden="true">
          <div class="modal-dialog modal-dialog-centered">
            <div class="modal-content">
              <div class="modal-header">
                <h5 class="modal-title" id="loginModalLabel">Iniciar sesión</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
              </div>
              <div class="modal-body">
                <label class="form-label" for="<%= txtLegajo.ClientID %>">Usuario</label>
                <div class="input-group" id="loginBox">
                    <asp:TextBox ID="txtLegajo" CssClass="form-control" runat="server" placeholder="Legajo / nombre / usuario / mail"></asp:TextBox>
                            <asp:TextBox ID="txtPassword" CssClass="form-control" runat="server" placeholder="Contraseña (deshabilitada)" TextMode="Password" Enabled="false" />
                    <asp:Button ID="btnBuscar" runat="server" OnClick="btnBuscar_Click" CssClass="btn btn-primary" Text="Log In" />
                </div>
              </div>
              <div class="modal-footer">
                <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cerrar</button>
              </div>
            </div>
          </div>
        </div>

        <!-- Botones ocultos para acciones de usuario (invocados desde la navbar) -->
        <asp:Button ID="btnCambiarUsuario" runat="server" OnClick="btnCambiarUsuario_Click" Style="display:none" />
        <asp:Button ID="btnLogout" runat="server" OnClick="btnLogout_Click" Style="display:none" />

    </asp:Content>
