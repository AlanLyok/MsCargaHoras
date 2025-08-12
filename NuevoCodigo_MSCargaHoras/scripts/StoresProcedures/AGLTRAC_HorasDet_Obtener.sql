-- Ejemplos:
-- EXEC dbo.AGLTRAC_HorasDet_Obtener @Filtro='alan',       @Fecha='20250801';
-- EXEC dbo.AGLTRAC_HorasDet_Obtener @Filtro='113',        @Fecha='20250801';
-- EXEC dbo.AGLTRAC_HorasDet_Obtener @Filtro='Todos',      @Fecha='20250801';
-- EXEC dbo.AGLTRAC_HorasDet_Obtener @Filtro='Desarrollo', @Fecha='20250801';

ALTER PROCEDURE dbo.AGLTRAC_HorasDet_Obtener
  @Filtro       VARCHAR(200) = 'Desarrollo',  -- nro, nombre, usuario, 'Todos' o 'Desarrollo'
  @Fecha        VARCHAR(20),                  -- 'YYYYMMDD' o fecha convertible
  @SoloActivos  BIT = 1
AS
BEGIN
  SET NOCOUNT ON;

  ---------------------------------------------------------------------------
  -- 1) Parseo de fecha (sin TRY_CONVERT). Acepta 'YYYYMMDD' o cualquier CONVERTIBLE.
  ---------------------------------------------------------------------------
  DECLARE @FechaDT DATETIME;
  IF (@Fecha LIKE '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]')
       SET @FechaDT = CONVERT(DATETIME, @Fecha, 112);
  ELSE IF (ISDATE(@Fecha) = 1)
       SET @FechaDT = CAST(@Fecha AS DATETIME);
  ELSE
  BEGIN
       RAISERROR('Fecha inválida. Use ''YYYYMMDD'' o una fecha válida.',16,1);
       RETURN;
  END

  -- Ventana sargable del día
  DECLARE @Fini DATETIME = DATEADD(DAY, DATEDIFF(DAY, 0, @FechaDT), 0);
  DECLARE @Ffin DATETIME = DATEADD(DAY, 1, @Fini);

  ---------------------------------------------------------------------------
  -- 2) Resolver filtro a un conjunto chico de legajos/usuarios (#Incl)
  ---------------------------------------------------------------------------
  DECLARE @LegajoNum INT = NULL;
  IF @Filtro NOT LIKE '%[^0-9]%' AND LEN(@Filtro) > 0
  BEGIN
    BEGIN TRY SET @LegajoNum = CAST(@Filtro AS INT); END TRY
    BEGIN CATCH SET @LegajoNum = NULL; END CATCH
  END

  DECLARE @ExisteUsuarioExacto BIT =
    CASE WHEN EXISTS(SELECT 1 FROM TareasNetMs..Usuarios WHERE Usuario = @Filtro) THEN 1 ELSE 0 END;
  DECLARE @EsMailExacto BIT =
    CASE WHEN CHARINDEX('@', @Filtro) > 0 AND CHARINDEX('%', @Filtro)=0 AND CHARINDEX('_', @Filtro)=0 THEN 1 ELSE 0 END;

  CREATE TABLE #Incl(
    NroLegajo INT NOT NULL PRIMARY KEY
  );

  DECLARE @sql NVARCHAR(MAX) = N'
    INSERT INTO #Incl(NroLegajo)
    SELECT L.NroLegajo
    FROM  TareasNetMs..Legajos  L
    LEFT  JOIN TareasNetMs..Usuarios U ON U.UsuarioID = L.UsuarioID
    WHERE ' + CASE WHEN @SoloActivos=1 THEN N'L.Activo = 1 AND ' ELSE N'' END;

  IF @Filtro = 'Todos'
    SET @sql += N'1 = 1';
  ELSE IF @Filtro = 'Desarrollo'
    SET @sql += N'L.SectorID IN (1,8)';
  ELSE IF @LegajoNum IS NOT NULL
    SET @sql += N'L.NroLegajo = @LegajoNum';
  ELSE IF @ExisteUsuarioExacto = 1
    SET @sql += N'U.Usuario = @Filtro';
  ELSE IF @EsMailExacto = 1
    SET @sql += N'U.Mail = @Filtro';
  ELSE
    SET @sql += N'(L.ApeyNom COLLATE SQL_Latin1_General_CP1_CI_AI LIKE ''%'' + @Filtro + ''%'' OR U.Mail LIKE ''%'' + @Filtro + ''%'')';

  EXEC sp_executesql @sql, N'@Filtro VARCHAR(200), @LegajoNum INT', @Filtro=@Filtro, @LegajoNum=@LegajoNum;

  IF NOT EXISTS(SELECT 1 FROM #Incl)
  BEGIN
    SELECT TOP (0)
      NroLegajo   = CAST(NULL AS INT),
      Fecha       = CAST(NULL AS DATETIME),
      Item        = CAST(NULL AS INT),
      ClienteID   = CAST(NULL AS INT),
      RazonSocial = CAST(NULL AS VARCHAR(200)),
      ProyectoID  = CAST(NULL AS INT),
      DescProyecto= CAST(NULL AS VARCHAR(200)),
      ActividadID = CAST(NULL AS INT),
      DescActividad = CAST(NULL AS VARCHAR(200)),
      TipoTareaID = CAST(NULL AS INT),
      DescTipoTarea= CAST(NULL AS VARCHAR(200)),
      HoraDesde   = CAST(NULL AS DATETIME),
      HoraHasta   = CAST(NULL AS DATETIME),
      Horas       = CAST(NULL AS DECIMAL(18,2)),
      TipoDocID   = CAST(NULL AS INT),
      DescTipoDoc = CAST(NULL AS VARCHAR(200)),
      NroDocID    = CAST(NULL AS INT),
      DescripTarea= CAST(NULL AS VARCHAR(500)),
      NoFacturar  = CAST(NULL AS BIT),
      SucOrdenFact= CAST(NULL AS INT),
      NroOrdenFact= CAST(NULL AS INT),
      IdRegistroDBF=CAST(NULL AS INT),
      Reimputado  = CAST(NULL AS INT),
      Revision    = CAST(NULL AS INT),
      Alarma      = CAST(NULL AS INT),
      Autoriza    = CAST(NULL AS INT),
      Fuera       = CAST(NULL AS INT),
      SoloLectura = CAST(NULL AS INT),
      NoPermiteHorasSinActInc = CAST(NULL AS BIT);
    RETURN;
  END

  ---------------------------------------------------------------------------
  -- 3) Consulta principal (JOIN por #Incl y filtro de fecha sargable)
  ---------------------------------------------------------------------------
  SELECT
          HD.NroLegajo,
          HD.Fecha,
          HD.Item,
          HD.ClienteID,
          CL.RazonSocial,
          HD.ProyectoID,
          PR.Descripcion   AS DescProyecto,
          HD.ActividadID,
          AC.Descripcion   AS DescActividad,
          HD.TipoTareaID,
          TT.Descripcion   AS DescTipoTarea,
          HD.HoraDesde,
          HD.HoraHasta,
          HD.Horas,
          HD.TipoDocID,
          TD.Descripcion   AS DescTipoDoc,
          HD.NroDocID,
          HD.DescripTarea,
          NoFacturar = CONVERT(BIT, ISNULL(HD.NoFacturar, 0)),
          HD.SucOrdenFact,
          HD.NroOrdenFact,
          HD.IdRegistroDBF,
          HD.Reimputado,
          HD.Revision,
          HD.Alarma,
          HD.Autoriza,
          HD.Fuera,
          SoloLectura = CONVERT(INT, CASE
              WHEN HD.NroOrdenFact IS NOT NULL THEN 1
              WHEN (ISNULL(EP.Terminado, 0) = 1 OR ISNULL(EP.PermiteCargarHoras, 0) = 0) THEN 2
              WHEN (ISNULL(EA.Terminada, 0) = 1 OR ISNULL(EP.PermiteCargarHoras, 0) = 0) THEN 3
              WHEN HD.ActividadID IS NOT NULL
                   AND ISNULL(AC.ActividadGlobal, 0) = 0
                   AND ISNULL(L.Externo, 0) = 0
                   AND NOT EXISTS (SELECT 1
                                   FROM ActividadesLegajos AL
                                   WHERE AL.ActividadID = HD.ActividadID
                                     AND AL.NroLegajo   = HD.NroLegajo) THEN 4
              ELSE 0
          END),
          -- REF001
          NoPermiteHorasSinActInc = CONVERT(BIT, ISNULL(PR.NoPermiteHorasSinActInc, 0))
  FROM       HorasDet          AS HD
  INNER JOIN #Incl             AS I   ON I.NroLegajo = HD.NroLegajo
  INNER JOIN Legajos           AS L   ON L.NroLegajo = HD.NroLegajo
  INNER JOIN Clientes          AS CL  ON CL.ClienteID = HD.ClienteID
  INNER JOIN Proyectos         AS PR  ON PR.ProyectoID = HD.ProyectoID
  INNER JOIN EstadosProyecto   AS EP  ON EP.EstadoProyectoID = PR.EstadoProyectoID
  LEFT  JOIN Actividades       AS AC  ON AC.ActividadID = HD.ActividadID
  LEFT  JOIN EstadosActividad  AS EA  ON EA.EstadoActividadID = AC.EstadoActividadID
  INNER JOIN TipoTarea         AS TT  ON TT.TipoTareaID = HD.TipoTareaID
  LEFT  JOIN TiposDoc          AS TD  ON TD.TipoDocID = HD.TipoDocID
  WHERE HD.Fecha >= @Fini
    AND  HD.Fecha <  @Ffin
  ORDER BY HD.Item;
END
GO
