using System;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Web;
using System.Web.Caching;

namespace MsCargaHoras.Data
{
    public sealed class TareasNetMsRepository
    {
        private static DataTable GetOrAdd(string cacheKey, TimeSpan absoluteTtl, Func<DataTable> factory)
        {
            try
            {
                var cache = HttpRuntime.Cache;
                var cached = cache[cacheKey] as DataTable;
                if (cached != null) return cached;
                var created = factory();
                var toCache = created == null ? null : created.Copy();
                cache.Insert(cacheKey, toCache, null, DateTime.UtcNow.Add(absoluteTtl), Cache.NoSlidingExpiration, CacheItemPriority.Default, null);
                return created;
            }
            catch
            {
                return factory();
            }
        }
        private static string GetConnectionString()
        {
            var cs = ConfigurationManager.ConnectionStrings["TareasNetMsConnectionString"];
            if (cs == null || string.IsNullOrWhiteSpace(cs.ConnectionString))
            {
                throw new InvalidOperationException("No se encontró la cadena de conexión 'TareasNetMsConnectionString' en Web.config");
            }
            return cs.ConnectionString;
        }

        private static SqlConnection CreateConnection()
        {
            return new SqlConnection(GetConnectionString());
        }

        private static void ApplyCommandDefaults(SqlCommand cmd)
        {
            // Evita bloqueos largos; 15s es razonable para UI
            cmd.CommandTimeout = 15;
        }

        private static void EnsureTenant(SqlConnection cn)
        {
            string tenant = ConfigurationManager.AppSettings["TareasNetMs.Tenant"] ?? "MS";
            using (var cmd = new SqlCommand("SetearTenant", cn))
            {
                cmd.CommandType = CommandType.StoredProcedure;
                cmd.Parameters.AddWithValue("@Key", "@TenantId");
                cmd.Parameters.AddWithValue("@Value", tenant);
                cmd.ExecuteNonQuery();
            }
        }

        public DataTable HorasDet_Obtener(int nroLegajo, DateTime fecha)
        {
            using (var cn = CreateConnection())
            using (var cmd = new SqlCommand("HorasDet_Obtener", cn))
            {
                cmd.CommandType = CommandType.StoredProcedure;
                ApplyCommandDefaults(cmd);
                cmd.Parameters.AddWithValue("@NroLegajo", nroLegajo);
                cmd.Parameters.AddWithValue("@Fecha", fecha);
                cn.Open();
                EnsureTenant(cn);
                using (var da = new SqlDataAdapter(cmd))
                {
                    var dt = new DataTable();
                    da.Fill(dt);
                    return dt;
                }
            }
        }

        public DataTable AGLTRAC_HorasDet_Obtener(int nroLegajo, DateTime fecha)
        {
            using (var cn = CreateConnection())
            using (var cmd = new SqlCommand("AGLTRAC_HorasDet_Obtener", cn))
            {
                cmd.CommandType = CommandType.StoredProcedure;
                ApplyCommandDefaults(cmd);
                cmd.Parameters.AddWithValue("@NroLegajo", nroLegajo);
                cmd.Parameters.AddWithValue("@Fecha", fecha);
                cn.Open();
                EnsureTenant(cn);
                using (var da = new SqlDataAdapter(cmd))
                {
                    var dt = new DataTable();
                    da.Fill(dt);
                    return dt;
                }
            }
        }

        public DataTable AGLTRAC_HorasDet_Obtener(string filtro, DateTime fecha)
        {
            using (var cn = CreateConnection())
            using (var cmd = new SqlCommand("AGLTRAC_HorasDet_Obtener", cn))
            {
                cmd.CommandType = CommandType.StoredProcedure;
                ApplyCommandDefaults(cmd);
                cmd.Parameters.AddWithValue("@Filtro", string.IsNullOrWhiteSpace(filtro) ? (object)DBNull.Value : filtro);
                cmd.Parameters.AddWithValue("@Fecha", fecha);
                cmd.Parameters.AddWithValue("@SoloActivos", true);
                cn.Open();
                EnsureTenant(cn);
                using (var da = new SqlDataAdapter(cmd))
                {
                    var dt = new DataTable();
                    da.Fill(dt);
                    return dt;
                }
            }
        }

        public DataTable HorasEnc_Obtener(int nroLegajo, DateTime fecha)
        {
            using (var cn = CreateConnection())
            using (var cmd = new SqlCommand("HorasEnc_Obtener", cn))
            {
                cmd.CommandType = CommandType.StoredProcedure;
                ApplyCommandDefaults(cmd);
                cmd.Parameters.AddWithValue("@NroLegajo", nroLegajo);
                cmd.Parameters.AddWithValue("@Fecha", fecha);
                cn.Open();
                EnsureTenant(cn);
                using (var da = new SqlDataAdapter(cmd))
                {
                    var dt = new DataTable();
                    da.Fill(dt);
                    return dt;
                }
            }
        }

        public DataTable Derechos_Buscar_DetalleProyecto(int nroLegajo, DateTime fecha, int proyectoId)
        {
            using (var cn = CreateConnection())
            using (var cmd = new SqlCommand("Derechos_Buscar_DetalleProyecto", cn))
            {
                cmd.CommandType = CommandType.StoredProcedure;
                ApplyCommandDefaults(cmd);
                cmd.Parameters.AddWithValue("@NroLegajo", nroLegajo);
                cmd.Parameters.AddWithValue("@Fecha", fecha);
                cmd.Parameters.AddWithValue("@ProyectoID", proyectoId);
                cn.Open();
                EnsureTenant(cn);
                using (var da = new SqlDataAdapter(cmd))
                {
                    var dt = new DataTable();
                    da.Fill(dt);
                    return dt;
                }
            }
        }

        public DataTable Derechos_Buscar_ClientesProyectos(int nroLegajo, DateTime fecha, int? clienteId, int? proyectoId)
        {
            using (var cn = CreateConnection())
            using (var cmd = new SqlCommand("Derechos_Buscar_ClientesProyectos", cn))
            {
                cmd.CommandType = CommandType.StoredProcedure;
                ApplyCommandDefaults(cmd);
                cmd.Parameters.AddWithValue("@NroLegajo", nroLegajo);
                cmd.Parameters.AddWithValue("@Fecha", fecha);
                cmd.Parameters.AddWithValue("@ClienteID", clienteId.HasValue ? (object)clienteId.Value : DBNull.Value);
                cmd.Parameters.AddWithValue("@ProyectoID", proyectoId.HasValue ? (object)proyectoId.Value : DBNull.Value);
                cn.Open();
                EnsureTenant(cn);
                using (var da = new SqlDataAdapter(cmd))
                {
                    var dt = new DataTable();
                    da.Fill(dt);
                    return dt;
                }
            }
        }

        public DataTable Derechos_Buscar_ClientesProyectos_Cached(int nroLegajo, DateTime fecha, int? clienteId, int? proyectoId)
        {
            string key = $"TNM:CliProy:{nroLegajo}:{fecha:yyyyMMdd}:{(clienteId.HasValue ? clienteId.Value.ToString() : "-")}:{(proyectoId.HasValue ? proyectoId.Value.ToString() : "-")}";
            return GetOrAdd(key, TimeSpan.FromMinutes(5), () => Derechos_Buscar_ClientesProyectos(nroLegajo, fecha, clienteId, proyectoId));
        }

        public DataTable TiposDoc_Combo()
        {
            using (var cn = CreateConnection())
            using (var cmd = new SqlCommand("TiposDoc_Combo", cn))
            {
                cmd.CommandType = CommandType.StoredProcedure;
                ApplyCommandDefaults(cmd);
                cn.Open();
                EnsureTenant(cn);
                using (var da = new SqlDataAdapter(cmd))
                {
                    var dt = new DataTable();
                    da.Fill(dt);
                    return dt;
                }
            }
        }

        public DataTable TiposDoc_Combo_Cached()
        {
            return GetOrAdd("TNM:TiposDoc_Combo", TimeSpan.FromMinutes(10), TiposDoc_Combo);
        }

        public DataTable TipoTarea_Combo()
        {
            using (var cn = CreateConnection())
            using (var cmd = new SqlCommand("TipoTarea_Combo", cn))
            {
                cmd.CommandType = CommandType.StoredProcedure;
                ApplyCommandDefaults(cmd);
                cn.Open();
                EnsureTenant(cn);
                using (var da = new SqlDataAdapter(cmd))
                {
                    var dt = new DataTable();
                    da.Fill(dt);
                    return dt;
                }
            }
        }

        public DataTable TipoTarea_Combo_Cached()
        {
            return GetOrAdd("TNM:TipoTarea_Combo", TimeSpan.FromMinutes(10), TipoTarea_Combo);
        }

        public void HorasEnc_Modificar(int nroLegajo, DateTime fecha, string observaciones)
        {
            using (var cn = CreateConnection())
            using (var cmd = new SqlCommand("HorasEnc_Modificar", cn))
            {
                cmd.CommandType = CommandType.StoredProcedure;
                ApplyCommandDefaults(cmd);
                cmd.Parameters.AddWithValue("@NroLegajo", nroLegajo);
                cmd.Parameters.AddWithValue("@Fecha", fecha);
                cmd.Parameters.AddWithValue("@Observaciones", observaciones ?? string.Empty);
                cn.Open();
                EnsureTenant(cn);
                cmd.ExecuteNonQuery();
            }
        }

        public void HorasDet_Modificar(
            int nroLegajo,
            DateTime fecha,
            int item,
            int clienteId,
            int proyectoId,
            int? actividadId,
            int tipoTareaId,
            string horaDesde,
            string horaHasta,
            double horas,
            int? tipoDocId,
            int? nroDocId,
            string descripTarea,
            bool noFacturar,
            int? sucOrdenFact,
            int? nroOrdenFact,
            int? idRegistroDbf,
            int? reimputado,
            int? revision,
            int alarma,
            string autoriza,
            bool fuera)
        {
            using (var cn = CreateConnection())
            using (var cmd = new SqlCommand("HorasDet_Modificar", cn))
            {
                cmd.CommandType = CommandType.StoredProcedure;
                ApplyCommandDefaults(cmd);
                cmd.Parameters.AddWithValue("@NroLegajo", nroLegajo);
                cmd.Parameters.AddWithValue("@Fecha", fecha);
                cmd.Parameters.AddWithValue("@Item", item);
                cmd.Parameters.AddWithValue("@ClienteId", clienteId);
                cmd.Parameters.AddWithValue("@ProyectoId", proyectoId);
            cmd.Parameters.AddWithValue("@ActividadId", actividadId.HasValue ? (object)actividadId.Value : DBNull.Value);
                cmd.Parameters.AddWithValue("@TipoTareaId", tipoTareaId);
            cmd.Parameters.AddWithValue("@HoraDesde", string.IsNullOrEmpty(horaDesde) ? (object)DBNull.Value : horaDesde);
            cmd.Parameters.AddWithValue("@HoraHasta", string.IsNullOrEmpty(horaHasta) ? (object)DBNull.Value : horaHasta);
                cmd.Parameters.AddWithValue("@Horas", horas);
            cmd.Parameters.AddWithValue("@TipoDocId", tipoDocId.HasValue ? (object)tipoDocId.Value : DBNull.Value);
            cmd.Parameters.AddWithValue("@NroDocId", nroDocId.HasValue ? (object)nroDocId.Value : DBNull.Value);
            cmd.Parameters.AddWithValue("@DescripTarea", descripTarea == null ? (object)DBNull.Value : descripTarea);
                cmd.Parameters.AddWithValue("@NoFacturar", noFacturar);
            cmd.Parameters.AddWithValue("@SucOrdenFact", sucOrdenFact.HasValue ? (object)sucOrdenFact.Value : DBNull.Value);
            cmd.Parameters.AddWithValue("@NroOrdenFact", nroOrdenFact.HasValue ? (object)nroOrdenFact.Value : DBNull.Value);
            cmd.Parameters.AddWithValue("@IdRegistroDBF", idRegistroDbf.HasValue ? (object)idRegistroDbf.Value : DBNull.Value);
            cmd.Parameters.AddWithValue("@Reimputado", reimputado.HasValue ? (object)reimputado.Value : DBNull.Value);
            cmd.Parameters.AddWithValue("@Revision", revision.HasValue ? (object)revision.Value : DBNull.Value);
                cmd.Parameters.AddWithValue("@Alarma", alarma);
            cmd.Parameters.AddWithValue("@Autoriza", string.IsNullOrEmpty(autoriza) ? (object)DBNull.Value : autoriza);
                cmd.Parameters.AddWithValue("@Fuera", fuera);
                cn.Open();
                EnsureTenant(cn);
                cmd.ExecuteNonQuery();
            }
        }
    }
}


