using System;
using System.Data;

namespace MsCargaHoras.Models
{
    public sealed class UserProfile
    {
        public string Nombre { get; set; }
        public string Legajo { get; set; }
        public string Usuario { get; set; }
        public string Email { get; set; }

        public static UserProfile FromInputs(string entrada, string numeroLegajo, string usuarioHeuristico)
        {
            return new UserProfile
            {
                Nombre = entrada ?? string.Empty,
                Legajo = string.IsNullOrWhiteSpace(numeroLegajo) ? "-" : numeroLegajo,
                Usuario = string.IsNullOrWhiteSpace(usuarioHeuristico) ? string.Empty : usuarioHeuristico,
                Email = string.Empty
            };
        }

        public static UserProfile FromLabtracRow(DataRow row, string entradaFallback, string legajoFallback, string usuarioHeuristico)
        {
            if (row == null) return FromInputs(entradaFallback, legajoFallback, usuarioHeuristico);
            string nombre = SafeGet(row, "ApeyNom");
            if (string.IsNullOrWhiteSpace(nombre)) nombre = SafeGet(row, "Nombre");
            if (string.IsNullOrWhiteSpace(nombre)) nombre = entradaFallback ?? string.Empty;

            string usuario = SafeGet(row, "Usuario");
            if (string.IsNullOrWhiteSpace(usuario)) usuario = usuarioHeuristico ?? string.Empty;

            string mail = SafeGet(row, "Email");
            if (string.IsNullOrWhiteSpace(mail)) mail = SafeGet(row, "Mail");

            return new UserProfile
            {
                Nombre = nombre,
                Legajo = string.IsNullOrWhiteSpace(legajoFallback) ? "-" : legajoFallback,
                Usuario = usuario,
                Email = mail ?? string.Empty
            };
        }

        private static string SafeGet(DataRow row, string column)
        {
            try
            {
                return row.Table.Columns.Contains(column) && row[column] != DBNull.Value
                    ? Convert.ToString(row[column])
                    : null;
            }
            catch { return null; }
        }
    }
}


