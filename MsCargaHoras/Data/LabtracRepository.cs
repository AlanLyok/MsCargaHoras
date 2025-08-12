using System;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;

namespace MsCargaHoras.Data
{
    public sealed class LabtracRepository
    {
        private static void ApplyCommandDefaults(SqlCommand cmd)
        {
            // Evitar bloqueos largos en UI
            cmd.CommandTimeout = 15;
        }
        private static string GetConnectionString()
        {
            var cs = ConfigurationManager.ConnectionStrings["LABTRACConnectionString"];
            if (cs == null || string.IsNullOrWhiteSpace(cs.ConnectionString))
            {
                throw new InvalidOperationException("No se encontró la cadena de conexión 'LABTRACConnectionString' en Web.config");
            }
            return cs.ConnectionString;
        }

        private static SqlConnection CreateConnection()
        {
            return new SqlConnection(GetConnectionString());
        }

        public DataTable AGLTRAC_ObtenerLegajosUsuarios(string filtro, bool soloActivos)
        {
            using (var cn = CreateConnection())
            using (var cmd = new SqlCommand("AGLTRAC_ObtenerLegajosUsuarios", cn))
            {
                cmd.CommandType = CommandType.StoredProcedure;
                ApplyCommandDefaults(cmd);
                cmd.Parameters.AddWithValue("@Filtro", filtro == null ? (object)DBNull.Value : filtro);
                cmd.Parameters.AddWithValue("@SoloActivos", soloActivos);
                using (var da = new SqlDataAdapter(cmd))
                {
                    var dt = new DataTable();
                    da.Fill(dt);
                    return dt;
                }
            }
        }
    }
}


