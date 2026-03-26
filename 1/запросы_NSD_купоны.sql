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

