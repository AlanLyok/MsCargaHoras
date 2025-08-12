## Especificación UX – Solapa "Carga de Horas" (ASP.NET Web Forms)

### 1) Objetivo
- **Propósito**: permitir cargar, editar y eliminar horas reales de manera rápida y confiable, inspirada en la pantalla WinForms existente, con mejoras de productividad en la web.
- **Resultado esperado**: una tercera solapa llamada "Horas Reales" dentro de la página principal del sitio que hoy ya presenta solapas para consultas. La nueva solapa ofrece una grilla editable con validaciones en tiempo real, totales, y soporte de atajos de teclado.

### 2) Alcance
- **Incluye**: diseño de interfaz, flujo de usuario, reglas de validación, estados de fila, accesibilidad, métricas de éxito, y plan de implementación sin fragmentos de código.
- **No incluye**: cambios de modelo de datos o definiciones de base de datos más allá de los campos necesarios; detalles técnicos de componentes o frameworks específicos.

### 3) Principios de diseño
- **Velocidad primero**: minimizar clics y viajes de mouse. Todo debe operarse enteramente con teclado.
- **Edición en contexto**: edición inline en la misma fila, con un panel de detalles opcional sólo para campos extendidos.
- **Prevención de errores**: validaciones oportunas y mensajes claros; detección de solapamientos; totales por día visibles.
- **Estado siempre visible**: diferenciación de filas nuevas, modificadas y eliminadas; contador de cambios pendientes de guardar.
- **No perder trabajo**: borradores locales automáticos con recuperación tras recarga del navegador.

### 4) Layout general de la solapa
- **Encabezado**: filtros rápidos de fecha (día/semana/mes), empleado (legajo/nombre), y selector de vista (diaria/semanal).
- **Grilla editable**: ocupa el área principal. Filas con edición inline y selección por teclado. Altura elástica de fila para evitar scroll horizontal.
- **Panel inferior (plegable)**: detalle de la fila activa con campos menos usados; se expande con una tecla y recuerda su estado.
- **Pie**: totales por rango y partición "dentro de empresa" vs. "fuera de empresa"; botones Guardar y Descartar con indicador de cambios.

### 5) Definición de columnas y campos
- **Est.**: marca visual del estado de la fila (N = nueva, M = modificada, E = eliminada). Tooltip con detalle.
- **Cliente**: autocompletar con búsqueda por texto; permite pegar texto y resolver luego. Requiere selección válida.
- **Proyecto**: dependiente de Cliente; autocompletar con búsqueda. Requerido.
- **Actividad**: lista restringida (catálogo). Requerido.
- **Tarea**: opcional, dependiente de Proyecto/Actividad.
- **Desde / Hasta**: hora en formato 24h con pasos de 5 min y flechas de incremento. Validación de rango y orden.
- **Horas**: calculado a partir de Desde/Hasta; editable sólo cuando el esquema del proyecto permita cargar por cantidad directa. Redondeo configurable (15/30 min).
- **Fuera**: casilla para marcar fuera de la empresa.
- **Tipo Doc / Nro Doc**: visibles sólo si "Fuera" está marcado; permiten comprobantes.
- **Observaciones**: campo multilinea con recuento de caracteres.

### 6) Interacciones clave de la grilla
- **Insertar**: tecla Enter en la última fila agrega una nueva. Botón "Insertar línea" debajo como alternativa.
- **Duplicar**: atajo dedicado para clonar la fila activa al día actual o al siguiente. Cursor salta a "Desde".
- **Eliminar**: marca la fila como eliminada (soft delete) hasta guardar; atajo con confirmación liviana.
- **Edición inline**: F2 para editar celda, Escape para deshacer cambios en celda/fila, Ctrl+Z para deshacer global.
- **Pegar masivo**: soporta pegar desde planillas con columnas en el mismo orden; se valida fila por fila.
- **Autoguardado**: opcional, cada X minutos o al cambiar de día. Muestra confirmación discreta.
- **Detección de solapamientos**: alerta no bloqueante al editar horas; botón para resolver sugiriendo ajustar "Hasta" o "Desde".
- **Conflictos de concurrencia**: si otra sesión cambió la misma fila, ofrecer combinar o recargar sólo esa fila.

### 7) Validaciones y reglas de negocio
- **Campos requeridos**: Cliente, Proyecto, Actividad, Desde/Hasta (o Horas si corresponde).
- **Rangos**: "Desde" < "Hasta"; máximo 24h por día; límite configurable por política (ej. 12h).
- **Solapamientos**: por empleado, fecha y proyecto; permitir excepciones con justificación en Observaciones.
- **Redondeo**: configurable por proyecto; mostrar badge con el redondeo aplicado.
- **Totales**: recalcular al vuelo por día, semana y por "dentro/fora" de empresa.

### 8) Atajos de teclado propuestos
- Navegación: flechas, Tab/Shift+Tab, Inicio/Fin, PageUp/PageDown entre días.
- Operaciones: Enter (nueva línea), Ctrl+D (duplicar fila), Supr (marcar eliminar), Ctrl+S (guardar), Ctrl+Z/Y (deshacer/rehacer), F2 (editar), F4 (abrir panel inferior), Ctrl+F (buscar en grilla).

### 9) Accesibilidad
- Roles ARIA en pestañas y tabla editable; foco visible de alto contraste.
- Atajos anunciados en tooltips y en ayuda integrada.
- Controles con etiquetas asociadas y tamaño mínimo táctil.

### 10) Estados visuales
- **Nueva**: borde izquierdo verde suave.
- **Modificada**: borde azul.
- **Eliminada (pendiente)**: texto tachado en gris y se oculta por defecto con un filtro.
- **Error**: fondo amarillo claro en celdas con error y mensaje contextual.

### 11) Flujo de guardado
- Botón Guardar consolidará altas, modificaciones y bajas en un único envío.
- Indicador de progreso y resultado por fila. Si hay errores, mantener el resto confirmado.
- Registro de auditoría: quién y cuándo, con totales por lote guardado.

### 12) Rendimiento
- Carga inicial limitada al rango visible (día/semanal) con paginación virtual.
- Búsquedas cliente/proyecto con listas diferidas y cacheadas por sesión.
- Operaciones de grilla sin bloquear la UI; mensajes discretos en área de notificaciones.

### 13) Seguridad y privacidad
- Validar permisos por empleado y proyecto. No exponer datos que no corresponden al usuario autenticado.
- Evitar incluir datos sensibles en almacenamiento local; los borradores sólo guardan filas y campos no sensibles.

### 14) Telemetría de UX
- Métricas: tiempo medio de alta de una fila, número de teclas/clics por operación, tasa de errores por validación, abandonos con cambios sin guardar.
- Eventos: insertar, duplicar, eliminar, guardar, conflicto resuelto, pegado masivo.

### 15) Criterios de aceptación
- Se puede cargar una semana completa con sólo teclado, sin diálogos modales obligatorios.
- Las validaciones previenen solapamientos y errores de rango sin frenar el flujo.
- Duplicar y pegar masivo reducen el tiempo de carga en al menos un 40% respecto a la versión WinForms.
- La UI recuerda filtros y preferencia de vista por usuario.

### 16) Plan de implementación (alto nivel, sin código)
1. Agregar la solapa "Horas Reales" en la página principal del sitio, junto a las existentes.
2. Incluir una grilla editable compatible con selección por teclado y edición inline.
3. Incorporar el panel inferior plegable con campos extendidos, totales y botones de línea (insertar, eliminar, duplicar).
4. Implementar validaciones en cliente y servidor: requeridos, rangos, solapamientos y redondeo.
5. Habilitar pegado masivo y duplicación; agregar atajos de teclado globales.
6. Añadir borrador local y recuperación ante recarga.
7. Integrar telemetría de eventos y métricas.
8. Pruebas de usabilidad con 3 usuarios frecuentes y ajustes finos.

### 17) Riesgos y mitigaciones
- **Latencia al autocompletar**: cache por sesión y límites de resultados.
- **Pegados incorrectos**: asistente de validación previa y previsualización antes de confirmar.
- **Concurrencia**: control de versión por fila y resolución específica sin perder cambios ajenos.

### 18) Anexos – Mapeo con la pantalla WinForms
- Se respeta la estructura de columnas principal: Estado, Cliente, Proyecto, Actividad, Tarea, Desde, Hasta, Horas, Fuera, Observaciones.
- Los botones "Insertar Línea", "Eliminar Línea" y "Duplicar Línea" se ubican en el pie, y sus atajos aparecen en tooltip.
- Los totales por "dentro" y "fuera de empresa" permanecen visibles en el pie y se actualizan en vivo.


### 19) Integración con TRAC (accesos y pestaña de tickets)
- Se incorporan accesos directos desde la solapa de Carga de Horas para: Ver ticket, Nuevo Ticket y **Últimos Commits SVN**. Abren en nueva pestaña y no generan postback.
- Prioridad para resolver el número de ticket al pulsar un acceso: (1) ticket seleccionado en la pestaña TRAC, (2) valor del campo de consulta, (3) número de documento de la fila seleccionada en la grilla de horas. Si no hay número, se solicita al usuario.
- Nueva pestaña “Tickets TRAC” que lista tickets asignados al legajo usando un procedimiento de LABTRAC. El título de cada fila funciona como enlace al ticket en TRAC.

#### 19.1) Detalle de “Últimos Commits SVN”
- Construcción del link al timeline TRAC:
  - Fecha `from` = día actual en formato dd/MM/yyyy (URL-encoded).
  - `daysback=15`, `changeset=on`, `update=Actualizar`.
  - `authors` = usuario TRAC asociado al legajo (resuelto desde LABTRAC); fallback conservador si no se encuentra.

