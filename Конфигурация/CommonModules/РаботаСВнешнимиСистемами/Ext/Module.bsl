////////////////////////////////////////////////////////////////////////////////
// ВЗАИМОДЕЙСТВИЕ С МАТРИКС

// Функция - Возвращает результаты сверки юр./физ. лиц со списком террористов
// 
// Параметры:
//	ПроверяемыеЛица	 - Массив - (Необязательный) Содержит массив проверяемых юр./физ. лиц
//						Если не указан, проводится сверка по полному списку юр./физ. лиц
//	ОшибкиСверки	 - Структура - (Необязательный, Выходной) В случае ошибок сверки возвращает структуру с описанием ошибок
//						Может содержать именованные таблицы:
//						- НеПроверенныеЛица: Ссылка (СправочникСсылка.ЮрФизЛица), Код (Строка), Категория (Строка)
//						- ОшибкиПоискаКодаВоВнешнейСистеме: Ссылка (СправочникСсылка.ЮрФизЛица)   
// 
// Возвращаемое значение:
//	ТаблицаЗначений, Неопределено - таблица успешно прошедших проверку лиц, Неопределено - в случае ошибки
//									Структура таблицы: ЮрФизЛицо (СправочникСсылка.ЮрФизЛица), Пройдена (Булево), Комментарий (Строка)
//
//
Функция ПолучитьРезультатСверкиСоСпискомТеррористовВMatrix(ПроверяемыеЛица = Неопределено, ОшибкиСверки = Неопределено) Экспорт	
	Перем ПроверенныеЛица; 	
	
	// Инициализация вспомогательных переменных
	ПорогТревоги		= 5;	
	СтрокаСоединения	= СтрокаСоединенияСМатрих();
	ПараметрыСоединения = Новый Структура("CommandTimeout", 180);	
	РазмерПакета		= 300; // Количество отправляемых на проверку лиц
	
#Область ШаблонЗапроса	
	ШаблонЗапроса		= "
		|SET NOCOUNT ON
		|;
		|
		|IF OBJECT_ID('tempdb..#Partners') IS NOT NULL
		|	Drop Table #Partners
		|;
		|IF OBJECT_ID('tempdb..#SuspectPartners') IS NOT NULL
		|	Drop Table #SuspectPartners
		|;		
		|IF OBJECT_ID('tempdb..#LastTerroristsList') IS NOT NULL
		|	Drop Table #LastTerroristsList
		|;	
		|
		|CREATE TABLE #Partners(
		|	Row_Index bigint IDENTITY(1,1),
		|	Data_Source nvarchar(15),
		|	Partner_ID nvarchar(9),
		|	Is_Firm bit,
		|	INN nvarchar(12),
		|	Birth_Date date,
		|	Name_Ru_Clean nvarchar(4000),
		|	Name_Ru nvarchar(4000),
		|	Name_En_Clean nvarchar(4000),
		|	Name_En nvarchar(4000),
		|	Address_Legal_Clean nvarchar(4000),
		|	Address_Legal nvarchar(4000),
		|	Address_Post_Clean nvarchar(4000),
		|	Address_Post nvarchar(4000),
		|	Document_Series nvarchar(4000),
		|	Document_Number nvarchar(4000),
		|	Document_Date date,
		|	Document_Issuer_Clean nvarchar(4000),
		|	Document_Issuer nvarchar(4000),
		|	КлючСтрокиСверки nvarchar(36)
		|	--,INDEX ix_Is_Firm NONCLUSTERED (Is_Firm)
		|	--,INDEX ix_INN NONCLUSTERED (INN)
		|	--,INDEX ix_Birth_Date NONCLUSTERED (Birth_Date)
		|	--,INDEX ix_Document_Series_Number NONCLUSTERED (Document_Series, Document_Number)
		|	--,INDEX ix_Document_Date NONCLUSTERED (Document_Date)
		|)
		|;
		|
		|INSERT INTO
		|	#Partners
		|SELECT		
		|	Data_Source,
		|	Partner_ID,
		|	Is_Firm,
		|	INN,
		|	Birth_Date,
		|	Name_Ru_Clean = dbo.udf_FEDSFM_Strings_Clean(Name_Ru),
		|	Name_Ru,
		|	Name_En_Clean = dbo.udf_FEDSFM_Strings_Clean(Name_En),
		|	Name_En,
		|	Address_Legal_Clean = dbo.udf_FEDSFM_Strings_Clean(Address_Legal),
		|	Address_Legal,
		|	Address_Post_Clean = dbo.udf_FEDSFM_Strings_Clean(Address_Post),
		|	Address_Post,
		|	Document_Series,
		|	Document_Number,
		|	Document_Date,
		|	Document_Issuer_Clean = dbo.udf_FEDSFM_Strings_Clean(Document_Issuer),
		|	Document_Issuer,
		|	КлючСтрокиСверки
		|FROM (
		|	&Партнеры
		|) Partners
		|; 
		|
		|SELECT TOP 1
		|	TempTerroristsLists.ID,
		|	TempTerroristsLists.Date
		|INTO
		|	#LastTerroristsList		
		|FROM
		|	MatriX.dbo.FEDSFM_Terrorists_Lists [TempTerroristsLists]
		|	INNER JOIN MatriX.dbo.Enums_Values [ListTypeTerrorists]
		|		ON ListTypeTerrorists.UID = 'FEDSFM.Lists.Terrorists'
		|			AND ListTypeTerrorists.ID = TempTerroristsLists.Type
		|ORDER BY
		|	TempTerroristsLists.Date DESC
		|;
		|
		|SELECT
		|	[Row_Index] = P.Row_Index,
		|	[Data_Source] = P.Data_Source,
		|	[Partner_ID] = P.Partner_ID,
		|	[TerroristList_Date] = LastTerroristsList.Date,
		|	[Terrorist_ID] = T.ID,
		|	[Terrorist_Name] = T.NAMEU,
		|	[Intersections] = 
		|		CASE WHEN (CASE WHEN T.TU = 3 THEN 0 ELSE 1 END) = P.Is_Firm 
		|			THEN (CASE WHEN T.ND = P.INN THEN 'ИНН, ' ELSE '' END)
		|					+ (CASE WHEN T.Address_Legal_Clean = P.Address_Legal_Clean AND T.Address_Legal_Clean <> '' THEN 'Юридический адрес, ' ELSE '' END)
		|					+ (CASE WHEN T.Address_Post_Clean = P.Address_Post_Clean AND T.Address_Post_Clean <> '' THEN 'Почтовый адрес, ' ELSE '' END)
		|					+ (CASE WHEN T.GR = P.Birth_Date AND T.TU = 3 THEN 'Дата рождения, ' ELSE '' END)
		|					+ (CASE WHEN T.CB_DATE = P.Document_Date AND T.TU = 3 THEN 'Дата выдачи ДУЛ, ' ELSE '' END)
		|					+ (CASE WHEN T.SD = P.Document_Series AND T.RG = P.Document_Number AND T.TU = 3 THEN 'Серия и номер ДУЛ, ' ELSE '' END)
		|					+ (CASE WHEN CharIndex(P.Document_Issuer_Clean, T.Document_Issuer_Clean) > 0 AND Len(P.Document_Issuer_Clean) > 10 AND T.TU = 3 THEN 'Орган выдавший ДУЛ, ' ELSE '' END)
		|					+ (CASE WHEN CharIndex(P.Name_Ru_Clean, T.Name_Clean) > 0 OR CharIndex(P.Name_En_Clean, T.Name_Clean) > 0 THEN 'Полное наименование, ' ELSE '' END)
		|			ELSE ''
		|		END,
		|	[Sum_Rank] = 
		|		CASE WHEN (CASE WHEN T.TU = 3 THEN 0 ELSE 1 END) = P.Is_Firm 
		|			THEN (CASE WHEN T.ND = P.INN THEN 5 ELSE 0 END)
		|					+ (CASE WHEN T.Address_Legal_Clean = P.Address_Legal_Clean AND T.Address_Legal_Clean <> '' THEN 3 ELSE 0 END)
		|					+ (CASE WHEN T.Address_Post_Clean = P.Address_Post_Clean AND T.Address_Post_Clean <> '' THEN 3 ELSE 0 END)
		|					+ (CASE WHEN T.GR = P.Birth_Date AND T.TU = 3 THEN 1 ELSE 0 END)
		|					+ (CASE WHEN T.CB_DATE = P.Document_Date AND T.TU = 3 THEN 1 ELSE 0 END)
		|					+ (CASE WHEN T.SD = P.Document_Series AND T.RG = P.Document_Number AND T.TU = 3 THEN 5 ELSE 0 END)
		|					+ (CASE WHEN CharIndex(P.Document_Issuer_Clean, T.Document_Issuer_Clean) > 0 AND Len(P.Document_Issuer_Clean) > 10 AND T.TU = 3 THEN 3 ELSE 0 END)
		|					+ (CASE WHEN CharIndex(P.Name_Ru_Clean, T.Name_Clean) > 0 OR CharIndex(P.Name_En_Clean, T.Name_Clean) > 0 THEN 3 ELSE 0 END)
		|			ELSE 0
		|		END
		|INTO
		|	#SuspectPartners
		|FROM #Partners as P
		|	INNER JOIN MatriX.dbo.FEDSFM_Terrorists_Lists_Details [T]
		|		INNER JOIN MatriX.dbo.FEDSFM_Terrorists_Lists [TerroristsLists]
		|			INNER JOIN #LastTerroristsList [LastTerroristsList]
		|			ON LastTerroristsList.ID = TerroristsLists.ID
		|		ON TerroristsLists.ID = T.List_ID
		|	ON
		|		(CASE WHEN T.TU = 3 THEN 0 ELSE 1 END) = P.Is_Firm AND (
		|			T.ND = P.INN
		|			OR (T.Address_Legal_Clean = P.Address_Legal_Clean AND T.Address_Legal_Clean <> '')
		|			OR (T.Address_Post_Clean = P.Address_Post_Clean AND T.Address_Post_Clean <> '')
		|			OR (T.GR = P.Birth_Date AND T.TU = 3)
		|			OR (T.CB_DATE = P.Document_Date AND T.TU = 3)
		|			OR (T.SD = P.Document_Series AND T.RG = P.Document_Number AND T.TU = 3)
		|			OR (CharIndex(P.Document_Issuer_Clean, T.Document_Issuer_Clean) > 0 AND Len(P.Document_Issuer_Clean) > 10 AND T.TU = 3)
		|			OR (CharIndex(P.Name_Ru_Clean, T.Name_Clean) > 0 OR CharIndex(P.Name_En_Clean, T.Name_Clean) > 0)
		|		)
		|WHERE
		|	CASE WHEN (CASE WHEN T.TU = 3 THEN 0 ELSE 1 END) = P.Is_Firm 
		|		THEN (CASE WHEN T.ND = P.INN THEN 5 ELSE 0 END)
		|				+ (CASE WHEN T.Address_Legal_Clean = P.Address_Legal_Clean AND T.Address_Legal_Clean <> '' THEN 3 ELSE 0 END)
		|				+ (CASE WHEN T.Address_Post_Clean = P.Address_Post_Clean AND T.Address_Post_Clean <> '' THEN 3 ELSE 0 END)
		|				+ (CASE WHEN T.GR = P.Birth_Date AND T.TU = 3 THEN 1 ELSE 0 END)
		|				+ (CASE WHEN T.CB_DATE = P.Document_Date AND T.TU = 3 THEN 1 ELSE 0 END)
		|				+ (CASE WHEN T.SD = P.Document_Series AND T.RG = P.Document_Number AND T.TU = 3 THEN 5 ELSE 0 END)
		|				+ (CASE WHEN CharIndex(P.Document_Issuer_Clean, T.Document_Issuer_Clean) > 0 AND Len(P.Document_Issuer_Clean) > 10 AND T.TU = 3 THEN 3 ELSE 0 END)
		|				+ (CASE WHEN CharIndex(P.Name_Ru_Clean, T.Name_Clean) > 0 OR CharIndex(P.Name_En_Clean, T.Name_Clean) > 0 THEN 3 ELSE 0 END)
		|		ELSE 0
		|	END >= &ПорогТревоги
		|;
		|
		|SELECT DISTINCT
		|	[ИдентификаторЛица] = Partners.Partner_ID,
		|	[Пройдена] = 
		|		CASE
		|			WHEN SuspectPartners.Partner_ID IS NULL
		|				THEN 1
		|			ELSE 0
		|		END,
		|	[Комментарий] = 
		|		'Список от ' + CONVERT(nvarchar(10), LastTerroristsList.Date, 104) + 				
		|		CASE
		|			WHEN SuspectPartners.Partner_ID IS NOT NULL
		|				THEN ', пересечения по данным ' + SuspectPartners.Data_Source
		|					+ ' с [' + CAST(SuspectPartners.Terrorist_ID  AS nvarchar(9)) + '] '
		|					+ SuspectPartners.Terrorist_Name + ' по ' + SuspectPartners.Intersections
		|					+ 'суммарная оценка ' + CAST(SuspectPartners.Sum_Rank AS nvarchar(3))     
		|			ELSE ''
		|		END,
		|	[ИдентификаторСписка] = LastTerroristsList.ID,
		|	КлючСтрокиСверки = [Partners].КлючСтрокиСверки
		|FROM #Partners [Partners] 
		|	LEFT JOIN #SuspectPartners [SuspectPartners]
		|		INNER JOIN (
		|			SELECT
		|				SuspectPartnersForRow.Partner_ID,
		|				MAX(SuspectPartnersForRow.Row_Index) [Max_Row]	
		|			FROM
		|				#SuspectPartners [SuspectPartnersForRow]	
		|				INNER JOIN (
		|					SELECT
		|						SuspectPartnersForRank.Partner_ID,
		|						MAX(SuspectPartnersForRank.Sum_Rank) [Sum_Rank]
		|					FROM #SuspectPartners [SuspectPartnersForRank]
		|					GROUP BY
		|						SuspectPartnersForRank.Partner_ID
		|				) [MaxRankSuspicion]
		|				ON MaxRankSuspicion.Partner_ID = SuspectPartnersForRow.Partner_ID
		|					AND MaxRankSuspicion.Sum_Rank = SuspectPartnersForRow.Sum_Rank
		|			GROUP BY
		|				SuspectPartnersForRow.Partner_ID	
		|		) [SuspectPartnersCleared]
		|		ON SuspectPartnersCleared.Partner_ID =  SuspectPartners.Partner_ID
		|			AND SuspectPartnersCleared.Max_Row =  SuspectPartners.Row_Index
		|	ON SuspectPartners.Partner_ID = Partners.Partner_ID,
		|	#LastTerroristsList [LastTerroristsList]
		|;
		|
		|IF OBJECT_ID('tempdb..#Partners') IS NOT NULL
		|	Drop Table #Partners
		|;
		|IF OBJECT_ID('tempdb..#SuspectPartners') IS NOT NULL
		|	Drop Table #SuspectPartners
		|;		
		|IF OBJECT_ID('tempdb..#LastTerroristsList') IS NOT NULL
		|	Drop Table #LastTerroristsList
		|;	
		|";	
#КонецОбласти
		
	// Подготовим параметр для передачи таблицы на сервер
	Запрос = Новый Запрос;
	
#Область ТекстЗапроса
	Запрос.Текст = 
		"ВЫБРАТЬ РАЗРЕШЕННЫЕ
		|	""ГК Регион"" КАК ИсточникДанных,
		|	ВЫБОР
		|		КОГДА ЮрФизЛица.ВидЮрФизЛица = ЗНАЧЕНИЕ(Перечисление.ВидыЮрФизЛиц.ЮридическоеЛицо)
		|			ТОГДА ""1""
		|		ИНАЧЕ ""0""
		|	КОНЕЦ КАК ЭтоОрганизация,
		|	ЮрФизЛица.Ссылка КАК Ссылка,
		|	ЮрФизЛица.Код КАК Идентификатор,
		|	РеквизитыЮридическихЛицНаРусском.ПолноеНаименованиеПоУставу КАК Наименование,
		|	РеквизитыЮридическихЛицНаАнглийском.ПолноеНаименованиеПоУставу КАК НаименованиеНаАнглийском,
		|	РеквизитыЮридическихЛицНаРусском.ИНН КАК ИНН,
		|	NULL КАК ДатаРождения,
		|	NULL КАК СерияУдостоверенияЛичности,
		|	NULL КАК НомерУдостоверенияЛичности,
		|	NULL КАК ДатаВыдачиУдостоверенияЛичности,
		|	NULL КАК ОрганВыдавшийУдостоверениеЛичности,
		|	ЕСТЬNULL(ЮридическийАдрес.Представление, АдресРегистрации.Представление) КАК ЮридическийАдрес,
		|	ПочтовыйАдрес.Представление КАК ПочтовыйАдрес
		|ИЗ
		|	Справочник.ЮрФизЛица КАК ЮрФизЛица
		|		ЛЕВОЕ СОЕДИНЕНИЕ РегистрСведений.РеквизитыЮридическихЛиц.СрезПоследних(
		|				,
		|				Подразделение = ЗНАЧЕНИЕ(Справочник.Подразделения.ГруппаКомпаний)
		|					И Язык = ЗНАЧЕНИЕ(Справочник.Языки.Русский)
		|					И &ФильтрАнкетПроверяемыхЛиц) КАК РеквизитыЮридическихЛицНаРусском
		|		ПО (РеквизитыЮридическихЛицНаРусском.ЮрФизЛицо = ЮрФизЛица.Ссылка)
		|		ЛЕВОЕ СОЕДИНЕНИЕ РегистрСведений.РеквизитыЮридическихЛиц.СрезПоследних(
		|				,
		|				Подразделение = ЗНАЧЕНИЕ(Справочник.Подразделения.ГруппаКомпаний)
		|					И Язык = ЗНАЧЕНИЕ(Справочник.Языки.Английский)
		|					И &ФильтрАнкетПроверяемыхЛиц) КАК РеквизитыЮридическихЛицНаАнглийском
		|		ПО (РеквизитыЮридическихЛицНаАнглийском.ЮрФизЛицо = ЮрФизЛица.Ссылка)
		|		ЛЕВОЕ СОЕДИНЕНИЕ РегистрСведений.КонтактнаяИнформация.СрезПоследних(
		|				,
		|				Подразделение = ЗНАЧЕНИЕ(Справочник.Подразделения.ГруппаКомпаний)
		|					И Язык = ЗНАЧЕНИЕ(Справочник.Языки.Русский)
		|					И Вид = ЗНАЧЕНИЕ(Справочник.ВидыКонтактнойИнформации.АдресРегистрации)
		|					И &ФильтрКонтактовПроверяемыхЛиц) КАК АдресРегистрации
		|		ПО (АдресРегистрации.Объект = ЮрФизЛица.Ссылка)
		|		ЛЕВОЕ СОЕДИНЕНИЕ РегистрСведений.КонтактнаяИнформация.СрезПоследних(
		|				,
		|				Подразделение = ЗНАЧЕНИЕ(Справочник.Подразделения.ГруппаКомпаний)
		|					И Язык = ЗНАЧЕНИЕ(Справочник.Языки.Русский)
		|					И Вид = ЗНАЧЕНИЕ(Справочник.ВидыКонтактнойИнформации.ЮридическийАдрес)
		|					И &ФильтрКонтактовПроверяемыхЛиц) КАК ЮридическийАдрес
		|		ПО (ЮридическийАдрес.Объект = ЮрФизЛица.Ссылка)
		|		ЛЕВОЕ СОЕДИНЕНИЕ РегистрСведений.КонтактнаяИнформация.СрезПоследних(
		|				,
		|				Подразделение = ЗНАЧЕНИЕ(Справочник.Подразделения.ГруппаКомпаний)
		|					И Язык = ЗНАЧЕНИЕ(Справочник.Языки.Русский)
		|					И Вид = ЗНАЧЕНИЕ(Справочник.ВидыКонтактнойИнформации.ПочтовыйАдрес)
		|					И &ФильтрКонтактовПроверяемыхЛиц) КАК ПочтовыйАдрес
		|		ПО (ПочтовыйАдрес.Объект = ЮрФизЛица.Ссылка)
		|ГДЕ
		|	&ФильтрПроверяемыхЛиц
		|
		|ОБЪЕДИНИТЬ ВСЕ
		|
		|ВЫБРАТЬ
		|	Организации.ПрефиксНумерации,
		|	""1"",
		|	ЮрФизЛица.Ссылка,
		|	ЮрФизЛица.Код,
		|	РеквизитыЮридическихЛицАнкетныеНаРусском.ПолноеНаименованиеПоУставу,
		|	РеквизитыЮридическихЛицАнкетныеНаАнглийском.ПолноеНаименованиеПоУставу,
		|	ЕСТЬNULL(РеквизитыЮридическихЛицАнкетныеНаРусском.ИНН, РеквизитыЮридическихЛицАнкетныеНаАнглийском.ИНН),
		|	NULL,
		|	NULL,
		|	NULL,
		|	NULL,
		|	NULL,
		|	ЕСТЬNULL(РеквизитыЮридическихЛицАнкетныеНаРусском.ЮридическийАдрес, РеквизитыЮридическихЛицАнкетныеНаАнглийском.ЮридическийАдрес),
		|	ЕСТЬNULL(РеквизитыЮридическихЛицАнкетныеНаРусском.ПочтовыйАдрес, РеквизитыЮридическихЛицАнкетныеНаАнглийском.ПочтовыйАдрес)
		|ИЗ
		|	РегистрСведений.РеквизитыЮридическихЛицАнкетные.СрезПоследних(
		|			,
		|			Язык = ЗНАЧЕНИЕ(Справочник.Языки.Русский)
		|				И &ФильтрАнкетПроверяемыхЛиц) КАК РеквизитыЮридическихЛицАнкетныеНаРусском
		|		ПОЛНОЕ СОЕДИНЕНИЕ РегистрСведений.РеквизитыЮридическихЛицАнкетные.СрезПоследних(
		|				,
		|				Язык = ЗНАЧЕНИЕ(Справочник.Языки.Английский)
		|					И &ФильтрАнкетПроверяемыхЛиц) КАК РеквизитыЮридическихЛицАнкетныеНаАнглийском
		|		ПО (РеквизитыЮридическихЛицАнкетныеНаАнглийском.ЮрФизЛицо = РеквизитыЮридическихЛицАнкетныеНаРусском.ЮрФизЛицо)
		|			И (РеквизитыЮридическихЛицАнкетныеНаАнглийском.Организация = РеквизитыЮридическихЛицАнкетныеНаРусском.Организация)
		|		ВНУТРЕННЕЕ СОЕДИНЕНИЕ Справочник.Организации КАК Организации
		|		ПО (Организации.Ссылка = ЕСТЬNULL(РеквизитыЮридическихЛицАнкетныеНаРусском.Организация, РеквизитыЮридическихЛицАнкетныеНаАнглийском.Организация))
		|		ВНУТРЕННЕЕ СОЕДИНЕНИЕ Справочник.ЮрФизЛица КАК ЮрФизЛица
		|		ПО (ЮрФизЛица.Ссылка = ЕСТЬNULL(РеквизитыЮридическихЛицАнкетныеНаРусском.ЮрФизЛицо, РеквизитыЮридическихЛицАнкетныеНаАнглийском.ЮрФизЛицо))
		|ГДЕ
		|	&ФильтрПроверяемыхЛиц
		|
		|ОБЪЕДИНИТЬ ВСЕ
		|
		|ВЫБРАТЬ
		|	Организации.ПрефиксНумерации,
		|	""0"",
		|	ЮрФизЛица.Ссылка,
		|	ЮрФизЛица.Код,
		|	РеквизитыФизическихЛицАнкетныеНаРусском.Фамилия + "" "" + РеквизитыФизическихЛицАнкетныеНаРусском.Имя + "" "" + РеквизитыФизическихЛицАнкетныеНаРусском.Отчество,
		|	РеквизитыФизическихЛицАнкетныеНаАнглийском.Фамилия + "" "" + РеквизитыФизическихЛицАнкетныеНаАнглийском.Имя + "" "" + РеквизитыФизическихЛицАнкетныеНаАнглийском.Отчество,
		|	ЕСТЬNULL(РеквизитыФизическихЛицАнкетныеНаРусском.ИНН, РеквизитыФизическихЛицАнкетныеНаАнглийском.ИНН),
		|	ЕСТЬNULL(РеквизитыФизическихЛицАнкетныеНаРусском.ДатаРождения, РеквизитыФизическихЛицАнкетныеНаАнглийском.ДатаРождения),
		|	ЕСТЬNULL(РеквизитыФизическихЛицАнкетныеНаРусском.СерияУдостоверенияЛичности, РеквизитыФизическихЛицАнкетныеНаАнглийском.СерияУдостоверенияЛичности),
		|	ЕСТЬNULL(РеквизитыФизическихЛицАнкетныеНаРусском.НомерУдостоверенияЛичности, РеквизитыФизическихЛицАнкетныеНаАнглийском.НомерУдостоверенияЛичности),
		|	ЕСТЬNULL(РеквизитыФизическихЛицАнкетныеНаРусском.ДатаВыдачиУдостоверенияЛичности, РеквизитыФизическихЛицАнкетныеНаАнглийском.ДатаВыдачиУдостоверенияЛичности),
		|	ЕСТЬNULL(РеквизитыФизическихЛицАнкетныеНаРусском.ОрганВыдавшийУдостоверениеЛичности, РеквизитыФизическихЛицАнкетныеНаАнглийском.ОрганВыдавшийУдостоверениеЛичности),
		|	ЕСТЬNULL(РеквизитыФизическихЛицАнкетныеНаРусском.АдресРегистрации, РеквизитыФизическихЛицАнкетныеНаАнглийском.АдресРегистрации),
		|	ЕСТЬNULL(РеквизитыФизическихЛицАнкетныеНаРусском.ПочтовыйАдрес, РеквизитыФизическихЛицАнкетныеНаАнглийском.ПочтовыйАдрес)
		|ИЗ
		|	РегистрСведений.РеквизитыФизическихЛицАнкетные.СрезПоследних(
		|			,
		|			Язык = ЗНАЧЕНИЕ(Справочник.Языки.Русский)
		|				И &ФильтрАнкетПроверяемыхЛиц) КАК РеквизитыФизическихЛицАнкетныеНаРусском
		|		ПОЛНОЕ СОЕДИНЕНИЕ РегистрСведений.РеквизитыФизическихЛицАнкетные.СрезПоследних(
		|				,
		|				Язык = ЗНАЧЕНИЕ(Справочник.Языки.Английский)
		|					И &ФильтрАнкетПроверяемыхЛиц) КАК РеквизитыФизическихЛицАнкетныеНаАнглийском
		|		ПО (РеквизитыФизическихЛицАнкетныеНаАнглийском.ЮрФизЛицо = РеквизитыФизическихЛицАнкетныеНаРусском.ЮрФизЛицо)
		|			И (РеквизитыФизическихЛицАнкетныеНаАнглийском.Организация = РеквизитыФизическихЛицАнкетныеНаРусском.Организация)
		|		ВНУТРЕННЕЕ СОЕДИНЕНИЕ Справочник.Организации КАК Организации
		|		ПО (Организации.Ссылка = ЕСТЬNULL(РеквизитыФизическихЛицАнкетныеНаРусском.Организация, РеквизитыФизическихЛицАнкетныеНаАнглийском.Организация))
		|		ВНУТРЕННЕЕ СОЕДИНЕНИЕ Справочник.ЮрФизЛица КАК ЮрФизЛица
		|		ПО (ЮрФизЛица.Ссылка = ЕСТЬNULL(РеквизитыФизическихЛицАнкетныеНаРусском.ЮрФизЛицо, РеквизитыФизическихЛицАнкетныеНаАнглийском.ЮрФизЛицо))
		|ГДЕ
		|	&ФильтрПроверяемыхЛиц
		|ИТОГИ ПО
		|	Ссылка";
#КонецОбласти
	
	Если ПроверяемыеЛица = Неопределено Тогда
		Запрос.Текст = СтрЗаменить(Запрос.Текст, "&ФильтрПроверяемыхЛиц", "ЮрФизЛица.ПометкаУдаления = ЛОЖЬ И ЮрФизЛица.ЭтоГруппа = ЛОЖЬ");
		Запрос.Текст = СтрЗаменить(Запрос.Текст, "&ФильтрАнкетПроверяемыхЛиц", "ИСТИНА");
		Запрос.Текст = СтрЗаменить(Запрос.Текст, "&ФильтрКонтактовПроверяемыхЛиц", "ИСТИНА");
	Иначе
		Запрос.Текст = СтрЗаменить(Запрос.Текст, "&ФильтрПроверяемыхЛиц", "ЮрФизЛица.Ссылка В (&ПроверяемыеЛица)");
		Запрос.Текст = СтрЗаменить(Запрос.Текст, "&ФильтрАнкетПроверяемыхЛиц", "ЮрФизЛицо В (&ПроверяемыеЛица)");
		Запрос.Текст = СтрЗаменить(Запрос.Текст, "&ФильтрКонтактовПроверяемыхЛиц", "Объект В (&ПроверяемыеЛица)");
		Запрос.УстановитьПараметр("ПроверяемыеЛица", ПроверяемыеЛица);
	КонецЕсли;	
	
	УстановитьПривилегированныйРежим(Истина); // т.к. требуются данные клиентов без отбора по организации
	ВыборкаЛиц = Запрос.Выполнить().Выбрать(ОбходРезультатаЗапроса.ПоГруппировкам);
	УстановитьПривилегированныйРежим(Ложь);
	
	РезультатСверки = Неопределено;
	РеквизитыСверки	= Новый Соответствие;

	Пока Истина Цикл
		МассивПартнеров		= Новый Массив;
		ДанныеПартнеров		= Новый Массив;
		КоличествоЗаписей	= 0;
		
		Пока ВыборкаЛиц.Следующий() Цикл
			МассивПартнеров.Добавить(ВыборкаЛиц.Ссылка);
			
			ВыборкаРеквизитовЛиц = ВыборкаЛиц.Выбрать(ОбходРезультатаЗапроса.Прямой);
			Пока ВыборкаРеквизитовЛиц.Следующий() Цикл
				КоличествоЗаписей = КоличествоЗаписей + 1;
				
				КлючСтрокиСверки = Строка(Новый УникальныйИдентификатор);
				
				ЗначенияРеквизитовСверки = Новый Структура("ИсточникДанных,Идентификатор,ЭтоОрганизация,ИНН");
				ЗаполнитьЗначенияСвойств(ЗначенияРеквизитовСверки, ВыборкаРеквизитовЛиц);
				ЗначенияРеквизитовСверки.Вставить("ДатаРождения"						, Формат(ВыборкаРеквизитовЛиц.ДатаРождения, "ДФ=yyyy/MM/dd"));
				ЗначенияРеквизитовСверки.Вставить("Наименование"						, СтрЗаменить(ВыборкаРеквизитовЛиц.Наименование, "'", "''"));
				ЗначенияРеквизитовСверки.Вставить("НаименованиеНаАнглийском"			, СтрЗаменить(ВыборкаРеквизитовЛиц.НаименованиеНаАнглийском, "'", "''"));
				ЗначенияРеквизитовСверки.Вставить("ЮридическийАдрес"					, СтрЗаменить(ВыборкаРеквизитовЛиц.ЮридическийАдрес, "'", "''"));
				ЗначенияРеквизитовСверки.Вставить("ПочтовыйАдрес"						, СтрЗаменить(ВыборкаРеквизитовЛиц.ПочтовыйАдрес, "'", "''"));
				ЗначенияРеквизитовСверки.Вставить("СерияУдостоверенияЛичности"			, СтрЗаменить(ВыборкаРеквизитовЛиц.СерияУдостоверенияЛичности, " ", ""));
				ЗначенияРеквизитовСверки.Вставить("НомерУдостоверенияЛичности"			, СтрЗаменить(ВыборкаРеквизитовЛиц.НомерУдостоверенияЛичности, " ", ""));
				ЗначенияРеквизитовСверки.Вставить("ДатаВыдачиУдостоверенияЛичности"		, Формат(ВыборкаРеквизитовЛиц.ДатаВыдачиУдостоверенияЛичности, "ДФ=yyyy/MM/dd"));
				ЗначенияРеквизитовСверки.Вставить("ОрганВыдавшийУдостоверениеЛичности"	, СтрЗаменить(ВыборкаРеквизитовЛиц.ОрганВыдавшийУдостоверениеЛичности, "'", "''"));
				РеквизитыСверки.Вставить(КлючСтрокиСверки, ЗначенияРеквизитовСверки);
				
				ДанныеПартнеров.Добавить(
					"SELECT"
					+ " '"  + ЗначенияРеквизитовСверки.ИсточникДанных + "'" + ?(КоличествоЗаписей = 1, " Data_Source", "") 
					+ ", '" + ЗначенияРеквизитовСверки.Идентификатор + "'" + ?(КоличествоЗаписей = 1, " Partner_ID", "") 
					+ ", "  + ЗначенияРеквизитовСверки.ЭтоОрганизация + ?(КоличествоЗаписей = 1, " Is_Firm", "")
					+ ", '" + ЗначенияРеквизитовСверки.ИНН + "'" + ?(КоличествоЗаписей = 1, " INN", "")
					+ ", '" + ЗначенияРеквизитовСверки.ДатаРождения + "'" + ?(КоличествоЗаписей = 1, " Birth_Date", "")
					+ ", '" + ЗначенияРеквизитовСверки.Наименование + "'" + ?(КоличествоЗаписей = 1, " Name_Ru", "")
					+ ", '" + ЗначенияРеквизитовСверки.НаименованиеНаАнглийском + "'" + ?(КоличествоЗаписей = 1, " Name_En", "")
					+ ", '" + ЗначенияРеквизитовСверки.ЮридическийАдрес + "'" + ?(КоличествоЗаписей = 1, " Address_Legal", "")
					+ ", '" + ЗначенияРеквизитовСверки.ПочтовыйАдрес + "'" + ?(КоличествоЗаписей = 1, " Address_Post", "")
					+ ", '" + ЗначенияРеквизитовСверки.СерияУдостоверенияЛичности + "'" + ?(КоличествоЗаписей = 1, " Document_Series", "")
					+ ", '" + ЗначенияРеквизитовСверки.НомерУдостоверенияЛичности + "'" + ?(КоличествоЗаписей = 1, " Document_Number", "")
					+ ", '" + ЗначенияРеквизитовСверки.ДатаВыдачиУдостоверенияЛичности + "'" + ?(КоличествоЗаписей = 1, " Document_Date", "")
					+ ", '" + ЗначенияРеквизитовСверки.ОрганВыдавшийУдостоверениеЛичности + "'" + ?(КоличествоЗаписей = 1, " Document_Issuer", "")
					+ ", '" + КлючСтрокиСверки + "'" + ?(КоличествоЗаписей = 1, " КлючСтрокиСверки", "")
				);
			КонецЦикла;	
			
			Если КоличествоЗаписей >= РазмерПакета Тогда
				Прервать;
			КонецЕсли;
		КонецЦикла;	
		
		Если КоличествоЗаписей = 0 Тогда
			Прервать;
		КонецЕсли;
		
		ПараметрПартнеры = СтрСоединить(ДанныеПартнеров, Символы.ПС + "UNION ALL" + Символы.ПС);	
		
		// Параметры
		ТекстЗапроса = СтрЗаменить(ШаблонЗапроса, "&ПорогТревоги", Формат(ПорогТревоги, "ЧГ="));
		ТекстЗапроса = СтрЗаменить(ТекстЗапроса, "&Партнеры", ПараметрПартнеры);
		
		// Получаем результат сверки со списками в Матрикс
		ТипыКолонок = Новый Структура;
		ТипыКолонок.Вставить("ИдентификаторЛица",	Новый ОписаниеТипов("Строка", , , , Новый КвалификаторыСтроки(9)));
		ТипыКолонок.Вставить("Пройдена",			Новый ОписаниеТипов("Булево"));
		ТипыКолонок.Вставить("Комментарий",			Новый ОписаниеТипов("Строка"));
		ТипыКолонок.Вставить("ИдентификаторСписка",	Новый ОписаниеТипов("Число"));
		ТипыКолонок.Вставить("КлючСтрокиСверки",	Новый ОписаниеТипов("Строка"));		
		
		Попытка
			РезультатСверкиПакета = ADODBC_ПолучитьТаблицуДанныхССервера(СтрокаСоединения, ТекстЗапроса, ТипыКолонок, ПараметрыСоединения);
		Исключение
		КонецПопытки;
		
		// Добавляем в ошибки проверки			
		Если РезультатСверкиПакета = Неопределено Тогда
			Если ОшибкиСверки = Неопределено Тогда
				ОшибкиСверки = Новый Структура;
			КонецЕсли;
			
			Если Не ОшибкиСверки.Свойство("НеПроверенныеЛица") Тогда
				ОшибкиСверки.Вставить("НеПроверенныеЛица", Новый ТаблицаЗначений);
				ОшибкиСверки.НеПроверенныеЛица.Колонки.Добавить("Ссылка", Новый ОписаниеТипов("СправочникСсылка.ЮрФизЛица"));
				ОшибкиСверки.НеПроверенныеЛица.Колонки.Добавить("Комментарий", Новый ОписаниеТипов("Строка"));
			КонецЕсли;
			
			Для Каждого НепроверенныйПартнер Из МассивПартнеров Цикл
				НеПроверенноеЛицо = ОшибкиСверки.НеПроверенныеЛица.Добавить();
				НеПроверенноеЛицо.Ссылка		= НепроверенныйПартнер.Ссылка;
				НеПроверенноеЛицо.Комментарий	= "Ошибка при выполнении запроса";
			КонецЦикла;
			
			Продолжить;
		КонецЕсли;

		Если РезультатСверки = Неопределено Тогда
			РезультатСверки = РезультатСверкиПакета;
		Иначе
			
			// Проверяем, что за время сверки список не изменился
			Если РезультатСверки.Количество() > 0
				И РезультатСверкиПакета.Количество() > 0
				И РезультатСверки[0].ИдентификаторСписка <> РезультатСверкиПакета[0].ИдентификаторСписка
			Тогда
				ОбщегоНазначенияКлиентСервер.СообщитьПользователю("Во время выполнения сверки произошло изменение списка террористов. Необходимо выполнить сверку повторно.");
				Возврат Неопределено;
			КонецЕсли;
			
			РаботаСКоллекциями.ТаблицаЗначений_Дополнить(РезультатСверкиПакета, РезультатСверки); 
		КонецЕсли;
	КонецЦикла;
	
	Если РезультатСверки = Неопределено Тогда
		Возврат Неопределено;
	КонецЕсли;
	
	Запрос = Новый Запрос("
		|ВЫБРАТЬ РАЗРЕШЕННЫЕ
		|	РезультатСверки.ИдентификаторЛица КАК ИдентификаторЛица,
		|	РезультатСверки.Пройдена КАК Пройдена,
		|	РезультатСверки.Комментарий КАК Комментарий,
		|	РезультатСверки.КлючСтрокиСверки
		|ПОМЕСТИТЬ
		|	_РезультатСверки
		|ИЗ
		|	&РезультатСверки КАК РезультатСверки
		|;
		|
		|ВЫБРАТЬ РАЗРЕШЕННЫЕ
		|	ЮрФизЛица.Ссылка КАК ЮрФизЛицо,
		|	РезультатСверки.Пройдена КАК Пройдена,
		|	РезультатСверки.Комментарий КАК Комментарий,
		|	РезультатСверки.КлючСтрокиСверки КАК КлючСтрокиСверки
		|ИЗ
		|	Справочник.ЮрФизЛица КАК ЮрФизЛица
		|	ВНУТРЕННЕЕ СОЕДИНЕНИЕ _РезультатСверки КАК РезультатСверки
		|		ПО РезультатСверки.ИдентификаторЛица = ЮрФизЛица.Код
		|");
	Запрос.УстановитьПараметр("РезультатСверки", РезультатСверки);
	
	// Получаем проверенные лица
	ПроверенныеЛица	= Запрос.Выполнить().Выгрузить();
	ПроверенныеЛица.Колонки.Добавить("РеквизитыСверки", Новый ОписаниеТипов("ХранилищеЗначения"));
	
	Для Каждого СтрокаДанных Из ПроверенныеЛица Цикл
		СтрокаДанных.РеквизитыСверки = Новый ХранилищеЗначения(РеквизитыСверки.Получить(СтрокаДанных.КлючСтрокиСверки));
	КонецЦикла;

	ПроверенныеЛица.Колонки.Удалить("КлючСтрокиСверки");	
	
	Возврат ПроверенныеЛица;
КонецФункции

Функция ПолучитьИнформациюОПоследнемСпискеТеррористов() Экспорт
	ИнфоОСписке = Новый Структура("Идентификатор, ДатаСписка");	
	
	СтрокаСоединения = СтрокаСоединенияСМатрих();
	
	Соединение = ADODBC_УстановитьСоединение(СтрокаСоединения);
	
	Если Соединение <> Неопределено Тогда
		
		adBigInt	= 20;  // An 8-byte signed integer.
		adDate		= 7;   // С датой не работает, использую adVarWChar с последующей конвертацией в дату 1С 
		adVarWChar	= 202; // A null-terminated Unicode character string.
		
		Попытка
			
			Command = ADODBC_ПолучитьКомандуОбращенияКХранимойПроцедуре(Соединение, "pub.usp_Terrorists_Get_Last_List");
			Command.NamedParameters = True;
			
			paramListID		= ADODBC_ДобавитьВыходнойПараметрКоманды(Command, "@List_ID", adBigInt);
			paramListDate	= ADODBC_ДобавитьВыходнойПараметрКоманды(Command, "@Date", adVarWChar, 10);
			
			Command.Execute();
			
			ИнфоОСписке.Идентификатор	= paramListID.Value;
			ИнфоОСписке.ДатаСписка		= ПолучитьЗначениеТипа(Тип("Дата"), paramListDate.Value)
			
		Исключение
			
			Сообщить(ОписаниеОшибки());
			Информация = ИнформацияОбОшибке();
			ОбщегоНазначенияКлиентСервер.СообщитьПользователю("Ошибка получения данных из Матрих: " + Информация.Описание);
			
		КонецПопытки;

		ADODBC_ЗакрытьСоединение(Соединение);
		
	КонецЕсли;
	
	Возврат ИнфоОСписке;	
КонецФункции

// Функция - Возвращает результаты сверки юр./физ. лиц со списком лиц с замороженными счетами
// 
// Параметры:
//	ПроверяемыеЛица	 - Массив - (Необязательный) Содержит массив проверяемых юр./физ. лиц
//						Если не указан, проводится сверка по полному списку юр./физ. лиц
//	ОшибкиСверки	 - Структура - (Необязательный, Выходной) В случае ошибок сверки возвращает структуру с описанием ошибок
//						Может содержать именованные таблицы:
//						- НеПроверенныеЛица: Ссылка (СправочникСсылка.ЮрФизЛица), Код (Строка), Категория (Строка)
//						- ОшибкиПоискаКодаВоВнешнейСистеме: Ссылка (СправочникСсылка.ЮрФизЛица)   
// 
// Возвращаемое значение:
//	ТаблицаЗначений, Неопределено - таблица успешно прошедших проверку лиц, Неопределено - в случае ошибки
//									Структура таблицы: ЮрФизЛицо (СправочникСсылка.ЮрФизЛица), Пройдена (Булево), Комментарий (Строка)
//
//
Функция ПолучитьРезультатСверкиСоСпискомЛицСЗамороженнымиСчетамиВMatrix(ПроверяемыеЛица = Неопределено, ОшибкиСверки = Неопределено) Экспорт	
	Перем ПроверенныеЛица; 	
	
	// Инициализация вспомогательных переменных
	ПорогТревоги		= 5;	
	СтрокаСоединения	= СтрокаСоединенияСМатрих();
	ПараметрыСоединения = Новый Структура("CommandTimeout", 180);	
	РазмерПакета		= 300; // Количество отправляемых на проверку лиц
	
#Область ШаблонЗапроса		
	ШаблонЗапроса		= "
		|SET NOCOUNT ON
		|;
		|
		|IF OBJECT_ID('tempdb..#Partners') IS NOT NULL
		|	Drop Table #Partners
		|;
		|IF OBJECT_ID('tempdb..#DecisionsSubjects') IS NOT NULL
		|	Drop Table #DecisionsSubjects
		|;		
		|IF OBJECT_ID('tempdb..#SuspectPartners') IS NOT NULL
		|	Drop Table #SuspectPartners
		|;
		|IF OBJECT_ID('tempdb..#LastDecisionsList') IS NOT NULL
		|	Drop Table #LastDecisionsList
		|;
		|
		|CREATE TABLE #Partners(
		|	Row_Index bigint IDENTITY(1,1),
		|	Data_Source nvarchar(15),
		|	Partner_ID nvarchar(9),
		|	Is_Firm bit,
		|	INN nvarchar(12),
		|	OGRN nvarchar(100),
		|	Birth_Date date,
		|	Name_Ru_Clean nvarchar(4000),
		|	Name_Ru nvarchar(4000),
		|	Name_En_Clean nvarchar(4000),
		|	Name_En nvarchar(4000),
		|	Address_Legal_Clean nvarchar(4000),
		|	Address_Legal nvarchar(4000),
		|	Address_Post_Clean nvarchar(4000),
		|	Address_Post nvarchar(4000),
		|	Document_Series nvarchar(4000),
		|	Document_Number nvarchar(4000),
		|	Document_Date date,
		|	Document_Issuer_Clean nvarchar(4000),
		|	Document_Issuer nvarchar(4000),
		|	КлючСтрокиСверки nvarchar(36)
		|	--,INDEX ix_Is_Firm NONCLUSTERED (Is_Firm)
		|	--,INDEX ix_INN NONCLUSTERED (INN)
		|	--,INDEX ix_Birth_Date NONCLUSTERED (Birth_Date)
		|	--,INDEX ix_Document_Series_Number NONCLUSTERED (Document_Series, Document_Number)
		|	--,INDEX ix_Document_Date NONCLUSTERED (Document_Date)
		|)
		|;
		|
		|INSERT INTO
		|	#Partners
		|SELECT
		|	Data_Source,
		|	Partner_ID,
		|	Is_Firm,
		|	INN,
		|	OGRN,
		|	Birth_Date,
		|	Name_Ru_Clean = dbo.udf_FEDSFM_Strings_Clean(Name_Ru),
		|	Name_Ru,
		|	Name_En_Clean = dbo.udf_FEDSFM_Strings_Clean(Name_En),
		|	Name_En,
		|	Address_Legal_Clean = dbo.udf_FEDSFM_Strings_Clean(Address_Legal),
		|	Address_Legal,
		|	Address_Post_Clean = dbo.udf_FEDSFM_Strings_Clean(Address_Post),
		|	Address_Post,
		|	Document_Series,
		|	Document_Number,
		|	Document_Date,
		|	Document_Issuer_Clean = dbo.udf_FEDSFM_Strings_Clean(Document_Issuer),
		|	Document_Issuer,
		|	КлючСтрокиСверки
		|FROM (
		|	&Партнеры
		|) Partners
		|; 
		|
		|SELECT TOP 1
		|	TempDecisionsLists.ID,
		|	TempDecisionsLists.Date
		|INTO
		|	#LastDecisionsList		
		|FROM
		|	MatriX.dbo.FEDSFM_Terrorists_Lists [TempDecisionsLists]
		|	INNER JOIN MatriX.dbo.Enums_Values [ListTypeDecisions]
		|		ON ListTypeDecisions.UID = 'FEDSFM.Lists.Decisions'
		|			AND ListTypeDecisions.ID = TempDecisionsLists.Type
		|ORDER BY
		|	TempDecisionsLists.Date DESC
		|;
		|
		|CREATE TABLE #DecisionsSubjects(
		|	List_ID bigint,
		|	Decision_ID bigint,
		|	ID bigint,
		|	Is_Firm bit,
		|	INN nvarchar(12),
		|	OGRN nvarchar(100),
		|	Birth_Date date,
		|	Name_Full_Ru nvarchar(4000),
		|	Name_Ru_Clean nvarchar(4000),
		|	Name_Full_En nvarchar(4000),
		|	Name_En_Clean nvarchar(4000),
		|	Address_Legal_Clean nvarchar(4000),
		|	Address_Post_Clean nvarchar(4000),
		|	Document_Series nvarchar(4000),
		|	Document_Number nvarchar(4000),
		|	Document_Date_Issue date,
		|	Document_Issuer_Clean nvarchar(4000)
		|	--,INDEX ix_Is_Firm__INN NONCLUSTERED (Is_Firm, INN)
		|	--,INDEX ix_Is_Firm__OGRN NONCLUSTERED (Is_Firm, OGRN)
		|	--,INDEX ix_INN NONCLUSTERED (INN)
		|	--,INDEX ix_OGRN NONCLUSTERED (OGRN)
		|	--,INDEX ix_Birth_Date NONCLUSTERED (Birth_Date)
		|	--,INDEX ix_Document_Series_Number NONCLUSTERED (Document_Series, Document_Number)
		|	--,INDEX ix_Document_Date NONCLUSTERED (Document_Date)
		|)
		|;		
		|
		|INSERT INTO
		|	#DecisionsSubjects
		|SELECT
		|	[List_ID] = Decisions.List_ID,
		|	[Decision_ID] = DecisionsSubjects.Decision_ID,
		|	[ID] = DecisionsSubjects.ID,
		|	[Is_Firm] = CASE WHEN DecisionsSubjects.Type_Name = 'Физическое лицо' THEN 0 ELSE 1 END,
		|	[INN] = DecisionsSubjects.INN,
		|	[OGRN] = DecisionsSubjects.OGRN,
		|	[Birth_Date] = DecisionsSubjects.Birth_Date,
		|	[Name_Full_Ru] = DecisionsSubjects.Name_Full_Ru,
		|	[Name_Full_En] = DecisionsSubjects.Name_Full_En,
		|	[Name_Ru_Clean] = dbo.udf_FEDSFM_Strings_Clean(DecisionsSubjects.Name_Full_Ru),
		|	[Name_En_Clean] = dbo.udf_FEDSFM_Strings_Clean(DecisionsSubjects.Name_Full_En),
		|	[Address_Legal_Clean] = dbo.udf_FEDSFM_Strings_Clean(DecisionsSubjects.Address_Legal),
		|	[Address_Post_Clean] = dbo.udf_FEDSFM_Strings_Clean(DecisionsSubjects.Address_Post),
		|	[Document_Series] = DecisionsSubjects.Document_Series,
		|	[Document_Number] = DecisionsSubjects.Document_Number,
		|	[Document_Date_Issue] = DecisionsSubjects.Document_Date_Issue,
		|	[Document_Issuer_Clean] = dbo.udf_FEDSFM_Strings_Clean(DecisionsSubjects.Document_Agency)
		|FROM MatriX.dbo.FEDSFM_Decisions_Lists_Subjects [DecisionsSubjects]
		|	INNER JOIN MatriX.dbo.FEDSFM_Decisions_Lists_Details [Decisions]
		|		INNER JOIN #LastDecisionsList [LastDecisionsList]
		|		ON LastDecisionsList.ID = Decisions.List_ID
		|	ON Decisions.ID = DecisionsSubjects.Decision_ID
		|;
		|		
		|SELECT
		|	[Row_Index] = P.Row_Index,
		|	[Data_Source] = P.Data_Source,
		|	[Partner_ID] = P.Partner_ID,
		|	[DecisionsSubject_ID] = DS.ID,
		|	[DecisionsSubject_Name] = CASE WHEN DS.Name_Full_Ru = '' OR DS.Name_Full_Ru IS NULL THEN DS.Name_Full_En ELSE DS.Name_Full_Ru END,
		|	[Decision_ID] = DS.Decision_ID,
		|	[List_ID] = DS.List_ID,
		|	[Intersections] = 
		|		CASE WHEN DS.Is_Firm = P.Is_Firm 
		|			THEN (CASE WHEN DS.INN = P.INN THEN 'ИНН, ' ELSE '' END)
		|					+ (CASE WHEN DS.OGRN = P.OGRN THEN 'ОГРН, ' ELSE '' END)
		|					+ (CASE WHEN DS.Address_Legal_Clean = P.Address_Legal_Clean AND DS.Address_Legal_Clean <> '' THEN 'Юридический адрес, ' ELSE '' END)
		|					+ (CASE WHEN DS.Address_Post_Clean = P.Address_Post_Clean AND DS.Address_Post_Clean <> '' THEN 'Почтовый адрес, ' ELSE '' END)
		|					+ (CASE WHEN DS.Birth_Date = P.Birth_Date AND DS.Is_Firm = 0 THEN 'Дата рождения, ' ELSE '' END)
		|					+ (CASE WHEN DS.Document_Date_Issue = P.Document_Date AND DS.Is_Firm = 0 THEN 'Дата выдачи ДУЛ, ' ELSE '' END)
		|					+ (CASE WHEN DS.Document_Series = P.Document_Series AND DS.Document_Number = P.Document_Number AND DS.Is_Firm = 0 THEN 'Серия и номер ДУЛ, ' ELSE '' END)
		|					+ (CASE WHEN CharIndex(P.Document_Issuer_Clean, DS.Document_Issuer_Clean) > 0 AND Len(P.Document_Issuer_Clean) > 10 AND DS.Is_Firm = 0 THEN 'Орган выдавший ДУЛ, ' ELSE '' END)
		|					+ (CASE WHEN CharIndex(P.Name_Ru_Clean, DS.Name_Ru_Clean) > 0 THEN 'Полное наименование (рус.), ' ELSE '' END)
		|					+ (CASE WHEN CharIndex(P.Name_En_Clean, DS.Name_En_Clean) > 0 THEN 'Полное наименование (англ.), ' ELSE '' END)
		|			ELSE ''
		|		END,
		|	[Sum_Rank] = 
		|		CASE WHEN DS.Is_Firm = P.Is_Firm 
		|			THEN (CASE WHEN DS.INN = P.INN THEN 5 ELSE 0 END)
		|					+ (CASE WHEN DS.OGRN = P.OGRN THEN 5 ELSE 0 END)
		|					+ (CASE WHEN DS.Address_Legal_Clean = P.Address_Legal_Clean AND DS.Address_Legal_Clean <> '' THEN 3 ELSE 0 END)
		|					+ (CASE WHEN DS.Address_Post_Clean = P.Address_Post_Clean AND DS.Address_Post_Clean <> '' THEN 3 ELSE 0 END)
		|					+ (CASE WHEN DS.Birth_Date = P.Birth_Date AND DS.Is_Firm = 0 THEN 1 ELSE 0 END)
		|					+ (CASE WHEN DS.Document_Date_Issue = P.Document_Date AND DS.Is_Firm = 0 THEN 1 ELSE 0 END)
		|					+ (CASE WHEN DS.Document_Series = P.Document_Series AND DS.Document_Number = P.Document_Number AND DS.Is_Firm = 0 THEN 5 ELSE 0 END)
		|					+ (CASE WHEN CharIndex(P.Document_Issuer_Clean, DS.Document_Issuer_Clean) > 0 AND Len(P.Document_Issuer_Clean) > 10 AND DS.Is_Firm = 0 THEN 3 ELSE 0 END)
		|					+ (CASE WHEN CharIndex(P.Name_Ru_Clean, DS.Name_Ru_Clean) > 0 THEN 3 ELSE 0 END)
		|					+ (CASE WHEN CharIndex(P.Name_En_Clean, DS.Name_En_Clean) > 0 THEN 3 ELSE 0 END)
		|			ELSE 0
		|		END
		|INTO
		|	#SuspectPartners
		|FROM #Partners as P
		|	INNER JOIN #DecisionsSubjects [DS]
		|	ON
		|		DS.Is_Firm = P.Is_Firm AND (
		|			DS.INN = P.INN
		|			OR DS.OGRN = P.OGRN
		|			OR (DS.Address_Legal_Clean = P.Address_Legal_Clean AND DS.Address_Legal_Clean <> '')
		|			OR (DS.Address_Post_Clean = P.Address_Post_Clean AND DS.Address_Post_Clean <> '')
		|			OR (DS.Birth_Date = P.Birth_Date AND P.Is_Firm = 0)
		|			OR (DS.Document_Date_Issue = P.Document_Date AND P.Is_Firm = 0)
		|			OR (DS.Document_Series = P.Document_Series AND DS.Document_Number = P.Document_Number AND P.Is_Firm = 0)
		|			OR (CharIndex(P.Document_Issuer_Clean, DS.Document_Issuer_Clean) > 0 AND Len(P.Document_Issuer_Clean) > 10 AND P.Is_Firm = 0)
		|			OR (CharIndex(P.Name_Ru_Clean, DS.Name_Ru_Clean) > 0)
		|			OR (CharIndex(P.Name_En_Clean, DS.Name_En_Clean) > 0)
		|		)
		|WHERE
		|	CASE WHEN DS.Is_Firm = P.Is_Firm 
		|		THEN (CASE WHEN DS.INN = P.INN THEN 5 ELSE 0 END)
		|				+ (CASE WHEN DS.OGRN = P.OGRN THEN 5 ELSE 0 END)
		|				+ (CASE WHEN DS.Address_Legal_Clean = P.Address_Legal_Clean AND DS.Address_Legal_Clean <> '' THEN 3 ELSE 0 END)
		|				+ (CASE WHEN DS.Address_Post_Clean = P.Address_Post_Clean AND DS.Address_Post_Clean <> '' THEN 3 ELSE 0 END)
		|				+ (CASE WHEN DS.Birth_Date = P.Birth_Date AND DS.Is_Firm = 0 THEN 1 ELSE 0 END)
		|				+ (CASE WHEN DS.Document_Date_Issue = P.Document_Date AND DS.Is_Firm = 0 THEN 1 ELSE 0 END)
		|				+ (CASE WHEN DS.Document_Series = P.Document_Series AND DS.Document_Number = P.Document_Number AND DS.Is_Firm = 0 THEN 5 ELSE 0 END)
		|				+ (CASE WHEN CharIndex(P.Document_Issuer_Clean, DS.Document_Issuer_Clean) > 0 AND Len(P.Document_Issuer_Clean) > 10 AND DS.Is_Firm = 0 THEN 3 ELSE 0 END)
		|				+ (CASE WHEN CharIndex(P.Name_Ru_Clean, DS.Name_Ru_Clean) > 0 THEN 3 ELSE 0 END)
		|				+ (CASE WHEN CharIndex(P.Name_En_Clean, DS.Name_En_Clean) > 0 THEN 3 ELSE 0 END)
		|		ELSE 0
		|	END >= &ПорогТревоги
		|;
		|
		|SELECT DISTINCT
		|	[ИдентификаторЛица] = Partners.Partner_ID,
		|	[Пройдена] = 
		|		CASE
		|			WHEN SuspectPartners.Partner_ID IS NULL
		|				THEN 1
		|			ELSE 0
		|		END,
		|	[Комментарий] = 
		|		CASE
		|			WHEN SuspectPartners.Partner_ID IS NULL
		|				THEN 'Список от ' + CONVERT(nvarchar(10), LastDecisionsList.Date, 104)
		|			ELSE 'Найдены совпадения данных ' + SuspectPartners.Data_Source
		|				+ ' с данными Списка решений от ' + CONVERT(nvarchar(10), LastDecisionsList.Date, 104) + ' по Решению от ' + convert(nvarchar(10), Decisions.Date, 104) + ' № ' + Decisions.Number + ' (' + Decisions.Sub_Type_Name + ')'     
		|				+ ' с [' + CAST(SuspectPartners.DecisionsSubject_ID  AS nvarchar(9)) + '] '
		|				+ SuspectPartners.DecisionsSubject_Name + ' по ' + SuspectPartners.Intersections
		|				+ 'суммарная оценка ' + CAST(SuspectPartners.Sum_Rank AS nvarchar(3))
		|		END,
		|	[ИдентификаторСписка] = LastDecisionsList.ID,
		|	КлючСтрокиСверки = [Partners].КлючСтрокиСверки
		|FROM #Partners [Partners] 
		|	LEFT JOIN #SuspectPartners [SuspectPartners]
		|		INNER JOIN (
		|			SELECT
		|				SuspectPartnersForRow.Partner_ID,
		|				MAX(SuspectPartnersForRow.Row_Index) [Max_Row]	
		|			FROM
		|				#SuspectPartners [SuspectPartnersForRow]	
		|				INNER JOIN (
		|					SELECT
		|						SuspectPartnersForRank.Partner_ID,
		|						MAX(SuspectPartnersForRank.Sum_Rank) [Sum_Rank]
		|					FROM #SuspectPartners [SuspectPartnersForRank]
		|					GROUP BY
		|						SuspectPartnersForRank.Partner_ID
		|				) [MaxRankSuspicion]
		|				ON MaxRankSuspicion.Partner_ID = SuspectPartnersForRow.Partner_ID
		|					AND MaxRankSuspicion.Sum_Rank = SuspectPartnersForRow.Sum_Rank
		|			GROUP BY
		|				SuspectPartnersForRow.Partner_ID	
		|		) [SuspectPartnersCleared]
		|		ON SuspectPartnersCleared.Partner_ID = SuspectPartners.Partner_ID
		|			AND SuspectPartnersCleared.Max_Row = SuspectPartners.Row_Index
		|		INNER JOIN MatriX.dbo.FEDSFM_Decisions_Lists_Details [Decisions]
		|		ON Decisions.ID = SuspectPartners.Decision_ID
		|			AND Decisions.List_ID = SuspectPartners.List_ID 
		|	ON SuspectPartners.Partner_ID = Partners.Partner_ID,
		|	#LastDecisionsList [LastDecisionsList]
		|;
		|
		|IF OBJECT_ID('tempdb..#Partners') IS NOT NULL
		|	Drop Table #Partners
		|;
		|IF OBJECT_ID('tempdb..#DecisionsSubjects') IS NOT NULL
		|	Drop Table #DecisionsSubjects
		|;		
		|IF OBJECT_ID('tempdb..#SuspectPartners') IS NOT NULL
		|	Drop Table #SuspectPartners
		|;
		|IF OBJECT_ID('tempdb..#LastDecisionsList') IS NOT NULL
		|	Drop Table #LastDecisionsList
		|;
		|";	
#КонецОбласти
		
	// Подготовим параметр для передачи таблицы на сервер
	Запрос = Новый Запрос;
	
#Область ТекстЗапроса	
	Запрос.Текст = 
		"ВЫБРАТЬ РАЗРЕШЕННЫЕ
		|	""ГК Регион"" КАК ИсточникДанных,
		|	ВЫБОР
		|		КОГДА ЮрФизЛица.ВидЮрФизЛица = ЗНАЧЕНИЕ(Перечисление.ВидыЮрФизЛиц.ЮридическоеЛицо)
		|			ТОГДА ""1""
		|		ИНАЧЕ ""0""
		|	КОНЕЦ КАК ЭтоОрганизация,
		|	ЮрФизЛица.Ссылка КАК Ссылка,
		|	ЮрФизЛица.Код КАК Идентификатор,
		|	РеквизитыЮридическихЛицНаРусском.ПолноеНаименованиеПоУставу КАК Наименование,
		|	РеквизитыЮридическихЛицНаАнглийском.ПолноеНаименованиеПоУставу КАК НаименованиеНаАнглийском,
		|	РеквизитыЮридическихЛицНаРусском.ИНН КАК ИНН,
		|	ДокументыЮридическихЛицСрезПоследних.Номер КАК ОГРН,
		|	NULL КАК ДатаРождения,
		|	NULL КАК СерияУдостоверенияЛичности,
		|	NULL КАК НомерУдостоверенияЛичности,
		|	NULL КАК ДатаВыдачиУдостоверенияЛичности,
		|	NULL КАК ОрганВыдавшийУдостоверениеЛичности,
		|	ЕСТЬNULL(ЮридическийАдрес.Представление, АдресРегистрации.Представление) КАК ЮридическийАдрес,
		|	ПочтовыйАдрес.Представление КАК ПочтовыйАдрес
		|ИЗ
		|	Справочник.ЮрФизЛица КАК ЮрФизЛица
		|		ЛЕВОЕ СОЕДИНЕНИЕ РегистрСведений.РеквизитыЮридическихЛиц.СрезПоследних(
		|				,
		|				Подразделение = ЗНАЧЕНИЕ(Справочник.Подразделения.ГруппаКомпаний)
		|					И Язык = ЗНАЧЕНИЕ(Справочник.Языки.Русский)
		|					И &ФильтрАнкетПроверяемыхЛиц) КАК РеквизитыЮридическихЛицНаРусском
		|		ПО (РеквизитыЮридическихЛицНаРусском.ЮрФизЛицо = ЮрФизЛица.Ссылка)
		|		ЛЕВОЕ СОЕДИНЕНИЕ РегистрСведений.РеквизитыЮридическихЛиц.СрезПоследних(
		|				,
		|				Подразделение = ЗНАЧЕНИЕ(Справочник.Подразделения.ГруппаКомпаний)
		|					И Язык = ЗНАЧЕНИЕ(Справочник.Языки.Английский)
		|					И &ФильтрАнкетПроверяемыхЛиц) КАК РеквизитыЮридическихЛицНаАнглийском
		|		ПО (РеквизитыЮридическихЛицНаАнглийском.ЮрФизЛицо = ЮрФизЛица.Ссылка)
		|		ЛЕВОЕ СОЕДИНЕНИЕ РегистрСведений.КонтактнаяИнформация.СрезПоследних(
		|				,
		|				Подразделение = ЗНАЧЕНИЕ(Справочник.Подразделения.ГруппаКомпаний)
		|					И Язык = ЗНАЧЕНИЕ(Справочник.Языки.Русский)
		|					И Вид = ЗНАЧЕНИЕ(Справочник.ВидыКонтактнойИнформации.АдресРегистрации)
		|					И &ФильтрКонтактовПроверяемыхЛиц) КАК АдресРегистрации
		|		ПО (АдресРегистрации.Объект = ЮрФизЛица.Ссылка)
		|		ЛЕВОЕ СОЕДИНЕНИЕ РегистрСведений.КонтактнаяИнформация.СрезПоследних(
		|				,
		|				Подразделение = ЗНАЧЕНИЕ(Справочник.Подразделения.ГруппаКомпаний)
		|					И Язык = ЗНАЧЕНИЕ(Справочник.Языки.Русский)
		|					И Вид = ЗНАЧЕНИЕ(Справочник.ВидыКонтактнойИнформации.ЮридическийАдрес)
		|					И &ФильтрКонтактовПроверяемыхЛиц) КАК ЮридическийАдрес
		|		ПО (ЮридическийАдрес.Объект = ЮрФизЛица.Ссылка)
		|		ЛЕВОЕ СОЕДИНЕНИЕ РегистрСведений.КонтактнаяИнформация.СрезПоследних(
		|				,
		|				Подразделение = ЗНАЧЕНИЕ(Справочник.Подразделения.ГруппаКомпаний)
		|					И Язык = ЗНАЧЕНИЕ(Справочник.Языки.Русский)
		|					И Вид = ЗНАЧЕНИЕ(Справочник.ВидыКонтактнойИнформации.ПочтовыйАдрес)
		|					И &ФильтрКонтактовПроверяемыхЛиц) КАК ПочтовыйАдрес
		|		ПО (ПочтовыйАдрес.Объект = ЮрФизЛица.Ссылка)
		|		ЛЕВОЕ СОЕДИНЕНИЕ РегистрСведений.ДокументыЮридическихЛиц.СрезПоследних(
		|				,
		|				Подразделение = ЗНАЧЕНИЕ(Справочник.Подразделения.ГруппаКомпаний)
		|					И Язык = ЗНАЧЕНИЕ(Справочник.Языки.Русский)
		|					И Вид = ЗНАЧЕНИЕ(Перечисление.ВидыДокументовЮридическихЛиц.СвидетельствоОГосударственнойРегистрации)
		|					И &ФильтрАнкетПроверяемыхЛиц) КАК ДокументыЮридическихЛицСрезПоследних
		|		ПО ЮрФизЛица.Ссылка = ДокументыЮридическихЛицСрезПоследних.ЮрФизЛицо
		|			И (ДокументыЮридическихЛицСрезПоследних.ДействуетПо = ДАТАВРЕМЯ(1, 1, 1))
		|ГДЕ
		|	&ФильтрПроверяемыхЛиц
		|
		|ОБЪЕДИНИТЬ ВСЕ
		|
		|ВЫБРАТЬ
		|	Организации.ПрефиксНумерации,
		|	""1"",
		|	ЮрФизЛица.Ссылка,
		|	ЮрФизЛица.Код,
		|	РеквизитыЮридическихЛицАнкетныеНаРусском.ПолноеНаименованиеПоУставу,
		|	РеквизитыЮридическихЛицАнкетныеНаАнглийском.ПолноеНаименованиеПоУставу,
		|	ЕСТЬNULL(РеквизитыЮридическихЛицАнкетныеНаРусском.ИНН, РеквизитыЮридическихЛицАнкетныеНаАнглийском.ИНН),
		|	ЕСТЬNULL(РеквизитыЮридическихЛицАнкетныеНаРусском.ОГРН, РеквизитыЮридическихЛицАнкетныеНаАнглийском.ОГРН),
		|	NULL,
		|	NULL,
		|	NULL,
		|	NULL,
		|	NULL,
		|	ЕСТЬNULL(РеквизитыЮридическихЛицАнкетныеНаРусском.ЮридическийАдрес, РеквизитыЮридическихЛицАнкетныеНаАнглийском.ЮридическийАдрес),
		|	ЕСТЬNULL(РеквизитыЮридическихЛицАнкетныеНаРусском.ПочтовыйАдрес, РеквизитыЮридическихЛицАнкетныеНаАнглийском.ПочтовыйАдрес)
		|ИЗ
		|	РегистрСведений.РеквизитыЮридическихЛицАнкетные.СрезПоследних(
		|			,
		|			Язык = ЗНАЧЕНИЕ(Справочник.Языки.Русский)
		|				И &ФильтрАнкетПроверяемыхЛиц) КАК РеквизитыЮридическихЛицАнкетныеНаРусском
		|		ПОЛНОЕ СОЕДИНЕНИЕ РегистрСведений.РеквизитыЮридическихЛицАнкетные.СрезПоследних(
		|				,
		|				Язык = ЗНАЧЕНИЕ(Справочник.Языки.Английский)
		|					И &ФильтрАнкетПроверяемыхЛиц) КАК РеквизитыЮридическихЛицАнкетныеНаАнглийском
		|		ПО (РеквизитыЮридическихЛицАнкетныеНаАнглийском.ЮрФизЛицо = РеквизитыЮридическихЛицАнкетныеНаРусском.ЮрФизЛицо)
		|			И (РеквизитыЮридическихЛицАнкетныеНаАнглийском.Организация = РеквизитыЮридическихЛицАнкетныеНаРусском.Организация)
		|		ВНУТРЕННЕЕ СОЕДИНЕНИЕ Справочник.Организации КАК Организации
		|		ПО (Организации.Ссылка = ЕСТЬNULL(РеквизитыЮридическихЛицАнкетныеНаРусском.Организация, РеквизитыЮридическихЛицАнкетныеНаАнглийском.Организация))
		|		ВНУТРЕННЕЕ СОЕДИНЕНИЕ Справочник.ЮрФизЛица КАК ЮрФизЛица
		|		ПО (ЮрФизЛица.Ссылка = ЕСТЬNULL(РеквизитыЮридическихЛицАнкетныеНаРусском.ЮрФизЛицо, РеквизитыЮридическихЛицАнкетныеНаАнглийском.ЮрФизЛицо))
		|ГДЕ
		|	&ФильтрПроверяемыхЛиц
		|
		|ОБЪЕДИНИТЬ ВСЕ
		|
		|ВЫБРАТЬ
		|	Организации.ПрефиксНумерации,
		|	""0"",
		|	ЮрФизЛица.Ссылка,
		|	ЮрФизЛица.Код,
		|	РеквизитыФизическихЛицАнкетныеНаРусском.Фамилия + "" "" + РеквизитыФизическихЛицАнкетныеНаРусском.Имя + "" "" + РеквизитыФизическихЛицАнкетныеНаРусском.Отчество,
		|	РеквизитыФизическихЛицАнкетныеНаАнглийском.Фамилия + "" "" + РеквизитыФизическихЛицАнкетныеНаАнглийском.Имя + "" "" + РеквизитыФизическихЛицАнкетныеНаАнглийском.Отчество,
		|	ЕСТЬNULL(РеквизитыФизическихЛицАнкетныеНаРусском.ИНН, РеквизитыФизическихЛицАнкетныеНаАнглийском.ИНН),
		|	"""",
		|	ЕСТЬNULL(РеквизитыФизическихЛицАнкетныеНаРусском.ДатаРождения, РеквизитыФизическихЛицАнкетныеНаАнглийском.ДатаРождения),
		|	ЕСТЬNULL(РеквизитыФизическихЛицАнкетныеНаРусском.СерияУдостоверенияЛичности, РеквизитыФизическихЛицАнкетныеНаАнглийском.СерияУдостоверенияЛичности),
		|	ЕСТЬNULL(РеквизитыФизическихЛицАнкетныеНаРусском.НомерУдостоверенияЛичности, РеквизитыФизическихЛицАнкетныеНаАнглийском.НомерУдостоверенияЛичности),
		|	ЕСТЬNULL(РеквизитыФизическихЛицАнкетныеНаРусском.ДатаВыдачиУдостоверенияЛичности, РеквизитыФизическихЛицАнкетныеНаАнглийском.ДатаВыдачиУдостоверенияЛичности),
		|	ЕСТЬNULL(РеквизитыФизическихЛицАнкетныеНаРусском.ОрганВыдавшийУдостоверениеЛичности, РеквизитыФизическихЛицАнкетныеНаАнглийском.ОрганВыдавшийУдостоверениеЛичности),
		|	ЕСТЬNULL(РеквизитыФизическихЛицАнкетныеНаРусском.АдресРегистрации, РеквизитыФизическихЛицАнкетныеНаАнглийском.АдресРегистрации),
		|	ЕСТЬNULL(РеквизитыФизическихЛицАнкетныеНаРусском.ПочтовыйАдрес, РеквизитыФизическихЛицАнкетныеНаАнглийском.ПочтовыйАдрес)
		|ИЗ
		|	РегистрСведений.РеквизитыФизическихЛицАнкетные.СрезПоследних(
		|			,
		|			Язык = ЗНАЧЕНИЕ(Справочник.Языки.Русский)
		|				И &ФильтрАнкетПроверяемыхЛиц) КАК РеквизитыФизическихЛицАнкетныеНаРусском
		|		ПОЛНОЕ СОЕДИНЕНИЕ РегистрСведений.РеквизитыФизическихЛицАнкетные.СрезПоследних(
		|				,
		|				Язык = ЗНАЧЕНИЕ(Справочник.Языки.Английский)
		|					И &ФильтрАнкетПроверяемыхЛиц) КАК РеквизитыФизическихЛицАнкетныеНаАнглийском
		|		ПО (РеквизитыФизическихЛицАнкетныеНаАнглийском.ЮрФизЛицо = РеквизитыФизическихЛицАнкетныеНаРусском.ЮрФизЛицо)
		|			И (РеквизитыФизическихЛицАнкетныеНаАнглийском.Организация = РеквизитыФизическихЛицАнкетныеНаРусском.Организация)
		|		ВНУТРЕННЕЕ СОЕДИНЕНИЕ Справочник.Организации КАК Организации
		|		ПО (Организации.Ссылка = ЕСТЬNULL(РеквизитыФизическихЛицАнкетныеНаРусском.Организация, РеквизитыФизическихЛицАнкетныеНаАнглийском.Организация))
		|		ВНУТРЕННЕЕ СОЕДИНЕНИЕ Справочник.ЮрФизЛица КАК ЮрФизЛица
		|		ПО (ЮрФизЛица.Ссылка = ЕСТЬNULL(РеквизитыФизическихЛицАнкетныеНаРусском.ЮрФизЛицо, РеквизитыФизическихЛицАнкетныеНаАнглийском.ЮрФизЛицо))
		|ГДЕ
		|	&ФильтрПроверяемыхЛиц
		|ИТОГИ ПО
		|	Ссылка";
#КонецОбласти
	
	Если ПроверяемыеЛица = Неопределено Тогда
		Запрос.Текст = СтрЗаменить(Запрос.Текст, "&ФильтрПроверяемыхЛиц", "ЮрФизЛица.ПометкаУдаления = ЛОЖЬ И ЮрФизЛица.ЭтоГруппа = ЛОЖЬ");
		Запрос.Текст = СтрЗаменить(Запрос.Текст, "&ФильтрАнкетПроверяемыхЛиц", "ИСТИНА");
		Запрос.Текст = СтрЗаменить(Запрос.Текст, "&ФильтрКонтактовПроверяемыхЛиц", "ИСТИНА");
	Иначе
		Запрос.Текст = СтрЗаменить(Запрос.Текст, "&ФильтрПроверяемыхЛиц", "ЮрФизЛица.Ссылка В (&ПроверяемыеЛица)");
		Запрос.Текст = СтрЗаменить(Запрос.Текст, "&ФильтрАнкетПроверяемыхЛиц", "ЮрФизЛицо В (&ПроверяемыеЛица)");
		Запрос.Текст = СтрЗаменить(Запрос.Текст, "&ФильтрКонтактовПроверяемыхЛиц", "Объект В (&ПроверяемыеЛица)");
		Запрос.УстановитьПараметр("ПроверяемыеЛица", ПроверяемыеЛица);
	КонецЕсли;	
	
	УстановитьПривилегированныйРежим(Истина); // т.к. требуются данные клиентов без отбора по организации
	ВыборкаЛиц = Запрос.Выполнить().Выбрать(ОбходРезультатаЗапроса.ПоГруппировкам);
	УстановитьПривилегированныйРежим(Ложь);
	
	РезультатСверки = Неопределено;
	РеквизитыСверки	= Новый Соответствие;

	Пока Истина Цикл
		МассивПартнеров		= Новый Массив;
		ДанныеПартнеров		= Новый Массив;
		КоличествоЗаписей	= 0;
		
		Пока ВыборкаЛиц.Следующий() Цикл
			МассивПартнеров.Добавить(ВыборкаЛиц.Ссылка);
			
			ВыборкаРеквизитовЛиц = ВыборкаЛиц.Выбрать(ОбходРезультатаЗапроса.Прямой);
			Пока ВыборкаРеквизитовЛиц.Следующий() Цикл
				КоличествоЗаписей = КоличествоЗаписей + 1;
				
				КлючСтрокиСверки = Строка(Новый УникальныйИдентификатор);
				
				ЗначенияРеквизитовСверки = Новый Структура("ИсточникДанных, Идентификатор, ЭтоОрганизация, ИНН, ОГРН");
				ЗаполнитьЗначенияСвойств(ЗначенияРеквизитовСверки, ВыборкаРеквизитовЛиц);
				ЗначенияРеквизитовСверки.Вставить("ДатаРождения", Формат(ВыборкаРеквизитовЛиц.ДатаРождения, "ДФ=yyyy/MM/dd"));
				ЗначенияРеквизитовСверки.Вставить("Наименование", СтрЗаменить(ВыборкаРеквизитовЛиц.Наименование, "'", "''"));
				ЗначенияРеквизитовСверки.Вставить("НаименованиеНаАнглийском", СтрЗаменить(ВыборкаРеквизитовЛиц.НаименованиеНаАнглийском, "'", "''"));
				ЗначенияРеквизитовСверки.Вставить("ЮридическийАдрес", СтрЗаменить(ВыборкаРеквизитовЛиц.ЮридическийАдрес, "'", "''"));
				ЗначенияРеквизитовСверки.Вставить("ПочтовыйАдрес", СтрЗаменить(ВыборкаРеквизитовЛиц.ПочтовыйАдрес, "'", "''"));
				ЗначенияРеквизитовСверки.Вставить("СерияУдостоверенияЛичности", СтрЗаменить(ВыборкаРеквизитовЛиц.СерияУдостоверенияЛичности, " ", ""));
				ЗначенияРеквизитовСверки.Вставить("НомерУдостоверенияЛичности", СтрЗаменить(ВыборкаРеквизитовЛиц.НомерУдостоверенияЛичности, " ", ""));
				ЗначенияРеквизитовСверки.Вставить("ДатаВыдачиУдостоверенияЛичности", Формат(ВыборкаРеквизитовЛиц.ДатаВыдачиУдостоверенияЛичности, "ДФ=yyyy/MM/dd"));
				ЗначенияРеквизитовСверки.Вставить("ОрганВыдавшийУдостоверениеЛичности", СтрЗаменить(ВыборкаРеквизитовЛиц.ОрганВыдавшийУдостоверениеЛичности, "'", "''"));
				РеквизитыСверки.Вставить(КлючСтрокиСверки, ЗначенияРеквизитовСверки);
				
				ДанныеПартнеров.Добавить(
					"SELECT"
					+ " '" + ЗначенияРеквизитовСверки.ИсточникДанных + "'" + ?(КоличествоЗаписей = 1, " Data_Source", "") 
					+ ", '" + ЗначенияРеквизитовСверки.Идентификатор + "'" + ?(КоличествоЗаписей = 1, " Partner_ID", "") 
					+ ", " + ЗначенияРеквизитовСверки.ЭтоОрганизация + ?(КоличествоЗаписей = 1, " Is_Firm", "")
					+ ", '" + ЗначенияРеквизитовСверки.ИНН + "'" + ?(КоличествоЗаписей = 1, " INN", "")
					+ ", '" + ЗначенияРеквизитовСверки.ОГРН + "'" + ?(КоличествоЗаписей = 1, " OGRN", "")
					+ ", '" + ЗначенияРеквизитовСверки.ДатаРождения + "'" + ?(КоличествоЗаписей = 1, " Birth_Date", "")
					+ ", '" + ЗначенияРеквизитовСверки.Наименование + "'" + ?(КоличествоЗаписей = 1, " Name_Ru", "")
					+ ", '" + ЗначенияРеквизитовСверки.НаименованиеНаАнглийском + "'" + ?(КоличествоЗаписей = 1, " Name_En", "")
					+ ", '" + ЗначенияРеквизитовСверки.ЮридическийАдрес + "'" + ?(КоличествоЗаписей = 1, " Address_Legal", "")
					+ ", '" + ЗначенияРеквизитовСверки.ПочтовыйАдрес + "'" + ?(КоличествоЗаписей = 1, " Address_Post", "")
					+ ", '" + ЗначенияРеквизитовСверки.СерияУдостоверенияЛичности + "'" + ?(КоличествоЗаписей = 1, " Document_Series", "")
					+ ", '" + ЗначенияРеквизитовСверки.НомерУдостоверенияЛичности + "'" + ?(КоличествоЗаписей = 1, " Document_Number", "")
					+ ", '" + ЗначенияРеквизитовСверки.ДатаВыдачиУдостоверенияЛичности + "'" + ?(КоличествоЗаписей = 1, " Document_Date", "")
					+ ", '" + ЗначенияРеквизитовСверки.ОрганВыдавшийУдостоверениеЛичности + "'" + ?(КоличествоЗаписей = 1, " Document_Issuer", "")
					+ ", '" + КлючСтрокиСверки + "'" + ?(КоличествоЗаписей = 1, " КлючСтрокиСверки", "")
					);
				
			КонецЦикла;	
			
			
			Если КоличествоЗаписей >= РазмерПакета Тогда
				Прервать;
			КонецЕсли;
		КонецЦикла;	
		
		Если КоличествоЗаписей = 0 Тогда
			Прервать;
		КонецЕсли;
		
		ПараметрПартнеры = СтрСоединить(ДанныеПартнеров, Символы.ПС + "UNION ALL" + Символы.ПС);	
		
		// Параметры
		ТекстЗапроса = СтрЗаменить(ШаблонЗапроса, "&ПорогТревоги", Формат(ПорогТревоги, "ЧГ="));
		ТекстЗапроса = СтрЗаменить(ТекстЗапроса, "&Партнеры", ПараметрПартнеры);
		
		// Получаем результат сверки со списками в Матрикс
		ТипыКолонок = Новый Структура;
		ТипыКолонок.Вставить("ИдентификаторЛица",	Новый ОписаниеТипов("Строка", , , , Новый КвалификаторыСтроки(9)));
		ТипыКолонок.Вставить("Пройдена",			Новый ОписаниеТипов("Булево"));
		ТипыКолонок.Вставить("Комментарий",			Новый ОписаниеТипов("Строка"));
		ТипыКолонок.Вставить("ИдентификаторСписка",	Новый ОписаниеТипов("Число"));		
		ТипыКолонок.Вставить("КлючСтрокиСверки",	Новый ОписаниеТипов("Строка"));		
		
		Попытка
			РезультатСверкиПакета = ADODBC_ПолучитьТаблицуДанныхССервера(СтрокаСоединения, ТекстЗапроса, ТипыКолонок, ПараметрыСоединения);
		Исключение
		КонецПопытки;
		
		// Добавляем в ошибки проверки			
		Если РезультатСверкиПакета = Неопределено Тогда
			Если ОшибкиСверки = Неопределено Тогда
				ОшибкиСверки = Новый Структура;
			КонецЕсли;
			
			Если Не ОшибкиСверки.Свойство("НеПроверенныеЛица") Тогда
				ОшибкиСверки.Вставить("НеПроверенныеЛица", Новый ТаблицаЗначений);
				ОшибкиСверки.НеПроверенныеЛица.Колонки.Добавить("Ссылка", Новый ОписаниеТипов("СправочникСсылка.ЮрФизЛица"));
				ОшибкиСверки.НеПроверенныеЛица.Колонки.Добавить("Комментарий", Новый ОписаниеТипов("Строка"));
			КонецЕсли;
			
			Для Каждого НепроверенныйПартнер Из МассивПартнеров Цикл
				НеПроверенноеЛицо = ОшибкиСверки.НеПроверенныеЛица.Добавить();
				НеПроверенноеЛицо.Ссылка		= НепроверенныйПартнер.Ссылка;
				НеПроверенноеЛицо.Комментарий	= "Ошибка при выполнении запроса";
			КонецЦикла;
			
			Продолжить;
		КонецЕсли;

		Если РезультатСверки = Неопределено Тогда
			РезультатСверки = РезультатСверкиПакета;
		Иначе
			
			// Проверяем, что за время сверки список не изменился
			Если РезультатСверки.Количество() > 0
				И РезультатСверкиПакета.Количество() > 0
				И РезультатСверки[0].ИдентификаторСписка <> РезультатСверкиПакета[0].ИдентификаторСписка
			Тогда
				ОбщегоНазначенияКлиентСервер.СообщитьПользователю("Во время выполнения сверки произошло изменение списка лиц с замороженными счетами. Необходимо выполнить сверку повторно.");
				Возврат Неопределено;
			КонецЕсли;
			
			РаботаСКоллекциями.ТаблицаЗначений_Дополнить(РезультатСверкиПакета, РезультатСверки); 
		КонецЕсли;
	КонецЦикла;
	
	Если РезультатСверки = Неопределено Тогда
		Возврат Неопределено;
	КонецЕсли;
	
	Запрос = Новый Запрос("
		|ВЫБРАТЬ РАЗРЕШЕННЫЕ
		|	РезультатСверки.ИдентификаторЛица КАК ИдентификаторЛица,
		|	РезультатСверки.Пройдена КАК Пройдена,
		|	РезультатСверки.Комментарий КАК Комментарий,
		|	РезультатСверки.КлючСтрокиСверки
		|ПОМЕСТИТЬ
		|	_РезультатСверки
		|ИЗ
		|	&РезультатСверки КАК РезультатСверки
		|;
		|
		|ВЫБРАТЬ РАЗРЕШЕННЫЕ
		|	ЮрФизЛица.Ссылка КАК ЮрФизЛицо,
		|	РезультатСверки.Пройдена КАК Пройдена,
		|	РезультатСверки.Комментарий КАК Комментарий,
		|	РезультатСверки.КлючСтрокиСверки КАК КлючСтрокиСверки
		|ИЗ
		|	Справочник.ЮрФизЛица КАК ЮрФизЛица
		|	ВНУТРЕННЕЕ СОЕДИНЕНИЕ _РезультатСверки КАК РезультатСверки
		|		ПО РезультатСверки.ИдентификаторЛица = ЮрФизЛица.Код
		|");
	Запрос.УстановитьПараметр("РезультатСверки", РезультатСверки);
	
	// Получаем проверенные лица
	ПроверенныеЛица	= Запрос.Выполнить().Выгрузить();
	ПроверенныеЛица.Колонки.Добавить("РеквизитыСверки", Новый ОписаниеТипов("ХранилищеЗначения"));
	
	Для Каждого СтрокаДанных Из ПроверенныеЛица Цикл
		СтрокаДанных.РеквизитыСверки = Новый ХранилищеЗначения(РеквизитыСверки.Получить(СтрокаДанных.КлючСтрокиСверки));
	КонецЦикла;

	ПроверенныеЛица.Колонки.Удалить("КлючСтрокиСверки");
		
	Возврат ПроверенныеЛица;
КонецФункции

// Функция - Возвращает результаты сверки юр./физ. лиц со списком лиц, которым отказано в операции с ДС, открытии или закрытии депозитного вклада
// 
// Параметры:
//	ПроверяемыеЛица	 - Массив - (Необязательный) Содержит массив проверяемых юр./физ. лиц
//						Если не указан, проводится сверка по полному списку юр./физ. лиц
//	ОшибкиСверки	 - Структура - (Необязательный, Выходной) В случае ошибок сверки возвращает структуру с описанием ошибок
//						Может содержать именованные таблицы:
//						- НеПроверенныеЛица: Ссылка (СправочникСсылка.ЮрФизЛица), Код (Строка), Категория (Строка)
//						- ОшибкиПоискаКодаВоВнешнейСистеме: Ссылка (СправочникСсылка.ЮрФизЛица)   
// 
// Возвращаемое значение:
//	ТаблицаЗначений, Неопределено - таблица успешно прошедших проверку лиц, Неопределено - в случае ошибки
//									Структура таблицы: ЮрФизЛицо (СправочникСсылка.ЮрФизЛица), Пройдена (Булево), Комментарий (Строка)
//
//
Функция ПолучитьРезультатСверкиСоСпискомОтказников(Организация, Период, ПроверяемыеЛица = Неопределено, ИдентификаторСписка, ОшибкиСверки = Неопределено) Экспорт	
	
	Перем ПроверенныеЛица; 	
	
	// Инициализация вспомогательных переменных
	ПорогТревоги		= 5;	
	СтрокаСоединения	= СтрокаСоединенияСExternals();
	ПараметрыСоединения = Новый Структура("CommandTimeout", 180);	
	РазмерПакета		= 300; // Количество отправляемых на проверку лиц
	
#Область ШаблонЗапросаЮрЛиц
	ШаблонЗапросаЮрЛиц	= "
		|SET NOCOUNT ON
		|;
		|
		|IF OBJECT_ID('tempdb..#Partners') IS NOT NULL
		|	Drop Table #Partners
		|;
		|IF OBJECT_ID('tempdb..#DecisionsSubjects') IS NOT NULL
		|	Drop Table #DecisionsSubjects
		|;		
		|IF OBJECT_ID('tempdb..#SuspectPartners') IS NOT NULL
		|	Drop Table #SuspectPartners
		|;
		|IF OBJECT_ID('tempdb..#LastDecisionsList') IS NOT NULL
		|	Drop Table #LastDecisionsList
		|;
		|
		|CREATE TABLE #Partners(
		|	Row_Index bigint IDENTITY(1,1),
		|	Data_Source nvarchar(15),
		|	Partner_ID nvarchar(9),
		|	Name_Clean nvarchar(4000),
		|	Name nvarchar(4000),
		|	Name_Full_Clean nvarchar(4000),
		|	Name_Full nvarchar(4000),
		|	INN nvarchar(12),
		|	RegistrationNumber nvarchar(100),
		|	[language] nvarchar(5),
		|	КлючСтрокиСверки nvarchar(36)
		|)
		|;
		|
		|INSERT INTO
		|	#Partners
		|SELECT
		|	Data_Source,
		|	Partner_ID,
		|	Name_Clean = dbo.RemoveExtraChar(Name),
		|	Name,
		|	Name_Full_Clean = dbo.RemoveExtraChar(Name_Full),
		|	Name_Full,
		|	INN,
		|	RegistrationNumber,
		|	[language],
		|	КлючСтрокиСверки
		|FROM (
		|	&Партнеры
		|) Partners
		|; 
		|
		|SELECT DISTINCT
		|	RefusalList.[File_Id],
		|	[Files].[File_Name], 
		|	RefusalList.[Period],
		|	RefusalList.[Organization]
		|INTO
		|	#LastDecisionsList		
		|FROM
		|	[Externals].[dbo].[RefusalList] [RefusalList]
		|LEFT JOIN
		|	[Externals].[dbo].[Files] [Files] 
		|		ON [RefusalList].[File_Id] = [Files].[Id]
		|WHERE
		|	RefusalList.Source_Id = 6 -- Перечень юридических и физических лиц предусмотренный Положением Банка России от 20 июля 2016 года № 550-П 
		|	AND RefusalList.Organization = '&Организация'
		|	--AND RefusalList.[Period] <= CONVERT(datetime, '&Период')
		|	AND ([RefusalList].[File_Id] = &ИдентификаторСписка OR &ИдентификаторСписка = 0)  -- пользователь выбрал перечень или по всем перечням
		|ORDER BY
		|	RefusalList.[Period] DESC
		|;
		|
		|CREATE TABLE #DecisionsSubjects(
		|	ID bigint,
		|	File_ID bigint,
		|	Name nvarchar(4000),
		|	Name_Clean nvarchar(4000),
		|	RegistrationNumber nvarchar(50),
		|	INN nvarchar(12)
		|)
		|;		
		|
		|INSERT INTO
		|	#DecisionsSubjects
		|SELECT
		|	[ID] = RefusalList.ID,
		|	[File_ID] = RefusalList.File_Id,
		|	[Name] = RefusalList.Name,
		|	[Name_Clean] = RefusalList.Name_Clean,
		|	[RegistrationNumber] = RefusalList.RegistrationNumber,
		|	[INN] = RefusalList.INN
		|FROM [Externals].[dbo].[RefusalList] [RefusalList]
		|	INNER JOIN #LastDecisionsList [LastDecisionsList]
		|		ON LastDecisionsList.File_Id = RefusalList.File_Id
		|		AND LastDecisionsList.Organization = RefusalList.Organization
		|		AND RefusalList.Is_Firm = 1
		|;
		|		
		|SELECT
		|	[Row_Index] = P.Row_Index,
		|	[Data_Source] = P.Data_Source,
		|	[Partner_ID] = P.Partner_ID,
		|	[DecisionsSubject_ID] = DS.ID,
		|	[DecisionsSubject_File_ID] = DS.File_ID,
		|	[DecisionsSubject_Name] = DS.Name,
		|	[Intersections] = (CASE WHEN DS.Name_Clean = P.Name_Clean THEN 'Наименование (' + P.[language] + '), ' ELSE '' END)
		|					+ (CASE WHEN DS.Name_Clean = P.Name_Full_Clean THEN 'Полное наименование (' + P.[language] + '), ' ELSE '' END)
		|					+ (CASE WHEN DS.INN = P.INN THEN 'ИНН, ' ELSE '' END)
		|					+ (CASE WHEN DS.RegistrationNumber = P.RegistrationNumber THEN 'Рег.номер, ' ELSE '' END),
		|	[Sum_Rank] = (CASE WHEN DS.INN = P.INN THEN 5 ELSE 0 END)
		|					+ (CASE WHEN DS.RegistrationNumber = P.RegistrationNumber THEN 5 ELSE 0 END)
		|					+ (CASE WHEN CharIndex(P.Name_Clean, DS.Name_Clean) > 0 THEN 3 ELSE 0 END)
		|					+ (CASE WHEN CharIndex(P.Name_Full_Clean, DS.Name_Clean) > 0 THEN 3 ELSE 0 END)
		|INTO
		|	#SuspectPartners
		|FROM #Partners as P
		|	INNER JOIN #DecisionsSubjects [DS]
		|	ON
		|			DS.INN = P.INN
		|			OR DS.RegistrationNumber = P.RegistrationNumber
		|			OR CharIndex(P.Name_Clean, DS.Name_Clean) > 0
		|			OR CharIndex(P.Name_Full_Clean, DS.Name_Clean) > 0
		|WHERE
		|	(CASE WHEN DS.INN = P.INN THEN 5 ELSE 0 END)
		|	+ (CASE WHEN DS.RegistrationNumber = P.RegistrationNumber THEN 5 ELSE 0 END)
		|	+ (CASE WHEN CharIndex(P.Name_Clean, DS.Name_Clean) > 0 THEN 3 ELSE 0 END)
		|	+ (CASE WHEN CharIndex(P.Name_Full_Clean, DS.Name_Clean) > 0 THEN 3 ELSE 0 END) >= &ПорогТревоги
		|;
		|
		|SELECT DISTINCT
		|	[ИдентификаторЛица] = Partners.Partner_ID,
		|	[Пройдена] = 
		|		CASE
		|			WHEN SuspectPartners.Partner_ID IS NULL
		|				THEN 1
		|			ELSE 0
		|		END,
		|	[Комментарий] = 
		|		CASE
		|			WHEN SuspectPartners.Partner_ID IS NULL
		|				THEN 'Список отказников от ' + CONVERT(nvarchar(10), LastDecisionsList.Period, 104)
		|			ELSE 'Найдены совпадения данных ' + SuspectPartners.Data_Source
		|				+ ' с данными Списка отказников от ' + CONVERT(nvarchar(10), LastDecisionsList.Period, 104)
		|				+ ' с [' + CAST(SuspectPartners.DecisionsSubject_ID  AS nvarchar(9)) + '] '
		|				+ SuspectPartners.DecisionsSubject_Name + ' по ' + SuspectPartners.Intersections
		|				+ 'суммарная оценка ' + CAST(SuspectPartners.Sum_Rank AS nvarchar(3))
		|		END,
		|	[ИдентификаторСписка] = LastDecisionsList.[File_Name],
		|	[КлючСтрокиСверки] = [Partners].КлючСтрокиСверки
		|FROM #Partners [Partners] 
		|	LEFT JOIN #SuspectPartners [SuspectPartners]
		|		INNER JOIN (
		|			SELECT
		|				SuspectPartnersForRow.Partner_ID,
		|				MAX(SuspectPartnersForRow.Row_Index) [Max_Row]	
		|			FROM
		|				#SuspectPartners [SuspectPartnersForRow]	
		|				INNER JOIN (
		|					SELECT
		|						SuspectPartnersForRank.Partner_ID,
		|						MAX(SuspectPartnersForRank.Sum_Rank) [Sum_Rank]
		|					FROM #SuspectPartners [SuspectPartnersForRank]
		|					GROUP BY
		|						SuspectPartnersForRank.Partner_ID
		|				) [MaxRankSuspicion]
		|				ON MaxRankSuspicion.Partner_ID = SuspectPartnersForRow.Partner_ID
		|					AND MaxRankSuspicion.Sum_Rank = SuspectPartnersForRow.Sum_Rank
		|			GROUP BY
		|				SuspectPartnersForRow.Partner_ID	
		|		) [SuspectPartnersCleared]
		|		ON SuspectPartnersCleared.Partner_ID = SuspectPartners.Partner_ID
		|			AND SuspectPartnersCleared.Max_Row = SuspectPartners.Row_Index
		|	ON SuspectPartners.Partner_ID = Partners.Partner_ID
		|	LEFT JOIN #LastDecisionsList [LastDecisionsList]
		|	ON SuspectPartners.DecisionsSubject_File_ID = LastDecisionsList.File_Id
		|;
		|
		|IF OBJECT_ID('tempdb..#Partners') IS NOT NULL
		|	Drop Table #Partners
		|;
		|IF OBJECT_ID('tempdb..#DecisionsSubjects') IS NOT NULL
		|	Drop Table #DecisionsSubjects
		|;		
		|IF OBJECT_ID('tempdb..#SuspectPartners') IS NOT NULL
		|	Drop Table #SuspectPartners
		|;
		|IF OBJECT_ID('tempdb..#LastDecisionsList') IS NOT NULL
		|	Drop Table #LastDecisionsList
		|;
		|";	
#КонецОбласти
	
#Область ШаблонЗапросаФизЛиц
	ШаблонЗапросаФизЛиц	= "
		|SET NOCOUNT ON
		|;
		|
		|IF OBJECT_ID('tempdb..#Partners') IS NOT NULL
		|	Drop Table #Partners
		|;
		|IF OBJECT_ID('tempdb..#DecisionsSubjects') IS NOT NULL
		|	Drop Table #DecisionsSubjects
		|;		
		|IF OBJECT_ID('tempdb..#SuspectPartners') IS NOT NULL
		|	Drop Table #SuspectPartners
		|;
		|IF OBJECT_ID('tempdb..#LastDecisionsList') IS NOT NULL
		|	Drop Table #LastDecisionsList
		|;
		|
		|CREATE TABLE #Partners(
		|	Row_Index bigint IDENTITY(1,1),
		|	Data_Source nvarchar(15),
		|	Partner_ID nvarchar(9),
		|	LastName_Clean nvarchar(100),
		|	LastName nvarchar(100),
		|	FirstName_Clean nvarchar(100),
		|	FirstName nvarchar(100),
		|	MiddleName_Clean nvarchar(100),
		|	MiddleName nvarchar(100),
		|	BirthDate date,
		|	INN nvarchar(12),
		|	RegistrationNumber nvarchar(100),
		|	[language] nvarchar(5),
		|	КлючСтрокиСверки nvarchar(36)
		|)
		|;
		|
		|INSERT INTO
		|	#Partners
		|SELECT
		|	Data_Source,
		|	Partner_ID,
		|	LastName_Clean = dbo.RemoveExtraChar(LastName),
		|	LastName,
		|	FirstName_Clean = dbo.RemoveExtraChar(FirstName),
		|	FirstName,
		|	MiddleName_Clean = dbo.RemoveExtraChar(MiddleName),
		|	MiddleName,
		|	BirthDate,
		|	INN,
		|	RegistrationNumber,
		|	[language],
		|	КлючСтрокиСверки
		|FROM (
		|	&Партнеры
		|) Partners
		|; 
		|
		|SELECT DISTINCT
		|	RefusalList.[File_Id],
		|	[Files].[File_Name], 
		|	RefusalList.[Period],
		|	RefusalList.[Organization]
		|INTO
		|	#LastDecisionsList		
		|FROM
		|	[Externals].[dbo].[RefusalList] [RefusalList]
		|LEFT JOIN
		|	[Externals].[dbo].[Files] [Files] 
		|		ON [RefusalList].[File_Id] = [Files].[Id]
		|WHERE
		|	RefusalList.Source_Id = 6 -- Перечень юридических и физических лиц предусмотренный Положением Банка России от 20 июля 2016 года № 550-П 
		|	AND RefusalList.Organization = '&Организация'
		|	--AND RefusalList.[Period] <= CONVERT(datetime, '&Период')
		|	AND ([RefusalList].[File_Id] = &ИдентификаторСписка OR &ИдентификаторСписка = 0)  -- пользователь выбрал перечень или по всем перечням
		|ORDER BY
		|	RefusalList.[Period] DESC
		|;
		|
		|CREATE TABLE #DecisionsSubjects(
		|	ID bigint,
		|	File_Id bigint,
		|	LastName nvarchar(100),
		|	LastName_Clean nvarchar(100),
		|	FirstName nvarchar(100),
		|	FirstName_Clean nvarchar(100),
		|	MiddleName nvarchar(100),
		|	MiddleName_Clean nvarchar(100),
		|	BirthDate date,
		|	RegistrationNumber nvarchar(50),
		|	INN nvarchar(12)
		|)
		|;		
		|
		|INSERT INTO
		|	#DecisionsSubjects
		|SELECT
		|	[ID] = RefusalList.ID,
		|	[File_ID] = RefusalList.File_Id,
		|	[LastName] = RefusalList.LastName,
		|	[LastName_Clean] = RefusalList.LastName_Clean,
		|	[FirstName] = RefusalList.FirstName,
		|	[FirstName_Clean] = RefusalList.FirstName_Clean,
		|	[MiddleName] = RefusalList.MiddleName,
		|	[MiddleName_Clean] = RefusalList.MiddleName_Clean,
		|	[BirthDate] = RefusalList.BirthDate,
		|	[RegistrationNumber] = RefusalList.RegistrationNumber,
		|	[INN] = RefusalList.INN
		|FROM [Externals].[dbo].[RefusalList] [RefusalList]
		|	INNER JOIN #LastDecisionsList [LastDecisionsList]
		|		ON LastDecisionsList.File_Id = RefusalList.File_Id
		|		AND LastDecisionsList.Organization = RefusalList.Organization
		|		AND RefusalList.Is_Firm = 0
		|;
		|		
		|SELECT
		|	[Row_Index] = P.Row_Index,
		|	[Data_Source] = P.Data_Source,
		|	[Partner_ID] = P.Partner_ID,
		|	[DecisionsSubject_ID] = DS.ID,
		|	[DecisionsSubject_File_ID] = DS.File_ID,
		|	[DecisionsSubject_Name] =  DS.LastName + ' ' + DS.FirstName + ' ' + DS.MiddleName,
		|	[Intersections] = (CASE WHEN DS.LastName_Clean = P.LastName_Clean AND P.LastName_Clean <> '' THEN 'Фамилия (' + P.[language] + '), ' ELSE '' END)
		|					+ (CASE WHEN DS.FirstName_Clean = P.FirstName_Clean AND P.FirstName_Clean <> '' THEN 'Имя (' + P.[language] + '), ' ELSE '' END)
		|					+ (CASE WHEN DS.MiddleName_Clean = P.MiddleName_Clean THEN 'Отчество (' + P.[language] + '), ' ELSE '' END)
		|					+ (CASE WHEN DS.BirthDate = P.BirthDate THEN 'Дата рождения, ' ELSE '' END)
		|					+ (CASE WHEN DS.INN = P.INN AND P.INN <> '' THEN 'ИНН, ' ELSE '' END)
		|					+ (CASE WHEN DS.RegistrationNumber = P.RegistrationNumber AND P.RegistrationNumber <> '' THEN 'Документ, ' ELSE '' END),
		|	[Sum_Rank] = (CASE WHEN DS.LastName_Clean = P.LastName_Clean AND P.LastName_Clean <> '' THEN 2 ELSE 0 END)
		|				+ (CASE WHEN DS.FirstName_Clean = P.FirstName_Clean AND P.FirstName_Clean <> '' THEN 2 ELSE 0 END)
		|				+ (CASE WHEN DS.MiddleName_Clean = P.MiddleName_Clean THEN 1 ELSE 0 END)
		|				+ (CASE WHEN DS.BirthDate = P.BirthDate THEN 2 ELSE 0 END)
		|				+ (CASE WHEN DS.RegistrationNumber = P.RegistrationNumber AND P.RegistrationNumber <> '' THEN 5 ELSE 0 END)
		|				+ (CASE WHEN DS.INN = P.INN AND P.INN <> '' THEN 5 ELSE 0 END)
		|INTO
		|	#SuspectPartners
		|FROM #Partners as P
		|	INNER JOIN #DecisionsSubjects [DS]
		|	ON 	DS.INN = P.INN AND P.INN <> ''
		|		OR DS.LastName_Clean = P.LastName_Clean AND P.LastName_Clean <> ''
		|		OR DS.FirstName_Clean = P.FirstName_Clean AND P.FirstName_Clean <> ''
		|		OR DS.MiddleName_Clean = P.MiddleName_Clean
		|		OR DS.BirthDate = P.BirthDate
		|		OR DS.RegistrationNumber = P.RegistrationNumber AND P.RegistrationNumber <> ''
		|WHERE
		|	(CASE WHEN DS.LastName_Clean = P.LastName_Clean AND P.LastName_Clean <> '' THEN 2 ELSE 0 END)
		|	+ (CASE WHEN DS.FirstName_Clean = P.FirstName_Clean AND P.FirstName_Clean <> '' THEN 2 ELSE 0 END)
		|	+ (CASE WHEN DS.MiddleName_Clean = P.MiddleName_Clean THEN 1 ELSE 0 END)
		|	+ (CASE WHEN DS.BirthDate = P.BirthDate THEN 2 ELSE 0 END)
		|	+ (CASE WHEN DS.RegistrationNumber = P.RegistrationNumber AND P.RegistrationNumber <> '' THEN 5 ELSE 0 END)
		|	+ (CASE WHEN DS.INN = P.INN AND P.INN <> '' THEN 5 ELSE 0 END) >= &ПорогТревоги
		|;
		|
		|SELECT DISTINCT
		|	[ИдентификаторЛица] = Partners.Partner_ID,
		|	[Пройдена] = 
		|		CASE
		|			WHEN SuspectPartners.Partner_ID IS NULL
		|				THEN 1
		|			ELSE 0
		|		END,
		|	[Комментарий] = 
		|		CASE
		|			WHEN SuspectPartners.Partner_ID IS NULL
		|				THEN 'Список отказников от ' + CONVERT(nvarchar(10), LastDecisionsList.Period, 104)
		|			ELSE 'Найдены совпадения данных ' + SuspectPartners.Data_Source
		|				+ ' с данными Списка отказников от ' + CONVERT(nvarchar(10), LastDecisionsList.Period, 104)
		|				+ ' с [' + CAST(SuspectPartners.DecisionsSubject_ID  AS nvarchar(9)) + '] '
		|				+ SuspectPartners.DecisionsSubject_Name + ' по ' + SuspectPartners.Intersections
		|				+ 'суммарная оценка ' + CAST(SuspectPartners.Sum_Rank AS nvarchar(3))
		|		END,
		|	[ИдентификаторСписка] = LastDecisionsList.[File_Name],
		|	[КлючСтрокиСверки] = [Partners].КлючСтрокиСверки
		|FROM #Partners [Partners] 
		|	LEFT JOIN #SuspectPartners [SuspectPartners]
		|		INNER JOIN (
		|			SELECT
		|				SuspectPartnersForRow.Partner_ID,
		|				MAX(SuspectPartnersForRow.Row_Index) [Max_Row]	
		|			FROM
		|				#SuspectPartners [SuspectPartnersForRow]	
		|				INNER JOIN (
		|					SELECT
		|						SuspectPartnersForRank.Partner_ID,
		|						MAX(SuspectPartnersForRank.Sum_Rank) [Sum_Rank]
		|					FROM #SuspectPartners [SuspectPartnersForRank]
		|					GROUP BY
		|						SuspectPartnersForRank.Partner_ID
		|				) [MaxRankSuspicion]
		|				ON MaxRankSuspicion.Partner_ID = SuspectPartnersForRow.Partner_ID
		|					AND MaxRankSuspicion.Sum_Rank = SuspectPartnersForRow.Sum_Rank
		|			GROUP BY
		|				SuspectPartnersForRow.Partner_ID	
		|		) [SuspectPartnersCleared]
		|		ON SuspectPartnersCleared.Partner_ID = SuspectPartners.Partner_ID
		|			AND SuspectPartnersCleared.Max_Row = SuspectPartners.Row_Index
		|	ON SuspectPartners.Partner_ID = Partners.Partner_ID
		|	LEFT JOIN #LastDecisionsList [LastDecisionsList]
		|	ON SuspectPartners.DecisionsSubject_File_ID = LastDecisionsList.File_Id
		|;
		|
		|IF OBJECT_ID('tempdb..#Partners') IS NOT NULL
		|	Drop Table #Partners
		|;
		|IF OBJECT_ID('tempdb..#DecisionsSubjects') IS NOT NULL
		|	Drop Table #DecisionsSubjects
		|;		
		|IF OBJECT_ID('tempdb..#SuspectPartners') IS NOT NULL
		|	Drop Table #SuspectPartners
		|;
		|IF OBJECT_ID('tempdb..#LastDecisionsList') IS NOT NULL
		|	Drop Table #LastDecisionsList
		|;
		|";	
#КонецОбласти
	
	// Подготовим параметр для передачи таблицы на сервер
	Запрос = Новый Запрос;
	
	Справочники.ЮрФизЛица.ПоместитьКлиентовВМенеджерВременныхТаблиц(Запрос, Организация, Период);
	
	#Область ТекстЗапроса
	Запрос.Текст = 
		"ВЫБРАТЬ РАЗРЕШЕННЫЕ РАЗЛИЧНЫЕ
		|	ЮрФизЛица.Ссылка КАК Ссылка,
		|	ВЫБОР
		|		КОГДА ЮрФизЛица.ВидЮрФизЛица = ЗНАЧЕНИЕ(Перечисление.ВидыЮрФизЛиц.ЮридическоеЛицо)
		|			ТОГДА 1
		|		ИНАЧЕ 0
		|	КОНЕЦ КАК ЭтоОрганизация,
		|	ЮрФизЛица.Код КАК Идентификатор,
		|	Организации.ПрефиксНумерации КАК ИсточникДанных
		|ПОМЕСТИТЬ ВТ_Клиенты
		|ИЗ
		|	(ВЫБРАТЬ
		|		_Клиенты.ЮрФизЛицо КАК ЮрФизЛицо,
		|		_Клиенты.Организация КАК Организация
		|	ИЗ
		|		_Клиенты КАК _Клиенты
		|	
		|	ОБЪЕДИНИТЬ
		|	
		|	ВЫБРАТЬ
		|		ЮрФизЛица.Ссылка,
		|		&Организация
		|	ИЗ
		|		Справочник.ЮрФизЛица КАК ЮрФизЛица
		|	ГДЕ
		|		ЮрФизЛица.Ссылка В(&ПроверяемыеЛица)) КАК ВложенныйЗапрос
		|		ВНУТРЕННЕЕ СОЕДИНЕНИЕ Справочник.ЮрФизЛица КАК ЮрФизЛица
		|		ПО ВложенныйЗапрос.ЮрФизЛицо = ЮрФизЛица.Ссылка
		|		ВНУТРЕННЕЕ СОЕДИНЕНИЕ Справочник.Организации КАК Организации
		|		ПО ВложенныйЗапрос.Организация = Организации.Ссылка
		|ГДЕ
		|	&ФильтрПроверяемыхЛиц
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|ВЫБРАТЬ РАЗРЕШЕННЫЕ
		|	ВТ_Клиенты.ЭтоОрганизация КАК ЭтоОрганизация,
		|	ВТ_Клиенты.Ссылка КАК Ссылка,
		|	""ГК Регион"" КАК ИсточникДанных,
		|	ВТ_Клиенты.Идентификатор КАК Идентификатор,
		|	РеквизитыЮридическихЛиц.ПолноеНаименованиеПоУставу КАК ПолноеНаименование,
		|	РеквизитыЮридическихЛиц.КраткоеНаименованиеПоУставу КАК КраткоеНаименование,
		|	РеквизитыЮридическихЛиц.ИНН КАК ИНН,
		|	ВЫБОР
		|		КОГДА РеквизитыЮридическихЛиц.РезидентРФ
		|			ТОГДА ДокументыЮридическихЛицСрезПоследних.Номер
		|		ИНАЧЕ РеквизитыЮридическихЛиц.TIN
		|	КОНЕЦ КАК РегистрационныйНомер,
		|	ВЫБОР РеквизитыЮридическихЛиц.Язык
		|		КОГДА ЗНАЧЕНИЕ(Справочник.Языки.Русский)
		|			ТОГДА ""Рус.""
		|		КОГДА ЗНАЧЕНИЕ(Справочник.Языки.Английский)
		|			ТОГДА ""Англ.""
		|	КОНЕЦ КАК Язык
		|ИЗ
		|	ВТ_Клиенты КАК ВТ_Клиенты
		|		ВНУТРЕННЕЕ СОЕДИНЕНИЕ РегистрСведений.РеквизитыЮридическихЛиц.СрезПоследних(
		|				&Период,
		|				Подразделение = ЗНАЧЕНИЕ(Справочник.Подразделения.ГруппаКомпаний)
		|					И &ФильтрАнкетПроверяемыхЛиц) КАК РеквизитыЮридическихЛиц
		|		ПО ВТ_Клиенты.Ссылка = РеквизитыЮридическихЛиц.ЮрФизЛицо
		|		ЛЕВОЕ СОЕДИНЕНИЕ РегистрСведений.ДокументыЮридическихЛиц.СрезПоследних(
		|				&Период,
		|				Подразделение = ЗНАЧЕНИЕ(Справочник.Подразделения.ГруппаКомпаний)
		|					И Язык = ЗНАЧЕНИЕ(Справочник.Языки.Русский)
		|					И Вид = ЗНАЧЕНИЕ(Перечисление.ВидыДокументовЮридическихЛиц.СвидетельствоОГосударственнойРегистрации)
		|					И &ФильтрАнкетПроверяемыхЛиц) КАК ДокументыЮридическихЛицСрезПоследних
		|		ПО ВТ_Клиенты.Ссылка = ДокументыЮридическихЛицСрезПоследних.ЮрФизЛицо
		|			И (ДокументыЮридическихЛицСрезПоследних.ДействуетПо = ДАТАВРЕМЯ(1, 1, 1)
		|				ИЛИ ДокументыЮридическихЛицСрезПоследних.ДействуетПо > &Период)
		|ГДЕ
		|	ВТ_Клиенты.ЭтоОрганизация = 1
		|
		|ОБЪЕДИНИТЬ ВСЕ
		|
		|ВЫБРАТЬ
		|	ВТ_Клиенты.ЭтоОрганизация,
		|	ВТ_Клиенты.Ссылка,
		|	ВТ_Клиенты.ИсточникДанных,
		|	ВТ_Клиенты.Идентификатор,
		|	РеквизитыЮридическихЛицАнкетные.ПолноеНаименованиеПоУставу,
		|	РеквизитыЮридическихЛицАнкетные.КраткоеНаименованиеПоУставу,
		|	РеквизитыЮридическихЛицАнкетные.ИНН,
		|	ВЫБОР
		|		КОГДА РеквизитыЮридическихЛицАнкетные.РезидентРФ
		|			ТОГДА РеквизитыЮридическихЛицАнкетные.ОГРН
		|		ИНАЧЕ РеквизитыЮридическихЛицАнкетные.TIN
		|	КОНЕЦ,
		|	ВЫБОР РеквизитыЮридическихЛицАнкетные.Язык
		|		КОГДА ЗНАЧЕНИЕ(Справочник.Языки.Русский)
		|			ТОГДА ""Рус.""
		|		КОГДА ЗНАЧЕНИЕ(Справочник.Языки.Английский)
		|			ТОГДА ""Англ.""
		|	КОНЕЦ
		|ИЗ
		|	ВТ_Клиенты КАК ВТ_Клиенты
		|		ВНУТРЕННЕЕ СОЕДИНЕНИЕ РегистрСведений.РеквизитыЮридическихЛицАнкетные.СрезПоследних(
		|				&Период,
		|				Организация = &Организация
		|					И &ФильтрАнкетПроверяемыхЛиц) КАК РеквизитыЮридическихЛицАнкетные
		|		ПО ВТ_Клиенты.Ссылка = РеквизитыЮридическихЛицАнкетные.ЮрФизЛицо
		|ГДЕ
		|	ВТ_Клиенты.ЭтоОрганизация = 1
		|ИТОГИ ПО
		|	Ссылка
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|ВЫБРАТЬ РАЗРЕШЕННЫЕ
		|	ВТ_Клиенты.ЭтоОрганизация КАК ЭтоОрганизация,
		|	ВТ_Клиенты.Ссылка КАК Ссылка,
		|	ВТ_Клиенты.ИсточникДанных КАК ИсточникДанных,
		|	ВТ_Клиенты.Идентификатор КАК Идентификатор,
		|	РеквизитыФизическихЛицАнкетныеСрезПоследних.Фамилия КАК Фамилия,
		|	РеквизитыФизическихЛицАнкетныеСрезПоследних.Имя КАК Имя,
		|	РеквизитыФизическихЛицАнкетныеСрезПоследних.Отчество КАК Отчество,
		|	РеквизитыФизическихЛицАнкетныеСрезПоследних.ДатаРождения КАК ДатаРождения,
		|	РеквизитыФизическихЛицАнкетныеСрезПоследних.ИНН КАК ИНН,
		|	РеквизитыФизическихЛицАнкетныеСрезПоследних.СерияУдостоверенияЛичности + РеквизитыФизическихЛицАнкетныеСрезПоследних.НомерУдостоверенияЛичности КАК РегистрационныйНомер,
		|	ВЫБОР РеквизитыФизическихЛицАнкетныеСрезПоследних.Язык
		|		КОГДА ЗНАЧЕНИЕ(Справочник.Языки.Русский)
		|			ТОГДА ""Рус.""
		|		КОГДА ЗНАЧЕНИЕ(Справочник.Языки.Английский)
		|			ТОГДА ""Англ.""
		|	КОНЕЦ КАК Язык
		|ИЗ
		|	ВТ_Клиенты КАК ВТ_Клиенты
		|		ВНУТРЕННЕЕ СОЕДИНЕНИЕ РегистрСведений.РеквизитыФизическихЛицАнкетные.СрезПоследних(
		|				&Период,
		|				Организация = &Организация
		|					И &ФильтрАнкетПроверяемыхЛиц) КАК РеквизитыФизическихЛицАнкетныеСрезПоследних
		|		ПО ВТ_Клиенты.Ссылка = РеквизитыФизическихЛицАнкетныеСрезПоследних.ЮрФизЛицо
		|ГДЕ
		|	ВТ_Клиенты.ЭтоОрганизация = 0
		|ИТОГИ ПО
		|	Ссылка";
#КонецОбласти

	Если ПроверяемыеЛица = Неопределено Тогда
		Запрос.Текст = СтрЗаменить(Запрос.Текст, "&ФильтрПроверяемыхЛиц", "ЮрФизЛица.ПометкаУдаления = ЛОЖЬ И ЮрФизЛица.ЭтоГруппа = ЛОЖЬ");
		Запрос.Текст = СтрЗаменить(Запрос.Текст, "&ФильтрАнкетПроверяемыхЛиц", "ИСТИНА");
	Иначе
		Запрос.Текст = СтрЗаменить(Запрос.Текст, "&ФильтрПроверяемыхЛиц", "ЮрФизЛица.Ссылка В (&ПроверяемыеЛица)");
		Запрос.Текст = СтрЗаменить(Запрос.Текст, "&ФильтрАнкетПроверяемыхЛиц", "ЮрФизЛицо В (&ПроверяемыеЛица)");
	КонецЕсли;	
	
	Запрос.УстановитьПараметр("ПроверяемыеЛица", ПроверяемыеЛица);
	Запрос.УстановитьПараметр("Период", Период);
	Запрос.УстановитьПараметр("Организация", Организация);
	
	Пакет = Запрос.ВыполнитьПакет();
	РезультатСверки = Неопределено;
	РеквизитыСверки	= Новый Соответствие;

	//1 - Юр лица
	//2 - Физ лица
	Для Индекс = 1 По 2 Цикл
		ВыборкаЛиц = Пакет[Индекс].Выбрать(ОбходРезультатаЗапроса.ПоГруппировкам);
		Пока Истина Цикл
			МассивПартнеров		= Новый Массив;
			ДанныеПартнеров		= Новый Массив;
			КоличествоЗаписей	= 0;
			
			Пока ВыборкаЛиц.Следующий() Цикл
				МассивПартнеров.Добавить(ВыборкаЛиц.Ссылка);
				
				ВыборкаРеквизитовЛиц = ВыборкаЛиц.Выбрать(ОбходРезультатаЗапроса.Прямой);
				Пока ВыборкаРеквизитовЛиц.Следующий() Цикл
					КоличествоЗаписей = КоличествоЗаписей + 1;
					
					КлючСтрокиСверки = Строка(Новый УникальныйИдентификатор);
					ЗначенияРеквизитовСверки = Новый Структура("ИсточникДанных, Идентификатор, ИНН");
					ЗаполнитьЗначенияСвойств(ЗначенияРеквизитовСверки, ВыборкаРеквизитовЛиц);

					Если Индекс = 1 Тогда
						ЗначенияРеквизитовСверки.Вставить("РегистрационныйНомер", ВыборкаРеквизитовЛиц.РегистрационныйНомер);
						ЗначенияРеквизитовСверки.Вставить("КраткоеНаименование", СтрЗаменить(ВыборкаРеквизитовЛиц.КраткоеНаименование, "'", "''"));
						ЗначенияРеквизитовСверки.Вставить("ПолноеНаименование", СтрЗаменить(ВыборкаРеквизитовЛиц.ПолноеНаименование, "'", "''"));
						ЗначенияРеквизитовСверки.Вставить("Язык", СтрЗаменить(ВыборкаРеквизитовЛиц.Язык, "'", "''"));
					
						ДанныеПартнеров.Добавить(
							"SELECT"
							+ " '" + ЗначенияРеквизитовСверки.ИсточникДанных + "'" + ?(КоличествоЗаписей = 1, " Data_Source", "") 
							+ ", '" + ЗначенияРеквизитовСверки.Идентификатор + "'" + ?(КоличествоЗаписей = 1, " Partner_ID", "") 
							+ ", '" + ЗначенияРеквизитовСверки.ИНН + "'" + ?(КоличествоЗаписей = 1, " INN", "")
							+ ", '" + ЗначенияРеквизитовСверки.РегистрационныйНомер + "'" + ?(КоличествоЗаписей = 1, " RegistrationNumber", "")
							+ ", '" + ЗначенияРеквизитовСверки.КраткоеНаименование + "'" + ?(КоличествоЗаписей = 1, " Name", "")
							+ ", '" + ЗначенияРеквизитовСверки.ПолноеНаименование + "'" + ?(КоличествоЗаписей = 1, " Name_Full", "")
							+ ", '" + ЗначенияРеквизитовСверки.Язык + "'" + ?(КоличествоЗаписей = 1, " [language]", "")
							+ ", '" + КлючСтрокиСверки + "'" + ?(КоличествоЗаписей = 1, " КлючСтрокиСверки", "")
						);
					
					Иначе
						ЗначенияРеквизитовСверки.Вставить("РегистрационныйНомер", СтрЗаменить(ВыборкаРеквизитовЛиц.РегистрационныйНомер, " ", ""));
						ЗначенияРеквизитовСверки.Вставить("Фамилия"				, СтрЗаменить(ВыборкаРеквизитовЛиц.Фамилия, "'", "''"));
						ЗначенияРеквизитовСверки.Вставить("Имя"					, СтрЗаменить(ВыборкаРеквизитовЛиц.Имя, "'", "''"));
						ЗначенияРеквизитовСверки.Вставить("Отчество"			, СтрЗаменить(ВыборкаРеквизитовЛиц.Отчество, "'", "''"));
						ЗначенияРеквизитовСверки.Вставить("ДатаРождения"		, Формат(ВыборкаРеквизитовЛиц.ДатаРождения, "ДФ='yyyyMMdd HH:mm:ss'"));
						ЗначенияРеквизитовСверки.Вставить("Язык"				, СтрЗаменить(ВыборкаРеквизитовЛиц.Язык, "'", "''"));
					
						ДанныеПартнеров.Добавить(
							"SELECT"
							+ " '" + ЗначенияРеквизитовСверки.ИсточникДанных + "'" + ?(КоличествоЗаписей = 1, " Data_Source", "") 
							+ ", '" + ЗначенияРеквизитовСверки.Идентификатор + "'" + ?(КоличествоЗаписей = 1, " Partner_ID", "") 
							+ ", '" + ЗначенияРеквизитовСверки.ИНН + "'" + ?(КоличествоЗаписей = 1, " INN", "")
							+ ", '" + ЗначенияРеквизитовСверки.РегистрационныйНомер + "'" + ?(КоличествоЗаписей = 1, " RegistrationNumber", "")
							+ ", '" + ЗначенияРеквизитовСверки.Фамилия + "'" + ?(КоличествоЗаписей = 1, " LastName", "")
							+ ", '" + ЗначенияРеквизитовСверки.Имя + "'" + ?(КоличествоЗаписей = 1, " FirstName", "")
							+ ", '" + ЗначенияРеквизитовСверки.Отчество + "'" + ?(КоличествоЗаписей = 1, " MiddleName", "")
							+ ", '" + ЗначенияРеквизитовСверки.ДатаРождения + "'" + ?(КоличествоЗаписей = 1, " BirthDate", "")
							+ ", '" + ЗначенияРеквизитовСверки.Язык + "'" + ?(КоличествоЗаписей = 1, " [language]", "")
							+ ", '" + КлючСтрокиСверки + "'" + ?(КоличествоЗаписей = 1, " КлючСтрокиСверки", "")
						);
					
					КонецЕсли;
					
					РеквизитыСверки.Вставить(КлючСтрокиСверки, ЗначенияРеквизитовСверки);
					
				КонецЦикла;	
				
				Если КоличествоЗаписей >= РазмерПакета Тогда
					Прервать;
				КонецЕсли;
			КонецЦикла;	
			
			Если КоличествоЗаписей = 0 Тогда
				Прервать;
			КонецЕсли;
			
			ПараметрПартнеры = СтрСоединить(ДанныеПартнеров, Символы.ПС + "UNION ALL" + Символы.ПС);	
			
			// Параметры
			ТекстЗапроса = СтрЗаменить(?(Индекс = 1, ШаблонЗапросаЮрЛиц, ШаблонЗапросаФизЛиц), "&ПорогТревоги", Формат(ПорогТревоги, "ЧГ="));
			
			ТекстЗапроса = СтрЗаменить(ТекстЗапроса, "&Партнеры"			, ПараметрПартнеры);
			ТекстЗапроса = СтрЗаменить(ТекстЗапроса, "&Период"				, Формат(Период, "ДФ='yyyyMMdd HH:mm:ss'"));
			ТекстЗапроса = СтрЗаменить(ТекстЗапроса, "&Организация"			, Строка(Организация.УникальныйИдентификатор()));
			ТекстЗапроса = СтрЗаменить(ТекстЗапроса, "&ИдентификаторСписка"	, Формат(ИдентификаторСписка, "ЧН=0; ЧГ="));
			
			// Получаем результат сверки со списками в Матрикс
			ТипыКолонок = Новый Структура;
			ТипыКолонок.Вставить("ИдентификаторЛица",	Новый ОписаниеТипов("Строка", , , , Новый КвалификаторыСтроки(9)));
			ТипыКолонок.Вставить("Пройдена",			Новый ОписаниеТипов("Булево"));
			ТипыКолонок.Вставить("Комментарий",			Новый ОписаниеТипов("Строка"));
			ТипыКолонок.Вставить("ИдентификаторСписка",	Новый ОписаниеТипов("Число"));		
			ТипыКолонок.Вставить("КлючСтрокиСверки",	Новый ОписаниеТипов("Строка"));
			
			Попытка
				РезультатСверкиПакета = ADODBC_ПолучитьТаблицуДанныхССервера(СтрокаСоединения, ТекстЗапроса, ТипыКолонок, ПараметрыСоединения);
			Исключение
			КонецПопытки;
			
			// Добавляем в ошибки проверки			
			Если РезультатСверкиПакета = Неопределено Тогда
				Если ОшибкиСверки = Неопределено Тогда
					ОшибкиСверки = Новый Структура;
				КонецЕсли;
				
				Если Не ОшибкиСверки.Свойство("НеПроверенныеЛица") Тогда
					ОшибкиСверки.Вставить("НеПроверенныеЛица", Новый ТаблицаЗначений);
					ОшибкиСверки.НеПроверенныеЛица.Колонки.Добавить("Ссылка", Новый ОписаниеТипов("СправочникСсылка.ЮрФизЛица"));
					ОшибкиСверки.НеПроверенныеЛица.Колонки.Добавить("Комментарий", Новый ОписаниеТипов("Строка"));
				КонецЕсли;
				
				Для Каждого НепроверенныйПартнер Из МассивПартнеров Цикл
					НеПроверенноеЛицо = ОшибкиСверки.НеПроверенныеЛица.Добавить();
					НеПроверенноеЛицо.Ссылка		= НепроверенныйПартнер.Ссылка;
					НеПроверенноеЛицо.Комментарий	= "Ошибка при выполнении запроса";
				КонецЦикла;
				
				Продолжить;
			КонецЕсли;

			Если РезультатСверки = Неопределено Тогда
				РезультатСверки = РезультатСверкиПакета;
			Иначе
				
				// Проверяем, что за время сверки список не изменился
				Если РезультатСверки.Количество() > 0
					И РезультатСверкиПакета.Количество() > 0
					И РезультатСверки[0].ИдентификаторСписка <> РезультатСверкиПакета[0].ИдентификаторСписка
				Тогда
					ОбщегоНазначенияКлиентСервер.СообщитьПользователю("Во время выполнения сверки произошло изменение списка лиц с замороженными счетами. Необходимо выполнить сверку повторно.");
					Возврат Неопределено;
				КонецЕсли;
				
				РаботаСКоллекциями.ТаблицаЗначений_Дополнить(РезультатСверкиПакета, РезультатСверки); 
			КонецЕсли;
		КонецЦикла;
	КонецЦикла;
	
	Если РезультатСверки = Неопределено Тогда
		Возврат Неопределено;
	КонецЕсли;
	
	Если ИдентификаторСписка = 0 Тогда
		//Объединим разные списки
		РезультатСверкиИдентификаторЛица = РезультатСверки.Скопировать(, "ИдентификаторЛица");
		РезультатСверкиИдентификаторЛица.Свернуть("ИдентификаторЛица");
		
		Для Каждого СтрокаИдентификаторЛица Из РезультатСверкиИдентификаторЛица Цикл
			ПараметрыПоиска = Новый Структура("ИдентификаторЛица", СтрокаИдентификаторЛица.ИдентификаторЛица);
			НайденныеСтроки = РезультатСверки.НайтиСтроки(ПараметрыПоиска);
			Если НайденныеСтроки.Количество() > 1 Тогда
				НоваяСтрока = РезультатСверки.Добавить();
				НоваяСтрока.ИдентификаторЛица = СтрокаИдентификаторЛица.ИдентификаторЛица;
				НоваяСтрока.Пройдена = Истина;
				
				МассивКоментариев = Новый Массив;
				
				Для Каждого СтрокаСверки Из НайденныеСтроки Цикл 
					НоваяСтрока.Пройдена = Мин(НоваяСтрока.Пройдена, СтрокаСверки.Пройдена);
					МассивКоментариев.Добавить(СтрокаСверки.Комментарий);
					РезультатСверки.Удалить(СтрокаСверки);
				КонецЦикла;
				
				НоваяСтрока.Комментарий = СтрСоединить(МассивКоментариев, Символы.ПС);
				
			КонецЕсли;
		КонецЦикла;
	КонецЕсли;
	
	Запрос = Новый Запрос(
		"ВЫБРАТЬ РАЗРЕШЕННЫЕ
	 	|	РезультатСверки.ИдентификаторЛица КАК ИдентификаторЛица,
		|	РезультатСверки.Пройдена КАК Пройдена,
		|	РезультатСверки.Комментарий КАК Комментарий,
		|	РезультатСверки.КлючСтрокиСверки
		|ПОМЕСТИТЬ _РезультатСверки
		|ИЗ
		|	&РезультатСверки КАК РезультатСверки
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|ВЫБРАТЬ РАЗРЕШЕННЫЕ
		|	ЮрФизЛица.Ссылка КАК ЮрФизЛицо,
		|	РезультатСверки.Пройдена КАК Пройдена,
		|	РезультатСверки.Комментарий КАК Комментарий,
		|	РезультатСверки.КлючСтрокиСверки КАК КлючСтрокиСверки,
		|	&Организация КАК Организация
		|ИЗ
		|	Справочник.ЮрФизЛица КАК ЮрФизЛица
		|		ВНУТРЕННЕЕ СОЕДИНЕНИЕ _РезультатСверки КАК РезультатСверки
		|		ПО (РезультатСверки.ИдентификаторЛица = ЮрФизЛица.Код)");
	
	Запрос.УстановитьПараметр("РезультатСверки", РезультатСверки);
	Запрос.УстановитьПараметр("Организация", Организация);
	
	// Получаем проверенные лица
	ПроверенныеЛица	= Запрос.Выполнить().Выгрузить();
	ПроверенныеЛица.Колонки.Добавить("РеквизитыСверки", Новый ОписаниеТипов("ХранилищеЗначения"));
	
	Для Каждого СтрокаДанных Из ПроверенныеЛица Цикл
		СтрокаДанных.РеквизитыСверки = Новый ХранилищеЗначения(РеквизитыСверки.Получить(СтрокаДанных.КлючСтрокиСверки));
	КонецЦикла;

	ПроверенныеЛица.Колонки.Удалить("КлючСтрокиСверки");
		
	Возврат ПроверенныеЛица;
КонецФункции

// Функция - Возвращает результаты сверки физ. лиц со списком недействительных паспортов
// 
// Параметры:
//	ПроверяемыеЛица	 - Массив - (Необязательный) Содержит массив проверяемых юр./физ. лиц
//						Если не указан, проводится сверка по полному списку юр./физ. лиц
//	ОшибкиСверки	 - Структура - (Необязательный, Выходной) В случае ошибок сверки возвращает структуру с описанием ошибок
//						Может содержать именованные таблицы:
//						- НеПроверенныеЛица: Ссылка (СправочникСсылка.ЮрФизЛица), Код (Строка), Категория (Строка)
//						- ОшибкиПоискаКодаВоВнешнейСистеме: Ссылка (СправочникСсылка.ЮрФизЛица)   
// 
// Возвращаемое значение:
//	ТаблицаЗначений, Неопределено - таблица успешно прошедших проверку лиц, Неопределено - в случае ошибки
//									Структура таблицы: ЮрФизЛицо (СправочникСсылка.ЮрФизЛица), Пройдена (Булево), Комментарий (Строка)
//
//
Функция ПолучитьРезультатСверкиСоСпискомНедействительныхПаспортов(Организация, Период, ПроверяемыеЛица = Неопределено, ОшибкиСверки = Неопределено) Экспорт	
	
	Перем ПроверенныеЛица; 	
	
	// Инициализация вспомогательных переменных
	ПорогТревоги		= 5;	
	СтрокаСоединения	= СтрокаСоединенияСExternals();
	ПараметрыСоединения = Новый Структура("CommandTimeout", 180);	
	РазмерПакета		= 300; // Количество отправляемых на проверку лиц
	
#Область ШаблонЗапросаФизЛиц
	ШаблонЗапросаФизЛиц	= "
		|SET NOCOUNT ON
		|;
		|
		|SELECT
		|	Partners.Partner_ID AS ИдентификаторЛица,
		|	CASE 
		|		WHEN Expired_Passports.Series IS NULL 
		|			THEN 1
		|		ELSE
		|			0
		|	END AS Пройдена,
		|	'Дата обновления списка недействительных паспортов: ' + ISNULL(CONVERT(varchar, (SELECT TOP 1 Upload_Time FROM Externals.dbo.Files Where Source_Id = 17 Order by Upload_Time DESC), 104), '-') AS Комментарий,
		|	Partners.КлючСтрокиСверки
		|FROM
		|	(&Партнеры) AS Partners
		|	LEFT JOIN Externals.dbo.Expired_Passports AS Expired_Passports
		|	ON Partners.Series = Expired_Passports.Series
		|		AND Partners.Number = Expired_Passports.Number";		
#КонецОбласти
	
	// Подготовим параметр для передачи таблицы на сервер
	Запрос = Новый Запрос;
	
	Справочники.ЮрФизЛица.ПоместитьКлиентовВМенеджерВременныхТаблиц(Запрос, Организация, Период);
	
#Область ТекстЗапроса
	Запрос.Текст = 
		"ВЫБРАТЬ РАЗРЕШЕННЫЕ РАЗЛИЧНЫЕ
		|	ЮрФизЛица.Ссылка КАК Ссылка,
		|	ЮрФизЛица.Код КАК Идентификатор,
		|	Организации.ПрефиксНумерации КАК ИсточникДанных
		|ПОМЕСТИТЬ ВТ_Клиенты
		|ИЗ
		|	(ВЫБРАТЬ
		|		_Клиенты.ЮрФизЛицо КАК ЮрФизЛицо,
		|		_Клиенты.Организация КАК Организация
		|	ИЗ
		|		_Клиенты КАК _Клиенты
		|	
		|	ОБЪЕДИНИТЬ
		|	
		|	ВЫБРАТЬ
		|		ЮрФизЛица.Ссылка,
		|		&Организация
		|	ИЗ
		|		Справочник.ЮрФизЛица КАК ЮрФизЛица
		|	ГДЕ
		|		ЮрФизЛица.Ссылка В(&ПроверяемыеЛица)) КАК ВложенныйЗапрос
		|		ВНУТРЕННЕЕ СОЕДИНЕНИЕ Справочник.ЮрФизЛица КАК ЮрФизЛица
		|		ПО ВложенныйЗапрос.ЮрФизЛицо = ЮрФизЛица.Ссылка
		|		ВНУТРЕННЕЕ СОЕДИНЕНИЕ Справочник.Организации КАК Организации
		|		ПО ВложенныйЗапрос.Организация = Организации.Ссылка
		|ГДЕ
		|	&ФильтрПроверяемыхЛиц
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|ВЫБРАТЬ РАЗРЕШЕННЫЕ
		|	ВТ_Клиенты.Ссылка КАК Ссылка,
		|	ВТ_Клиенты.ИсточникДанных КАК ИсточникДанных,
		|	ВТ_Клиенты.Идентификатор КАК Идентификатор,
		|	РеквизитыФизическихЛицАнкетныеСрезПоследних.СерияУдостоверенияЛичности КАК СерияУдостоверенияЛичности,
		|	РеквизитыФизическихЛицАнкетныеСрезПоследних.НомерУдостоверенияЛичности КАК НомерУдостоверенияЛичности,
		|	РеквизитыФизическихЛицАнкетныеСрезПоследних.Фамилия КАК Фамилия,
		|	РеквизитыФизическихЛицАнкетныеСрезПоследних.Имя КАК Имя,
		|	РеквизитыФизическихЛицАнкетныеСрезПоследних.Отчество КАК Отчество
		|ИЗ
		|	ВТ_Клиенты КАК ВТ_Клиенты
		|		ВНУТРЕННЕЕ СОЕДИНЕНИЕ РегистрСведений.РеквизитыФизическихЛицАнкетные.СрезПоследних(
		|				&Период,
		|				Организация = &Организация
		|					И Язык = ЗНАЧЕНИЕ(Справочник.Языки.Русский)
		|					И &ФильтрАнкетПроверяемыхЛиц) КАК РеквизитыФизическихЛицАнкетныеСрезПоследних
		|		ПО ВТ_Клиенты.Ссылка = РеквизитыФизическихЛицАнкетныеСрезПоследних.ЮрФизЛицо
		|ГДЕ
		|	РеквизитыФизическихЛицАнкетныеСрезПоследних.ВидУдостоверенияЛичности = ЗНАЧЕНИЕ(Справочник.ВидыДокументовФизическихЛиц.ПаспортРФ)
		|	И РеквизитыФизическихЛицАнкетныеСрезПоследних.СерияУдостоверенияЛичности <> """"
		|	И РеквизитыФизическихЛицАнкетныеСрезПоследних.НомерУдостоверенияЛичности <> """"
		|ИТОГИ ПО
		|	Ссылка";
#КонецОбласти
	
	Если ПроверяемыеЛица = Неопределено Тогда
		Запрос.Текст = СтрЗаменить(Запрос.Текст, "&ФильтрПроверяемыхЛиц", "ЮрФизЛица.ПометкаУдаления = ЛОЖЬ И ЮрФизЛица.ЭтоГруппа = ЛОЖЬ");
		Запрос.Текст = СтрЗаменить(Запрос.Текст, "&ФильтрАнкетПроверяемыхЛиц", "ИСТИНА");
	Иначе
		Запрос.Текст = СтрЗаменить(Запрос.Текст, "&ФильтрПроверяемыхЛиц", "ЮрФизЛица.Ссылка В (&ПроверяемыеЛица)");
		Запрос.Текст = СтрЗаменить(Запрос.Текст, "&ФильтрАнкетПроверяемыхЛиц", "ЮрФизЛицо В (&ПроверяемыеЛица)");
	КонецЕсли;	
	
	Запрос.УстановитьПараметр("ПроверяемыеЛица", ПроверяемыеЛица);
	Запрос.УстановитьПараметр("Период" 		, Период);
	Запрос.УстановитьПараметр("Организация"	, Организация);
	
	РезультатСверки = Неопределено;
	РеквизитыСверки	= Новый Соответствие;

	ВыборкаЛиц = Запрос.Выполнить().Выбрать(ОбходРезультатаЗапроса.ПоГруппировкам);
	Пока Истина Цикл
		МассивПартнеров		= Новый Массив;
		ДанныеПартнеров		= Новый Массив;
		КоличествоЗаписей	= 0;
		
		Пока ВыборкаЛиц.Следующий() Цикл
			МассивПартнеров.Добавить(ВыборкаЛиц.Ссылка);
			
			ВыборкаРеквизитовЛиц = ВыборкаЛиц.Выбрать(ОбходРезультатаЗапроса.Прямой);
			Пока ВыборкаРеквизитовЛиц.Следующий() Цикл
				КоличествоЗаписей = КоличествоЗаписей + 1;
				
				КлючСтрокиСверки = Строка(Новый УникальныйИдентификатор);
				
				ЗначенияРеквизитовСверки = Новый Структура("Фамилия, Имя, Отчество");
				ЗаполнитьЗначенияСвойств(ЗначенияРеквизитовСверки, ВыборкаРеквизитовЛиц);
				ЗначенияРеквизитовСверки.Вставить("СерияУдостоверенияЛичности", СтрЗаменить(ВыборкаРеквизитовЛиц.СерияУдостоверенияЛичности, " ", ""));
				ЗначенияРеквизитовСверки.Вставить("НомерУдостоверенияЛичности", СтрЗаменить(ВыборкаРеквизитовЛиц.НомерУдостоверенияЛичности, " ", ""));
				
				ДанныеПартнеров.Добавить(
					"SELECT"
					+ " '" + ВыборкаРеквизитовЛиц.Идентификатор + "'" + ?(КоличествоЗаписей = 1, " Partner_ID", "") 
					+ ", '" + СтрЗаменить(ЗначенияРеквизитовСверки.СерияУдостоверенияЛичности, "'", "''") + "'" + ?(КоличествоЗаписей = 1, " Series", "")
					+ ", '" + СтрЗаменить(ЗначенияРеквизитовСверки.НомерУдостоверенияЛичности, "'", "''") + "'" + ?(КоличествоЗаписей = 1, " Number", "")
					+ ", '" + КлючСтрокиСверки + "'" + ?(КоличествоЗаписей = 1, " КлючСтрокиСверки", "")
				);
				
				РеквизитыСверки.Вставить(КлючСтрокиСверки, ЗначенияРеквизитовСверки);
				
			КонецЦикла;	
			
			Если КоличествоЗаписей >= РазмерПакета Тогда
				Прервать;
			КонецЕсли;
		КонецЦикла;	
		
		Если КоличествоЗаписей = 0 Тогда
			Прервать;
		КонецЕсли;
		
		ПараметрПартнеры = СтрСоединить(ДанныеПартнеров, Символы.ПС + "UNION ALL" + Символы.ПС);	
		
		ТекстЗапроса = СтрЗаменить(ШаблонЗапросаФизЛиц, "&Партнеры"	, ПараметрПартнеры);
		
		// Получаем результат сверки со списками в Матрикс
		ТипыКолонок = Новый Структура;
		ТипыКолонок.Вставить("ИдентификаторЛица",	Новый ОписаниеТипов("Строка", , , , Новый КвалификаторыСтроки(9)));
		ТипыКолонок.Вставить("Пройдена",			Новый ОписаниеТипов("Булево"));
		ТипыКолонок.Вставить("Комментарий",			Новый ОписаниеТипов("Строка"));
		ТипыКолонок.Вставить("КлючСтрокиСверки",	Новый ОписаниеТипов("Строка"));
		
		Попытка
			РезультатСверкиПакета = ADODBC_ПолучитьТаблицуДанныхССервера(СтрокаСоединения, ТекстЗапроса, ТипыКолонок, ПараметрыСоединения);
		Исключение
		КонецПопытки;
		
		// Добавляем в ошибки проверки			
		Если РезультатСверкиПакета = Неопределено Тогда
			Если ОшибкиСверки = Неопределено Тогда
				ОшибкиСверки = Новый Структура;
			КонецЕсли;
			
			Если Не ОшибкиСверки.Свойство("НеПроверенныеЛица") Тогда
				ОшибкиСверки.Вставить("НеПроверенныеЛица", Новый ТаблицаЗначений);
				ОшибкиСверки.НеПроверенныеЛица.Колонки.Добавить("Ссылка", Новый ОписаниеТипов("СправочникСсылка.ЮрФизЛица"));
				ОшибкиСверки.НеПроверенныеЛица.Колонки.Добавить("Комментарий", Новый ОписаниеТипов("Строка"));
			КонецЕсли;
			
			Для Каждого НепроверенныйПартнер Из МассивПартнеров Цикл
				НеПроверенноеЛицо = ОшибкиСверки.НеПроверенныеЛица.Добавить();
				НеПроверенноеЛицо.Ссылка		= НепроверенныйПартнер.Ссылка;
				НеПроверенноеЛицо.Комментарий	= "Ошибка при выполнении запроса";
			КонецЦикла;
			
			Продолжить;
		КонецЕсли;

		Если РезультатСверки = Неопределено Тогда
			РезультатСверки = РезультатСверкиПакета;
		Иначе
			
			РаботаСКоллекциями.ТаблицаЗначений_Дополнить(РезультатСверкиПакета, РезультатСверки); 
		КонецЕсли;
	КонецЦикла;
	
	Если РезультатСверки = Неопределено Тогда
		Возврат Неопределено;
	КонецЕсли;
	
	Запрос = Новый Запрос(
		"ВЫБРАТЬ РАЗРЕШЕННЫЕ
	 	|	РезультатСверки.ИдентификаторЛица КАК ИдентификаторЛица,
		|	РезультатСверки.Пройдена КАК Пройдена,
		|	РезультатСверки.Комментарий КАК Комментарий,
		|	РезультатСверки.КлючСтрокиСверки
		|ПОМЕСТИТЬ _РезультатСверки
		|ИЗ
		|	&РезультатСверки КАК РезультатСверки
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|ВЫБРАТЬ РАЗРЕШЕННЫЕ
		|	ЮрФизЛица.Ссылка КАК ЮрФизЛицо,
		|	РезультатСверки.Пройдена КАК Пройдена,
		|	РезультатСверки.Комментарий КАК Комментарий,
		|	РезультатСверки.КлючСтрокиСверки КАК КлючСтрокиСверки,
		|	&Организация КАК Организация
		|ИЗ
		|	Справочник.ЮрФизЛица КАК ЮрФизЛица
		|		ВНУТРЕННЕЕ СОЕДИНЕНИЕ _РезультатСверки КАК РезультатСверки
		|		ПО (РезультатСверки.ИдентификаторЛица = ЮрФизЛица.Код)");
	
	Запрос.УстановитьПараметр("РезультатСверки", РезультатСверки);
	Запрос.УстановитьПараметр("Организация", Организация);
	
	// Получаем проверенные лица
	ПроверенныеЛица	= Запрос.Выполнить().Выгрузить();
	
	
	ПроверенныеЛица.Колонки.Добавить("РеквизитыСверки", Новый ОписаниеТипов("ХранилищеЗначения"));
	
	Для Каждого СтрокаДанных Из ПроверенныеЛица Цикл
		СтрокаДанных.РеквизитыСверки = Новый ХранилищеЗначения(РеквизитыСверки.Получить(СтрокаДанных.КлючСтрокиСверки));
	КонецЦикла;

	ПроверенныеЛица.Колонки.Удалить("КлючСтрокиСверки");
	
	Возврат ПроверенныеЛица;
	
КонецФункции

Функция ЗначенияРеквизитовСверки(РеквизитыСверки, Выборка)
	
	ЗначенияРеквизитов = Новый Структура;
	Для Каждого ИмяРеквизита Из РеквизитыСверки Цикл
		ЗначенияРеквизитов.Вставить(ИмяРеквизита, Выборка[ИмяРеквизита]);
	КонецЦикла;
	
	Возврат ЗначенияРеквизитов;
	
КонецФункции

// Функция - Возвращает результаты сверки юр./физ. лиц со списком лиц, в отношении которых вводятся специальные экономические меры
// 
// Параметры:
//	ПроверяемыеЛица	 - Массив - (Необязательный) Содержит массив проверяемых юр./физ. лиц
//						Если не указан, проводится сверка по полному списку юр./физ. лиц
//	ОшибкиСверки	 - Структура - (Необязательный, Выходной) В случае ошибок сверки возвращает структуру с описанием ошибок
//						Может содержать именованные таблицы:
//						- НеПроверенныеЛица: Ссылка (СправочникСсылка.ЮрФизЛица), Код (Строка), Категория (Строка)
//						- ОшибкиПоискаКодаВоВнешнейСистеме: Ссылка (СправочникСсылка.ЮрФизЛица)   
// 
// Возвращаемое значение:
//	ТаблицаЗначений, Неопределено - таблица успешно прошедших проверку лиц, Неопределено - в случае ошибки
//									Структура таблицы: ЮрФизЛицо (СправочникСсылка.ЮрФизЛица), Пройдена (Булево), Комментарий (Строка)
//
//
Функция ПолучитьРезультатСверкиССанкционнымСписком(Организация, Период, КодПеречня, ПредставлениеСписка, ПроверяемыеЛица = Неопределено, ОшибкиСверки = Неопределено) Экспорт	
	
	Перем ПроверенныеЛица; 	
	
	// Инициализация вспомогательных переменных
	СтрокаСоединения	= СтрокаСоединенияСExternals();
	ПараметрыСоединения = Новый Структура("CommandTimeout", 180);	
	РазмерПакета		= 300; // Количество отправляемых на проверку лиц
	
#Область ШаблонЗапросаЮрЛиц
	ШаблонЗапросаЮрЛиц	= "
		|SET NOCOUNT ON
		|;
		|
		|IF OBJECT_ID('tempdb..#Partners') IS NOT NULL
		|	Drop Table #Partners
		|;
		|IF OBJECT_ID('tempdb..#DecisionsSubjects') IS NOT NULL
		|	Drop Table #DecisionsSubjects
		|;		
		|IF OBJECT_ID('tempdb..#SuspectPartners') IS NOT NULL
		|	Drop Table #SuspectPartners
		|;
		|IF OBJECT_ID('tempdb..#LastDecisionsList') IS NOT NULL
		|	Drop Table #LastDecisionsList
		|;
		|
		|CREATE TABLE #Partners(
		|	Row_Index bigint IDENTITY(1,1),
		|	Data_Source nvarchar(15),
		|	Partner_ID nvarchar(9),
		|	Name_Clean nvarchar(4000),
		|	Name nvarchar(4000),
		|	Name_Full_Clean nvarchar(4000),
		|	Name_Full nvarchar(4000),
		|	RegistrationNumber nvarchar(100),
		|	[language] nvarchar(5),
		|	КлючСтрокиСверки nvarchar(36)
		|)
		|;
		|
		|INSERT INTO
		|	#Partners
		|SELECT
		|	Data_Source,
		|	Partner_ID,
		|	Name_Clean = dbo.RemoveExtraChar(Name),
		|	Name,
		|	Name_Full_Clean = dbo.RemoveExtraChar(Name_Full),
		|	Name_Full,
		|	RegistrationNumber,
		|	[language],
		|	КлючСтрокиСверки
		|FROM (
		|	&Партнеры
		|) Partners
		|; 
		|
		|SELECT TOP 1
		|	RefusalList.[File_Id],
		|	[Files].[File_Name], 
		|	RefusalList.[Period]
		|INTO
		|	#LastDecisionsList		
		|FROM
		|	[Externals].[dbo].[RefusalList] [RefusalList]
		|LEFT JOIN
		|	[Externals].[dbo].[Files] [Files] 
		|		ON [RefusalList].[File_Id] = [Files].[Id]
		|WHERE
		|	RefusalList.Source_Id = &Source_ID -- Указа Президента Российской Федерации от 22 октября 2018 г. N 592 О применении специальных экономических мер в связи с недружественными действиями Украины в отношении граждан и юридических лиц Российской Федерации
		|	AND RefusalList.[Period] <= CONVERT(datetime, '&Период')
		|ORDER BY
		|	RefusalList.[Period] DESC
		|;
		|
		|CREATE TABLE #DecisionsSubjects(
		|	ID bigint,
		|	Name nvarchar(4000),
		|	Name_Clean nvarchar(4000),
		|	RegistrationNumber nvarchar(50)
		|)
		|;		
		|
		|INSERT INTO
		|	#DecisionsSubjects
		|SELECT
		|	[ID] = RefusalList.ID,
		|	[Name] = RefusalList.Name,
		|	[Name_Clean] = RefusalList.Name_Clean,
		|	[RegistrationNumber] = RefusalList.RegistrationNumber
		|FROM [Externals].[dbo].[RefusalList] [RefusalList]
		|	INNER JOIN #LastDecisionsList [LastDecisionsList]
		|		ON LastDecisionsList.File_Id = RefusalList.File_Id
		|		AND RefusalList.Is_Firm = 1
		|;
		|		
		|SELECT
		|	[Row_Index] = P.Row_Index,
		|	[Data_Source] = P.Data_Source,
		|	[Partner_ID] = P.Partner_ID,
		|	[DecisionsSubject_ID] = DS.ID,
		|	[DecisionsSubject_Name] = DS.Name,
		|	[Intersections] = (CASE WHEN DS.RegistrationNumber = P.RegistrationNumber AND P.RegistrationNumber <> '' THEN 'Рег.номер, ' ELSE '' END)
		|					+ (CASE WHEN CharIndex(P.Name_Clean, DS.Name_Clean) > 0 THEN 'Наименование (' + P.[language] + '), ' ELSE '' END)
		|					+ (CASE WHEN CharIndex(P.Name_Full_Clean, DS.Name_Clean) > 0 THEN 'Полное наименование (' + P.[language] + '), ' ELSE '' END),
		|	[Sum_Rank] = ((CASE WHEN DS.RegistrationNumber = P.RegistrationNumber AND P.RegistrationNumber <> '' THEN 5 ELSE 0 END)
		|				+ (CASE WHEN DS.Name_Clean = P.Name_Clean THEN 5 ELSE 0 END)
		|				+ (CASE WHEN DS.Name_Clean = P.Name_Full_Clean THEN 5 ELSE 0 END)
		|				+ (CASE WHEN CharIndex(P.Name_Clean, DS.Name_Clean) > 0 THEN 3 ELSE 0 END)
		|				+ (CASE WHEN CharIndex(P.Name_Full_Clean, DS.Name_Clean) > 0 THEN 3 ELSE 0 END))
		|INTO
		|	#SuspectPartners
		|FROM #Partners as P
		|	INNER JOIN #DecisionsSubjects [DS]
		|	ON
		|			DS.RegistrationNumber = P.RegistrationNumber AND P.RegistrationNumber <> ''
		|			OR CharIndex(P.Name_Clean, DS.Name_Clean) > 0
		|			OR CharIndex(P.Name_Full_Clean, DS.Name_Clean) > 0
		|WHERE
		|	((CASE WHEN DS.RegistrationNumber = P.RegistrationNumber AND P.RegistrationNumber <> '' THEN 5 ELSE 0 END)
		|	+ (CASE WHEN DS.Name_Clean = P.Name_Clean THEN 5 ELSE 0 END)
		|	+ (CASE WHEN DS.Name_Clean = P.Name_Full_Clean THEN 5 ELSE 0 END)
		|	+ (CASE WHEN CharIndex(P.Name_Clean, DS.Name_Clean) > 0 THEN 3 ELSE 0 END)
		|	+ (CASE WHEN CharIndex(P.Name_Full_Clean, DS.Name_Clean) > 0 THEN 3 ELSE 0 END)) >= &ПорогТревоги
		|;
		|
		|SELECT DISTINCT
		|	[ИдентификаторЛица] = Partners.Partner_ID,
		|	[Пройдена] = 
		|		CASE
		|			WHEN SuspectPartners.Partner_ID IS NULL
		|				THEN 1
		|			ELSE 0
		|		END,
		|	[Комментарий] = 
		|		CASE
		|			WHEN SuspectPartners.Partner_ID IS NULL
		|				THEN '&ПредставлениеСписка' + CONVERT(nvarchar(10), LastDecisionsList.Period, 104)
		|			ELSE 'Найдены совпадения данных ' + SuspectPartners.Data_Source
		|				+ ' с данными санкционного списка от ' + CONVERT(nvarchar(10), LastDecisionsList.Period, 104)
		|				+ ' с [' + CAST(SuspectPartners.DecisionsSubject_ID  AS nvarchar(9)) + '] '
		|				+ SuspectPartners.DecisionsSubject_Name + ' по ' + SuspectPartners.Intersections
		|				+ 'суммарная оценка ' + CAST(SuspectPartners.Sum_Rank AS nvarchar(3))
		|		END,
		|	[ИдентификаторСписка] = LastDecisionsList.[File_Name],
		|	[Partners].КлючСтрокиСверки
		|FROM #Partners [Partners] 
		|	LEFT JOIN #SuspectPartners [SuspectPartners]
		|		INNER JOIN (
		|			SELECT
		|				SuspectPartnersForRow.Partner_ID,
		|				MAX(SuspectPartnersForRow.Row_Index) [Max_Row]	
		|			FROM
		|				#SuspectPartners [SuspectPartnersForRow]	
		|				INNER JOIN (
		|					SELECT
		|						SuspectPartnersForRank.Partner_ID,
		|						MAX(SuspectPartnersForRank.Sum_Rank) [Sum_Rank]
		|					FROM #SuspectPartners [SuspectPartnersForRank]
		|					GROUP BY
		|						SuspectPartnersForRank.Partner_ID
		|				) [MaxRankSuspicion]
		|				ON MaxRankSuspicion.Partner_ID = SuspectPartnersForRow.Partner_ID
		|					AND MaxRankSuspicion.Sum_Rank = SuspectPartnersForRow.Sum_Rank
		|			GROUP BY
		|				SuspectPartnersForRow.Partner_ID	
		|		) [SuspectPartnersCleared]
		|		ON SuspectPartnersCleared.Partner_ID = SuspectPartners.Partner_ID
		|			AND SuspectPartnersCleared.Max_Row = SuspectPartners.Row_Index
		|	ON SuspectPartners.Partner_ID = Partners.Partner_ID,
		|	#LastDecisionsList [LastDecisionsList]
		|;
		|
		|IF OBJECT_ID('tempdb..#Partners') IS NOT NULL
		|	Drop Table #Partners
		|;
		|IF OBJECT_ID('tempdb..#DecisionsSubjects') IS NOT NULL
		|	Drop Table #DecisionsSubjects
		|;		
		|IF OBJECT_ID('tempdb..#SuspectPartners') IS NOT NULL
		|	Drop Table #SuspectPartners
		|;
		|IF OBJECT_ID('tempdb..#LastDecisionsList') IS NOT NULL
		|	Drop Table #LastDecisionsList
		|;
		|";	
#КонецОбласти
	
#Область ШаблонЗапросаФизЛиц
	ШаблонЗапросаФизЛиц	= "
		|SET NOCOUNT ON
		|;
		|
		|IF OBJECT_ID('tempdb..#Partners') IS NOT NULL
		|	Drop Table #Partners
		|;
		|IF OBJECT_ID('tempdb..#DecisionsSubjects') IS NOT NULL
		|	Drop Table #DecisionsSubjects
		|;		
		|IF OBJECT_ID('tempdb..#SuspectPartners') IS NOT NULL
		|	Drop Table #SuspectPartners
		|;
		|IF OBJECT_ID('tempdb..#LastDecisionsList') IS NOT NULL
		|	Drop Table #LastDecisionsList
		|;
		|
		|CREATE TABLE #Partners(
		|	Row_Index bigint IDENTITY(1,1),
		|	Data_Source nvarchar(15),
		|	Partner_ID nvarchar(9),
		|	LastName_Clean nvarchar(100),
		|	LastName nvarchar(100),
		|	FirstName_Clean nvarchar(100),
		|	FirstName nvarchar(100),
		|	MiddleName_Clean nvarchar(100),
		|	MiddleName nvarchar(100),
		|	BirthDate date,
		|	[language] nvarchar(5),
		|	КлючСтрокиСверки nvarchar(36)
		|)
		|;
		|
		|INSERT INTO
		|	#Partners
		|SELECT
		|	Data_Source,
		|	Partner_ID,
		|	LastName_Clean = dbo.RemoveExtraChar(LastName),
		|	LastName,
		|	FirstName_Clean = dbo.RemoveExtraChar(FirstName),
		|	FirstName,
		|	MiddleName_Clean = dbo.RemoveExtraChar(MiddleName),
		|	MiddleName,
		|	BirthDate,
		|	[language],
		|	КлючСтрокиСверки
		|FROM (
		|	&Партнеры
		|) Partners
		|; 
		|
		|SELECT TOP 1
		|	RefusalList.[File_Id],
		|	[Files].[File_Name], 
		|	RefusalList.[Period]
		|INTO
		|	#LastDecisionsList		
		|FROM
		|	[Externals].[dbo].[RefusalList] [RefusalList]
		|LEFT JOIN
		|	[Externals].[dbo].[Files] [Files] 
		|		ON [RefusalList].[File_Id] = [Files].[Id]
		|WHERE
		|	RefusalList.Source_Id = &Source_ID -- Указа Президента Российской Федерации от 22 октября 2018 г. N 592 О применении специальных экономических мер в связи с недружественными действиями Украины в отношении граждан и юридических лиц Российской Федерации
		|	AND RefusalList.[Period] <= CONVERT(datetime, '&Период')
		|ORDER BY
		|	RefusalList.[Period] DESC
		|;
		|
		|CREATE TABLE #DecisionsSubjects(
		|	ID bigint,
		|	LastName nvarchar(100),
		|	LastName_Clean nvarchar(100),
		|	FirstName nvarchar(100),
		|	FirstName_Clean nvarchar(100),
		|	MiddleName nvarchar(100),
		|	MiddleName_Clean nvarchar(100),
		|	BirthDate date
		|)
		|;		
		|
		|INSERT INTO
		|	#DecisionsSubjects
		|SELECT
		|	[ID] = RefusalList.ID,
		|	[LastName] = RefusalList.LastName,
		|	[LastName_Clean] = RefusalList.LastName_Clean,
		|	[FirstName] = RefusalList.FirstName,
		|	[FirstName_Clean] = RefusalList.FirstName_Clean,
		|	[MiddleName] = RefusalList.MiddleName,
		|	[MiddleName_Clean] = RefusalList.MiddleName_Clean,
		|	[BirthDate] = RefusalList.BirthDate
		|FROM [Externals].[dbo].[RefusalList] [RefusalList]
		|	INNER JOIN #LastDecisionsList [LastDecisionsList]
		|		ON LastDecisionsList.File_Id = RefusalList.File_Id
		|		AND RefusalList.Is_Firm = 0
		|;
		|		
		|SELECT
		|	[Row_Index] = P.Row_Index,
		|	[Data_Source] = P.Data_Source,
		|	[Partner_ID] = P.Partner_ID,
		|	[DecisionsSubject_ID] = DS.ID,
		|	[DecisionsSubject_Name] =  DS.LastName + ' ' + DS.FirstName + ' ' + DS.MiddleName,
		|	[Intersections] = (CASE WHEN DS.LastName_Clean = P.LastName_Clean AND P.LastName_Clean <> '' THEN 'Фамилия (' + P.[language] + '), ' ELSE '' END)
		|					+ (CASE WHEN DS.FirstName_Clean = P.FirstName_Clean AND P.FirstName_Clean <> '' THEN 'Имя (' + P.[language] + '), ' ELSE '' END)
		|					+ (CASE WHEN DS.MiddleName_Clean = P.MiddleName_Clean THEN 'Отчество (' + P.[language] + '), ' ELSE '' END)
		|					+ (CASE WHEN DS.BirthDate = P.BirthDate THEN 'Дата рождения, ' ELSE '' END),
		|	[Sum_Rank] = (CASE WHEN DS.LastName_Clean = P.LastName_Clean AND P.LastName_Clean <> '' THEN 2 ELSE 0 END)
		|				+ (CASE WHEN DS.FirstName_Clean = P.FirstName_Clean AND P.FirstName_Clean <> '' THEN 2 ELSE 0 END)
		|				+ (CASE WHEN ISNULL(DS.MiddleName_Clean, P.MiddleName_Clean) = P.MiddleName_Clean THEN 1 ELSE 0 END)
		|				+ (CASE WHEN ISNULL(DS.BirthDate, P.BirthDate) = P.BirthDate THEN 2 ELSE 0 END)
		|INTO
		|	#SuspectPartners
		|FROM #Partners as P
		|	INNER JOIN #DecisionsSubjects [DS]
		|	ON 	DS.LastName_Clean = P.LastName_Clean AND P.LastName_Clean <> ''
		|		OR DS.FirstName_Clean = P.FirstName_Clean AND P.FirstName_Clean <> ''
		|		OR DS.MiddleName_Clean = P.MiddleName_Clean AND P.MiddleName_Clean <> ''
		|		OR DS.BirthDate = P.BirthDate
		|WHERE
		|	(CASE WHEN DS.LastName_Clean = P.LastName_Clean AND P.LastName_Clean <> '' THEN 2 ELSE 0 END)
		|	+ (CASE WHEN DS.FirstName_Clean = P.FirstName_Clean AND P.FirstName_Clean <> '' THEN 2 ELSE 0 END)
		|	+ (CASE WHEN ISNULL(DS.MiddleName_Clean, P.MiddleName_Clean) = P.MiddleName_Clean THEN 1 ELSE 0 END)
		|	+ (CASE WHEN ISNULL(DS.BirthDate, P.BirthDate) = P.BirthDate THEN 2 ELSE 0 END) >= &ПорогТревоги
		|;
		|
		|SELECT DISTINCT
		|	[ИдентификаторЛица] = Partners.Partner_ID,
		|	[Пройдена] = 
		|		CASE
		|			WHEN SuspectPartners.Partner_ID IS NULL
		|				THEN 1
		|			ELSE 0
		|		END,
		|	[Комментарий] = 
		|		CASE
		|			WHEN SuspectPartners.Partner_ID IS NULL
		|				THEN '&ПредставлениеСписка' + CONVERT(nvarchar(10), LastDecisionsList.Period, 104)
		|			ELSE 'Найдены совпадения данных ' + SuspectPartners.Data_Source
		|				+ ' с данными санкционного списка от ' + CONVERT(nvarchar(10), LastDecisionsList.Period, 104)
		|				+ ' с [' + CAST(SuspectPartners.DecisionsSubject_ID  AS nvarchar(9)) + '] '
		|				+ SuspectPartners.DecisionsSubject_Name + ' по ' + SuspectPartners.Intersections
		|				+ 'суммарная оценка ' + CAST(SuspectPartners.Sum_Rank AS nvarchar(3))
		|		END,
		|	[ИдентификаторСписка] = LastDecisionsList.[File_Name],
		|	[КлючСтрокиСверки] = [Partners].КлючСтрокиСверки 
		|FROM #Partners [Partners] 
		|	LEFT JOIN #SuspectPartners [SuspectPartners]
		|		INNER JOIN (
		|			SELECT
		|				SuspectPartnersForRow.Partner_ID,
		|				MAX(SuspectPartnersForRow.Row_Index) [Max_Row]	
		|			FROM
		|				#SuspectPartners [SuspectPartnersForRow]	
		|				INNER JOIN (
		|					SELECT
		|						SuspectPartnersForRank.Partner_ID,
		|						MAX(SuspectPartnersForRank.Sum_Rank) [Sum_Rank]
		|					FROM #SuspectPartners [SuspectPartnersForRank]
		|					GROUP BY
		|						SuspectPartnersForRank.Partner_ID
		|				) [MaxRankSuspicion]
		|				ON MaxRankSuspicion.Partner_ID = SuspectPartnersForRow.Partner_ID
		|					AND MaxRankSuspicion.Sum_Rank = SuspectPartnersForRow.Sum_Rank
		|			GROUP BY
		|				SuspectPartnersForRow.Partner_ID	
		|		) [SuspectPartnersCleared]
		|		ON SuspectPartnersCleared.Partner_ID = SuspectPartners.Partner_ID
		|			AND SuspectPartnersCleared.Max_Row = SuspectPartners.Row_Index
		|	ON SuspectPartners.Partner_ID = Partners.Partner_ID,
		|	#LastDecisionsList [LastDecisionsList]
		|;
		|
		|IF OBJECT_ID('tempdb..#Partners') IS NOT NULL
		|	Drop Table #Partners
		|;
		|IF OBJECT_ID('tempdb..#DecisionsSubjects') IS NOT NULL
		|	Drop Table #DecisionsSubjects
		|;		
		|IF OBJECT_ID('tempdb..#SuspectPartners') IS NOT NULL
		|	Drop Table #SuspectPartners
		|;
		|IF OBJECT_ID('tempdb..#LastDecisionsList') IS NOT NULL
		|	Drop Table #LastDecisionsList
		|;
		|";	
#КонецОбласти
	
	// Подготовим параметр для передачи таблицы на сервер
	Запрос = Новый Запрос;
		
	Справочники.ЮрФизЛица.ПоместитьКлиентовВМенеджерВременныхТаблиц(Запрос, Организация, Период);
	
#Область ТекстЗапроса	
	Запрос.Текст = 
		"ВЫБРАТЬ РАЗРЕШЕННЫЕ РАЗЛИЧНЫЕ
		|	ЮрФизЛица.Ссылка КАК Ссылка,
		|	ВЫБОР
		|		КОГДА ЮрФизЛица.ВидЮрФизЛица = ЗНАЧЕНИЕ(Перечисление.ВидыЮрФизЛиц.ЮридическоеЛицо)
		|			ТОГДА 1
		|		ИНАЧЕ 0
		|	КОНЕЦ КАК ЭтоОрганизация,
		|	ЮрФизЛица.Код КАК Идентификатор,
		|	Организации.ПрефиксНумерации КАК ИсточникДанных
		|ПОМЕСТИТЬ ВТ_Клиенты
		|ИЗ
		|	(ВЫБРАТЬ
		|		_Клиенты.ЮрФизЛицо КАК ЮрФизЛицо,
		|		_Клиенты.Организация КАК Организация
		|	ИЗ
		|		_Клиенты КАК _Клиенты
		|	ГДЕ
		|		(&НетОтбораПоПроверяемымЛицам
		|				ИЛИ _Клиенты.ЮрФизЛицо В (&ПроверяемыеЛица))
		|	
		|	ОБЪЕДИНИТЬ
		|	
		|	ВЫБРАТЬ
		|		ЮрФизЛица.Ссылка,
		|		&Организация
		|	ИЗ
		|		Справочник.ЮрФизЛица КАК ЮрФизЛица
		|	ГДЕ
		|		ЮрФизЛица.Ссылка В(&ПроверяемыеЛица)) КАК ВложенныйЗапрос
		|		ВНУТРЕННЕЕ СОЕДИНЕНИЕ Справочник.ЮрФизЛица КАК ЮрФизЛица
		|		ПО ВложенныйЗапрос.ЮрФизЛицо = ЮрФизЛица.Ссылка
		|			И (ЮрФизЛица.ПометкаУдаления = ЛОЖЬ)
		|			И (ЮрФизЛица.ЭтоГруппа = ЛОЖЬ)
		|		ВНУТРЕННЕЕ СОЕДИНЕНИЕ Справочник.Организации КАК Организации
		|		ПО ВложенныйЗапрос.Организация = Организации.Ссылка
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|ВЫБРАТЬ РАЗРЕШЕННЫЕ
		|	ВТ_Клиенты.ЭтоОрганизация КАК ЭтоОрганизация,
		|	ВТ_Клиенты.Ссылка КАК Ссылка,
		|	""ГК Регион"" КАК ИсточникДанных,
		|	ВТ_Клиенты.Идентификатор КАК Идентификатор,
		|	РеквизитыЮридическихЛиц.ПолноеНаименованиеПоУставу КАК ПолноеНаименование,
		|	РеквизитыЮридическихЛиц.КраткоеНаименованиеПоУставу КАК КраткоеНаименование,
		|	ВЫБОР
		|		КОГДА РеквизитыЮридическихЛиц.РезидентРФ
		|			ТОГДА ДокументыЮридическихЛицСрезПоследних.Номер
		|		ИНАЧЕ РеквизитыЮридическихЛиц.TIN
		|	КОНЕЦ КАК РегистрационныйНомер,
		|	РеквизитыЮридическихЛиц.ИНН КАК ИНН,
		|	ВЫБОР РеквизитыЮридическихЛиц.Язык
		|		КОГДА ЗНАЧЕНИЕ(Справочник.Языки.Русский)
		|			ТОГДА ""Рус.""
		|		КОГДА ЗНАЧЕНИЕ(Справочник.Языки.Английский)
		|			ТОГДА ""Англ.""
		|	КОНЕЦ КАК Язык
		|ИЗ
		|	ВТ_Клиенты КАК ВТ_Клиенты
		|		ВНУТРЕННЕЕ СОЕДИНЕНИЕ РегистрСведений.РеквизитыЮридическихЛиц.СрезПоследних(
		|				&Период,
		|				Подразделение = ЗНАЧЕНИЕ(Справочник.Подразделения.ГруппаКомпаний)
		|					И (&НетОтбораПоПроверяемымЛицам
		|						ИЛИ ЮрФизЛицо В (&ПроверяемыеЛица))) КАК РеквизитыЮридическихЛиц
		|		ПО ВТ_Клиенты.Ссылка = РеквизитыЮридическихЛиц.ЮрФизЛицо
		|		ЛЕВОЕ СОЕДИНЕНИЕ РегистрСведений.ДокументыЮридическихЛиц.СрезПоследних(
		|				&Период,
		|				Подразделение = ЗНАЧЕНИЕ(Справочник.Подразделения.ГруппаКомпаний)
		|					И Вид = ЗНАЧЕНИЕ(Перечисление.ВидыДокументовЮридическихЛиц.СвидетельствоОГосударственнойРегистрации)
		|					И (&НетОтбораПоПроверяемымЛицам
		|						ИЛИ ЮрФизЛицо В (&ПроверяемыеЛица))) КАК ДокументыЮридическихЛицСрезПоследних
		|		ПО ВТ_Клиенты.Ссылка = ДокументыЮридическихЛицСрезПоследних.ЮрФизЛицо
		|			И (ДокументыЮридическихЛицСрезПоследних.ДействуетПо = ДАТАВРЕМЯ(1, 1, 1)
		|				ИЛИ ДокументыЮридическихЛицСрезПоследних.ДействуетПо > &Период)
		|ГДЕ
		|	ВТ_Клиенты.ЭтоОрганизация = 1
		|
		|ОБЪЕДИНИТЬ ВСЕ
		|
		|ВЫБРАТЬ
		|	ВТ_Клиенты.ЭтоОрганизация,
		|	ВТ_Клиенты.Ссылка,
		|	ВТ_Клиенты.ИсточникДанных,
		|	ВТ_Клиенты.Идентификатор,
		|	РеквизитыЮридическихЛицАнкетные.ПолноеНаименованиеПоУставу,
		|	РеквизитыЮридическихЛицАнкетные.КраткоеНаименованиеПоУставу,
		|	ВЫБОР
		|		КОГДА РеквизитыЮридическихЛицАнкетные.РезидентРФ
		|			ТОГДА РеквизитыЮридическихЛицАнкетные.ОГРН
		|		ИНАЧЕ РеквизитыЮридическихЛицАнкетные.TIN
		|	КОНЕЦ,
		|	РеквизитыЮридическихЛицАнкетные.ИНН,
		|	ВЫБОР РеквизитыЮридическихЛицАнкетные.Язык
		|		КОГДА ЗНАЧЕНИЕ(Справочник.Языки.Русский)
		|			ТОГДА ""Рус.""
		|		КОГДА ЗНАЧЕНИЕ(Справочник.Языки.Английский)
		|			ТОГДА ""Англ.""
		|	КОНЕЦ
		|ИЗ
		|	ВТ_Клиенты КАК ВТ_Клиенты
		|		ВНУТРЕННЕЕ СОЕДИНЕНИЕ РегистрСведений.РеквизитыЮридическихЛицАнкетные.СрезПоследних(
		|				&Период,
		|				Организация = &Организация
		|					И (&НетОтбораПоПроверяемымЛицам
		|						ИЛИ ЮрФизЛицо В (&ПроверяемыеЛица))) КАК РеквизитыЮридическихЛицАнкетные
		|		ПО ВТ_Клиенты.Ссылка = РеквизитыЮридическихЛицАнкетные.ЮрФизЛицо
		|ГДЕ
		|	ВТ_Клиенты.ЭтоОрганизация = 1
		|ИТОГИ ПО
		|	Ссылка
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|ВЫБРАТЬ РАЗРЕШЕННЫЕ
		|	ВТ_Клиенты.ЭтоОрганизация КАК ЭтоОрганизация,
		|	ВТ_Клиенты.Ссылка КАК Ссылка,
		|	ВТ_Клиенты.ИсточникДанных КАК ИсточникДанных,
		|	ВТ_Клиенты.Идентификатор КАК Идентификатор,
		|	РеквизитыФизическихЛицАнкетныеСрезПоследних.Фамилия КАК Фамилия,
		|	РеквизитыФизическихЛицАнкетныеСрезПоследних.Имя КАК Имя,
		|	РеквизитыФизическихЛицАнкетныеСрезПоследних.Отчество КАК Отчество,
		|	РеквизитыФизическихЛицАнкетныеСрезПоследних.ДатаРождения КАК ДатаРождения,
		|	РеквизитыФизическихЛицАнкетныеСрезПоследних.Фамилия + "" "" + РеквизитыФизическихЛицАнкетныеСрезПоследних.Имя + "" "" + РеквизитыФизическихЛицАнкетныеСрезПоследних.Отчество КАК ФИО,
		|	ВЫБОР РеквизитыФизическихЛицАнкетныеСрезПоследних.Язык
		|		КОГДА ЗНАЧЕНИЕ(Справочник.Языки.Русский)
		|			ТОГДА ""Рус.""
		|		КОГДА ЗНАЧЕНИЕ(Справочник.Языки.Английский)
		|			ТОГДА ""Англ.""
		|	КОНЕЦ КАК Язык
		|ИЗ
		|	ВТ_Клиенты КАК ВТ_Клиенты
		|		ВНУТРЕННЕЕ СОЕДИНЕНИЕ РегистрСведений.РеквизитыФизическихЛицАнкетные.СрезПоследних(
		|				&Период,
		|				Организация = &Организация
		|					И (&НетОтбораПоПроверяемымЛицам
		|						ИЛИ ЮрФизЛицо В (&ПроверяемыеЛица))) КАК РеквизитыФизическихЛицАнкетныеСрезПоследних
		|		ПО ВТ_Клиенты.Ссылка = РеквизитыФизическихЛицАнкетныеСрезПоследних.ЮрФизЛицо
		|ГДЕ
		|	ВТ_Клиенты.ЭтоОрганизация = 0
		|ИТОГИ ПО
		|	Ссылка";
#КонецОбласти	
		
	Запрос.УстановитьПараметр("НетОтбораПоПроверяемымЛицам", (ПроверяемыеЛица = Неопределено));
	Запрос.УстановитьПараметр("ПроверяемыеЛица", ПроверяемыеЛица);
	Запрос.УстановитьПараметр("Период", Период);
	Запрос.УстановитьПараметр("Организация", Организация);
	
	Пакет = Запрос.ВыполнитьПакет();
	РезультатСверки = Неопределено;
	РеквизитыСверки	= Новый Соответствие;

	//1 - Юр лица
	//2 - Физ лица
	Для Индекс = 1 По 2 Цикл
		
		ВыборкаЛиц = Пакет[Индекс].Выбрать(ОбходРезультатаЗапроса.ПоГруппировкам);
		
		Пока Истина Цикл 
			
			МассивПартнеров		= Новый Массив;
			ДанныеПартнеров		= Новый Массив;
			КоличествоЗаписей	= 0;
			
			Пока ВыборкаЛиц.Следующий() Цикл 
				
				МассивПартнеров.Добавить(ВыборкаЛиц.Ссылка);
				
				ВыборкаРеквизитовЛиц = ВыборкаЛиц.Выбрать(ОбходРезультатаЗапроса.Прямой); 
				
				Пока ВыборкаРеквизитовЛиц.Следующий() Цикл
					
					КоличествоЗаписей = КоличествоЗаписей + 1;
					
					КлючСтрокиСверки = Строка(Новый УникальныйИдентификатор);
					
					ЗначенияРеквизитовСверки = Новый Структура("ИсточникДанных, Идентификатор");
					ЗаполнитьЗначенияСвойств(ЗначенияРеквизитовСверки, ВыборкаРеквизитовЛиц);
					
					Если Индекс = 1 Тогда
						
						ЗначенияРеквизитовСверки.Вставить("РегистрационныйНомер", ВыборкаРеквизитовЛиц.РегистрационныйНомер);
						ЗначенияРеквизитовСверки.Вставить("КраткоеНаименование",  СтрЗаменить(ВыборкаРеквизитовЛиц.КраткоеНаименование, "'", "''"));
						ЗначенияРеквизитовСверки.Вставить("ПолноеНаименование",   СтрЗаменить(ВыборкаРеквизитовЛиц.ПолноеНаименование, "'", "''"));
						ЗначенияРеквизитовСверки.Вставить("Язык", СтрЗаменить(ВыборкаРеквизитовЛиц.Язык, "'", "''"));
						
						ДанныеПартнеров.Добавить(
							"SELECT"
							+ " '" + ЗначенияРеквизитовСверки.ИсточникДанных + "'" + ?(КоличествоЗаписей = 1, " Data_Source", "") 
							+ ", '" + ЗначенияРеквизитовСверки.Идентификатор + "'" + ?(КоличествоЗаписей = 1, " Partner_ID", "") 
							+ ", '" + ЗначенияРеквизитовСверки.РегистрационныйНомер + "'" + ?(КоличествоЗаписей = 1, " RegistrationNumber", "")
							+ ", '" + ЗначенияРеквизитовСверки.КраткоеНаименование + "'" + ?(КоличествоЗаписей = 1, " Name", "")
							+ ", '" + ЗначенияРеквизитовСверки.ПолноеНаименование + "'" + ?(КоличествоЗаписей = 1, " Name_Full", "")
							+ ", '" + ЗначенияРеквизитовСверки.Язык + "'" + ?(КоличествоЗаписей = 1, " [language]", "")
							+ ", '" + КлючСтрокиСверки + "'" + ?(КоличествоЗаписей = 1, " КлючСтрокиСверки", "")
						);
					
					Иначе
						
						ЗначенияРеквизитовСверки.Вставить("Фамилия",      СтрЗаменить(ВыборкаРеквизитовЛиц.Фамилия, "'", "''"));
						ЗначенияРеквизитовСверки.Вставить("Имя",          СтрЗаменить(ВыборкаРеквизитовЛиц.Имя, "'", "''"));
						ЗначенияРеквизитовСверки.Вставить("Отчество",     СтрЗаменить(ВыборкаРеквизитовЛиц.Отчество, "'", "''"));
						ЗначенияРеквизитовСверки.Вставить("ДатаРождения", Формат(ВыборкаРеквизитовЛиц.ДатаРождения, "ДФ='yyyyMMdd HH:mm:ss'"));
						ЗначенияРеквизитовСверки.Вставить("Язык",         СтрЗаменить(ВыборкаРеквизитовЛиц.Язык, "'", "''"));
					
						ДанныеПартнеров.Добавить(
							"SELECT"
							+ " '" + ВыборкаРеквизитовЛиц.ИсточникДанных + "'" + ?(КоличествоЗаписей = 1, " Data_Source", "") 
							+ ", '" + ВыборкаРеквизитовЛиц.Идентификатор + "'" + ?(КоличествоЗаписей = 1, " Partner_ID", "") 
							+ ", '" + ЗначенияРеквизитовСверки.Фамилия + "'" + ?(КоличествоЗаписей = 1, " LastName", "")
							+ ", '" + ЗначенияРеквизитовСверки.Имя + "'" + ?(КоличествоЗаписей = 1, " FirstName", "")
							+ ", '" + ЗначенияРеквизитовСверки.Отчество + "'" + ?(КоличествоЗаписей = 1, " MiddleName", "")
							+ ", '" + ЗначенияРеквизитовСверки.ДатаРождения + "'" + ?(КоличествоЗаписей = 1, " BirthDate", "")
							+ ", '" + ЗначенияРеквизитовСверки.Язык + "'" + ?(КоличествоЗаписей = 1, " [language]", "")
							+ ", '" + КлючСтрокиСверки + "'" + ?(КоличествоЗаписей = 1, " КлючСтрокиСверки", "")
						);
					
					КонецЕсли;
					
					РеквизитыСверки.Вставить(КлючСтрокиСверки, ЗначенияРеквизитовСверки);
					
				КонецЦикла;	
				
				Если КоличествоЗаписей >= РазмерПакета Тогда
					Прервать;
				КонецЕсли;  
				
			КонецЦикла;	
			
			Если КоличествоЗаписей = 0 Тогда
				Прервать;
			КонецЕсли;
			
			ПараметрПартнеры = СтрСоединить(ДанныеПартнеров, Символы.ПС + "UNION ALL" + Символы.ПС);	
			
			ТекстЗапроса = ?(Индекс = 1, ШаблонЗапросаЮрЛиц, ШаблонЗапросаФизЛиц);
			
			// Параметры
			ТекстЗапроса = СтрЗаменить(ТекстЗапроса, "&ПорогТревоги",        ?(Индекс = 1, "5", "7"));//порог тревоги: юр.лица - 5, физ.лица - 7
			ТекстЗапроса = СтрЗаменить(ТекстЗапроса, "&Партнеры",            ПараметрПартнеры);
			ТекстЗапроса = СтрЗаменить(ТекстЗапроса, "&Период",              Формат(Период, "ДФ='yyyyMMdd HH:mm:ss'"));
			ТекстЗапроса = СтрЗаменить(ТекстЗапроса, "&Source_ID",           КодПеречня);
			ТекстЗапроса = СтрЗаменить(ТекстЗапроса, "&ПредставлениеСписка", ПредставлениеСписка);
			
			// Получаем результат сверки со списками в Матрикс
			ТипыКолонок = Новый Структура;
			ТипыКолонок.Вставить("ИдентификаторЛица",	Новый ОписаниеТипов("Строка", , , , Новый КвалификаторыСтроки(9)));
			ТипыКолонок.Вставить("Пройдена",			Новый ОписаниеТипов("Булево"));
			ТипыКолонок.Вставить("Комментарий",			Новый ОписаниеТипов("Строка"));
			ТипыКолонок.Вставить("ИдентификаторСписка",	Новый ОписаниеТипов("Число"));		
			ТипыКолонок.Вставить("КлючСтрокиСверки",	Новый ОписаниеТипов("Строка"));
			
			Попытка
				РезультатСверкиПакета = ADODBC_ПолучитьТаблицуДанныхССервера(СтрокаСоединения, ТекстЗапроса, ТипыКолонок, ПараметрыСоединения);
			Исключение
			КонецПопытки;
			
			// Добавляем в ошибки проверки			
			Если РезультатСверкиПакета = Неопределено Тогда 
				
				Если ОшибкиСверки = Неопределено Тогда
					ОшибкиСверки = Новый Структура;
				КонецЕсли;
				
				Если Не ОшибкиСверки.Свойство("НеПроверенныеЛица") Тогда
					ОшибкиСверки.Вставить("НеПроверенныеЛица", Новый ТаблицаЗначений);
					ОшибкиСверки.НеПроверенныеЛица.Колонки.Добавить("Ссылка", Новый ОписаниеТипов("СправочникСсылка.ЮрФизЛица"));
					ОшибкиСверки.НеПроверенныеЛица.Колонки.Добавить("Комментарий", Новый ОписаниеТипов("Строка"));
				КонецЕсли;
				
				Для Каждого НепроверенныйПартнер Из МассивПартнеров Цикл
					НеПроверенноеЛицо = ОшибкиСверки.НеПроверенныеЛица.Добавить();
					НеПроверенноеЛицо.Ссылка		= НепроверенныйПартнер.Ссылка;
					НеПроверенноеЛицо.Комментарий	= "Ошибка при выполнении запроса";
				КонецЦикла;
				
				Продолжить;
				
			КонецЕсли;

			Если РезультатСверки = Неопределено Тогда
				РезультатСверки = РезультатСверкиПакета;
			Иначе
				
				// Проверяем, что за время сверки список не изменился
				Если РезультатСверки.Количество() > 0
					И РезультатСверкиПакета.Количество() > 0
					И РезультатСверки[0].ИдентификаторСписка <> РезультатСверкиПакета[0].ИдентификаторСписка
				Тогда
					ОбщегоНазначенияКлиентСервер.СообщитьПользователю("Во время выполнения сверки произошло изменение списка лиц с замороженными счетами. Необходимо выполнить сверку повторно.");
					Возврат Неопределено;
				КонецЕсли;
				
				РаботаСКоллекциями.ТаблицаЗначений_Дополнить(РезультатСверкиПакета, РезультатСверки); 
				
			КонецЕсли;
			
		КонецЦикла; 
		
	КонецЦикла;
	
	Если РезультатСверки = Неопределено Тогда
		Возврат Неопределено;
	КонецЕсли;
	
	Запрос = Новый Запрос(
		"ВЫБРАТЬ РАЗРЕШЕННЫЕ
	 	|	РезультатСверки.ИдентификаторЛица КАК ИдентификаторЛица,
		|	РезультатСверки.Пройдена КАК Пройдена,
		|	РезультатСверки.Комментарий КАК Комментарий,
		|	РезультатСверки.КлючСтрокиСверки
		|ПОМЕСТИТЬ _РезультатСверки
		|ИЗ
		|	&РезультатСверки КАК РезультатСверки
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|ВЫБРАТЬ РАЗРЕШЕННЫЕ
		|	ЮрФизЛица.Ссылка КАК ЮрФизЛицо,
		|	РезультатСверки.Пройдена КАК Пройдена,
		|	РезультатСверки.Комментарий КАК Комментарий,
		|	РезультатСверки.КлючСтрокиСверки КАК КлючСтрокиСверки,
		|	&Организация КАК Организация
		|ИЗ
		|	Справочник.ЮрФизЛица КАК ЮрФизЛица
		|		ВНУТРЕННЕЕ СОЕДИНЕНИЕ _РезультатСверки КАК РезультатСверки
		|		ПО (РезультатСверки.ИдентификаторЛица = ЮрФизЛица.Код)");
	
	Запрос.УстановитьПараметр("РезультатСверки", РезультатСверки);
	Запрос.УстановитьПараметр("Организация", Организация);
	
	// Получаем проверенные лица
	ПроверенныеЛица	= Запрос.Выполнить().Выгрузить();
	
	ПроверенныеЛица.Колонки.Добавить("РеквизитыСверки", Новый ОписаниеТипов("ХранилищеЗначения"));
	
	Для Каждого СтрокаДанных Из ПроверенныеЛица Цикл
		СтрокаДанных.РеквизитыСверки = Новый ХранилищеЗначения(РеквизитыСверки.Получить(СтрокаДанных.КлючСтрокиСверки));
	КонецЦикла;

	ПроверенныеЛица.Колонки.Удалить("КлючСтрокиСверки");
	
	Возврат ПроверенныеЛица; 
	
КонецФункции 

Процедура ОбновитьРеквизитыОбъектаИзМатрикс(Объект, Подразделение = Неопределено, Язык = Неопределено, НеСообщатьОбИзмененииОбъектов = Ложь, НеСообщатьОбОтсутствииИзменений = Ложь) Экспорт
	
	ОбработкаИмпортНСИ = Обработки.ИмпортНормативноСправочнойИнформации.Создать();
	
	// для загрузки некоторых справочников нужна организация
	// при интерактивной загрузке организация выбирается в форме, куда попадает из
	// настроек пользователя по умолчанию, но может быть и перевыбрана
	Если Объект.Метаданные().Реквизиты.Найти("Организация") = Неопределено Тогда
		Организация = ОбщегоНазначения.ЗначениеПараметраСеанса("ТекущаяОрганизация");
	Иначе
		Организация = Объект.Организация;
	КонецЕсли;
	
	// заполним реквизиты
	ОбработкаИмпортНСИ.ГруппаПравил   = "Матрих";
	ОбработкаИмпортНСИ.ГруппаОбъектов = Справочники.ГруппыИмпортируемыхОбъектов.ПолучитьГруппуОбъекта(Объект);
	
	ОбработкаИмпортНСИ.Организация   = Организация;
	ОбработкаИмпортНСИ.Подразделение = ?(ЗначениеЗаполнено(Подразделение), Подразделение, Справочники.Подразделения.ГруппаКомпаний);
	ОбработкаИмпортНСИ.Язык          = ?(ЗначениеЗаполнено(Язык), Язык, Справочники.Языки.Русский);
	
	ОбработкаИмпортНСИ.НеСообщатьОбИзмененииОбъектов	= НеСообщатьОбИзмененииОбъектов;
	ОбработкаИмпортНСИ.НеСообщатьОбОтсутствииИзменений	= НеСообщатьОбОтсутствииИзменений;
	
	СтрокаИмпортируемыеОбъекты = ОбработкаИмпортНСИ.ИмпортируемыеОбъекты.Добавить();
	СтрокаИмпортируемыеОбъекты.Объект = Объект;
	
	ОбработкаИмпортНСИ.ИмпортироватьДанные();
	
	// Если объект - Пай, то обновим и ПИФ.
	Если ТипЗнч(Объект) = Тип("СправочникСсылка.Паи") Тогда
		
		ОбработкаИмпортНСИ.ИмпортируемыеОбъекты.Очистить();
		
		ПИФ = Объект.ПаевойИнвестиционныйФонд;
		
		ОбработкаИмпортНСИ.ГруппаОбъектов = Справочники.ГруппыИмпортируемыхОбъектов.ПолучитьГруппуОбъекта(ПИФ);
		
		СтрокаИмпортируемыеОбъекты			= ОбработкаИмпортНСИ.ИмпортируемыеОбъекты.Добавить();
		СтрокаИмпортируемыеОбъекты.Объект	= ПИФ;
		
		ОбработкаИмпортНСИ.ИмпортироватьДанные();
		
	КонецЕсли;

КонецПроцедуры // ОбновитьРеквизитыОбъектаИзМатрикс

Процедура ОбновитьОбъектыИзМатрикс(ГруппаОбъектов, ИмпортируемыеОбъекты, НеСообщатьОбИзмененииОбъектов = Ложь, НеСообщатьОбОтсутствииИзменений = Ложь) Экспорт
	
	ОбработкаИмпортНСИ = Обработки.ИмпортНормативноСправочнойИнформации.Создать();
	
	ОбработкаИмпортНСИ.Организация						= ОбщегоНазначения.ЗначениеПараметраСеанса("ТекущаяОрганизация");
	ОбработкаИмпортНСИ.Подразделение					= Справочники.Подразделения.ГруппаКомпаний;
	ОбработкаИмпортНСИ.Язык								= Справочники.Языки.Русский;
	ОбработкаИмпортНСИ.ГруппаПравил						= "Матрих";
	ОбработкаИмпортНСИ.ГруппаОбъектов					= ГруппаОбъектов;
	ОбработкаИмпортНСИ.НеСообщатьОбИзмененииОбъектов	= НеСообщатьОбИзмененииОбъектов;
	ОбработкаИмпортНСИ.НеСообщатьОбОтсутствииИзменений	= НеСообщатьОбОтсутствииИзменений;
	
	ОбработкаИмпортНСИ.ИмпортируемыеОбъекты.Загрузить(ИмпортируемыеОбъекты);
	
	ОбработкаИмпортНСИ.ИмпортироватьДанные();
	
КонецПроцедуры // ОбновитьПереданныеОбъектыЗагруженныеИзХКомпани

Процедура ОбновитьВыделенныеОбъектыИзМатрикс(Знач ВыделенныеСтроки, ИмяРеквизитаОбъекта = "Ссылка") Экспорт
	
	ВыделенныеОбъекты = Новый Массив;
		
	Для каждого ВыделеннаяСтрока Из ВыделенныеСтроки Цикл
		ВыделенныеОбъекты.Добавить(ВыделеннаяСтрока[ИмяРеквизитаОбъекта]);
	КонецЦикла;
	
	Запрос = Новый Запрос;
	Запрос.Текст =
		"ВЫБРАТЬ РАЗРЕШЕННЫЕ
		|	КодыВоВнешнихСистемахСрезПоследних.Объект,
		|	КодыВоВнешнихСистемахСрезПоследних.ГруппаОбъектов КАК ГруппаОбъектов,
		|	КодыВоВнешнихСистемахСрезПоследних.Код КАК КодВоВнешнейСистеме
		|ИЗ
		|	РегистрСведений.КодыВоВнешнихСистемах.СрезПоследних(
		|			,
		|			ВнешняяСистема = ЗНАЧЕНИЕ(Справочник.ВнешниеСистемы.Матрих)
		|				И Объект В (&Объект)) КАК КодыВоВнешнихСистемахСрезПоследних
		|ИТОГИ ПО
		|	ГруппаОбъектов";
		
	Запрос.УстановитьПараметр("Объект", ВыделенныеОбъекты);
	
	ВыборкаГруппыОбъектов = Запрос.Выполнить().Выбрать(ОбходРезультатаЗапроса.ПоГруппировкам);
	
	ИмпортируемыеОбъекты = Новый ТаблицаЗначений;
	ИмпортируемыеОбъекты.Колонки.Добавить("Объект");
	ИмпортируемыеОбъекты.Колонки.Добавить("КодВоВнешнейСистеме");
	
	Пока ВыборкаГруппыОбъектов.Следующий() Цикл
		Выборка = ВыборкаГруппыОбъектов.Выбрать();
		
		ИмпортируемыеОбъекты.Очистить();
		
		Пока Выборка.Следующий() Цикл
			ЗаполнитьЗначенияСвойств(ИмпортируемыеОбъекты.Добавить(), Выборка);
		КонецЦикла;
			
		РаботаСВнешнимиСистемами.ОбновитьОбъектыИзМатрикс(ВыборкаГруппыОбъектов.ГруппаОбъектов, ИмпортируемыеОбъекты);
	КонецЦикла;
	
КонецПроцедуры // ОбновитьВыделенныеОбъектыИзМатрикс

Функция ПолучитьКодМатрихФизическогоЛица(АнкетаКлиента) Экспорт
	
	СтрокаСоединения = СтрокаСоединенияСМатрих();
	
	Соединение = ADODBC_УстановитьСоединение(СтрокаСоединения);
	
	Если Соединение <> Неопределено Тогда
		
		Попытка
			
			Command = ADODBC_ПолучитьКомандуОбращенияКХранимойПроцедуре(Соединение, "usp_External_API_Persons_Manage");
			Command.NamedParameters = true;
			
			// ДОБАВЛЕНИЕ ПАРАМЕТРОВ // -------------------------------------------------------------------------------
			
			#Область ДобавлениеПараметров
			
			adVarWChar   = 202;  // Строковый тип
			adBoolean    = 11;  // Строковый тип
			
			ADODBC_ДобавитьВходнойПараметрКоманды(Command, "@Do_ControlList_Check",  adBoolean, 1, Ложь); 					//@Do_ControlList_Check = 0 - не проверять по перечню террористов и прочим
			
			ADODBC_ДобавитьВходнойПараметрКоманды(Command, "@Manage_Action_UID",     adVarWChar, 128, "CreatePerson"); //@Manage_Action_UID nvarchar(128) = 'CreateAll',                -- Тип действия (CheckOnly / CreatePerson / UpdatePerson / CreateAll / UpdateAll)
																												   		//-- Сведения о внешней системе
			ADODBC_ДобавитьВходнойПараметрКоманды(Command, "@External_System_UID",   adVarWChar, 128, "RAM.API");		//@External_System_UID nvarchar(128),                            -- UID системы (EVA.API / RAM.API)
			//ADODBC_ДобавитьВходнойПараметрКоманды(Command, "@External_System_Person_UID", adVarWChar, 128, );		//@External_System_Person_UID nvarchar(128) = null,              -- Идентификатор лица во внешней (по отношению к MatriX) системе
			
			//ADODBC_ДобавитьВходнойПараметрКоманды(Command, "@External_Strategy_UID", adVarWChar, 128, "", Ложь);   	//@External_Strategy_UID nvarchar(512),                          -- Стратегия (EVA.PIA.* / EVA.Brokerage.*, в перспективе RAM.*)
				
			//ADODBC_ДобавитьВходнойПараметрКоманды(Command, "@External_Agreement_Date", adVarWChar, 10, );			//@External_Agreement_Date date = null,                          -- Дата заключения договоров
			ADODBC_ДобавитьВходнойПараметрКоманды(Command, "@External_DateTime",     adVarWChar, 128
				, Формат(АнкетаКлиента.Дата, "ДФ='yyyy-MM-dd hh:mm:ss'"));   											//@External_DateTime datetime2 = null,                           -- Дата / время создания / изменения сведений о лице во внешней системе
																														//-- Сведения о лице
			//ADODBC_ДобавитьВходнойПараметрКоманды(Command, "@Person_ID", 20, 0, ); 									//@Person_ID bigint = null,                                      -- ID лица в MatriX
			
			ADODBC_ДобавитьВходнойПараметрКоманды(Command, "@Gender_Type_UID",       adVarWChar, 128, 
				?(АнкетаКлиента.Пол = Перечисления.ПолФизическогоЛица.Мужской, "Gender.Male",
				?(АнкетаКлиента.Пол = Перечисления.ПолФизическогоЛица.Женский, "Gender.Female", Неопределено)));		//@Gender_Type_UID nvarchar(128) = null,                         -- Пол (Gender.Male / Gender.Female)
					
			ADODBC_ДобавитьВходнойПараметрКоманды(Command, "@Person_Name_First_Ru",  adVarWChar, 512
				, АнкетаКлиента.Имя);             																		//@Person_Name_First_Ru nvarchar(512) = null,                    -- Имя на русском
			//ADODBC_ДобавитьВходнойПараметрКоманды(Command, "@Person_Name_First_En", adVarWChar, 512, );				//@Person_Name_First_En nvarchar(512) = null,                    -- Имя на английском
			ADODBC_ДобавитьВходнойПараметрКоманды(Command, "@Person_Name_Second_Ru", adVarWChar, 512
				, АнкетаКлиента.Отчество);        																		//@Person_Name_Second_Ru nvarchar(512) = null,                   -- Отчество на русском
			//ADODBC_ДобавитьВходнойПараметрКоманды(Command, "@Person_Name_Second_En", adVarWChar, 512, );				//@Person_Name_Second_En nvarchar(512) = null,                   -- Отчество на английском
			ADODBC_ДобавитьВходнойПараметрКоманды(Command, "@Person_Name_Last_Ru",   adVarWChar, 512
				, АнкетаКлиента.Фамилия);         																		//@Person_Name_Last_Ru nvarchar(512) = null,                     -- Фамилия на русском
			//ADODBC_ДобавитьВходнойПараметрКоманды(Command, "@Person_Name_Last_En", adVarWChar, 512, );				//@Person_Name_Last_En nvarchar(512) = null,                     -- Фамилия на английском
			ADODBC_ДобавитьВходнойПараметрКоманды(Command, "@Person_Birth_Date",     adVarWChar,  10
				, АнкетаКлиента.ДатаРождения);  																		//@Person_Birth_Date date = null,                                -- Дата рождения
			ADODBC_ДобавитьВходнойПараметрКоманды(Command, "@Person_Birth_Place_Ru", adVarWChar, 512
				, АнкетаКлиента.МестоРождения);   																		//@Person_Birth_Place_Ru nvarchar(512) = null,                   -- Место рождения на русском
			//ADODBC_ДобавитьВходнойПараметрКоманды(Command, "@Person_Birth_Place_En", adVarWChar, 512, );				//@Person_Birth_Place_En nvarchar(512) = null,                   -- Место рождения на английском
			ADODBC_ДобавитьВходнойПараметрКоманды(Command, "@Person_Nationality_Country_Code", adVarWChar, 3
				, АнкетаКлиента.Гражданство.КодАльфа3); 																//@Person_Nationality_Country_Code nvarchar(3) = null, -- Гражданство (ISO код страны)
			ADODBC_ДобавитьВходнойПараметрКоманды(Command, "@Person_Nationality2_Country_Code", adVarWChar, 3
				, АнкетаКлиента.ВтороеГражданство.КодАльфа3);															//@Person_Nationality2_Country_Code nvarchar(3) = null,          -- Гражданство 2 (ISO код страны)
			ADODBC_ДобавитьВходнойПараметрКоманды(Command, "@Person_Tax_Resident_Country_Code", adVarWChar, 3
				, ?(АнкетаКлиента.РезидентРФ, "RUS", Неопределено));													//@Person_Tax_Resident_Country_Code nvarchar(3) = null,          -- Налоговый резидент (ISO код страны)
																														//-- Документ, удостоверяющий личность
			ADODBC_ДобавитьВходнойПараметрКоманды(Command, "@Registration_Document_Type_UID",   adVarWChar, 128
				, ТипДокументаУдостоверяющегоЛичностьМатрих(АнкетаКлиента.ВидУдостоверенияЛичности)); 					//@Registration_Document_Type_UID nvarchar(128) = null,          -- Тип документа (Persons.Document.ID.Passport / Persons.Document.ID.Passport.Foreign.National)
				
			ADODBC_ДобавитьВходнойПараметрКоманды(Command, "@Registration_Document_Series",     adVarWChar, 128
				, АнкетаКлиента.СерияУдостоверенияЛичности);     														//@Registration_Document_Series nvarchar(128) = null,            -- Серия
			ADODBC_ДобавитьВходнойПараметрКоманды(Command, "@Registration_Document_Number",     adVarWChar, 128
				, АнкетаКлиента.НомерУдостоверенияЛичности);     														//@Registration_Document_Number nvarchar(128) = null,            -- Номер
				
			ADODBC_ДобавитьВходнойПараметрКоманды(Command, "@Registration_Document_Issue_Date", adVarWChar, 10
				, Формат(АнкетаКлиента.ДатаВыдачиУдостоверенияЛичности, "ДФ='yyyy-MM-dd'"));							//@Registration_Document_Issue_Date date = null,                 -- Дата выдачи
			ADODBC_ДобавитьВходнойПараметрКоманды(Command, "@Registration_Document_Expiration_Date", adVarWChar, 10
				, Формат(АнкетаКлиента.ДатаОкончанияДействияУдостоверенияЛичности, "ДФ='yyyy-MM-dd'"));					//@Registration_Document_Expiration_Date date = null,            -- Дата окончания срока действия (если есть)
				
			ADODBC_ДобавитьВходнойПараметрКоманды(Command, "@Registration_Document_Issuer_Code",    adVarWChar, 32
				, АнкетаКлиента.КодОрганаВыдавшегоУдостоверениеЛичности);												//@Registration_Document_Issuer_Code nvarchar(32) = null,        -- Кем выдан (Код подразделения)
			ADODBC_ДобавитьВходнойПараметрКоманды(Command, "@Registration_Document_Issuer_Name_Ru", adVarWChar, 512
				, АнкетаКлиента.ОрганВыдавшийУдостоверениеЛичности);     												//@Registration_Document_Issuer_Name_Ru nvarchar(512) = null,    -- Кем выдан (имя на русском)
			ADODBC_ДобавитьВходнойПараметрКоманды(Command, "@Registration_Document_Issuer_Name_En", adVarWChar, 512
				, ); 																									//@Registration_Document_Issuer_Name_En nvarchar(512) = null,    -- Кем выдан (имя на английском)
																														//-- Вспомогательные документы
			ADODBC_ДобавитьВходнойПараметрКоманды(Command, "@Person_Tax_Number",     adVarWChar, 32
				, АнкетаКлиента.ИНН);   																				//@Person_Tax_Number nvarchar(32) = null,      -- ИНН
			ADODBC_ДобавитьВходнойПараметрКоманды(Command, "@Person_Pension_Number", adVarWChar, 32
				, АнкетаКлиента.СНИЛС); 																				//@Person_Pension_Number nvarchar(32) = null,  -- СНИЛС
																														//-- Адрес регистрации
																														
																														
			ADODBC_ДобавитьВходнойПараметрКоманды(Command, "@Address_Legal_Text_Ru",      adVarWChar, 400, АнкетаКлиента.АдресРегистрации);		//@Address_Legal_Text_Ru nvarchar(400) = null,                   -- Строка с адресом на русском
			
			//ADODBC_ДобавитьВходнойПараметрКоманды(Command, "@Address_Legal_Text_En",      adVarWChar, 400, );		//@Address_Legal_Text_En nvarchar(400) = null,                   -- Строка с адресом на английском

			СтруктураАдресаРегистрации = РаботаСКонтактнойИнформациейКлиентСервер.АдресФИАСВСтруктуру(АнкетаКлиента.АдресРегистрацииФИАС);
			
			Если ЗначениеЗаполнено(СтруктураАдресаРегистрации.Страна) Тогда
				КодСтраныАдресаРегистрации = Справочники.СтраныМира.НайтиПоНаименованию(СтруктураАдресаРегистрации.Страна).КодАльфа3;
			ИначеЕсли ЗначениеЗаполнено(АнкетаКлиента.АдресРегистрацииФИАС) Тогда
				КодСтраныАдресаРегистрации = Справочники.СтраныМира.Россия.КодАльфа3;
			КонецЕсли;

			ADODBC_ДобавитьВходнойПараметрКоманды(Command, "@Address_Legal_Country_Code", adVarWChar,   3, КодСтраныАдресаРегистрации);	    //@Address_Legal_Country_Code nvarchar(3) = null,                -- Страна (ISO код)
			ADODBC_ДобавитьВходнойПараметрКоманды(Command, "@Address_Legal_Post_Code",    adVarWChar,  32, СтруктураАдресаРегистрации.Индекс);		//@Address_Legal_Post_Code nvarchar(32) = null,                  -- Индекс
			ADODBC_ДобавитьВходнойПараметрКоманды(Command, "@Address_Legal_Region_Ru",    adVarWChar, 512, СтруктураАдресаРегистрации.Регион);		//@Address_Legal_Region_Ru nvarchar(512) = null,                 -- Регион (республика, край, область) на русском
			
			//ADODBC_ДобавитьВходнойПараметрКоманды(Command, "@Address_Legal_Region_En",    adVarWChar, 512, );		//@Address_Legal_Region_En nvarchar(512) = null,                 -- Регион (республика, край, область) на английском
			
			ADODBC_ДобавитьВходнойПараметрКоманды(Command, "@Address_Legal_Area_Ru",      adVarWChar, 512, СтруктураАдресаРегистрации.Район);		//@Address_Legal_Area_Ru nvarchar(512) = null,                   -- Областной регион (район) на русском
			
			//ADODBC_ДобавитьВходнойПараметрКоманды(Command, "@Address_Legal_Area_En",      adVarWChar, 512, );		//@Address_Legal_Area_En nvarchar(512) = null,                   -- Областной регион (район) на английском
			
			ADODBC_ДобавитьВходнойПараметрКоманды(Command, "@Address_Legal_City_Ru",      adVarWChar, 512, СтруктураАдресаРегистрации.Город);		//@Address_Legal_City_Ru nvarchar(512) = null,                   -- Город (Населенный пункт) на русском
			
			//ADODBC_ДобавитьВходнойПараметрКоманды(Command, "@Address_Legal_City_En",      adVarWChar, 512, );		//@Address_Legal_City_En nvarchar(512) = null,                   -- Город (Населенный пункт) на английском
			
			ADODBC_ДобавитьВходнойПараметрКоманды(Command, "@Address_Legal_Street_Ru",    adVarWChar, 512, СтруктураАдресаРегистрации.Улица);		//@Address_Legal_Street_Ru nvarchar(512) = null,                 -- Улица на русском
			
			//ADODBC_ДобавитьВходнойПараметрКоманды(Command, "@Address_Legal_Street_En",    adVarWChar, 512, );		//@Address_Legal_Street_En nvarchar(512) = null,                 -- Улица на английском
			
			ADODBC_ДобавитьВходнойПараметрКоманды(Command, "@Address_Legal_House",    	 adVarWChar,  32, СтруктураАдресаРегистрации.Дом);		//@Address_Legal_House nvarchar(32) = null,                      -- Дом
			
			Если СтруктураАдресаРегистрации.ТипДома = "1060" Тогда
				ADODBC_ДобавитьВходнойПараметрКоманды(Command, "@Address_Legal_Building",     adVarWChar,  32, СтруктураАдресаРегистрации.Строение);		//@Address_Legal_Building nvarchar(32) = null,                   -- Строение
			Иначе
				ADODBC_ДобавитьВходнойПараметрКоманды(Command, "@Address_Legal_Block",        adVarWChar,  32, СтруктураАдресаРегистрации.Строение);		//@Address_Legal_Block nvarchar(32) = null,                      -- Корпус	
			КонецЕсли;
			
			ADODBC_ДобавитьВходнойПараметрКоманды(Command, "@Address_Legal_Apartment",    adVarWChar,  32, СтруктураАдресаРегистрации.Помещение);		//@Address_Legal_Apartment nvarchar(32) = null,                  -- Квартира
			
			
			ADODBC_ДобавитьВходнойПараметрКоманды(Command, "@Address_Post_Text_Ru",       adVarWChar, 400, ?(ПустаяСтрока(АнкетаКлиента.АдресМестаЖительства), АнкетаКлиента.ПочтовыйАдрес, АнкетаКлиента.АдресМестаЖительства));									//@Address_Post_Text_Ru nvarchar(400) = null,                    -- Строка с адресом на русском
			
			ПочтовыйАдресФИАС = ?(ПустаяСтрока(АнкетаКлиента.АдресМестаЖительстваФИАС), АнкетаКлиента.ПочтовыйАдресФИАС, АнкетаКлиента.АдресМестаЖительстваФИАС);
			СтруктураПочтовогоАдреса = РаботаСКонтактнойИнформациейКлиентСервер.АдресФИАСВСтруктуру(ПочтовыйАдресФИАС);
			
			Если ЗначениеЗаполнено(СтруктураПочтовогоАдреса.Страна) Тогда
				КодСтраныПочтовогоАдреса = Справочники.СтраныМира.НайтиПоНаименованию(СтруктураПочтовогоАдреса.Страна).КодАльфа3;
			ИначеЕсли ЗначениеЗаполнено(ПочтовыйАдресФИАС) Тогда 
				КодСтраныПочтовогоАдреса = Справочники.СтраныМира.Россия.КодАльфа3;
			КонецЕсли;
																														
			ADODBC_ДобавитьВходнойПараметрКоманды(Command, "@Address_Post_Country_Code",  adVarWChar,   3, КодСтраныПочтовогоАдреса);		//@Address_Post_Country_Code nvarchar(3) = null,                 -- Страна (ISO код)
			ADODBC_ДобавитьВходнойПараметрКоманды(Command, "@Address_Post_Post_Code",     adVarWChar,  32, СтруктураПочтовогоАдреса.Индекс);		//@Address_Post_Post_Code nvarchar(32) = null,                   -- Индекс
			ADODBC_ДобавитьВходнойПараметрКоманды(Command, "@Address_Post_Region_Ru",     adVarWChar, 512, СтруктураПочтовогоАдреса.Регион);		//@Address_Post_Region_Ru nvarchar(512) = null,                  -- Регион (республика, край, область) на русском
			//ADODBC_ДобавитьВходнойПараметрКоманды(Command, "@Address_Post_Region_En",     adVarWChar, 512, );		//@Address_Post_Region_En nvarchar(512) = null,                  -- Регион (республика, край, область) на английском
			ADODBC_ДобавитьВходнойПараметрКоманды(Command, "@Address_Post_Area_Ru",       adVarWChar, 512, СтруктураПочтовогоАдреса.Район);		//@Address_Post_Area_Ru nvarchar(512) = null,                    -- Областной регион (район) на русском
			//ADODBC_ДобавитьВходнойПараметрКоманды(Command, "@Address_Post_Area_En",       adVarWChar, 512, );		//@Address_Post_Area_En nvarchar(512) = null,                    -- Областной регион (район) на английском
			ADODBC_ДобавитьВходнойПараметрКоманды(Command, "@Address_Post_City_Ru",       adVarWChar, 512, СтруктураПочтовогоАдреса.Город);		//@Address_Post_City_Ru nvarchar(512) = null,                    -- Город (Населенный пункт) на русском
			//ADODBC_ДобавитьВходнойПараметрКоманды(Command, "@Address_Post_City_En",       adVarWChar, 512, );		//@Address_Post_City_En nvarchar(512) = null,                    -- Город (Населенный пункт) на английском
			ADODBC_ДобавитьВходнойПараметрКоманды(Command, "@Address_Post_Street_Ru",     adVarWChar, 512, СтруктураПочтовогоАдреса.Улица);		//@Address_Post_Street_Ru nvarchar(512) = null,                  -- Улица на русском
			//ADODBC_ДобавитьВходнойПараметрКоманды(Command, "@Address_Post_Street_En",     adVarWChar, 512, );		//@Address_Post_Street_En nvarchar(512) = null,                  -- Улица на английском
			ADODBC_ДобавитьВходнойПараметрКоманды(Command, "@Address_Post_House",    	 adVarWChar,  32, СтруктураПочтовогоАдреса.Дом);		//@Address_Post_House nvarchar(32) = null,                       -- Дом
			
			Если СтруктураПочтовогоАдреса.ТипДома = "1060" Тогда
				ADODBC_ДобавитьВходнойПараметрКоманды(Command, "@Address_Post_Building",      adVarWChar,  32, СтруктураПочтовогоАдреса.Строение);		//@Address_Post_Building nvarchar(32) = null,                    -- Строение
			Иначе
				ADODBC_ДобавитьВходнойПараметрКоманды(Command, "@Address_Post_Block",         adVarWChar,  32, СтруктураПочтовогоАдреса.Строение);		//@Address_Post_Block nvarchar(32) = null,                       -- Корпус
			КонецЕсли;
				
			ADODBC_ДобавитьВходнойПараметрКоманды(Command, "@Address_Post_Apartment",     adVarWChar,  32, СтруктураПочтовогоАдреса.Помещение);		//@Address_Post_Apartment nvarchar(32) = null,                   -- Квартира
			
			
			//ADODBC_ДобавитьВходнойПараметрКоманды(Command, "@Address_Post_Text_En",       adVarWChar, 400, );		//@Address_Post_Text_En nvarchar(400) = null,                    -- Строка с адресом на английском
																														//-- Реквизиты лица
			Если АнкетаКлиента.БанковскиеРеквизиты.Количество() Тогда
																															
				СтрокаРеквизитов = АнкетаКлиента.БанковскиеРеквизиты[0];
				
				ADODBC_ДобавитьВходнойПараметрКоманды(Command, "@Bank_Reqiusites_BIC", adVarWChar, 32
					, СтрокаРеквизитов.БИК);																			//@Bank_Reqiusites_BIC nvarchar(32) = null,                      -- БИК
				ADODBC_ДобавитьВходнойПараметрКоманды(Command, "@Bank_Reqiusites_Name", adVarWChar, 32
					, СтрокаРеквизитов.НаименованиеБанка);																//@Bank_Reqiusites_Name nvarchar(32) = null,                     -- Имя банка
				ADODBC_ДобавитьВходнойПараметрКоманды(Command, "@Bank_Reqiusites_Correspondent_Number", adVarWChar, 32
					, СтрокаРеквизитов.КоррСчет);																		//@Bank_Reqiusites_Correspondent_Number nvarchar(32) = null,     -- Номер корреспондентского счета
				ADODBC_ДобавитьВходнойПараметрКоманды(Command, "@Bank_Reqiusites_Account_Number", adVarWChar, 32
					, СтрокаРеквизитов.НомерСчета);																		//@Bank_Reqiusites_Account_Number nvarchar(32) = null,           -- Номер расчетного счета
				ADODBC_ДобавитьВходнойПараметрКоманды(Command, "@Bank_Reqiusites_Purpose", adVarWChar, 32
					, СтрокаРеквизитов.НазначениеПлатежа);																//@Bank_Reqiusites_Purpose nvarchar(32) = null,                  -- Назначение платежа
																														
			КонецЕсли;																											
			
																														//-- Сведения о контактах лица
			Если АнкетаКлиента.ЦельДоверительноеУправление Тогда
																															
				ADODBC_ДобавитьВходнойПараметрКоманды(Command, "@Person_Phone", adVarWChar, 32
					, АнкетаКлиента.Телефоны);																			//@Person_Phone nvarchar(20) = null,                             -- Номер телефона
					
			КонецЕсли;	
			ADODBC_ДобавитьВходнойПараметрКоманды(Command, "@Person_Email", adVarWChar, 32
				, АнкетаКлиента.EMail);																					//@Person_Email nvarchar(512) = null,                            -- Адрес электронной почты
																														//-- Прочие данные
			//ADODBC_ДобавитьВходнойПараметрКоманды(Command, "@Person_Additional_Info",  ???????, ???, );				//@Person_Additional_Info xml = null                             -- Прочие данные клиента
			
			#КонецОбласти																											
			
			// ВЫПОЛНЕНИЕ //------------------------------------------------------------------------------------------- 																											
					
			Результат = Command.Execute();
			Если Результат.State = 1 Тогда
				КодМатрих = Формат(Результат.Fields("person_id").Value, "ЧН=0; ЧГ=0");
			Иначе
				ТекстОшибки = Результат.State;
				ОбщегоНазначенияКлиентСервер.СообщитьПользователю("Ошибка получения данных из Матрих: State = " + ТекстОшибки);
				ЗаписьЖурналаРегистрации("Ошибка получения данных из Матрих", УровеньЖурналаРегистрации.Ошибка, , АнкетаКлиента.Ссылка, ТекстОшибки);
			КонецЕсли;
		Исключение
			Сообщить(ОписаниеОшибки());
			Информация = ИнформацияОбОшибке();
			ОбщегоНазначенияКлиентСервер.СообщитьПользователю("Ошибка получения данных из Матрих: " + Информация.Описание);
			ЗаписьЖурналаРегистрации("Ошибка получения данных из Матрих", УровеньЖурналаРегистрации.Ошибка, , АнкетаКлиента.Ссылка, Информация.Описание);
		КонецПопытки;

		ADODBC_ЗакрытьСоединение(Соединение);
		
	КонецЕсли;
	
	Возврат КодМатрих;
	
КонецФункции

Функция ТипДокументаУдостоверяющегоЛичностьМатрих(ВидДокументУдостоверяющегоЛичность)
	
	Если Не ЗначениеЗаполнено(ВидДокументУдостоверяющегоЛичность) Тогда
		Возврат Неопределено;
	КонецЕсли;
	
	Менеджер = Справочники.ВидыДокументовФизическихЛиц;
	
	Если ВидДокументУдостоверяющегоЛичность = Менеджер.ПаспортРФ Тогда
		Возврат "Persons.Document.ID.Passport";	
	ИначеЕсли ВидДокументУдостоверяющегоЛичность = Менеджер.ПаспортИностранногоГражданина Тогда
		Возврат "Persons.Document.ID.Passport.Foreign.National";
	ИначеЕсли ВидДокументУдостоверяющегоЛичность = Менеджер.СвидетельствоОРождении Тогда
		Возврат "Persons.Document.ID.Birth";
	ИначеЕсли ВидДокументУдостоверяющегоЛичность = Менеджер.ПаспортСССР Тогда
		Возврат "Persons.Document.ID.Passport.USSR";
	ИначеЕсли ВидДокументУдостоверяющегоЛичность = Менеджер.ВидНаЖительство Тогда
		Возврат "Persons.Document.ID.Permission";
	Иначе
		ВызватьИсключение "Для вида удостоверения личности " + ВидДокументУдостоверяющегоЛичность + " не задано соответствие Матрих";
	КонецЕсли;
	
КонецФункции

Функция СтрокаСоединенияСМатрих() Экспорт
	
	Если ПараметрыСеанса.ЭтоРабочаяИнформационнаяБаза Тогда
		Возврат "Driver={SQL Server};Server=AP21.G1.LAN;UID=svc_API_AM;PWD=p8z4gr39VAxXAfhn;Database=MatriX";
	Иначе	
		//Возврат "Driver={SQL Server};Server=AP22.G1.LAN;UID=svc_API_AM;PWD=p8z4gr39VAxXAfhn;Database=MatriX";
		Возврат "Driver={SQL Server};Server=AP25.G1.LAN;UID=svc_API_AM;PWD=p8z4gr39VAxXAfhn;Database=MatriX";
	КонецЕсли;
	
КонецФункции

Функция СтрокаСоединенияСМатрихExternal() Экспорт
	
	Возврат "Driver={SQL Server};Server=AP15.G1.LAN;UID=svc_API_AM;PWD=p8z4gr39VAxXAfhn;Database=MatriX_External";
	
КонецФункции

#Область Взаимодействие_с_Бухгалтерией

Функция ПолучитьCOMСоединениеСБухгалтерией(Организация) Экспорт
	
	Отказ = Ложь;
	Бухгалтерия = Неопределено;
	
	ПараметрыСоединения = Новый Структура("Организация", Организация);
	
#Область СтрокаСоединенияСБазойБухгалтерии
	
	СтрокаСоединенияСБазойБухгалтерии = ПланыВидовХарактеристик.ДополнительныеСведения.ЗначениеДополнительнойНастройки(, "ПрочиеНастройки.СтрокаСоединенияСБазойБухгалтерии", Организация);
	Если ЗначениеЗаполнено(СтрокаСоединенияСБазойБухгалтерии) И СтрЧислоВхождений(СтрокаСоединенияСБазойБухгалтерии, "Usr=") = 0 Тогда
		СтрокаСоединенияСБазойБухгалтерии = СтрокаСоединенияСБазойБухгалтерии + "Usr=""robotOLE"";";
	КонецЕсли;
	
	ПараметрыСоединения.Вставить("СтрокаСоединенияСБазойБухгалтерии", СтрокаСоединенияСБазойБухгалтерии);
	
	Если ЗначениеЗаполнено(СтрокаСоединенияСБазойБухгалтерии) И СтрЧислоВхождений(СтрокаСоединенияСБазойБухгалтерии, "Pwd=") = 0 Тогда
		СтрокаСоединенияСБазойБухгалтерии = СтрокаСоединенияСБазойБухгалтерии + "Pwd=""11111""";
	КонецЕсли;
	
	Если НЕ ЗначениеЗаполнено(СтрокаСоединенияСБазойБухгалтерии) Тогда
		ОбщегоНазначенияКлиентСервер.СообщитьПользователю("Не задана строка соединения с базой бухгалтерии для организации " + Организация,,,, Отказ);
	КонецЕсли;
	
#КонецОбласти
	
#Область ИмяКомпонентыСоединенияСБазойБухгалтерии

	ИмяКомпонентыСоединенияСБазойБухгалтерии = ПланыВидовХарактеристик.ДополнительныеСведения.ЗначениеДополнительнойНастройки(, "ПрочиеНастройки.ИмяКомпонентыСоединенияСБазойБухгалтерии", Организация);
	ПараметрыСоединения.Вставить("ИмяКомпонентыСоединенияСБазойБухгалтерии", ИмяКомпонентыСоединенияСБазойБухгалтерии);
	
	Если НЕ ЗначениеЗаполнено(ИмяКомпонентыСоединенияСБазойБухгалтерии) Тогда
		ОбщегоНазначенияКлиентСервер.СообщитьПользователю("Не задано имя компоненты соединения с базой бухгалтерии",,,, Отказ);
	КонецЕсли;
	
#КонецОбласти		
	
	Если НЕ Отказ Тогда
		
		Механизм = "РаботаСВнешнимиСистемами.ПолучитьCOMСоединениеСБухгалтерией";
		
		ПараметрыВыполненияДляСбораСтатистики = РегистрыСведений.СтатистикаРаботыВнутреннихМеханизмов.ПолучитьПараметрыВыполнения(ПараметрыСоединения, "Организация, СтрокаСоединенияСБазойБухгалтерии, ИмяКомпонентыСоединенияСБазойБухгалтерии");
		Сессия = РегистрыСведений.СтатистикаРаботыВнутреннихМеханизмов.ЗарегистрироватьНовуюСессию(
			Механизм,
			ПараметрыВыполненияДляСбораСтатистики.Хранилище,
			ПараметрыВыполненияДляСбораСтатистики.Описание);            
		
		Попытка
			
			Соединение = Новый COMОбъект(ИмяКомпонентыСоединенияСБазойБухгалтерии);
			Бухгалтерия = Соединение.Connect(СтрокаСоединенияСБазойБухгалтерии);
			
			КраткоеПредставлениеОшибки = Неопределено;
			
		Исключение
			
			ИнформацияОбОшибке = ИнформацияОбОшибке();
			
			// Выведем сообщение для пользователя
			КраткоеПредставлениеОшибки = ОбработкаОшибок.КраткоеПредставлениеОшибки(ИнформацияОбОшибке);
			ОбщегоНазначенияКлиентСервер.СообщитьПользователю("Ошибка подключения к бухгалтерской базе! " + КраткоеПредставлениеОшибки); 
			
			// Добавим запись в журнал регистрации
			ПодробноеПредставлениеОшибки = ОбработкаОшибок.ПодробноеПредставлениеОшибки(ИнформацияОбОшибке);
			ИсточникОшибки = "РаботаСВнешнимиСистемами.ПолучитьCOMСоединениеСБухгалтерией";
			ЗаписьЖурналаРегистрации(ИсточникОшибки, УровеньЖурналаРегистрации.Ошибка, , ИсточникОшибки, ПодробноеПредставлениеОшибки);
			
		КонецПопытки;
		
		РегистрыСведений.СтатистикаРаботыВнутреннихМеханизмов.ЗарегистрироватьОкончаниеСессии(Механизм, Сессия,,, КраткоеПредставлениеОшибки);
		
	КонецЕсли;
	
	Возврат Бухгалтерия;
	
КонецФункции

Функция ПолучитьОрганизациюБухгалтерии(СоединениеСБухгалтерией, Организация) Экспорт
	
	Если Организация = ОбщегоНазначения.ПолучитьИменованныйОбъект("Организация_РПИ") Тогда
		ИдентификаторОрганизации = "25edd09e-d191-42ba-8dad-254d7b4f535d";
	ИначеЕсли Организация = ОбщегоНазначения.ПолучитьИменованныйОбъект("Организация_РЭМ") Тогда
		ИдентификаторОрганизации = "24f247b5-fc83-4b90-94b9-f48f5b4c897b";
	ИначеЕсли Организация = ОбщегоНазначения.ПолучитьИменованныйОбъект("Организация_ТрастМ") Тогда
		ИдентификаторОрганизации = "a10bacb9-5299-11e3-934d-000c29e4a50d";
	ИначеЕсли Организация = ОбщегоНазначения.ПолучитьИменованныйОбъект("Организация_МДТраст") Тогда
		ИдентификаторОрганизации = "eb907965-5cfb-11e9-80d1-005056ae724d";
	Иначе
		ВызватьИсключение СтрШаблон("Соответствие организации '%1' в информационной базе бухгалтерии не задано!", Организация);
	КонецЕсли;		

	ОрганизацияБухгалтерии = СоединениеСБухгалтерией.Справочники.Организации.ПолучитьСсылку(СоединениеСБухгалтерией.NewObject("УникальныйИдентификатор", ИдентификаторОрганизации));
	
	Возврат ОрганизацияБухгалтерии;
	
КонецФункции

Функция ПолучитьСтоимостьСобственныхСредствИзБухгалтерии(Организация, Период, СоединениеСБухгалтерией = Неопределено) Экспорт
	
	// Соединение с ИБ бухгалтерии
	
	Если СоединениеСБухгалтерией = Неопределено Тогда
		СоединениеСБухгалтерией = ПолучитьCOMСоединениеСБухгалтерией(Организация);
	КонецЕсли;
	
	Если СоединениеСБухгалтерией = Неопределено Тогда
		ОбщегоНазначенияКлиентСервер.СообщитьПользователю("Не удалось подключиться к базе бухгалтерии. Получение информации о стоимости собственных средств невозможно!"); 
		Возврат Неопределено;
	КонецЕсли;
	
	// Получаем данные из ИБ бухгалтерии
	
	Запрос = СоединениеСБухгалтерией.NewObject("Запрос");
	
	Запрос.Текст = 
		"ВЫБРАТЬ РАЗРЕШЕННЫЕ ПЕРВЫЕ 1
		|	ПРЕДСТАВЛЕНИЕССЫЛКИ(РЕГ_XBRL_0420514СобственныеСредства.Ссылка) КАК Ссылка,
		|	РЕГ_XBRL_0420514СобственныеСредства.Сумма КАК Сумма
		|ИЗ
		|	Документ.РЕГ_XBRL_0420514.СобственныеСредства КАК РЕГ_XBRL_0420514СобственныеСредства
		|ГДЕ
		|	РЕГ_XBRL_0420514СобственныеСредства.Ссылка.Организация = &Организация
		|	И РЕГ_XBRL_0420514СобственныеСредства.Ссылка.ДатаКон = &Дата
		|	И (РЕГ_XBRL_0420514СобственныеСредства.КодСтроки = ""07""
		|			ИЛИ РЕГ_XBRL_0420514СобственныеСредства.ИДПоказателя = ""RazmerSobstvennyxSredstv"")
		|	И НЕ РЕГ_XBRL_0420514СобственныеСредства.Ссылка.ПометкаУдаления
		|	И РЕГ_XBRL_0420514СобственныеСредства.Ссылка.Состояние = ЗНАЧЕНИЕ(Перечисление.УПЦБ_СостоянияОтчетов.Утвержден)
		|
		|УПОРЯДОЧИТЬ ПО
		|	РЕГ_XBRL_0420514СобственныеСредства.Ссылка.Дата УБЫВ";
	
	Если Период > Дата(2023, 4, 1) Тогда 
		Запрос.Текст = СтрЗаменить(Запрос.Текст, "Документ.РЕГ_XBRL_0420514.СобственныеСредства", "Документ.РЕГ_XBRL_0420514_версия_5.СобственныеСредства");
	ИначеЕсли Период > Дата(2021, 10, 1) Тогда
		Запрос.Текст = СтрЗаменить(Запрос.Текст, "Документ.РЕГ_XBRL_0420514.СобственныеСредства", "Документ.РЕГ_XBRL_0420514_версия_4.СобственныеСредства");
	КонецЕсли;
	
	Запрос.УстановитьПараметр("Дата"		, НачалоДня(Период));
	Запрос.УстановитьПараметр("Организация"	, ПолучитьОрганизациюБухгалтерии(СоединениеСБухгалтерией, Организация));
	
	Выборка = Запрос.Выполнить().Выбрать();
	
	Если Выборка.Следующий() Тогда
		СтоимостьСобственныхСредствИзБухгалтерии = Выборка.Сумма;
	Иначе
		СтоимостьСобственныхСредствИзБухгалтерии = 0;
		ОбщегоНазначенияКлиентСервер.СообщитьПользователю("Не обнаружен отчёт 0420514 в бухгалтерской базе на " + Формат(Период, "ДФ=dd.MM.yyyy") + ". Получение информации о стоимости собственных средств невозможно!"); 
	КонецЕсли;
	
	Возврат СтоимостьСобственныхСредствИзБухгалтерии;
	
КонецФункции

//Получает данные о вознаграждении управляющего из бухгалтерской базы
//	Сопоставление договоров бух-ии и счетов ДУ бэк-офиса производится по номеру договора и дате заключения
//	Если в базе бэк-офиса присутствует несколько счетов ДУ с одинаковыми номером и датой, то ВУК сопоставляется с рандомным счётом ДУ из этого списка, у остальных из списка вознаграждение будет 0.
//
// Параметры:
//	ВидВознаграждения - "Начисленное" - начисленное вознаграждение, "Удержанное" - удержанное вознаграждение
//
Функция ПолучитьДанныеБухгалтерииОВознагражденииУК(ВидВознаграждения, НачалоПериода, КонецПериода, Организация, СчетаДоверительногоУправления = Неопределено, СоединениеСБухгалтерией = Неопределено) Экспорт
	
	// Соединение с ИБ бухгалтерии
	
	Если СоединениеСБухгалтерией = Неопределено Тогда
		СоединениеСБухгалтерией = ПолучитьCOMСоединениеСБухгалтерией(Организация);
	КонецЕсли;
	
	Если СоединениеСБухгалтерией = Неопределено Тогда
		Возврат Неопределено;
	КонецЕсли;
	
	// Получаем данные из ИБ бухгалтерии
	
	Попытка
		
		ЗапросБухгалтерии = СоединениеСБухгалтерией.NewObject("Запрос");
		
		Если ВидВознаграждения = "Начисленное" Тогда
			
			#Область Текст_запроса_начисленного_вознаграждения
			
			ЗапросБухгалтерии.Текст = 
				"ВЫБРАТЬ РАЗРЕШЕННЫЕ
				|	Вознаграждение.ДатаОперации КАК ДатаОперации,
				|	Вознаграждение.Отправитель КАК Отправитель,
				|	Вознаграждение.НомерДоговора КАК НомерДоговора,
				|	Вознаграждение.ДатаДоговора КАК ДатаДоговора,
				|	""<Не определен>"" КАК СчетОтправителя,
				|	СУММА(Вознаграждение.Сумма) КАК Сумма
				|ИЗ
				|	(ВЫБРАТЬ
				|		НАЧАЛОПЕРИОДА(БНФОБанковскийОборотыДтКт.Период, ДЕНЬ) КАК ДатаОперации,
				|		БНФОБанковскийОборотыДтКт.СубконтоДт1.Наименование КАК Отправитель,
				|		БНФОБанковскийОборотыДтКт.СубконтоДт2.Номер КАК НомерДоговора,
				|		БНФОБанковскийОборотыДтКт.СубконтоДт2.Дата КАК ДатаДоговора,
				|		БНФОБанковскийОборотыДтКт.СуммаОборот КАК Сумма
				|	ИЗ
				|		РегистрБухгалтерии.БНФОБанковский.ОборотыДтКт(
				|				&ДатаНачала,
				|				&ДатаОкончания,
				|				День,
				|				СчетДт.Код = ""47902"",
				|				,
				|				СчетКт.Код = ""71602"",
				|				,
				|				Организация = &Организация) КАК БНФОБанковскийОборотыДтКт
				|	
				|	ОБЪЕДИНИТЬ 
				|	
				|	ВЫБРАТЬ
				|		НАЧАЛОПЕРИОДА(БНФОБанковскийОборотыДтКт.Период, ДЕНЬ) КАК ДатаОперации,
				|		БНФОБанковскийОборотыДтКт.СубконтоКт1.Наименование КАК Отправитель,
				|		БНФОБанковскийОборотыДтКт.СубконтоКт2.Номер КАК НомерДоговора,
				|		БНФОБанковскийОборотыДтКт.СубконтоКт2.Дата КАК ДатаДоговора,
				|		- БНФОБанковскийОборотыДтКт.СуммаОборот КАК Сумма
				|	ИЗ
				|		РегистрБухгалтерии.БНФОБанковский.ОборотыДтКт(
				|				&ДатаНачала,
				|				&ДатаОкончания,
				|				День,
				|				СчетДт.Код = ""71602"",
				|				,
				|				СчетКт.Код = ""47903"",
				|				,
				|				Организация = &Организация) КАК БНФОБанковскийОборотыДтКт) КАК Вознаграждение
				|
				|СГРУППИРОВАТЬ ПО
				|	Вознаграждение.ДатаОперации,
				|	Вознаграждение.Отправитель,
				|	Вознаграждение.НомерДоговора,
				|	Вознаграждение.ДатаДоговора";
			
			#КонецОбласти

		ИначеЕсли ВидВознаграждения = "Удержанное" Тогда
			
			#Область Текст_запроса_удержанного_вознаграждения
			
			ЗапросБухгалтерии.Текст = 
			    "ВЫБРАТЬ РАЗРЕШЕННЫЕ
				|	СтатьиДвиженияДенежныхСредств.Ссылка КАК Статья
				|ПОМЕСТИТЬ ВТ_СтатьиДДС_Вознаграждение
				|ИЗ
				|	Справочник.СтатьиДвиженияДенежныхСредств КАК СтатьиДвиженияДенежныхСредств
				|ГДЕ
				|	(СтатьиДвиженияДенежныхСредств.Наименование ПОДОБНО ""%Вознаграждение УК%""
				|		ИЛИ СтатьиДвиженияДенежныхСредств.КодВидаОперацииНФО В (""01750"", ""01700""))
				|;
				|
				|////////////////////////////////////////////////////////////////////////////////
				|ВЫБРАТЬ РАЗРЕШЕННЫЕ
				|	Вознаграждение.ДатаОперации КАК ДатаОперации,
				|	Вознаграждение.Отправитель КАК Отправитель,
				|	Вознаграждение.НомерДоговора КАК НомерДоговора,
				|	Вознаграждение.ДатаДоговора КАК ДатаДоговора,
				|	Вознаграждение.СчетОтправителя КАК СчетОтправителя,
				|	СУММА(Сумма) КАК Сумма
				|ИЗ
				|	(ВЫБРАТЬ 
				|		НАЧАЛОПЕРИОДА(БНФОБанковскийОборотыДтКт.Период, ДЕНЬ) КАК ДатаОперации,
				|		БНФОБанковскийОборотыДтКт.СубконтоКт1.Наименование КАК Отправитель,
				|		БНФОБанковскийОборотыДтКт.СубконтоКт2.Номер КАК НомерДоговора,
				|		БНФОБанковскийОборотыДтКт.СубконтоКт2.Дата КАК ДатаДоговора,
				|		ПоступлениеНаРасчетныйСчет.СчетКонтрагента.НомерСчета КАК СчетОтправителя,
				|		БНФОБанковскийОборотыДтКт.СуммаОборот КАК Сумма
				|	ИЗ
				|		РегистрБухгалтерии.БНФОБанковский.ОборотыДтКт(
				|				&ДатаНачала,
				|				&ДатаОкончания,
				|				Регистратор,
				|				СчетДт.Код = ""20501"",
				|				,
				|				СчетКт.Код В (""47902"", ""47903""),
				|				,
				|				СубконтоДт2 В
				|						(ВЫБРАТЬ
				|							ВТ_СтатьиДДС_Вознаграждение.Статья КАК Статья
				|						ИЗ
				|							ВТ_СтатьиДДС_Вознаграждение КАК ВТ_СтатьиДДС_Вознаграждение)
				|					И Организация = &Организация) КАК БНФОБанковскийОборотыДтКт
				|			ЛЕВОЕ СОЕДИНЕНИЕ Документ.ПоступлениеНаРасчетныйСчет КАК ПоступлениеНаРасчетныйСчет
				|			ПО БНФОБанковскийОборотыДтКт.Регистратор = ПоступлениеНаРасчетныйСчет.Ссылка
				|	
				|	ОБЪЕДИНИТЬ ВСЕ
				|	
				|	ВЫБРАТЬ 
				|		НАЧАЛОПЕРИОДА(БНФОБанковскийОборотыДтКт.Период, ДЕНЬ) КАК ДатаОперации,
				|		БНФОБанковскийОборотыДтКт.СубконтоДт1.Наименование КАК Отправитель,
				|		БНФОБанковскийОборотыДтКт.СубконтоДт2.Номер КАК НомерДоговора,
				|		БНФОБанковскийОборотыДтКт.СубконтоДт2.Дата КАК ДатаДоговора,
				|		СписаниеСРасчетногоСчета.СчетКонтрагента.НомерСчета КАК СчетОтправителя,
				|		-БНФОБанковскийОборотыДтКт.СуммаОборот КАК Сумма
				|	ИЗ
				|		РегистрБухгалтерии.БНФОБанковский.ОборотыДтКт(
				|				&ДатаНачала,
				|				&ДатаОкончания,
				|				Регистратор,
				|				СчетДт.Код В (""47902"", ""47903""),
				|				,
				|				СчетКт.Код = ""20501"",
				|				,
				|				СубконтоКт2 В
				|						(ВЫБРАТЬ
				|							ВТ_СтатьиДДС_Вознаграждение.Статья КАК Статья
				|						ИЗ
				|							ВТ_СтатьиДДС_Вознаграждение КАК ВТ_СтатьиДДС_Вознаграждение)
				|					И Организация = &Организация
				|				) КАК БНФОБанковскийОборотыДтКт
				|			ЛЕВОЕ СОЕДИНЕНИЕ Документ.СписаниеСРасчетногоСчета КАК СписаниеСРасчетногоСчета
				|			ПО БНФОБанковскийОборотыДтКт.Регистратор = СписаниеСРасчетногоСчета.Ссылка) КАК Вознаграждение 
				|	
				|СГРУППИРОВАТЬ ПО
				|	Вознаграждение.ДатаОперации,
				|	Вознаграждение.Отправитель,
				|	Вознаграждение.НомерДоговора,
				|	Вознаграждение.ДатаДоговора,
				|	Вознаграждение.СчетОтправителя";
			
			#КонецОбласти

		Иначе
			
			ВызватьИсключение "Неверно задан вид вознаграждения из бух-ии. Возможные варианты: ""Начисленное"", ""Удержанное""";
		
		КонецЕсли;
	
		ОрганизацияБухгалтерии = РаботаСВнешнимиСистемами.ПолучитьОрганизациюБухгалтерии(СоединениеСБухгалтерией, Организация);
			
		ЗапросБухгалтерии.УстановитьПараметр("ДатаНачала",		НачалоПериода);
		ЗапросБухгалтерии.УстановитьПараметр("ДатаОкончания",	КонецПериода);
		ЗапросБухгалтерии.УстановитьПараметр("Организация",		ОрганизацияБухгалтерии);
		
		// В базе бухгалтерии до слияния РЭМа и Траста две организации
		Если Организация = ОбщегоНазначения.ПолучитьИменованныйОбъект("Организация_РЭМ") 
			И НачалоПериода >= '20260101'
			И НачалоПериода <= '20260414' Тогда
			
			//Если передавать организации массивом, запрос почему-то зависает. Поэтому используем ИЛИ
			ЗапросБухгалтерии.Текст = СтрЗаменить(ЗапросБухгалтерии.Текст, "Организация = &Организация", "(Организация = &Организация ИЛИ Организация = &ОрганизацияДоп)");
			
			ОрганизацияДоп = СоединениеСБухгалтерией.Справочники.Организации.ПолучитьСсылку(СоединениеСБухгалтерией.NewObject("УникальныйИдентификатор", "a10bacb9-5299-11e3-934d-000c29e4a50d"));
			ЗапросБухгалтерии.УстановитьПараметр("ОрганизацияДоп", ОрганизацияДоп);
			
		КонецЕсли;
		
		ТаблицаВознагражденийБухгалтерии = Новый ТаблицаЗначений;
		ТаблицаВознагражденийБухгалтерии.Колонки.Добавить("Отправитель",	 Новый ОписаниеТипов("Строка", , , , Новый КвалификаторыСтроки(150)));
		ТаблицаВознагражденийБухгалтерии.Колонки.Добавить("НомерДоговора",	 Новый ОписаниеТипов("Строка", , , , Новый КвалификаторыСтроки(50)));
		ТаблицаВознагражденийБухгалтерии.Колонки.Добавить("ДатаДоговора",	 Новый ОписаниеТипов("Дата"));
		ТаблицаВознагражденийБухгалтерии.Колонки.Добавить("СчетОтправителя", Новый ОписаниеТипов("Строка", , , , Новый КвалификаторыСтроки(50)));
		ТаблицаВознагражденийБухгалтерии.Колонки.Добавить("ДатаОперации",	 Новый ОписаниеТипов("Дата"));
		ТаблицаВознагражденийБухгалтерии.Колонки.Добавить("Сумма",			 Новый ОписаниеТипов("Число"));
		
		ВыборкаБухгалтерии = ЗапросБухгалтерии.Выполнить().Выбрать();
		Пока ВыборкаБухгалтерии.Следующий() Цикл
			НоваяСтрока = ТаблицаВознагражденийБухгалтерии.Добавить();
			ЗаполнитьЗначенияСвойств(НоваяСтрока, ВыборкаБухгалтерии);
			НоваяСтрока.НомерДоговора = СокрЛП(НоваяСтрока.НомерДоговора);
		КонецЦикла;

	Исключение
		
		ОбщегоНазначенияКлиентСервер.СообщитьПользователю("Ошибка получения данных из информационной базы бухгалтерии: " + ОписаниеОшибки());
		Возврат Неопределено;
		
	КонецПопытки;
	
	#Область Текст_запроса_для_идентификации_счетов_ДУ
	
	ТекстЗапроса =
		"ВЫБРАТЬ РАЗРЕШЕННЫЕ
		|	ВознагражденияУК.Отправитель КАК Отправитель,
		|	ВознагражденияУК.НомерДоговора КАК НомерДоговора,
		|	ВознагражденияУК.ДатаДоговора КАК ДатаДоговора,
		|	ВознагражденияУК.СчетОтправителя КАК СчетОтправителя,
		|	ВознагражденияУК.Сумма КАК Сумма,
		|	ВознагражденияУК.ДатаОперации КАК Период
		|ПОМЕСТИТЬ _ВознагражденияУК
		|ИЗ
		|	&ВознагражденияУК КАК ВознагражденияУК
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|ВЫБРАТЬ РАЗРЕШЕННЫЕ
		|	ВЫБОР
		|		КОГДА КлиентыДоверительногоУправленияСрезПоследних.Клиент ССЫЛКА Справочник.ПаевыеИнвестиционныеФонды
		|			ТОГДА КлиентыДоверительногоУправленияСрезПоследних.Клиент.НомерПравил
		|		ИНАЧЕ СчетаДоверительногоУправления.НомерДоговора
		|	КОНЕЦ КАК НомерДоговора,
		|	ВЫБОР
		|		КОГДА КлиентыДоверительногоУправленияСрезПоследних.Клиент ССЫЛКА Справочник.ПаевыеИнвестиционныеФонды
		|			ТОГДА КлиентыДоверительногоУправленияСрезПоследних.Клиент.ДатаПравил
		|		ИНАЧЕ СчетаДоверительногоУправления.ДатаЗаключения
		|	КОНЕЦ КАК ДатаДоговора,
		|	МИНИМУМ(СчетаДоверительногоУправления.Ссылка) КАК СчетДоверительногоУправления
		|ПОМЕСТИТЬ _ДоговорыСчетовДУ
		|ИЗ
		|	Справочник.СчетаДоверительногоУправления КАК СчетаДоверительногоУправления
		|		ЛЕВОЕ СОЕДИНЕНИЕ РегистрСведений.КлиентыДоверительногоУправления.СрезПоследних(&ДатаОкончания, ) КАК КлиентыДоверительногоУправленияСрезПоследних
		|		ПО СчетаДоверительногоУправления.Ссылка = КлиентыДоверительногоУправленияСрезПоследних.СчетДоверительногоУправления
		|ГДЕ
		|	СчетаДоверительногоУправления.Организация = &Организация
		|	И НЕ СчетаДоверительногоУправления.Ссылка В (&ИсключаемыеСчетаДУ)
		|
		|СГРУППИРОВАТЬ ПО
		|	ВЫБОР
		|		КОГДА КлиентыДоверительногоУправленияСрезПоследних.Клиент ССЫЛКА Справочник.ПаевыеИнвестиционныеФонды
		|			ТОГДА КлиентыДоверительногоУправленияСрезПоследних.Клиент.НомерПравил
		|		ИНАЧЕ СчетаДоверительногоУправления.НомерДоговора
		|	КОНЕЦ,
		|	ВЫБОР
		|		КОГДА КлиентыДоверительногоУправленияСрезПоследних.Клиент ССЫЛКА Справочник.ПаевыеИнвестиционныеФонды
		|			ТОГДА КлиентыДоверительногоУправленияСрезПоследних.Клиент.ДатаПравил
		|		ИНАЧЕ СчетаДоверительногоУправления.ДатаЗаключения
		|	КОНЕЦ
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|ВЫБРАТЬ РАЗРЕШЕННЫЕ
		|	ЕСТЬNULL(_ДоговорыСчетовДУ.СчетДоверительногоУправления, ЗНАЧЕНИЕ(Справочник.СчетаДоверительногоУправления.ПустаяСсылка)) КАК СчетДоверительногоУправления,
		|	_ВознагражденияУК.Период КАК Период,
		|	_ВознагражденияУК.Отправитель КАК Отправитель,
		|	_ВознагражденияУК.НомерДоговора КАК НомерДоговора,
		|	_ВознагражденияУК.ДатаДоговора КАК ДатаДоговора,
		|	_ВознагражденияУК.СчетОтправителя КАК СчетОтправителя,
		|	_ВознагражденияУК.Сумма КАК Сумма
		|ПОМЕСТИТЬ _ВознагражденияУКСоСчетамиДУ
		|ИЗ
		|	_ВознагражденияУК КАК _ВознагражденияУК
		|		ЛЕВОЕ СОЕДИНЕНИЕ _ДоговорыСчетовДУ КАК _ДоговорыСчетовДУ
		|		ПО (_ВознагражденияУК.НомерДоговора В (_ДоговорыСчетовДУ.НомерДоговора, ""Договор ДУ № "" + _ДоговорыСчетовДУ.НомерДоговора, ""№"" + _ДоговорыСчетовДУ.НомерДоговора, ""Дговор ДУ № "" + _ДоговорыСчетовДУ.НомерДоговора, ""Договор ДУ "" + _ДоговорыСчетовДУ.НомерДоговора, ""Договор ДУ №"" + _ДоговорыСчетовДУ.НомерДоговора, ""Договор №"" + _ДоговорыСчетовДУ.НомерДоговора))
		|			И _ВознагражденияУК.ДатаДоговора = _ДоговорыСчетовДУ.ДатаДоговора
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|ВЫБРАТЬ РАЗРЕШЕННЫЕ
		|	_ВознагражденияУКСоСчетамиДУ.Период КАК Период,
		|	_ВознагражденияУКСоСчетамиДУ.Отправитель КАК Отправитель,
		|	_ВознагражденияУКСоСчетамиДУ.НомерДоговора КАК НомерДоговора,
		|	_ВознагражденияУКСоСчетамиДУ.ДатаДоговора КАК ДатаДоговора,
		|	_ВознагражденияУКСоСчетамиДУ.СчетОтправителя КАК СчетОтправителя,
		|	СУММА(_ВознагражденияУКСоСчетамиДУ.Сумма) КАК Сумма
		|ПОМЕСТИТЬ _ОшибкиИдентификации
		|ИЗ
		|	_ВознагражденияУКСоСчетамиДУ КАК _ВознагражденияУКСоСчетамиДУ
		|ГДЕ
		|	_ВознагражденияУКСоСчетамиДУ.СчетДоверительногоУправления = ЗНАЧЕНИЕ(Справочник.СчетаДоверительногоУправления.ПустаяСсылка)
		|
		|СГРУППИРОВАТЬ ПО
		|	_ВознагражденияУКСоСчетамиДУ.Период,
		|	_ВознагражденияУКСоСчетамиДУ.Отправитель,
		|	_ВознагражденияУКСоСчетамиДУ.НомерДоговора,
		|	_ВознагражденияУКСоСчетамиДУ.ДатаДоговора,
		|	_ВознагражденияУКСоСчетамиДУ.СчетОтправителя
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|ВЫБРАТЬ РАЗРЕШЕННЫЕ
		|	ВложенныйЗапрос.СчетДоверительногоУправления КАК СчетДоверительногоУправления,
		|	КлиентыДоверительногоУправления.Клиент КАК Клиент,
		|	ВложенныйЗапрос.Период КАК Период,
		|	ВложенныйЗапрос.Отправитель КАК Отправитель,
		|	ВложенныйЗапрос.НомерДоговора КАК НомерДоговора,
		|	ВложенныйЗапрос.ДатаДоговора КАК ДатаДоговора,
		|	ВложенныйЗапрос.СчетОтправителя КАК СчетОтправителя,
		|	ВложенныйЗапрос.Сумма КАК Сумма
		|ПОМЕСТИТЬ _ТаблицаВознаграждений
		|ИЗ
		|	(ВЫБРАТЬ
		|		_ВознагражденияУКСоСчетамиДУ.СчетДоверительногоУправления КАК СчетДоверительногоУправления,
		|		_ВознагражденияУКСоСчетамиДУ.Период КАК Период,
		|		_ВознагражденияУКСоСчетамиДУ.Отправитель КАК Отправитель,
		|		_ВознагражденияУКСоСчетамиДУ.НомерДоговора КАК НомерДоговора,
		|		_ВознагражденияУКСоСчетамиДУ.ДатаДоговора КАК ДатаДоговора,
		|		_ВознагражденияУКСоСчетамиДУ.СчетОтправителя КАК СчетОтправителя,
		|		_ВознагражденияУКСоСчетамиДУ.Сумма КАК Сумма,
		|		МАКСИМУМ(КлиентыДоверительногоУправления.Период) КАК ДатаКлиента
		|	ИЗ
		|		_ВознагражденияУКСоСчетамиДУ КАК _ВознагражденияУКСоСчетамиДУ
		|			ЛЕВОЕ СОЕДИНЕНИЕ РегистрСведений.КлиентыДоверительногоУправления КАК КлиентыДоверительногоУправления
		|			ПО _ВознагражденияУКСоСчетамиДУ.СчетДоверительногоУправления = КлиентыДоверительногоУправления.СчетДоверительногоУправления
		|				И _ВознагражденияУКСоСчетамиДУ.Период >= КлиентыДоверительногоУправления.Период
		|	ГДЕ
		|		(_ВознагражденияУКСоСчетамиДУ.СчетДоверительногоУправления В (&СчетаДоверительногоУправления)
		|				ИЛИ &СчетаДоверительногоУправления = НЕОПРЕДЕЛЕНО
		|					И _ВознагражденияУКСоСчетамиДУ.СчетДоверительногоУправления <> ЗНАЧЕНИЕ(Справочник.СчетаДоверительногоУправления.ПустаяСсылка))
		|	
		|	СГРУППИРОВАТЬ ПО
		|		_ВознагражденияУКСоСчетамиДУ.Отправитель,
		|		_ВознагражденияУКСоСчетамиДУ.НомерДоговора,
		|		_ВознагражденияУКСоСчетамиДУ.СчетДоверительногоУправления,
		|		_ВознагражденияУКСоСчетамиДУ.ДатаДоговора,
		|		_ВознагражденияУКСоСчетамиДУ.СчетОтправителя,
		|		_ВознагражденияУКСоСчетамиДУ.Сумма,
		|		_ВознагражденияУКСоСчетамиДУ.Период) КАК ВложенныйЗапрос
		|		ЛЕВОЕ СОЕДИНЕНИЕ РегистрСведений.КлиентыДоверительногоУправления КАК КлиентыДоверительногоУправления
		|		ПО ВложенныйЗапрос.СчетДоверительногоУправления = КлиентыДоверительногоУправления.СчетДоверительногоУправления
		|			И ВложенныйЗапрос.ДатаКлиента = КлиентыДоверительногоУправления.Период";
	
	#КонецОбласти
	
	//Из бухгалтерии выгружаются вознаграждения УК. Среди ключевых полей номер договора (для клиентов ПИФ - номер правил). По номеру правил ищется СДУ клиента.
	//Для Академии и Современного взгляда находятся сразу два счета ДУ, т.к. там нет никаких проверок на дату расторжения, а эти два счета ДУ в марте 2026 были закрыты в Трасте и открыты в ЭсМ.
	//Т.к. отчетность ЦБ в рабочей базе должна строиться начиная с периода апрель 2026 года и дальше, то счета ДУ Академия и Современный взгляд, ранее принадлежащие организации Траст, добавим в исключения
	ИсключаемыеСчетаДУ = Новый Массив;
	ИсключаемыеСчетаДУ.Добавить(ОбщегоНазначения.ПолучитьИменованныйОбъект("СчетДУ_Академия"));
	ИсключаемыеСчетаДУ.Добавить(ОбщегоНазначения.ПолучитьИменованныйОбъект("СчетДУ_СовременныйВзгляд"));
	
	Запрос = Новый Запрос(ТекстЗапроса);
	Запрос.МенеджерВременныхТаблиц = Новый МенеджерВременныхТаблиц;
	
	Запрос.УстановитьПараметр("Организация",					Организация);
	Запрос.УстановитьПараметр("СчетаДоверительногоУправления",	СчетаДоверительногоУправления);
	Запрос.УстановитьПараметр("ДатаОкончания",					КонецПериода);
	Запрос.УстановитьПараметр("ВознагражденияУК",				ТаблицаВознагражденийБухгалтерии);
	Запрос.УстановитьПараметр("ИсключаемыеСчетаДУ",				ИсключаемыеСчетаДУ);

	Запрос.Выполнить();
	
	ТаблицаВознаграждений	= Запрос.МенеджерВременныхТаблиц.Таблицы["_ТаблицаВознаграждений"].ПолучитьДанные().Выгрузить();
	ТаблицаОшибок			= Запрос.МенеджерВременныхТаблиц.Таблицы["_ОшибкиИдентификации"].ПолучитьДанные().Выгрузить();
	
	Если ТаблицаОшибок.Количество() > 0 Тогда
		
		#Область Вывод_сообщений_об_ошибках_идентификации
		
		ОбщегоНазначенияКлиентСервер.СообщитьПользователю("При импорте вознаграждений (" + ВидВознаграждения + ") из бухгалтерии не удалось идентифицировать счета ДУ");
		
		Для Каждого СтрокаДанных Из ТаблицаОшибок Цикл
			ОбщегоНазначенияКлиентСервер.СообщитьПользователю(СтрШаблон(	
				"Дата операции: %1
				|Отправитель: %2
				|Номер договора: %3 от %4
				|Счет отправителя: %5
				|Сумма: %6",
				Формат(СтрокаДанных.Период, "ДФ=dd.MM.yy"),
				СтрокаДанных.Отправитель,
				СтрокаДанных.НомерДоговора, Формат(СтрокаДанных.ДатаДоговора, "ДФ=dd.MM.yy"), 
				СтрокаДанных.СчетОтправителя,
				СтрокаДанных.Сумма));
		КонецЦикла;
		
		#КонецОбласти
		
	КонецЕсли;		

	Возврат ТаблицаВознаграждений;
	
КонецФункции

#КонецОбласти

////////////////////////////////////////////////////////////////////////////////
// ВЗАИМОДЕЙСТВИЕ С САЙТОМ ИИС

Функция ПолучитьДатуНачалаИмпортаССайта() Экспорт
	
	ДатаНачалаИмпорта = '20170801';
	
	Возврат ДатаНачалаИмпорта;
   
КонецФункции

Функция ПолучитьДанныеССайта(ДатаНачалаИмпорта) Экспорт
	
	АдресСервера = "iis-pvt.region-am.ru";
	АдресСкрипта = "/api/v1/orders/export/xml/" + XMLСтрока(ДатаНачалаИмпорта);
	
	HTTPСоединение = Новый HTTPСоединение(АдресСервера,,,,,60);
	HTTPЗапрос     = Новый HTTPЗапрос(АдресСкрипта);
	
	Попытка
		HTTPОтвет = HTTPСоединение.Получить(HTTPЗапрос);
	Исключение
		
		ИнформацияОбОшибке = ИнформацияОбОшибке();
		ОбщегоНазначенияКлиентСервер.СообщитьПользователю("Ошибка получения данных с сайта " + АдресСервера + ": " + ИнформацияОбОшибке.Описание);
		
		Возврат Неопределено;
	КонецПопытки;
	
	СтрокаXML = HTTPОтвет.ПолучитьТелоКакСтроку("UTF-8");
	
	Если HTTPОтвет.КодСостояния <> 200 Тогда
		
		ОбщегоНазначенияКлиентСервер.СообщитьПользователю("Ошибка получения данных с сайта " 
			+ АдресСервера + ": код возврата " + HTTPОтвет.КодСостояния + " тело " + СтрокаXML);
			
		Возврат Неопределено;
		
	КонецЕсли;
	
	Возврат СтрокаXML;
	
КонецФункции

Функция ПолучитьКоллекциюОбъектов(СтрокаXML, ВнешняяСистема = Неопределено) Экспорт
	
	Попытка
		
		ЧтениеXML = Новый ЧтениеXML;
		ЧтениеXML.УстановитьСтроку(СтрокаXML);
		
		ДанныеXDTO = ФабрикаXDTO.ПрочитатьXML(ЧтениеXML);
		
	Исключение
		
		ИнформацияОбОшибке = ИнформацияОбОшибке();
		ОбщегоНазначенияКлиентСервер.СообщитьПользователю("Ошибка чтения XML: " + ИнформацияОбОшибке.Описание);
		
		Возврат Неопределено;
	КонецПопытки;

	// Внешняя система по умолчанию
	Если ВнешняяСистема = Неопределено Тогда
		ВнешняяСистема = Справочники.ВнешниеСистемы.СайтИИС;
	КонецЕсли;
	
	// Определяем формат XML по внешней системе
	Если ВнешняяСистема = Справочники.ВнешниеСистемы.СайтИИС Тогда	
		// Пустая коллекция
		Если ДанныеXDTO.Свойства().Получить("order") = Неопределено Тогда
			Возврат Неопределено;	
		КонецЕсли;
		
		Если ТипЗнч(ДанныеXDTO.order) = Тип("СписокXDTO") Тогда
			Возврат ДанныеXDTO.order;
		Иначе
			КоллекцияОбъектов = Новый Массив;
			КоллекцияОбъектов.Добавить(ДанныеXDTO.order);
			
			Возврат КоллекцияОбъектов;
		КонецЕсли;
		
	ИначеЕсли ВнешняяСистема = Справочники.ВнешниеСистемы.АгентыДУИИС Тогда
		// Пустая коллекция
		Если ДанныеXDTO.Свойства().Получить("АНКЕТА_ФИЗИЧЕСКОГО_ЛИЦА") = Неопределено Тогда
			Возврат Неопределено;	
		КонецЕсли;
		
		Если ТипЗнч(ДанныеXDTO) = Тип("СписокXDTO") Тогда
			Возврат ДанныеXDTO;
		Иначе
			КоллекцияОбъектов = Новый Массив;
			КоллекцияОбъектов.Добавить(ДанныеXDTO);
			
			Возврат КоллекцияОбъектов;
		КонецЕсли;
	КонецЕсли;	
КонецФункции

Функция ПрочитатьАнкетныеДанные(ОбъектXDTO, ВнешняяСистема = Неопределено) Экспорт
	// Внешняя система по умолчанию
	Если ВнешняяСистема = Неопределено Тогда
		ВнешняяСистема = Справочники.ВнешниеСистемы.СайтИИС;
	КонецЕсли;
	
	// Определяем формат анкеты по внешней системе
	Если ВнешняяСистема = Справочники.ВнешниеСистемы.СайтИИС Тогда	
		Возврат ПрочитатьАнкетныеДанныеССайта(ОбъектXDTO, ВнешняяСистема);
	ИначеЕсли ВнешняяСистема = Справочники.ВнешниеСистемы.АгентыДУИИС Тогда
		Возврат ПрочитатьАнкетныеДанныеИзФайла(ОбъектXDTO, ВнешняяСистема);
	КонецЕсли;
КонецФункции

Функция ПрочитатьАнкетныеДанныеССайта(ОбъектXDTO, ВнешняяСистема)
	// Инициализация вспомогательных переменных
	
	ГруппаОбъектов = Справочники.ГруппыИмпортируемыхОбъектов.АнкетыФизическихЛиц;
	
	ИменаПолейАдреса = Новый Структура;	
	ИменаПолейАдреса.Вставить("Страна", "country");	
	ИменаПолейАдреса.Вставить("Индекс", "index");	
	ИменаПолейАдреса.Вставить("Регион", "region");	
	ИменаПолейАдреса.Вставить("КодРегиона", "regioncode");	
	ИменаПолейАдреса.Вставить("Область", "area");	
	ИменаПолейАдреса.Вставить("НаселенныйПункт", "locality");	
	ИменаПолейАдреса.Вставить("Улица", "street");
	ИменаПолейАдреса.Вставить("Дом", "house");	
	ИменаПолейАдреса.Вставить("Корпус", "housing");	
	ИменаПолейАдреса.Вставить("Строение", "structure");	
	ИменаПолейАдреса.Вставить("Квартира", "flat");
	
	// Получаем и заполняем анкету
	КодВнешнейСистемы = ПолучитьЗначениеТипа(Тип("Строка"), ОбъектXDTO.order_id);
	АнкетаФизическогоЛица = НайтиЗначениеПоКодуВнешнейСистемы(ВнешняяСистема, ГруппаОбъектов, КодВнешнейСистемы);
	
	Если АнкетаФизическогоЛица <> Неопределено Тогда
		ДокументОбъект = АнкетаФизическогоЛица.ПолучитьОбъект();
	Иначе
		ДокументОбъект = Документы.АнкетаФизическогоЛица.СоздатьДокумент();	
		ДокументОбъект.Заполнить(Неопределено);
	КонецЕсли;
	
	ДокументОбъект.Организация = ПараметрыСеанса.ТекущаяОрганизация;
	
	ДокументОбъект.ВидИсточника = Перечисления.ИсточникиАнкетИЗаявок.Сайт;
	ДокументОбъект.УпрощеннаяИдентификация = Истина;
	
	ДокументОбъект.Фамилия  = ПолучитьЗначениеТипа(Тип("Строка"), ОбъектXDTO.surname);
	ДокументОбъект.Имя      = ПолучитьЗначениеТипа(Тип("Строка"), ОбъектXDTO.forename);
	ДокументОбъект.Отчество = ПолучитьЗначениеТипа(Тип("Строка"), ОбъектXDTO.patronymic);
	ДокументОбъект.Дата     = ПолучитьЗначениеТипа(Тип("Дата"),   ОбъектXDTO.datetime);
	
	Если Не ЗначениеЗаполнено(ДокументОбъект.Дата) Тогда
		// договорились, что с сайта datetime должен содержать данные,
		// а пришло пустое значение; в таком случае решили взять из другого поля
		ДокументОбъект.Дата = ПолучитьЗначениеТипа(Тип("Дата"), ОбъектXDTO.dealdate);
	КонецЕсли;
	
	ДокументОбъект.ДатаРождения  = ПолучитьЗначениеТипа(Тип("Дата"),   ОбъектXDTO.birthday);
	ДокументОбъект.МестоРождения = ПолучитьЗначениеТипа(Тип("Строка"), ОбъектXDTO.birthplace);
	
	ДокументОбъект.ИНН   = ПолучитьЗначениеТипа(Тип("Строка"), ОбъектXDTO.inn);
	ДокументОбъект.СНИЛС = ПолучитьЗначениеТипа(Тип("Строка"), ОбъектXDTO.snils);
	
	ДокументОбъект.ВидУдостоверенияЛичности           = Справочники.ВидыДокументовФизическихЛиц.ПаспортРФ;
	ДокументОбъект.СерияУдостоверенияЛичности         = ПолучитьЗначениеТипа(Тип("Строка"), ОбъектXDTO.passport.series, Истина);
	ДокументОбъект.НомерУдостоверенияЛичности         = ПолучитьЗначениеТипа(Тип("Строка"), ОбъектXDTO.passport.number, Истина);
	ДокументОбъект.ДатаВыдачиУдостоверенияЛичности    = ПолучитьЗначениеТипа(Тип("Дата"),   ОбъектXDTO.passport.issuedate);
	ДокументОбъект.ОрганВыдавшийУдостоверениеЛичности = ПолучитьЗначениеТипа(Тип("Строка"), ОбъектXDTO.passport.issuedby);
	ДокументОбъект.КодОрганаВыдавшегоУдостоверениеЛичности = ПолучитьЗначениеТипа(Тип("Строка"), ОбъектXDTO.passport.issuenum);
	
	Если Не ЗначениеЗаполнено(ДокументОбъект.СтатусПроверки) Тогда
		ДокументОбъект.СтатусПроверки = Перечисления.СтатусыПроверкиУдостоверенияЛичности.НеПроверен;	
	КонецЕсли;
	
	ДокументОбъект.Телефоны				= ПолучитьЗначениеТипа(Тип("Строка"), ОбъектXDTO.phone);
	ДокументОбъект.ТелефонДляОповещения = ПолучитьЗначениеТипа(Тип("Строка"), ОбъектXDTO.phone);
	
	ДокументОбъект.EMail    = ПолучитьЗначениеТипа(Тип("Строка"), ОбъектXDTO.email);
	
	ДокументОбъект.ПочтовыйАдрес        = ПрочитатьАдрес(ОбъектXDTO.mail, ИменаПолейАдреса);
	ДокументОбъект.ПочтовыйАдресФИАС	= ПрочитатьАдресФИАС(ОбъектXDTO.mail, ИменаПолейАдреса);
	
	ДокументОбъект.АдресРегистрации     = ПрочитатьАдрес(ОбъектXDTO.living, ИменаПолейАдреса);
	ДокументОбъект.АдресРегистрацииФИАС = ПрочитатьАдресФИАС(ОбъектXDTO.living, ИменаПолейАдреса);
	
	КодГражданства = ПолучитьЗначениеТипа(Тип("Строка"), ОбъектXDTO.citizenship);
	ДокументОбъект.Гражданство = Справочники.СтраныМира.НайтиПоРеквизиту("КодАльфа2", КодГражданства);
	
	КодРезиденства = ПолучитьЗначениеТипа(Тип("Строка"), ОбъектXDTO.taxresidency);
	ДокументОбъект.РезидентРФ = (КодРезиденства = Справочники.СтраныМира.Россия.КодАльфа2);
	
	ДокументОбъект.НалоговыйРезидентИностранногоГосударства	= КодРезиденства <> Справочники.СтраныМира.Россия.КодАльфа2;
	ДокументОбъект.РезидентПо173ФЗ							= Истина;
	ДокументОбъект.РаспространениеЗаконодательстваСША		= Ложь;
	ДокументОбъект.ИностранныйНалогоплательщик				= Ложь;
	ДокументОбъект.СогласиеНаПередачуИнформации				= Ложь;
	
	НомерБанковскогоСчета = ПолучитьЗначениеТипа(Тип("Строка"), ОбъектXDTO.return.rs);
	Если Не ПустаяСтрока(НомерБанковскогоСчета) Тогда
		Если ДокументОбъект.БанковскиеРеквизиты.Количество() Тогда
			СтрокаТабЧасти = ДокументОбъект.БанковскиеРеквизиты[0];
		Иначе
			СтрокаТабЧасти = ДокументОбъект.БанковскиеРеквизиты.Добавить();
		КонецЕсли;
		СтрокаТабЧасти.БИК               = ПолучитьЗначениеТипа(Тип("Строка"), ОбъектXDTO.return.bic);
		СтрокаТабЧасти.НаименованиеБанка = ПолучитьЗначениеТипа(Тип("Строка"), ОбъектXDTO.return.title);
		СтрокаТабЧасти.КоррСчет          = ПолучитьЗначениеТипа(Тип("Строка"), ОбъектXDTO.return.ks);
		СтрокаТабЧасти.НомерСчета        = НомерБанковскогоСчета;
		СтрокаТабЧасти.ПолучательПлатежа = ДокументОбъект.Фамилия + " " + ДокументОбъект.Имя + ?(ПустаяСтрока(ДокументОбъект.Отчество), "", " " + ДокументОбъект.Отчество);
	КонецЕсли;
	
	ДокументОбъект.ЦельДоверительноеУправление = Истина;
	
	ДокументОбъект.ПометкаУдаления = Ложь;
	
	Если НЕ ЗначениеЗаполнено(ДокументОбъект.ЮрФизЛицо) Тогда
		ДокументОбъект.ЗаполнитьЮрФизЛицо();
	КонецЕсли;
	
	Если НЕ ПроверитьВозможностьЗаписиАнкеты(ДокументОбъект) Тогда
		Возврат ДокументОбъект.ЮрФизЛицо;
	КонецЕсли;
	
	ОповещениеПриЗагрузкеДанныхВАнкету(ДокументОбъект);
	
	НачатьТранзакцию();
	
	ДокументОбъект.ДополнительныеСвойства.Вставить("ЗагрузкаДанныхВАнкету", Истина);
	ДокументОбъект.Записать(РежимЗаписиДокумента.Проведение);
	ЗарегистрироватьКодОбъектаВоВнешнейСистеме( ДокументОбъект.Ссылка, ВнешняяСистема, ГруппаОбъектов, КодВнешнейСистемы);
	
	ЗафиксироватьТранзакцию();
	
	Возврат ДокументОбъект.ЮрФизЛицо;
КонецФункции

Функция ПроверитьВозможностьЗаписиАнкеты(Документ)
	
	Результат = Истина;
	
	Если Документ.УпрощеннаяИдентификация Тогда
		
		Запрос = Новый Запрос;
		Запрос.УстановитьПараметр("Период",			Документ.Дата);
		Запрос.УстановитьПараметр("Организация",	Документ.Организация);
		Запрос.УстановитьПараметр("ЮрФизЛицо",		Документ.ЮрФизЛицо);
		Запрос.Текст =
			"ВЫБРАТЬ РАЗРЕШЕННЫЕ
			|	РеквизитыФизическихЛицАнкетныеСрезПоследних.Фамилия КАК Фамилия,
			|	РеквизитыФизическихЛицАнкетныеСрезПоследних.Имя КАК Имя,
			|	РеквизитыФизическихЛицАнкетныеСрезПоследних.Отчество КАК Отчество,
			|	РеквизитыФизическихЛицАнкетныеСрезПоследних.Пол КАК Пол,
			|	РеквизитыФизическихЛицАнкетныеСрезПоследних.ДатаРождения КАК ДатаРождения,
			|	РеквизитыФизическихЛицАнкетныеСрезПоследних.ИНН КАК ИНН,
			|	РеквизитыФизическихЛицАнкетныеСрезПоследних.ВидУдостоверенияЛичности КАК ВидУдостоверенияЛичности,
			|	РеквизитыФизическихЛицАнкетныеСрезПоследних.СерияУдостоверенияЛичности КАК СерияУдостоверенияЛичности,
			|	РеквизитыФизическихЛицАнкетныеСрезПоследних.НомерУдостоверенияЛичности КАК НомерУдостоверенияЛичности,
			|	РеквизитыФизическихЛицАнкетныеСрезПоследних.ДатаВыдачиУдостоверенияЛичности КАК ДатаВыдачиУдостоверенияЛичности,
			|	РеквизитыФизическихЛицАнкетныеСрезПоследних.ДатаОкончанияДействияУдостоверенияЛичности КАК ДатаОкончанияДействияУдостоверенияЛичности,
			|	РеквизитыФизическихЛицАнкетныеСрезПоследних.ОрганВыдавшийУдостоверениеЛичности КАК ОрганВыдавшийУдостоверениеЛичности,
			|	РеквизитыФизическихЛицАнкетныеСрезПоследних.КодОрганаВыдавшегоУдостоверениеЛичности КАК КодОрганаВыдавшегоУдостоверениеЛичности,
			|	РеквизитыФизическихЛицАнкетныеСрезПоследних.РезидентРФ КАК РезидентРФ,
			|	РеквизитыФизическихЛицАнкетныеСрезПоследних.Гражданство КАК Гражданство,
			|	РеквизитыФизическихЛицАнкетныеСрезПоследних.ВтороеГражданство КАК ВтороеГражданство,
			|	РеквизитыФизическихЛицАнкетныеСрезПоследних.СНИЛС КАК СНИЛС,
			|	РеквизитыФизическихЛицАнкетныеСрезПоследних.МестоРождения КАК МестоРождения,
			|	РеквизитыФизическихЛицАнкетныеСрезПоследних.ОГРНИП КАК ОГРНИП,
			|	РеквизитыФизическихЛицАнкетныеСрезПоследних.ДатаВыдачиОГРНИП КАК ДатаВыдачиОГРНИП,
			|	РеквизитыФизическихЛицАнкетныеСрезПоследних.ОрганВыдавшийОГРНИП КАК ОрганВыдавшийОГРНИП,
			|	РеквизитыФизическихЛицАнкетныеСрезПоследних.АдресРегистрации КАК АдресРегистрации,
			|	РеквизитыФизическихЛицАнкетныеСрезПоследних.АдресРегистрацииФИАС КАК АдресРегистрацииФИАС,
			|	РеквизитыФизическихЛицАнкетныеСрезПоследних.АдресМестаЖительства КАК АдресМестаЖительства,
			|	РеквизитыФизическихЛицАнкетныеСрезПоследних.АдресМестаЖительстваФИАС КАК АдресМестаЖительстваФИАС,
			|	РеквизитыФизическихЛицАнкетныеСрезПоследних.ПочтовыйАдрес КАК ПочтовыйАдрес,
			|	РеквизитыФизическихЛицАнкетныеСрезПоследних.ПочтовыйАдресФИАС КАК ПочтовыйАдресФИАС,
			|	РеквизитыФизическихЛицАнкетныеСрезПоследних.EMail КАК EMail,
			|	РеквизитыФизическихЛицАнкетныеСрезПоследних.Телефоны КАК Телефоны,
			|	РеквизитыФизическихЛицАнкетныеСрезПоследних.РезидентПо173ФЗ КАК РезидентПо173ФЗ,
			|	РеквизитыФизическихЛицАнкетныеСрезПоследних.Период КАК Период,
			|	РеквизитыФизическихЛицАнкетныеСрезПоследних.Регистратор.УпрощеннаяИдентификация КАК УпрощеннаяИдентификация
			|ИЗ
			|	РегистрСведений.РеквизитыФизическихЛицАнкетные.СрезПоследних(
			|			&Период,
			|			Организация = &Организация
			|				И Язык = ЗНАЧЕНИЕ(Справочник.Языки.Русский)
			|				И ЮрФизЛицо = &ЮрФизЛицо) КАК РеквизитыФизическихЛицАнкетныеСрезПоследних";
		
		Выборка = Запрос.Выполнить().Выбрать();
		
		Если Выборка.Следующий()
			И НЕ Выборка.УпрощеннаяИдентификация Тогда
			
			ТекстСообщения =
				"Обнаружены данные анкеты с упрощенной идентификацией.
				|Данные анкеты не будут записаны, т.к. существует анкета с полной идентификацией.";
			
			ОбщегоНазначенияКлиентСервер.СообщитьПользователю(ТекстСообщения);
			
			Результат =  Ложь;
			
		КонецЕсли;
		
	КонецЕсли;
	
	Возврат Результат;
	
КонецФункции

Функция ПрочитатьАнкетныеДанныеИзФайла(ОбъектXDTO, ВнешняяСистема)
	// Инициализация вспомогательных переменных
	Ошибки			= Новый Массив;	
	ГруппаОбъектов	= Справочники.ГруппыИмпортируемыхОбъектов.АнкетыФизическихЛиц;
	
	ИменаПолейАдреса = Новый Структура;	
	ИменаПолейАдреса.Вставить("Страна",				"Страна");	
	ИменаПолейАдреса.Вставить("Индекс",				"Индекс");	
	ИменаПолейАдреса.Вставить("Регион",				"Регион");
	ИменаПолейАдреса.Вставить("КодРегиона",			"КодРегиона");
	ИменаПолейАдреса.Вставить("Область",			"Область");	
	ИменаПолейАдреса.Вставить("НаселенныйПункт",	"НаселенныйПункт");	
	ИменаПолейАдреса.Вставить("Улица",				"Улица");
	ИменаПолейАдреса.Вставить("Дом",				"Дом");	
	ИменаПолейАдреса.Вставить("Корпус",				"Корпус");	
	ИменаПолейАдреса.Вставить("Строение",			"Строение");	
	ИменаПолейАдреса.Вставить("Квартира",			"Квартира");
	
	СвойстваОбъекта = ОбъектXDTO.Свойства();
	
	// АНКЕТА_ФИЗИЧЕСКОГО_ЛИЦА_БЕНЕФИЦИАРНОГО_ВЛАДЕЛЬЦА
	БенефициарныеВладельцы = Новый Массив;
	Если СвойстваОбъекта.Получить("АНКЕТА_ФИЗИЧЕСКОГО_ЛИЦА_БЕНЕФИЦИАРНОГО_ВЛАДЕЛЬЦА") <> Неопределено Тогда
		АнкетыБенефициарныхВладельцев = ОбъектXDTO.АНКЕТА_ФИЗИЧЕСКОГО_ЛИЦА_БЕНЕФИЦИАРНОГО_ВЛАДЕЛЬЦА;
		Если ТипЗнч(АнкетыБенефициарныхВладельцев) = Тип("ОбъектXDTO") Тогда
			АнкетыБенефициарныхВладельцев = Новый Массив;
			АнкетыБенефициарныхВладельцев.Добавить(ОбъектXDTO.АНКЕТА_ФИЗИЧЕСКОГО_ЛИЦА_БЕНЕФИЦИАРНОГО_ВЛАДЕЛЬЦА);
		КонецЕсли;
		
		Для Каждого АнкетаБенефициарногоВладельца Из АнкетыБенефициарныхВладельцев Цикл 
			Если АнкетаБенефициарногоВладельца.Свойства().Получить("ДатаОформленияАнкеты") <> Неопределено Тогда
				ЮрФизЛицоБенефициарногоВладельца = ПрочитатьАнкетныеДанныеИзФайла(АнкетаБенефициарногоВладельца, ВнешняяСистема); 
				Если Не ЗначениеЗаполнено(ЮрФизЛицоБенефициарногоВладельца) Тогда
					Продолжить;
				КонецЕсли;
				
				БенефициарныеВладельцы.Добавить(
					Новый Структура("ЮрФизЛицо", ЮрФизЛицоБенефициарногоВладельца)
				);   	
			КонецЕсли;
		КонецЦикла;
	КонецЕсли;
	
	// АНКЕТА_ФИЗИЧЕСКОГО_ЛИЦА_ВЫГОДОПРИОБРЕТАТЕЛЯ
	ФизЛицаВыгодоприобретатели = Новый Массив;
	Если СвойстваОбъекта.Получить("АНКЕТА_ФИЗИЧЕСКОГО_ЛИЦА_ВЫГОДОПРИОБРЕТАТЕЛЯ") <> Неопределено Тогда		
		АнкетыФизЛицВыгодоприобретателей = ОбъектXDTO.АНКЕТА_ФИЗИЧЕСКОГО_ЛИЦА_ВЫГОДОПРИОБРЕТАТЕЛЯ;
		Если ТипЗнч(АнкетыФизЛицВыгодоприобретателей) = Тип("ОбъектXDTO") Тогда
			АнкетыФизЛицВыгодоприобретателей = Новый Массив;
			АнкетыФизЛицВыгодоприобретателей.Добавить(ОбъектXDTO.АНКЕТА_ФИЗИЧЕСКОГО_ЛИЦА_ВЫГОДОПРИОБРЕТАТЕЛЯ);
		КонецЕсли;
		
		Для Каждого АнкетаФизЛицаВыгодоприобретателя Из АнкетыФизЛицВыгодоприобретателей Цикл 
			Если АнкетаФизЛицаВыгодоприобретателя.Свойства().Получить("ДатаОформленияАнкеты") <> Неопределено Тогда
				ЮрФизЛицоВыгодоприобретателя = ПрочитатьАнкетныеДанныеИзФайла(АнкетаФизЛицаВыгодоприобретателя, ВнешняяСистема); 
				Если Не ЗначениеЗаполнено(ЮрФизЛицоВыгодоприобретателя) Тогда
					Продолжить;
				КонецЕсли;
				
				ФизЛицаВыгодоприобретатели.Добавить(
					Новый Структура("ЮрФизЛицо", ЮрФизЛицоВыгодоприобретателя)
				);   	
			КонецЕсли;
		КонецЦикла;
	КонецЕсли;
	
	// АНКЕТА_ФИЗИЧЕСКОГО_ЛИЦА_ПРЕДСТАВИТЕЛЯ
	ФизЛицаПредставители = Новый Массив;
	Если СвойстваОбъекта.Получить("АНКЕТА_ФИЗИЧЕСКОГО_ЛИЦА_ПРЕДСТАВИТЕЛЯ") <> Неопределено Тогда
		АнкетыФизЛицПредставителей = ОбъектXDTO.АНКЕТА_ФИЗИЧЕСКОГО_ЛИЦА_ПРЕДСТАВИТЕЛЯ;
		Если ТипЗнч(АнкетыФизЛицПредставителей) = Тип("ОбъектXDTO") Тогда
			АнкетыФизЛицПредставителей = Новый Массив;
			АнкетыФизЛицПредставителей.Добавить(ОбъектXDTO.АНКЕТА_ФИЗИЧЕСКОГО_ЛИЦА_ПРЕДСТАВИТЕЛЯ);
		КонецЕсли;
		
		Для Каждого АнкетаФизЛицаПредставителя Из АнкетыФизЛицПредставителей Цикл 
			Если АнкетаФизЛицаПредставителя.Свойства().Получить("ДатаОформленияАнкеты") <> Неопределено Тогда
				ЮрФизЛицоПредставителя = ПрочитатьАнкетныеДанныеИзФайла(АнкетаФизЛицаПредставителя, ВнешняяСистема); 
				Если Не ЗначениеЗаполнено(ЮрФизЛицоПредставителя) Тогда
					Продолжить;
				КонецЕсли;
				
				ФизЛицаПредставители.Добавить(
					Новый Структура("ЮрФизЛицо, СтатусПредставителя, ОснованиеПолномочий",
						ЮрФизЛицоПредставителя,
						Неопределено,
						АнкетаФизЛицаПредставителя.ДокументПодтверждающийПолномочия
					)
				);   	
			КонецЕсли;
		КонецЦикла;
	КонецЕсли;	
	
	// АНКЕТА_ЮРИДИЧЕСКОГО_ЛИЦА_ВЫГОДОПРИОБРЕТАТЕЛЯ
	ЮрЛицоВыгодоприобретатель = Неопределено;
	Если СвойстваОбъекта.Получить("АНКЕТА_ЮРИДИЧЕСКОГО_ЛИЦА_ВЫГОДОПРИОБРЕТАТЕЛЯ") <> Неопределено Тогда
		// Загрузка анкет юридических лиц не реализована. Анкета ""АНКЕТА_ЮРИДИЧЕСКОГО_ЛИЦА_ВЫГОДОПРИОБРЕТАТЕЛЯ"" загружена не будет!"
	КонецЕсли;
	
	// АНКЕТА_ЮРИДИЧЕСКОГО_ЛИЦА_ПРЕДСТАВИТЕЛЯ
	ЮрЛицоПредставитель = Неопределено;
	Если СвойстваОбъекта.Получить("АНКЕТА_ЮРИДИЧЕСКОГО_ЛИЦА_ПРЕДСТАВИТЕЛЯ") <> Неопределено Тогда
		// Загрузка анкет юридических лиц не реализована. Анкета ""АНКЕТА_ЮРИДИЧЕСКОГО_ЛИЦА_ПРЕДСТАВИТЕЛЯ"" загружена не будет!"
	КонецЕсли;	
	
	// ЗАЯВЛЕНИЕ_О_ПРИСОЕДИНЕНИИ
	ЗаявлениеОПрисоединении = Неопределено; 	
	Если СвойстваОбъекта.Получить("ЗАЯВЛЕНИЕ_О_ПРИСОЕДИНЕНИИ") <> Неопределено Тогда
		ЗаявлениеОПрисоединении	= ОбъектXDTO.ЗАЯВЛЕНИЕ_О_ПРИСОЕДИНЕНИИ;	
	КонецЕсли;	
	
	// Анкета физ. лица
	Если СвойстваОбъекта.Получить("АНКЕТА_ФИЗИЧЕСКОГО_ЛИЦА") <> Неопределено Тогда
		ДанныеАнкеты = ОбъектXDTO.АНКЕТА_ФИЗИЧЕСКОГО_ЛИЦА;
	Иначе
		ДанныеАнкеты = ОбъектXDTO;
	КонецЕсли;
	СвойстваАнкеты = ДанныеАнкеты.Свойства();
	
	// ФИО
	Если СвойстваАнкеты.Получить("ФИО") <> Неопределено Тогда
		ДанныеФИО = ДанныеАнкеты.ФИО;			
	ИначеЕсли СвойстваАнкеты.Получить("ФИОБенефициарныйВладелец") <> Неопределено Тогда
		ДанныеФИО = ДанныеАнкеты.ФИОБенефициарныйВладелец;			
	Иначе
		ВызватьИсключение "Данные о ФИО физического лица не обнаружены!";
	КонецЕсли;
	
	// Представление юр./физ. лица
	Фамилия  = ТРег(ПолучитьЗначениеТипа(Тип("Строка"), ДанныеФИО.Фамилия));
	Имя      = ТРег(ПолучитьЗначениеТипа(Тип("Строка"), ДанныеФИО.Имя));
	Отчество = ТРег(ПолучитьЗначениеТипа(Тип("Строка"), ДанныеФИО.Отчество));
	
	НаименованиеЮрФизЛицаАнкеты = Фамилия
		+ ?(ЗначениеЗаполнено(Имя), " " + Имя, "")
		+ ?(ЗначениеЗаполнено(Отчество), " " + Отчество, "");			
	
	// Получаем и заполняем анкету
	АнкетаФизическогоЛица	= Неопределено;
	
	// Анкету ищем по коду "[ID] от [Дата анкеты]", где
	// ID - "[Серия паспорта] [Номер паспорта]"
	ДокументУЛ					= ДанныеАнкеты.ДокументУдостоверяющийЛичность;	
	СерияУдостоверенияЛичности	= ПолучитьЗначениеТипа(Тип("Строка"), ДокументУЛ.Серия, Истина);
	НомерУдостоверенияЛичности	= ПолучитьЗначениеТипа(Тип("Строка"), ДокументУЛ.Номер, Истина);
	ИдентификаторЛица			= СерияУдостоверенияЛичности + " " + НомерУдостоверенияЛичности;	
	
	Если ПустаяСтрока(ИдентификаторЛица) Тогда
		Сообщить("Идентификатор анкеты '" + НаименованиеЮрФизЛицаАнкеты + "' не определен. Загрузка анкеты выполнена не будет.");
		Возврат Неопределено;
	КонецЕсли;
	
	ДатаОформленияАнкеты	= ПолучитьЗначениеТипа(Тип("Дата"), ДанныеАнкеты.ДатаОформленияАнкеты);
	КодВнешнейСистемы		= ИдентификаторЛица + " от " + Формат(ДатаОформленияАнкеты, "ДФ=dd.MM.yyyy");
	АнкетаФизическогоЛица	= НайтиЗначениеПоКодуВнешнейСистемы(ВнешняяСистема, ГруппаОбъектов, КодВнешнейСистемы);
	
	Если АнкетаФизическогоЛица <> Неопределено Тогда
		ДокументОбъект = АнкетаФизическогоЛица.ПолучитьОбъект();
		ЭтоНоваяАнкета = Ложь;
	Иначе
		ДокументОбъект = Документы.АнкетаФизическогоЛица.СоздатьДокумент();	
		ДокументОбъект.Заполнить(Неопределено);
		ЭтоНоваяАнкета = Истина;
	КонецЕсли;
	
	// Метод идентификации		
	УпрощеннаяИдентификация = Ложь;	
	Если СвойстваОбъекта.Получить("МетодИдентификации") <> Неопределено Тогда
		УпрощеннаяИдентификация = (ВРег(ПолучитьЗначениеТипа(Тип("Строка"), ОбъектXDTO.МетодИдентификации)) = "УПРОЩЕННАЯ");			
	КонецЕсли;
	
	// Общее
	ДокументОбъект.ПометкаУдаления				= Ложь;
	ДокументОбъект.ВидИсточника				= Перечисления.ИсточникиАнкетИЗаявок.Агент;
	ДокументОбъект.УпрощеннаяИдентификация		= УпрощеннаяИдентификация;
	
	ДокументОбъект.Дата							= ПолучитьЗначениеТипа(Тип("Дата"), ДанныеАнкеты.ДатаОформленияАнкеты);
	
	// ФИО
	ДокументОбъект.Фамилия  = Фамилия;
	ДокументОбъект.Имя      = Имя;
	ДокументОбъект.Отчество = Отчество;
	
	// Дата и место рождения
	ДокументОбъект.ДатаРождения  = ПолучитьЗначениеТипа(Тип("Дата"), ДанныеАнкеты.ДатаРождения);
	ДокументОбъект.МестоРождения = ПолучитьЗначениеТипа(Тип("Строка"), ДанныеАнкеты.МестоРождения);
	
	// ИНН
	ДокументОбъект.ИНН = ПолучитьЗначениеТипа(Тип("Строка"), ДанныеАнкеты.ИНН);
	
	// СНИЛС
	Если СвойстваАнкеты.Получить("СНИЛС") <> Неопределено Тогда
		ДокументОбъект.СНИЛС = ПолучитьЗначениеТипа(Тип("Строка"), ДанныеАнкеты.СНИЛС);
	КонецЕсли;
	
	// ОГРНИП 
	Если СвойстваАнкеты.Получить("ОГРНИП") <> Неопределено Тогда
		ДанныеОГРНИП								= ДанныеАнкеты.ОГРНИП;
		ДокументОбъект.ОГРНИП						= ПолучитьЗначениеТипа(Тип("Строка"), ДанныеОГРНИП.Номер);
		ДокументОбъект.ДатаВыдачиОГРНИП				= ПолучитьЗначениеТипа(Тип("Дата"), ДанныеОГРНИП.ДатаРегистрации);
		ДокументОбъект.ОрганВыдавшийОГРНИП			= ПолучитьЗначениеТипа(Тип("Строка"), ДанныеОГРНИП.НаименованиеОргана);
		ДокументОбъект.АдресОрганаВыдавшегоОГРНИП	= ПолучитьЗначениеТипа(Тип("Строка"), ДанныеОГРНИП.АдресОргана);
	КонецЕсли;		
	
	// Виды деятельности	
	Если СвойстваАнкеты.Получить("ВидДеятельности") <> Неопределено Тогда
		ДокументОбъект.ВидыДеятельности	= ПолучитьЗначениеТипа(Тип("Строка"), ДанныеАнкеты.ВидДеятельности);
	КонецЕсли;
	
	// Лицензии
	Если СвойстваАнкеты.Получить("СведенияОЛицензиях") <> Неопределено Тогда
		ДокументОбъект.Лицензии = "";
		
		// Т.к. лицензий может и не быть
		Если ДанныеАнкеты.СведенияОЛицензиях.Свойства().Получить("Лицензия") <> Неопределено Тогда  
			ДанныеОЛицензиях = ДанныеАнкеты.СведенияОЛицензиях.Лицензия;
			Если ТипЗнч(ДанныеОЛицензиях) = Тип("ОбъектXDTO") Тогда
				ДанныеОЛицензиях = Новый Массив;
				ДанныеОЛицензиях.Добавить(ДанныеАнкеты.СведенияОЛицензиях.Лицензия);
			КонецЕсли;
			
			Для Каждого ДанныеЛицензии Из ДанныеОЛицензиях Цикл
				ДокументОбъект.Лицензии = ДокументОбъект.Лицензии + ПолучитьЗначениеТипа(Тип("Строка"), ДанныеЛицензии) + "; ";
			КонецЦикла;
			
			ДокументОбъект.Лицензии = Лев(ДокументОбъект.Лицензии, СтрДлина(ДокументОбъект.Лицензии) - 2);
		КонецЕсли;		
	КонецЕсли;
	
	// Публичное должностное лицо	
	Если СвойстваАнкеты.Получить("ИПДЛ") <> Неопределено Тогда
		ДанныеИПДЛ = ДанныеАнкеты.ИПДЛ;	
		ДокументОбъект.ЯвляетсяПубличнымДолжностнымЛицом			= (ПолучитьЗначениеТипа(Тип("Строка"), ДанныеИПДЛ.Ответ) = "Да");
		ДокументОбъект.ЯвляетсяПубличнымДолжностнымЛицомОписание	= СериализаторXDTO.ПрочитатьXDTO(ДанныеИПДЛ);	 	
	КонецЕсли;
	
	Если Не ДокументОбъект.ЯвляетсяПубличнымДолжностнымЛицом Тогда
		Если СвойстваАнкеты.Получить("ДолжностноеЛицоПубличнойМеждународнойОрганизации") <> Неопределено Тогда
			ДанныеДЛПМО = ДанныеАнкеты.ДолжностноеЛицоПубличнойМеждународнойОрганизации;	
			ДокументОбъект.ЯвляетсяПубличнымДолжностнымЛицом			= (ПолучитьЗначениеТипа(Тип("Строка"), ДанныеДЛПМО.Ответ) = "Да");
			ДокументОбъект.ЯвляетсяПубличнымДолжностнымЛицомОписание	= СериализаторXDTO.ПрочитатьXDTO(ДанныеДЛПМО);	 	
		КонецЕсли;
	КонецЕсли;
	
	// Родственники публичного должностного лица
	Если СвойстваАнкеты.Получить("РодственныеСвязиИПДЛ") <> Неопределено Тогда
		ДанныеРодственныеСвязиИПДЛ = ДанныеАнкеты.РодственныеСвязиИПДЛ;	
		ДокументОбъект.ЯвляетсяРодственникомПубличногоДолжностногоЛица			= (ПолучитьЗначениеТипа(Тип("Строка"), ДанныеРодственныеСвязиИПДЛ.Ответ) = "Да");
		ДокументОбъект.ЯвляетсяРодственникомПубличногоДолжностногоЛицаОписание	= СериализаторXDTO.ПрочитатьXDTO(ДанныеРодственныеСвязиИПДЛ);	 	
	КонецЕсли;	
	
	// ФАТФ
	Если СвойстваАнкеты.Получить("ФАТФ") <> Неопределено Тогда
		ДанныеФАТФ = ДанныеАнкеты.ФАТФ;	
		ДокументОбъект.НаличиеСчетаВГосударствахНеВыполняющихРекомендацииФАТФ			= (ПолучитьЗначениеТипа(Тип("Строка"), ДанныеФАТФ.Ответ) = "Да");
		ДокументОбъект.НаличиеСчетаВГосударствахНеВыполняющихРекомендацииФАТФОписание	= СериализаторXDTO.ПрочитатьXDTO(ДанныеФАТФ);	 	
	КонецЕсли;
	
	// Цели отношений УК
	Если СвойстваАнкеты.Получить("ОтношенияУК") <> Неопределено Тогда
		ЦельОтношений = ДанныеАнкеты.ОтношенияУК.ЦельОтношений;
		
		ДокументОбъект.ЦельПриобретениеПаев			= (ЦельОтношений = "Приобретение паев паевого инвестиционного фонда под управлением УК");
		ДокументОбъект.ЦельДоверительноеУправление	= (ЦельОтношений = "Доверительное управление ценными бумагами");
		ДокументОбъект.ЦельДругое					= (ЦельОтношений = "Другое");
		
		Если ДокументОбъект.ЦельДругое И ДанныеАнкеты.ОтношенияУК.Свойства().Получить("ДругиеЦели")<>Неопределено Тогда
			ДокументОбъект.ЦельДругоеОписание = ПолучитьЗначениеТипа(Тип("Строка"), ДанныеАнкеты.ОтношенияУК.ДругиеЦели);	
		КонецЕсли;
	КонецЕсли;
	
	// Цели ФХД
	Если СвойстваАнкеты.Получить("ЦелиХозяйственнойДеятельности") <> Неопределено Тогда
		ДокументОбъект.ЦелиДеятельности	= ПолучитьЗначениеТипа(Тип("Строка"), ДанныеАнкеты.ЦелиХозяйственнойДеятельности);
	Иначе
		ДокументОбъект.ЦелиДеятельности	= Неопределено;	
	КонецЕсли;	
	
	// Финансовое положение
	Если СвойстваАнкеты.Получить("ФинансовоеПоложение") <> Неопределено Тогда
		ДокументОбъект.ПоложительноеФинансовоеПоложение = (ПолучитьЗначениеТипа(Тип("Строка"), ДанныеАнкеты.ФинансовоеПоложение) = "Положительное"); 	
	КонецЕсли;	
	
	// Деловая репутация
	Если СвойстваАнкеты.Получить("ДеловаяРепутация") <> Неопределено Тогда
		ДокументОбъект.ДеловаяРепутацияПоложительная = (ПолучитьЗначениеТипа(Тип("Строка"), ДанныеАнкеты.ДеловаяРепутация.ТипДР) = "Деловая репутация положительная");
		
		Если Не ДокументОбъект.ДеловаяРепутацияПоложительная И ДанныеАнкеты.ДеловаяРепутация.Свойства().Получить("ДругойСтатусДР")<>Неопределено Тогда
			ДокументОбъект.ДеловаяРепутацияОписание = ПолучитьЗначениеТипа(Тип("Строка"), ДанныеАнкеты.ДеловаяРепутация.ДругойСтатусДР);		
		КонецЕсли;
	КонецЕсли;
	
	// Источники происхождения д/с
	Если СвойстваАнкеты.Получить("ИсточникАктивов") <> Неопределено Тогда
		ДокументОбъект.ИсточникиПроисхожденияДенежныхСредств = ПолучитьЗначениеТипа(Тип("Строка"), ДанныеАнкеты.ИсточникАктивов);
	Иначе
		ДокументОбъект.ИсточникиПроисхожденияДенежныхСредств = Неопределено;	
	КонецЕсли;
	
	// Гражданство
	КодГражданства = ПолучитьЗначениеТипа(Тип("Строка"), ДанныеАнкеты.Гражданство);
	ДокументОбъект.Гражданство = Справочники.СтраныМира.НайтиПоРеквизиту("КодАльфа2", КодГражданства);
	
	// Документ, удостоверяющий личность
	ВидДокументаУЛ = ПолучитьЗначениеТипа(Тип("Строка"), ДокументУЛ.ТипДокумента);	
	
	ВидУдостоверенияЛичности = Справочники.ВидыДокументовФизическихЛиц.НайтиПоНаименованию(ВидДокументаУЛ, Истина);	
	Если Не ЗначениеЗаполнено(ВидУдостоверенияЛичности) Тогда
		Сообщить("Некорректный вид документа '" + ВидДокументаУЛ + "' для '" + НаименованиеЮрФизЛицаАнкеты + "'. Загрузка анкеты выполнена не будет.");
		Возврат Неопределено;	
	КонецЕсли;
	
	ДокументОбъект.ВидУдостоверенияЛичности					= ВидУдостоверенияЛичности;
	ДокументОбъект.СерияУдостоверенияЛичности				= СерияУдостоверенияЛичности;
	ДокументОбъект.НомерУдостоверенияЛичности				= НомерУдостоверенияЛичности;
	ДокументОбъект.ДатаВыдачиУдостоверенияЛичности			= ПолучитьЗначениеТипа(Тип("Дата"),   ДокументУЛ.ДатаВыдачи);
	ДокументОбъект.ОрганВыдавшийУдостоверениеЛичности		= ПолучитьЗначениеТипа(Тип("Строка"), ДокументУЛ.КемВыдан);
	ДокументОбъект.КодОрганаВыдавшегоУдостоверениеЛичности	= ПолучитьЗначениеТипа(Тип("Строка"), ДокументУЛ.КодПодразделения);
	
	ДокументОбъект.МиграционнаяКарта			= ПолучитьЗначениеТипа(Тип("Строка"), ДанныеАнкеты.МиграционнаяКарта);
	ДокументОбъект.ДокументПраваНаходитьсяВРФ	= ПолучитьЗначениеТипа(Тип("Строка"), ДанныеАнкеты.ДокументПодтверждающийПравоПроживанияИнстрГраждРФ);
	
	Если Не ЗначениеЗаполнено(ДокументОбъект.СтатусПроверки) Тогда
		ДокументОбъект.СтатусПроверки = Перечисления.СтатусыПроверкиУдостоверенияЛичности.НеПроверен;	
	КонецЕсли;
	
	// Контактная информация
	КонтактнаяИнформация = ДанныеАнкеты.КонтактнаяИнформация;
	
	ДокументОбъект.Телефоны				= ПолучитьЗначениеТипа(Тип("Строка"), КонтактнаяИнформация.Телефоны);
	ДокументОбъект.ТелефонДляОповещения = ПолучитьЗначениеТипа(Тип("Строка"), КонтактнаяИнформация.Телефоны);
	
	ДокументОбъект.EMail    = ПолучитьЗначениеТипа(Тип("Строка"), КонтактнаяИнформация.ЭлПочта);
	
	Если СвойстваАнкеты.Получить("АдресМестоЖительства") <> Неопределено Тогда
		
		ДокументОбъект.АдресМестаЖительства     = ПрочитатьАдрес(ДанныеАнкеты.АдресМестоЖительства, ИменаПолейАдреса);
		ДокументОбъект.АдресМестаЖительстваФИАС = ПрочитатьАдресФИАС(ДанныеАнкеты.АдресМестоЖительства, ИменаПолейАдреса);
		
		ДокументОбъект.АдресРегистрации     = ДокументОбъект.АдресМестаЖительства;
		ДокументОбъект.АдресРегистрацииФИАС = ДокументОбъект.АдресМестаЖительстваФИАС;
		
	КонецЕсли;
		
	// ЗАЯВЛЕНИЕ_О_ПРИСОЕДИНЕНИИ
	Если ЗаявлениеОПрисоединении <> Неопределено Тогда
		СвойстваЗаявления = ЗаявлениеОПрисоединении.Свойства();
		
		// При упрощенной идентификации при необходимости часть данных подтягиваем из анкеты о присоединении
		Если УпрощеннаяИдентификация Тогда
			// Паспортные данные
			Если СвойстваЗаявления.Получить("ДокументУдостоверяющийЛичность") <> Неопределено Тогда
				ДокументУЛЗаявления = ЗаявлениеОПрисоединении.ДокументУдостоверяющийЛичность;
				Если Не ЗначениеЗаполнено(ДокументОбъект.ДатаВыдачиУдостоверенияЛичности) Тогда
					ДокументОбъект.ДатаВыдачиУдостоверенияЛичности = ПолучитьЗначениеТипа(Тип("Дата"), ДокументУЛЗаявления.ДатаВыдачи);
				КонецЕсли;
				Если Не ЗначениеЗаполнено(ДокументОбъект.ОрганВыдавшийУдостоверениеЛичности) Тогда
					ДокументОбъект.ОрганВыдавшийУдостоверениеЛичности = ПолучитьЗначениеТипа(Тип("Строка"), ДокументУЛЗаявления.КемВыдан);
				КонецЕсли;
				Если Не ЗначениеЗаполнено(ДокументОбъект.КодОрганаВыдавшегоУдостоверениеЛичности) Тогда
					ДокументОбъект.КодОрганаВыдавшегоУдостоверениеЛичности = ПолучитьЗначениеТипа(Тип("Строка"), ДокументУЛЗаявления.КодПодразделения);
				КонецЕсли;
			КонецЕсли;
			
			// Электронная почта
			Если СвойстваЗаявления.Получить("ЭлПочтаДляПредоставленияДокументов") <> Неопределено Тогда
				Если Не ЗначениеЗаполнено(ДокументОбъект.EMail) Тогда
					ДокументОбъект.EMail = ПолучитьЗначениеТипа(Тип("Строка"), ЗаявлениеОПрисоединении.ЭлПочтаДляПредоставленияДокументов);
				КонецЕсли;
			КонецЕсли;
			
			// Адрес места жительства
			Если СвойстваЗаявления.Получить("АдресМестоЖительства") <> Неопределено Тогда
				Если Не ЗначениеЗаполнено(ДокументОбъект.АдресМестаЖительства) Тогда
					ДокументОбъект.АдресМестаЖительства     = ПрочитатьАдрес(ЗаявлениеОПрисоединении.АдресМестоЖительства, ИменаПолейАдреса);
					ДокументОбъект.АдресМестаЖительстваФИАС = ПрочитатьАдресФИАС(ЗаявлениеОПрисоединении.АдресМестоЖительства, ИменаПолейАдреса);
					
					ДокументОбъект.АдресРегистрации     = ДокументОбъект.АдресМестаЖительства;
					ДокументОбъект.АдресРегистрацииФИАС = ДокументОбъект.АдресМестаЖительстваФИАС;
				КонецЕсли;
			КонецЕсли;
		КонецЕсли;
			
		// Сверка данных в анкете физического лица и заявлении о присоединении
		ОшибкиСверки = Новый Массив;
		
		Если СвойстваЗаявления.Получить("ФИО") <> Неопределено Тогда
			ДанныеФИОЗаявления = ЗаявлениеОПрисоединении.ФИО;
			Если ДанныеФИО.Фамилия <> ДанныеФИОЗаявления.Фамилия Тогда
				ОшибкиСверки.Добавить("'Фамилия'");
			КонецЕсли;
			Если ДанныеФИО.Имя <> ДанныеФИОЗаявления.Имя Тогда
				ОшибкиСверки.Добавить("'Имя'");
			КонецЕсли;
			Если ПолучитьЗначениеТипа(Тип("Строка"), ДанныеФИО.Отчество) <> ПолучитьЗначениеТипа(Тип("Строка"), ДанныеФИОЗаявления.Отчество) Тогда
				ОшибкиСверки.Добавить("'Отчество'");
			КонецЕсли;
		КонецЕсли;
		
		Если ДокументОбъект.ДатаРождения <> ПолучитьЗначениеТипа(Тип("Дата"), ЗаявлениеОПрисоединении.ДатаРождения) Тогда
			ОшибкиСверки.Добавить("'Дата рождения'");
		КонецЕсли;
		
		Если СвойстваЗаявления.Получить("ДокументУдостоверяющийЛичность") <> Неопределено Тогда
			ДокументУЛЗаявления = ЗаявлениеОПрисоединении.ДокументУдостоверяющийЛичность;
			Если ДокументОбъект.СерияУдостоверенияЛичности <> ПолучитьЗначениеТипа(Тип("Строка"), ДокументУЛЗаявления.Серия, Истина) Тогда
				ОшибкиСверки.Добавить("'Серия документа, удостоверяющего личность'");
			КонецЕсли;
			Если ДокументОбъект.НомерУдостоверенияЛичности <> ПолучитьЗначениеТипа(Тип("Строка"), ДокументУЛЗаявления.Номер, Истина) Тогда
				ОшибкиСверки.Добавить("'Номер документа, удостоверяющего личность'");
			КонецЕсли;
			Если ЗначениеЗаполнено(ДокументОбъект.ДатаВыдачиУдостоверенияЛичности) И ДокументОбъект.ДатаВыдачиУдостоверенияЛичности <> ПолучитьЗначениеТипа(Тип("Дата"), ДокументУЛЗаявления.ДатаВыдачи) Тогда
				ОшибкиСверки.Добавить("'Дата выдачи документа, удостоверяющего личность'");
			КонецЕсли;
			Если ЗначениеЗаполнено(ДокументОбъект.ОрганВыдавшийУдостоверениеЛичности) И ДокументОбъект.ОрганВыдавшийУдостоверениеЛичности <> ПолучитьЗначениеТипа(Тип("Строка"), ДокументУЛЗаявления.КемВыдан) Тогда
				ОшибкиСверки.Добавить("'Орган, выдавший документ, удостоверяющий личность'");
			КонецЕсли;
			Если ЗначениеЗаполнено(ДокументОбъект.КодОрганаВыдавшегоУдостоверениеЛичности) И ДокументОбъект.КодОрганаВыдавшегоУдостоверениеЛичности <> ПолучитьЗначениеТипа(Тип("Строка"), ДокументУЛЗаявления.КодПодразделения) Тогда
				ОшибкиСверки.Добавить("'Код органа, выдавшего документ, удостоверяющий личность'");
			КонецЕсли;			
		КонецЕсли;
		
		Если СвойстваЗаявления.Получить("ЭлПочтаДляПредоставленияДокументов") <> Неопределено Тогда
			Если ДокументОбъект.EMail <> ПолучитьЗначениеТипа(Тип("Строка"), ЗаявлениеОПрисоединении.ЭлПочтаДляПредоставленияДокументов) Тогда
				ОшибкиСверки.Добавить("'Адрес электронной почты'");
			КонецЕсли;
		КонецЕсли;
		
		Если СвойстваЗаявления.Получить("АдресМестоЖительства") <> Неопределено Тогда
			Если ДокументОбъект.АдресМестаЖительства <> ПрочитатьАдрес(ЗаявлениеОПрисоединении.АдресМестоЖительства, ИменаПолейАдреса) Тогда
				ОшибкиСверки.Добавить("'Адрес места жительства'");
			КонецЕсли;
		КонецЕсли;
		
		Если СвойстваЗаявления.Получить("Гражданство") <> Неопределено Тогда
			КодГражданстваИзЗаявления = ПолучитьЗначениеТипа(Тип("Строка"), ЗаявлениеОПрисоединении.Гражданство);
			ГражданствоИзЗаявления = Справочники.СтраныМира.НайтиПоРеквизиту("КодАльфа2", КодГражданстваИзЗаявления);
			
			Если НЕ ЗначениеЗаполнено(ДокументОбъект.Гражданство) Тогда
				ДокументОбъект.Гражданство = ГражданствоИзЗаявления;
			ИначеЕсли ДокументОбъект.Гражданство <> ГражданствоИзЗаявления Тогда
				ОшибкиСверки.Добавить("'Гражданство'");
			КонецЕсли;
		КонецЕсли;
		
		Если ОшибкиСверки.Количество() Тогда
			ВызватьИсключение "Значения реквизитов " + СтрСоединить(ОшибкиСверки, ", ")+ ", указанные в анкете и в заявлении о присоединении '" + НаименованиеЮрФизЛицаАнкеты + "', различаются!";
		КонецЕсли;
		
		// Мобильный телефон
		Если СвойстваЗаявления.Получить("МобильныйТелефон") <> Неопределено Тогда
			МобильныйТелефон = ПолучитьЗначениеТипа(Тип("Строка"), ЗаявлениеОПрисоединении.МобильныйТелефон);
			Если Не ПустаяСтрока(МобильныйТелефон) Тогда
				ДокументОбъект.ТелефонДляОповещения = МобильныйТелефон;
				Если СтрНайти(НРег(ДокументОбъект.Телефоны), НРег(МобильныйТелефон)) = 0 Тогда	
					ДокументОбъект.Телефоны = ?(ПустаяСтрока(ДокументОбъект.Телефоны), "", ДокументОбъект.Телефоны + "; ") + МобильныйТелефон; 	
				КонецЕсли;
			КонецЕсли;
		КонецЕсли;
		
		// Электронная почта
		Если СвойстваЗаявления.Получить("ЭлПочтаДляПредоставленияДокументов") <> Неопределено Тогда
			ЭлектроннаяПочта = ПолучитьЗначениеТипа(Тип("Строка"), ЗаявлениеОПрисоединении.ЭлПочтаДляПредоставленияДокументов);
			Если Не ПустаяСтрока(ЭлектроннаяПочта)
				И СтрНайти(НРег(ДокументОбъект.EMail), НРег(ЭлектроннаяПочта)) = 0	
			Тогда
				ДокументОбъект.EMail = ?(ПустаяСтрока(ДокументОбъект.EMail), "", ДокументОбъект.EMail + "; ") + ЭлектроннаяПочта; 	
			КонецЕсли;
		КонецЕсли;
		
		// Адреса
		Если ЗаявлениеОПрисоединении.Свойства().Получить("АдресПочтовый") <> Неопределено Тогда
			ДокументОбъект.ПочтовыйАдрес        = ПрочитатьАдрес(ЗаявлениеОПрисоединении.АдресПочтовый, ИменаПолейАдреса);
			ДокументОбъект.ПочтовыйАдресФИАС	= ПрочитатьАдресФИАС(ЗаявлениеОПрисоединении.АдресПочтовый, ИменаПолейАдреса);
		Иначе
			ОбщегоНазначенияКлиентСервер.СообщитьПользователю("В анкете клиента '" + НаименованиеЮрФизЛицаАнкеты + "' не указан почтовый адрес! Загрузка анкеты не будет произведена.");
			Возврат Неопределено;
		КонецЕсли;
		
		Если СвойстваЗаявления.Получить("АдресФактическогоПроживанияВИностранномГосударстве") <> Неопределено Тогда
			Если ЗаявлениеОПрисоединении.АдресФактическогоПроживанияВИностранномГосударстве.Ответ = "Да" Тогда
				ДокументОбъект.АдресФактическогоПроживанияВИностранномГосударстве = ПрочитатьАдрес(ЗаявлениеОПрисоединении.АдресФактическогоПроживанияВИностранномГосударстве, ИменаПолейАдреса);
			КонецЕсли;
		КонецЕсли;
		
		Если СвойстваЗаявления.Получить("АдресПочтовыйВИностранномГосударстве") <> Неопределено Тогда
			Если ЗаявлениеОПрисоединении.АдресПочтовыйВИностранномГосударстве.Ответ = "Да" Тогда
				ДокументОбъект.АдресПочтовыйВИностранномГосударстве = ПрочитатьАдрес(ЗаявлениеОПрисоединении.АдресПочтовыйВИностранномГосударстве, ИменаПолейАдреса);
			КонецЕсли;
		КонецЕсли;
		
		Если СвойстваЗаявления.Получить("АдресДоВостребованияВИностранномГосударстве") <> Неопределено Тогда
			Если ЗаявлениеОПрисоединении.АдресДоВостребованияВИностранномГосударстве.Ответ = "Да" Тогда
				ДокументОбъект.АдресДоВостребованияВИностранномГосударстве = ПрочитатьАдрес(ЗаявлениеОПрисоединении.АдресДоВостребованияВИностранномГосударстве, ИменаПолейАдреса);
			КонецЕсли;
		КонецЕсли;
		
		ДокументОбъект.РезидентРФ = (ПолучитьЗначениеТипа(Тип("Строка"), ЗаявлениеОПрисоединении.РезидентРФ) = "Да");
		
		Если СвойстваЗаявления.Получить("НалоговоеРезидентствоИГ") <> Неопределено Тогда
			ДанныеРезидентстваИГ = ЗаявлениеОПрисоединении.НалоговоеРезидентствоИГ;
			
			ДокументОбъект.НалоговыйРезидентИностранногоГосударства = (ПолучитьЗначениеТипа(Тип("Строка"), ДанныеРезидентстваИГ.Ответ) = "Да");
			
			Если ДокументОбъект.НалоговыйРезидентИностранногоГосударства И ДокументОбъект.РезидентРФ Тогда
				ВызватьИсключение "В анкете указано, что физ.лицо резидент РФ и налоговый резидент иностранного государства!";
			КонецЕсли;
			
			Если ДокументОбъект.НалоговыйРезидентИностранногоГосударства Тогда
				ДокументОбъект.НалоговыйРезидентИностранногоГосударстваГосударство =
							Справочники.СтраныМира.НайтиПоРеквизиту("КодАльфа2", ПолучитьЗначениеТипа(Тип("Строка"), ДанныеРезидентстваИГ.Государство));
			КонецЕсли;
			
		КонецЕсли;
		
		Если СвойстваЗаявления.Получить("ИныеОснованияИН") <> Неопределено Тогда
			ДанныеИностранныйНалогоплательщик = ЗаявлениеОПрисоединении.ИныеОснованияИН;
			
			ДокументОбъект.ИностранныйНалогоплательщик = (ПолучитьЗначениеТипа(Тип("Строка"), ДанныеИностранныйНалогоплательщик.Ответ) = "Да");
			
			Если ДокументОбъект.ИностранныйНалогоплательщик Тогда
				ДокументОбъект.ИностранныйНалогоплательщикГосударство =
								Справочники.СтраныМира.НайтиПоРеквизиту("КодАльфа2", ПолучитьЗначениеТипа(Тип("Строка"), ДанныеИностранныйНалогоплательщик.Государство));
				ДокументОбъект.ИностранныйНалогоплательщикОснования = ПолучитьЗначениеТипа(Тип("Строка"), ДанныеИностранныйНалогоплательщик.Основания);
			КонецЕсли;
		КонецЕсли;
		
		Если СвойстваЗаявления.Получить("Резидент173ФЗ") <> Неопределено Тогда
			ДокументОбъект.РезидентПо173ФЗ = (ПолучитьЗначениеТипа(Тип("Строка"), ЗаявлениеОПрисоединении.Резидент173ФЗ) = "Да");
		КонецЕсли;
		
		Если СвойстваЗаявления.Получить("ЗаконодательствоСША") <> Неопределено Тогда
			ДокументОбъект.РаспространениеЗаконодательстваСША = (ПолучитьЗначениеТипа(Тип("Строка"), ЗаявлениеОПрисоединении.ЗаконодательствоСША) = "Да");
		КонецЕсли;
		
		Если СвойстваЗаявления.Получить("СогласиеНаПередачуИнформации") <> Неопределено Тогда
			ДокументОбъект.СогласиеНаПередачуИнформации = (ПолучитьЗначениеТипа(Тип("Строка"), ЗаявлениеОПрисоединении.СогласиеНаПередачуИнформации) = "Да");
		КонецЕсли;
		
		НомерБанковскогоСчета = ПолучитьЗначениеТипа(Тип("Строка"), ЗаявлениеОПрисоединении.БанкСчет.РасчетныйСчет);
		Если Не ПустаяСтрока(НомерБанковскогоСчета) Тогда
			Если ДокументОбъект.БанковскиеРеквизиты.Количество() Тогда
				СтрокаТабЧасти = ДокументОбъект.БанковскиеРеквизиты[0];
			Иначе
				СтрокаТабЧасти = ДокументОбъект.БанковскиеРеквизиты.Добавить();
			КонецЕсли;
			СтрокаТабЧасти.БИК               = ПолучитьЗначениеТипа(Тип("Строка"), ЗаявлениеОПрисоединении.БанкСчет.БИК);
			СтрокаТабЧасти.НаименованиеБанка = ПолучитьЗначениеТипа(Тип("Строка"), ЗаявлениеОПрисоединении.БанкСчет.ИмяБанка);
			СтрокаТабЧасти.КоррСчет          = ПолучитьЗначениеТипа(Тип("Строка"), ЗаявлениеОПрисоединении.БанкСчет.КорСчет);
			СтрокаТабЧасти.НомерСчета        = НомерБанковскогоСчета;
			СтрокаТабЧасти.ПолучательПлатежа = ДокументОбъект.Фамилия + " " + ДокументОбъект.Имя + ?(ПустаяСтрока(ДокументОбъект.Отчество), "", " " + ДокументОбъект.Отчество);
		КонецЕсли;
		
		// Способ место получения отчетности
		Если СвойстваЗаявления.Получить("СпособМестоПолученияОтчетности") <> Неопределено Тогда
			ДокументОбъект.СпособМестоПолученияОтчетности = ПолучитьЗначениеТипа(Тип("Строка"), ЗаявлениеОПрисоединении.СпособМестоПолученияОтчетности); 	
		КонецЕсли;	
		
		// Среднемесячные доходы
		Если СвойстваЗаявления.Получить("СреднемесячныеДоходы") <> Неопределено Тогда
			ДокументОбъект.СреднемесячныеДоходы = ПолучитьЗначениеТипа(Тип("Строка"), ЗаявлениеОПрисоединении.СрдМесДох); 	
		КонецЕсли;	
		
		// Среднемесячные расходы
		Если СвойстваЗаявления.Получить("СреднемесячныеРасходы") <> Неопределено Тогда
			ДокументОбъект.СреднемесячныеРасходы = ПолучитьЗначениеТипа(Тип("Строка"), ЗаявлениеОПрисоединении.СрдМесРасх); 	
		КонецЕсли;	
		
		// Накопления
		Если СвойстваЗаявления.Получить("Накопления") <> Неопределено Тогда
			ДокументОбъект.Накопления = ПолучитьЗначениеТипа(Тип("Строка"), ЗаявлениеОПрисоединении.Накопления); 	
		КонецЕсли;	
		
		// Инвест опыт
		Если СвойстваЗаявления.Получить("ИнвестОпыт") <> Неопределено Тогда
			ДокументОбъект.ИнвестОпыт = ПолучитьЗначениеТипа(Тип("Строка"), ЗаявлениеОПрисоединении.ИнвестОпыт); 	
		КонецЕсли;	
		
		// Стоимость имущества
		Если СвойстваЗаявления.Получить("СтоимостьИмущества") <> Неопределено Тогда
			ДокументОбъект.СтоимостьИмущества = ПолучитьЗначениеТипа(Тип("Строка"), ЗаявлениеОПрисоединении.СтоимостьИмущества); 	
		КонецЕсли;	
		
		// Кодовое слово
		Если СвойстваЗаявления.Получить("КодовоеСлово") <> Неопределено Тогда
			ДокументОбъект.КодовоеСлово = ПолучитьЗначениеТипа(Тип("Строка"), ЗаявлениеОПрисоединении.КодовоеСлово); 	
		КонецЕсли;	
		
		
		
	КонецЕсли;
	
	Если НЕ ЗначениеЗаполнено(ДокументОбъект.АдресМестаЖительства) Тогда
		ОбщегоНазначенияКлиентСервер.СообщитьПользователю("В анкете клиента '" + НаименованиеЮрФизЛицаАнкеты + "' не указан адрес места жительства! Загрузка анкеты не будет произведена.");
		Возврат Неопределено;
	КонецЕсли;
	
	// Представители / Выгодоприобретатели
	Если СвойстваАнкеты.Получить("СведенияВыгодоприобретатель") <> Неопределено Тогда
		ДокументОбъект.ВыгодоприобретательКлиент = (ПолучитьЗначениеТипа(Тип("Строка"), ДанныеАнкеты.СведенияВыгодоприобретатель) = "Клиент");
	КонецЕсли;
	
	Если СвойстваАнкеты.Получить("СведенияБенефициарныйВладелец") <> Неопределено Тогда
		ДокументОбъект.БенефициарныйВладелецКлиент = (ПолучитьЗначениеТипа(Тип("Строка"), ДанныеАнкеты.СведенияБенефициарныйВладелец) = "Клиент");
	КонецЕсли;	
	
	ДокументОбъект.ПредставителиВыгодоприобретатели.Очистить();	
	
	// Бенефициарные владельцы
	Для Каждого БенефициарныйВладелец Из БенефициарныеВладельцы Цикл
		ОписаниеБенефициарногоВладельца = ДокументОбъект.ПредставителиВыгодоприобретатели.Добавить();
		ОписаниеБенефициарногоВладельца.ВидУчастника	= Перечисления.ВидыУчастниковАнкет.БенефициарныйВладелец;
		ОписаниеБенефициарногоВладельца.ЮрФизЛицо		= БенефициарныйВладелец.ЮрФизЛицо;	
	КонецЦикла;
	
	// Выгодоприобретатели (физические лица)
	Для Каждого ФизЛицоВыгодоприобретатель Из ФизЛицаВыгодоприобретатели Цикл
		ОписаниеВыгодоприобретателя = ДокументОбъект.ПредставителиВыгодоприобретатели.Добавить();
		ОписаниеВыгодоприобретателя.ВидУчастника	= Перечисления.ВидыУчастниковАнкет.Выгодоприобретатель;
		ОписаниеВыгодоприобретателя.ЮрФизЛицо		= ФизЛицоВыгодоприобретатель.ЮрФизЛицо;	
	КонецЦикла;
	
	// Представители (физические лица)
	Для Каждого ФизЛицоПредставитель Из ФизЛицаПредставители Цикл
		ОписаниеПредставителя = ДокументОбъект.ПредставителиВыгодоприобретатели.Добавить();
		ОписаниеПредставителя.ВидУчастника			= Перечисления.ВидыУчастниковАнкет.Представитель;
		ОписаниеПредставителя.ЮрФизЛицо				= ФизЛицоПредставитель.ЮрФизЛицо;
		ОписаниеПредставителя.СтатусПредставителя	= ФизЛицоПредставитель.СтатусПредставителя;
		ОписаниеПредставителя.ОснованиеПолномочий	= ФизЛицоПредставитель.ОснованиеПолномочий;
	КонецЦикла;	
	
	Если СвойстваАнкеты.Получить("ЛицоЗаполнившееАнкету") <> Неопределено Тогда
		ЛицоЗаполневшееАнкету = ДанныеАнкеты.ЛицоЗаполнившееАнкету;
		
		ДокументОбъект.ДолжностьАгента = ПолучитьЗначениеТипа(Тип("Строка"), ЛицоЗаполневшееАнкету.Должность);
		
		ФИО = ЛицоЗаполневшееАнкету.ФИО;
		ДокументОбъект.ФИОАгента = СокрЛП(ПолучитьЗначениеТипа(Тип("Строка"), ФИО.Фамилия) + " "
									+ ПолучитьЗначениеТипа(Тип("Строка"), ФИО.Имя) + " "
									+ ПолучитьЗначениеТипа(Тип("Строка"), ФИО.Отчество));
	КонецЕсли;
	
	ОповещениеПриЗагрузкеДанныхВАнкету(ДокументОбъект);
	
	// Сохраняем данные
	НачатьТранзакцию();
	
	ДокументОбъект.ДополнительныеСвойства.Вставить("ЗагрузкаДанныхВАнкету", Истина);
	ДокументОбъект.Записать(РежимЗаписиДокумента.Проведение);
	ЗарегистрироватьКодОбъектаВоВнешнейСистеме(ДокументОбъект.Ссылка, ВнешняяСистема, ГруппаОбъектов, КодВнешнейСистемы);
	
	// Если загружается анкета с упрощенной идентификацией,
	// то в системе не должно быть анкет с полной идентификацией для действующих клиентов на дату анкеты.
	// Проверяем здесь, т.к. ЮрФизЛицо определяется при записи документа
	Если УпрощеннаяИдентификация Тогда
		Запрос = Новый Запрос;
		
		Справочники.ЮрФизЛица.ПоместитьКлиентовВМенеджерВременныхТаблиц(Запрос, ДокументОбъект.Организация, ДокументОбъект.Дата);
		
		Запрос.Текст = 
		
		#Область ТекстЗапроса		
			"ВЫБРАТЬ РАЗРЕШЕННЫЕ РАЗЛИЧНЫЕ
			|	_Клиенты.ЮрФизЛицо КАК ЮрФизЛицо,
			|	РеквизитыФизическихЛицАнкетныеСрезПоследних.Регистратор КАК Ссылка
			|ИЗ
			|		_Клиенты КАК _Клиенты
			|		ВНУТРЕННЕЕ СОЕДИНЕНИЕ РегистрСведений.РеквизитыФизическихЛицАнкетные.СрезПоследних(
			|				&Период,
			|				Организация = &Организация
			|					И ЮрФизЛицо = &ЮрФизЛицо
			|					И Язык = ЗНАЧЕНИЕ(Справочник.Языки.Русский)) КАК РеквизитыФизическихЛицАнкетныеСрезПоследних
			|		ПО (РеквизитыФизическихЛицАнкетныеСрезПоследних.ЮрФизЛицо = _Клиенты.ЮрФизЛицо)
			|			И (ВЫРАЗИТЬ(РеквизитыФизическихЛицАнкетныеСрезПоследних.Регистратор КАК Документ.АнкетаФизическогоЛица).УпрощеннаяИдентификация = ЛОЖЬ)";
		#КонецОбласти

		Запрос.УстановитьПараметр("Период"			, ДокументОбъект.Дата);
		Запрос.УстановитьПараметр("Организация"		, ДокументОбъект.Организация);
		Запрос.УстановитьПараметр("ЮрФизЛицо"		, ДокументОбъект.ЮрФизЛицо);
		
		АнкетыСПолнойИдентификацией = Запрос.Выполнить().Выбрать();
		Если АнкетыСПолнойИдентификацией.Следующий() Тогда
			ОтменитьТранзакцию();
			ОбщегоНазначенияКлиентСервер.СообщитьПользователю("В анкете клиента '" + НаименованиеЮрФизЛицаАнкеты + "' указана упрощенная идентификация, но найдена зарегистрированная анкета с полной идентификацией. Загрузка анкеты выполнена не будет.", АнкетыСПолнойИдентификацией.Ссылка);
			Возврат Неопределено;	
		КонецЕсли;
	КонецЕсли;	
	
	ЗафиксироватьТранзакцию();
	
	// Уведомляем об обновлении анкеты
	ОбщегоНазначенияКлиентСервер.СообщитьПользователю(?(ЭтоНоваяАнкета, "Добавлена", "Обновлена") + " анкета '" + НаименованиеЮрФизЛицаАнкеты + "'", ДокументОбъект.Ссылка); 	
	
	Возврат ДокументОбъект.ЮрФизЛицо;
КонецФункции

Функция ПрочитатьАдрес(ОбъектXDTO, ИменаПолейАдреса)	
	Страна = ПолучитьЗначениеТипа(Тип("Строка"), ОбъектXDTO[ИменаПолейАдреса.Страна]);
	Индекс = ПолучитьЗначениеТипа(Тип("Строка"), ОбъектXDTO[ИменаПолейАдреса.Индекс]);
	Регион = ПолучитьЗначениеТипа(Тип("Строка"), ОбъектXDTO[ИменаПолейАдреса.Регион]);
	Район  = ПолучитьЗначениеТипа(Тип("Строка"), ОбъектXDTO[ИменаПолейАдреса.Область]);
	Город  = ПолучитьЗначениеТипа(Тип("Строка"), ОбъектXDTO[ИменаПолейАдреса.НаселенныйПункт]);
	Улица  = ПолучитьЗначениеТипа(Тип("Строка"), ОбъектXDTO[ИменаПолейАдреса.Улица]);
	
	Дом      = ПолучитьЗначениеТипа(Тип("Строка"), ОбъектXDTO[ИменаПолейАдреса.Дом]);
	Корпус   = ПолучитьЗначениеТипа(Тип("Строка"), ОбъектXDTO[ИменаПолейАдреса.Корпус]);
	Строение = ПолучитьЗначениеТипа(Тип("Строка"), ОбъектXDTO[ИменаПолейАдреса.Строение]);
	Квартира = ПолучитьЗначениеТипа(Тип("Строка"), ОбъектXDTO[ИменаПолейАдреса.Квартира]);
	
	// Страна должна приходить по коду альфа-2
	Если ЗначениеЗаполнено(Страна) Тогда
		СтранаСсылка = Справочники.СтраныМира.НайтиПоРеквизиту("КодАльфа2", Страна);
		Если ЗначениеЗаполнено(СтранаСсылка) Тогда
			Страна = ОбщегоНазначения.ЗначениеРеквизитаОбъекта(СтранаСсылка, "Наименование");	
		КонецЕсли;
	КонецЕсли;
	
	ПредставлениеАдреса = "";
	ДополнитьПредставлениеАдреса(Страна,   ", ", ПредставлениеАдреса);
	ДополнитьПредставлениеАдреса(Индекс,   ", ", ПредставлениеАдреса);
	ДополнитьПредставлениеАдреса(Регион,   ", ", ПредставлениеАдреса);
	ДополнитьПредставлениеАдреса(Район,    ", ", ПредставлениеАдреса, Истина);
	ДополнитьПредставлениеАдреса(Город,    ", ", ПредставлениеАдреса, Истина);
	
	ДополнитьПредставлениеАдреса(Улица,    ", ", ПредставлениеАдреса);
	ДополнитьПредставлениеАдреса(?(ПустаяСтрока(Дом), "", "дом " + Дом),            ", ", ПредставлениеАдреса);
	ДополнитьПредставлениеАдреса(?(ПустаяСтрока(Корпус), "", "корп. " + Корпус),    ", ", ПредставлениеАдреса);
	ДополнитьПредставлениеАдреса(?(ПустаяСтрока(Строение), "", "стр. " + Строение), ", ", ПредставлениеАдреса);
	ДополнитьПредставлениеАдреса(?(ПустаяСтрока(Квартира), "", "кв. " + Квартира),  ", ", ПредставлениеАдреса);
	
	Возврат ПредставлениеАдреса;
	
КонецФункции

Функция ПрочитатьАдресФИАС(ОбъектXDTO, ИменаПолейАдреса)
	Страна		= ПолучитьЗначениеТипа(Тип("Строка"), ОбъектXDTO[ИменаПолейАдреса.Страна]);
	Индекс		= ПолучитьЗначениеТипа(Тип("Строка"), ОбъектXDTO[ИменаПолейАдреса.Индекс]);
	Регион		= ПолучитьЗначениеТипа(Тип("Строка"), ОбъектXDTO[ИменаПолейАдреса.Регион]);
	КодРегиона	= ПолучитьЗначениеТипа(Тип("Строка"), ОбъектXDTO[ИменаПолейАдреса.КодРегиона]);
	Район		= ПолучитьЗначениеТипа(Тип("Строка"), ОбъектXDTO[ИменаПолейАдреса.Область]);
	Город		= ПолучитьЗначениеТипа(Тип("Строка"), ОбъектXDTO[ИменаПолейАдреса.НаселенныйПункт]);
	Улица		= ПолучитьЗначениеТипа(Тип("Строка"), ОбъектXDTO[ИменаПолейАдреса.Улица]);
	
	Дом      = ПолучитьЗначениеТипа(Тип("Строка"), ОбъектXDTO[ИменаПолейАдреса.Дом]);
	Корпус   = ПолучитьЗначениеТипа(Тип("Строка"), ОбъектXDTO[ИменаПолейАдреса.Корпус]);
	Строение = ПолучитьЗначениеТипа(Тип("Строка"), ОбъектXDTO[ИменаПолейАдреса.Строение]);
	Квартира = ПолучитьЗначениеТипа(Тип("Строка"), ОбъектXDTO[ИменаПолейАдреса.Квартира]);	
	
	// для РФ страна должна быть пустой  
	Если СтрНайти(ВРег(СтрЗаменить(Страна, "  ", " ")), "РОССИЙСКАЯ ФЕДЕРАЦИЯ") > 0
	ИЛИ СтрНайти(ВРег(Страна), "РОССИЯ") > 0
	ИЛИ ВРег(Страна) = "RU" Тогда
		Страна = "";			
	КонецЕсли;

	// Страна должна приходить по коду альфа-2
	Если ЗначениеЗаполнено(Страна) Тогда
		СтранаСсылка = Справочники.СтраныМира.НайтиПоРеквизиту("КодАльфа2", Страна);
		Если ЗначениеЗаполнено(СтранаСсылка) Тогда
			Страна = ОбщегоНазначения.ЗначениеРеквизитаОбъекта(СтранаСсылка, "Наименование");	
		КонецЕсли;
	КонецЕсли;
	
	ПредставлениеАдреса = "";
	ДополнитьПредставлениеАдреса(Страна,   ", ", ПредставлениеАдреса);
	ДополнитьПредставлениеАдреса(Индекс,   ", ", ПредставлениеАдреса);
	ДополнитьПредставлениеАдреса(Регион,   ", ", ПредставлениеАдреса);
	ДополнитьПредставлениеАдреса(Район,    ", ", ПредставлениеАдреса, Истина);
	ДополнитьПредставлениеАдреса(Город,    ", ", ПредставлениеАдреса, Истина);
	
	ДополнитьПредставлениеАдреса(Улица,    ", ", ПредставлениеАдреса);
	ДополнитьПредставлениеАдреса(?(ПустаяСтрока(Дом), "", "дом " + Дом),            ", ", ПредставлениеАдреса);
	ДополнитьПредставлениеАдреса(?(ПустаяСтрока(Корпус), "", "корп. " + Корпус),    ", ", ПредставлениеАдреса);
	ДополнитьПредставлениеАдреса(?(ПустаяСтрока(Строение), "", "стр. " + Строение), ", ", ПредставлениеАдреса);
	ДополнитьПредставлениеАдреса(?(ПустаяСтрока(Квартира), "", "кв. " + Квартира),  ", ", ПредставлениеАдреса);
	
	ПространствоИмен = "http://www.v8.1c.ru/ssl/contactinfo";
	
	Результат = ФабрикаXDTO.Создать(ФабрикаXDTO.Тип(ПространствоИмен, "КонтактнаяИнформация"));
	Результат.Состав = ФабрикаXDTO.Создать(ФабрикаXDTO.Тип(ПространствоИмен, "Адрес"));
	Результат.Представление = ПредставлениеАдреса;
	
	Адрес = Результат.Состав;
		
	Если ЗначениеЗаполнено(Страна) Тогда
		Адрес.Страна = Страна;
		Адрес.Состав = ПредставлениеАдреса;
		
	Иначе
		АдресРФ = ФабрикаXDTO.Создать(ФабрикаXDTO.Тип(ПространствоИмен, "АдресРФ"));
		
		Если ЗначениеЗаполнено(Индекс) Тогда
			ЭлементИндекс = СоздатьДопАдрЭлемента(АдресРФ);
			ЭлементИндекс.ТипАдрЭл = "10100000";
			ЭлементИндекс.Значение = Индекс;
		КонецЕсли;	
		
		Если ЗначениеЗаполнено(Регион) Тогда
			АдресРФ.СубъектРФ = Регион;
		КонецЕсли;
		
		Если ЗначениеЗаполнено(КодРегиона) Тогда
			АдресРФ.КодСубъектаРФ = КодРегиона;
		КонецЕсли;
		
		Если ЗначениеЗаполнено(Район) Тогда
			АдресРФ.СвРайМО = ФабрикаXDTO.Создать(АдресРФ.Тип().Свойства.Получить("СвРайМО").Тип);
			АдресРФ.СвРайМО.Район = Район;

		КонецЕсли;
		
		Если ЗначениеЗаполнено(Город) Тогда
			АдресРФ.Город = Город;
		КонецЕсли;
		
		Если ЗначениеЗаполнено(Улица) Тогда
			АдресРФ.Улица = Улица;
		КонецЕсли;
		
		Если ЗначениеЗаполнено(Дом) Тогда
			ЭлементДом = СоздатьНомерДопАдрЭлемента(АдресРФ);
			ЭлементДом.Тип = "1010";
			ЭлементДом.Значение = Дом;
		КонецЕсли;
		
		Если ЗначениеЗаполнено(Корпус) Тогда
			ЭлементКорпус = СоздатьНомерДопАдрЭлемента(АдресРФ);
			ЭлементКорпус.Тип = "1050";
			ЭлементКорпус.Значение = Корпус;

		КонецЕсли;
		
		Если ЗначениеЗаполнено(Строение) Тогда
			ЭлементКорпус = СоздатьНомерДопАдрЭлемента(АдресРФ);
			ЭлементКорпус.Тип = "1060";
			ЭлементКорпус.Значение = Строение;
		КонецЕсли;
		
		Если ЗначениеЗаполнено(Квартира) Тогда
			ЭлементКвартира = СоздатьНомерДопАдрЭлемента(АдресРФ);
			ЭлементКвартира.Тип = "2010";
			ЭлементКвартира.Значение = Квартира;
		КонецЕсли;
		
		Адрес.Состав = АдресРФ;
	КонецЕсли;
	
	Запись = Новый ЗаписьXML;
	Запись.УстановитьСтроку(Новый ПараметрыЗаписиXML(, , Ложь, Ложь, ""));
	
	ФабрикаXDTO.ЗаписатьXML(Запись, Результат);
	
	Результат = СтрЗаменить(Запись.Закрыть(), Символы.ПС, "&#10;");
	
	Возврат Результат;
	
КонецФункции

Функция СоздатьНомерДопАдрЭлемента(АдресРФ) Экспорт 
	ДопАдрЭл = СоздатьДопАдрЭлемента(АдресРФ);
	ДопАдрЭл.Номер = ФабрикаXDTO.Создать(ДопАдрЭл.Тип().Свойства.Получить("Номер").Тип);
	Возврат ДопАдрЭл.Номер;
КонецФункции

Функция СоздатьДопАдрЭлемента(АдресРФ) Экспорт
	СвойствоДопАдрЭлемента = АдресРФ.ДопАдрЭл.ВладеющееСвойство;
	ДопАдрЭлемента = ФабрикаXDTO.Создать(СвойствоДопАдрЭлемента.Тип);
	АдресРФ.ДопАдрЭл.Добавить(ДопАдрЭлемента);
	Возврат ДопАдрЭлемента;
КонецФункции

Процедура ДополнитьПредставлениеАдреса(Дополнение, СтрокаКонкатенации, Представление, ПропускатьНайденныйТекст = Ложь)
	
	Если ПропускатьНайденныйТекст и СтрНайти(Представление, СтрокаКонкатенации + Дополнение) Тогда
		Возврат;
	КонецЕсли;
	
	Если Дополнение <> "" Тогда
		Представление = Представление + ?(ПустаяСтрока(Представление), "", СтрокаКонкатенации) + Дополнение;
	КонецЕсли;
	
КонецПроцедуры

Функция ПолучитьЗначениеТипа(Тип, ЗначениеXDTO, УдалитьПробельныеСимволыИзСтроки = Ложь) Экспорт
	
	Если ТипЗнч(ЗначениеXDTO) = Тип("ОбъектXDTO") Тогда // Так читаются пустые значения
		Возврат ОбщегоНазначенияКлиентСервер.ПустоеЗначениеТипа(Тип); 
	Иначе
		КонвертируемоеЗначение = СокрЛП(ЗначениеXDTO);
	КонецЕсли;
	
	Попытка
		ЗначениеКонвертации = XMLЗначение(Тип, КонвертируемоеЗначение);
	Исключение
		
		ИнформацияОбОшибке = ИнформацияОбОшибке();
		ОбщегоНазначенияКлиентСервер.СообщитьПользователю("Ошибка конвертации значения " 
			+ ЗначениеКонвертации + " тип значения " + ТипЗнч(ЗначениеКонвертации)
			+ " в тип " + Тип + ": " + ИнформацияОбОшибке.Описание);
		
		Возврат ОбщегоНазначенияКлиентСервер.ПустоеЗначениеТипа(Тип);
		
	КонецПопытки;
	
	Если УдалитьПробельныеСимволыИзСтроки И ТипЗнч(ЗначениеКонвертации) = Тип("Строка") Тогда
		ЗначениеКонвертации = РаботаСоСтрокамиКлиентСервер.ЗаменитьПробельныеСимволы(ЗначениеКонвертации);
	КонецЕсли;
	
	Возврат ЗначениеКонвертации;
	
КонецФункции

Процедура ОбработатьОшибку(ТекстОшибки, ИсточникПоУмолчанию = "", ДополнительныеПараметры = Неопределено)
	
	Если ТипЗнч(ДополнительныеПараметры) = Тип("Структура") И ДополнительныеПараметры.Свойство("РежимБезУведомлений") Тогда
		
		Если Не ДополнительныеПараметры.Свойство("Ошибки") Тогда
			ДополнительныеПараметры.Вставить("Ошибки", Новый Массив);	
		КонецЕсли;
		
		ДополнительныеПараметры.Ошибки.Добавить(ТекстОшибки);
		
	Иначе
		
		УстановитьПривилегированныйРежим(Истина);
		
		ИсточникОшибки = ИсточникПоУмолчанию;
		Если ТипЗнч(ДополнительныеПараметры) = Тип("Структура") И ДополнительныеПараметры.Свойство("Источник") Тогда
			ИсточникОшибки = ДополнительныеПараметры.Источник;	
		КонецЕсли;
		
		ЗаписьЖурналаРегистрации(ИсточникОшибки, УровеньЖурналаРегистрации.Ошибка, , ИсточникОшибки, ТекстОшибки);
		
		ОбщегоНазначенияКлиентСервер.СообщитьПользователю(ТекстОшибки);
		
		УстановитьПривилегированныйРежим(Ложь);
		
	КонецЕсли;
	
КонецПроцедуры

Процедура ОповещениеПриЗагрузкеДанныхВАнкету(ДокументОбъект)
	
	ТекстОшибки = "";
	Если НЕ РаботаСКонтактнойИнформациейКлиентСервер.ПроверкаТелефонаДляОповещения(ДокументОбъект.ТелефонДляОповещения, ТекстОшибки) Тогда
		
		РеквизитыОповещения = Новый Структура;
		РеквизитыОповещения.Вставить("Источник"				, ДокументОбъект);
		РеквизитыОповещения.Вставить("Организация"			, ДокументОбъект.Организация);
		РеквизитыОповещения.Вставить("ЮрФизЛицо"			, ДокументОбъект.ЮрФизЛицо);
		РеквизитыОповещения.Вставить("ТекстОповещения"		, "Неверно указан телефон для оповещения: " + ТекстОшибки + " (" + ДокументОбъект.ТелефонДляОповещения + ")");
		
		Справочники.Оповещения.СформироватьОповещения(ДокументОбъект.Метаданные().ПолноеИмя(), Перечисления.ТипыСобытий.ПриЗагрузкеДанныхВАнкету, РеквизитыОповещения);
		
		ДокументОбъект.ТелефонДляОповещения = "";
		
	КонецЕсли;
	
КонецПроцедуры

////////////////////////////////////////////////////////////////////////////////
// РАБОТА С ИМПОРТИРУЕМЫМИ ОБЪЕКТАМИ

Функция ОбъектИмпортируетсяИзВнешнейСистемы(Объект, Описание = "", ВнешняяСистема = Неопределено) Экспорт
	
	Описание = "";
	
	ОбъектМД           = Метаданные.НайтиПоТипу(ТипЗнч(Объект));
	ПолноеИмяОбъектаМД = ОбъектМД.ПолноеИмя();
	
	// значения данных регистров всегда и полностью импортируются из Матрих
	ЗагружаютсяИзМатрикс = Новый Массив(); // когда-нибудь этот список будет получаться автоматически из импорта из внеш. систем
	
	ЗагружаютсяИзМатрикс.Добавить("Справочник.ЮрФизЛица");
	ЗагружаютсяИзМатрикс.Добавить("Справочник.Лицензии");
	ЗагружаютсяИзМатрикс.Добавить("Справочник.ИнвестиционныеСчета");
	ЗагружаютсяИзМатрикс.Добавить("Справочник.Портфели");
	ЗагружаютсяИзМатрикс.Добавить("Справочник.Акции");
	ЗагружаютсяИзМатрикс.Добавить("Справочник.Облигации");
	ЗагружаютсяИзМатрикс.Добавить("Справочник.Паи");
	ЗагружаютсяИзМатрикс.Добавить("Справочник.ПаевыеИнвестиционныеФонды");
	ЗагружаютсяИзМатрикс.Добавить("Справочник.Векселя");
	ЗагружаютсяИзМатрикс.Добавить("Справочник.ИпотечныеСертификатыУчастия"); 
	ЗагружаютсяИзМатрикс.Добавить("Справочник.ДепозитарныеРасписки");
	ЗагружаютсяИзМатрикс.Добавить("Справочник.ПроизводныеФинансовыеИнструменты");
	ЗагружаютсяИзМатрикс.Добавить("Справочник.ВалютныеПары");
	ЗагружаютсяИзМатрикс.Добавить("Справочник.БазовыеСтавкиОблигаций");
	ЗагружаютсяИзМатрикс.Добавить("Справочник.Отрасли");
	ЗагружаютсяИзМатрикс.Добавить("Справочник.Товары");
	
	ЗагружаютсяИзМатрикс.Добавить("РегистрСведений.ДокументыЮридическихЛиц");
	ЗагружаютсяИзМатрикс.Добавить("РегистрСведений.КодыВТорговыхСистемах");
	ЗагружаютсяИзМатрикс.Добавить("РегистрСведений.КонтактнаяИнформация");
	ЗагружаютсяИзМатрикс.Добавить("РегистрСведений.КупонныйДоходПоОблигациям");
	ЗагружаютсяИзМатрикс.Добавить("РегистрСведений.НоминалыЦенныхБумаг");
	ЗагружаютсяИзМатрикс.Добавить("РегистрСведений.РеквизитыЮридическихЛиц");
	ЗагружаютсяИзМатрикс.Добавить("РегистрСведений.УсловияОферт");
	ЗагружаютсяИзМатрикс.Добавить("РегистрСведений.ГарантийныеОбеспечения");
	ЗагружаютсяИзМатрикс.Добавить("РегистрСведений.ПереченьЦенныхБумагПредназначенныхДляКвалифицированныхИнвесторов");
	ЗагружаютсяИзМатрикс.Добавить("РегистрСведений.РасчетныеЦеныПаев");
	ЗагружаютсяИзМатрикс.Добавить("РегистрСведений.СвязанныеЮридическиеЛица");
	ЗагружаютсяИзМатрикс.Добавить("РегистрСведений.ОбъемыАктивовЭмитентов");
	ЗагружаютсяИзМатрикс.Добавить("РегистрСведений.ЦенныеБумагиВОбращении");
	ЗагружаютсяИзМатрикс.Добавить("РегистрСведений.РеквизитыПИФ");
	ЗагружаютсяИзМатрикс.Добавить("РегистрСведений.РасчетныеЦеныПаев");
	ЗагружаютсяИзМатрикс.Добавить("РегистрСведений.УсловияРасчетаПроцентовВекселей");
	ЗагружаютсяИзМатрикс.Добавить("РегистрСведений.СтатусыЛицензий");
	ЗагружаютсяИзМатрикс.Добавить("РегистрСведений.ОрганизаторыРазмещенияЦенныхБумаг");
	
	// значения данных регистров всегда и полностью импортируются из ЗУП
	ЗагружаютсяИзЗУП = Новый Массив;
	ЗагружаютсяИзЗУП.Добавить("Справочник.Сотрудники");
	
	ЗагружаютсяИзЗУП.Добавить("РегистрСведений.РеквизитыСотрудниковОрганизации");
	ЗагружаютсяИзЗУП.Добавить("РегистрСведений.СотрудникиОрганизации");
	ЗагружаютсяИзЗУП.Добавить("РегистрСведений.СостояниеСотрудниковОрганизаций");
	
	// Часть элементов импортируются из ЗУП
	ЧастьЭлементовЗагружаетсяИзЗУП = Новый Массив;
	ЧастьЭлементовЗагружаетсяИзЗУП.Добавить("Справочник.Должности");
	ЧастьЭлементовЗагружаетсяИзЗУП.Добавить("Справочник.Подразделения");
	
	ЗагружаютсяИзExternals = Новый Массив;
	ЗагружаютсяИзExternals.Добавить("РегистрСведений.РыночныеРискиНКЦ"); 
	
	Если ЗагружаютсяИзМатрикс.Найти(ПолноеИмяОбъектаМД) <> Неопределено Тогда
		Если      Найти(ПолноеИмяОбъектаМД, "Справочник.") = 1 Тогда
			Описание = "Элементы справочника " + ОбъектМД.Представление() + " загружаются из Матрикс. Воспользуйтесь ссылкой в карточке или обработкой ""Импорт нормативно-справочной информации""";
		ИначеЕсли Найти(ПолноеИмяОбъектаМД, "РегистрСведений.") = 1 Тогда
			Описание = "Данные регистра " + ОбъектМД.Представление() + " загружаются из Матрикс. Воспользуйтесь ссылкой в карточке записи или обработкой ""Импорт нормативно-справочной информации""";
		КонецЕсли;
		
		ВнешняяСистема = Справочники.ВнешниеСистемы.Матрих;
			
		Возврат Истина;
		
	ИначеЕсли ЗагружаютсяИзЗУП.Найти(ПолноеИмяОбъектаМД) <> Неопределено Тогда
		Если Найти(ПолноеИмяОбъектаМД, "Справочник.") = 1 Тогда
			Описание = "Элементы справочника " + ОбъектМД.Представление() + " загружаются из ЗУП на основании регламента.";
		ИначеЕсли Найти(ПолноеИмяОбъектаМД, "РегистрСведений.") = 1 Тогда
			Описание = "Данные регистра " + ОбъектМД.Представление() + " загружаются из ЗУП на основании регламента.";
		КонецЕсли;
		
		ВнешняяСистема = Справочники.ВнешниеСистемы.ЗУП;
			
		Возврат Истина;
		
	ИначеЕсли ЧастьЭлементовЗагружаетсяИзЗУП.Найти(ПолноеИмяОбъектаМД) <> Неопределено Тогда
		
		Если РегистрыСведений.КодыВоВнешнихСистемах.СрезПоследних(ТекущаяДата(), Новый Структура("ВнешняяСистема, Объект", Справочники.ВнешниеСистемы.ЗУП, Объект.Ссылка)).Количество() Тогда
			Описание = "Элементы справочника " + ОбъектМД.Представление() + " загружаются из ЗУП на основании регламента.";
			ВнешняяСистема = Справочники.ВнешниеСистемы.ЗУП;
			
			Возврат Истина;
		КонецЕсли;
		
	ИначеЕсли ЗагружаютсяИзExternals.Найти(ПолноеИмяОбъектаМД) <> Неопределено Тогда
		
		Если      Найти(ПолноеИмяОбъектаМД, "Справочник.") = 1 Тогда
			Описание = "Элементы справочника " + ОбъектМД.Представление() + " загружаются из Externals.";
		ИначеЕсли Найти(ПолноеИмяОбъектаМД, "РегистрСведений.") = 1 Тогда
			Описание = "Данные регистра " + ОбъектМД.Представление() + " загружаются из Externals.";
		КонецЕсли;
		
		ВнешняяСистема = Справочники.ВнешниеСистемы.Externals;
			
		Возврат Истина;
		
	КонецЕсли;
	
	Возврат Ложь;
	
КонецФункции // ОбъектИмпортируетсяИзВнешнейСистемы

////////////////////////////////////////////////////////////////////////////////
// РАБОТА С КОДАМИ ВНЕШНИХ СИСТЕМ

Процедура ЗарегистрироватьКодОбъектаВоВнешнейСистеме(Объект, ВнешняяСистема, ГруппаОбъектов, Код, ДопКод1 = Неопределено, ДопКод2 = Неопределено, Период = '19800101') Экспорт

	// у обычных пользователей нет прав на изменение регистра сведений КодыВоВнешнихСистемах;
	// право на изменение регистра определяется наличием права на изменение объекта
	
	Если Не ПравоДоступа("Изменение", Объект.Метаданные()) Тогда 
		ВызватьИсключение "Ошибка регистрации кода внешней системы. Отсутвуют права на изменение объекта " + Объект.Метаданные().ПолноеИмя();
	КонецЕсли;
	
	УстановитьПривилегированныйРежим(Истина);
	
	МенеджерЗаписиКодыВоВнешнихСистемах = РегистрыСведений.КодыВоВнешнихСистемах.СоздатьМенеджерЗаписи();
	МенеджерЗаписиКодыВоВнешнихСистемах.Период         = Период;
	МенеджерЗаписиКодыВоВнешнихСистемах.ВнешняяСистема = ВнешняяСистема;
	МенеджерЗаписиКодыВоВнешнихСистемах.ГруппаОбъектов = ГруппаОбъектов;
	МенеджерЗаписиКодыВоВнешнихСистемах.Объект         = Объект;
	МенеджерЗаписиКодыВоВнешнихСистемах.Код            = Код;
	МенеджерЗаписиКодыВоВнешнихСистемах.ДопКод         = ДопКод1;
	МенеджерЗаписиКодыВоВнешнихСистемах.ДопКод1        = ДопКод2;
	МенеджерЗаписиКодыВоВнешнихСистемах.Записать();
	
	УстановитьПривилегированныйРежим(Ложь);	

КонецПроцедуры // ЗарегистрироватьКодОбъектаВоВнешнейСистеме

Функция НайтиЗначениеПоКодуВнешнейСистемы(ВнешняяСистема, ГруппаОбъектов, Код, ДопКод1 = Неопределено, ДопКод2 = Неопределено, Период = Неопределено) Экспорт
	
	НайденноеЗначение = Неопределено;
	
	Выборка = ПолучитьВыборкуОбъектовПоКодуВнешнейСистемы(ВнешняяСистема, ГруппаОбъектов, Код, ДопКод1, ДопКод2, Период);
	Если Выборка.Следующий() Тогда
		НайденноеЗначение = Выборка.Объект;
	КонецЕсли;
	
	Возврат НайденноеЗначение;

КонецФункции

Функция ПолучитьВыборкуОбъектовПоКодуВнешнейСистемы(ВнешняяСистема, ГруппаОбъектов, Код, ДопКод1 = Неопределено, ДопКод2 = Неопределено, Период = Неопределено)
	
	Запрос = Новый Запрос(
	"ВЫБРАТЬ РАЗРЕШЕННЫЕ
	|	РегистрКодов.Объект КАК Объект
	|ИЗ
	|	РегистрСведений.КодыВоВнешнихСистемах.СрезПоследних(
	|			&Период,
	|			ВнешняяСистема = &ВнешняяСистема
	|				И ГруппаОбъектов = &ГруппаОбъектов
	|				И Объект В
	|					(ВЫБРАТЬ РАЗЛИЧНЫЕ
	|						РегистрКодов.Объект КАК Объект
	|					ИЗ
	|						РегистрСведений.КодыВоВнешнихСистемах КАК РегистрКодов
	|					ГДЕ
	|						РегистрКодов.ВнешняяСистема = &ВнешняяСистема
	|						И РегистрКодов.ГруппаОбъектов = &ГруппаОбъектов
	|						И РегистрКодов.Код = &Код
	|						И РегистрКодов.ДопКод = &ДопКод
	|						И РегистрКодов.ДопКод1 = &ДопКод1)) КАК РегистрКодов
	|ГДЕ
	|	РегистрКодов.Код = &Код
	|	И РегистрКодов.ДопКод = &ДопКод
	|	И РегистрКодов.ДопКод1 = &ДопКод1");
	
	Если ДопКод1 = Неопределено Тогда
		Запрос.Текст = СтрЗаменить(Запрос.Текст, "И РегистрКодов.ДопКод = &ДопКод", "");	
	КонецЕсли;
	Если ДопКод2 = Неопределено Тогда
		Запрос.Текст = СтрЗаменить(Запрос.Текст, "И РегистрКодов.ДопКод1 = &ДопКод1", "");	
	КонецЕсли;
	
	Запрос.УстановитьПараметр("ВнешняяСистема", ВнешняяСистема);
	Запрос.УстановитьПараметр("ГруппаОбъектов", ГруппаОбъектов);
	
	Запрос.УстановитьПараметр("Период",  Период);
	Запрос.УстановитьПараметр("Код",     Код);
	Запрос.УстановитьПараметр("ДопКод",  ДопКод1);
	Запрос.УстановитьПараметр("ДопКод1", ДопКод2);
	
	Возврат Запрос.Выполнить().Выбрать();
	
КонецФункции

Функция ПолучитьВнешниеКодыЮрФизЛиц(ВнешняяСистема, МассивЛиц = Неопределено, ОшибкиПоиска = Неопределено) Экспорт
	Запрос = Новый Запрос("
		|ВЫБРАТЬ РАЗРЕШЕННЫЕ
		|	ЮрФизЛица.Ссылка КАК Ссылка,
		|	ЮрФизЛица.Наименование КАК Наименование,
		|	КодыВоВнешнихСистемахСрезПоследних.Код КАК Код
		|ПОМЕСТИТЬ
		|	_ВнешниеКодыЮрФизЛиц
		|ИЗ
		|	Справочник.ЮрФизЛица КАК ЮрФизЛица
		|	ЛЕВОЕ СОЕДИНЕНИЕ РегистрСведений.КодыВоВнешнихСистемах.СрезПоследних(, ВнешняяСистема = &ВнешняяСистема И 2 = 2) КАК КодыВоВнешнихСистемахСрезПоследних
		|		ПО КодыВоВнешнихСистемахСрезПоследних.Объект = ЮрФизЛица.Ссылка
		|ГДЕ
		|	ЮрФизЛица.ЭтоГруппа = ЛОЖЬ
		|	И 1 = 1
		|;
		|
		|ВЫБРАТЬ РАЗРЕШЕННЫЕ
		|	ВнешниеКодыЮрФизЛиц.Ссылка
		|ИЗ
		|	_ВнешниеКодыЮрФизЛиц КАК ВнешниеКодыЮрФизЛиц
		|ГДЕ
		|	ВнешниеКодыЮрФизЛиц.Код ЕСТЬ NULL
		|УПОРЯДОЧИТЬ ПО
		|	ВнешниеКодыЮрФизЛиц.Наименование 
		|;
		|
		|ВЫБРАТЬ РАЗРЕШЕННЫЕ
		|	ВнешниеКодыЮрФизЛиц.Код
		|ИЗ
		|	_ВнешниеКодыЮрФизЛиц КАК ВнешниеКодыЮрФизЛиц
		|ГДЕ
		|	ВнешниеКодыЮрФизЛиц.Код ЕСТЬ НЕ NULL
		|;
		|");
	Запрос.УстановитьПараметр("ВнешняяСистема", ВнешняяСистема);
	
	Если МассивЛиц <> Неопределено Тогда
		Запрос.Текст = СтрЗаменить(Запрос.Текст, "1 = 1", "ЮрФизЛица.Ссылка В (&МассивЛиц)");
		Запрос.Текст = СтрЗаменить(Запрос.Текст, "2 = 2", "Объект В (&МассивЛиц)");
		Запрос.УстановитьПараметр("МассивЛиц", МассивЛиц);
	КонецЕсли;
	
	Пакет = Запрос.ВыполнитьПакет();
	ОшибкиПоиска	= Пакет[1].Выгрузить();
	НайденныеКоды	= Пакет[2].Выгрузить();
	
	Возврат НайденныеКоды.ВыгрузитьКолонку("Код");
КонецФункции

////////////////////////////////////////////////////////////////////////////////
// ВЗАИМОДЕЙСТВИЕ С ВНЕШНИМ СЕРВЕРОМ ДАННЫХ ПОСРЕДСТВОМ ADODB.Connection

// Устанавливает соединение с сервером данных, используя COM-объект ADODB.Connection.
// Если соединение установить не удалось, выводится сообщение об ошибке.
//
// Параметры:
// 	СтрокаСоединения - строка соединения (ConnectionString) с сервером
// 
// Возвращаемое значение
// 	- COM-объект ADODB.Connection, если соединение установлено
//  - Неопределено - в противном случае
//
Функция ADODBC_УстановитьСоединение(СтрокаСоединения, ПараметрыСоединения = Неопределено, ДополнительныеПараметры = Неопределено) Экспорт
	
	Соединение = Новый COMОбъект("ADODB.Connection");
		
	Если ТипЗнч(ПараметрыСоединения) = Тип("Структура") Тогда
		ЗаполнитьЗначенияСвойств(Соединение, ПараметрыСоединения); 
	КонецЕсли;
	
	Соединение.ConnectionString = СтрокаСоединения;
	
	Для НомерПопытки = 1 По 3 Цикл
		
		Попытка	
			
			Соединение.Open();
			Прервать;
			
		Исключение
			
			Если НомерПопытки = 3 Тогда
				
				ТекстОшибки = НСтр("ru = 'Не удалось установить соединение с сервером SQL. Система сообщает: " + ОписаниеОшибки() + "'");
				ОбработатьОшибку(ТекстОшибки, "РаботаСВнешнимиСистемами.ADODBC_УстановитьСоединение", ДополнительныеПараметры);
				Возврат Неопределено;
				
			Иначе
				
				ВремяТаймаута = 3; //секунды
    			ЗапуститьПриложение("Timeout /T " + Строка(ВремяТаймаута) + " /NoBreak", , Истина);
				
			КонецЕсли;
			
		КонецПопытки;
		
	КонецЦикла;

	Возврат Соединение;
	
КонецФункции // ADODBC_УстановитьСоединение

// Разрывает переданное соединение с сервером данных. Если соединение закрыть не удалось,
// выводится сообщение об ошибке.
//
// Параметры:
// 	Соединение - COM-объект ADODB.Connection
// 
// Возвращаемое значение
// 	- Истина - если соединение было закрыто без ошибок
//  - Ложь - в противном случае
//
Функция ADODBC_ЗакрытьСоединение(Соединение, ДополнительныеПараметры = Неопределено) Экспорт
	
	Попытка
		Соединение.Close();
	Исключение
		ТекстОшибки = НСтр("ru = 'Не удалось закрыть соединение с сервером SQL. Система сообщает: " + ОписаниеОшибки() + "'");
		
		ОбработатьОшибку(ТекстОшибки, "РаботаСВнешнимиСистемами.ADODBC_ЗакрытьСоединение", ДополнительныеПараметры);
		
		Возврат Ложь;
	КонецПопытки;
	
	Возврат Истина;
	
КонецФункции // ADODBC_ЗакрытьСоединение

// Выполняет переданный запрос на сервере данных. Если при выполнении запроса
// произошла ошибка, то выводится сообщение, содержащее текст запроса и описание ошибки.
//
// Параметры:
// 	Соединение   - COM-объект ADODB.Connection
//  ТекстЗапроса - текст запроса, который будет выполнен на сервере
// 
// Возвращаемое значение
// 	- COM-объект ADODB.Recordset, если запрос был выполнен успешно
//  - Неопределено - в противном случае
//
Функция ADODBC_ВыполнитьЗапрос(Соединение, ТекстЗапроса, ДополнительныеПараметры = Неопределено) Экспорт
	
	НаборЗаписей = Новый COMОбъект("ADODB.Recordset");
	
	Для НомерПопытки = 1 По 3 Цикл
	
		Попытка
			
			НаборЗаписей.Open(ТекстЗапроса, Соединение);
			Прервать;
			
		Исключение
			
			Если НомерПопытки = 3 Тогда
				
				ОписаниеОшибки	= СтрЗаменить(ОписаниеОшибки(), """", "'");
				ТекстЗапроса	= СтрЗаменить(ТекстЗапроса, """", "'");
				ТекстОшибки		= НСтр("ru = ""Не удалось выполнить запрос " + Символы.ПС + ТекстЗапроса + Символы.ПС + "Система сообщает: " + ОписаниеОшибки + """");
				
				ОбработатьОшибку(ТекстОшибки, "РаботаСВнешнимиСистемами.ADODBC_ВыполнитьЗапрос", ДополнительныеПараметры);
				Возврат Неопределено;
				
			Иначе
				
				ВремяТаймаута = 3; //секунды
    			ЗапуститьПриложение("Timeout /T " + Строка(ВремяТаймаута) + " /NoBreak", , Истина);
				
			КонецЕсли;
			
		КонецПопытки;
		
	КонецЦикла;

	Возврат НаборЗаписей;
	
КонецФункции // ADODBC_ВыполнитьЗапрос

// Формирует из переданного COM-объекта ADODB.Recordset таблицу значений, имена 
//  колонок которой совпадают с именами полей набора. По-умолчанию колонки не типизированные
//  (т.е. передать такую таблицу в запрос не получится). В случае возникновения
//  ошибки выводится сообщение, содержащее текст запроса, по возможности, и описание ошибки.
//
// Параметры:
// 	НаборЗаписей - COM-объект ADODB.Recordset
// 	ТипыКолонок  - Структура, ключами которой являются имена колонок, а значениями - описание типов
// 
// Возвращаемое значение
// 	- Таблица значений, повторяющая структуру и содержащая данные из переданного набора,
//    если не возникло ошибок
//  - Неопределено - в противном случае
//
Функция ADODBC_ВыгрузитьНаборВТаблицуЗначений(НаборЗаписей, ТипыКолонок = Неопределено, ДополнительныеПараметры = Неопределено) Экспорт
	
	ТаблицаЗначений = Новый ТаблицаЗначений;
	
	Попытка
		Если НаборЗаписей.EOF И НаборЗаписей.BOF Тогда
			ВозвращатьПустуюТаблицу = Ложь;
			
			Если ТипЗнч(ДополнительныеПараметры) = Тип("Структура")
				И ДополнительныеПараметры.Свойство("ВозвращатьПустуюТаблицу") И ДополнительныеПараметры.ВозвращатьПустуюТаблицу = Истина
			Тогда
				ВозвращатьПустуюТаблицу = Истина;
			КонецЕсли;
			
			Если Не ВозвращатьПустуюТаблицу Тогда
				Возврат Неопределено;
			КонецЕсли;
			
		КонецЕсли;
			
		// создадим колонки таблицы значений
		КолПолейЗаписи = НаборЗаписей.Fields.Count;
		
		Для НомПоля = 0 По КолПолейЗаписи - 1 Цикл
			
			ИмяПоля = НаборЗаписей.Fields.Item(НомПоля).Name;
			
			Если ТипыКолонок = Неопределено Тогда
				ТаблицаЗначений.Колонки.Добавить(ИмяПоля);
			Иначе
				ТаблицаЗначений.Колонки.Добавить(ИмяПоля, ТипыКолонок[ИмяПоля]);
			КонецЕсли;
			
		КонецЦикла;

		// заполнение таблицы значений
		Если Не (НаборЗаписей.EOF И НаборЗаписей.BOF) Тогда
			
			НаборЗаписей.MoveFirst(); // если набор пустой, эта процедура вызывает исключение
			
			Пока НаборЗаписей.EOF() = 0 Цикл
							
				СтрокаТаблицыЗначений = ТаблицаЗначений.Добавить();
				
				Для НомПоля = 0 По КолПолейЗаписи - 1 Цикл
					СтрокаТаблицыЗначений[НомПоля] = НаборЗаписей.Fields.Item(НомПоля).Value;
				КонецЦикла;
				
				НаборЗаписей.MoveNext();
				
			КонецЦикла;
			
		КонецЕсли;
			
	Исключение
		ОписаниеОшибки = СтрЗаменить(ОписаниеОшибки(), """", "'");
		
		Попытка
			ТекстЗапроса = НаборЗаписей.Source;
		Исключение
			ТекстЗапроса = "<>";
		КонецПопытки;
		
		ТекстЗапроса = СтрЗаменить(ТекстЗапроса, """", "'");
		
		Если СтрДлина(ТекстЗапроса) > 255 Тогда
			ТекстЗапроса = Лев(ТекстЗапроса, 254) + "…";
		КонецЕсли;
		
		ТекстОшибки = НСтр("ru = ""Не удалось выгрузить в таблицу значений результат запроса " + Символы.ПС + ТекстЗапроса + Символы.ПС + "Система сообщает: " + ОписаниеОшибки + """");
		
		ОбработатьОшибку(ТекстОшибки, "РаботаСВнешнимиСистемами.ADODBC_ВыгрузитьНаборВТаблицуЗначений", ДополнительныеПараметры);
		
		Возврат Неопределено;
		
	КонецПопытки;
	
	Возврат ТаблицаЗначений;
	
КонецФункции // ADODBC_ВыгрузитьНаборВТаблицуЗначений

// Автоматизирует выборку данных из внешнего источника с последующей передачей результата
// в таблицу значений и разрывом соединения с сервером.
//
// Параметры:
// 	СтрокаСоединения - строка соединения (ConnectionString) с сервером
//  ТекстЗапроса     - текст запроса, который будет выполнен на сервере
// 
// Возвращаемое значение
// 	- Таблица значений, являющаяся результатом выгрузки набора данных, полученного с сервера,
//    если в процессе соединения с сервером, выполнения запроса и выгрузки данных в
//    таблицу значений не возникло ошибок
//  - Неопределено - в противном случае
//
Функция ADODBC_ПолучитьТаблицуДанныхССервера(СтрокаСоединения, ТекстЗапроса, ТипыКолонок = Неопределено, ПараметрыСоединения = Неопределено, ДополнительныеПараметры = Неопределено) Экспорт
	
	Соединение = ADODBC_УстановитьСоединение(СтрокаСоединения, ПараметрыСоединения, ДополнительныеПараметры);
	Если Соединение = Неопределено Тогда
		Возврат Неопределено;
	КонецЕсли;
	
	НаборЗаписей = ADODBC_ВыполнитьЗапрос(Соединение, ТекстЗапроса, ДополнительныеПараметры);
	Если НаборЗаписей = Неопределено Тогда
		Возврат Неопределено;
	КонецЕсли;
	
	ВнешниеДанные = ADODBC_ВыгрузитьНаборВТаблицуЗначений(НаборЗаписей, ТипыКолонок, ДополнительныеПараметры);
	
	ADODBC_ЗакрытьСоединение(Соединение, ДополнительныеПараметры);
	
	Возврат ВнешниеДанные;
	
КонецФункции // ADODBC_ПолучитьТаблицуДанныхССервера

// Создает команду для обращения к хранимой процедуре
//
// Параметры:
// 	Соединение - COM-объект ADODB.Connection
// 
// Возвращаемое значение
// 	- COM-объект ADODB.Command
//
Функция ADODBC_ПолучитьКомандуОбращенияКХранимойПроцедуре(Соединение, ИмяПроцедуры) Экспорт
	
	Command = Новый COMОбъект("ADODB.Command");
	Command.CommandTimeout   = 900;
	Command.ActiveConnection = Соединение;
	Command.CommandText      = ИмяПроцедуры;
	Command.CommandType      = 4; // Хранимая процедура

	Возврат Command;
	
КонецФункции

// Добавляет входящий параметр хранимой процедуры
//
// Параметры:
// 	Соединение - COM-объект ADODB.Command
//	Имя - имя параметра
//  Тип - тип параметра, например 202 = nvarchar
//  ДлинаТипа - например, длина строкового тип
//	Значение  - значение параметра
//	НеДобавлятьПустоеЗначение - если Истина, пустое значение не добавляется
//
// Возвращаемое значение
// 	- Истина - параметр добавлен, иначе Ложь
//
Функция ADODBC_ДобавитьВходнойПараметрКоманды(Command, Имя, Тип, ДлинаТипа, Значение, НеДобавлятьПустоеЗначение = Истина) Экспорт
	
	Если НеДобавлятьПустоеЗначение и Не ЗначениеЗаполнено(Значение) Тогда
		Возврат Ложь;
	КонецЕсли;
	
	Если ТипЗнч(Значение) = Тип("Строка") Тогда
		Command.Parameters.Append(Command.CreateParameter(Имя, Тип, 1, ДлинаТипа, Лев(Значение, ДлинаТипа)));
	Иначе	
		Command.Parameters.Append(Command.CreateParameter(Имя, Тип, 1, ДлинаТипа, Значение));
	КонецЕсли;
	
	Возврат Истина;
	
КонецФункции

// Добавляет исходящий параметр хранимой процедуры
//
// Параметры:
// 	Соединение - COM-объект ADODB.Command
//	Имя - имя параметра
//  Тип - тип параметра, например 202 = nvarchar
//  ДлинаТипа - например, длина строкового типа (-1 для типов с фиксированной длиной)
//	Значение  - значение параметра
//
// Возвращаемое значение
// 	- COM-объект ADODB.Parameter
//
Функция ADODBC_ДобавитьВыходнойПараметрКоманды(Command, Имя, Тип, ДлинаТипа = 0, Значение = NULL) Экспорт
	
	// adParamOutput = 2
	// adParamInputOutput = 3 
	Направление = ?(Значение = NULL, 2, 3);		
	
	Если ТипЗнч(Значение) = Тип("Строка") Тогда
		Parameter = Command.CreateParameter(Имя, Тип, Направление, ДлинаТипа, Лев(Значение, ДлинаТипа));
	Иначе	
		Parameter = Command.CreateParameter(Имя, Тип, Направление, ДлинаТипа, Значение);
	КонецЕсли;
	
	Command.Parameters.Append(Parameter);	
	
	Возврат Parameter;
	
КонецФункции

// Записывает двоичные данные в файл с указанным именем 
//
// Параметры:
//  МассивБайт - COMSafeArray - массив байт
//	ИмяФайла - Строка - Полное имя файла
//
Процедура ADODBC_СохранитьМассивБайтВФайл(МассивБайт, ИмяФайла) Экспорт
	Поток = Новый COMОбъект("ADODB.Stream");
	Поток.Type = 1; // adTypeBinary
	Поток.Open();
	Поток.Write(МассивБайт);
	Поток.SaveToFile(ИмяФайла);
	Поток.Close();
КонецПроцедуры

Функция ADODBC_ВнутренниеКонстанты() Экспорт
	ADODBC_Константы = Новый Структура;
	
	ADODBC_Константы.Вставить("adOpenKeyset",		1);
	ADODBC_Константы.Вставить("adLockOptimistic",	3);
	ADODBC_Константы.Вставить("adExecuteNoRecords",	128);
	ADODBC_Константы.Вставить("adCmdTable",			2);
	
	Возврат ADODBC_Константы;
КонецФункции

////////////////////////////////////////////////////////////////////////////////
// ВЗАИМОДЕЙСТВИЕ С СЭДами СпецДепов
Функция СЭД_ПолучитьСписокАктивныхСчетовДоверительногоУправления(Организация, Период, СЭД, Вариант) Экспорт
	
	Если Вариант = "Выписки" Тогда
	
		Запрос = Новый Запрос;
		Запрос.Текст =
			"ВЫБРАТЬ РАЗРЕШЕННЫЕ РАЗЛИЧНЫЕ
			|	РеестрПлатежей.СчетДоверительногоУправления КАК СчетДоверительногоУправления
			|ИЗ
			|	РегистрСведений.РеестрПлатежей КАК РеестрПлатежей
			|ГДЕ
			|	РеестрПлатежей.ДатаПлатежа МЕЖДУ НАЧАЛОПЕРИОДА(&Период, ДЕНЬ) И КОНЕЦПЕРИОДА(&Период, ДЕНЬ)
			|	И РеестрПлатежей.Организация = &Организация
			|	И (РеестрПлатежей.СчетДоверительногоУправления.ВидДоговораДоверительногоУправления = ЗНАЧЕНИЕ(Перечисление.ВидыДоговоровДоверительногоУправления.УправлениеПенсионнымиНакоплениями)
			|			ИЛИ РеестрПлатежей.СчетДоверительногоУправления.ВидДоговораДоверительногоУправления = ЗНАЧЕНИЕ(Перечисление.ВидыДоговоровДоверительногоУправления.УправлениеПенсионнымиРезервами)
			|			ИЛИ РеестрПлатежей.СчетДоверительногоУправления.ВидДоговораДоверительногоУправления = ЗНАЧЕНИЕ(Перечисление.ВидыДоговоровДоверительногоУправления.УправлениеАктивамиПФР)
			|			ИЛИ РеестрПлатежей.СчетДоверительногоУправления.ВидДоговораДоверительногоУправления = ЗНАЧЕНИЕ(Перечисление.ВидыДоговоровДоверительногоУправления.УправлениеАктивамиСаморегулируемыхОрганизаций)
			|			ИЛИ РеестрПлатежей.СчетДоверительногоУправления.ВидДоговораДоверительногоУправления = ЗНАЧЕНИЕ(Перечисление.ВидыДоговоровДоверительногоУправления.УправлениеРезервамиСтраховыхКомпаний)
			|			ИЛИ РеестрПлатежей.СчетДоверительногоУправления.ВидДоговораДоверительногоУправления = ЗНАЧЕНИЕ(Перечисление.ВидыДоговоровДоверительногоУправления.УправлениеАктивамиАкционерныхИнвестиционныхФондов))
			|	И РеестрПлатежей.СчетДоверительногоУправления.СпециализированныйДепозитарий.СистемаЭлектронногоДокументооборота = &СЭД";
			
		Запрос.УстановитьПараметр("Организация",	Организация);
		Запрос.УстановитьПараметр("Период",			Период);
		Запрос.УстановитьПараметр("СЭД", 			СЭД);
		
		Возврат Запрос.Выполнить().Выгрузить().ВыгрузитьКолонку("СчетДоверительногоУправления");
	
	ИначеЕсли Вариант = "Отчет брокера" Тогда
		
		Запрос = Новый Запрос;
		Запрос.Текст =
			"ВЫБРАТЬ РАЗРЕШЕННЫЕ РАЗЛИЧНЫЕ
			|	ЖурналОперацийБэкОфиса.СчетДоверительногоУправления КАК СчетДоверительногоУправления
			|ИЗ
			|	РегистрСведений.ЖурналОперацийБэкОфиса КАК ЖурналОперацийБэкОфиса
			|ГДЕ
			|	ЖурналОперацийБэкОфиса.Дата МЕЖДУ НАЧАЛОПЕРИОДА(&Период, ДЕНЬ) И КОНЕЦПЕРИОДА(&Период, ДЕНЬ)
			|	И ЖурналОперацийБэкОфиса.Состояние = ЗНАЧЕНИЕ(Перечисление.СостоянияДокументов.Проведен)
			|	И ЖурналОперацийБэкОфиса.Организация = &Организация
			|	И ЖурналОперацийБэкОфиса.Брокер <> ЗНАЧЕНИЕ(Справочник.БрокерскиеКомпании.ПустаяСсылка)
			|	И (ЖурналОперацийБэкОфиса.СчетДоверительногоУправления.ВидДоговораДоверительногоУправления = ЗНАЧЕНИЕ(Перечисление.ВидыДоговоровДоверительногоУправления.УправлениеПенсионнымиНакоплениями)
			|			ИЛИ ЖурналОперацийБэкОфиса.СчетДоверительногоУправления.ВидДоговораДоверительногоУправления = ЗНАЧЕНИЕ(Перечисление.ВидыДоговоровДоверительногоУправления.УправлениеАктивамиПФР)
			|			ИЛИ ЖурналОперацийБэкОфиса.СчетДоверительногоУправления.ВидДоговораДоверительногоУправления = ЗНАЧЕНИЕ(Перечисление.ВидыДоговоровДоверительногоУправления.УправлениеПенсионнымиРезервами)
			|			ИЛИ ЖурналОперацийБэкОфиса.СчетДоверительногоУправления.ВидДоговораДоверительногоУправления = ЗНАЧЕНИЕ(Перечисление.ВидыДоговоровДоверительногоУправления.УправлениеАктивамиСаморегулируемыхОрганизаций)
			|			ИЛИ ЖурналОперацийБэкОфиса.СчетДоверительногоУправления.ВидДоговораДоверительногоУправления = ЗНАЧЕНИЕ(Перечисление.ВидыДоговоровДоверительногоУправления.УправлениеАктивамиАкционерныхИнвестиционныхФондов)
			|			ИЛИ ЖурналОперацийБэкОфиса.СчетДоверительногоУправления.ВидДоговораДоверительногоУправления = ЗНАЧЕНИЕ(Перечисление.ВидыДоговоровДоверительногоУправления.УправлениеРезервамиСтраховыхКомпаний))
			|	И ЖурналОперацийБэкОфиса.СчетДоверительногоУправления.СпециализированныйДепозитарий.СистемаЭлектронногоДокументооборота = &СЭД
			|
			|ОБЪЕДИНИТЬ
			|
			|ВЫБРАТЬ РАЗЛИЧНЫЕ
			|	ОстаткиДенежныхСредств.СчетДоверительногоУправления
			|ИЗ
			|	РегистрНакопления.ОстаткиДенежныхСредств КАК ОстаткиДенежныхСредств
			|ГДЕ
			|	ОстаткиДенежныхСредств.Период МЕЖДУ НАЧАЛОПЕРИОДА(&Период, ДЕНЬ) И КОНЕЦПЕРИОДА(&Период, ДЕНЬ)
			|	И ОстаткиДенежныхСредств.Организация = &Организация
			|	И ОстаткиДенежныхСредств.Активность
			|	И ОстаткиДенежныхСредств.Брокер <> ЗНАЧЕНИЕ(Справочник.БрокерскиеКомпании.ПустаяСсылка)
			|	И (ОстаткиДенежныхСредств.СчетДоверительногоУправления.ВидДоговораДоверительногоУправления = ЗНАЧЕНИЕ(Перечисление.ВидыДоговоровДоверительногоУправления.УправлениеПенсионнымиНакоплениями)
			|			ИЛИ ОстаткиДенежныхСредств.СчетДоверительногоУправления.ВидДоговораДоверительногоУправления = ЗНАЧЕНИЕ(Перечисление.ВидыДоговоровДоверительногоУправления.УправлениеАктивамиПФР)
			|			ИЛИ ОстаткиДенежныхСредств.СчетДоверительногоУправления.ВидДоговораДоверительногоУправления = ЗНАЧЕНИЕ(Перечисление.ВидыДоговоровДоверительногоУправления.УправлениеПенсионнымиРезервами)
			|			ИЛИ ОстаткиДенежныхСредств.СчетДоверительногоУправления.ВидДоговораДоверительногоУправления = ЗНАЧЕНИЕ(Перечисление.ВидыДоговоровДоверительногоУправления.УправлениеАктивамиСаморегулируемыхОрганизаций)
			|			ИЛИ ОстаткиДенежныхСредств.СчетДоверительногоУправления.ВидДоговораДоверительногоУправления = ЗНАЧЕНИЕ(Перечисление.ВидыДоговоровДоверительногоУправления.УправлениеАктивамиАкционерныхИнвестиционныхФондов)
			|			ИЛИ ОстаткиДенежныхСредств.СчетДоверительногоУправления.ВидДоговораДоверительногоУправления = ЗНАЧЕНИЕ(Перечисление.ВидыДоговоровДоверительногоУправления.УправлениеРезервамиСтраховыхКомпаний))
			|	И ОстаткиДенежныхСредств.СчетДоверительногоУправления.СпециализированныйДепозитарий.СистемаЭлектронногоДокументооборота = &СЭД";
			
		Запрос.УстановитьПараметр("Организация",	Организация);
		Запрос.УстановитьПараметр("Период",			Период);
		Запрос.УстановитьПараметр("СЭД", 			СЭД);
		
		Возврат Запрос.Выполнить().Выгрузить().ВыгрузитьКолонку("СчетДоверительногоУправления");
		
	ИначеЕсли Вариант = "МНО" Тогда
		
		Запрос = Новый Запрос;
		Запрос.Текст =
			"ВЫБРАТЬ РАЗРЕШЕННЫЕ РАЗЛИЧНЫЕ
			|	МНО.СчетДоверительногоУправления КАК СчетДоверительногоУправления
			|ИЗ
			|	Документ.МНО КАК МНО
			|ГДЕ
			|	МНО.Дата МЕЖДУ НАЧАЛОПЕРИОДА(&Период, ДЕНЬ) И КОНЕЦПЕРИОДА(&Период, ДЕНЬ)
			|	И МНО.Организация = &Организация
			|	И (МНО.СчетДоверительногоУправления.ВидДоговораДоверительногоУправления = ЗНАЧЕНИЕ(Перечисление.ВидыДоговоровДоверительногоУправления.УправлениеПенсионнымиНакоплениями)
			|			ИЛИ МНО.СчетДоверительногоУправления.ВидДоговораДоверительногоУправления = ЗНАЧЕНИЕ(Перечисление.ВидыДоговоровДоверительногоУправления.УправлениеПенсионнымиРезервами)
			|			ИЛИ МНО.СчетДоверительногоУправления.ВидДоговораДоверительногоУправления = ЗНАЧЕНИЕ(Перечисление.ВидыДоговоровДоверительногоУправления.УправлениеАктивамиПФР)
			|			ИЛИ МНО.СчетДоверительногоУправления.ВидДоговораДоверительногоУправления = ЗНАЧЕНИЕ(Перечисление.ВидыДоговоровДоверительногоУправления.УправлениеАктивамиСаморегулируемыхОрганизаций)
			|			ИЛИ МНО.СчетДоверительногоУправления.ВидДоговораДоверительногоУправления = ЗНАЧЕНИЕ(Перечисление.ВидыДоговоровДоверительногоУправления.УправлениеАктивамиАкционерныхИнвестиционныхФондов)
			|			ИЛИ МНО.СчетДоверительногоУправления.ВидДоговораДоверительногоУправления = ЗНАЧЕНИЕ(Перечисление.ВидыДоговоровДоверительногоУправления.УправлениеРезервамиСтраховыхКомпаний))
			|	И НЕ МНО.ПометкаУдаления
			|	И МНО.СчетДоверительногоУправления.СпециализированныйДепозитарий.СистемаЭлектронногоДокументооборота = &СЭД";
		
		Запрос.УстановитьПараметр("Организация",	Организация);
		Запрос.УстановитьПараметр("Период",      	Период);
		Запрос.УстановитьПараметр("СЭД", 			СЭД);
		
		Возврат Запрос.Выполнить().Выгрузить().ВыгрузитьКолонку("СчетДоверительногоУправления");
		
	ИначеЕсли Вариант = "СЧА" Тогда
		
		Запрос = Новый Запрос;
		Запрос.Текст =
			"ВЫБРАТЬ РАЗРЕШЕННЫЕ РАЗЛИЧНЫЕ
			|	СчетаДоверительногоУправления.Ссылка КАК СчетДоверительногоУправления
			|ИЗ
			|	РегистрСведений.НастройкиУчетаОбщие.СрезПоследних(&Период, ) КАК НастройкиУчетаОбщиеСрезПоследних
			|		ВНУТРЕННЕЕ СОЕДИНЕНИЕ Справочник.СчетаДоверительногоУправления КАК СчетаДоверительногоУправления
			|			ВНУТРЕННЕЕ СОЕДИНЕНИЕ РегистрСведений.ИсполнителиПоЦеннымБумагам КАК ИсполнителиПоЦеннымБумагам
			|			ПО СчетаДоверительногоУправления.Ссылка = ИсполнителиПоЦеннымБумагам.СчетДоверительногоУправления
			|		ПО НастройкиУчетаОбщиеСрезПоследних.СчетДоверительногоУправления = СчетаДоверительногоУправления.Ссылка
			|ГДЕ
			|	СчетаДоверительногоУправления.Организация = &Организация
			|	И СчетаДоверительногоУправления.ВидДоговораДоверительногоУправления В(&СписокВидовДоговоров)
			|	И СчетаДоверительногоУправления.СпециализированныйДепозитарий.СистемаЭлектронногоДокументооборота = &СЭД";
		
		СписокВидовДоговоров = Новый Массив;
		СписокВидовДоговоров.Добавить(Перечисления.ВидыДоговоровДоверительногоУправления.УправлениеПенсионнымиНакоплениями);
		СписокВидовДоговоров.Добавить(Перечисления.ВидыДоговоровДоверительногоУправления.УправлениеПенсионнымиРезервами);
		СписокВидовДоговоров.Добавить(Перечисления.ВидыДоговоровДоверительногоУправления.УправлениеАктивамиПФР);
		
		Запрос.УстановитьПараметр("Организация", 			Организация);
		Запрос.УстановитьПараметр("СписокВидовДоговоров",	СписокВидовДоговоров);
		Запрос.УстановитьПараметр("Период",      			Период);
		Запрос.УстановитьПараметр("СЭД", 					СЭД);
		
		Возврат Запрос.Выполнить().Выгрузить().ВыгрузитьКолонку("СчетДоверительногоУправления");
		
	ИначеЕсли Вариант = "645" Тогда
		
		Запрос = Новый Запрос;
		Запрос.Текст =
			"ВЫБРАТЬ РАЗРЕШЕННЫЕ РАЗЛИЧНЫЕ
			|	СчетаДоверительногоУправления.Ссылка КАК СчетДоверительногоУправления
			|ПОМЕСТИТЬ _СДУ
			|ИЗ
			|	РегистрСведений.НастройкиУчетаОбщие.СрезПоследних(&Период, ) КАК НастройкиУчетаОбщиеСрезПоследних
			|		ВНУТРЕННЕЕ СОЕДИНЕНИЕ Справочник.СчетаДоверительногоУправления КАК СчетаДоверительногоУправления
			|			ВНУТРЕННЕЕ СОЕДИНЕНИЕ РегистрСведений.ИсполнителиПоЦеннымБумагам КАК ИсполнителиПоЦеннымБумагам
			|			ПО СчетаДоверительногоУправления.Ссылка = ИсполнителиПоЦеннымБумагам.СчетДоверительногоУправления
			|		ПО НастройкиУчетаОбщиеСрезПоследних.СчетДоверительногоУправления = СчетаДоверительногоУправления.Ссылка
			|ГДЕ
			|	СчетаДоверительногоУправления.Организация = &Организация
			|	И НастройкиУчетаОбщиеСрезПоследних.ВестиЕдиныйБухгалтерскийУчет
			|	И СчетаДоверительногоУправления.ВидДоговораДоверительногоУправления = &ПенсРезервы
			|	И СчетаДоверительногоУправления.СпециализированныйДепозитарий.СистемаЭлектронногоДокументооборота = ЗНАЧЕНИЕ(Справочник.ВнешниеСистемы.СЭД_ВТБ)
			|
			|ОБЪЕДИНИТЬ ВСЕ
			|
			|ВЫБРАТЬ
			|	СчетаДоверительногоУправления.Ссылка
			|ИЗ
			|	Справочник.СчетаДоверительногоУправления КАК СчетаДоверительногоУправления
			|ГДЕ
			|	СчетаДоверительногоУправления.Ссылка = &САФМАР
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|ВЫБРАТЬ РАЗРЕШЕННЫЕ РАЗЛИЧНЫЕ
			|	_СДУ.СчетДоверительногоУправления КАК СчетДоверительногоУправления
			|ИЗ
			|	_СДУ КАК _СДУ";
		
		Запрос.УстановитьПараметр("САФМАР",			Справочники.СчетаДоверительногоУправления.ПолучитьСсылку(Новый УникальныйИдентификатор("9484d707-9fa2-11e3-92b0-000c2931cdc5")));
		Запрос.УстановитьПараметр("Организация",	Организация);
		Запрос.УстановитьПараметр("ВТБ",			ОбщегоНазначения.ПолучитьИменованныйОбъект("СпецДепозитарий_ВТБ"));
		Запрос.УстановитьПараметр("ПенсРезервы",	Перечисления.ВидыДоговоровДоверительногоУправления.УправлениеПенсионнымиРезервами);
		Запрос.УстановитьПараметр("Период",			Период);
		
		Возврат Запрос.Выполнить().Выгрузить().ВыгрузитьКолонку("СчетДоверительногоУправления");
		
	КонецЕсли;
	
КонецФункции // ПолучитьСписокАктивныхСчетовДоверительногоУправления

////////////////////////////////////////////////////////////////////////////////
// СОХРАНЕНИЕ И ЧТЕНИЕ ФАЙЛОВ ИЗ EXTERNALS

Функция СтрокаСоединенияСExternals() Экспорт
	
	Если ОбщегоНазначения.ЗначениеПараметраСеанса("ЭтоРабочаяИнформационнаяБаза") Тогда
		Возврат "Driver={SQL Server};Server=AP70;UID=Nikolay;PWD=11111;Database=Externals";
	Иначе
		Возврат "Driver={SQL Server};Server=AP69;Database=Externals;Trusted_Connection=Yes";
	КонецЕсли;
	
КонецФункции

// Сохраняет один файл в таблицу Externals
//
//Параметры
//  ИмяФайла - Строка - Краткое имя сохраняемого файла [File_Name]
//  Источник - Число - Истчоник данных [Source_Id]
//  ДвоичныеДанные - ДвоичныеДанные - Файл в формате двоичных данных
//  ВремяЗагрузки - Дата - Время загрузки файла. Если параметр не задан, то будет установлена ТекущаяДата()
//
Процедура СохранитьФайлВExternals(ИмяФайла, Источник, ДвоичныеДанные, ДатаПубликации, ИдентификаторОрганизации, ХешСумма, Соединение = Неопределено) Экспорт
	
	ТаблицаФайлов = ПодготовитьТаблицуСохраненияФайловВExternals();
	
	СтрокаФайлов = ТаблицаФайлов.Добавить();
	СтрокаФайлов.ИмяФайла					= ИмяФайла;
	СтрокаФайлов.Источник					= Источник;
	СтрокаФайлов.ДвоичныеДанные				= ДвоичныеДанные;
	СтрокаФайлов.ИдентификаторОрганизации	= ИдентификаторОрганизации;
	СтрокаФайлов.ДатаПубликации				= ДатаПубликации;
	СтрокаФайлов.ХешСумма					= ХешСумма;
	
	СохранитьМассивФайловВExternals(ТаблицаФайлов, Соединение);
	
КонецПроцедуры

Процедура СохранитьМассивФайловВExternals(ТаблицаФайлов, Соединение = Неопределено) Экспорт
	Если ТаблицаФайлов.Количество() = 0 Тогда
		Возврат;
	КонецЕсли;
	
	Механизм = "РаботаСВнешнимиСистемами.СохранитьМассивФайловВExternals";
	ОписаниеДобавленныхФайлов = Новый Массив;
	Сессия   = РегистрыСведений.СтатистикаРаботыВнутреннихМеханизмов.ЗарегистрироватьНовуюСессию(Механизм);
	
	РазрыватьСоединение = (Соединение = Неопределено);
	Если РазрыватьСоединение Тогда
		Соединение = РаботаСВнешнимиСистемами.ADODBC_УстановитьСоединение(СтрокаСоединенияСExternals());
	КонецЕсли;
	
	КоличествоЗаписей = 0;
	
	RecordSet = Новый COMОбъект("ADODB.RecordSet");
	ВнутренниеКонстанты = ADODBC_ВнутренниеКонстанты();
	// RecordSet.CursorType = adOpenKeyset; RecordSet.LockType = adLockOptimistic;
	RecordSet.Open("Files", Соединение,
		ВнутренниеКонстанты.adOpenKeyset, ВнутренниеКонстанты.adLockOptimistic, ВнутренниеКонстанты.adCmdTable);
	
	Для Каждого СтрокаФайлов Из ТаблицаФайлов Цикл
		Если ПолучитьИдентификаторФайлаВExternals(СтрокаФайлов.Источник, СтрокаФайлов.ИдентификаторОрганизации, СтрокаФайлов.ИмяФайла, СтрокаФайлов.ХешСумма, Соединение) = Неопределено Тогда
			Recordset.AddNew();
			RecordSet.Fields("File_Name").Value 	= СтрокаФайлов.ИмяФайла;
			RecordSet.Fields("File_Data").Value 	= ПолучитьCOMSafeArrayИзДвоичныхДанных(СтрокаФайлов.ДвоичныеДанные);
			RecordSet.Fields("Source_Id").Value 	= СтрокаФайлов.Источник;
			RecordSet.Fields("Organization").Value 	= СтрокаФайлов.ИдентификаторОрганизации;
			RecordSet.Fields("sha256hash").Value 	= СтрокаФайлов.ХешСумма;
			
			Если ЗначениеЗаполнено(СтрокаФайлов.ДатаПубликации) Тогда
				RecordSet.Fields("Publication_Date").Value = СтрокаФайлов.ДатаПубликации;
			КонецЕсли;
			
			Если ЗначениеЗаполнено(СтрокаФайлов.ВремяЗагрузки) Тогда
				RecordSet.Fields("Upload_Time").Value = СтрокаФайлов.ВремяЗагрузки;
			КонецЕсли;
			
			КоличествоЗаписей = КоличествоЗаписей + 1;
			
			ОписаниеФайла = СтрШаблон("Имя файла: %1
				|Источник данных: %2", 
				СтрокаФайлов.ИмяФайла,
				СтрокаФайлов.Источник);
			
			Если ЗначениеЗаполнено(СтрокаФайлов.ИдентификаторОрганизации) Тогда
				Организация = Справочники.Организации.ПолучитьСсылку(Новый УникальныйИдентификатор(СтрокаФайлов.ИдентификаторОрганизации));
				ОписаниеФайла = ОписаниеФайла + Символы.ПС + "Организация: " + Организация;
			КонецЕсли;
			
			ОписаниеДобавленныхФайлов.Добавить(ОписаниеФайла);
		КонецЕсли;
	КонецЦикла;
	
	Если КоличествоЗаписей > 0 Тогда
		Recordset.Update();
		ОписаниеФайлов = СтрСоединить(ОписаниеДобавленныхФайлов, ";" + Символы.ПС);
	Иначе
		ОписаниеФайлов = "Обновление файлов не требуется";
	КонецЕсли;

	Если РазрыватьСоединение Тогда
		РаботаСВнешнимиСистемами.ADODBC_ЗакрытьСоединение(Соединение);
	КонецЕсли;
	
	РегистрыСведений.СтатистикаРаботыВнутреннихМеханизмов.ЗарегистрироватьОкончаниеСессии(Механизм, Сессия, , ОписаниеФайлов);
КонецПроцедуры

Функция ПодготовитьТаблицуСохраненияФайловВExternals() Экспорт
	
	ТаблицаФайлов = Новый ТаблицаЗначений;
	ТаблицаФайлов.Колонки.Добавить("ИмяФайла",					Новый ОписаниеТипов("Строка"));
	ТаблицаФайлов.Колонки.Добавить("Источник",					Новый ОписаниеТипов("Число"));
	ТаблицаФайлов.Колонки.Добавить("ДвоичныеДанные",			Новый ОписаниеТипов("ДвоичныеДанные"));
	ТаблицаФайлов.Колонки.Добавить("ИдентификаторОрганизации",	Новый ОписаниеТипов("Строка"));
	ТаблицаФайлов.Колонки.Добавить("ДатаПубликации",			Новый ОписаниеТипов("Дата"));
	ТаблицаФайлов.Колонки.Добавить("ХешСумма", 					Новый ОписаниеТипов("Строка"));
	ТаблицаФайлов.Колонки.Добавить("ВремяЗагрузки",				Новый ОписаниеТипов("Дата"));
	
	Возврат ТаблицаФайлов;
	
КонецФункции

Функция ПолучитьCOMSafeArrayИзДвоичныхДанных(ДвоичныеДанные) Экспорт
	
#Область МедленныйВариант
	//ЧтениеДанных		= Новый ЧтениеДанных(ДвоичныеДанные);
	//БуферДвоичныхДанных = ЧтениеДанных.ПрочитатьВБуферДвоичныхДанных();
	//
	//Массив = Новый Массив;
	//Для Каждого Байт Из БуферДвоичныхДанных Цикл
	//	Массив.Добавить(Байт);
	//КонецЦикла;
	//
	//Возврат Новый COMSafeArray(Массив, "VT_UI1");
#КонецОбласти
	
	ИмяВременногоФайла = ПолучитьИмяВременногоФайла();
	
	ДвоичныеДанные.Записать(ИмяВременногоФайла);
	
	Поток = Новый COMОбъект("ADODB.Stream");
	Поток.Type = 1; // adTypeBinary
	Поток.Open();
	Поток.LoadFromFile(ИмяВременногоФайла);
	Байты = Поток.Read(-1);
	Поток.Close();
	
	УдалитьФайлы(ИмяВременногоФайла);

	Возврат Байты;
	
КонецФункции

//Возвращает файл в виде двоичных данных по идентификатору из Externals
//
//Параметры
// Идентификатор - Число - Идентификатор файла в Externals [Externals].[dbo].[Files].[Id]
//
Функция ПолучитьФайлИзExternals(Идентификатор) Экспорт
	
	МассивИдентификаторов = Новый Массив;
	МассивИдентификаторов.Добавить(Идентификатор);
	
	ТаблицаФайлов = ПолучитьМассивФайловИзExternals(МассивИдентификаторов);
	
	Если ТаблицаФайлов.Количество() > 0 Тогда
		Возврат ТаблицаФайлов[0].ДвоичныеДанные;
	Иначе
		Возврат Неопределено;
	КонецЕсли;
	
КонецФункции

Функция ПолучитьМассивФайловИзExternals(МассивИдентификаторов) Экспорт
	
	СтрокаСоединения = СтрокаСоединенияСExternals();	
	
	ТаблицаФайлов = Новый ТаблицаЗначений;
	ТаблицаФайлов.Колонки.Добавить("Идентификатор"	, Новый ОписаниеТипов("Число"));
	ТаблицаФайлов.Колонки.Добавить("ДвоичныеДанные"	, Новый ОписаниеТипов("ДвоичныеДанные"));
	
	ТипыКолонок = Новый Структура;
	ТипыКолонок.Вставить("Идентификатор"	, Новый ОписаниеТипов("Число"));
	ТипыКолонок.Вставить("ДвоичныеДанные"	, Новый ОписаниеТипов("ДвоичныеДанные"));
	ТипыКолонок.Вставить("COMSafeArray"		, Новый ОписаниеТипов("COMSafeArray"));
	
	ТекстЗапроса = 
		"SELECT 
		|	[ID] AS Идентификатор,
		|	File_Data AS COMSafeArray
		|FROM
		|	[Externals].[dbo].[Files]
		|Where 
		|	[ID] IN (&Идентификатор)";

	ТекстЗапроса = СтрЗаменить(ТекстЗапроса, "&Идентификатор", СтрЗаменить(СтрСоединить(МассивИдентификаторов, ","), Символы.НПП, ""));
	
	РезультатЗапроса = РаботаСВнешнимиСистемами.ADODBC_ПолучитьТаблицуДанныхССервера(СтрокаСоединения, ТекстЗапроса, ТипыКолонок);
	
	Если РезультатЗапроса <> Неопределено Тогда
		Для Каждого СтрокаРезультата Из РезультатЗапроса Цикл
			
			СтрокаФалов = ТаблицаФайлов.Добавить();
			СтрокаФалов.Идентификатор	= СтрокаРезультата.Идентификатор;
			СтрокаФалов.ДвоичныеДанные	= ПолучитьДвоичныеДанныеИзCOMSafeArray(СтрокаРезультата.COMSafeArray);

		КонецЦикла;
	КонецЕсли;
	
	Возврат ТаблицаФайлов;

КонецФункции

Функция ПолучитьДвоичныеДанныеИзCOMSafeArray(COMSafeArray) Экспорт

#Область МедленныйВариант
	//Массив = COMSafeArray.Выгрузить();
	//Длина = Массив.Количество();
	//
	//Буфер = новый БуферДвоичныхДанных(Длина);
	//Для индекс = 0 по Длина - 1 Цикл
	//	Буфер.Установить(индекс, Массив[индекс]);	
	//КонецЦикла;
	//
	//Поток = новый ПотокВПамяти(Буфер);
	//ДвоичныеДанные = Поток.ЗакрытьИПолучитьДвоичныеДанные();
	//
	//Возврат ДвоичныеДанные;
#КонецОбласти
	
	ИмяВременногоФайла = ПолучитьИмяВременногоФайла();
	
	Поток = Новый COMОбъект("ADODB.Stream");
	Поток.Type = 1; // adTypeBinary
	Поток.Open();
	Поток.Write(COMSafeArray);
	Поток.SaveToFile(ИмяВременногоФайла);
	Поток.Close();
	
	ДвоичныеДанные = Новый ДвоичныеДанные(ИмяВременногоФайла);
	
	УдалитьФайлы(ИмяВременногоФайла);

	Возврат ДвоичныеДанные;
	
КонецФункции

Процедура СохранитьСписокДляСверкиВExternals(Организация, ИдентификаторСписка, ДатаПубликации, МассивСтрок, Знач ДанныеФайла) Экспорт
	
	Если ТипЗнч(Организация) = Тип("СправочникСсылка.Организации") Тогда
		ИдентификаторОрганизации = Строка(Организация.УникальныйИдентификатор());
	Иначе
		ИдентификаторОрганизации = Организация;
	КонецЕсли;
	
	Соединение = РаботаСВнешнимиСистемами.ADODBC_УстановитьСоединение(СтрокаСоединенияСExternals());
	Соединение.BeginTrans();
	
	ХешСумма = УниверсальныеМеханизмы.ПолучитьКонтрольнуюСуммуДвоичныхДанных(ДанныеФайла.ДвоичныеДанные, ХешФункция.SHA256);
	
	Если НРег(ДанныеФайла.Расширение) <> ".zip" Тогда
		ДанныеФайла = РаботаСФайламиКлиентСервер.ПоместитьДвоичныеДанныеВАрхив(ДанныеФайла);
	КонецЕсли;
	
	СохранитьФайлВExternals(ДанныеФайла.Имя, ИдентификаторСписка, ДанныеФайла.ДвоичныеДанные, ДатаПубликации, ИдентификаторОрганизации, ХешСумма, Соединение); 
	
	File_Id = ПолучитьИдентификаторФайлаВExternals(ИдентификаторСписка, ИдентификаторОрганизации, ДанныеФайла.Имя, ХешСумма, Соединение);

#Область УдалениеДанныхЗаПериод
	ТекстЗапроса = 
		"DELETE FROM Externals.dbo.RefusalList
		|WHERE 
		|	Period = CONVERT(datetime, '&Период')
		|	AND Source_Id = &Source_Id
		|	AND Organization = '&Organization'";
	
	ТекстЗапроса = СтрЗаменить(ТекстЗапроса, "&Период"		, Формат(ДатаПубликации, "ДФ='yyyyMMdd HH:mm:ss'"));
	ТекстЗапроса = СтрЗаменить(ТекстЗапроса, "&Source_Id"	, ИдентификаторСписка);
	ТекстЗапроса = СтрЗаменить(ТекстЗапроса, "&Organization", ИдентификаторОрганизации);
	
	Соединение.Execute(ТекстЗапроса);
#КонецОбласти

#Область ЗаписьДанных
	Запрос = Новый COMОбъект("ADODB.Command");
	Запрос.CommandText = 
		"INSERT INTO Externals.dbo.RefusalList
		|	([File_Id],[Source_Id],[Organization],[Is_Firm],[Name],[LastName],[FirstName],[MiddleName],[BirthDate],[RegistrationNumber],[INN],[Period],[LegalAddress],[PlaceOfBirth],[Name_Clean],[LastName_Clean],[FirstName_Clean],[MiddleName_Clean])
		|VALUES
		|	(?, ?, ?, CONVERT(Bit, ?), ?, ?, ?, ?, CONVERT(datetime, ?), ?, ?, CONVERT(datetime, ?), ?, ?, dbo.RemoveExtraChar(?), dbo.RemoveExtraChar(?), dbo.RemoveExtraChar(?), dbo.RemoveExtraChar(?))";
	
	Запрос.CommandType		= 1;
	Запрос.Prepared			= "True";
	Запрос.NamedParameters	= "True";
	Запрос.Parameters.Append(Запрос.CreateParameter("@File_Id"				, 20	, 1, 10));
	Запрос.Parameters.Append(Запрос.CreateParameter("@Source_Id"			, 20	, 1, 10));
	Запрос.Parameters.Append(Запрос.CreateParameter("@Organization"			, 200	, 1, 36));
																							   
	Запрос.Parameters.Append(Запрос.CreateParameter("@Is_Firm"				, 3		, 1, 1));
	Запрос.Parameters.Append(Запрос.CreateParameter("@Name"					, 201	, 1, 4000));
	Запрос.Parameters.Append(Запрос.CreateParameter("@LastName"				, 200	, 1, 500));
	Запрос.Parameters.Append(Запрос.CreateParameter("@FirstName"			, 200	, 1, 100));
	Запрос.Parameters.Append(Запрос.CreateParameter("@MiddleName"			, 200	, 1, 100));
	Запрос.Parameters.Append(Запрос.CreateParameter("@BirthDate"			, 135	, 1, 8));
	Запрос.Parameters.Append(Запрос.CreateParameter("@RegistrationNumber"	, 200	, 1, 50));
	Запрос.Parameters.Append(Запрос.CreateParameter("@INN"					, 200	, 1, 50));
	Запрос.Parameters.Append(Запрос.CreateParameter("@Period"				, 135	, 1, 8));
	Запрос.Parameters.Append(Запрос.CreateParameter("@LegalAddress"			, 200	, 1, 1023));
	Запрос.Parameters.Append(Запрос.CreateParameter("@PlaceOfBirth"			, 200	, 1, 500));
	Запрос.Parameters.Append(Запрос.CreateParameter("@Name_Clean"			, 201	, 1, 4000));
	Запрос.Parameters.Append(Запрос.CreateParameter("@LastName_Clean"		, 200	, 1, 500));
	Запрос.Parameters.Append(Запрос.CreateParameter("@FirstName_Clean"		, 200	, 1, 100));
	Запрос.Parameters.Append(Запрос.CreateParameter("@MiddleName_Clean"		, 200	, 1, 100));
	
	Запрос.ActiveConnection = Соединение;
	
	Для Каждого СтрокаДанных Из МассивСтрок Цикл
		Запрос.Parameters("@File_Id").Value				= File_Id;
		Запрос.Parameters("@Source_Id").Value			= ИдентификаторСписка;
		Запрос.Parameters("@Organization").Value		= ИдентификаторОрганизации;
																														 
		Запрос.Parameters("@Is_Firm").Value				= СтрокаДанных.Is_Firm;
		Запрос.Parameters("@Name").Value				= СтрокаДанных.Name;
		Запрос.Parameters("@LastName").Value			= СтрокаДанных.LastName;
		Запрос.Parameters("@FirstName").Value			= СтрокаДанных.FirstName;
		Запрос.Parameters("@MiddleName").Value			= СтрокаДанных.MiddleName;
		Запрос.Parameters("@BirthDate").Value			= СтрокаДанных.BirthDate; 
		Запрос.Parameters("@RegistrationNumber").Value	= СтрокаДанных.RegistrationNumber;
		Запрос.Parameters("@INN").Value					= СтрокаДанных.INN;
		Запрос.Parameters("@Period").Value				= СтрокаДанных.Period; 
		Запрос.Parameters("@LegalAddress").Value		= СтрокаДанных.LegalAddress;
		Запрос.Parameters("@PlaceOfBirth").Value		= СтрокаДанных.PlaceOfBirth;
		
		Запрос.Parameters("@Name_Clean").Value			= СтрокаДанных.Name;
		Запрос.Parameters("@LastName_Clean").Value		= СтрокаДанных.LastName;
		Запрос.Parameters("@FirstName_Clean").Value		= СтрокаДанных.FirstName;
		Запрос.Parameters("@MiddleName_Clean").Value	= СтрокаДанных.MiddleName;
		
		Запрос.Execute();
	КонецЦикла;	
#КонецОбласти

	Соединение.CommitTrans();
	РаботаСВнешнимиСистемами.ADODBC_ЗакрытьСоединение(Соединение);
	
КонецПроцедуры

Функция ПолучитьИдентификаторФайлаВExternals(ИдентификаторИсточника, ИдентификаторОрганизации, ИмяФайла, ХешСумма, Соединение = Неопределено) Экспорт
	
	РазрыватьСоединение = (Соединение = Неопределено);
	Если РазрыватьСоединение Тогда
		Соединение = РаботаСВнешнимиСистемами.ADODBC_УстановитьСоединение(СтрокаСоединенияСExternals());
	КонецЕсли;
	
	ТекстЗапроса =
		"SELECT TOP (1) 
		|	Id
		|FROM 
		|	Externals.dbo.Files
		|Where 
		|	File_Name = '&ИмяФайла'
		|	AND Source_Id = '&Source_Id'
		|	AND Organization = '&Organization'
		|	AND sha256hash = '&sha256hash'
		|ORDER BY
		|	Files.Upload_Time desc";
	
	ТекстЗапроса = СтрЗаменить(ТекстЗапроса, "&ИмяФайла"	, ИмяФайла);
	ТекстЗапроса = СтрЗаменить(ТекстЗапроса, "&Source_Id"	, ИдентификаторИсточника);
	ТекстЗапроса = СтрЗаменить(ТекстЗапроса, "&Organization", ИдентификаторОрганизации);
	ТекстЗапроса = СтрЗаменить(ТекстЗапроса, "&sha256hash"	, ХешСумма);
	
	НаборЗаписей = Соединение.Execute(ТекстЗапроса);
	
	File_Id = Неопределено;
	
	Если НЕ (НаборЗаписей.EOF И НаборЗаписей.BOF) Тогда
		НаборЗаписей.MoveFirst();
		File_Id = НаборЗаписей.Fields.Item(0).Value;
	КонецЕсли;
	
	НаборЗаписей = "";
	
	Если РазрыватьСоединение Тогда
		РаботаСВнешнимиСистемами.ADODBC_ЗакрытьСоединение(Соединение);
	КонецЕсли;
	
	Возврат File_Id;
	
КонецФункции

////////////////////////////////////////////////////////////////////////////////
// ЧТЕНИЕ ФАЙЛОВ ИЗ XBRL Editor (XE © Artyukhin)

Функция СтрокаСоединенияСXE() Экспорт
	
	Возврат "Driver={SQL Server};Server=AP63;UID=svc_API_AM;PWD=p8z4gr39VAxXAfhn;Database=XE"
	
КонецФункции

Функция ПолучитьТаблицуФайловИзXE(Соединение, ВерсияТаксономии = "", ТочкаВхода = "", ОГРН = "", Дата = Неопределено, СписокРазделов = "", УсловиеОтбора = "", ВключатьСодержимоеФайла = Ложь) Экспорт
	
	ТекстЗапроса = 
		"SELECT 
		|	ID AS ИндентификаторОтчета,
		|	Taxonomy_Version AS ВерсияТаксономии,
		|	Entry_Point_Code AS ТочкаВхода,
		|	Firm_Code AS ОГРН,
		|	Date_From AS ДатаНачала,
		|	Date_To AS ДатаОкончания,
		|	[File_Name] AS ИмяФайла,
		|	--[File_Data] AS ДанныеXML,
		|	CAST(Load_Date AS datetime)  AS ДатаЗагрузки,
		|	[Description] AS Примечание,
		|	Forms AS РазделыОтчета
		|FROM 
		|	API_AM.udf_Get_Instances(&ВерсияТаксономии, &ТочкаВхода, &ОГРН, &Дата, &СписокРазделов)";
	
	ТекстЗапроса = СтрЗаменить(ТекстЗапроса, "&ВерсияТаксономии",	?(ПустаяСтрока(ВерсияТаксономии),	"null", "'" + СтрЗаменить(ВерсияТаксономии, "_", ".") + "'"));
	ТекстЗапроса = СтрЗаменить(ТекстЗапроса, "&ТочкаВхода",			?(ПустаяСтрока(ТочкаВхода), 		"null", "'" + ТочкаВхода + "'"));
	ТекстЗапроса = СтрЗаменить(ТекстЗапроса, "&ОГРН",				?(ПустаяСтрока(ОГРН), 				"null", "'" + ОГРН + "'"));
	ТекстЗапроса = СтрЗаменить(ТекстЗапроса, "&Дата",				?(ПустаяСтрока(Дата), 				"null", "'" + Формат(Дата, "ДФ=yyyyMMdd") + "'"));
	ТекстЗапроса = СтрЗаменить(ТекстЗапроса, "&СписокРазделов",		?(ПустаяСтрока(СписокРазделов), 	"null", "'" + СписокРазделов + "'"));
	
	Если  ЗначениеЗаполнено(УсловиеОтбора) Тогда
		ТекстЗапроса = ТекстЗапроса + "
			|WHERE
			|	" + УсловиеОтбора;
	КонецЕсли;
	
	Если ВключатьСодержимоеФайла Тогда
		ТекстЗапроса = СтрЗаменить(ТекстЗапроса, "--[File_Data]", "[File_Data]");
	КонецЕсли;
	
	ТипыКолонок = Новый Структура;
	ТипыКолонок.Вставить("ИндентификаторОтчета",	Новый ОписаниеТипов("Число"));
	ТипыКолонок.Вставить("ВерсияТаксономии", 		Новый ОписаниеТипов("Строка"));
	ТипыКолонок.Вставить("ТочкаВхода", 				Новый ОписаниеТипов("Строка"));
	ТипыКолонок.Вставить("ОГРН", 					Новый ОписаниеТипов("Строка"));
	ТипыКолонок.Вставить("ДатаНачала", 				Новый ОписаниеТипов("Дата"));
	ТипыКолонок.Вставить("ДатаОкончания",			Новый ОписаниеТипов("Дата"));
	ТипыКолонок.Вставить("ИмяФайла", 				Новый ОписаниеТипов("Строка"));
	ТипыКолонок.Вставить("ДатаЗагрузки", 			Новый ОписаниеТипов("Дата", Новый КвалификаторыДаты(ЧастиДаты.ДатаВремя)));
	ТипыКолонок.Вставить("ДанныеXML", 				Новый ОписаниеТипов("Строка"));
	ТипыКолонок.Вставить("Примечание", 				Новый ОписаниеТипов("Строка"));
	ТипыКолонок.Вставить("РазделыОтчета", 			Новый ОписаниеТипов("Строка"));
	
	ДополнительныеПараметры = Новый Структура("ВозвращатьПустуюТаблицу", Истина);
	
	Возврат ADODBC_ВыгрузитьНаборВТаблицуЗначений(ADODBC_ВыполнитьЗапрос(Соединение, ТекстЗапроса, ДополнительныеПараметры), ТипыКолонок, ДополнительныеПараметры);
	
КонецФункции

Функция ТаблицаВложенийИзXE(Соединение, ИдентификаторыОтчетов) Экспорт
	
	ТекстЗапроса = 
		"SELECT
       	|	*
		|FROM API_AM.udf_Get_Instances_Attachments('&ИдентификаторыОтчетов')";
	
	ТекстЗапроса = СтрЗаменить(ТекстЗапроса, "&ИдентификаторыОтчетов", ИдентификаторыОтчетов);
	
	ТипыКолонок = Новый Структура;
	ТипыКолонок.Вставить("ID",	        Новый ОписаниеТипов("Число"));
	ТипыКолонок.Вставить("Instance_ID", Новый ОписаниеТипов("Число"));
	ТипыКолонок.Вставить("File_Path", 	Новый ОписаниеТипов("Строка"));
	ТипыКолонок.Вставить("Description", Новый ОписаниеТипов("Строка"));
	
	ДополнительныеПараметры = Новый Структура("ВозвращатьПустуюТаблицу", Истина);
	
	Возврат ADODBC_ВыгрузитьНаборВТаблицуЗначений(ADODBC_ВыполнитьЗапрос(Соединение, ТекстЗапроса, ДополнительныеПараметры), ТипыКолонок, ДополнительныеПараметры);
	
КонецФункции

////////////////////////////////////////////////////////////////////////////////
// НАСТРОЙКИ ЗАГРУЗКИ ОПЕРАЦИЙ БРОКЕРА БК РЕГИОН

Функция ИмпортРазделенПоОчередям(Организация) Экспорт
	
	Запрос = Новый Запрос("ВЫБРАТЬ РАЗРЕШЕННЫЕ
		|	ЗначенияДополнительныхСведений.Значение
		|ИЗ
		|	РегистрСведений.ЗначенияДополнительныхСведений КАК ЗначенияДополнительныхСведений
		|ГДЕ
		|	ЗначенияДополнительныхСведений.Объект = &Объект
		|	И ЗначенияДополнительныхСведений.Свойство.Ключ = &Ключ");
		
	Запрос.УстановитьПараметр("Объект", Организация);
	Запрос.УстановитьПараметр("Ключ",   "ИмпортРазделенПоОчередям");
	
	Выборка = Запрос.Выполнить().Выбрать();
	
	Если Выборка.Следующий() Тогда		
		Возврат Выборка.Значение;	
	КонецЕсли;
	
	Возврат Ложь;
	
КонецФункции

Функция ПолучитьВидыДоговорДоверительногоУправленияДляОчереди(Организация, Очередь) Экспорт
	
	Если Организация <> ОбщегоНазначения.ПолучитьИменованныйОбъект("Организация_РПИ") Тогда
		ВызватьИсключение "Не определены очереди загрузки для : " + Строка(Организация);
	КонецЕсли;
		
	СписокВидовДоговоровПервойОчереди = Новый Массив();
		
	СписокВидовДоговоровПервойОчереди.Добавить(Перечисления.ВидыДоговоровДоверительногоУправления.УправлениеАктивамиЮридическогоЛица);
	СписокВидовДоговоровПервойОчереди.Добавить(Перечисления.ВидыДоговоровДоверительногоУправления.Собственный);
	
	Если Очередь = 1 Тогда
		
		Возврат СписокВидовДоговоровПервойОчереди;
		
	ИначеЕсли Очередь = 2 Тогда		
		
		СписокВидовДоговоровВторойОчереди  = Новый Массив();
		
		Для Каждого ЗначениеПеречисление ИЗ Перечисления.ВидыДоговоровДоверительногоУправления Цикл
			Если СписокВидовДоговоровПервойОчереди.Найти(ЗначениеПеречисление) = Неопределено Тогда
				СписокВидовДоговоровВторойОчереди.Добавить(ЗначениеПеречисление);
			КонецЕсли;						
		КонецЦикла;
		
		Возврат СписокВидовДоговоровВторойОчереди;
		
	Иначе
		ВызватьИсключение "Не определены виды договоров для очерди: " + Строка(Очередь);		
	КонецЕсли;
		
КонецФункции

Функция КоличествоОчередейОрганизации(Организация) Экспорт
	
	Если Организация = ОбщегоНазначения.ПолучитьИменованныйОбъект("Организация_РПИ") Тогда
		Возврат 2;
	Иначе
		Возврат 1;
	КонецЕсли;
		
КонецФункции

#Область Подключение_к_EGAR

Функция EGAR_ПолучитьПараметрыПодключения(Сервер) Экспорт
	
	ПараметрыПодключения = Новый Структура; 
		
	Если Найти(Сервер, "АП91") > 0 Тогда //тестовый
		
		СерверHTTP 	        = "ap91.g1.lan";
		Порт				= 8120;
		URL				    = "/elm_am/api/v1/";
		ПараметрыПодключения.Вставить("СтрокаСоединенияSQL", "Driver={SQL Server};Server=AP91.G1.LAN;UID=link_1C;PWD=12345;Database=ELM_AM");
		
	ИначеЕсли Найти(Сервер, "АП55") > 0 Тогда //боевой
		
	    СерверHTTP 	        = "ap55.g1.lan";
		Порт				= 8000;
		URL				    = "/elm_ram/api/v1/";
		ПараметрыПодключения.Вставить("СтрокаСоединенияSQL", "Driver={SQL Server};Server=AP55.G1.LAN;UID=link_1C;PWD=EGAR_3;Database=ELM_ram");
		
	Иначе
		Возврат "Не обнаружены параметры подключения к серверу " + Сервер;
	КонецЕсли;
	
	Заголовки = Новый Соответствие(); 
	Заголовки.Вставить("Content-Type", "application/json");
	Заголовки.Вставить("Connection", "Keep-Alive");

	//HTTP 
	ПараметрыПодключения.Вставить("СоединениеHTTP",   Новый HTTPСоединение(СерверHTTP, Порт, "egar-user", "EgarEgar",,,, Ложь));
    ПараметрыПодключения.Вставить("ЗаголовкиHTTP",    Заголовки);
	ПараметрыПодключения.Вставить("Portfolios",       URL + "data/portfolios"); //Адрес справочника
	ПараметрыПодключения.Вставить("Trades",           URL + "data/trades?limits=false&synchronous=false&preprocess=false&priority=0"); //Таблица сделок
	ПараметрыПодключения.Вставить("Limits",           URL + "limits?useExternalIds=true&removeExistingFilters=true"); // Таблица лимитов
	ПараметрыПодключения.Вставить("AccountingPrices", URL + "data/accountingprices"); // Таблица предварительных цен
	ПараметрыПодключения.Вставить("Bonds_htm",        URL + "data/bonds_htm"); // Таблица бумаг удерживаемых до погашения

	ТекстСообщения = "";

	HTTPОтвет = HTTP_ВыполнитьЗапрос("GET", ПараметрыПодключения, URL + "me",, ТекстСообщения);
	
	Если HTTPОтвет = Неопределено Тогда
		Возврат ТекстСообщения;		
	Иначе
		
		CookieArray = СтрРазделить(HTTPОтвет.Заголовки.Получить("Set-Cookie"),";");
		
		ПараметрыПодключения.ЗаголовкиHTTP.Вставить("Cookie", CookieArray[0]);

		Возврат ПараметрыПодключения;
		
	КонецЕсли;
		
КонецФункции

Функция EGAR_ОрганизацииДляВыгрузки() Экспорт

	МассивОрганизаций = Новый Массив;
	МассивОрганизаций.Добавить(ОбщегоНазначения.ПолучитьИменованныйОбъект("Организация_РЭМ"));
	МассивОрганизаций.Добавить(ОбщегоНазначения.ПолучитьИменованныйОбъект("Организация_ТрастМ"));
	Возврат МассивОрганизаций;

КонецФункции

#КонецОбласти

#Область Подключение_к_Первой_Форме

Функция ПерваяФорма_ПолучитьПараметрыПодключения(Сервер, Порт = 443, Логин = "", Пароль = "") Экспорт	
	
	Если Сервер = "1f.g1.lan" Или Сервер = "test1f.g1.lan" Тогда //основная
		
		Логин = ?(Логин = "", "UK_UFO_Robot", Логин);
		Пароль = ?(Пароль = "", "UK_UFO_Robot", Пароль);  
		
	ИначеЕсли Сервер = "uk1f" Тогда //колл центр.
		
		Логин = ?(Логин = "", "robot", Логин);
		Пароль = ?(Пароль = "", "NrfSwGNs6hcgX2uXA390", Пароль);
		Сервер = ?(ПараметрыСеанса.ЭтоРабочаяИнформационнаяБаза, Сервер, "devuk1f") + ".region.ru";
		
	Иначе	
		ОбработатьОшибку("Отсутствуют настройки подключения к серверу [" + Сервер + "]", "РаботаСВнешнимиСистемами.ПерваяФорма_ПолучитьПараметрыПодключения()");
		Возврат Неопределено;
	КонецЕсли; 
				
	ПараметрыПодключения = Новый Структура("СоединениеHTTP, ЗаголовкиHTTP", Новый HTTPСоединение(Сервер, Порт,,,,, Новый ЗащищенноеСоединениеOpenSSL()), Новый Соответствие);
	ПараметрыПодключения.ЗаголовкиHTTP.Вставить("Content-type", "application/json");
		
	ЗаписьJSON = Новый ЗаписьJSON;
	ЗаписьJSON.УстановитьСтроку(Новый ПараметрыЗаписиJSON(ПереносСтрокJSON.Нет));	
	ЗаписатьJSON(ЗаписьJSON, Новый Структура("login, password", Логин, Пароль));
	
    ТелоЗапроса = ЗаписьJSON.Закрыть();
	
	ТекстСообщения = "Не удалось установить соединение с 1-ой Формой! Сервер [" + Сервер + "]"; 
	
	HTTPОтвет = HTTP_ВыполнитьЗапрос("POST", ПараметрыПодключения, "/api/auth/token-v2", ТелоЗапроса, ТекстСообщения);
	
	Если HTTPОтвет = Неопределено Тогда
		
		ОбработатьОшибку(ТекстСообщения, "РаботаСВнешнимиСистемами.ПерваяФорма_ПолучитьПараметрыПодключения()");
		Возврат Неопределено;
		
	Иначе
		
		СтрокаJSON = HTTPОтвет.ПолучитьТелоКакСтроку("UTF-8");
		
		ЧтениеJSON = Новый ЧтениеJSON();
    	ЧтениеJSON.УстановитьСтроку(СтрокаJSON);
    	ОтветОбъект = ПрочитатьJSON(ЧтениеJSON);
				
		ПараметрыПодключения.ЗаголовкиHTTP.Вставить("Cookie", "1FormaAuth=" + ОтветОбъект.data.accessToken);
		
		Возврат ПараметрыПодключения;
	
	КонецЕсли;

КонецФункции 

#КонецОбласти

#Область HTTP
	
Функция HTTP_ВыполнитьЗапрос(ИмяМетода, ПараметрыПодключения, ТекстЗапроса, ТелоЗапроса = "", ТекстСообщения = "", КоличествоПопыток = 3) Экспорт 
	
	КоличествоПопыток = ?(ПараметрыСеанса.ЭтоРабочаяИнформационнаяБаза, КоличествоПопыток, 1); 

	Запрос = Новый HTTPЗапрос(ТекстЗапроса, ПараметрыПодключения.ЗаголовкиHTTP); 
		
	Если ЗначениеЗаполнено(ТелоЗапроса) Тогда
		
		Если ТипЗнч(ТелоЗапроса) = Тип("Строка") Тогда
			Запрос.УстановитьТелоИзСтроки(ТелоЗапроса, "UTF-8", ИспользованиеByteOrderMark.НеИспользовать);
		ИначеЕсли ТипЗнч(ТелоЗапроса) = Тип("ДвоичныеДанные") Тогда
			Запрос.УстановитьТелоИзДвоичныхДанных(ТелоЗапроса);	
		КонецЕсли;
		
	КонецЕсли;
	
	Для НомерПопытки = 1 По КоличествоПопыток Цикл
		
		ЗафиксироватьОшибку = (НомерПопытки = КоличествоПопыток);
		
		Попытка
			
			Если ИмяМетода = "PUT" Тогда
            	HTTPОтвет = ПараметрыПодключения.СоединениеHTTP.Записать(Запрос);
			ИначеЕсли ИмяМетода = "GET" Тогда
				HTTPОтвет = ПараметрыПодключения.СоединениеHTTP.Получить(Запрос);
			ИначеЕсли ИмяМетода = "POST" Тогда
				HTTPОтвет = ПараметрыПодключения.СоединениеHTTP.ОтправитьДляОбработки(Запрос);
			ИначеЕсли ИмяМетода = "PATCH" Тогда
				HTTPОтвет = ПараметрыПодключения.СоединениеHTTP.Изменить(Запрос);	
			ИначеЕсли ИмяМетода = "DELETE" Тогда
				HTTPОтвет = ПараметрыПодключения.СоединениеHTTP.Удалить(Запрос);	
			КонецЕсли;
			
			Если HTTPОтвет.КодСостояния >= 200 И HTTPОтвет.КодСостояния <= 299 Тогда
				Возврат HTTPОтвет;
			Иначе
				HTTP_ОбработкаОшибкиЗапроса(ЗафиксироватьОшибку, ТекстСообщения, "Код ошибки: " + HTTPОтвет.КодСостояния + Символы.ПС + ". Текст ошибки: " + HTTPОтвет.ПолучитьТелоКакСтроку("UTF-8"));	
			КонецЕсли;
			
		Исключение
			
			HTTP_ОбработкаОшибкиЗапроса(ЗафиксироватьОшибку, ТекстСообщения, ОписаниеОшибки());
	
		КонецПопытки;
		
	КонецЦикла;
	
	Возврат Неопределено;
		
КонецФункции

Процедура HTTP_ОбработкаОшибкиЗапроса(ЗафиксироватьОшибку, ТекстСообщения, ОписаниеОшибки)

	Если ЗафиксироватьОшибку Тогда
		ТекстСообщения = ТекстСообщения + ?(Прав(ТекстСообщения, 1) = ".", " ", ". ") + ОписаниеОшибки;
	Иначе
		ЗапуститьПриложение("Timeout /T 5 /NoBreak",, Истина); // ждем 5 сек
	КонецЕсли;

КонецПроцедуры

#КонецОбласти

#Область Инициализация_параметров_внешних_источников

Процедура ПодключитьсяКВнешнемуИсточникуAssetManagementArchive() Экспорт
	ВнешнийИсточник = ВнешниеИсточникиДанных.AssetManagementArchive;
	
	// Описание параметров подключения
	ПараметрыСоединения = Новый ПараметрыСоединенияВнешнегоИсточникаДанных;
	ПараметрыСоединения.СУБД             = "MSSQLServer";
	ПараметрыСоединения.АутентификацияОС = Ложь;
	ПараметрыСоединения.ИмяПользователя  = "Nikolay";
	ПараметрыСоединения.Пароль           = "11111";
	
	Если ПараметрыСеанса.ЭтоРабочаяИнформационнаяБаза Тогда
		ПараметрыСоединения.СтрокаСоединения = "DRIVER={SQL Server};Server=AP70;Database=AssetManagementArchive;";
	Иначе
		ПараметрыСоединения.СтрокаСоединения = "DRIVER={SQL Server};Server=AP69;Database=AssetManagementArchive;";
	КонецЕсли;
	
	// Параметры соединения кэшируются. Всегда требуется повторная установка, если меняются параметры авторизации
	ВнешнийИсточник.УстановитьОбщиеПараметрыСоединения(ПараметрыСоединения);
	ВнешнийИсточник.УстановитьПараметрыСоединенияПользователя(ИмяПользователя(), ПараметрыСоединения);
	ВнешнийИсточник.УстановитьПараметрыСоединенияСеанса(ПараметрыСоединения);
	
	// Выполняем авторизацию
	ВнешнийИсточник.УстановитьСоединение();
КонецПроцедуры

Процедура ПодключитьсяКВнешнемуИсточникуRiskControl() Экспорт
	ВнешнийИсточник = ВнешниеИсточникиДанных.RiskControl;
	
	// Описание параметров подключения
	ПараметрыСоединения = Новый ПараметрыСоединенияВнешнегоИсточникаДанных;
	ПараметрыСоединения.СУБД             = "MSSQLServer";
	ПараметрыСоединения.АутентификацияОС = Ложь;
	ПараметрыСоединения.ИмяПользователя  = "Git";
	ПараметрыСоединения.Пароль           = "HNfc^t19";
	
	Если ПараметрыСеанса.ЭтоРабочаяИнформационнаяБаза Тогда
		ПараметрыСоединения.СтрокаСоединения = "DRIVER={SQL Server};Server=AP18.G1.LAN;Database=ais_warehouse;";
	Иначе
		ПараметрыСоединения.СтрокаСоединения = "DRIVER={SQL Server};Server=AP18.G1.LAN;Database=ais_warehouse_dev;";
	КонецЕсли;
	
	// Параметры соединения кэшируются. Всегда требуется повторная установка, если меняются параметры авторизации
	ВнешнийИсточник.УстановитьОбщиеПараметрыСоединения(ПараметрыСоединения);
	ВнешнийИсточник.УстановитьПараметрыСоединенияПользователя(ИмяПользователя(), ПараметрыСоединения);
	ВнешнийИсточник.УстановитьПараметрыСоединенияСеанса(ПараметрыСоединения);
	
	// Выполняем авторизацию
	ВнешнийИсточник.УстановитьСоединение();
КонецПроцедуры

Процедура ПодключитьсяКВнешнемуИсточникуMatrixMigration() Экспорт
	ВнешнийИсточник = ВнешниеИсточникиДанных.MatrixMigration;
	
	// Описание параметров подключения
	ПараметрыСоединения = Новый ПараметрыСоединенияВнешнегоИсточникаДанных;
	ПараметрыСоединения.СУБД             = "MSSQLServer";
	ПараметрыСоединения.АутентификацияОС = Ложь;
	ПараметрыСоединения.ИмяПользователя  = "svc_API_AM";
	ПараметрыСоединения.Пароль           = "p8z4gr39VAxXAfhn";
	ПараметрыСоединения.СтрокаСоединения = "DRIVER={SQL Server};Server=AP21.G1.LAN;Database=Migration;";
	
	// Параметры соединения кэшируются. Всегда требуется повторная установка, если меняются параметры авторизации
	ВнешнийИсточник.УстановитьОбщиеПараметрыСоединения(ПараметрыСоединения);
	ВнешнийИсточник.УстановитьПараметрыСоединенияПользователя(ИмяПользователя(), ПараметрыСоединения);
	ВнешнийИсточник.УстановитьПараметрыСоединенияСеанса(ПараметрыСоединения);
	
	// Выполняем авторизацию
	ВнешнийИсточник.УстановитьСоединение();
КонецПроцедуры

#КонецОбласти

// Функция - Возвращает результаты сверки физ. лиц со списком дисквалифицированных лиц
// 
// Параметры:
//	ПроверяемыеЛица	 - Массив - (Необязательный) Содержит массив проверяемых физ. лиц
//						Если не указан, проводится сверка по полному списку должностных лиц
// 
// Возвращаемое значение:
//	ТаблицаЗначений, Неопределено - таблица успешно прошедших проверку лиц, Неопределено - в случае ошибки
//									Структура таблицы: ЮрФизЛицо (СправочникСсылка.ЮрФизЛица), Пройдена (Булево), Комментарий (Строка)
//
//
Функция ПолучитьРезультатСверкиСоСпискомДисквалифицированныхЛиц(Организация, Период, ПроверяемыеЛица = Неопределено) Экспорт	
	
	Перем ПроверенныеЛица; 	

#Область ДолжностныеЛица

	МВТ = Новый МенеджерВременныхТаблиц;
	
	РегистрыСведений.ВнутренниеПеречни.ЗаполнитьДолжностныеЛица(МВТ, Организация, Период, ПроверяемыеЛица);
	
	ПроверенныеЛица = МВТ.Таблицы.Найти("_ДолжностныеЛица").ПолучитьДанные().Выгрузить();
	
	ПроверенныеЛица.Колонки.Добавить("Пройдена",			Новый ОписаниеТипов("Булево"));
	ПроверенныеЛица.Колонки.Добавить("Комментарий", 		Новый ОписаниеТипов("Строка"));
	ПроверенныеЛица.Колонки.Добавить("КлючСтрокиСверки",	Новый ОписаниеТипов("Строка"));
	ПроверенныеЛица.Колонки.Добавить("РеквизитыСверки",		Новый ОписаниеТипов("ХранилищеЗначения"));
	
#КонецОбласти	

#Область ДисквалифицированныеЛица

	Если ПроверенныеЛица.Количество() Тогда
		Запрос = Новый Запрос;
		Запрос.Текст = 
			"ВЫБРАТЬ РАЗРЕШЕННЫЕ
			|	СписокДисквалифицированныхЛиц.The_number_of_the_record_from_the_register_of_disqualified_persons КАК НомерЗаписиИзРеестраДисквалифицированныхЛиц,
			|	СписокДисквалифицированныхЛиц.Full_name КАК ФИО,
			|	СписокДисквалифицированныхЛиц.Date_of_birth_of_the_person КАК ДатаРождения,
			|	СписокДисквалифицированныхЛиц.Place_of_birth КАК МестоРождения,
			|	СписокДисквалифицированныхЛиц.Start_date КАК ДатаНачалаСУчетомСведенийОПересмотре,
			|	СписокДисквалифицированныхЛиц.Date_of_expiry_of_the_period_of_Ineligibility КАК ДатаИстеченияСрокаДисквалификацииСУчетомСведенийОПересмотре,
			|	Файлы.Publication_Date КАК ДатаПубликации,
			|	СписокДисквалифицированныхЛиц.Ссылка КАК Решение
			|ИЗ
			|	ВнешнийИсточникДанных.Externals.Таблица.Register_of_disqualified_persons КАК СписокДисквалифицированныхЛиц
			|		ЛЕВОЕ СОЕДИНЕНИЕ ВнешнийИсточникДанных.Externals.Таблица.dbo_Files КАК Файлы
			|		ПО СписокДисквалифицированныхЛиц.File_Id = Файлы.Ссылка
			|ГДЕ
			|	СписокДисквалифицированныхЛиц.File_Id В
			|			(ВЫБРАТЬ ПЕРВЫЕ 1
			|				dbo_Files.Ссылка КАК Ссылка
			|			ИЗ
			|				ВнешнийИсточникДанных.Externals.Таблица.dbo_Files КАК dbo_Files
			|			ГДЕ
			|				dbo_Files.Source_Id.Id = 24
			|				И dbo_Files.Publication_Date <= &Период
			|			УПОРЯДОЧИТЬ ПО
			|				dbo_Files.Publication_Date УБЫВ)
			|	И СписокДисквалифицированныхЛиц.Full_name В(&СписокФИО)";
		
		Запрос.УстановитьПараметр("Период",		Период);
		Запрос.УстановитьПараметр("СписокФИО",	ПроверенныеЛица.ВыгрузитьКолонку("ФИО"));
	
		ДисквалифицированныеЛица = Запрос.Выполнить().Выгрузить();

		Для Каждого СтрокаДанных Из ПроверенныеЛица Цикл
			ПараметрыПоиска = Новый Структура("ФИО", ВРег(СтрокаДанных.ФИО));
			НайденныеСтроки = ДисквалифицированныеЛица.НайтиСтроки(ПараметрыПоиска);
			
			СтрокаДанных.Пройдена = (НайденныеСтроки.Количество() = 0); 
			
			Комментарий		= Новый Массив;
			СписокРешений	= Новый Массив;
			
			Для Каждого СтрокаДисквалифицированныеЛица Из НайденныеСтроки Цикл
				Комментарий.Добавить("Дата публикации списка: " + Формат(СтрокаДисквалифицированныеЛица.ДатаПубликации, "ДФ=dd.MM.yyyy"));
				Комментарий.Добавить("Номер записи из реестра дисквалифицированных лиц: " + Формат(СтрокаДисквалифицированныеЛица.НомерЗаписиИзРеестраДисквалифицированныхЛиц, "ЧГ=0"));
				Комментарий.Добавить("ФИО: " + СтрокаДисквалифицированныеЛица.ФИО);
				Комментарий.Добавить("Дата рождения: " + Формат(СтрокаДисквалифицированныеЛица.ДатаРождения, "ДФ=dd.MM.yyyy"));
				Комментарий.Добавить("Место рождения: " + СтрокаДисквалифицированныеЛица.МестоРождения);
				Комментарий.Добавить("Дата начала дисквалификации: " + Формат(СтрокаДисквалифицированныеЛица.ДатаНачалаСУчетомСведенийОПересмотре, "ДФ=dd.MM.yyyy"));
				Комментарий.Добавить("Дата окончания срока дисквалификации: " + Формат(СтрокаДисквалифицированныеЛица.ДатаИстеченияСрокаДисквалификацииСУчетомСведенийОПересмотре, "ДФ=dd.MM.yyyy"));
				Комментарий.Добавить("");
				
				СписокРешений.Добавить(СтрокаДисквалифицированныеЛица.Решение);
			КонецЦикла;
			
			СтрокаДанных.Комментарий = СтрСоединить(Комментарий, Символы.ПС);
			
			ЗначенияРеквизитовСверки = Новый Структура("Фамилия, Имя, Отчество, ДатаРождения");
			ЗаполнитьЗначенияСвойств(ЗначенияРеквизитовСверки, СтрокаДанных);
			
			Если СписокРешений.Количество() = 1 Тогда
				ЗначенияРеквизитовСверки.Вставить("СписокРешений", СписокРешений[0]);
			Иначе
				ЗначенияРеквизитовСверки.Вставить("СписокРешений", СписокРешений);
			КонецЕсли;
			
			СтрокаДанных.РеквизитыСверки = Новый ХранилищеЗначения(ЗначенияРеквизитовСверки);
			СтрокаДанных.КлючСтрокиСверки = Строка(Новый УникальныйИдентификатор);
			
		КонецЦикла;
		
	КонецЕсли;
	
#КонецОбласти

	Возврат ПроверенныеЛица;
	
КонецФункции

Процедура УстановитьПараметрыСоединенийСВнешнимиИсточниками() Экспорт
	УстановитьПараметрыСоединенияСВнешнимИсточникомExternals();
	УстановитьПараметрыСоединенияСВнешнимИсточникомRiskControl();
КонецПроцедуры

Процедура УстановитьПараметрыСоединенияСВнешнимИсточникомExternals()
	ПараметрыСоединения = ВнешниеИсточникиДанных.Externals.ПолучитьОбщиеПараметрыСоединения();
	
	ПараметрыСоединения.АутентификацияОС = Ложь;
	ПараметрыСоединения.АутентификацияСтандартная = Истина;
	ПараметрыСоединения.ИмяПользователя = "Nikolay";
	ПараметрыСоединения.Пароль = "11111";
	ПараметрыСоединения.СУБД = "MSSQLServer";
		
	Если ОбщегоНазначения.ЗначениеПараметраСеанса("ЭтоРабочаяИнформационнаяБаза") Тогда
		ПараметрыСоединения.СтрокаСоединения = "Driver={SQL Server};Server=AP70;Database=Externals";
	Иначе
		ПараметрыСоединения.СтрокаСоединения = "Driver={SQL Server};Server=AP69;Database=Externals";
	КонецЕсли;
	
	УстановитьПривилегированныйРежим(Истина);
	
	ВнешниеИсточникиДанных.Externals.УстановитьОбщиеПараметрыСоединения(ПараметрыСоединения);
	ВнешниеИсточникиДанных.Externals.УстановитьПараметрыСоединенияПользователя(ПользователиИнформационнойБазы.ТекущийПользователь().Имя, ПараметрыСоединения);
	ВнешниеИсточникиДанных.Externals.УстановитьПараметрыСоединенияСеанса(ПараметрыСоединения);
КонецПроцедуры

Процедура УстановитьПараметрыСоединенияСВнешнимИсточникомRiskControl() Экспорт
	ПараметрыСоединения = ВнешниеИсточникиДанных.RiskControl.ПолучитьОбщиеПараметрыСоединения();
	
	ПараметрыСоединения.АутентификацияОС = Ложь;
	ПараметрыСоединения.АутентификацияСтандартная = Истина;
	ПараметрыСоединения.ИмяПользователя = "Git";
	ПараметрыСоединения.Пароль = "HNfc^t19";
	ПараметрыСоединения.СУБД = "MSSQLServer";
		
	Если ОбщегоНазначения.ЗначениеПараметраСеанса("ЭтоРабочаяИнформационнаяБаза") Тогда
		ПараметрыСоединения.СтрокаСоединения = "Driver={SQL Server};Server=AP18.G1.LAN;Database=ais_warehouse;SCHEMA=AM;";
	Иначе
		ПараметрыСоединения.СтрокаСоединения = "Driver={SQL Server};Server=AP18.G1.LAN;Database=ais_warehouse_dev;SCHEMA=AM;";
	КонецЕсли;
	
	УстановитьПривилегированныйРежим(Истина);
	
	ВнешниеИсточникиДанных.RiskControl.УстановитьОбщиеПараметрыСоединения(ПараметрыСоединения);
	ВнешниеИсточникиДанных.RiskControl.УстановитьПараметрыСоединенияПользователя(ПользователиИнформационнойБазы.ТекущийПользователь().Имя, ПараметрыСоединения);
	ВнешниеИсточникиДанных.RiskControl.УстановитьПараметрыСоединенияСеанса(ПараметрыСоединения);
КонецПроцедуры

#Область Подключение_к_ЕСИА_Финанс

Функция ЕСИА_Финанс_ПараметрыПодключения(Организация, ContentType = "application/json") Экспорт
		
	ПараметрыПодключения = Новый Структура();    
	
	Если РаботаСДокументами.ОрганизацияРаботаетСРозницейПИФ(Организация, ТекущаяДатаСеанса()) Тогда
		
		// Используем внутренние шлюзы из доп. сведений, внешние в комментариях
		// ТЕСТ: "dev.lk.region-am.ru"
		// ПРОД: "lk.region-am.ru"
		
		Запрос = Новый Запрос(
			"ВЫБРАТЬ РАЗРЕШЕННЫЕ
			|	ЗначенияДополнительныхСведенийПРОД.Значение КАК АдресПРОД,
			|	ЗначенияДополнительныхСведенийТЕСТ.Значение КАК АдресТЕСТ
			|ИЗ
			|	РегистрСведений.ЗначенияДополнительныхСведений КАК ЗначенияДополнительныхСведенийПРОД
			|		ВНУТРЕННЕЕ СОЕДИНЕНИЕ РегистрСведений.ЗначенияДополнительныхСведений КАК ЗначенияДополнительныхСведенийТЕСТ
			|		ПО ЗначенияДополнительныхСведенийПРОД.Объект = ЗначенияДополнительныхСведенийТЕСТ.Объект
			|			И (ЗначенияДополнительныхСведенийТЕСТ.Свойство.Ключ = ""ПрочиеНастройки.АдресЛККЕСИАФинанс_Тест"")
			|ГДЕ
			|	ЗначенияДополнительныхСведенийПРОД.Объект = &Организация
			|	И ЗначенияДополнительныхСведенийПРОД.Свойство.Ключ = ""ПрочиеНастройки.АдресЛККЕСИАФинанс""");
		
		Запрос.УстановитьПараметр("Организация", Организация);
		
		Выборка = Запрос.Выполнить().Выбрать();
		
		Если Выборка.Следующий() Тогда
			
			Если ОбщегоНазначения.ЗначениеПараметраСеанса("ЭтоРабочаяИнформационнаяБаза") Тогда
				ПараметрыПодключения.Вставить("СоединениеHTTP", Новый HTTPСоединение(Выборка.АдресПРОД,,,,,, Новый ЗащищенноеСоединениеOpenSSL));				
			Иначе 
				ПараметрыПодключения.Вставить("СоединениеHTTP", Новый HTTPСоединение(Выборка.АдресТЕСТ,,,,,, Новый ЗащищенноеСоединениеOpenSSL));				
			КонецЕсли;

			ПотокДанных = Новый ПотокВПамяти();
			ЗаписьДанных = Новый ЗаписьДанных(ПотокДанных);
			ЗаписьДанных.ЗаписатьСимволы("region:ee02bb73ae9480735650f2cb6cd762a41f1bbc9b");
			ЗаписьДанных.Закрыть();

			ДвоичныеДанные = ПотокДанных.ЗакрытьИПолучитьДвоичныеДанные();
			
			ЗаголовкиHTTP = Новый Соответствие;
			ЗаголовкиHTTP.Вставить("Authorization", "basic " + Base64Строка(ДвоичныеДанные));
			ЗаголовкиHTTP.Вставить("Content-Type", ContentType);
			
			ПараметрыПодключения.Вставить("ЗаголовкиHTTP", ЗаголовкиHTTP);
			
		Иначе	
			ВызватьИсключение СтрШаблон("В дополнительных сведениях организации %1 не указаны адреса ЛКК ЕСИА.Финанс (тестовый и рабочий стенд)", Организация);
		КонецЕсли;
		
	Иначе
		ВызватьИсключение СтрШаблон("Организация %1 не подключена к ЛКК ЕСИА.Финанс", Организация);
	КонецЕсли;
	
	Возврат ПараметрыПодключения;
	
КонецФункции

Функция ЕСИА_Финанс_ВосстановлениеЗначенияИзJSON(ИмяСвойства, Значение, ДополнительныеПараметры) Экспорт
	
	Если ИмяСвойства = "id" Или СтрЗаканчиваетсяНа(ИмяСвойства, "_id") Тогда
		Возврат ?(ТипЗнч(Значение) = Тип("Число"), Формат(Значение, "ЧГ=0"), Значение);
	Иначе
		//actuality_updated_at, birthday, issue_date, expiration_date, created_at, signed_at, closed_at 
		Если Не ЗначениеЗаполнено(Значение) Тогда
			Возврат Неопределено;	
		ИначеЕсли ТипЗнч(Значение) = Тип("Массив") Тогда
			Значение = Значение[Значение.Количество() - 1];
		КонецЕсли;
		
		ДатаСтр = "";
		//2026-05-08T00:00:00.000+03:00 -> 20260508000000 //2021-06-10 -> 20210610
		Если СтрНайти(Значение, "T") > 0 Или СтрНайти(Значение, "-") > 0  Тогда
			ДатаСтр = Лев(РаботаСоСтрокамиКлиентСервер.ОставитьТолькоЦифрыВСтроке(Значение), 14) 
				
		Иначе 
			//10.06.2021 -> 20210610
			ЧастиТекДаты = РаботаСоСтрокамиКлиентСервер.РазложитьСтрокуВМассивПодстрок(Значение, ".", Истина, Истина);
		
			Для Инд = 1 - ЧастиТекДаты.Количество() По 0 Цикл	
				ДатаСтр = ДатаСтр + ЧастиТекДаты[-Инд];	
			КонецЦикла;
			
		КонецЕсли;
	
		Возврат Дата(ДатаСтр);
		
	КонецЕсли;
	
КонецФункции

#КонецОбласти
