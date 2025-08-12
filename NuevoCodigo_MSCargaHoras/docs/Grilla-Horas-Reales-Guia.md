## Guía funcional – Grilla “Horas Reales”

### Objetivo
Implementar una grilla editable moderna, sin jQuery, que soporte edición inline, navegación por teclado, pegado masivo, estados por fila y alto rendimiento.

### Requisitos funcionales
- Edición inline de celdas con validaciones inmediatas.
- Soporte de teclado (moverse entre celdas, confirmar/cancelar ediciones).
- Pegado desde planilla (column mapping claro y seguro).
- Paginación/virtualización para grandes volúmenes.
- Estados por fila: Nueva (N), Modificada (M), Eliminada (E pendiente) y Error en celdas.
- Operaciones rápidas: duplicar fila, borrar/descartar cambios, autoguardado.
- Indicadores de conflicto: solapes de horario y avisos discretos.

### Columnas (propuesta)
- Estado (N/M/E)
- Cliente (Id/Descripción)
- Proyecto (Id/Descripción)
- Actividad (Id/Descripción)
- Tipo de Tarea (Id/Descripción)
- Desde (fecha/hora)
- Hasta (fecha/hora)
- Horas (decimal)
- Fuera (sí/no)
- TipoDoc (Id/Descripción) y NroDoc (texto)
- Observaciones (texto)

### Comportamiento esperado
- Validación al salir de celda; feedback visible y accesible.
- Reglas de negocio: solapes, horas mín./máx., campos requeridos, coherencia Cliente→Proyecto→Actividad.
- Estados visuales por fila coherentes con tokens (ver documento de tokens).
- Conteo de cambios con badge y botones Guardar/Descartar visibles.
- Tooltips de ayuda con atajos de teclado.

### Interacciones clave
- Teclado: mover, editar, confirmar (enter), cancelar (esc), seleccionar rango (shift).
- Pegado: detección de columnas compatibles y confirmación previa.
- Duplicado: agrega una fila copiando valores editables, actualizando estado a N.
- Eliminación: marca E pendiente con estilo visual y posibilidad de revertir.
- Autoguardado: confirma discretamente con un toast; errores mantienen foco y detalle.

### Accesibilidad
- Roles ARIA apropiados para tabla editable.
- Orden de tabulación lógico, foco visible y alto contraste.
- Mensajes de error y toasts anunciables a lectores de pantalla.

### Integración
- Incluir la grilla únicamente dentro de la solapa “Horas Reales”.
- Mantener dependencias encapsuladas y no introducir jQuery.
- Orquestar guardado/validación con la capa existente del backend.
- [Hecho] Estructura base y estilos; carga de dependencias en solapa.
- [Pendiente] Editores (selects/timepicker), validaciones, solapes y toasts.

### Pruebas
- Volumen alto con virtualización.
- Casos de bordes: solapes, horas inválidas, campos obligatorios.
- Flujo de pegado desde planilla y recuperación ante errores.
- Navegación solo teclado y lector de pantalla básico.



### Relación con accesos TRAC
- Los accesos Ver ticket, Nuevo Ticket y **Últimos Commits SVN** abren nuevas pestañas y no generan postback.
- “Últimos Commits SVN” filtra el timeline de TRAC por autor (usuario del legajo), fecha actual y 15 días hacia atrás.

### Horas Faltantes (pestaña Resumen)
- Origen de datos: `AGLTRAC_BuscarHsPendientesDeCarga(@Filtro)`.
- En la grilla se ocultan las columnas `Legajo` y `Apellido y Nombre`; el filtro sigue funcionando con esos datos internamente.
- Al pulsar Ver ticket, el sistema resuelve el número en este orden: (1) ticket seleccionado en la pestaña TRAC, (2) valor del campo de consulta junto a los botones, (3) Nro Doc. de la fila seleccionada en la grilla. Si no puede determinarse, se solicita al usuario.
