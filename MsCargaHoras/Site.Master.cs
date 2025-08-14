using System;
using System.Web;
using System.Web.UI;
using MsCargaHoras.App_Start;

namespace MsCargaHoras
{
    public partial class SiteMaster : MasterPage
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            try
            {
                ApplyUserFromSession();
            }
            catch { }
        }

        // Flujo de aplicar desde navbar eliminado; el filtro se aplica desde la página
        private void ApplyUserFromSession()
        {
            var context = HttpContext.Current;
            var user = context?.Session?["CURRENT_USER"] as CurrentUser;
            if (user == null)
            {
                // 1) Preferir valor guardado en sesión como string simple
                var login = Convert.ToString(context?.Session?["LOGIN_USER"]) ?? string.Empty;
                // 2) Fallback: valor resuelto por el módulo SimpleAuthModule desde cookie
                if (string.IsNullOrWhiteSpace(login))
                {
                    try { login = Convert.ToString(context?.Items["LOGIN_USER"]) ?? string.Empty; } catch { }
                }
                // 3) Último recurso: intentar desencriptar cookie
                if (string.IsNullOrWhiteSpace(login))
                {
                    try
                    {
                        var ck = context?.Request?.Cookies["ms_login"];
                        var raw = ck != null ? context.Server.UrlDecode(ck.Value) : null;
                        login = TryUnprotect(raw) ?? raw;
                    }
                    catch { }
                }
                if (!string.IsNullOrWhiteSpace(login))
                {
                    user = new CurrentUser
                    {
                        Nombre = login,
                        Usuario = login,
                        Legajo = ExtractDigits(login),
                        Email = string.Empty
                    };
                }
            }
            if (user == null) return;

            if (lblNavbarNombre != null) lblNavbarNombre.Text = string.IsNullOrWhiteSpace(user.Nombre) ? "-" : user.Nombre;
            if (lblNavbarLegajo != null) lblNavbarLegajo.Text = string.IsNullOrWhiteSpace(user.Legajo) ? "-" : user.Legajo;
            if (lblUserNombre != null) lblUserNombre.Text = user.Nombre ?? string.Empty;
            if (lblUserLegajo != null) lblUserLegajo.Text = string.IsNullOrWhiteSpace(user.Legajo) ? "-" : user.Legajo;
            if (lblUserUsuario != null) lblUserUsuario.Text = user.Usuario ?? string.Empty;
            if (lblUserMail != null) lblUserMail.Text = user.Email ?? string.Empty;
        }

        private static string ExtractDigits(string text)
        {
            if (string.IsNullOrWhiteSpace(text)) return string.Empty;
            var arr = text.ToCharArray();
            System.Text.StringBuilder sb = new System.Text.StringBuilder(arr.Length);
            for (int i = 0; i < arr.Length; i++)
            {
                if (char.IsDigit(arr[i])) sb.Append(arr[i]);
            }
            return sb.ToString();
        }

        private static string TryUnprotect(string protectedValue)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(protectedValue)) return null;
                var urlDecoded = System.Web.HttpUtility.UrlDecode(protectedValue);
                var data = Convert.FromBase64String(urlDecoded);
                var plain = System.Web.Security.MachineKey.Unprotect(data, "ms_login_v1");
                return plain == null ? null : System.Text.Encoding.UTF8.GetString(plain);
            }
            catch { return null; }
        }
    }
}