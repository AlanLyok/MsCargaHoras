<%@ WebHandler Language="C#" Class="MsCargaHoras.Descargas.ProtocoloTareas" %>

using System;
using System.IO;
using System.Web;
// Quitar compresión dinámica para evitar dependencias de System.IO.Compression en tiempo de ejecución de IIS Express

namespace MsCargaHoras.Descargas
{
    public class ProtocoloTareas : IHttpHandler
    {
        public void ProcessRequest(HttpContext context)
        {
            // Sirve un ZIP ya preparado (o un .reg como último recurso) para registrar el protocolo tareas://
            try
            {
                Func<string, string> map = rel => context.Server.MapPath(rel);
                var preferredZip = map("~/App_Data/Registrar_TareasNet.zip");
                string fileToSend = null;
                if (File.Exists(preferredZip)) fileToSend = preferredZip;
                if (string.IsNullOrEmpty(fileToSend)) throw new FileNotFoundException("No se encontró InstaladorMsCargaHoras_TareasNet.zip en App_Data.");

                var bytes = File.ReadAllBytes(fileToSend);
                context.Response.Clear();
                var ext = Path.GetExtension(fileToSend).ToLowerInvariant();
                context.Response.ContentType = (ext == ".zip") ? "application/zip" : "application/octet-stream";
                context.Response.AddHeader("Content-Disposition", "attachment; filename=" + Path.GetFileName(fileToSend));
                context.Response.AddHeader("Content-Length", bytes.Length.ToString());
                context.Response.BinaryWrite(bytes);
                context.Response.Flush();
            }
            catch (Exception ex)
            {
                context.Response.StatusCode = 500;
                context.Response.ContentType = "text/plain";
                context.Response.Write("Error preparando descarga: " + ex.Message);
            }
        }

        public bool IsReusable { get { return false; } }
    }
}


