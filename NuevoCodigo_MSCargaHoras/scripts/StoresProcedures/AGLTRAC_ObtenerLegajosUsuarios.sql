-- Ejemplos
-- EXEC dbo.AGLTRAC_ObtenerLegajosUsuarios @Filtro='alan';
-- EXEC dbo.AGLTRAC_ObtenerLegajosUsuarios @Filtro='113';
-- EXEC dbo.AGLTRAC_ObtenerLegajosUsuarios @Filtro='Todos';
-- EXEC dbo.AGLTRAC_ObtenerLegajosUsuarios @Filtro='Desarrollo';

ALTER PROC dbo.AGLTRAC_ObtenerLegajosUsuarios
  @Filtro      VARCHAR(200) = 'Desarrollo',   -- número, nombre, usuario, 'Todos' o 'Desarrollo'
  @SoloActivos BIT = 1
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @LegajoNum INT = NULL;
  IF @Filtro NOT LIKE '%[^0-9]%' AND LEN(@Filtro) > 0
  BEGIN
    BEGIN TRY SET @LegajoNum = CAST(@Filtro AS INT); END TRY
    BEGIN CATCH SET @LegajoNum = NULL; END CATCH
  END

  -- ¿Existe un usuario exacto igual al filtro? (optimiza ese caso)
  DECLARE @ExisteUsuarioExacto BIT =
    CASE WHEN EXISTS (SELECT 1 FROM TareasNetMs..Usuarios WHERE Usuario = @Filtro) THEN 1 ELSE 0 END;

  -- ¿El filtro parece mail sin comodines? (optimiza igualdad por mail)
  DECLARE @EsMailExacto BIT =
    CASE WHEN CHARINDEX('@', @Filtro) > 0 AND CHARINDEX('%', @Filtro) = 0 AND CHARINDEX('_', @Filtro) = 0
         THEN 1 ELSE 0 END;

  DECLARE @sql NVARCHAR(MAX) = N'
    SELECT L.NroLegajo, L.ApeyNom, U.Usuario, U.Mail
    FROM  TareasNetMs..Legajos  AS L
    LEFT  JOIN TareasNetMs..Usuarios AS U ON U.UsuarioID = L.UsuarioID
    WHERE ' + CASE WHEN @SoloActivos = 1 THEN N'L.Activo = 1 AND ' ELSE N'' END;

  IF @Filtro = 'Todos'
    SET @sql += N'1=1 ';
  ELSE IF @Filtro = 'Desarrollo'
    SET @sql += N'L.SectorID IN (1,8) ';
  ELSE IF @LegajoNum IS NOT NULL
    SET @sql += N'L.NroLegajo = @LegajoNum ';
  ELSE IF @ExisteUsuarioExacto = 1
    SET @sql += N'U.Usuario = @Filtro ';
  ELSE IF @EsMailExacto = 1
    SET @sql += N'U.Mail = @Filtro ';
  ELSE
    -- Búsqueda “difusa”: nombre (sin acentos/mayúsculas) o mail por patrón
    SET @sql += N'(L.ApeyNom COLLATE SQL_Latin1_General_CP1_CI_AI LIKE ''%'' + @Filtro + ''%'' OR U.Mail LIKE ''%'' + @Filtro + ''%'') ';

  SET @sql += N' ORDER BY L.ApeyNom;';

  EXEC sp_executesql
       @sql,
       N'@Filtro VARCHAR(200), @LegajoNum INT',
       @Filtro=@Filtro, @LegajoNum=@LegajoNum;
END
GO
