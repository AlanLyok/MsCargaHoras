# UI 2025 — Tailwind + Flowbite + daisyUI (ASP.NET Web Forms)

## Objetivo
Modernizar UI sin reescribir backend.

## Instalar
```bash
npm init -y
npm i -D tailwindcss @tailwindcss/cli daisyui flowbite
```

## CSS de entrada
`/Styles/app.tailwind.css`
```css
@import "tailwindcss";
@plugin "daisyui";
@source "./**/*.{aspx,ascx,master,html,js}";
/* opcional sin preflight:
@import "tailwindcss/components";
@import "tailwindcss/utilities";
*/
```

## Scripts
`package.json`
```json
{
  "scripts":{
    "tw:build":"npx @tailwindcss/cli -i ./Styles/app.tailwind.css -o ./Content/tw.css",
    "tw:watch":"npx @tailwindcss/cli -i ./Styles/app.tailwind.css -o ./Content/tw.css --watch"
  }
}
```
Build:
```bash
npm run tw:build
```

## Master Page (layout)
`/Site.Master` (fragmento)
```html
<html lang="es" data-theme="corporate">
<head runat="server">
  <meta charset="utf-8"/><meta name="viewport" content="width=device-width,initial-scale=1"/>
  <link href="~/Content/tw.css" rel="stylesheet"/>
</head>
<body class="min-h-dvh bg-base-100 text-base-content">
<form runat="server">
  <nav class="border-b">
    <div class="navbar container mx-auto">
      <div class="navbar-start"><a class="btn btn-ghost text-xl">App</a></div>
      <div class="navbar-end">
        <button class="btn" data-dropdown-toggle="m1" type="button">Menú</button>
        <div id="m1" class="hidden bg-base-100 shadow rounded-box p-2">
          <ul class="menu menu-sm">
            <li><a href="~/Default.aspx">Inicio</a></li>
            <li><a href="~/Cuenta/Perfil.aspx">Perfil</a></li>
          </ul>
        </div>
      </div>
    </div>
  </nav>

  <asp:ContentPlaceHolder ID="MainContent" runat="server" />
</form>
<script src="https://cdn.jsdelivr.net/npm/flowbite/dist/flowbite.min.js"></script>
</body></html>
```

## Página ejemplo
`/Cuenta/Login.aspx`
```aspx
<asp:Content ID="c1" ContentPlaceHolderID="MainContent" runat="server">
  <div class="container mx-auto px-4 py-12">
    <div class="mx-auto max-w-sm card bg-base-200 shadow-xl">
      <div class="card-body">
        <h2 class="card-title">Ingresar</h2>
        <label class="form-control">
          <span class="label-text">Usuario</span>
          <asp:TextBox ID="txtUser" runat="server" CssClass="input input-bordered w-full" />
        </label>
        <label class="form-control mt-3">
          <span class="label-text">Contraseña</span>
          <asp:TextBox ID="txtPass" runat="server" TextMode="Password" CssClass="input input-bordered w-full" />
        </label>
        <asp:Button ID="btnLogin" runat="server" Text="Entrar" CssClass="btn btn-primary mt-4 w-full" />
      </div>
    </div>
  </div>
</asp:Content>
```

## Toggle de tema
```html
<button class="btn" onclick="
  document.documentElement.setAttribute(
    'data-theme',
    document.documentElement.getAttribute('data-theme')==='dark'?'corporate':'dark'
  )">Tema</button>
```

## Migración rápida
1) Agregar `~/Content/tw.css` en `Site.Master`.
2) Crear pantallas piloto (login/dashboard) con daisyUI.
3) Sustituir modals/dropdowns por Flowbite.
4) Reemplazar paneles/tablas/inputs legacy por `card/table/input/btn`.

## Notas
- No bundlear `tw.css` con System.Web.Optimization; usar `<link>` directo.
- Mantener jQuery solo si tus scripts lo requieren; Flowbite no lo necesita.
- Si hay choque de estilos, usar variante sin preflight del CSS.
