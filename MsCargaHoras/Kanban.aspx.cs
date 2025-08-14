using System;
using System.Web.UI;

namespace MsCargaHoras
{
    public partial class Kanban : Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                try
                {
                    var login = Convert.ToString(Session["LOGIN_USER"]) ?? string.Empty;
                    if (!string.IsNullOrWhiteSpace(login))
                    {
                        // El usuario se toma del login; no editable aquí
                        hidUserKey.Value = login;
                    }
                    // Ajuste de toolbar offsets (navbar+toolbars)
                    try
                    {
                        var script = @"(function(){try{ var root=document.documentElement; var hNav=parseInt(getComputedStyle(root).getPropertyValue('--navbar-h'))||56; var hBar=parseInt(getComputedStyle(root).getPropertyValue('--toolbar-h'))||48; var search=document.getElementById('toolbarSearch'); var cont=document.querySelector('.body-content'); if(search){ search.style.top = (hNav) + 'px'; } if(cont){ cont.style.paddingTop = (hNav + (2*hBar)) + 'px'; } }catch(e){} })();";
                        ScriptManager.RegisterStartupScript(this, GetType(), Guid.NewGuid().ToString("N"), script, true);
                    }
                    catch { }
                }
                catch { }
            }
        }

        protected void btnAplicar_Click(object sender, EventArgs e)
        {
            try { rptItems.DataBind(); } catch { }
        }

        protected void dsKanban_Selecting(object sender, System.Web.UI.WebControls.SqlDataSourceSelectingEventArgs e)
        {
            var filtro = (hidUserKey.Value ?? string.Empty).Trim();
            if (string.IsNullOrWhiteSpace(filtro)) { e.Cancel = true; return; }

            var fuente = (ddlFuente.SelectedValue ?? "TODOS").ToUpperInvariant();
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

        protected void SqlDataSource_Selected(object sender, System.Web.UI.WebControls.SqlDataSourceStatusEventArgs e)
        {
            try
            {
                if (e.Exception != null)
                {
                    try { ScriptManager.RegisterStartupScript(this, GetType(), Guid.NewGuid().ToString("N"), "try{UiCommon.showToast('Error cargando tareas: " + System.Web.HttpUtility.JavaScriptStringEncode(e.Exception.Message) + "','danger');}catch(e){}", true); } catch { }
                    e.ExceptionHandled = true;
                }
                else
                {
                    try
                    {
                        // Toast de cantidad filas en grilla
                        ScriptManager.RegisterStartupScript(this, GetType(), Guid.NewGuid().ToString("N"), "try{var g=document.getElementById('" + grdTrac.ClientID + "'); var c=0; if(g){ var rows=g.getElementsByTagName('tr'); c=Math.max(0, rows.length-1);} UiCommon.showToast('Tareas: '+c+' filas.','info'); }catch(e){}", true);
                    }
                    catch { }
                }
            }
            catch { }
        }

        protected void grdTrac_DataBound(object sender, EventArgs e)
        {
            if (grdTrac.HeaderRow != null)
            {
                grdTrac.HeaderRow.TableSection = System.Web.UI.WebControls.TableRowSection.TableHeader;
            }
        }
    }
}


