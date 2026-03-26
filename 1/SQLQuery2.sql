SELECT
	CAC.period_from_calc,
	CAC.payment_size
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
    B.ISIN = 'RU000A10ECK5'
ORDER BY
	CAC.period_from_calc;