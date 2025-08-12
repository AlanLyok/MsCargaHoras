# MsCargaHoras – README del sitio

Sitio interno de Carga de Horas basado en ASP.NET WebForms (.NET Framework 4.8). Este documento resume el estado funcional actual, cómo ejecutarlo localmente, la configuración necesaria y consideraciones operativas. Evita detalles de implementación y fragmentos de código.

## Descripción general
- **Tecnología**: ASP.NET WebForms con `Site.Master`, Bootstrap 5, postbacks parciales (`UpdatePanel`) y mejoras de UI reutilizables.
- **Datos**: SQL Server vía procedimientos almacenados en LABTRAC y TareasNetMs. Resolución de usuario/legajo desde LABTRAC. Linked server a TRAC para vistas relacionadas.
- **Sesión**: login simple por filtro (legajo, nombre, usuario o mail). La sesión se persiste en servidor y se refuerza con cookie `ms_login` protegida.
- **UI**: tabs principales (Resumen, Carga de Horas, Tareas Pendientes) y una vista auxiliar de Horas Sugeridas. Theming claro/oscuro, toasts, overlay de carga, toolbars fijas para acciones y búsqueda global.

## Funcionalidades actuales
- **Login y sesión**: ingreso por filtro; persistencia en `Session` y cookie protegida. Botones de Cambiar usuario/Log Out en la navbar.
- **Resumen (Horas Faltantes)**: consulta `AGLTRAC_BuscarHsPendientesDeCarga(@Filtro)`. Al seleccionar un día, sincroniza la fecha de Carga de Horas y muestra totales de días/horas.
- **Horas Sugeridas**: consulta `AGLTRAC_ObtenerHorasSugeridas` y muestra un TOP acotado. Paginación y orden disponibles.
- **Carga de Horas (modo consulta)**: lectura del detalle del día desde TareasNetMs con `AGLTRAC_HorasDet_Obtener`. Precarga de catálogos en sesión (Tipos de Doc., Tipos de Tarea, Clientes/Proyectos). Edición local provisional (sin persistencia en base aún).
- **Tareas Pendientes**: consulta `AGLTRAC_ObtenerTareasAsignadas` (fuentes TRAC/Actividades/Todas). Selección de ticket para accesos rápidos.
- **Accesos TRAC y actividades**: botones para ver ticket, crear ticket, consultar horas de ticket, consultar actividad y ver timelines por autor TRAC.
- **Mejoras de UI**: tarjetas con scroll interno, encabezados estandarizados, búsqueda global sincronizada y theming claro/oscuro persistente.

## Requisitos
- Windows con Visual Studio 2022 (workload de ASP.NET y web) o Build Tools 2022.
- Targeting Pack de .NET Framework 4.8.
- IIS Express instalado (o IIS local).
- Acceso a SQL Server con las bases LABTRAC y TareasNetMs; linked server hacia TRAC según ambiente.

## Configuración
- `LABTRACConnectionString`: acceso a LABTRAC.
- `TareasNetMsConnectionString`: acceso a TareasNetMs.
- `appSettings:TareasNetMs.Tenant`: identificador de tenant para SP de TareasNetMs (se establece antes de ejecutar SPs).
- Cookies seguras: `HttpOnly` y `SameSite`. Habilitar `Secure` bajo HTTPS. HSTS recomendado en Release.
- Transformaciones por ambiente en `MsCargaHoras/Web.[Ambiente].config` para cadenas de conexión y `appSettings`. Evitar credenciales en claro en `Web.config` base.

## Ejecución local
- Doble clic: `Start-MsCargaHoras.cmd` (compila, levanta IIS Express y abre el navegador; inicia una segunda ventana en modo vigilancia).
- PowerShell: `Start-MsCargaHoras.ps1` admite parámetros de configuración (por ejemplo, puerto, abrir navegador). Internamente utiliza `NuevoCodigo_MSCargaHoras/scripts/Build-Run-MsCargaHoras.ps1` para compilar, ejecutar y vigilar cambios con recompilación automática.
- Log de compilación: `NuevoCodigo_MSCargaHoras/scripts/msbuild-last.log` (si se configura). Útil para diagnóstico.

## Uso básico
- Abrir el sitio y escribir un filtro de empleado (legajo, nombre, usuario o mail). Pulsar Aplicar.
- En Resumen, seleccionar un día para sincronizar la fecha y ver Horas Sugeridas y el detalle del día en Carga de Horas.
- En Carga de Horas, revisar el detalle leído para la fecha actual. La edición es local y no persiste en base todavía.
- En Tareas Pendientes, seleccionar fuente (TRAC/Actividades/Todas) y usar los accesos rápidos a tickets/actividades.

## Stores utilizados (resumen)
- LABTRAC: `AGLTRAC_BuscarHsPendientesDeCarga`, `AGLTRAC_ObtenerTareasAsignadas`, `AGLTRAC_ObtenerLegajosUsuarios`.
- TareasNetMs: `AGLTRAC_HorasDet_Obtener` y catálogos (`TiposDoc_Combo`, `TipoTarea_Combo`, `Derechos_Buscar_ClientesProyectos`).
- TRAC: vía linked server para timelines y navegación a tickets.

## Seguridad y operación
- No commitear secretos ni credenciales en `Web.config`. Utilizar transformaciones por ambiente o variables de entorno seguras.
- Forzar HTTPS en entornos superiores y activar HSTS en Release.
- Si se escala a múltiples nodos, evaluar sesión out‑of‑proc y afinidad en el balanceador.
- Dependencias por CDN: revisar integridad (SRI) al publicar o servir localmente si se requiere aislamiento.

## Limitaciones y próximos pasos
- Persistencia de Carga de Horas: actualmente modo consulta. Pendiente completar guardado (encabezado/detalle) con validaciones y selectores basados en catálogos.
- “Horas Sugeridas”: consolidar dataset propio y reemplazar el TOP temporal cuando corresponda.
- Autenticación: hoy es simple por filtro; considerar integrar autenticación corporativa y derivación automática del legajo por usuario logueado.
- Accesibilidad: mantener foco visible y revisar contraste en tablas; profundizar en roles ARIA de grillas.

## Solución de problemas (breve)
- Instalar targeting pack de .NET 4.8 si la compilación falla por framework.
- Compilar desde línea de comandos con Build Tools 2022 si falta MSBuild.
- Reiniciar IIS Express si se cambió `Web.config` y no se reflejan cambios.
- Verificar linked server hacia TRAC y permisos en SQL si no aparecen tareas o timelines.

## Scripts incluidos
- `NuevoCodigo_MSCargaHoras/scripts/Build-Run-MsCargaHoras.ps1`: compila, levanta IIS Express y vigila cambios (recompilación automática). Soporta autocorrección limitada de errores comunes y log opcional.
- `Start-MsCargaHoras.ps1`: orquestador en la raíz del repo. Reutiliza la instancia de IIS en modo vigilancia.
- `Start-MsCargaHoras.cmd`: lanzador para Windows.

## Contacto y soporte
Para consultas internas sobre infraestructura, cadenas de conexión o linked servers, contactar al equipo de Desarrollo/Mastersoft.


