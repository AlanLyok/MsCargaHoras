## Patrones UI unificados – MsCargaHoras

Este documento provee patrones listos para usar basados en Bootstrap 5 y `tokens.css` para mantener consistencia visual, soporte completo Light/Dark, accesibilidad y escalabilidad.

### Card + Tabla
Estructura estándar para listados/tablas dentro de una tarjeta.

```html
<div class="card shadow-sm">
  <div class="card-header h5 mb-0 d-flex justify-content-between align-items-center">
    <span>Título</span>
    <span class="badge bg-secondary-subtle text-secondary-emphasis">Meta</span>
  </div>
  <div class="card-body">
    <div class="table-responsive grid-scroll">
      <table class="table table-striped table-hover align-middle">
        <thead>
          <tr><th>Columna</th></tr>
        </thead>
        <tbody>
          <!-- filas -->
        </tbody>
      </table>
    </div>
  </div>
</div>
```

Buenas prácticas:
- Usar siempre `.table-responsive.grid-scroll` para alto máximo y scroll interno.
- Evitar `table-dark` en el header; el header ya hereda `--surface-2` por `app.css`.

### Botones
- Primarios: `.btn-primary` para acciones principales.
- Secundarios: `.btn-outline-primary`, `.btn-outline-secondary`.
- Suaves/ligeros: `.btn-soft-primary|secondary|success|info|warning|danger` (colores basados en `--bs-*-bg-subtle` y `--bs-*-text-emphasis`).
- Toolbars: usar `.btn-sm` y prefijar con icono `bi`.

Ejemplo:
```html
<button class="btn btn-primary btn-sm"><i class="bi bi-plus-circle"></i><span class="ms-1">Agregar</span></button>
<button class="btn btn-soft-secondary btn-sm"><i class="bi bi-search"></i><span class="ms-1">Buscar</span></button>
```

### Formularios
- Entradas: `form-control`, selects `form-select`, checks `form-check-input`.
- Placeholders y foco accesible heredan de tokens: `--form-*` y `--focus-ring-color`.

```html
<label class="form-label" for="inp">Campo</label>
<input id="inp" type="text" class="form-control" placeholder="Buscar..." />
```

### Tabs
Usar tabs Bootstrap; el color activo usa `--bs-nav-tabs-link-active-*`.

```html
<ul class="nav nav-tabs">
  <li class="nav-item"><button class="nav-link active" data-bs-toggle="tab" data-bs-target="#t1">Tab 1</button></li>
  <li class="nav-item"><button class="nav-link" data-bs-toggle="tab" data-bs-target="#t2">Tab 2</button></li>
</ul>
<div class="tab-content">
  <div id="t1" class="tab-pane fade show active">...</div>
  <div id="t2" class="tab-pane fade">...</div>
</div>
```

### Toasts, Dropdowns y Modales
- Colores controlados por tokens: `--toast-*`, `--dropdown-*`, `--modal-*`.
- Inicializar con Bootstrap. Tooltips están deshabilitados globalmente por ahora.

### Temas Light/Dark
- Se gestiona con `:root[data-theme='dark'|'light']` y media query `prefers-color-scheme` en `tokens.css`.
- No usar colores hardcodeados; usar utilidades Bootstrap o variables `--bs-*` derivadas de tokens.

### Utilidades
- Espaciado: escala `--sp-*` y utilidades `gap-*`, `p-*`, `m-*`.
- Avatar: `.avatar-circle` disponible para iniciales de usuario.

### Kanban (simple)
- Columnas como tarjetas con header y lista de tarjetas internas.
- Drag & Drop nativo en el navegador; persistencia de columna por tarjeta en `localStorage`.
 - Orden manual por columna: la posición se guarda por usuario y se reaplica en cada carga.

Estructura:
```html
<div class="kanban-board">
  <div class="kanban-col">
    <div class="kanban-col-header">Por hacer</div>
    <div class="kanban-list">
      <div class="kanban-card" draggable="true">
        <div class="title"><a href="#" target="_blank">#123 | Título</a></div>
        <div class="meta">
          <span class="badge bg-secondary-subtle text-secondary-emphasis">TRAC</span>
          <span>Cliente</span>
          <span>Proyecto</span>
          <span class="text-nowrap">01/01/2025 12:00</span>
        </div>
      </div>
    </div>
  </div>
</div>
```

Buenas prácticas:
- Usar badges sutiles para tipo/fuente.
- Limitar altura de columnas y permitir scroll interno.
- Respetar tokens para color en light/dark.

### Rendimiento y escalabilidad
- Todo el theming es por CSS variables, lo que evita recalcular muchas reglas entre temas.
- Reutilizar los patrones STL (card + tabla, toolbar de acciones) reduce CSS específico y JS personalizado.


