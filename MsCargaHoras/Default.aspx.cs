using System;
using System.Collections.Generic;
using System.Data;
using System.Globalization;
using System.Linq;
using System.Web.UI;
using System.Configuration;
using System.Data.SqlClient;
using System.Web.Security;
using System.Text;
using MsCargaHoras.Data;

namespace MsCargaHoras
{
    public partial class _Default : Page
    {
        private const string SesionHorasKey = "HORAS_EDITABLES";
        private void ClearAllGrids()
        {
            try
            {
                // Horas faltantes
                grdDatos.DataSource = null; grdDatos.DataBind(); total.Text = string.Empty;
                // Sugeridas
                grdSugeridas.DataSource = null; grdSugeridas.DataBind(); ViewState.Remove("SUGERIDAS_TABLE"); ViewState.Remove("SUGERIDAS_SORT_DIR");
                // Carga de Horas
                Session.Remove(SesionHorasKey);
                grdHoras.DataSource = null; grdHoras.DataBind();
                lblDiaSeleccionado.Text = "-"; lblFechaSeleccionada.Text = "--/--/----"; lblFaltaSeleccionada.Text = "0";
                // Trac pendientes
                hidLegajoNum.Value = string.Empty; hidTracAuthor.Value = string.Empty; hidTracSelTicketId.Value = string.Empty;
                grdTrac.DataSource = null; grdTrac.DataBind();
                // Feedback
                try{ ScriptManager.RegisterStartupScript(this, GetType(), "toastCleared", "try{UiCommon.showToast('Pantalla limpiada.','info');}catch(e){}", true);}catch{}
            }
            catch { }
        }

        protected void Page_Load(object sender, EventArgs e)
        {
            // Sincronizar sesión desde cookie si aplica
            try
            {
                if (Session["LOGIN_USER"] == null)
                {
                    // 1) Preferir valor que cargó el módulo (desencriptado)
                    var fromModule = Convert.ToString(Context.Items["LOGIN_USER"]);
                    // 2) Compatibilidad: si no vino del módulo, intentar desencriptar cookie
                    if (string.IsNullOrWhiteSpace(fromModule))
                    {
                        var ck = Request.Cookies["ms_login"];
                        var raw = ck != null ? Server.UrlDecode(ck.Value) : null;
                        fromModule = TryUnprotect(raw) ?? raw; // si viniera legacy plano, quedará visible pero se normalizará luego
                    }
                    if (!string.IsNullOrWhiteSpace(fromModule)) { Session["LOGIN_USER"] = fromModule; }
                }
            }
            catch { }

            if (!IsPostBack)
            {
                // Estado de login
                var login = Convert.ToString(Session["LOGIN_USER"]) ?? string.Empty;
                if (string.IsNullOrWhiteSpace(login))
                {
                    // No logueado: limpiar todo y forzar modal de login
                    ClearAllGrids();
                    var scriptShow = "try{ var a=document.getElementById('loginActions'); if(a) a.style.display='none'; var lm=document.getElementById('loginModal'); if(lm && window.bootstrap){ var inst = bootstrap.Modal.getInstance(lm) || new bootstrap.Modal(lm,{backdrop:'static',keyboard:false}); inst.show(); } }catch(e){}";
                    System.Web.UI.ScriptManager.RegisterStartupScript(this, GetType(), "showLoginModalOnInit", scriptShow, true);
                    // Fecha por defecto en Carga de Horas
                    try { dtpFechaCarga.Text = DateTime.Today.ToString("yyyy-MM-dd"); } catch { }
                    return;
                }
                else
                {
                    // Logueado: aplicar filtro y mostrar barra
                    txtLegajo.Text = login;
                    AplicarFiltro(login);
                    var safe = (login ?? string.Empty).Replace("\\", "\\\\").Replace("'", "\\'").Replace("\r", " ").Replace("\n", " ");
                    var script = "try{ var a=document.getElementById('loginActions'); if(a) a.style.display='flex'; var l=document.getElementById('lblLoginUsuario'); if(l) l.innerText='" + safe + "'; forceCloseLoginModal && forceCloseLoginModal(); }catch(e){}";
                    System.Web.UI.ScriptManager.RegisterStartupScript(this, GetType(), "restoreLoginBox", script, true);
                    // Fecha por defecto en Carga de Horas
                    try { dtpFechaCarga.Text = DateTime.Today.ToString("yyyy-MM-dd"); } catch { }
                }
            }
        }

        private static string TryUnprotect(string protectedValue)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(protectedValue)) return null;
                var urlDecoded = System.Web.HttpUtility.UrlDecode(protectedValue);
                var data = Convert.FromBase64String(urlDecoded);
                var plain = MachineKey.Unprotect(data, "ms_login_v1");
                return plain == null ? null : Encoding.UTF8.GetString(plain);
            }
            catch { return null; }
        }

        protected void btnBuscar_Click(object sender, EventArgs e)
        {
            AplicarFiltro(txtLegajo.Text?.Trim());
            // Persistir "login" simple en sesión y localStorage vía script
            var login = (txtLegajo.Text ?? string.Empty).Trim();
            Session["LOGIN_USER"] = login;
            // Set cookie simple (httpOnly) para que el módulo la restaure en cada request
            try
            {
                // Proteger el valor con MachineKey.Protect + Base64
                var raw = System.Text.Encoding.UTF8.GetBytes(login ?? string.Empty);
                var prot = System.Web.Security.MachineKey.Protect(raw, "ms_login_v1");
                var b64 = Convert.ToBase64String(prot ?? Array.Empty<byte>());
                var ck = new System.Web.HttpCookie("ms_login", Server.UrlEncode(b64))
                {
                    HttpOnly = true,
                    Secure = Request.IsSecureConnection,
                    SameSite = System.Web.SameSiteMode.Lax,
                    Expires = DateTime.UtcNow.AddDays(7)
                };
                Response.Cookies.Set(ck);
            }
            catch { }
            var safe = (login ?? string.Empty).Replace("\\", "\\\\").Replace("'", "\\'").Replace("\r", " ").Replace("\n", " ");
            var script = $"try{{ if(window.UserState){{ UserState.resetFilters(); }} localStorage.setItem('app:loggedUser', '{safe}'); var acts=document.getElementById('loginActions'); if(acts){{ acts.style.display='flex'; var l=document.getElementById('lblLoginUsuario'); if(l) l.innerText='{safe}'; }} if(window.UserUi){{ UserUi.set('{safe}','{(ObtenerLegajoDeEntrada(login) ?? "")}','{ResolverAuthorTracDesdeEntrada(login)}',''); }} var lm=document.getElementById('loginModal'); if(lm && window.bootstrap){{ var inst=bootstrap.Modal.getInstance(lm) || new bootstrap.Modal(lm); inst.hide(); }} }}catch(e){{}}";
            System.Web.UI.ScriptManager.RegisterStartupScript(this, GetType(), "persistLogin", script, true);
        }

        protected void btnLogout_Click(object sender, EventArgs e)
        {
            Session.Remove("LOGIN_USER");
            Session.Remove("CURRENT_USER");
            txtLegajo.Text = string.Empty;
            try{ var ck = new System.Web.HttpCookie("ms_login", ""); ck.Expires = DateTime.UtcNow.AddDays(-1); Response.Cookies.Set(ck);}catch{}
            ClearAllGrids();
            var script = "try{ if(window.UserState){ UserState.resetFilters(); } localStorage.removeItem('app:loggedUser'); if(window.UserUi){ UserUi.set('','','',''); } var dn=document.getElementById('ddUserNombre'); if(dn) dn.innerText=''; var dl=document.getElementById('ddUserLegajo'); if(dl) dl.innerText=''; var du=document.getElementById('ddUserUsuario'); if(du) du.innerText=''; var dm=document.getElementById('ddUserMail'); if(dm) dm.innerText=''; var av=document.getElementById('avatarInitials'); if(av) av.textContent='--'; var lm=document.getElementById('loginModal'); if(lm && window.bootstrap){ var inst = bootstrap.Modal.getInstance(lm) || new bootstrap.Modal(lm,{backdrop:'static',keyboard:false}); inst.show(); } }catch(e){}";
            System.Web.UI.ScriptManager.RegisterStartupScript(this, GetType(), "logout", script, true);
        }

        protected void btnCambiarUsuario_Click(object sender, EventArgs e)
        {
            // Mostrar modal para ingresar otro usuario
            ClearAllGrids();
            var script = "try{ var lm=document.getElementById('loginModal'); if(lm && window.bootstrap){ var inst = bootstrap.Modal.getInstance(lm) || new bootstrap.Modal(lm,{backdrop:'static',keyboard:false}); inst.show(); } }catch(e){}";
            System.Web.UI.ScriptManager.RegisterStartupScript(this, GetType(), "switchUser", script, true);
        }

        public void AplicarFiltro(string filtro)
        {
            // Sincroniza el textbox interno (oculto) para no romper bindings existentes
            txtLegajo.Text = filtro ?? string.Empty;

            // El SqlDataSource está configurado como StoredProcedure = BuscarHsPendientesDeCarga
            // y toma el parámetro "Filtro" desde txtLegajo.Text
            var sw = System.Diagnostics.Stopwatch.StartNew();
            try { grdDatos.DataBind(); }
            catch (Exception ex) { TryToastError("Error cargando horas faltantes: " + ex.Message); MsCargaHoras.App_Start.Logger.Error("Bind grdDatos", ex); }
            finally { sw.Stop(); MsCargaHoras.App_Start.Logger.Info($"Bind grdDatos: {sw.ElapsedMilliseconds}ms"); }
            ActualizarTotalDesdeGrid();

            // Resolve usuario desde LABTRAC y cachea en Session (estandariza nombres de columnas)
            var entrada = txtLegajo.Text?.Trim();
                    var repo = new MsCargaHoras.Data.LabtracRepository();
                    var dt = repo.AGLTRAC_ObtenerLegajosUsuarios(string.IsNullOrWhiteSpace(entrada) ? "Desarrollo" : entrada, true);
            var current = new MsCargaHoras.App_Start.CurrentUser();
                    if (dt != null && dt.Rows.Count > 0)
                    {
                        var row = dt.Rows[0];
                // Centraliza nombres de campos heterogéneos del store
                string nombre = row.Table.Columns.Contains("ApeyNom") ? Convert.ToString(row["ApeyNom"]) : (row.Table.Columns.Contains("Nombre") ? Convert.ToString(row["Nombre"]) : entrada);
                string legajo = row.Table.Columns.Contains("NroLegajo") ? Convert.ToString(row["NroLegajo"]) : ObtenerLegajoDeEntrada(entrada);
                string usuario = row.Table.Columns.Contains("Usuario") ? Convert.ToString(row["Usuario"]) : ResolverAuthorTracDesdeEntrada(entrada);
                string mail = row.Table.Columns.Contains("Email") ? Convert.ToString(row["Email"]) : (row.Table.Columns.Contains("Mail") ? Convert.ToString(row["Mail"]) : string.Empty);
                current.Nombre = nombre ?? string.Empty;
                current.Legajo = legajo ?? string.Empty;
                current.Usuario = usuario ?? string.Empty;
                current.Email = mail ?? string.Empty;
                    }
                    else
                    {
                // Fallback minimal
                current.Nombre = entrada ?? string.Empty;
                current.Legajo = ObtenerLegajoDeEntrada(entrada) ?? string.Empty;
                current.Usuario = ResolverAuthorTracDesdeEntrada(entrada) ?? string.Empty;
            }
            Session["CURRENT_USER"] = current;
            // Refresco de UI + bindeo centralizado
            ClearAllGrids();
            ApplyUserToHeader(current);
            BindAllGrids(current, entrada);
            // Fallback: disparar bind de TRAC fuera de UpdatePanel si quedara pendiente
            try{ btnBindTrac_Click(this, EventArgs.Empty); }catch{}

            // Empuja actualización de user header y avatar en cliente (navbar está fuera del UpdatePanel)
            try
            {
                string Js(string s) => System.Web.HttpUtility.JavaScriptStringEncode(s ?? string.Empty);
                var sb = new System.Text.StringBuilder();
                sb.AppendLine("(function(){try{");
                sb.AppendFormat("var n='{0}', l='{1}', u='{2}', m='{3}';", Js(current.Nombre), Js(current.Legajo), Js(current.Usuario), Js(current.Email)).AppendLine();
                sb.AppendLine("try{ var dn=document.getElementById('ddUserNombre'); if(dn) dn.innerText=n; }catch(e){}");
                sb.AppendLine("try{ var dl=document.getElementById('ddUserLegajo'); if(dl) dl.innerText=l; }catch(e){}");
                sb.AppendLine("try{ var du=document.getElementById('ddUserUsuario'); if(du) du.innerText=u; }catch(e){}");
                sb.AppendLine("try{ var dm=document.getElementById('ddUserMail'); if(dm) dm.innerText=m; }catch(e){}");
                sb.AppendLine("var av=document.getElementById('avatarInitials');");
                sb.AppendLine("var ini=(function(t){ if(!t) return ''; var p=t.trim().split(/\\s+/); var a=p[0]?p[0].charAt(0):''; var b=p[1]?p[1].charAt(0):''; return (a+b).toUpperCase(); })(n) || (l||'--');");
                sb.AppendLine("if(av) av.textContent=ini;");
                sb.AppendLine("var acts=document.getElementById('loginActions'); if(acts){ acts.style.display='flex'; var lEl=document.getElementById('lblLoginUsuario'); if(lEl) lEl.innerText=n||u||m||l; }");
                sb.AppendLine("if(window.forceCloseLoginModal){ try{ forceCloseLoginModal(); }catch(_){} }");
                sb.AppendLine("}catch(e){} })();");
                var script = sb.ToString();
                System.Web.UI.ScriptManager.RegisterStartupScript(this, GetType(), "updUserHeader", script, true);
            }
            catch { }
        }

        protected void ddlFuente_SelectedIndexChanged(object sender, EventArgs e)
        {
            // Reconsultar tareas al cambiar la fuente, solo si hay filtro
            var filtro = (txtLegajo.Text ?? string.Empty).Trim();
            if (string.IsNullOrWhiteSpace(filtro)) return;
                grdTrac.DataBind();
            }

        // Aplica datos del usuario a la cabecera (navbar y dropdown del master)
        private void ApplyUserToHeader(MsCargaHoras.App_Start.CurrentUser user)
        {
            if (user == null) return;
            var master = this.Master;
            if (master == null) return;

            var lblNombre = master.FindControl("lblNavbarNombre") as System.Web.UI.WebControls.Label;
            var lblLegajo = master.FindControl("lblNavbarLegajo") as System.Web.UI.WebControls.Label;
            if (lblNombre != null) lblNombre.Text = string.IsNullOrWhiteSpace(user.Nombre) ? "-" : user.Nombre;
            if (lblLegajo != null) lblLegajo.Text = string.IsNullOrWhiteSpace(user.Legajo) ? "-" : user.Legajo;

            var lblUserNombre = master.FindControl("lblUserNombre") as System.Web.UI.WebControls.Label;
            var lblUserLegajo = master.FindControl("lblUserLegajo") as System.Web.UI.WebControls.Label;
            var lblUserUsuario = master.FindControl("lblUserUsuario") as System.Web.UI.WebControls.Label;
            var lblUserMail = master.FindControl("lblUserMail") as System.Web.UI.WebControls.Label;
            if (lblUserNombre != null) lblUserNombre.Text = user.Nombre ?? string.Empty;
            if (lblUserLegajo != null) lblUserLegajo.Text = string.IsNullOrWhiteSpace(user.Legajo) ? "-" : user.Legajo;
            if (lblUserUsuario != null) lblUserUsuario.Text = user.Usuario ?? string.Empty;
            if (lblUserMail != null) lblUserMail.Text = user.Email ?? string.Empty;
        }

        // Bindea todas las grillas respetando el usuario actual y setea campos auxiliares
        private void BindAllGrids(MsCargaHoras.App_Start.CurrentUser user, string filtroEntrada)
        {
            if (user == null) return;

            // Faltantes
            try { grdDatos.DataBind(); ActualizarTotalDesdeGrid(); } catch { }

            // TRAC pendientes: autor y bind
            try
            {
                hidTracAuthor.Value = string.IsNullOrWhiteSpace(user.Usuario) ? ResolverAuthorTracDesdeEntrada(filtroEntrada) : user.Usuario;
                var sw2 = System.Diagnostics.Stopwatch.StartNew();
                try { grdTrac.DataBind(); }
                catch (Exception ex) { TryToastError("Error cargando tareas TRAC: " + ex.Message); MsCargaHoras.App_Start.Logger.Error("Bind grdTrac", ex); }
                finally { sw2.Stop(); MsCargaHoras.App_Start.Logger.Info($"Bind grdTrac: {sw2.ElapsedMilliseconds}ms"); }
            }
            catch { }

            // Legajo numérico (otras integraciones)
            if (int.TryParse(user.Legajo, out _)) { hidLegajoNum.Value = user.Legajo; }

            // UX: fecha por defecto para carga de horas
            try { dtpFechaCarga.Text = DateTime.Today.ToString("yyyy-MM-dd"); } catch { }
        }

        // Botón oculto para garantizar bind de TRAC si el UpdatePanel quedara inconsistente
        protected void btnBindTrac_Click(object sender, EventArgs e)
        {
            try
            {
                grdTrac.DataBind();
            }
            catch (Exception ex)
            {
                TryToastError("TRAC: " + ex.Message);
            }
        }

        private void TryToastError(string message)
        {
            try { ScriptManager.RegisterStartupScript(this, GetType(), Guid.NewGuid().ToString("N"), $"try{{UiCommon.showToast('{System.Web.HttpUtility.JavaScriptStringEncode(message)}','danger');}}catch(e){{}}", true); } catch { }
        }

        private string ObtenerUsuarioTracDesdeLabtrac(string filtro)
        {
            try
            {
                var repo = new MsCargaHoras.Data.LabtracRepository();
                var dt = repo.AGLTRAC_ObtenerLegajosUsuarios(string.IsNullOrWhiteSpace(filtro) ? "Desarrollo" : filtro, true);
                if (dt != null && dt.Rows.Count > 0)
                {
                    var usuario = Convert.ToString(dt.Rows[0]["Usuario"]);
                    if (!string.IsNullOrWhiteSpace(usuario)) return usuario.Trim();
                }
            }
            catch { }
            return null;
        }

        private string ResolverAuthorTracDesdeEntrada(string entrada)
        {
            // Regla simple: si el texto contiene algo como ":usuario" o "usuario@",
            // intentamos extraer un posible login; de lo contrario, devolvemos default
            if (!string.IsNullOrWhiteSpace(entrada))
            {
                var txt = entrada.Trim();
                int atIdx = txt.IndexOf('@');
                if (atIdx > 0)
                {
                    return txt.Substring(0, atIdx).Trim();
                }
                int spcIdx = txt.IndexOf(' ');
                if (spcIdx > 0)
                {
                    // Si viene "1234 Apellido, Nombre" intentamos usuario conocido por mapeo simple
                    var posible = txt.Replace(" ", "").ToLowerInvariant();
                }
            }
            // Fallback según requerimiento
            return "alipshitz";
        }

        // ------------- Integración con TareasNetMs (Carga de Horas) ---------------
        protected void btnAplicarCarga_Click(object sender, EventArgs e)
        {
            // Lee cabecera y detalle del día seleccionado desde TareasNetMs
            if (!DateTime.TryParse(dtpFechaCarga.Text, out var fecha))
            {
                // Si no hay fecha, usar hoy (00:00)
                fecha = DateTime.Today;
            }

            var repoTn = new MsCargaHoras.Data.TareasNetMsRepository();
            // Traer detalle actual desde TareasNetMs (AGLTRAC_HorasDet_Obtener) aceptando filtro mixto
            string filtro = (txtLegajo.Text ?? string.Empty).Trim();
            DataTable det;
            if (int.TryParse(ObtenerLegajoDeEntrada(filtro), out var nroLegajo))
            {
                det = repoTn.AGLTRAC_HorasDet_Obtener(nroLegajo, fecha);
            }
            else
            {
                det = repoTn.AGLTRAC_HorasDet_Obtener(string.IsNullOrWhiteSpace(filtro) ? "Desarrollo" : filtro, fecha);
            }

            if (det == null)
            {
                try{ ScriptManager.RegisterStartupScript(this, GetType(), "toastErr", "try{UiCommon.showToast('No se pudo obtener horas del día seleccionado.','danger');}catch(e){}", true);}catch{}
                return;
            }

            // Cargar combos de TipoDoc y TipoTarea + Clientes/Proyectos permitidos
            var tiposDoc = repoTn.TiposDoc_Combo_Cached();
            var tiposTarea = repoTn.TipoTarea_Combo_Cached();
            var cliProy = repoTn.Derechos_Buscar_ClientesProyectos_Cached(nroLegajo, fecha, null, null);
            Session["COMBO_TIPOS_DOC"] = tiposDoc;
            Session["COMBO_TIPO_TAREA"] = tiposTarea;
            Session["COMBO_CLIENTE_PROYECTO"] = cliProy;

            // Mapear a modelo simple en memoria
            var lista = det.AsEnumerable().Select((r, idx) => new HoraEditable
            {
                Id = idx + 1,
                Cliente = det.Columns.Contains("RazonSocial") ? (r["RazonSocial"] as string ?? string.Empty) : string.Empty,
                Proyecto = det.Columns.Contains("DescProyecto") ? (r["DescProyecto"] as string ?? string.Empty) : string.Empty,
                Actividad = det.Columns.Contains("DescActividad") ? (r["DescActividad"] as string ?? string.Empty) : string.Empty,
                Tarea = det.Columns.Contains("DescTipoTarea") ? (r["DescTipoTarea"] as string ?? string.Empty) : string.Empty,
                Desde = det.Columns.Contains("HoraDesde") ? FormatearHora(r["HoraDesde"]) : string.Empty,
                Hasta = det.Columns.Contains("HoraHasta") ? FormatearHora(r["HoraHasta"]) : string.Empty,
                Horas = det.Columns.Contains("Horas") ? Convert.ToDecimal(r.Field<double?>("Horas") ?? 0d) : 0m,
                Fuera = det.Columns.Contains("Fuera") ? (r.Field<bool?>("Fuera") ?? false) : false,
                TipoDoc = det.Columns.Contains("DescTipoDoc") ? (r["DescTipoDoc"] as string ?? string.Empty) : string.Empty,
                NroDoc = det.Columns.Contains("NroDocId") ? (r["NroDocId"] == DBNull.Value ? string.Empty : Convert.ToString(r["NroDocId"])) : string.Empty,
                Observaciones = det.Columns.Contains("DescripTarea") ? (r["DescripTarea"] as string ?? string.Empty) : string.Empty
            }).ToList();

            Session[SesionHorasKey] = lista;
            RebindHoras();
            RecalcularTotales();
            try{ ScriptManager.RegisterStartupScript(this, GetType(), "toastOk", "try{UiCommon.showToast('Horas del día cargadas.','success');}catch(e){}", true);}catch{}
        }

        private static string FormatearHora(object valor)
        {
            if (valor == null || valor == DBNull.Value) return string.Empty;
            var s = Convert.ToString(valor)?.Trim();
            if (TimeSpan.TryParse(s, out var ts)) return ts.ToString(@"hh\:mm");
            // algunos registros pueden venir como "     " (5 espacios)
            return string.IsNullOrWhiteSpace(s) ? string.Empty : s;
        }

        private void ActualizarTotalDesdeGrid()
        {
            // Cuenta filas resultantes y muestra en la etiqueta "total"
            int cantidadFilas = grdDatos.Rows == null ? 0 : grdDatos.Rows.Count;
            var texto = cantidadFilas > 0 ? $"Resultados: {cantidadFilas}" : "Sin resultados";
            total.Text = texto;

            // Sumarizador de la columna 'Falta' (detecta índice por encabezado)
            try
            {
                int idxColFalta = -1;
                if (grdDatos.HeaderRow != null)
                {
                    for (int i = 0; i < grdDatos.HeaderRow.Cells.Count; i++)
                    {
                        var h = (grdDatos.HeaderRow.Cells[i].Text ?? string.Empty).Trim();
                        if (h.Equals("Falta", StringComparison.OrdinalIgnoreCase) || h.Equals("Falta Cargar", StringComparison.OrdinalIgnoreCase))
                        { idxColFalta = i; break; }
                    }
                }
                if (idxColFalta < 0) idxColFalta = 3; // fallback seguro
                decimal suma = 0m;
                foreach (System.Web.UI.WebControls.GridViewRow row in grdDatos.Rows)
                {
                    if (row.Cells.Count > idxColFalta)
                    {
                        var raw = row.Cells[idxColFalta].Text ?? "0";
                        // Extraer números por si hay formato textual
                        var digits = new string(raw.Where(ch => char.IsDigit(ch) || ch == ',' || ch == '.').ToArray());
                        if (decimal.TryParse(digits, System.Globalization.NumberStyles.Any, System.Globalization.CultureInfo.InvariantCulture, out var val))
                        {
                            suma += val;
                        }
                        else if (decimal.TryParse(digits, out val))
                        {
                            suma += val;
                        }
                    }
                }
                try { lblDiasFaltantes.Text = cantidadFilas > 0 ? ($"{cantidadFilas} días") : string.Empty; } catch { }
                try { lblHorasFaltantes.Text = cantidadFilas > 0 ? ($"{suma:0.##} Hs") : string.Empty; } catch { }
            }
            catch { try { lblDiasFaltantes.Text = string.Empty; lblHorasFaltantes.Text = string.Empty; } catch { } }
        }

        protected void grdDatos_DataBound(object sender, EventArgs e)
        {
            // Ajuste visual: ocultar select con CSS manteniendo el render para no romper EventValidation
            if (grdDatos.HeaderRow != null && grdDatos.HeaderRow.Cells.Count > 0)
            {
                var c = grdDatos.HeaderRow.Cells[0];
                c.CssClass = string.IsNullOrEmpty(c.CssClass) ? "d-none" : (c.CssClass + " d-none");
            }
            foreach (System.Web.UI.WebControls.GridViewRow row in grdDatos.Rows)
            {
                if (row.Cells.Count > 0)
                {
                    var c = row.Cells[0];
                    c.CssClass = string.IsNullOrEmpty(c.CssClass) ? "d-none" : (c.CssClass + " d-none");
                }
            }

            // Ocultar columnas de Legajo y ApeyNom si existen en el resultado
            try
            {
                // Buscamos por encabezados conocidos
                int idxLegajo = -1, idxApeyNom = -1;
                if (grdDatos.HeaderRow != null)
                {
                    for (int i = 0; i < grdDatos.HeaderRow.Cells.Count; i++)
                    {
                        var headerText = grdDatos.HeaderRow.Cells[i].Text?.Trim();
                        if (string.Equals(headerText, "Legajo", StringComparison.OrdinalIgnoreCase)) idxLegajo = i;
                        if (string.Equals(headerText, "Apellido y Nombre", StringComparison.OrdinalIgnoreCase) || string.Equals(headerText, "ApeyNom", StringComparison.OrdinalIgnoreCase)) idxApeyNom = i;
                    }
                }
                if (idxLegajo >= 0)
                {
                    grdDatos.HeaderRow.Cells[idxLegajo].Visible = false;
                    foreach (System.Web.UI.WebControls.GridViewRow row in grdDatos.Rows)
                    {
                        row.Cells[idxLegajo].Visible = false;
                    }
                }
                if (idxApeyNom >= 0)
                {
                    grdDatos.HeaderRow.Cells[idxApeyNom].Visible = false;
                    foreach (System.Web.UI.WebControls.GridViewRow row in grdDatos.Rows)
                    {
                        row.Cells[idxApeyNom].Visible = false;
                    }
                }
            }
            catch { /* visual only */ }

            // Toast con cantidad de filas visibles
            try
            {
                int count = grdDatos.Rows == null ? 0 : grdDatos.Rows.Count;
                ScriptManager.RegisterStartupScript(this, GetType(), Guid.NewGuid().ToString("N"), $"try{{UiCommon.showToast('Resumen: {count} filas.','info');}}catch(e){{}}", true);
            }
            catch { }
        }

        protected void grdDatos_SelectedIndexChanged(object sender, EventArgs e)
        {
            // Refleja día/fecha en encabezado y aplica carga para esa fecha
            if (grdDatos.SelectedRow == null) return;
            var row = grdDatos.SelectedRow;
            // Asume columnas Día | FechaCarga | Falta
            try
            {
                lblDiaSeleccionado.Text = row.Cells.Count > 1 ? row.Cells[1].Text : "-";
                lblFechaSeleccionada.Text = row.Cells.Count > 2 ? row.Cells[2].Text : "--/--/----";
                var faltaTxt = row.Cells.Count > 3 ? row.Cells[3].Text : "0";
                lblFaltaSeleccionada.Text = new string(faltaTxt.Where(char.IsDigit).ToArray());
            }
            catch { /* visual only */ }

            // Disparar consulta de horas sugeridas para la fecha seleccionada
            DateTime fecha;
            if (!DateTime.TryParse(lblFechaSeleccionada.Text, out fecha)) return;

            // Setea la fecha en el selector de Carga de Horas (yyyy-MM-dd para input[type=date])
            try
            {
                dtpFechaCarga.Text = fecha.ToString("yyyy-MM-dd");
            }
            catch { }

            // Cargar horas reales del día en la grilla de edición (solo consulta) y cargar horas sugeridas
            CargarHorasRealesDesdeBase(fecha);
            CargarHorasSugeridas(fecha);
            // No rebindear TRAC completo aquí: ya está cargado; solo aplicar filtros en cliente
            try { ScriptManager.RegisterStartupScript(this, GetType(), Guid.NewGuid().ToString("N"), "try{ if(window.GridEnhancer){ GridEnhancer.enhanceAll(); } }catch(e){}", true); } catch { }
        }

        private void CargarHorasSugeridas(DateTime fecha)
        {
            // Consultar tareas sugeridas usando el store específico (misma firma que Asignadas)
            try
            {
                // Clonar configuración y ejecutar el SP de sugeridas
                using (var cn = new System.Data.SqlClient.SqlConnection(System.Configuration.ConfigurationManager.ConnectionStrings["LABTRACConnectionString"].ConnectionString))
                using (var cmd = new System.Data.SqlClient.SqlCommand("AGLTRAC_ObtenerHorasSugeridas", cn))
                {
                    cmd.CommandType = System.Data.CommandType.StoredProcedure;
                    cmd.CommandTimeout = 15;
                    // Reutilizamos el mismo criterio que dsTrac_Selecting
                    string filtro = (txtLegajo.Text ?? string.Empty).Trim();
                    if (string.IsNullOrWhiteSpace(filtro)) filtro = "Desarrollo";
                    cmd.Parameters.AddWithValue("@Filtro", (object)filtro ?? System.DBNull.Value);
                    cmd.Parameters.AddWithValue("@SoloActivos", true);
                    cmd.Parameters.AddWithValue("@FechaDesde", DateTime.Today.AddDays(-60));
                    cmd.Parameters.AddWithValue("@Fuente", (ddlFuente.SelectedValue ?? "TODOS").ToUpperInvariant());
                    // Log
                    try { MsCargaHoras.App_Start.Logger.Info($"Sugeridas: Exec AGLTRAC_ObtenerHorasSugeridas @Filtro='{filtro}', @SoloActivos=true, @FechaDesde={DateTime.Today.AddDays(-60):yyyy-MM-dd}, @Fuente='{(ddlFuente.SelectedValue ?? "TODOS").ToUpperInvariant()}'"); } catch {}

                    cn.Open();
                    var da = new System.Data.SqlClient.SqlDataAdapter(cmd);
                    var table = new System.Data.DataTable();
                    da.Fill(table);
                    try { MsCargaHoras.App_Start.Logger.Info($"Sugeridas: rows={table?.Rows.Count ?? 0}"); } catch {}
                if (table != null && table.Rows.Count > 0)
                {
                    // Mostrar TOP 10 para no saturar la sección
                    var top = table.AsEnumerable().Take(10);
                    var result = top.Any() ? top.CopyToDataTable() : table.Clone();

                    // Calcular total de horas (si hay columna numérica compatible) y días
                    try
                    {
                        int dias = result.Rows.Count;
                        decimal horas = 0m;
                        // Buscar una columna compatible por nombre (Falta/Faltan/Horas)
                        var faltaCol = result.Columns.Cast<System.Data.DataColumn>()
                            .FirstOrDefault(c => c.ColumnName.Equals("Falta", StringComparison.OrdinalIgnoreCase)
                                              || c.ColumnName.Equals("Horas", StringComparison.OrdinalIgnoreCase)
                                              || c.ColumnName.Equals("Hs", StringComparison.OrdinalIgnoreCase));
                        if (faltaCol != null)
                        {
                            foreach (System.Data.DataRow r in result.Rows)
                            {
                                var raw = Convert.ToString(r[faltaCol]) ?? "0";
                                var digits = new string(raw.Where(ch => char.IsDigit(ch) || ch==',' || ch=='.').ToArray());
                                if (decimal.TryParse(digits, System.Globalization.NumberStyles.Any, System.Globalization.CultureInfo.InvariantCulture, out var v)) horas += v;
                                else if (decimal.TryParse(digits, out v)) horas += v;
                            }
                        }
                        try{ lblDiasFaltantes.Text = dias + " días"; }catch{}
                        try{ lblHorasFaltantes.Text = horas.ToString("0.##") + " Hs"; }catch{}
                    }
                    catch { }

                    grdSugeridas.DataSource = result;
                    ViewState["SUGERIDAS_TABLE"] = result; // soporte sorting/paging
                }
                else
                {
                    // Fallback: mostrar TOP 10 de asignadas si sugeridas está vacío (solo visual)
                    try
                    {
                        var view = dsTrac.Select(System.Web.UI.DataSourceSelectArguments.Empty) as System.Data.DataView;
                        var t2 = view == null ? null : view.ToTable();
                        if (t2 != null)
                        {
                            var top2 = t2.AsEnumerable().Take(10);
                            var result2 = top2.Any() ? top2.CopyToDataTable() : t2.Clone();
                            grdSugeridas.DataSource = result2;
                            ViewState["SUGERIDAS_TABLE"] = result2;
                        }
                        else { grdSugeridas.DataSource = null; ViewState.Remove("SUGERIDAS_TABLE"); }
                    }
                    catch { grdSugeridas.DataSource = null; ViewState.Remove("SUGERIDAS_TABLE"); }
                }
                }
            }
            catch(Exception ex)
            {
                try { MsCargaHoras.App_Start.Logger.Error("Sugeridas: excepción en CargarHorasSugeridas", ex); } catch { }
            grdSugeridas.DataSource = null;
                ViewState.Remove("SUGERIDAS_TABLE");
            }
            grdSugeridas.DataBind();
        }

        protected void grdSugeridas_PageIndexChanging(object sender, System.Web.UI.WebControls.GridViewPageEventArgs e)
        {
            grdSugeridas.PageIndex = e.NewPageIndex;
            var table = ViewState["SUGERIDAS_TABLE"] as System.Data.DataTable;
            grdSugeridas.DataSource = table;
            grdSugeridas.DataBind();
        }

        protected void grdSugeridas_Sorting(object sender, System.Web.UI.WebControls.GridViewSortEventArgs e)
        {
            var table = ViewState["SUGERIDAS_TABLE"] as System.Data.DataTable;
            if (table == null) return;
            var dir = ViewState["SUGERIDAS_SORT_DIR"] as string == "ASC" ? "DESC" : "ASC";
            ViewState["SUGERIDAS_SORT_DIR"] = dir;
            var view = new System.Data.DataView(table) { Sort = e.SortExpression + " " + dir };
            grdSugeridas.DataSource = view;
            grdSugeridas.DataBind();
        }

        protected void grdSugeridas_RowDataBound(object sender, System.Web.UI.WebControls.GridViewRowEventArgs e)
        {
            // Si hay columna Link en el DataTable y no viene en campos visibles, HyperLinkField ya usa DataNavigateUrlFields="Link"
            // Por compatibilidad, no hacemos nada aquí. Este hook queda para futuras personalizaciones (por ejemplo, íconos por tipo).
        }

        // Asegurar que el header quede dentro de THEAD para que los filtros/orden se rendericen bien y visibles
        protected void grdHoras_DataBound(object sender, EventArgs e)
        {
            if (grdHoras.HeaderRow != null)
            {
                grdHoras.HeaderRow.TableSection = System.Web.UI.WebControls.TableRowSection.TableHeader;
                try
                {
                    // Tipado numérico para ordenar mejor
                    int idxHoras = -1, idxFalta = -1;
                    for (int i = 0; i < grdHoras.HeaderRow.Cells.Count; i++)
                    {
                        var txt = grdHoras.HeaderRow.Cells[i].Text.Trim().ToLowerInvariant();
                        if (txt == "horas") idxHoras = i;
                        if (txt == "falta") idxFalta = i;
                    }
                    if (idxHoras >= 0) grdHoras.HeaderRow.Cells[idxHoras].Attributes["data-filter"] = "number";
                    if (idxFalta >= 0) grdHoras.HeaderRow.Cells[idxFalta].Attributes["data-filter"] = "number";
                }
                catch { }
            }
        }

        protected void grdTrac_DataBound(object sender, EventArgs e)
        {
            if (grdTrac.HeaderRow != null)
            {
                grdTrac.HeaderRow.TableSection = System.Web.UI.WebControls.TableRowSection.TableHeader;
            }
            try { ScriptManager.RegisterStartupScript(this, GetType(), Guid.NewGuid().ToString("N"), "try{ if(window.GridEnhancer){ GridEnhancer.enhanceAll(); } }catch(e){}", true); } catch { }
            // Toast con cantidad de filas visibles
            try
            {
                int count = grdTrac.Rows == null ? 0 : grdTrac.Rows.Count;
                ScriptManager.RegisterStartupScript(this, GetType(), Guid.NewGuid().ToString("N"), $"try{{UiCommon.showToast('TRAC: {count} filas.','info');}}catch(e){{}}", true);
            }
            catch { }
        }

        protected void grdSugeridas_DataBound(object sender, EventArgs e)
        {
            if (grdSugeridas.HeaderRow != null)
            {
                grdSugeridas.HeaderRow.TableSection = System.Web.UI.WebControls.TableRowSection.TableHeader;
                try
                {
                    // Título | type | Cliente | Proyecto | Fecha comprometida
                    if (grdSugeridas.HeaderRow.Cells.Count >= 5)
                    {
                        grdSugeridas.HeaderRow.Cells[4].Attributes["data-filter"] = "date";
                    }
                }
                catch { }
            }
            try
            {
                int count = grdSugeridas.Rows == null ? 0 : grdSugeridas.Rows.Count;
                ScriptManager.RegisterStartupScript(this, GetType(), Guid.NewGuid().ToString("N"), $"try{{UiCommon.showToast('Sugeridas: {count} filas.','info');}}catch(e){{}}", true);
            }
            catch { }
        }

        private void CargarHorasRealesDesdeBase(DateTime fecha)
        {
            // Solo consulta: leer LABTRAC (AGLTRAC_HorasDet_Obtener) y reflejar en la grilla editable en memoria, sin persistir
            var repoTn = new MsCargaHoras.Data.TareasNetMsRepository();
            string filtro = (txtLegajo.Text ?? string.Empty).Trim();
            DataTable det;
            if (int.TryParse(ObtenerLegajoDeEntrada(filtro), out var nroLegajo))
            {
                det = repoTn.AGLTRAC_HorasDet_Obtener(nroLegajo, fecha);
            }
            else
            {
                det = repoTn.AGLTRAC_HorasDet_Obtener(string.IsNullOrWhiteSpace(filtro) ? "Desarrollo" : filtro, fecha);
            }

            var lista = det.AsEnumerable().Select((r, idx) => new HoraEditable
            {
                Id = idx + 1,
                Cliente = det.Columns.Contains("RazonSocial") ? (r["RazonSocial"] as string ?? string.Empty) : string.Empty,
                Proyecto = det.Columns.Contains("DescProyecto") ? (r["DescProyecto"] as string ?? string.Empty) : string.Empty,
                Actividad = det.Columns.Contains("DescActividad") ? (r["DescActividad"] as string ?? string.Empty) : string.Empty,
                Tarea = det.Columns.Contains("DescTipoTarea") ? (r["DescTipoTarea"] as string ?? string.Empty) : string.Empty,
                Desde = det.Columns.Contains("HoraDesde") ? FormatearHora(r["HoraDesde"]) : string.Empty,
                Hasta = det.Columns.Contains("HoraHasta") ? FormatearHora(r["HoraHasta"]) : string.Empty,
                Horas = det.Columns.Contains("Horas") ? Convert.ToDecimal(r.Field<double?>("Horas") ?? 0d) : 0m,
                Fuera = det.Columns.Contains("Fuera") ? (r.Field<bool?>("Fuera") ?? false) : false,
                TipoDoc = det.Columns.Contains("DescTipoDoc") ? (r["DescTipoDoc"] as string ?? string.Empty) : string.Empty,
                NroDoc = det.Columns.Contains("NroDocId") ? (r["NroDocId"] == DBNull.Value ? string.Empty : Convert.ToString(r["NroDocId"])) : string.Empty,
                Observaciones = det.Columns.Contains("DescripTarea") ? (r["DescripTarea"] as string ?? string.Empty) : string.Empty
            }).ToList();

            Session[SesionHorasKey] = lista;
            RebindHoras();
            RecalcularTotales();
        }

        protected void grdDatos_RowDataBound(object sender, System.Web.UI.WebControls.GridViewRowEventArgs e)
        {
            // Permite seleccionar fila haciendo clic en cualquier celda
            if (e.Row.RowType == System.Web.UI.WebControls.DataControlRowType.DataRow)
            {
                e.Row.Attributes["style"] = "cursor:pointer";
                // Usar overload sin registerForEventValidation para evitar la excepción durante DataBind
                e.Row.Attributes["onclick"] = Page.ClientScript.GetPostBackClientHyperlink(grdDatos, "Select$" + e.Row.RowIndex);
            }
        }

        private static string ObtenerLegajoDeEntrada(string entrada)
        {
            if (string.IsNullOrWhiteSpace(entrada)) return "";
            // Si entrada contiene un número aislado, úselo; si no, dejar vacío
            var digits = new string(entrada.Where(char.IsDigit).ToArray());
            return digits;
        }

        protected void dsTrac_Selecting(object sender, System.Web.UI.WebControls.SqlDataSourceSelectingEventArgs e)
        {
            // Cancelar si no hay filtro ingresado
            var filtro = (txtLegajo.Text ?? string.Empty).Trim();
            if (string.IsNullOrWhiteSpace(filtro)) { e.Cancel = true; return; }

            // Parámetros del SP AGLTRAC_ObtenerTareasAsignadas
            var fuente = (ddlFuente.SelectedValue ?? "TODOS").ToUpperInvariant();
            // Optimización: limitar el rango temporal para reducir el set devuelto por el SP
            // Últimos 60 días a partir de hoy
            var fechaDesde = DateTime.Today.AddDays(-60);

            var parms = e.Command.Parameters;
            void Set(string name, object value)
            {
                if (!parms.Contains(name))
                {
                    var p = e.Command.CreateParameter();
                    p.ParameterName = name;
                    p.Value = value ?? DBNull.Value;
                    parms.Add(p);
                }
                else
                {
                    parms[name].Value = value ?? DBNull.Value;
                }
            }

            Set("@Filtro", filtro);
            Set("@SoloActivos", true);
            Set("@FechaDesde", fechaDesde);
            Set("@Fuente", fuente);
        }

        // Hook de diagnóstico para SqlDataSource
        protected void SqlDataSource_Selecting(object sender, System.Web.UI.WebControls.SqlDataSourceSelectingEventArgs e)
        {
            try
            {
                e.Command.CommandTimeout = 15; // defensa ante bloqueos
                // Log de parámetros
                var src = sender as System.Web.UI.WebControls.SqlDataSource;
                var name = src != null ? src.ID : "SqlDataSource";
                var sb = new System.Text.StringBuilder();
                sb.Append(name).Append(" Selecting → ");
                try { sb.Append(e.Command.CommandText); } catch { }
                sb.Append(" | Params: ");
                for (int i = 0; i < e.Command.Parameters.Count; i++)
                {
                    var p = e.Command.Parameters[i];
                    sb.Append(p.ParameterName).Append("=").Append(p.Value == null ? "<null>" : p.Value.ToString()).Append("; ");
                }
                MsCargaHoras.App_Start.Logger.Info(sb.ToString());
            }
            catch { }
        }
        protected void SqlDataSource_Selected(object sender, System.Web.UI.WebControls.SqlDataSourceStatusEventArgs e)
        {
            try
            {
                if (e.Exception != null)
                {
                    TryToastError("Error consultando datos: " + e.Exception.Message);
                    e.ExceptionHandled = true;
                }
                var src = sender as System.Web.UI.WebControls.SqlDataSource;
                var name = src != null ? src.ID : "SqlDataSource";
                MsCargaHoras.App_Start.Logger.Info($"{name} Selected → AffectedRows={e.AffectedRows}");
            }
            catch { }
        }

        // Eventos TRAC (opcionalmente para enlazar HyperLink Título y ticket seleccionado)
        protected void grdTrac_RowDataBound(object sender, System.Web.UI.WebControls.GridViewRowEventArgs e)
        {
            if (e.Row.RowType == System.Web.UI.WebControls.DataControlRowType.DataRow)
            {
                var link = e.Row.FindControl("lnkTracTitulo") as System.Web.UI.WebControls.HyperLink;
                var data = e.Row.DataItem as System.Data.DataRowView;
                if (link != null && data != null)
                {
                    // El campo Titulo ya incluye "#ID | resumen"; extraemos ID para el link
                    var titulo = Convert.ToString(data["Titulo"]);
                    var digits = new string((titulo ?? string.Empty).Where(char.IsDigit).ToArray());
                    if (!string.IsNullOrEmpty(digits))
                    {
                        link.NavigateUrl = "https://ticket.mastersoft.com.ar/trac/incidentes/ticket/" + digits;
                    }
                }
            }
        }

        protected void grdTrac_SelectedIndexChanged(object sender, EventArgs e)
        {
            if (grdTrac.SelectedRow == null) return;
            var texto = grdTrac.SelectedRow.Cells[1].Text; // debería coincidir con la columna Título
            var digits = new string((texto ?? string.Empty).Where(char.IsDigit).ToArray());
            hidTracSelTicketId.Value = digits;
        }

        // ------------ Modelo en memoria para la solapa Carga de Horas -------------
        private class HoraEditable
        {
            public int Id { get; set; }
            public string Cliente { get; set; }
            public string Proyecto { get; set; }
            public string Actividad { get; set; }
            public string Tarea { get; set; }
            public string Desde { get; set; } // HH:mm
            public string Hasta { get; set; } // HH:mm
            public decimal Horas { get; set; } // si no se completa Desde/Hasta
            public bool Fuera { get; set; }
            public string TipoDoc { get; set; }
            public string NroDoc { get; set; }
            public string Observaciones { get; set; }
        }

        private void InicializarHoras()
        {
            if (Session[SesionHorasKey] == null)
            {
                var lista = new List<HoraEditable>
                {
                    new HoraEditable { Id = 1, Cliente = "", Proyecto = "", Actividad = "", Tarea = "", Desde = "08:00", Hasta = "12:00", Horas = 4, Fuera = false, TipoDoc = "", NroDoc = "", Observaciones = "" }
                };
                Session[SesionHorasKey] = lista;
            }
        }

        private List<HoraEditable> ObtenerHoras()
        {
            InicializarHoras();
            return (List<HoraEditable>)Session[SesionHorasKey];
        }

        private void RebindHoras()
        {
            grdHoras.DataSource = ObtenerHoras();
            grdHoras.DataBind();
        }

        protected void Celda_TextChanged(object sender, EventArgs e)
        {
            // Cuando se edita una celda, tomamos la fila seleccionada para mapear cambios
            if (grdHoras.SelectedIndex < 0) return;
            var fila = ObtenerHoras().ElementAt(grdHoras.SelectedIndex);

            // Recorremos los controles de la fila para mapear valores
            var row = grdHoras.Rows[grdHoras.SelectedIndex];
            string Texto(string controlId)
            {
                var ctrl = row.FindControl(controlId) as System.Web.UI.WebControls.TextBox;
                return ctrl?.Text ?? string.Empty;
            }

            fila.Cliente = Texto("txtCliente");
            fila.Proyecto = Texto("txtProyecto");
            fila.Actividad = Texto("txtActividad");
            fila.Tarea = Texto("txtTarea");
            fila.Desde = Texto("txtDesde");
            fila.Hasta = Texto("txtHasta");
            fila.Observaciones = Texto("txtObs");

            // Horas: si viene vacía, intentamos calcular
            var horasTxt = Texto("txtHoras");
            if (decimal.TryParse(horasTxt, NumberStyles.Number, CultureInfo.InvariantCulture, out var horas))
            {
                fila.Horas = horas;
            }
            else
            {
                fila.Horas = CalcularHoras(fila.Desde, fila.Hasta);
            }

            RebindHoras();
            RecalcularTotales();
        }

        protected void chkFuera_CheckedChanged(object sender, EventArgs e)
        {
            if (grdHoras.SelectedIndex < 0) return;
            var row = grdHoras.Rows[grdHoras.SelectedIndex];
            var chk = row.FindControl("chkFuera") as System.Web.UI.WebControls.CheckBox;
            var fila = ObtenerHoras().ElementAt(grdHoras.SelectedIndex);
            fila.Fuera = chk != null && chk.Checked;
            RebindHoras();
            RecalcularTotales();
        }

        protected void grdHoras_RowDataBound(object sender, System.Web.UI.WebControls.GridViewRowEventArgs e)
        {
            // Toggle de campos de comprobantes según Fuera
            if (e.Row.RowType == System.Web.UI.WebControls.DataControlRowType.DataRow)
            {
                var chk = e.Row.FindControl("chkFuera") as System.Web.UI.WebControls.CheckBox;
                bool fuera = chk != null && chk.Checked;

                var tipo = e.Row.FindControl("txtTipoDoc");
                var nro = e.Row.FindControl("txtNroDoc");
                if (tipo != null) tipo.Visible = fuera;
                if (nro != null) nro.Visible = fuera;
            }
        }

        protected void grdHoras_SelectedIndexChanged(object sender, EventArgs e)
        {
            // Persistir índice seleccionado para que JS pueda leer el Nro Doc por defecto
            hidSelHoraIdx.Value = grdHoras.SelectedIndex.ToString();
        }

        private static decimal CalcularHoras(string desde, string hasta)
        {
            if (TimeSpan.TryParse(desde, out var tDesde) && TimeSpan.TryParse(hasta, out var tHasta))
            {
                if (tHasta < tDesde) return 0m;
                return (decimal)(tHasta - tDesde).TotalHours;
            }
            return 0m;
        }

        private void RecalcularTotales()
        {
            var horas = ObtenerHoras();
            decimal dentro = horas.Where(h => !h.Fuera).Sum(h => h.Horas);
            decimal fuera = horas.Where(h => h.Fuera).Sum(h => h.Horas);
            decimal totalGeneral = dentro + fuera;

            string F(decimal val) => TimeSpan.FromHours((double)val).ToString(@"hh\:mm");

            lblTotDentro.Text = F(dentro);
            lblTotFuera.Text = F(fuera);
            lblTotGeneral.Text = F(totalGeneral);
        }

        protected void btnGuardar_Click(object sender, EventArgs e)
        {
            // Modo solo consulta: no persiste en base
            // Deja visible un mensaje simple o recalcula totales
            RecalcularTotales();
        }

        private static int ParseEntero(string valor)
        {
            // La UI actual guarda descripciones; mientras no tengamos combos de IDs,
            // devolvemos 0 para que el SP falle solo si es requerido estrictamente.
            if (int.TryParse(valor, out var id)) return id;
            return 0;
        }

        protected void btnDescartar_Click(object sender, EventArgs e)
        {
            // Restablece el modelo en memoria a su estado inicial
            Session.Remove(SesionHorasKey);
            InicializarHoras();
            RebindHoras();
            RecalcularTotales();
        }

        protected void btnInsertar_Click(object sender, EventArgs e)
        {
            var horas = ObtenerHoras();
            int nuevoId = horas.Count == 0 ? 1 : horas.Max(h => h.Id) + 1;
            horas.Add(new HoraEditable
            {
                Id = nuevoId,
                Desde = "08:00",
                Hasta = "12:00",
                Horas = 4m
            });
            RebindHoras();
            grdHoras.SelectedIndex = horas.Count - 1;
            RecalcularTotales();
        }

        protected void btnEliminar_Click(object sender, EventArgs e)
        {
            if (grdHoras.SelectedIndex < 0) return;
            var horas = ObtenerHoras();
            horas.RemoveAt(grdHoras.SelectedIndex);
            RebindHoras();
            grdHoras.SelectedIndex = horas.Count - 1;
            RecalcularTotales();
        }

        protected void btnDuplicar_Click(object sender, EventArgs e)
        {
            if (grdHoras.SelectedIndex < 0) return;
            var horas = ObtenerHoras();
            var src = horas[grdHoras.SelectedIndex];
            int nuevoId = horas.Max(h => h.Id) + 1;
            horas.Add(new HoraEditable
            {
                Id = nuevoId,
                Cliente = src.Cliente,
                Proyecto = src.Proyecto,
                Actividad = src.Actividad,
                Tarea = src.Tarea,
                Desde = src.Desde,
                Hasta = src.Hasta,
                Horas = src.Horas,
                Fuera = src.Fuera,
                TipoDoc = src.TipoDoc,
                NroDoc = src.NroDoc,
                Observaciones = src.Observaciones
            });
            RebindHoras();
            grdHoras.SelectedIndex = horas.Count - 1;
            RecalcularTotales();
        }
    }
}