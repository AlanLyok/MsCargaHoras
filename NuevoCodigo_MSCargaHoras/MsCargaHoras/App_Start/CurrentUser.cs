using System;

namespace MsCargaHoras.App_Start
{
    /// <summary>
    /// Representa el usuario actual resuelto para la sesión de la aplicación.
    /// </summary>
    public sealed class CurrentUser
    {
        public string Nombre { get; set; } = string.Empty;
        public string Legajo { get; set; } = string.Empty;
        public string Usuario { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;

        public bool IsValid()
        {
            return !string.IsNullOrWhiteSpace(Usuario) || !string.IsNullOrWhiteSpace(Legajo) || !string.IsNullOrWhiteSpace(Nombre);
        }
    }
}


