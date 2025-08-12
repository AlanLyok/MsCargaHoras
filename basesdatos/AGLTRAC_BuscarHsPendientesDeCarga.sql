-- Ejemplos:
-- EXEC dbo.AGLTRAC_BuscarHsPendientesDeCarga @Filtro='113';
-- EXEC dbo.AGLTRAC_BuscarHsPendientesDeCarga @Filtro='alan';
-- EXEC dbo.AGLTRAC_BuscarHsPendientesDeCarga @Filtro='Desarrollo';
-- EXEC dbo.AGLTRAC_BuscarHsPendientesDeCarga @Filtro='Todos';

ALTER PROC dbo.AGLTRAC_BuscarHsPendientesDeCarga
  @Filtro      VARCHAR(200) = 'Desarrollo',   -- número, nombre, usuario, 'Todos' o 'Desarrollo'
  @SoloActivos BIT          = 1,
  @DiasAtras   INT          = 30
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @fechaini DATETIME = DATEADD(DAY, -@DiasAtras, GETDATE());
  DECLARE @fechafin DATETIME = GETDATE();
  DECLARE @baseExcluidos VARCHAR(MAX) = ',82,210,1017,160,';  -- los de siempre

  ------------------------------------------------------------------
  -- 1) Resolver el filtro a un conjunto chico de legajos/usuarios
  ------------------------------------------------------------------
  DECLARE @LegajoNum INT = NULL;
  IF @Filtro NOT LIKE '%[^0-9]%' AND LEN(@Filtro)>0
  BEGIN
    BEGIN TRY SET @LegajoNum = CAST(@Filtro AS INT); END TRY
    BEGIN CATCH SET @LegajoNum = NULL; END CATCH
  END

  DECLARE @ExisteUsuarioExacto BIT =
    CASE WHEN EXISTS(SELECT 1 FROM TareasNetMs..Usuarios WHERE Usuario=@Filtro) THEN 1 ELSE 0 END;
  DECLARE @EsMailExacto BIT =
    CASE WHEN CHARINDEX('@',@Filtro)>0 AND CHARINDEX('%',@Filtro)=0 AND CHARINDEX('_',@Filtro)=0 THEN 1 ELSE 0 END;

  CREATE TABLE #Incl(
    NroLegajo INT        NOT NULL PRIMARY KEY,
    ApeyNom   VARCHAR(200) NULL,
    Usuario   VARCHAR(200) NULL,
    Mail      VARCHAR(200) NULL,
    SectorID  INT          NULL
  );

  DECLARE @sql NVARCHAR(MAX) = N'
    INSERT INTO #Incl(NroLegajo,ApeyNom,Usuario,Mail,SectorID)
    SELECT L.NroLegajo, L.ApeyNom, U.Usuario, U.Mail, L.SectorID
    FROM  TareasNetMs..Legajos  L
    LEFT  JOIN TareasNetMs..Usuarios U ON U.UsuarioID = L.UsuarioID
    WHERE ' + CASE WHEN @SoloActivos=1 THEN N'L.Activo=1 AND ' ELSE N'' END;

  IF @Filtro='Todos'
    SET @sql += N'1=1';
  ELSE IF @Filtro='Desarrollo'
    SET @sql += N'L.SectorID IN (1,8)';
  ELSE IF @LegajoNum IS NOT NULL
    SET @sql += N'L.NroLegajo = @LegajoNum';
  ELSE IF @ExisteUsuarioExacto=1
    SET @sql += N'U.Usuario = @Filtro';
  ELSE IF @EsMailExacto=1
    SET @sql += N'U.Mail = @Filtro';
  ELSE
    SET @sql += N'(L.ApeyNom COLLATE SQL_Latin1_General_CP1_CI_AI LIKE ''%'' + @Filtro + ''%'' OR U.Mail LIKE ''%'' + @Filtro + ''%'')';

  EXEC sp_executesql @sql, N'@Filtro VARCHAR(200), @LegajoNum INT', @Filtro=@Filtro, @LegajoNum=@LegajoNum;

  -- Si no matchea nadie, salimos rápido
  IF NOT EXISTS (SELECT 1 FROM #Incl)
  BEGIN
    SELECT TOP 0
      CAST(NULL AS VARCHAR(50))  AS Dia,
      CAST(NULL AS VARCHAR(10))  AS FechaCarga,
      CAST(NULL AS VARCHAR(10))  AS [Falta Cargar],
      CAST(NULL AS INT)          AS Legajo,
      CAST(NULL AS VARCHAR(200)) AS ApeyNom,
      CAST(NULL AS INT)          AS SectorID,
      CAST(NULL AS VARCHAR(200)) AS Usuario,
      CAST(NULL AS VARCHAR(200)) AS Mail;
    RETURN;
  END

  ------------------------------------------------------------------
  -- 2) Empujar filtro al proc de horas vía lista de EXCLUIDOS
  --    (si #Incl es chico, excluimos el resto para que devuelva poco)
  ------------------------------------------------------------------
  DECLARE @cnt_all INT, @cnt_inc INT;
  SELECT @cnt_all = COUNT(*) FROM TareasNetMs..Legajos L WHERE (@SoloActivos=0 OR L.Activo=1);
  SELECT @cnt_inc = COUNT(*) FROM #Incl;

  DECLARE @extraExcluidos NVARCHAR(MAX) = N'';
  IF (@cnt_inc * 2) < @cnt_all  -- menos de la mitad: conviene excluir el resto
  BEGIN
    SELECT @extraExcluidos = STUFF((
      SELECT ',' + CAST(L.NroLegajo AS VARCHAR(10))
      FROM TareasNetMs..Legajos L
      WHERE (@SoloActivos=0 OR L.Activo=1)
        AND NOT EXISTS (SELECT 1 FROM #Incl I WHERE I.NroLegajo=L.NroLegajo)
      FOR XML PATH(''), TYPE).value('.','nvarchar(max)'),1,1,'');
  END

  DECLARE @legajosExcluidos VARCHAR(MAX) =
      @baseExcluidos + ISNULL(@extraExcluidos,'');

  ------------------------------------------------------------------
  -- 3) Ejecutar proc y filtrar con JOIN a #Incl (sin OR en WHERE)
  ------------------------------------------------------------------
  CREATE TABLE #temp(
    Legajo INT,
    [Apellido y Nombre] VARCHAR(200),
    Dia VARCHAR(50),
    FechaCarga VARCHAR(10),
    [Falta Cargar] VARCHAR(10)
  );

  INSERT INTO #temp
    EXEC TareasNetMs.dbo.ControlHoras_GustavoVillon @fechaini, @fechafin, @legajosExcluidos;

  CREATE INDEX IX_temp_Legajo ON #temp(Legajo);  -- acelera el join

  SELECT
      t.Dia,
      t.FechaCarga,
      t.[Falta Cargar],
      i.NroLegajo AS Legajo,
      i.ApeyNom,
      i.SectorID,
      i.Usuario,
      i.Mail
  FROM #temp AS t
  JOIN #Incl AS i ON i.NroLegajo = t.Legajo
  ORDER BY i.ApeyNom;

  DROP TABLE #temp;
  DROP TABLE #Incl;
END
GO
