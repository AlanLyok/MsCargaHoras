## Inventario completo de UI – MsCargaHoras

Documento para inventariar todos los elementos de UI del sitio, agruparlos por tipo, y vincularlos con la paleta de tokens y los temas light/dark.

- Stack: ASP.NET WebForms + Bootstrap 5.3 + Bootstrap Icons + CSS tokens (`MsCargaHoras/Content/tokens.css`) + overrides (`MsCargaHoras/Content/app.css`).
- JS de UI: `MsCargaHoras/Scripts/ui-common.js` (helpers de botones, toasts, overlay, estandarización de grillas) y `MsCargaHoras/Scripts/grid-enhancer.js` (ordenamiento, filtros por columna, búsqueda global y badges de filtros para tablas).
- Temas: soporte de tema claro/oscuro por preferencia del SO y por toggler manual que aplica `data-theme` en `:root` (ver `Site.Master`).

### Tokens, colores y temas
- Archivo de referencia: `MsCargaHoras/Content/tokens.css` y `docs/Tokens-DesignSystem.md`.
- Variables base: `--bs-primary`, `--bs-danger`, `--bs-success`, `--bs-info`, `--bs-warning`, `--bs-secondary`, neutrales y superficies (`--surface-1`, `--surface-2`).
- Modo light/dark: definido por media query y por `:root[data-theme='dark'|'light']`.
- Overrides de componentes en `app.css` garantizan coherencia de color por tema en: botones `.btn-*`, tablas `.table*`, dropdowns, modales, toasts, cards, tabs, formularios, etc.
 - Bundling: `tokens.css` se incluye en `~/Content/css` (ver `MsCargaHoras/Bundle.config`) y se carga en `Site.Master` vía `<webopt:bundlereference path="~/Content/css"/>`.

### Layout y navegación
- Navbar
  - Clases: `navbar navbar-expand-lg navbar-dark bg-dark fixed-top shadow-sm`.
  - Elementos: brand con logo, toggler, menús/acciones, botón de alternar tema (`#themeToggle`), dropdown de usuario (avatar con iniciales).
  - Ubicación: `MsCargaHoras/Site.Master`.
  - Estado de color: override en `app.css` para `.navbar-dark.bg-dark` en dark mode.
  - Iconos: Bootstrap Icons (`<i class="bi bi-*"></i>`).
  - Personalizado: avatar redondo con iniciales (`.avatar-circle`) y botón de alternar tema que modifica `data-theme`.

- Toolbars superiores (fijas)
  - Barras: `#toolbarActions` y `#toolbarSearch`.
  - Clases: `toolbar sticky-top bg-body-tertiary border-bottom`.
  - Control de alturas: `--navbar-h` y `--toolbar-h` en `Site.Master` (CSS inline) y lógica JS para offsets.
  - Ubicación: `MsCargaHoras/Default.aspx`.

- Contenedor principal
  - `div.container-fluid.body-content` con padding horizontal y control de overflow.
  - Ubicación: `MsCargaHoras/Site.Master` + overrides en `app.css`.

- Footer
  - Clases: `py-3` + layout flex.
  - Ubicación: `MsCargaHoras/Site.Master`.

- Overlay de carga (custom)
  - Elementos: `#loadingOverlay` con backdrop + spinner Bootstrap.
  - Control: `UiCommon.showLoading/hideLoading` y hooks a `PageRequestManager` (postbacks). 
  - Ubicación: `MsCargaHoras/Site.Master` y `MsCargaHoras/Scripts/ui-common.js`.
  - Estado: personalización propia.

### Navegación por pestañas
- Tabs (Bootstrap)
  - Clases: `nav nav-tabs`, `tab-content`, `tab-pane`, atributos `data-bs-toggle="tab"`.
  - Persistencia de pestaña activa en `localStorage`.
  - Ubicación: `MsCargaHoras/Default.aspx`.
  - Estado de color: variables de tabs activas definidas en tokens (`--bs-nav-tabs-*`).

### Cards y agrupadores
- Cards (Bootstrap) usadas como fieldsets
  - Patrón marcado: `<fieldset class="card ..."><legend class="card-header ...">...</legend><div class="card-body">...</div></fieldset>`.
  - Ubicación: `MsCargaHoras/Default.aspx`, y también creadas dinámicamente por `UiCommon.wrapGridInCard`.
  - Estado: uso consistente; patrón de `fieldset + legend` es personalizado (ver sección de personalizaciones).

### Tablas / Grillas de datos
- ASP.NET `GridView` con estilos Bootstrap
  - Clases: `table table-striped table-hover align-middle` + `HeaderStyle CssClass="table-dark"` + `PagerStyle CssClass="pagination"`.
  - Contenedores: `.table-responsive`, `.grid-scroll`, `.table-sticky`.
  - Ubicaciones: `Default.aspx` (`grdDatos`, `grdSugeridas`, `grdHoras`, `grdTrac`), `TestLABTRAC.aspx` (`grid`).
  - Estado de color: tokens aplican variables de `table` (luz/sombra/hover) en `tokens.css` + `app.css`.

- Grid Enhancer (custom)
  - Funciones: orden por columna, filtros multi-select por columna (menú `.filter-menu`), búsqueda global (`#globalSearch`), filtro rápido por Fuente (`#ddlFuente`), badge de filtros activos en header de card.
  - Clases/estructuras: `.th-filter`, `.filter-btn`, `.filter-menu`, `.grid-filter-summary`, `.th-inner/.th-icons-*`. 
  - Ubicación: `MsCargaHoras/Scripts/grid-enhancer.js` y estilos en `MsCargaHoras/Content/app.css`.
  - Estado: componente personalizado.

### Formularios y entradas
- Inputs
  - `asp:TextBox` con `form-control` (incluye `TextMode="Date"`), `input[type="text"]` global de búsqueda.
  - `asp:DropDownList` con `form-select form-select-sm` (Filtro Fuente).
  - `input-group` en modal de login.
  - `form-check-input` (checkboxes en menús de filtro de columnas).
  - Placeholders y focus ring acordes a tokens.
  - Ubicaciones: `Default.aspx`, `TestLABTRAC.aspx` (txtQuery), modal.

- Labels y badges
  - `asp:Label` y `.form-label`.
  - Badges Bootstrap: `badge bg-secondary-subtle text-secondary-emphasis`, `badge bg-primary-subtle text-primary-emphasis`, `badge bg-dark-subtle text-dark-emphasis`.
  - Ubicaciones: toolbars, resúmenes, navbar.

- Botones
  - Variantes usadas: `.btn-primary`, `.btn-outline-primary`, `.btn-success`, `.btn-outline-info`, `.btn-warning`, `.btn-dark`, `.btn-outline-secondary`, `.btn-outline-danger`, `.btn-secondary`.
  - Variantes suaves: `.btn-soft-primary|secondary|success|info|warning|danger` mapeadas a `--bs-*-bg-subtle` y `--bs-*-text-emphasis`.
  - Tamaños: `.btn-sm` en toolbars y navbar.
  - Con iconos: `<i class="bi ..."></i>` antes del texto, o icon-only en navbar.
  - Estados y mapeo de color: en `app.css` se definen variables derivadas de `--bs-*`.

### Modales, dropdowns y toasts
- Modal (Bootstrap)
  - Modal de Login: `#loginModal` con `modal-dialog-centered`, `modal-content`.
  - Control: `bootstrap.Modal` (JS) y helper `forceCloseLoginModal()`.
  - Ubicación: `Default.aspx`.

- Dropdowns (Bootstrap)
  - Dropdown de usuario (avatar) con `dropdown-menu-end`, ítems y divisores.
  - Ubicación: `Site.Master`.

- Toasts (Bootstrap)
  - Contenedor: `#toastContainer` fijo (top-right).
  - API: `UiCommon.showToast(message, type)` crea toasts (`text-bg-*`) y usa `bootstrap.Toast` si está disponible.
  - Ubicación: `Site.Master` (contenedor) + `ui-common.js` (lógica).
  - Estado: componente personalizado (wrapper) sobre Bootstrap Toast.

### Iconografía
- Librería: Bootstrap Icons (`link` en `Site.Master`).
- Uso: `bi bi-eye-fill`, `bi bi-search`, `bi bi-plus-circle`, `bi bi-clipboard-check`, `bi bi-list-task`, `bi bi-git`, `bi bi-share`, `bi bi-file-earmark-text`, `bi bi-tools`, etc.

### Componentes WebForms en uso (UI)
- `asp:ScriptManager`, `asp:UpdatePanel` (AJAX), `asp:SqlDataSource`.
- `asp:GridView` (múltiples), `asp:BoundField`, `asp:HyperLinkField`, `asp:CommandField`, `asp:CheckBoxField`.
- `asp:TextBox`, `asp:DropDownList`, `asp:Button`, `asp:Label`, `asp:HiddenField`, `asp:Panel`.
- `friendlyUrls:ViewSwitcher` (en `Site.Mobile.Master`).

### Componente de grilla editable (3rd-party)
- Tabulator (en preparación)
  - CSS/JS referenciados en la pestaña "Carga" para `#gridHorasReales`.
  - Theming mínimo aplicado en `app.css` para alinear con tokens.
  - Ubicación: `Default.aspx` (sección Carga de Horas).

### Lista por tipo con ubicaciones
- Navegación
  - Navbar: `Site.Master`.
  - Tabs: `Default.aspx`.
  - Dropdown usuario: `Site.Master`.

- Feedback/Estado
  - Toasts: `Site.Master` + `ui-common.js`.
  - Loading overlay: `Site.Master` + `ui-common.js`.

- Datos
  - GridView: `Default.aspx` (4 grillas), `TestLABTRAC.aspx` (1 grilla).
  - Paginación: `PagerStyle CssClass="pagination"` (en `grdSugeridas`).
  - Filtros por columna/orden: `grid-enhancer.js`.

- Formularios
  - Inputs y selects: `Default.aspx`, `TestLABTRAC.aspx`.
  - Modal de login: `Default.aspx`.

- Elementos de estado
  - Badges: `Default.aspx`, `Site.Master`.
  - Spinners: overlay (Bootstrap spinner) en `Site.Master`.

### Mapeo de color (resumen)
- Botones `.btn-primary`/`outline`/`danger`/`secondary`/`success`/`info`/`warning`: derivados de `--bs-primary|danger|secondary|success|info|warning` (tokens).
- Tabs activas: `--bs-nav-tabs-link-active-*` (tokens).
- Tablas: `--bs-table-*` + degradé `--table-grad-*` (tokens/app.css).
- Cards: `--bs-card-*` (tokens).
- Dropdowns/Popovers/Modals/Toasts: `--dropdown-*`, `--popover-*`, `--modal-*`, `--toast-*` (tokens).
- Formularios: `--form-*` (tokens), foco con `--focus-ring-color`.

### Elementos personalizados o a normalizar
- Fieldset como Card
  - Uso de `<fieldset><legend>` estilizados como `.card`/`.card-header`.
  - Recomendación: mantener o migrar a markup de `.card` nativa para consistencia semántica.

- Avatar del usuario (`.avatar-circle`)
  - Generado con iniciales y degradé de marca.
  - Mantener variables de color basadas en `--bs-primary`.

- Overlay de carga y hooks a postbacks
  - Implementación propia; OK. Asegurar accesibilidad (roles/aria ya presentes).

- Grid Enhancer
  - Menús de filtro por columna (`.filter-menu`) y badge de filtros activos.
  - OK; seguir usando variables de tokens para colores de menú.

- Badges "subtle" (`bg-*-subtle`)
  - Bootstrap calcula estos tonos con variables `--bs-*-bg-subtle`/`--bs-*-text-emphasis`. Ya están definidos en `tokens.css` para ambos temas (light/dark) y se usan en variantes `.btn-soft-*`.

- Archivos legacy
  - `MsCargaHoras/Content/Content/*.css` y `MsCargaHoras/Content/Site.css` (antiguo): revisar que no estén en uso por bundles actuales.

### Guía breve de consistencia
- Usar siempre clases Bootstrap + variables `--bs-*` provistas por `tokens.css`.
- Evitar colores hardcodeados; preferir utilidades que deriven de tokens.
- Formularios: `form-control`/`form-select` y `form-check-input` para coherencia de foco/colores.
- Grillas: envolver en `.table-responsive` + `grid-scroll` y aplicar `UiCommon.standardizeGridView`/`GridEnhancer`.
- Botones: preferir variantes estándar y tamaños `.btn-sm` en toolbars; iconos con `bi` precediendo el texto.
 - Dropdowns/Modals/Toasts: inicializarlos mediante Bootstrap y dejar que `app.css`/tokens definan los colores. Tooltips: deshabilitados globalmente por ahora.

### Referencias directas a archivos
- Layout y navegación: `MsCargaHoras/Site.Master`.
- Vistas principales: `MsCargaHoras/Default.aspx`.
- Pruebas: `MsCargaHoras/TestLABTRAC.aspx`.
- Estilos: `MsCargaHoras/Content/tokens.css`, `MsCargaHoras/Content/app.css`.
- JS UI: `MsCargaHoras/Scripts/ui-common.js`, `MsCargaHoras/Scripts/grid-enhancer.js`.
- Documentos: `docs/Tokens-DesignSystem.md`, `docs/Modernizacion-UI-Bootstrap5.md`, `docs/Grilla-Horas-Reales-UX.md`.
 - Documentos: `docs/Tokens-DesignSystem.md`, `docs/Modernizacion-UI-Bootstrap5.md`, `docs/Grilla-Horas-Reales-UX.md`, `docs/Patrones-UI.md`.

### Checklist de cobertura (para futuras revisiones)
- [ ] Revisar `Content/Content/*` y `Content/Site.css` legacy en bundles; eliminar si no se usan.
- [ ] Unificar markup de cards (fieldset+legend vs card puro).
- [ ] Estandarizar tamaños y espaciados con escala `--sp-*` en nuevas vistas.
- [ ] Completar theming de Tabulator si se evoluciona la grilla editable.



