## Modernización UI y Unificación a Bootstrap 5.3+

### Resumen
- **Objetivo**: Unificar el framework de UI en Bootstrap 5.3+, eliminar jQuery en la UI nueva y mantener compatibilidad con páginas legacy.
- **Beneficios**: coherencia visual, mejor tipografía y grid, utilidades modernas, variables para theming, accesibilidad y rendimiento.
- **Resultado esperado**: vistas nuevas consistentes, grilla editable moderna en “Horas Reales” y base lista para modo oscuro.

### Alcance
- Vistas de la nueva UX, incluyendo la solapa “Horas Reales”.
- Layout base, navegación con tabs y contenedores fluidos.
- Theming con tokens y modo claro/oscuro.
- Controles de entrada modernos y accesibles.
- Páginas legacy continúan operando con dependencias históricas cuando sea necesario.

### Principios
- **Base única**: Bootstrap 5.3+.
- **UI nueva sin jQuery**; mantener jQuery solo donde el legacy lo requiera.
- **Componentes livianos y OSS**, con foco en accesibilidad.
- **Separación de responsabilidades**: tokens (variables), utilidades/overrides y estilos históricos.
- **Evolución segura**: feature flags y despliegue escalonado.

### Decisiones tecnológicas
- **Framework**: Bootstrap 5.3+ como estándar único.
- **Design system**: capa liviana sobre BS5. Alternativas:
  - Tabler CSS o AdminLTE v4 para una base de “app interna” con componentes coherentes.
  - O bien BS5 puro con tokens propios y utilidades.
- **Iconografía**: Bootstrap Icons para estados y acciones.
- **Grilla editable**: Tabulator (MIT). Alternativa: AG Grid Community.
- **Controles**: Flatpickr (fecha/hora), Tom Select (selects con autocomplete), Tippy.js (tooltips/ayuda).
- **Bundling**: System.Web.Optimization o referencias directas a archivos minimizados, manteniendo cargas separadas para legacy vs UI nueva.

### Plan de trabajo (paso a paso)
**A. Resolver la doble Bootstrap**
- Adoptar Bootstrap 5.3+ como base única en vistas nuevas.
- Actualizar bundles y orden de carga en `Site.Master`.
- Retirar referencias a BS3/jQuery en vistas nuevas; conservar jQuery donde el legacy lo requiera.

**B. Hoja de estilos de sistema**
- Crear `tokens.css` para variables de diseño.
- Crear `app.css` para utilidades y overrides (estados de fila, sticky, focus, zebra tables, etc.).
- Mantener en `Site.css` solo estilos históricos no disruptivos.

**C. Layout base de aplicación**
- Header compacto con breadcrumb opcional.
- Contenedor `container-fluid` con filas y columnas estándar BS5.
- Tabs BS5 para “Faltantes / Sugeridas / Reales” con `nav-tabs` y `tab-content`.

**D. Grilla “Horas Reales”**
- Incluir Tabulator únicamente en la solapa nueva.
- Columnas y editores: Estado, Cliente, Proyecto, Actividad, Tarea, Desde, Hasta, Horas, Fuera, Observaciones.
- Estados visuales por fila (N/M/E), validaciones inline, pegado masivo, duplicado y detección de solapes con avisos discretos.

**E. Controles y utilidades**
- Flatpickr para fecha/hora (24h, paso pequeño consistente con negocio).
- Tom Select para Cliente/Proyecto (autocomplete, dependencia entre combos y caché por sesión).
- Toasts livianos para autoguardado y errores discretos; tooltips de atajos con Tippy.js.

**F. Theming + Dark mode**
- Toggle en header que alterna una clase de tema sobre el elemento raíz y conmuta tokens.
- Persistir preferencia en almacenamiento local y respetar preferencias del sistema.

### Prioridades (rápidas, alto impacto)
- Unificar a Bootstrap 5.3+ y limpiar el bundle.
- Definir tokens de diseño y `app.css`.
- Incorporar Tabulator en “Horas Reales”.
- Añadir Flatpickr y Tom Select en inputs clave.
- Integrar iconografía y reforzar accesibilidad (focus/contraste/atajos).

### Checklist de implementación
- [Hecho] Bootstrap 5.3+ único en vistas nuevas y orden de bundle actualizado.
- [Hecho] `tokens.css` y `app.css` creados y referenciados.
- [Hecho] Layout base con `container-fluid`, tabs BS5 y tema claro/oscuro con persistencia.
- [Hecho] UI nueva sin jQuery en `MsCargaHoras`; jQuery queda sólo como compatibilidad legacy.
- [Hecho] Preparación de grilla Tabulator en solapa “Carga de Horas” (placeholder + estilos + carga acotada).
- [Hecho] Accesibilidad mínima en tabs (aria-label, foco).
- [Pendiente] Columnas/editores finales de la grilla, validaciones, pegado masivo, duplicado.
- [Pendiente] Detección de solapes y contador de conflictos.
- [Pendiente] Toasts/Tooltips de ayuda y atajos.
- [Hecho] Modo oscuro con tokens y mapeo de variables BS; contraste verificado.
- [Hecho] Páginas legacy sin regresiones vinculadas a jQuery.
- [Hecho] Transforms `Web.Debug.config`/`Web.Release.config` para cadenas y tenant (sacar secretos del `Web.config`).

### Pruebas y validación
- Navegación por teclado y lectores de pantalla.
- Cross-browser reciente (Chromium, Firefox, Edge).
- Rendimiento con volúmenes altos en grilla (virtualización efectiva) [Pendiente al implementar columnas].
- Flujo de pegado, duplicado, detección de solapes y conteo de cambios [Pendiente].
- Revisión visual y de contraste en modo claro/oscuro.

### Despliegue y rollback
- Habilitar por feature flag las vistas nuevas.
- Despliegue escalonado: primero layout + tokens, luego grilla y controles.
- Rollback rápido: conservar bundles antiguos y alternar el flag si fuera necesario.

### Próximas iteraciones
- I1: Columnas/editores Tabulator + estados N/M/E + contador de cambios.
- I2: Validaciones cliente + toasts + pegado masivo.
- I3: Solapes + guardado integrado con SPs (errores y mapeo de IDs).
- I4: Dependencias Cliente→Proyecto→Actividad y tuning de rendimiento/accesibilidad.

### Referencias
- Bootstrap 5.3+: [Sitio oficial](https://getbootstrap.com)
- Bootstrap Icons: [Iconos](https://icons.getbootstrap.com)
- Tabulator: [Documentación](https://tabulator.info)
- AG Grid Community: [Documentación](https://www.ag-grid.com)
- Tabler CSS: [Documentación](https://tabler.io)
- AdminLTE v4: [Documentación](https://adminlte.io)
- Flatpickr: [Documentación](https://flatpickr.js.org)
- Tom Select: [Documentación](https://tom-select.js.org)
- Tippy.js: [Documentación](https://atomiks.github.io/tippyjs)


