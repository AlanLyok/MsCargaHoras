using System;
using System.Text;
using System.Web;
using System.Web.Security;

namespace MsCargaHoras.App_Start
{
    // Módulo HTTP muy simple para restaurar el usuario desde cookie segura
    // y exponerlo vía HttpContext.Items["LOGIN_USER"]. Pensado para migrar luego a Forms/Identity.
    public class SimpleAuthModule : IHttpModule
    {
        private const string CookieName = "ms_login";

        public void Init(HttpApplication context)
        {
            context.BeginRequest += (s, e) =>
            {
                try
                {
                    var app = (HttpApplication)s;
                    var req = app.Context.Request;
                    var cookie = req.Cookies[CookieName];
                    string login = null;
                    if (cookie != null && !string.IsNullOrEmpty(cookie.Value))
                    {
                        // Intentar desencriptar/proteger con MachineKey.Unprotect (v1)
                        // Mantener compatibilidad hacia atrás con valor plano
                        login = TryUnprotect(cookie.Value) ?? HttpUtility.UrlDecode(cookie.Value);
                    }
                    if (!string.IsNullOrWhiteSpace(login))
                    {
                        app.Context.Items["LOGIN_USER"] = login;
                    }
                }
                catch { }
            };
        }

        public void Dispose() { }

        private static string TryUnprotect(string protectedValue)
        {
            try
            {
                // El valor pudo venir URL-encoded y en Base64
                var urlDecoded = HttpUtility.UrlDecode(protectedValue ?? string.Empty) ?? string.Empty;
                byte[] data = Convert.FromBase64String(urlDecoded);
                byte[] plain = MachineKey.Unprotect(data, "ms_login_v1");
                return plain == null ? null : Encoding.UTF8.GetString(plain);
            }
            catch
            {
                return null;
            }
        }
    }
}


