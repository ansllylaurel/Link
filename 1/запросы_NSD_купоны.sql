/* 
  Запросы для просмотра данных НРД (NSD) по купонам.

  Важно:
  - В правилах импорта используется 4-х частное имя:
      [LS_APPSERV].[MatriX_External].[NSD]....
    значит таблицы читаются через linked server LS_APPSERV.
  - Выполняйте запросы в SSMS/SQL Manager в контексте базы, где существует linked server LS_APPSERV
    (часто это база ReferenceBooks, как в строке соединения правил импорта).
*/

/* ============================================================
   1) Основной запрос: купоны + корпоративные действия (как в ТЗ)
   ============================================================ */
SELECT TOP (500)
    CAC.*,
    CA.*
FROM [LS_APPSERV].[MatriX_External].[NSD].[Corporate_Actions_Coupons] AS CAC
INNER JOIN [LS_APPSERV].[MatriX_External].[NSD].[Corporate_Actions] AS CA
    ON CA.action_id = CAC.action_id;


/* ============================================================
   2) То же, но исключаем отменённые действия (как в Template.txt)
   ============================================================ */
SELECT TOP (500)
    CAC.*,
    CA.*
FROM [LS_APPSERV].[MatriX_External].[NSD].[Corporate_Actions_Coupons] AS CAC
INNER JOIN [LS_APPSERV].[MatriX_External].[NSD].[Corporate_Actions] AS CA
    ON CA.action_id = CAC.action_id
   AND CA.action_state_code <> 'C';


/* ============================================================
   3) Проверка структуры: какие колонки есть в таблицах
   ============================================================ */
SELECT TOP (0) *
FROM [LS_APPSERV].[MatriX_External].[NSD].[Corporate_Actions_Coupons];

SELECT TOP (0) *
FROM [LS_APPSERV].[MatriX_External].[NSD].[Corporate_Actions];


/* ============================================================
   4) Пример "точечной" выборки по одному Action_ID (подставьте значение)
   ============================================================ */
DECLARE @ActionId BIGINT = NULL; -- TODO: поставьте конкретный action_id

SELECT TOP (500)
    CAC.*,
    CA.*
FROM [LS_APPSERV].[MatriX_External].[NSD].[Corporate_Actions_Coupons] AS CAC
INNER JOIN [LS_APPSERV].[MatriX_External].[NSD].[Corporate_Actions] AS CA
    ON CA.action_id = CAC.action_id
WHERE (@ActionId IS NULL OR CAC.action_id = @ActionId);

/* ============================================================
   4.1) Поиск по ISIN облигации

   Логика как в правилах импорта:
   ISIN -> Migration.AM.vw_Bonds (BondID)
   BondID -> MatriX.dbo.vw_Securities_Codes (Type_UID = 'Securities.Code.NSD') -> NSD.Securities (code_nsd)
   NSD.Securities.id -> NSD.Corporate_Actions_Coupons.security_id -> NSD.Corporate_Actions
   ============================================================ */
DECLARE @ISIN NVARCHAR(32) = NULL; -- TODO: например 'RU000A0JX0J2'

SELECT TOP (500)
    B.BondID,
    B.ISIN,
    Nsd_codes.Code            AS NSD_Code,
    NSD_Securities.id         AS NSD_Security_ID,
    CAC.*,
    CA.*
FROM [Migration].[AM].[vw_Bonds] AS B
LEFT JOIN MatriX.dbo.vw_Securities_Codes AS Nsd_codes
    ON Nsd_codes.Security_ID = B.BondID
   AND Nsd_codes.Type_UID = 'Securities.Code.NSD'
   AND Nsd_codes.Is_Export = 1
LEFT JOIN [LS_APPSERV].[MatriX_External].[NSD].[Securities] AS NSD_Securities
    ON NSD_Securities.code_nsd = Nsd_codes.Code
LEFT JOIN [LS_APPSERV].[MatriX_External].[NSD].[Corporate_Actions_Coupons] AS CAC
    ON CAC.Security_id = NSD_Securities.id
LEFT JOIN [LS_APPSERV].[MatriX_External].[NSD].[Corporate_Actions] AS CA
    ON CA.action_id = CAC.action_id
WHERE
    (@ISIN IS NULL OR LTRIM(RTRIM(B.ISIN)) = LTRIM(RTRIM(@ISIN)))
ORDER BY
    B.BondID,
    CAC.period_from_calc;


/* ============================================================
   5) Запасной вариант (если вы подключены напрямую к MatriX_External)
      Используйте только если:
      - вы подключились к SQL серверу, где база MatriX_External доступна напрямую
      - и схема NSD существует в этой базе
   ============================================================ */
-- USE [MatriX_External];
-- GO
-- SELECT TOP (500)
--     CAC.*,
--     CA.*
-- FROM [NSD].[Corporate_Actions_Coupons] AS CAC
-- INNER JOIN [NSD].[Corporate_Actions] AS CA
--     ON CA.action_id = CAC.action_id;

