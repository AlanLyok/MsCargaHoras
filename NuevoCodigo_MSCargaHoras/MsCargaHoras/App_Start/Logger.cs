using System;
using System.IO;
using System.Text;
using System.Web;

namespace MsCargaHoras.App_Start
{
    public static class Logger
    {
        private static readonly object Sync = new object();
        private static string GetLogPath()
        {
            try
            {
                var root = HttpContext.Current?.Server.MapPath("~") ?? AppDomain.CurrentDomain.BaseDirectory;
                var dir = Path.Combine(root, "App_Data", "logs");
                Directory.CreateDirectory(dir);
                return Path.Combine(dir, "app.log");
            }
            catch
            {
                return Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "app.log");
            }
        }

        public static void Info(string message) => Write("INFO", message);
        public static void Error(string message, Exception ex = null) => Write("ERROR", message + (ex == null ? string.Empty : (" | " + ex.Message)));
        public static void Debug(string message) => Write("DEBUG", message);

        private static void Write(string level, string message)
        {
            try
            {
                var line = $"{DateTime.UtcNow:O} [{level}] {message}";
                lock (Sync)
                {
                    File.AppendAllText(GetLogPath(), line + Environment.NewLine, Encoding.UTF8);
                }
            }
            catch { }
        }
    }
}


