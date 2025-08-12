<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="TestLABTRAC.aspx.cs" Inherits="MsCargaHoras.TestLABTRAC" MasterPageFile="~/Site.Master" %>

<asp:Content runat="server" ID="BodyContent" ContentPlaceHolderID="MainContent">
    <h2>Prueba de conectividad LABTRAC</h2>
    <p>Ejecuta una consulta simple contra la cadena de conexión <strong>LABTRACConnectionString</strong>.</p>
    <asp:Panel runat="server">
        <asp:Label runat="server" ID="lblStatus" />
    </asp:Panel>
    <asp:Panel runat="server" CssClass="form-group">
        <asp:TextBox runat="server" ID="txtQuery" CssClass="form-control" />
        <asp:Button runat="server" ID="btnRun" Text="Ejecutar" OnClick="btnRun_Click" CssClass="btn btn-primary" />
    </asp:Panel>
    <asp:GridView runat="server" ID="grid" CssClass="table table-striped table-bordered" AutoGenerateColumns="true" />
</asp:Content>


