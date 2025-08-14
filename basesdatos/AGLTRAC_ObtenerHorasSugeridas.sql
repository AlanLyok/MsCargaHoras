-- Ejemplos:
-- EXEC dbo.AGLTRAC_ObtenerHorasSugeridas @Filtro='alan', @Fuente='TRAC', @Top=10;
-- EXEC dbo.AGLTRAC_ObtenerHorasSugeridas @Filtro='113',  @Fuente='ACT',  @Top=5;
-- EXEC dbo.AGLTRAC_ObtenerHorasSugeridas @Filtro='Desarrollo', @Fuente='TODOS', @Top=20;

CREATE OR ALTER PROC dbo.AGLTRAC_ObtenerHorasSugeridas
  @Filtro        VARCHAR(200) = 'Desarrollo',   -- nro, nombre, usuario, 'Todos' o 'Desarrollo'
  @SoloActivos   BIT          = 1,
  @FechaDesde    DATETIME     = '2023-01-01T09:00:00', -- para TRAC
  @Fuente        VARCHAR(12)  = 'TODOS',        -- 'TRAC' | 'ACT'/'ACTIVIDADES' | 'TODOS'
  @Top           INT          = 10
AS
BEGIN
  SET NOCOUNT ON;

  -- Normalizo @Top
  IF @Top IS NULL OR @Top < 1 SET @Top = 10;

  -- Normalizo fuente
  DECLARE @F VARCHAR(12) = UPPER(LTRIM(RTRIM(@Fuente)));
  DECLARE @InclTRAC BIT = CASE WHEN @F IN ('TRAC','TODOS','ALL','*') THEN 1 ELSE 0 END;
  DECLARE @InclACT  BIT = CASE WHEN @F IN ('ACT','ACTIVIDAD','ACTIVIDADES','TODOS','ALL','*') THEN 1 ELSE 0 END;

  -- Resolver filtro local (legajo/usuario/nombre) y armar owners
  DECLARE @LegajoNum INT = NULL;
  IF @Filtro NOT LIKE '%[^0-9]%' AND LEN(@Filtro) > 0
  BEGIN
    BEGIN TRY SET @LegajoNum = CAST(@Filtro AS INT); END TRY
    BEGIN CATCH SET @LegajoNum = NULL; END CATCH
  END

  CREATE TABLE #OwnersDetail (
    Usuario    VARCHAR(200) NOT NULL PRIMARY KEY,
    NroLegajo  INT          NULL,
    ApeyNom    VARCHAR(200) NULL,
    Mail       VARCHAR(200) NULL
  );

  INSERT INTO #OwnersDetail (Usuario, NroLegajo, ApeyNom, Mail)
  SELECT DISTINCT U.Usuario, L.NroLegajo, L.ApeyNom, U.Mail
  FROM TareasNetMs..Legajos  L
  JOIN TareasNetMs..Usuarios U ON U.UsuarioID = L.UsuarioID
  WHERE (@SoloActivos = 0 OR L.Activo = 1)
    AND (
         @Filtro = 'Todos'
      OR (@Filtro = 'Desarrollo' AND L.SectorID IN (1,8))
      OR (@LegajoNum IS NOT NULL AND L.NroLegajo = @LegajoNum)
      OR (U.Usuario = @Filtro)
      OR (L.ApeyNom COLLATE SQL_Latin1_General_CP1_CI_AI LIKE '%' + @Filtro + '%')
    );

  IF NOT EXISTS (SELECT 1 FROM #OwnersDetail)
  BEGIN
    SELECT TOP 0
      CAST(NULL AS VARCHAR(255)) AS Titulo,
      CAST(NULL AS VARCHAR(12))  AS [type],
      CAST(NULL AS VARCHAR(200)) AS Mail,
      CAST(NULL AS VARCHAR(300)) AS Link,
      CAST(NULL AS VARCHAR(200)) AS Cliente,
      CAST(NULL AS VARCHAR(200)) AS Proyecto,
      CAST(NULL AS DATETIME)     AS FechaInicio,
      CAST(NULL AS DATETIME)     AS FechaComprometida,
      CAST(NULL AS VARCHAR(12))  AS Fuente;
    RETURN;
  END

  DECLARE @OwnerList NVARCHAR(MAX);
  SELECT @OwnerList =
    STUFF((
      SELECT DISTINCT ',' + '''' + REPLACE(LOWER(Usuario), '''', '''''') + ''''
      FROM #OwnersDetail
      FOR XML PATH(''), TYPE
    ).value('.', 'nvarchar(max)'), 1, 1, '');

  DECLARE @FechaDesdeTRAC_sec BIGINT = DATEDIFF(SECOND, '19700101', @FechaDesde);
  DECLARE @LinkedServer SYSNAME  = N'MSTRAC';
  DECLARE @remote      NVARCHAR(MAX);
  DECLARE @sql         NVARCHAR(MAX);
  DECLARE @selectUnion NVARCHAR(200);

  -- Selección final según @Fuente
  IF @InclTRAC=1 AND @InclACT=1
       SET @selectUnion = N'SELECT * FROM T_TRAC UNION ALL SELECT * FROM T_ACT';
  ELSE IF @InclTRAC=1
       SET @selectUnion = N'SELECT * FROM T_TRAC';
  ELSE IF @InclACT=1
       SET @selectUnion = N'SELECT * FROM T_ACT';
  ELSE   -- ninguno: devolver vacío
       SET @selectUnion = N'SELECT * FROM T_TRAC WHERE 1=0';

  -- Consulta TRAC remota (con filtro por owners + fecha)
  SET @remote = N'
    SELECT  t.status,
            prioridad.value AS prioridad,
            t.id            AS ticket,
            t.type,
            cl.value        AS cliente,
            t.severity,
            t.summary,
            t.reporter,
            t.owner,
            t.time          AS created,
            t.changetime    AS modified
    FROM ticket t
    LEFT JOIN enum e
           ON e.name = t.severity AND e.type = ''severity''
    LEFT JOIN ticket_custom c
           ON c.ticket = t.id AND c.name = ''tcf_subcomponent''
    LEFT JOIN ticket_custom cl
           ON cl.ticket = t.id AND cl.name = ''client''
    LEFT JOIN ticket_custom desamda
           ON desamda.ticket = t.id AND desamda.name = ''d_developersmda''
    LEFT JOIN ticket_custom prioridad
           ON prioridad.ticket = t.id AND prioridad.name = ''our_priority''
    WHERE t.type IN (''Defecto'',''Evolutivo'',''Incidente'',''Mejora'',''GDC'')
      AND t.status NOT IN (''d_closed'',''m_closed'',''i_closed'',''x_closed'',''g_closed'')
      AND t.time >= ' + CAST(@FechaDesdeTRAC_sec AS VARCHAR(30)) + N'
      AND LOWER(t.owner) IN (' + @OwnerList + N')';

  -- CTEs + TOP parametrizado
  SET @sql = N'
  ;WITH T_TRAC AS (
    SELECT
      ''https://ticket.mastersoft.com.ar/trac/incidentes/ticket/'' + CAST(T.ticket AS VARCHAR(20)) AS Link,
      CAST(T.ticket AS VARCHAR(20)) + ''|'' + LEFT(T.summary,100)  AS Titulo,
      T.cliente                                     AS Cliente,
      CAST(T.ticket AS VARCHAR(20))                 AS Proyecto,
      T.[type]                                      AS Tipo,
      DATEADD(SECOND, T.created  / 1000000 - 10800, CONVERT(DATETIME,''19700101'',112)) AS FechaInicio,
      DATEADD(SECOND, T.modified / 1000000 - 10800, CONVERT(DATETIME,''19700101'',112)) AS FechaComprometida,
      OD.Mail,
      OD.NroLegajo,
      OD.ApeyNom,
      ''TRAC'' AS Fuente
    FROM OPENQUERY(' + QUOTENAME(@LinkedServer) + N', ''' + REPLACE(@remote,'''','''''') + N''') AS T
    JOIN #OwnersDetail AS OD ON OD.Usuario = T.owner
  ),
  T_ACT AS (
    SELECT
      ''https://desarrollo.mastersoft.com.ar/DatosActividad/?ActividadID='' + CAST(AC.ActividadID AS VARCHAR(20)) AS Link,
      LEFT(CAST(AC.ActividadID AS VARCHAR(20)) + ''|'' + AC.Descripcion + '' |'' + LTRIM(RTRIM(PR.Descripcion)) + '' | '' + CL.RazonSocial, 255) AS Titulo,
      LTRIM(RTRIM(CL.RazonSocial)) AS Cliente,
      CAST(PR.Nrodoc AS VARCHAR(20)) + PR.Descripcion AS Proyecto,
      ''Actividad'' AS Tipo,
      DATEADD(HOUR,12, AC.FechaInicio)       AS FechaInicio,
      DATEADD(HOUR,12, AC.FechaComprometida) AS FechaComprometida,
      OD.Mail,
      OD.NroLegajo,
      OD.ApeyNom,
      ''ACT'' AS Fuente
    FROM TareasNetMs..Clientes CL
    JOIN TareasNetMs..Proyectos PR ON PR.ClienteID = CL.ClienteID
    JOIN TareasNetMs..Actividades AC ON AC.ProyectoID = PR.ProyectoID
    JOIN TareasNetMs..Legajos LG ON LG.NroLegajo = AC.NroLegajoACargo
    JOIN #OwnersDetail AS OD ON OD.NroLegajo = LG.NroLegajo
    JOIN TareasNetMs..Usuarios U ON U.UsuarioID = LG.UsuarioID
    JOIN TareasNetMs..TipoTope TT ON TT.TipoTopeID = AC.TipoTopeID
    JOIN TareasNetMs..EstadosActividad EA ON EA.EstadoActividadID = AC.EstadoActividadID
    JOIN TareasNetMs..TipoActividad TA ON TA.TipoActividadID = AC.TipoActividadID
    JOIN TareasNetMs..ActividadesPlanificacion AP 
         ON AC.ActividadID = AP.ActividadID AND AC.EstadoActividadID = AP.EstadoActividadID
    LEFT JOIN TareasNetMS.dbo.ActividadesDocumentosDesarrollo DOCACT 
         ON DOCACT.ActividadID = AC.ActividadID AND DOCACT.documentodesaid = 2
    LEFT JOIN TareasNetMS.dbo.ActividadesDocumentosDesarrollo FC61 
         ON FC61.ActividadId = AC.ActividadId AND FC61.documentodesaid = 1
    WHERE ' + CASE WHEN @SoloActivos=1 THEN N'LG.Activo = 1 AND ' ELSE N'' END + N' EA.Terminada = 0
  )
  SELECT TOP (@Top)
      Titulo,
      Tipo AS [type],
      Mail,
      Link,
      Cliente,
      Proyecto,
      FechaInicio,
      FechaComprometida,
      Fuente
  FROM (
      ' + @selectUnion + N'
  ) X
  ORDER BY FechaInicio DESC;';

  EXEC sp_executesql @sql, N'@Top INT', @Top=@Top;
END
GO
