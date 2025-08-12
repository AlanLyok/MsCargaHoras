# Guía de Estilos UI 2025 — Tailwind + Flowbite + daisyUI (WebForms .NET) — **Paleta actualizada #C00000**

> **Objetivo:** Sistema visual moderno y performante con 2 temas:  
> **app-dark:** negro + gris oscuro + **rojo #C00000**  
> **app-light:** blanco + gris claro + **rojo #C00000**  
> Instrucciones para que una IA actualice **código existente**, `tailwind.config.js`, vistas WebForms y CSS.

---

## 0) Stack asumido
- Tailwind v4 (`@tailwindcss/cli`), **daisyUI**, Flowbite.  
- ASP.NET Web Forms (`Site.Master`, `.aspx`, `.ascx`).  
- `tw.css` compilado por Tailwind y referenciado con `<link>`.

---

## 1) **Actualización obligatoria de colores** (Tailwind/daisyUI)

### 1.1 Reemplazar temas en `tailwind.config.js`
> **Acción IA:** localizar `module.exports.daisyui.themes` y **sobrescribir** con:

```js
/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ["./**/*.{aspx,ascx,master,html,js}"],
  plugins: [require('daisyui')],
  daisyui: {
    themes: [
      {
        "app-light": {
          "primary": "#C00000",          // rojo corporativo
          "primary-content": "#FFFFFF",
          "secondary": "#6B7280",        // gris medio
          "accent": "#C00000",           // mantener rojo como acento
          "neutral": "#111827",          // texto principal
          "base-100": "#FFFFFF",         // fondo blanco
          "base-200": "#F3F4F6",         // gris claro
          "base-300": "#E5E7EB",
          "info": "#0EA5E9",
          "success": "#22C55E",
          "warning": "#F59E0B",
          "error": "#B91C1C"
        }
      },
      {
        "app-dark": {
          "primary": "#C00000",
          "primary-content": "#FFFFFF",
          "secondary": "#9CA3AF",        // gris claro en dark
          "accent": "#C00000",
          "neutral": "#E5E7EB",          // texto principal
          "base-100": "#0B0C0F",         // casi negro
          "base-200": "#111317",         // gris muy oscuro
          "base-300": "#1B1F27",
          "info": "#38BDF8",
          "success": "#22C55E",
          "warning": "#FBBF24",
          "error": "#F87171"
        }
      }
    ]
  }
};
```

### 1.2 Activar tema y toggle
> **Acción IA:** en `Site.Master` (o layout), asegurar:

```html
<html lang="es" data-theme="app-light"> <!-- app-dark opcional -->
```

> **Acción IA:** añadir/preservar toggle + persistencia:

```html
<button id="themeBtn" type="button" class="btn btn-sm">Tema</button>
<script>
(function(){
  var r=document.documentElement, k='theme', s=localStorage.getItem(k);
  if(s) r.setAttribute('data-theme', s);
  document.getElementById('themeBtn').addEventListener('click', function(){
    var next = r.getAttribute('data-theme')==='app-dark'?'app-light':'app-dark';
    r.setAttribute('data-theme', next); localStorage.setItem(k,next);
  });
})();
</script>
```

### 1.3 Rebuild CSS
> **Acción IA (terminal):**
```bash
npm run tw:build
```

---

## 2) **Tokens & reglas de uso** (con #C00000)

**Color**
- Primario: `bg-primary text-primary-content hover:brightness-110 active:brightness-90`.
- Links de acción: `text-primary hover:underline` en contenido.
- Bordes: `border-base-300` (light), `border-base-200` (dark).
- Separadores: `divide-base-300/60`.
- **No** usar rojo para párrafos extensos; reservar para CTAs, badges, highlights.

**Tipografía**
- Fuente: `ui-sans-serif, system-ui, Segoe UI, Roboto, Inter, Arial, sans-serif`.
- Jerarquía: H1 `text-3xl/7`, H2 `text-2xl/7`, H3 `text-xl/7`, cuerpo `text-base/7`, _muted_ `text-sm/6 text-base-content/70`.
- Pesos: títulos `font-semibold`, botones `font-medium`.

**Espaciado**
- `container mx-auto px-4 md:px-6`.
- `gap-4` (cards/listas), `gap-6` (secciones).  
- Márgenes seccionales: `mb-8`.

**Radios & sombras**
- `rounded-xl` (controles), `rounded-2xl` (cards/modals).
- `shadow` suave / `shadow-lg` en overlays. Evitar sombras en listas largas.

**Focus & A11y**
- `focus:outline-none focus:ring-2 focus:ring-primary/70 focus:ring-offset-2`.
- Contraste mínimo 4.5:1; texto crítico **no** en rojo puro.

**Motion**
- `transition-all duration-150` en hover/focus.  
- Respetar `prefers-reduced-motion`.

---

## 3) Patrones de layout

**Shell**
```html
<body class="min-h-dvh bg-base-100 text-base-content">
  <div class="drawer lg:drawer-open">
    <input id="nav" type="checkbox" class="drawer-toggle" />
    <div class="drawer-content">
      <div class="navbar border-b px-4">
        <label for="nav" class="btn btn-ghost lg:hidden">☰</label>
        <div class="flex-1 text-lg font-semibold">App</div>
        <div class="flex items-center gap-2">
          <button class="btn btn-primary btn-sm">Acción</button>
        </div>
      </div>
      <main class="container mx-auto p-4 md:p-6"><!-- contenido --></main>
    </div>
    <div class="drawer-side border-r bg-base-100">
      <label for="nav" class="drawer-overlay"></label>
      <aside class="w-72 p-4">
        <ul class="menu">
          <li><a href="~/Default.aspx">Inicio</a></li>
          <li><details open><summary>Módulo</summary>
            <ul><li><a>Opción A</a></li></ul>
          </details></li>
        </ul>
      </aside>
    </div>
  </div>
</body>
```

**Secciones**
- Título `text-2xl font-semibold mb-4`; contenido con `grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-6`.

---

## 4) Componentes (clases + política)

**Botones (daisyUI)**
- Primario (CTA): `btn btn-primary` (usa #C00000).
- Secundario: `btn`.
- Fantasma: `btn btn-ghost` (nav).
- Tamaños: `btn-sm|btn|btn-lg` (default: `btn`).

**Inputs**
- `input input-bordered w-full`, `select select-bordered w-full`, `textarea textarea-bordered w-full`.
- Ayuda `text-sm text-base-content/70`; error `text-error`.

**Formularios**
- 1-col: `space-y-4`; 2-col: `grid grid-cols-1 md:grid-cols-2 gap-6`.
- Botonera: `mt-6 flex gap-3` → `[Guardar]=btn-primary` `[Cancelar]=btn-ghost`.
- Validación: borde `border-error` + `alert alert-error` (errores globales).

**Cards/Panels**
- `card bg-base-200 shadow-lg rounded-2xl`; header `card-title` + acciones a la derecha.

**Tablas**
- Wrapper `overflow-x-auto`; `table` (+ `table-zebra` opcional).
- Header sticky: `sticky top-0 bg-base-100`.
- Acciones fila: `btn btn-sm`.

**Modals/Drawers**
- Preferir **daisyUI modal** o **Flowbite modal**. Acciones claras (`btn-primary` + `btn-ghost`).

**Feedback**
- `alert alert-success|warning|error|info`; toast con `toast > .alert` (auto-cierre 3–5s).
- Skeleton: `skeleton h-6 w-…`.

**Badges**
- `badge` / `badge-outline` (usar `badge-primary` con prudencia).

---

## 5) Iconografía
- SVG inline (Heroicons/Lucide), trazo 1.5–2px (`stroke-current`).
- Tamaños: `size-4` texto, `size-5` botón, `size-6` header.
- Color hereda; evitar PNG para UI cromada.

---

## 6) Gráficos
- Serie principal con `text-primary` para acentos; secundarias en neutros.
- Fondos transparentes; labels `text-sm`; sin sombras ni animaciones pesadas.

---

## 7) Accesibilidad
- Focus visible en todo interactivo.
- `aria-label` en icon-only.
- Orden de tab correcto; modal con foco interno.
- AA mínimo de contraste.

---

## 8) Performance
- Compilar `tw.css` (purgado) — **no** Play CDN en prod.
- Imágenes `loading="lazy"` y `decoding="async"`.
- Evitar reflow: alturas fijas en skeletons/containers.
- Reusar componentes; minimizar JS (usar nativo de daisyUI/Flowbite).

---

## 9) Mapeo WebForms (reglas IA)
1. Asegurar `<link href="~/Content/tw.css" rel="stylesheet" />` y `data-theme="app-light|app-dark"`.
2. En cada `.aspx`:
   - Envolver con `container mx-auto p-4 md:p-6`.
   - Paneles → `card`.
   - Inputs → `input/select/textarea ...-bordered w-full`.
   - Botones → `btn|btn-primary` (usa #C00000).
   - Tablas → `overflow-x-auto table`.
   - Alertas → `alert ...`.
3. Estándares:
   - `rounded-xl` mínimo; `shadow` moderado; `gap-6` secciones; `space-y-4` forms.
4. Validación:
   - Borde `border-error`; texto `text-error`; `ValidationSummary` → `alert alert-error`.
5. Navbar/Sidebar:
   - Navbar `navbar border-b`; sidebar `drawer`.

---

## 10) Ejemplo corto (ABM)
```aspx
<div class="card bg-base-200 shadow-lg">
  <div class="card-body">
    <h2 class="card-title">Cliente</h2>
    <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
      <label class="form-control">
        <span class="label-text">Nombre</span>
        <asp:TextBox runat="server" CssClass="input input-bordered w-full" />
      </label>
      <label class="form-control">
        <span class="label-text">CUIT</span>
        <asp:TextBox runat="server" CssClass="input input-bordered w-full" />
      </label>
    </div>
    <div class="mt-6 flex gap-3">
      <asp:Button runat="server" Text="Guardar" CssClass="btn btn-primary" />
      <asp:Button runat="server" Text="Cancelar" CssClass="btn btn-ghost" />
    </div>
  </div>
</div>
```

---

## 11) Do / Don’t
**Do**
- Usar `app-light/app-dark` y `btn/btn-primary` (rojo #C00000).
- Mantener radios/sombras/espaciado consistentes.
- Preferir componentes nativos (daisyUI/Flowbite).

**Don’t**
- Mezclar Bootstrap y Tailwind en **vistas nuevas**.
- Usar rojo en bloques de texto largos.
- Sombras fuertes en listados extensos.

---

## 12) Checklist por vista
- [ ] Layout base (container + spacing).
- [ ] Tipografía jerárquica correcta.
- [ ] Paleta aplicada (fondo/contraste), rojo **#C00000** en CTAs.
- [ ] Controles daisyUI aplicados.
- [ ] Focus/hover visibles.
- [ ] Accesibilidad AA.
- [ ] Carga percibida (skeleton/toast).
- [ ] Sin dependencias legacy innecesarias.
