<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="http://www.w3.org/1999/xhtml" version="2.0" >
	<xsl:output method="html" version="5.0" encoding="UTF-16" indent="yes"/>
	<xsl:decimal-format name="russian" decimal-separator="," grouping-separator="."/>
	<xsl:template name="FormatDate">
		<xsl:param name="RawDate"/>
		<xsl:value-of select="concat(substring($RawDate, 9, 2), '.', substring($RawDate, 6, 2), '.', substring($RawDate, 1, 4))"/>
	</xsl:template>
	<xsl:template name="TCurrency_Code">
		<xsl:param name="Currency_Code"/>
		<xsl:choose>
			<xsl:when test="$Currency_Code='392'">	<xsl:text disable-output-escaping="yes">Японская йена</xsl:text></xsl:when>
			<xsl:when test="$Currency_Code='643'">	<xsl:text disable-output-escaping="yes">Российский рубль</xsl:text></xsl:when>
			<xsl:when test="$Currency_Code='826'">	<xsl:text disable-output-escaping="yes">Фунт стерлингов</xsl:text></xsl:when>
			<xsl:when test="$Currency_Code='840'">	<xsl:text disable-output-escaping="yes">Доллар США</xsl:text></xsl:when>
			<xsl:when test="$Currency_Code='978'">	<xsl:text disable-output-escaping="yes">Евро</xsl:text></xsl:when>
			<xsl:when test="$Currency_Code='792'">	<xsl:text disable-output-escaping="yes">Турецкая лира (до 01.01.2005)</xsl:text></xsl:when>
			<xsl:when test="$Currency_Code='986'">	<xsl:text disable-output-escaping="yes">Бразильский реал</xsl:text></xsl:when>
			<xsl:when test="$Currency_Code='356'">	<xsl:text disable-output-escaping="yes">Индийская рупия</xsl:text></xsl:when>
			<xsl:when test="$Currency_Code='756'">	<xsl:text disable-output-escaping="yes">Швейцарский франк</xsl:text></xsl:when>
			<xsl:when test="$Currency_Code='484'">	<xsl:text disable-output-escaping="yes">Мексиканское песо</xsl:text></xsl:when>
			<xsl:when test="$Currency_Code='156'">	<xsl:text disable-output-escaping="yes">Китайский юань</xsl:text></xsl:when>
			<xsl:when test="$Currency_Code='157'">	<xsl:text disable-output-escaping="yes">Гонконгский доллар</xsl:text></xsl:when>
			<xsl:when test="$Currency_Code='974'">	<xsl:text disable-output-escaping="yes">Белорусский рубль (до 01.07.2016)</xsl:text></xsl:when>
			<xsl:when test="$Currency_Code='398'">	<xsl:text disable-output-escaping="yes">Казахстанский тенге</xsl:text></xsl:when>
			<xsl:when test="$Currency_Code='124'">	<xsl:text disable-output-escaping="yes">Канадский доллар</xsl:text></xsl:when>
			<xsl:when test="$Currency_Code='376'">	<xsl:text disable-output-escaping="yes">Новый шекель</xsl:text></xsl:when>
			<xsl:when test="$Currency_Code='417'">	<xsl:text disable-output-escaping="yes">Кыргызский сом</xsl:text></xsl:when>
			<xsl:when test="$Currency_Code='980'">	<xsl:text disable-output-escaping="yes">Украинская гривна</xsl:text></xsl:when>
			<xsl:when test="$Currency_Code='4217'">	<xsl:text disable-output-escaping="yes">Аргентинское песо</xsl:text></xsl:when>
			<xsl:when test="$Currency_Code='944'">	<xsl:text disable-output-escaping="yes">Азербайджанский манат</xsl:text></xsl:when>
			<xsl:when test="$Currency_Code='36'">	<xsl:text disable-output-escaping="yes">Австралийский доллар</xsl:text></xsl:when>
			<xsl:when test="$Currency_Code='702'">	<xsl:text disable-output-escaping="yes">Сингапурский доллар</xsl:text></xsl:when>
			<xsl:when test="$Currency_Code='203'">	<xsl:text disable-output-escaping="yes">Чешская крона</xsl:text></xsl:when>
			<xsl:when test="$Currency_Code='933'">	<xsl:text disable-output-escaping="yes">Белорусский рубль</xsl:text></xsl:when>
			<xsl:when test="$Currency_Code='949'">	<xsl:text disable-output-escaping="yes">Турецкая лира</xsl:text></xsl:when>
			<xsl:when test="$Currency_Code='410'">	<xsl:text disable-output-escaping="yes">Вон Республики Корея</xsl:text></xsl:when>
			<xsl:when test="$Currency_Code='348'">	<xsl:text disable-output-escaping="yes">Венгерский форинт</xsl:text></xsl:when>
			<xsl:when test="$Currency_Code='352'">	<xsl:text disable-output-escaping="yes">Исландская крона</xsl:text></xsl:when>
			<xsl:when test="$Currency_Code='208'">	<xsl:text disable-output-escaping="yes">Датская крона</xsl:text></xsl:when>
			<xsl:when test="$Currency_Code='554'">	<xsl:text disable-output-escaping="yes">Новозеландский доллар</xsl:text></xsl:when>
			<xsl:when test="$Currency_Code='985'">	<xsl:text disable-output-escaping="yes">Польский злотый</xsl:text></xsl:when>
			<xsl:when test="$Currency_Code='152'">	<xsl:text disable-output-escaping="yes">Чилийское песо</xsl:text></xsl:when>
			<xsl:when test="$Currency_Code='710'">	<xsl:text disable-output-escaping="yes">Южноафриканский рэнд</xsl:text></xsl:when>
			<xsl:when test="$Currency_Code='578'">	<xsl:text disable-output-escaping="yes">Норвежская крона</xsl:text></xsl:when>
			<xsl:when test="$Currency_Code='752'">	<xsl:text disable-output-escaping="yes">Шведская крона</xsl:text></xsl:when>
			<xsl:when test="$Currency_Code='901'">	<xsl:text disable-output-escaping="yes">Новый тайваньский доллар</xsl:text></xsl:when>
			<xsl:when test="$Currency_Code='60'">	<xsl:text disable-output-escaping="yes">Бермудский доллар</xsl:text></xsl:when>
			<xsl:when test="$Currency_Code='136'">	<xsl:text disable-output-escaping="yes">Доллар Островов Кайман</xsl:text></xsl:when>
		</xsl:choose>
    </xsl:template>
	<xsl:template match="NetAssetValue">
		<html>
			<head>
				
				<style>				
					<!-- 
						В стилях используютя параметры необходимые для корректного вывода формата html данных при импорте в Excel. 
						Настройки формата в американской локализации, при этом при открытии Excel сам приводит их к Российской локали.
						Используемые варианты значений mso-number-format:
							"@"							- Текстовые данные
							"#,##0.00;-#,##0.00[Red]	- Сумма с разделителями и двумя знаками после запятой



						Почитать о форматах Excel можно тут: https://www.ablebits.com/office-addins-blog/2016/07/07/custom-excel-number-format/										
					 -->

					<!-- Элементы таблицы -->
					th { border: Thin solid black; border-collapse: collapse; margin: 1px;	padding: 5px; text-align:left; vertical-align: middle; text-align:center;	mso-number-format:"@"; background-color: #6da5f8; color: White;}	
					td { border: Thin solid black; border-collapse: collapse; margin: 1px;	padding: 5px; text-align:center; vertical-align: middle; mso-number-format:"@";}	

					<!--Заголовки -->
					.header { color: White; background-color: #6da5f8; border: Thin solid black; text-align: center; margin: 10px;	padding: 10px; mso-number-format:"@"}		
					
					<!--Таблицы-->					
					.thinborder_table		{ border: Thin solid black; border-collapse: collapse; margin: 20px; padding: 20px; }


					<!--Ячейки таблицы-->
					.table_cell				{ border: Thin solid black; border-collapse: collapse; margin: 1px;	padding: 5px; text-align: center; 	vertical-align: middle; mso-number-format:"@";}		
					.table_cell_l 			{ border: Thin solid black; border-collapse: collapse; margin: 1px;	padding: 5px; text-align: left;  	vertical-align: middle; mso-number-format:"@";}
					.table_cell_r 			{ border: Thin solid black; border-collapse: collapse; margin: 1px;	padding: 5px; text-align: right; 	vertical-align: middle; mso-number-format:"@";}
					
					<!--Ячейка с числовыми данными (разделители  два знака после запятой)-->
					.table_cell_amnt		{ border: Thin solid black; border-collapse: collapse; margin: 1px;	padding: 5px; text-align: center;	vertical-align: middle; mso-number-format:"#,##0.00;-#,##0.00[Red]";}		
					
					h1 {color: #5779CB; mso-number-format:"@";}
					h2 {color: #5779CB; mso-number-format:"@";}
					h3 {margin: 10px; padding: 10px; mso-number-format:"@";}
					h4 {margin: 10px; padding: 10px; mso-number-format:"@";}

					table { border: Thin solid black; border-collapse: collapse; }

				</style>

				<title>Стоимость чистых активов. Отчет</title>

			</head>
			<body>
					
				<table style="border: none; background-color: white; border-bottom: thick solid #6da5f8 " width="100%"> 					
					<tr>
						<th style="border: none; background-color: white;" colspan = "14">
							<!-- Заголовок -->
							<div style='color: #5779CB; text-align: left; font-size: 38;'>					
									<xsl:choose>
										<xsl:when test="MetaData/Report_Title='1'">
											<xsl:text disable-output-escaping="yes">Расчет текущей стоимости активов и стоимости чистых активов, составляющих пенсионные накопления (для ПН)</xsl:text>
										</xsl:when>
										<xsl:when test="MetaData/Report_Title='2'">
											<xsl:text disable-output-escaping="yes">Расчет стоимости активов, составляющих пенсионные резервы (для ПР УК)</xsl:text>
										</xsl:when>
										<xsl:when test="MetaData/Report_Title='3'">
											<xsl:text disable-output-escaping="yes"> Расчет совокупной стоимости пенсионных резервов негосударственного пенсионного фонда (для ПР Фонда)</xsl:text>
										</xsl:when>
									</xsl:choose>					
							</div>
						</th>	
					</tr>
				</table>

				<br/>			

				<h2>Информация об отчёте.</h2>

				<table class="thinborder_table">					
					<tr><td class="header" colspan="2" style="text-align: left;" > Период данных </td></tr>
					<tr><td class="table_cell_l" width="300"> Дата отчета:</td>
						<td colspan="1" class="table_cell_r">
							<xsl:call-template name="FormatDate">
								<xsl:with-param name="RawDate" select="MetaData/Date"/>
							</xsl:call-template>
						</td>
					</tr>
					<tr><td class="table_cell_l " width="300">Время, по состоянию на которое рассчитывается СЧА:</td>	<td class="table_cell_r" width="150"><xsl:value-of select="MetaData/Creation_Time"/></td></tr>

					<tr><td class="header" colspan="2"  style="text-align: left;"> Информация о фонде </td></tr>

					<tr><td class="table_cell_l" width="300">Код фонда в системе СД:</td>	<td class="table_cell_r" width="150"><xsl:value-of select="MetaData/Ext_Fond_Code"/></td></tr>
					<tr><td class="table_cell_l" width="300">ИНН фонда:</td>				<td class="table_cell_r" width="150"><xsl:value-of select="MetaData/VAT_Registration_No_Fond"/></td></tr>				

					<tr><td class="header" colspan="2"  style="text-align: left;"> Информация об управляющей компании </td></tr>
					<tr><td class="table_cell_l" width="300">Код УК в системе СД:</td>																	<td class="table_cell_r" width="150"><xsl:value-of select="MetaData/Ext_UK_Сode"/></td></tr>
					<tr><td class="table_cell_l">ИНН УК:</td>																							<td class="table_cell_r" width="150"><xsl:value-of select="MetaData/VAT_Registration_No_UK"/></td></tr>
					<tr><td class="table_cell_l" width="300">Номер договора доверительного управления (для УК) / Номер договора со СД (для Фонда):</td>	<td class="table_cell_r" width="150"><xsl:value-of select="MetaData/No_Agreement"/></td></tr>
					<tr><td class="table_cell_l" width="300">Дата договора доверительного управления (для УК) / Дата договора со СД (для Фонда):</td>	<td class="table_cell_r" width="150"><xsl:call-template name="FormatDate"><xsl:with-param name="RawDate" select="MetaData/Date_Agreement"/></xsl:call-template></td></tr>
				</table>	
				
				<br/>	
			
				<xsl:if test="Sections/Section_1/Data_Row">				
					<h2>1 - Денежные средства на счетах</h2>
					<table class = "thinborder_table">  
						<thead>
							<!-- <tr><th colspan="8"> <b>1 - Денежные средства на счетах</b></th></tr>   class="thinborder_table"-->
							<tr>
								<th class="header" width ="50"> № п/п </th>
								<th class="header" width ="150"> БИК банка</th>
								<th class="header" width ="150"> ИНН банка</th>
								<th class="header" width ="150"> Дата договора банковского счета, депозита, депозитного сертификата</th>
								<th class="header" > Номер договора банковского счета, депозита, депозитного сертификата</th>
								<th class="header" > Валюта</th>
								<th class="header" width ="150"> Номер банковского счета</th>
								<th class="header" width ="150"> Сумма денежных средств</th>
							</tr>						
							<tr>
								<th  class="header" >1</th>
								<th  class="header" >2</th>
								<th  class="header" >3</th>
								<th  class="header" >4</th>
								<th  class="header" >5</th>
								<th  class="header" >6</th>
								<th  class="header" >7</th>
								<th  class="header" >8</th>
							</tr>
						</thead>
						<tbody>
								<xsl:for-each select="Sections/Section_1/Data_Row">
									<tr>
										<td class="table_cell"><xsl:value-of select="Num_Row"/></td>
										<td class="table_cell"><xsl:value-of select="Bank_BIC"/></td>
										<td class="table_cell"><xsl:value-of select="VAT_Registration_No_Bank"/></td>
										<td class="table_cell">
											<xsl:if test="Date_Bank_Agreement/text()">
												<xsl:call-template name="FormatDate">
													<xsl:with-param name="RawDate" select="Date_Bank_Agreement"/>
												</xsl:call-template>
											</xsl:if>
										</td>
										<td class="table_cell">
											<xsl:if test="No_Bank_Agreement/text()">
												<xsl:value-of select="No_Bank_Agreement"/>
											</xsl:if>
										</td>
										<td class="table_cell">
											<xsl:call-template name="TCurrency_Code">
												<xsl:with-param name="Currency_Code" select="Currency_Code" />
											</xsl:call-template>
										</td>
										<td class="table_cell"><xsl:value-of select="Bank_Account_No"/></td>
										<td class="table_cell_amnt"><xsl:value-of select="Amount"/></td>
									</tr>
								</xsl:for-each>
						</tbody>
					</table>
				</xsl:if>			
				
						
							
				<xsl:if test="Sections/Section_2/Data_Row">
				<h2>2 - Денежные средства в депозитах</h2>
					<table class="thinborder_table">
						<thead>
						
							<tr>
								<th  class="header"  width ="50"> № п/п </th>
								<th  class="header"  width ="150"> БИК банка</th>
								<th  class="header"  width ="150"> ИНН банка</th>
								<th  class="header"  width ="150"> Дата договора банковского счета, депозита, депозитного сертификата</th>
								<th  class="header" > Номер договора банковского счета, депозита, депозитного сертификата</th>
								<th  class="header" > Валюта</th>
								<th  class="header"  width ="150"> Номер банковского счета</th>
								<th  class="header"  width ="150"> Оценочная стоимость</th>
							</tr>						
							<tr  class="header" >
								<th  class="header" >1</th><th class="header" >2</th><th class="header" >3</th><th class="header" >4</th><th class="header" >5</th><th class="header" >6</th><th class="header" >7</th><th class="header" >8</th>
							</tr>					
						</thead>
						<tbody>
								<xsl:for-each select="Sections/Section_2/Data_Row">
									<tr>
										<td class="size3">
											<xsl:value-of select="Num_Row"/>
										</td>
										<td class="size12">
											<xsl:value-of select="Bank_BIC"/>
										</td>
										<td class="size12">
											<xsl:value-of select="VAT_Registration_No_Bank"/>
										</td>
										<td class="size15">
											<xsl:if test="Date_Bank_Agreement/text()">
												<xsl:call-template name="FormatDate">
													<xsl:with-param name="RawDate" select="Date_Bank_Agreement"/>
												</xsl:call-template>
											</xsl:if>
										</td>
										<td class="size15">
											<xsl:if test="No_Bank_Agreement/text()">
												<xsl:value-of select="No_Bank_Agreement"/>
											</xsl:if>
										</td>
										<td class="size15">
											<xsl:call-template name="TCurrency_Code">
												<xsl:with-param name="Currency_Code" select="Currency_Code" />
											</xsl:call-template>
										</td>
										<td class="size15">
											<xsl:value-of select="Bank_Account_No"/>
										</td>
										<td class="table_cell_amnt">
											<xsl:value-of select="Amount"/>
										</td>
									</tr>
								</xsl:for-each>
						</tbody>
					</table>
				</xsl:if>

				
				<xsl:if test="Sections/Section_3/Data_Row">
				<h2>3 - Депозитные сертификаты</h2>

				<table class="thinborder_table">
					<thead>
						<tr>
							<th   class="header">№ п/п</th>
							<th   class="header">БИК банка</th>
							<th   class="header">ИНН банка</th>
							<th   class="header">Дата договора банковского счета, депозита, депозитного сертификата</th>
							<th   class="header">Валюта</th>
							<th   class="header">Номер банковского счета</th>
							<th   class="header">Оценочная стоимость</th>
						</tr>
						<tr>
							<th   class="header">1</th><th   class="header">2</th><th   class="header">3</th><th   class="header">4</th><th   class="header">5</th><th class="header">6</th><th class="header">7</th>
						</tr>
					</thead>
					<tbody>
							<xsl:for-each select="Sections/Section_3/Data_Row">
								<tr>
									<td class="size3">
										<xsl:value-of select="Num_Row"/>
									</td>
									<td class="size16">
										<xsl:value-of select="Bank_BIC"/>
									</td>
									<td class="size16">
										<xsl:value-of select="VAT_Registration_No_Bank"/>
									</td>
									<td class="size16">
										<xsl:if test="Date_Bank_Agreement/text()">
											<xsl:call-template name="FormatDate">
												<xsl:with-param name="RawDate" select="Date_Bank_Agreement"/>
											</xsl:call-template>
										</xsl:if>
									</td>
									<td class="size16">
										<xsl:call-template name="TCurrency_Code">
											<xsl:with-param name="Currency_Code" select="Currency_Code" />
										</xsl:call-template>
									</td>
									<td class="size16">
										<xsl:value-of select="Bank_Account_No"/>
									</td>
									<td class="table_cell_amnt">
										<xsl:value-of select="Amount"/>
									</td>
								</tr>
							</xsl:for-each>
					</tbody>
				</table>
				</xsl:if>

				
				<xsl:if test="Sections/Section_4/Data_Row">
					<h2>4 - Ценные бумаги</h2>

					<table class="thinborder_table">
						<thead>
							<tr>
								<th class="header">№ п/п</th>  
								<th class="header">Номер гос. регистрации</th>
								<th class="header">ISIN</th>  
								<th class="header">Количество ЦБ</th>  
								<th class="header">Оценочная стоимость</th>  
								<th class="header">Категория ФИ</th> 							
							</tr>
							<tr>
								<th class="header">1</th><th class="header">2</th><th class="header">3</th><th class="header">4</th><th class="header">5</th><th class="header">6</th>
							</tr>
						</thead>
						<tbody>
								<xsl:for-each select="Sections/Section_4/Data_Row">
									<tr>
										<td class="size3">
											<xsl:value-of select="Num_Row"/>
										</td>
										<td class="size20">
											<xsl:value-of select="State_Registration_No"/>
										</td>
										<td class="size20">
											<xsl:value-of select="ISIN"/>
										</td>
										<td class="size20">
											<xsl:value-of select="Quantity"/>
										</td>
										<td class="table_cell_amnt">
											<xsl:value-of select="Amount"/>
										</td>
										<td class="size17">
											<xsl:value-of select="FI_Class"/>
										</td>
									</tr>
								</xsl:for-each>
						</tbody>
					</table>
					<br/>
				</xsl:if>					

				<xsl:if test="Sections/Section_5/Data_Row">
					<h2>5 - Объекты недвижимого имущества</h2>

					<table class="thinborder_table">
						<thead>
							<tr>
								<th class="header">№ п/п</th>
								<th class="header">Номер гос. регистрации</th>
								<th class="header">Оценочная стоимость </th>
							</tr>
							<tr>
								<th class="header">1</th><th class="header">2</th><th class="header">3</th>
							</tr>
						</thead>

						<tbody>
								<xsl:for-each select="Sections/Section_5/Data_Row">
									<tr>
										<td class="size2">
											<xsl:value-of select="Num_Row"/>
										</td>
										<td class="size49">
											<xsl:value-of select="State_Registration_No"/>
										</td>
										<td class="table_cell_amnt">
											<xsl:value-of select="Amount"/>
										</td>
									</tr>
								</xsl:for-each>
						</tbody>
					</table>
					<br/>
				</xsl:if>					
				
				<h2>6 -  Дебиторская задолженность</h2>

				<xsl:if test="Sections/Sections_6/Section_6_1/Data_Row">
					<h3>6.1 -  Средства  на специальных брокерских счетах</h3>				
					
					<table class="thinborder_table">					
						<thead>
							<tr>
								<th class="header">№ п/п</th>
								<th class="header">Номер договора (УК - Брокер)</th>
								<th class="header">Дата договора</th>
								<th class="header">Валюта счета</th>
								<th class="header">Сумма дебиторской задолженности</th>
							</tr>
							<tr>
								<th class="header">1</th><th class="header">2</th><th class="header">3</th><th class="header">4</th><th class="header">5</th>
							</tr>
						</thead>

						<tbody>
								<xsl:for-each select="Sections/Sections_6/Section_6_1/Data_Row">
									<tr>
										<td class="size2">
											<xsl:value-of select="Num_Row"/>
										</td>
										<td class="size24">
											<xsl:value-of select="No_Bank_Agreement"/>
										</td>
										<td class="size24">
											<xsl:if test="Date_Bank_Agreement/text()">
												<xsl:call-template name="FormatDate">
													<xsl:with-param name="RawDate" select="Date_Bank_Agreement"/>
												</xsl:call-template>
											</xsl:if>
										</td>
										<td class="size25">
											<xsl:call-template name="TCurrency_Code">
												<xsl:with-param name="Currency_Code" select="Currency_Code" />
											</xsl:call-template>
										</td>
										<td class="table_cell_amnt">
											<xsl:value-of select="Amount"/>
										</td>
									</tr>
								</xsl:for-each>
						</tbody>
					</table>
					<br/>
				</xsl:if>
				
				
				
				<xsl:if test="Sections/Sections_6/Section_6_2/Data_Row">

					<h3>6.2 -   Средства на счетах клиринговых центров</h3>
					
					<table class="thinborder_table">				
						<thead>
							<tr>
								<th class="header">№ п/п</th>
								<th class="header">Номер договора (УК - Брокер)</th>
								<th class="header">Дата договора</th>
								<th class="header">Валюта счета</th>
								<th class="header">Сумма дебиторской задолженности</th>
							</tr>
							<tr>
								<th class="header">1</th><th class="header">2</th><th class="header">3</th><th class="header">4</th><th class="header">5</th>
							</tr>
						</thead>
						<tbody>
								<xsl:for-each select="Sections/Sections_6/Section_6_2/Data_Row">
									<tr>
										<td class="size2">
											<xsl:value-of select="Num_Row"/>
										</td>
										<td class="size24">
											<xsl:value-of select="No_Bank_Agreement"/>
										</td>
										<td class="size24">
											<xsl:if test="Date_Bank_Agreement/text()">
												<xsl:call-template name="FormatDate">
													<xsl:with-param name="RawDate" select="Date_Bank_Agreement"/>
												</xsl:call-template>
											</xsl:if>
										</td>
										<td class="size25">
											<xsl:call-template name="TCurrency_Code">
												<xsl:with-param name="Currency_Code" select="Currency_Code" />
											</xsl:call-template>
										</td>
										<td class="table_cell_amnt">
											<xsl:value-of select="Amount"/>
										</td>
									</tr>
								</xsl:for-each>
						</tbody>
					</table>
					<br/>
				</xsl:if>					

				<xsl:if test="Sections/Sections_6/Section_6_3/Data_Row">

					<h3>6.3 -  Дебиторская задолженность по доходам по ЦБ (НКД к погашению)</h3>				

					<table class="thinborder_table">
						<thead>
							<tr>
								<th class="header">№ п/п </th>
								<th class="header">Номер гос. регистрации</th>
								<th class="header">ISIN</th>
								<th class="header">Сумма дебиторской задолженности</th>
							</tr>					
							<tr>
								<th class="header">1</th><th class="header">2</th><th class="header">3</th><th class="header">4</th>
							</tr>
						</thead>
						<tbody>
							<xsl:for-each select="Sections/Sections_6/Section_6_3/Data_Row">
								<tr>
									<td class="size3">
										<xsl:value-of select="Num_Row"/>
									</td>
									<td class="size27">
										<xsl:if test="State_Registration_No/text()">
											<xsl:value-of select="State_Registration_No"/>
										</xsl:if>
									</td>
									<td class="size27">
										<xsl:value-of select="ISIN"/>
									</td>
									<td class="table_cell_amnt">
										<xsl:value-of select="Amount"/>
									</td>
								</tr>
							</xsl:for-each>
						</tbody>
					</table>
					<br/>
				</xsl:if>
						
				<xsl:if test="Sections/Sections_6/Section_6_4/Data_Row">
					<h3>
						6.4 -   Дебиторская задолженность по сделкам РЕПО
					</h3>

					<table class="thinborder_table">
						<thead>
							<tr>
								<th class="header">№ п/п </th>
								<th class="header">Номер гос. регистрации</th>
								<th class="header">ISIN</th>
								<th class="header">Сумма дебиторской задолженности</th>
							</tr>					
							<tr>
								<th class="header">1</th><th class="header">2</th><th class="header">3</th><th class="header">4</th>
							</tr>
						</thead>
						<tbody>
								<xsl:for-each select="Sections/Sections_6/Section_6_4/Data_Row">
									<tr>
										<td class="size3">
											<xsl:value-of select="Num_Row"/>
										</td>
										<td class="size27">
											<xsl:if test="State_Registration_No/text()">
												<xsl:value-of select="State_Registration_No"/>
											</xsl:if>
										</td>
										<td class="size27">
											<xsl:value-of select="ISIN"/>
										</td>
										<td class="table_cell_amnt">
											<xsl:value-of select="Amount"/>
										</td>
									</tr>
								</xsl:for-each>
						</tbody>
					</table>
					<br/>
				</xsl:if>
				
				
				
				
				<xsl:if test="Sections/Sections_6/Section_6_4/Detail_6_4/Data_Row">
					<h3>
						6.4 -   расшифровки по сделкам РЕПО
					</h3>

					<table class="thinborder_table">
						<thead>
							<tr>
								<th class="header">№ п/п </th>
								<th class="header">ГРН</th>
								<th class="header">ISIN</th>
								<th class="header">Биржевой номер</th>
								<th class="header">Вид сделки</th>
								<th class="header">Дата первой части</th>
								<th class="header">Дата второй части</th>
								<th class="header">Ставка Репо</th>
								<th class="header">Количество</th>
								<th class="header">Сумма займа</th>
								<th class="header">Расходы по сделке</th>
								<th class="header">Начисленные проценты</th>
							</tr>					
						</thead>
						<tbody>
								<xsl:for-each select="Sections/Sections_6/Section_6_4/Detail_6_4/Data_Row">
									<tr>
										<td class="size3">
											<xsl:value-of select="Num_Row"/>
										</td>
										<td class="size27">
											<xsl:value-of select="State_Registration_No"/>
										</td>
										<td class="size27">
											<xsl:value-of select="ISIN"/>
										</td>
										<td class="size27">
											<xsl:value-of select="Transaction_Code"/>
										</td>
										<td class="size27">
											<xsl:choose>
												<xsl:when test="Transaction_Type [text()='1']">Обратное РЕПО</xsl:when>
												<xsl:when test="Transaction_Type [text()='2']">Прямое РЕПО</xsl:when>
											</xsl:choose>
										</td>
										<td class="size27">
											<xsl:call-template name="FormatDate">
												<xsl:with-param name="RawDate" select="Date_First_Part"/>
											</xsl:call-template>
										</td>
										<td class="size27">
											<xsl:call-template name="FormatDate">
												<xsl:with-param name="RawDate" select="Date_Second_Part"/>
											</xsl:call-template>
										</td>
										<td class="size27">
											<xsl:value-of select="Rate"/>
										</td>
										<td class="size27">
											<xsl:value-of select="Quantity"/>
										</td>
										<td class="size27">
											<xsl:value-of select="Loan_Amount"/>
										</td>
										<td class="size27">
											<xsl:value-of select="Еxpenses"/>
										</td>
										<td class="size27">
											<xsl:value-of select="Interest"/>
										</td>
									</tr>
								</xsl:for-each>
						</tbody>
					</table>
					<br/>
				</xsl:if>

				<xsl:if test="Sections/Sections_6/Section_6_5/Data_Row">
					<h3>6.5 -   Прочая дебиторская задолженность по ЦБ, ПФИ</h3>				
					<table class="thinborder_table">
						<thead>
							<tr>
								<th class="header">№ п/п </th>
								<th class="header">Номер гос. регистрации</th>
								<th class="header">ISIN</th>
								<th class="header">Сумма дебиторской задолженности</th>
							</tr>					
							<tr>
								<th class="header">1</th><th class="header">2</th><th class="header">3</th><th class="header">4</th>
							</tr>
						</thead>
						<tbody>
								<xsl:for-each select="Sections/Sections_6/Section_6_5/Data_Row">
									<tr>
										<td class="size3">
											<xsl:value-of select="Num_Row"/>
										</td>
										<td class="size27">
											<xsl:if test="State_Registration_No/text()">
												<xsl:value-of select="State_Registration_No"/>
											</xsl:if>
										</td>
										<td class="size27">
											<xsl:value-of select="ISIN"/>
										</td>
										<td class="table_cell_amnt">
											<xsl:value-of select="Amount"/>
										</td>
									</tr>
								</xsl:for-each>
						</tbody>
					</table>
					<br/>
				</xsl:if>
				
				<xsl:if test="Sections/Sections_6/Section_6_6/Data_Row">

					<h3>6.6 - Прочая дебиторская задолженность по Контрагентам</h3>

					<table class="thinborder_table">				
						<thead>
							<tr>
								<th class="header">№ п/п</th>
								<th class="header">ИНН контрагента</th>
								<th class="header">КПП контрагента</th>
								<th class="header">Сумма дебиторской задолженности</th>
							</tr>	
							<tr>
								<th class="header">1</th><th class="header">2</th><th class="header">3</th><th class="header">4</th>
							</tr>				
						</thead>
						<tbody>
								<xsl:for-each select="Sections/Sections_6/Section_6_6/Data_Row">
									<tr>
										<td class="size2">
											<xsl:value-of select="Num_Row"/>
										</td>
										<td class="size49">
											<xsl:value-of select="VAT_Registration_No_Bank"/>
										</td>
										<td class="size49">
											<xsl:value-of select="KPP"/>
										</td>
										<td class="table_cell_amnt">
											<xsl:value-of select="Amount"/>
										</td>
									</tr>
								</xsl:for-each>
						</tbody>
					</table>
					<br/>
				</xsl:if>
				
				
				
				<xsl:if test="Sections/Sections_6/Section_6_6/Detail_6_6/Data_Row">
					<h3>
						6.6 -   расшифровки по сделкам МНО
					</h3>

					<table class="thinborder_table">
						<thead>
							<tr>
								<th class="header">№ п/п </th>
								<th class="header">Код</th>
								<th class="header">Наименование кредитной организации</th>
								<th class="header"> ИНН</th>
								<th class="header">Наименование</th>
								<th class="header">Дата размещения</th>
								<th class="header">Дата погашения</th>
								<th class="header">Ставка</th>
								<th class="header">Валюта</th>
								<th class="header">Сумма</th>
								<th class="header">Сумма в валюте</th>
								<th class="header">%% начисленные</th>
								<th class="header">%% Начисленные в валюте</th>
							</tr>					
						</thead>
						<tbody>
								<xsl:for-each select="Sections/Sections_6/Section_6_6/Detail_6_6/Data_Row">
									<tr>
										<td class="size3">
											<xsl:value-of select="Num_Row"/>
										</td>
										<td class="size27">
											<xsl:value-of select="Transaction_Code"/>
										</td>
										<td class="size27">
											<xsl:value-of select="Name_Credit_Org"/>
										</td>
										<td class="size27">
											<xsl:value-of select="VAT_Registration_No"/>
										</td>
										<td class="size27">
											<xsl:value-of select="No_Agreement"/>
										</td>
										<td class="size27">
											<xsl:call-template name="FormatDate">
												<xsl:with-param name="RawDate" select="Date_Placement"/>
											</xsl:call-template>
										</td>
										<td class="size27">
											<xsl:call-template name="FormatDate">
												<xsl:with-param name="RawDate" select="Maturity_Date"/>
											</xsl:call-template>
										</td>
										<td class="size27">
											<xsl:value-of select="Rate"/>
										</td>
										<td class="size27">
											<xsl:value-of select="Currency_Code"/>
										</td>
										<td class="size27">
											<xsl:value-of select="Amount"/>
										</td>
										<td class="size27">
											<xsl:value-of select="Amount_Currency"/>
										</td>
										<td class="size27">
											<xsl:value-of select="Interest"/>
										</td>
										<td class="size27">
											<xsl:value-of select="Interest_Currency"/>
										</td>
									</tr>
								</xsl:for-each>
						</tbody>
					</table>
					<br/>
				</xsl:if>

				
				
				
				<xsl:if test="Sections/Sections_6/Section_6_7/Data_Row">
					<h3>6.7 -   Прочая дебиторская задолженность по налогам и сборам</h3>
					<table class="thinborder_table">					
						<thead>
							<tr>
								<th class="header">№ п/п							</th>
								<th class="header">ИНН контрагента					</th>
								<th class="header">Код налога						</th>
								<th class="header">Сумма дебиторской задолженности </th>
							</tr>
							<tr>
								<th class="header">1</th><th class="header">2</th><th class="header">3</th><th class="header">4</th>
							</tr>					
						</thead>
						<tbody>
								<xsl:for-each select="Sections/Sections_6/Section_6_7/Data_Row">
									<tr>
										<td class="size3">
											<xsl:value-of select="Num_Row"/>
										</td>
										<td class="size27">
											<xsl:if test="VAT_Registration_No_Bank/text()">
												<xsl:value-of select="VAT_Registration_No_Bank"/>
											</xsl:if>
										</td>
										<td class="size27">
											<xsl:value-of select="Tax_Code"/>
										</td>
										<td class="table_cell_amnt">
											<xsl:value-of select="Amount"/>
										</td>
									</tr>
								</xsl:for-each>
						</tbody>
					</table>
					<br/>
				</xsl:if>
				
				
				<h2>Раздел 7 -  Обязательства</h2>

				<xsl:if test="Sections/Sections_7/Section_7_1/Data_Row">
					<h3>7.1 -   Кредиторская задолженность по сделкам РЕПО</h3>

					<table class="thinborder_table">				
						<thead>
							<tr>
								<th class="header">№ п/п</th>
								<th class="header">Номер гос. регистрации</th>
								<th class="header">ISIN</th>
								<th class="header">Сумма кредиторской задолженности</th>
							</tr>
							<tr>
								<th class="header">1</th><th class="header">2</th><th class="header">3</th><th class="header">4</th>
							</tr>					
						</thead>
						<tbody>
								<xsl:for-each select="Sections/Sections_7/Section_7_1/Data_Row">
									<tr>
										<td class="size3">
											<xsl:value-of select="Num_Row"/>
										</td>
										<td class="size27">
											<xsl:if test="State_Registration_No/text()">
												<xsl:value-of select="State_Registration_No"/>
											</xsl:if>
										</td>
										<td class="size27">
											<xsl:value-of select="ISIN"/>
										</td>
										<td class="table_cell_amnt">
											<xsl:value-of select="Amount"/>
										</td>
									</tr>
								</xsl:for-each>
						</tbody>
					</table>
					<br/>
				</xsl:if>
				
				<xsl:if test="Sections/Sections_7/Section_7_2/Data_Row">
					<h3>7.2 -   Прочая кредиторская задолженность по ЦБ, ПФИ</h3>

					<table class="thinborder_table">
						<thead>
							<tr>
								<th class="header">№ п/п</th>
								<th class="header">Номер гос. регистрации</th>
								<th class="header">ISIN</th>
								<th class="header">Сумма кредиторской задолженности</th>
							</tr>
							<tr>
								<th class="header">1</th><th class="header">2</th><th class="header">3</th><th class="header">4</th>
							</tr>					
						</thead>
						<tbody>
								<xsl:for-each select="Sections/Sections_7/Section_7_2/Data_Row">
									<tr>
										<td class="size3">
											<xsl:value-of select="Num_Row"/>
										</td>
										<td class="size27">
											<xsl:if test="State_Registration_No/text()">
												<xsl:value-of select="State_Registration_No"/>
											</xsl:if>
										</td>
										<td class="size27">
											<xsl:value-of select="ISIN"/>
										</td>
										<td class="table_cell_amnt">
											<xsl:value-of select="Amount"/>
										</td>
									</tr>
								</xsl:for-each>
						</tbody>
					</table>
					<br/>
				</xsl:if>

				<xsl:if test="Sections/Sections_7/Section_7_3/Data_Row">
					<h3>
					7.3 - Прочая кредиторская задолженность по Контрагентам
					</h3>

					<table class="thinborder_table">				 
						<thead>
							<tr>
								<th class="header">№ п/п</th>
								<th class="header">ИНН контрагента</th>
								<th class="header">КПП контрагента</th>
								<th class="header">Сумма кредиторской задолженности</th>		
							</tr>
							<tr>
								<th class="header">1</th><th class="header">2</th><th class="header">3</th><th class="header">4</th>
							</tr>					
						</thead>
						<tbody>
								<xsl:for-each select="Sections/Sections_7/Section_7_3/Data_Row">
									<tr>
										<td class="size2">
											<xsl:value-of select="Num_Row"/>
										</td>
										<td class="size49">
											<xsl:value-of select="VAT_Registration_No_Bank"/>
										</td>
										<td class="size49">
											<xsl:value-of select="KPP"/>
										</td>
										<td class="table_cell_amnt">
											<xsl:value-of select="Amount"/>
										</td>
									</tr>
								</xsl:for-each>
						</tbody>
					</table>
					<br/>
				</xsl:if>
								
				<xsl:if test="Sections/Sections_7/Section_7_4/Data_Row">
					<h3>7.4 -   Прочая кредиторская задолженность по налогам и сборам</h3>									
					<table class="thinborder_table">
						<thead>
							<tr>
								<th class="header" width='100'>№ п/п</th>
								<th class="header">ИНН контрагента</th>
								<th class="header">Код налога</th>
								<th class="header">Сумма дебиторской задолженности</th>
							</tr>
							<tr>
								<th class="header"  width='100'>1</th><th class="header">2</th><th class="header">3</th><th class="header">4</th>
							</tr>					
						</thead>
						<tbody>
								<xsl:for-each select="Sections/Sections_7/Section_7_4/Data_Row">
									<tr>
										<td class="table_cell"  width='100'>
											<xsl:value-of select="Num_Row"/>
										</td>
										<td class="table_cell">
											<xsl:if test="VAT_Registration_No_Bank/text()">
												<xsl:value-of select="VAT_Registration_No_Bank"/>
											</xsl:if>
										</td>
										<td class="table_cell">
											<xsl:value-of select="Tax_Code"/>
										</td>
										<td class="table_cell_amnt">
											<xsl:value-of select="Amount"/>
										</td>
									</tr>
								</xsl:for-each>
						</tbody>
					</table>
					<br/>
				</xsl:if>
				
				<xsl:if test="Sections/Section_8/Data_Row">
					<h2>8 - Производные финансовые инструменты</h2>

					<table class="thinborder_table">
						<thead>
							<tr>
								<th class="header">№ п/п</th>  
								<th class="header">Код контракта для биржевых инструментов, другой идентификатор для внебиржевых инструментов</th>
								<th class="header">Открытая позиция</th>  
								<th class="header">Количество ЦБ</th>  
								<th class="header">Оценочная стоимость</th>  							
							</tr>
							<tr>
								<th class="header">1</th><th class="header">2</th><th class="header">3</th><th class="header">4</th><th class="header">5</th>
							</tr>
						</thead>
						<tbody>
								<xsl:for-each select="Sections/Section_8/Data_Row">
									<tr>
										<td class="size3">
											<xsl:value-of select="Num_Row"/>
										</td>
										<td class="size20">
											<xsl:value-of select="Registration_No"/>
										</td>
										<td class="size20">
											<xsl:choose>
												<xsl:when test="Open_Position [text()='1']">Короткая позиция</xsl:when>
												<xsl:when test="Open_Position [text()='2']">Длинная позиция</xsl:when>
											</xsl:choose>
										</td>
										<td class="size20">
											<xsl:value-of select="Quantity"/>
										</td>
										<td class="table_cell_amnt">
											<xsl:value-of select="Amount"/>
										</td>
									</tr>
								</xsl:for-each>
						</tbody>
					</table>
					<br/>
				</xsl:if>

				<h2>Разделы 6,7 - Расшифровка дебиторской и кредиторской задолженности</h2>
						
				<xsl:if test="Sections/Sections_6-7_d/Section_6_5_d">
					<h3>
						6.5 - расшифровка прочей дебиторской задолженности по ЦБ, ПФИ
					</h3>

					<table class="thinborder_table">
						<thead>
							<tr>
								<th class="header">Наименование дебиторской задолженности</th>
								<th class="header">Код дебиторской задолженности</th>
								<th class="header">ISIN</th>
								<th class="header">Номер гос. регистрации</th>
								<th class="header">Номер договора/Биржевой номер сделки</th>
								<th class="header">Сумма</th>
							</tr>					
						</thead>
						<tbody>
								<xsl:for-each select="Sections/Sections_6-7_d/Section_6_5_d/A6-5-1/Data_Row">
									<tr>
										<td class="size64">
											Комиссия по сделкам Т+
										</td>
										<td class="size8">
											6.5.1
										</td>
										<td class="size27">
											<xsl:value-of select="ISIN"/>
										</td>
										<td class="size27">
											<xsl:value-of select="State_Registration_No"/>
										</td>
										<td class="size27">
											<xsl:value-of select="No_Bank_Agreement"/>
										</td>
										<td class="size27">
											<xsl:value-of select="Amount"/>
										</td>
									</tr>
								</xsl:for-each>
						</tbody>
						<tbody>
								<xsl:for-each select="Sections/Sections_6-7_d/Section_6_5_d/A6-5-2/Data_Row">
									<tr>
										<td class="size64">
											Положительная переоценка сделок Т+
										</td>
										<td class="size8">
											6.5.2
										</td>
										<td class="size27">
											<xsl:value-of select="ISIN"/>
										</td>
										<td class="size27">
											<xsl:value-of select="State_Registration_No"/>
										</td>
										<td class="size27">
											<xsl:value-of select="No_Bank_Agreement"/>
										</td>
										<td class="size27">
											<xsl:value-of select="Amount"/>
										</td>
									</tr>
								</xsl:for-each>
						</tbody>
						<tbody>
								<xsl:for-each select="Sections/Sections_6-7_d/Section_6_5_d/A6-5-3/Data_Row">
									<tr>
										<td class="size64">
											Дебиторская задолженность по договорам купли-продажи ЦБ
										</td>
										<td class="size8">
											6.5.3
										</td>
										<td class="size27">
											<xsl:value-of select="ISIN"/>
										</td>
										<td class="size27">
											<xsl:value-of select="State_Registration_No"/>
										</td>
										<td class="size27">
											<xsl:value-of select="No_Bank_Agreement"/>
										</td>
										<td class="size27">
											<xsl:value-of select="Amount"/>
										</td>
									</tr>
								</xsl:for-each>
						</tbody>
						<tbody>
								<xsl:for-each select="Sections/Sections_6-7_d/Section_6_5_d/A6-5-4/Data_Row">
									<tr>
										<td class="size64">
											Дебиторская задолженность по дивидендам
										</td>
										<td class="size8">
											6.5.4
										</td>
										<td class="size27">
											<xsl:value-of select="ISIN"/>
										</td>
										<td class="size27">
											<xsl:value-of select="State_Registration_No"/>
										</td>
										<td class="size27">
											X
										</td>
										<td class="size27">
											<xsl:value-of select="Amount"/>
										</td>
									</tr>
								</xsl:for-each>
						</tbody>
						<tbody>
								<xsl:for-each select="Sections/Sections_6-7_d/Section_6_5_d/A6-5-5/Data_Row">
									<tr>
										<td class="size64">
											Дебиторская задолженность по частичному погашению номинала ЦБ
										</td>
										<td class="size8">
											6.5.5
										</td>
										<td class="size27">
											<xsl:value-of select="ISIN"/>
										</td>
										<td class="size27">
											<xsl:value-of select="State_Registration_No"/>
										</td>
										<td class="size27">
											X
										</td>
										<td class="size27">
											<xsl:value-of select="Amount"/>
										</td>
									</tr>
								</xsl:for-each>
						</tbody>
						<tbody>
								<xsl:for-each select="Sections/Sections_6-7_d/Section_6_5_d/A6-5-6/Data_Row">
									<tr>
										<td class="size64">
											Дебиторская задолженность по полному погашению номинала ЦБ
										</td>
										<td class="size8">
											6.5.6
										</td>
										<td class="size27">
											<xsl:value-of select="ISIN"/>
										</td>
										<td class="size27">
											<xsl:value-of select="State_Registration_No"/>
										</td>
										<td class="size27">
											X
										</td>
										<td class="size27">
											<xsl:value-of select="Amount"/>
										</td>
									</tr>
								</xsl:for-each>
						</tbody>
						<tbody>
								<xsl:for-each select="Sections/Sections_6-7_d/Section_6_5_d/A6-5-7/Data_Row">
									<tr>
										<td class="size64">
											Дебиторская задолженность по промежуточным платежам по ПФИ
										</td>
										<td class="size8">
											6.5.7
										</td>
										<td class="size27">
											X
										</td>
										<td class="size27">
											<xsl:value-of select="State_Registration_No"/>
										</td>
										<td class="size27">
											X
										</td>
										<td class="size27">
											<xsl:value-of select="Amount"/>
										</td>
									</tr>
								</xsl:for-each>
						</tbody>
					</table>
					<br/>
				</xsl:if>

				<xsl:if test="Sections/Sections_6-7_d/Section_6_6_d">
					<h3>
						6.6 - расшифровка прочей дебиторской задолженности по Контрагентам
					</h3>

					<table class="thinborder_table">
						<thead>
							<tr>
								<th class="header">Наименование дебиторской задолженности</th>
								<th class="header">Код дебиторской задолженности</th>
								<th class="header">ИНН</th>
								<th class="header">КПП</th>
								<th class="header">Номер договора/Биржевой номер сделки</th>
								<th class="header">Сумма</th>
							</tr>					
						</thead>
						<tbody>
								<xsl:for-each select="Sections/Sections_6-7_d/Section_6_6_d/A6-6-1/Data_Row">
									<tr>
										<td class="size64">
											Начисленные проценты по МНО
										</td>
										<td class="size8">
											6.6.1
										</td>
										<td class="size27">
											X
										</td>
										<td class="size27">
											X
										</td>
										<td class="size27">
											X
										</td>
										<td class="size27">
											<xsl:value-of select="Amount"/>
										</td>
									</tr>
								</xsl:for-each>
						</tbody>
						<tbody>
								<xsl:for-each select="Sections/Sections_6-7_d/Section_6_6_d/A6-6-2/Data_Row">
									<tr>
										<td class="size64">
											Дебиторская задолженность по возмещению необходимых расходов УК
										</td>
										<td class="size8">
											6.6.2
										</td>
										<td class="size27">
											<xsl:value-of select="VAT_Registration_No_Bank"/>
										</td>
										<td class="size27">
											<xsl:value-of select="KPP"/>
										</td>
										<td class="size27">
											X
										</td>
										<td class="size27">
											<xsl:value-of select="Amount"/>
										</td>
									</tr>
								</xsl:for-each>
						</tbody>
						<tbody>
								<xsl:for-each select="Sections/Sections_6-7_d/Section_6_6_d/A6-6-3/Data_Row">
									<tr>
										<td class="size64">
											Авансы выплаченные по вознаграждению УК
										</td>
										<td class="size8">
											6.6.3
										</td>
										<td class="size27">
											<xsl:value-of select="VAT_Registration_No_Bank"/>
										</td>
										<td class="size27">
											<xsl:value-of select="KPP"/>
										</td>
										<td class="size27">
											X
										</td>
										<td class="size27">
											<xsl:value-of select="Amount"/>
										</td>
									</tr>
								</xsl:for-each>
						</tbody>
						<tbody>
								<xsl:for-each select="Sections/Sections_6-7_d/Section_6_6_d/A6-6-4/Data_Row">
									<tr>
										<td class="size64">
											Расходы по страхованию имущества
										</td>
										<td class="size8">
											6.6.4
										</td>
										<td class="size27">
											<xsl:value-of select="VAT_Registration_No_Bank"/>
										</td>
										<td class="size27">
											<xsl:value-of select="KPP"/>
										</td>
										<td class="size27">
											X
										</td>
										<td class="size27">
											<xsl:value-of select="Amount"/>
										</td>
									</tr>
								</xsl:for-each>
						</tbody>
						<tbody>
								<xsl:for-each select="Sections/Sections_6-7_d/Section_6_6_d/A6-6-5/Data_Row">
									<tr>
										<td class="size64">
											Дебиторская задолженность по ошибочно списанным средствам (суммы, списанные со счетов до выяснения)
										</td>
										<td class="size8">
											6.6.5
										</td>
										<td class="size27">
											<xsl:value-of select="VAT_Registration_No_Bank"/>
										</td>
										<td class="size27">
											<xsl:value-of select="KPP"/>
										</td>
										<td class="size27">
											X
										</td>
										<td class="size27">
											<xsl:value-of select="Amount"/>
										</td>
									</tr>
								</xsl:for-each>
						</tbody>
						<tbody>
								<xsl:for-each select="Sections/Sections_6-7_d/Section_6_6_d/A6-6-6/Data_Row">
									<tr>
										<td class="size64">
											Прочая дебиторская задолженность
										</td>
										<td class="size8">
											6.6.6
										</td>
										<td class="size27">
											<xsl:value-of select="VAT_Registration_No_Bank"/>
										</td>
										<td class="size27">
											<xsl:value-of select="KPP"/>
										</td>
										<td class="size27">
											<xsl:value-of select="No_Bank_Agreement"/>
										</td>
										<td class="size27">
											<xsl:value-of select="Amount"/>
										</td>
									</tr>
								</xsl:for-each>
						</tbody>
					</table>
					<br/>
				</xsl:if>

				<xsl:if test="Sections/Sections_6-7_d/Section_6_7_d">
					<h3>
						6.7 - расшифровка прочей дебиторской задолженности по налогам и сборам
					</h3>

					<table class="thinborder_table">
						<thead>
							<tr>
								<th class="header">Наименование дебиторской задолженности</th>
								<th class="header">Код дебиторской задолженности</th>
								<th class="header">Сумма</th>
							</tr>					
						</thead>
						<tbody>
								<xsl:for-each select="Sections/Sections_6-7_d/Section_6_7_d/A6-7-1/Data_Row">
									<tr>
										<td class="size64">
											Дебиторская задолженность по налогу на имущество
										</td>
										<td class="size8">
											6.7.1
										</td>
										<td class="size27">
											<xsl:value-of select="Amount"/>
										</td>
									</tr>
								</xsl:for-each>
						</tbody>
						<tbody>
								<xsl:for-each select="Sections/Sections_6-7_d/Section_6_7_d/A6-7-2/Data_Row">
									<tr>
										<td class="size64">
											Дебиторская задолженность по расчетам по гос.пошлине
										</td>
										<td class="size8">
											6.7.2
										</td>
										<td class="size27">
											<xsl:value-of select="Amount"/>
										</td>
									</tr>
								</xsl:for-each>
						</tbody>
						<tbody>
								<xsl:for-each select="Sections/Sections_6-7_d/Section_6_7_d/A6-7-3/Data_Row">
									<tr>
										<td class="size64">
											Дебиторская задолженность по расчетам по НДС
										</td>
										<td class="size8">
											6.7.3
										</td>
										<td class="size27">
											<xsl:value-of select="Amount"/>
										</td>
									</tr>
								</xsl:for-each>
						</tbody>
						<tbody>
								<xsl:for-each select="Sections/Sections_6-7_d/Section_6_7_d/A6-7-4/Data_Row">
									<tr>
										<td class="size64">
											Прочая дебиторская задолженность по иным налогам и сборам
										</td>
										<td class="size8">
											6.7.4
										</td>
										<td class="size27">
											<xsl:value-of select="Amount"/>
										</td>
									</tr>
								</xsl:for-each>
						</tbody>
					</table>
					<br/>
				</xsl:if>
				
				<xsl:if test="Sections/Sections_6-7_d/Section_7_2_d">
					<h3>
						7.2 -   расшифровка прочей кредиторской задолженности по ЦБ, ПФИ
					</h3>

					<table class="thinborder_table">
						<thead>
							<tr>
								<th class="header">Наименование кредиторской задолженности</th>
								<th class="header">Код кредиторской задолженности</th>
								<th class="header">ISIN</th>
								<th class="header">Номер гос. регистрации</th>
								<th class="header">Номер договора/Биржевой номер сделки</th>
								<th class="header">Сумма</th>
							</tr>					
						</thead>
						<tbody>
								<xsl:for-each select="Sections/Sections_6-7_d/Section_7_2_d/A7-2-1/Data_Row">
									<tr>
										<td class="size64">
											Отрицательная переоценка сделок Т+
										</td>
										<td class="size8">
											7.2.1
										</td>
										<td class="size27">
											<xsl:value-of select="ISIN"/>
										</td>
										<td class="size27">
											<xsl:value-of select="State_Registration_No"/>
										</td>
										<td class="size27">
											<xsl:value-of select="No_Bank_Agreement"/>
										</td>
										<td class="size27">
											<xsl:value-of select="Amount"/>
										</td>
									</tr>
								</xsl:for-each>
						</tbody>
						<tbody>
								<xsl:for-each select="Sections/Sections_6-7_d/Section_7_2_d/A7-2-2/Data_Row">
									<tr>
										<td class="size64">
											Кредиторская задолженность по договорам купли-продажи ценных бумаг
										</td>
										<td class="size8">
											7.2.2
										</td>
										<td class="size27">
											<xsl:value-of select="ISIN"/>
										</td>
										<td class="size27">
											<xsl:value-of select="State_Registration_No"/>
										</td>
										<td class="size27">
											<xsl:value-of select="No_Bank_Agreement"/>
										</td>
										<td class="size27">
											<xsl:value-of select="Amount"/>
										</td>
									</tr>
								</xsl:for-each>
						</tbody>
						<tbody>
								<xsl:for-each select="Sections/Sections_6-7_d/Section_7_2_d/A7-2-3/Data_Row">
									<tr>
										<td class="size64">
											Кредиторская задолженность по налогу на дивиденды
										</td>
										<td class="size8">
											7.2.3
										</td>
										<td class="size27">
											<xsl:value-of select="ISIN"/>
										</td>
										<td class="size27">
											<xsl:value-of select="State_Registration_No"/>
										</td>
										<td class="size27">
											X
										</td>
										<td class="size27">
											<xsl:value-of select="Amount"/>
										</td>
									</tr>
								</xsl:for-each>
						</tbody>
						<tbody>
								<xsl:for-each select="Sections/Sections_6-7_d/Section_7_2_d/A7-2-4/Data_Row">
									<tr>
										<td class="size64">
											Кредиторская задолженность по промежуточным платежам по ПФИ
										</td>
										<td class="size8">
											7.2.4
										</td>
										<td class="size27">
											X
										</td>
										<td class="size27">
											<xsl:value-of select="State_Registration_No"/>
										</td>
										<td class="size27">
											X
										</td>
										<td class="size27">
											<xsl:value-of select="Amount"/>
										</td>
									</tr>
								</xsl:for-each>
						</tbody>
					</table>
					<br/>
				</xsl:if>
				
				<xsl:if test="Sections/Sections_6-7_d/Section_7_3_d">
					<h3>
						7.3 - расшифровка прочей кредиторской задолженности по Контрагентам
					</h3>

					<table class="thinborder_table">
						<thead>
							<tr>
								<th class="header">Наименование кредиторской задолженности</th>
								<th class="header">Код кредиторской задолженности</th>
								<th class="header">ИНН</th>
								<th class="header">КПП</th>
								<th class="header">Номер договора/Биржевой номер сделки</th>
								<th class="header">Сумма</th>
							</tr>					
						</thead>
						<tbody>
								<xsl:for-each select="Sections/Sections_6-7_d/Section_7_3_d/A7-3-1/Data_Row">
									<tr>
										<td class="size64">
											Оплата услуг/вознаграждение Спецдепозитария
										</td>
										<td class="size8">
											7.3.1
										</td>
										<td class="size27">
											<xsl:value-of select="VAT_Registration_No_Bank"/>
										</td>
										<td class="size27">
											<xsl:value-of select="KPP"/>
										</td>
										<td class="size27">
											X
										</td>
										<td class="size27">
											<xsl:value-of select="Amount"/>
										</td>
									</tr>
								</xsl:for-each>
						</tbody>
						<tbody>
								<xsl:for-each select="Sections/Sections_6-7_d/Section_7_3_d/A7-3-2/Data_Row">
									<tr>
										<td class="size64">
											Вознаграждение УК/Фонда
										</td>
										<td class="size8">
											7.3.2
										</td>
										<td class="size27">
											<xsl:value-of select="VAT_Registration_No_Bank"/>
										</td>
										<td class="size27">
											<xsl:value-of select="KPP"/>
										</td>
										<td class="size27">
											X
										</td>
										<td class="size27">
											<xsl:value-of select="Amount"/>
										</td>
									</tr>
								</xsl:for-each>
						</tbody>
						<tbody>
								<xsl:for-each select="Sections/Sections_6-7_d/Section_7_3_d/A7-3-3/Data_Row">
									<tr>
										<td class="size64">
											Оплата услуг аудитора, оценщика
										</td>
										<td class="size8">
											7.3.3
										</td>
										<td class="size27">
											<xsl:value-of select="VAT_Registration_No_Bank"/>
										</td>
										<td class="size27">
											<xsl:value-of select="KPP"/>
										</td>
										<td class="size27">
											X
										</td>
										<td class="size27">
											<xsl:value-of select="Amount"/>
										</td>
									</tr>
								</xsl:for-each>
						</tbody>
						<tbody>
								<xsl:for-each select="Sections/Sections_6-7_d/Section_7_3_d/A7-3-4/Data_Row">
									<tr>
										<td class="size64">
											Кредиторская задолженность по ошибочно полученным средствам (суммы, зачисленные на счета до выяснения)
										</td>
										<td class="size8">
											7.3.4
										</td>
										<td class="size27">
											<xsl:value-of select="VAT_Registration_No_Bank"/>
										</td>
										<td class="size27">
											<xsl:value-of select="KPP"/>
										</td>
										<td class="size27">
											X
										</td>
										<td class="size27">
											<xsl:value-of select="Amount"/>
										</td>
									</tr>
								</xsl:for-each>
						</tbody>
						<tbody>
								<xsl:for-each select="Sections/Sections_6-7_d/Section_7_3_d/A7-3-5/Data_Row">
									<tr>
										<td class="size64">
											Прочие расходы по брокерскому договору
										</td>
										<td class="size8">
											7.3.5
										</td>
										<td class="size27">
											<xsl:value-of select="VAT_Registration_No_Bank"/>
										</td>
										<td class="size27">
											<xsl:value-of select="KPP"/>
										</td>
										<td class="size27">
											X
										</td>
										<td class="size27">
											<xsl:value-of select="Amount"/>
										</td>
									</tr>
								</xsl:for-each>
						</tbody>
						<tbody>
								<xsl:for-each select="Sections/Sections_6-7_d/Section_7_3_d/A7-3-6/Data_Row">
									<tr>
										<td class="size64">
											Прочая кредиторская задолженность
										</td>
										<td class="size8">
											7.3.6
										</td>
										<td class="size27">
											<xsl:value-of select="VAT_Registration_No_Bank"/>
										</td>
										<td class="size27">
											<xsl:value-of select="KPP"/>
										</td>
										<td class="size27">
											<xsl:value-of select="No_Bank_Agreement"/>
										</td>
										<td class="size27">
											<xsl:value-of select="Amount"/>
										</td>
									</tr>
								</xsl:for-each>
						</tbody>
					</table>
					<br/>
				</xsl:if>
				
				<xsl:if test="Sections/Sections_6-7_d/Section_7_4_d">
					<h3>
						7.4 - расшифровка прочей кредиторской задолженности по налогам и сборам
					</h3>

					<table class="thinborder_table">
						<thead>
							<tr>
								<th class="header">Наименование кредиторской задолженности</th>
								<th class="header">Код кредиторской задолженности</th>
								<th class="header">Сумма</th>
							</tr>					
						</thead>
						<tbody>
								<xsl:for-each select="Sections/Sections_6-7_d/Section_7_4_d/A7-4-1/Data_Row">
									<tr>
										<td class="size64">
											Расчеты по налогу на имущество
										</td>
										<td class="size8">
											7.4.1
										</td>
										<td class="size27">
											<xsl:value-of select="Amount"/>
										</td>
									</tr>
								</xsl:for-each>
						</tbody>
						<tbody>
								<xsl:for-each select="Sections/Sections_6-7_d/Section_7_4_d/A7-4-2/Data_Row">
									<tr>
										<td class="size64">
											Кредиторская задолженность по расчетам по НДС
										</td>
										<td class="size8">
											7.4.2
										</td>
										<td class="size27">
											<xsl:value-of select="Amount"/>
										</td>
									</tr>
								</xsl:for-each>
						</tbody>
						<tbody>
								<xsl:for-each select="Sections/Sections_6-7_d/Section_7_4_d/A7-4-3/Data_Row">
									<tr>
										<td class="size64">
											Расчеты по уплате гос.пошлины
										</td>
										<td class="size8">
											7.4.3
										</td>
										<td class="size27">
											<xsl:value-of select="Amount"/>
										</td>
									</tr>
								</xsl:for-each>
						</tbody>
						<tbody>
								<xsl:for-each select="Sections/Sections_6-7_d/Section_7_4_d/A7-4-4/Data_Row">
									<tr>
										<td class="size64">
											Расчеты с бюджетом по иным налогам и сборам
										</td>
										<td class="size8">
											7.4.4
										</td>
										<td class="size27">
											<xsl:value-of select="Amount"/>
										</td>
									</tr>
								</xsl:for-each>
						</tbody>
					</table>
					<br/>
				</xsl:if>	

				<br/>

				<h2>Итоговые данные</h2>

				<table class="thinborder_table">					
					<tbody>
						<tr>
							<th class="header"  colspan="2">Итоговая сумма</th>
						</tr>
						<tr>
							<td class="table_cell_amnt" colspan="2">
								<xsl:value-of select="Total_By_Report/Amount"/>
							</td>
						</tr>
						<tr>
							<th class="header"  colspan="2">Сведения о должностном лице, ответственном за составление отчетности</th>
						</tr>
						<tr>
							<td class="table_cell_l" width="100">ФИО:</td><td class="table_cell_l" ><xsl:value-of select="СведенияДолжнЛицоСостОтчет/FIO"/></td>
						</tr>
						<tr>
							<td class="table_cell_l" width="100">Должность: </td><td class="table_cell_l" ><xsl:value-of select="СведенияДолжнЛицоСостОтчет/Position"/></td>
						</tr>
					</tbody>
				</table>
			</body>
		</html>
	</xsl:template>
</xsl:stylesheet>
