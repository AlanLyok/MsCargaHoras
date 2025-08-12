## Especificación de Tokens – Mini Design System

### Objetivo
Definir un set de tokens (variables) que habilite coherencia visual, theming y mantenimiento simple sin tocar múltiples archivos CSS.

### Tipografía
- Familia base sans: preferir una fuente moderna (por ejemplo Inter) y fallback a system.
- Escalas de tamaño y line-height consistentes con legibilidad.

### Espaciado (escala 8px)
- Niveles de espaciado con incrementos regulares para márgenes y paddings.
- Uso consistente en componentes, formularios y grillas.

### Colores de estado (alineados a la UX)
- Fila nueva (N): verde suave en fondo o acento lateral.
- Fila modificada (M): azul suave en fondo o acento lateral.
- Fila eliminada pendiente (E): texto gris, estilo tachado en celdas afectadas.
- Celda con error: fondo cálido suave y contorno visible.

### Theming (claro/oscuro)
- Definir tokens neutrales (texto, fondo, borde, surface) para modo claro.
- Alternar valores para modo oscuro respetando contraste mínimo AA.
- Preferencia del usuario: respetar ajustes del sistema y permitir override manual.

### Accesibilidad
- Colores con relación de contraste adecuada.
- Estados de foco visibles y consistentes.
- Transiciones suaves que no dificulten la lectura.

### Convenciones
- Prefijos por categoría (ej.: color-*, sp-*, font-*).
- Mantener documentación breve por token crítico (qué afecta y dónde se usa).

### Implementación
- [Hecho] Un único archivo de tokens (`Content/tokens.css`) con mapeo a variables de Bootstrap (`--bs-*`).
- [Hecho] Archivo de utilidades/overrides (`Content/app.css`) que consume tokens y aplica patrones (zebra, sticky, focus, toasts, theming Tabulator).
- [Pendiente] Definir tokens para badges de estado N/M/E e íconos, y documentar su uso en la grilla.


