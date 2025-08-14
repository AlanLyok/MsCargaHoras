Instalador del protocolo tareas:// para TareasNet
=================================================

Contenido
- RegistrarTareasNet.reg      → instala el protocolo (usuario actual)
- DesRegistrarTareasNet.reg   → desinstala el protocolo

Qué hace
- Registra el esquema personalizado tareas:// para que el botón de la web pueda abrir TareasNet.
- Lanza el sistema en silencio (sin ventana de consola) con directorio de trabajo C:\MsDna.
- Comando registrado:
  mshta vbscript:CreateObject("WScript.Shell").Run(
    "cmd.exe /c start """" /D ""C:\MsDna"" ""\\MSWINPFL01\Datos\archcli\TareasNet2IP.UPD""",
    0
  )(close)

Requisitos
- Debe existir la carpeta C:\MsDna.
- El recurso de red debe ser accesible: \\MSWINPFL01\Datos\archcli\TareasNet2IP.UPD
- No requiere privilegios de administrador.

Instalación (paso a paso)
1) Haga doble clic en RegistrarTareasNet.reg.
2) Acepte los avisos del Registro de Windows.
3) En el navegador, presione el botón "TareasNet". En el primer uso, el navegador puede preguntar si desea abrir una aplicación externa; puede marcar "Permitir siempre".

Desinstalación
1) Haga doble clic en DesRegistrarTareasNet.reg y acepte los avisos.

Verificación manual (opcional)
- Abrir "Símbolo del sistema" y ejecutar:
  reg query "HKCU\Software\Classes\tareas\shell\open\command" /ve
- Debe mostrarse un valor que comienza con:
  mshta vbscript:CreateObject("WScript.Shell").Run("cmd.exe /c start ... /D "C:\MsDna" ...)

Solución de problemas
- Si el navegador intenta abrir "Windows Script Host" (wscript.exe), quedó un registro viejo:
  1) Desinstale con DesRegistrarTareasNet.reg.
  2) En CMD, ejecute: reg delete "HKCU\Software\Classes\tareas" /f
  3) Vuelva a instalar RegistrarTareasNet.reg.
- Si TareasNet muestra errores buscando archivos en C:\Windows\System32, asegúrese de reinstalar con este paquete (fija "Iniciar en: C:\MsDna").

Contacto
- Equipo Desarrollo Mastersoft


