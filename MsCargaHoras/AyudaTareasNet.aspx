<%@ Page Title="Ayuda TareasNet" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="AyudaTareasNet.aspx.cs" Inherits="MsCargaHoras.AyudaTareasNet" %>

<asp:Content ID="BodyContent" ContentPlaceHolderID="MainContent" runat="server">
    <div class="py-4">
        <div class="container">
            <div class="card shadow-sm">
                <div class="card-header d-flex align-items-center justify-content-between">
                    <span class="h5 mb-0">Abrir TareasNet</span>
                    <a class="btn btn-outline-secondary btn-sm" href="<%: ResolveUrl("~/") %>">Volver al inicio</a>
                </div>
                <div class="card-body">
                    <div class="alert alert-warning" role="alert">
                        ¿No se abrió? Descargá <strong>Registrar_TareasNet.zip</strong> para habilitar el acceso desde el navegador.
                    </div>
                    <div class="d-flex flex-wrap gap-2 mb-3">
                        <a class="btn btn-primary" href="<%: ResolveUrl("~/Descargas/ProtocoloTareas.ashx") %>" download="Registrar_TareasNet.zip" target="_blank" rel="noopener" onclick="return openExternal('<%: ResolveUrl("~/Descargas/ProtocoloTareas.ashx") %>');">Descargar Registrar_TareasNet.zip</a>
                        <a class="btn btn-outline-secondary" href="<%: ResolveUrl("~/") %>">Volver al inicio</a>
                    </div>
                    <div class="mb-2 fw-semibold">Paso a paso</div>
                    <ol class="mb-0">
                        <li>Descargá el ZIP.</li>
                        <li>Extraé el contenido.</li>
                        <li>Hacé doble clic en <strong>RegistrarTareasNet.reg</strong> y aceptá los avisos.</li>
                        <li>Volvé a la página anterior y probá el botón <strong>TareasNet</strong> nuevamente.</li>
                    </ol>
                </div>
            </div>
        </div>
    </div>
</asp:Content>
