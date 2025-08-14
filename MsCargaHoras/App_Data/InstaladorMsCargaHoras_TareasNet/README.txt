Instalador MsCargaHoras - TareasNet
===================================

Contenido del ZIP
- Instalar_RunTareasNet.bat  → Instala el protocolo tareas:// para abrir TareasNet
- Desinstalar_RunTareasNet.bat  → Quita el protocolo
- Data\RegistrarTareasNet.reg  → Claves de registro de instalación (usuario actual)
- Data\DesRegistrarTareasNet.reg  → Claves de registro de desinstalación

Requisitos
- Windows con acceso al recurso de red: \\MSWINPFL01\Datos\archcli\TareasNet2IP.UPD
- Archivo C:\MsDna\RunNet.exe existente (o la carpeta C:\MsDna/ D:\MsDna). Si no existe, el instalador crea C:\MsDna.
- No requiere privilegios de administrador.

Instalación (paso a paso)
1) Extraer el ZIP en una carpeta temporal (Escritorio/Descargas).
2) Ejecutar Instalar_RunTareasNet.bat (doble clic).
3) Verificar mensajes “OK” en cada paso y “Instalación completa”.
4) Volver al navegador y presionar el botón “TareasNet”.

Qué hace la instalación
- Crea/elige la carpeta MsDna en C:\ (o usa D:\MsDna si ya existe).
- Registra el protocolo tareas:// bajo:
  HKCU\Software\Classes\tareas\shell\open\command
  Valor: mshta vbscript:CreateObject("WScript.Shell").Run("C:\\MsDna\\RunNet.exe \\\\MSWINPFL01\\Datos\\archcli\\TareasNet2IP.UPD",0)(close)
- Abre TareasNet sin mostrar consola (modo oculto).

Desinstalación
1) Ejecutar Desinstalar_RunTareasNet.bat (doble clic).
2) Esto quita la clave HKCU\Software\Classes\tareas.

Pruebas rápidas
- En el navegador (Chrome/Edge), escribir en la barra: tareas://abrir
  La primera vez, el navegador puede pedir confirmación para abrir una app externa.
- Desde el sitio interno, presionar el botón “TareasNet”.

Solución de problemas
- Si no se abre nada y no aparecen errores:
  • Asegurarse de tener acceso al recurso \\MSWINPFL01\Datos\archcli\TareasNet2IP.UPD (probar en el Explorador).
  • Confirmar que exista C:\MsDna\RunNet.exe.
  • Verificar con “reg query HKCU\Software\Classes\tareas\shell\open\command /ve”.
  • Revisar que mshta.exe exista en %SystemRoot%\System32\mshta.exe.
- Si el recurso de red o la ruta de RunNet.exe cambian, editar Data\RegistrarTareasNet.reg y reinstalar.

Contacto
- Equipo Desarrollo Mastersoft


