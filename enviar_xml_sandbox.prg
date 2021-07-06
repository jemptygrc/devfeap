***ENVIAR XML SANDBOX
***CLIENTE: VALCON
***DATA: 15/06/2021
***ULTIMA ALTERACAO: 29/06/2021

*************************************************************************************************
*************************************************************************************************
*************************************************************************************************
***********DECLARACAO DE VARIAVEIS

***DADOS FATURAS
PRIVATE my_pathXML
PRIVATE numFact
PRIVATE nomeCliente
PRIVATE nomeDoc

PRIVATE my_outbound
PRIVATE my_ftstamp
PRIVATE errorCode

my_ftstamp=""
my_pathXML=""
numFact=0
nomeCliente=""
nomeDoc=""

LOCAL nifEmpresa
nifEmpresa=""
nifEmpresa="PT508369444"

*SELECT factFe
SELECT FT
SELECT FT3
my_ftstamp=alltrim(ft.ftstamp)
my_pathXML=alltrim(ft3.u_pathXML)
numFact=FT.FNO         
nomeDoc=alltrim(FT.NMDOC)
nomeCliente=alltrim(FT.NOME)


*************************************************************************************************************************
*************************************************************************************************************************
if !pergunta("Pretende enviar o XML/CIUS PT?",1,"Deve verificar se j� tem o ficheiro XML exportado",.T.)
	msg("Opera��o cancelada","WAIT")
	return
endif


*select factFe
*GO TOP
*SCAN

	*!* Validar se o XML foi gerado
	if empty(FT3.u_pathXML)
		msg("Aten��o! Desculpe, mas escolheu um documento que n�o tem o ficheiro XML."+chr(13)+chr(33)+"Deve exportar o documento para ficheiro XML e s� depois fazer o envio","FORM")
		RETURN
	else

	***RESPOSTAS
	LOCAL responseToken,responseRequestID,responseRequestStatus,responseIntegrated
	responseToken=""
	responseRequestID=""
	responseRequestStatus=""
	responseIntegrated=""
	**********************

	***URLS
	LOCAL my_tokenURL,my_serverBaseURL,my_serviceURL,my_IntegratedURL
	my_tokenURL=""
	my_serverBaseURL=""
	my_serviceURL=""
	my_IntegratedURL=""
	**********************

	LOCAL xpos
	xpos=0

	LOCAL my_token
	my_token=""

	LOCAL my_requestid
	my_requestid=""


*************************************************************************************************
*************************************************************************************************
*************************************************************************************************

	*Parametros JSON para envio à API
	TEXT TO mJSON TEXTMERGE NOSHOW
	{
		"username": "joao.mendes@grincop.pt",
		"password":"Grincop2021"
	}
	ENDTEXT

	*!* URL da API SANDBOX
	my_tokenURL = "https://dcn-solution.saphety.com/Dcn.Sandbox.WebApi/api/Account/GetToken"

	*!* URL da API SANDBOX
	*!*my_tokenURL = "https://dcn-solution.saphety.com/Dcn.Business.WebApi/api/Account/GetToken"

	loHTTP3 = CREATEOBJECT("WinHttp.WinHttpRequest.5.1")
	loHTTP3.Open("POST", my_tokenURL)

	*Headers da chamada
	loHTTP3.SetRequestHeader("content-type", "application/json")

	***Envio
	loHTTP3.Send(mJSON)

	***Resposta completa
	responseToken=loHTTP3.responsetext

	***Substitui a resposta pelo valor a partir da data:
	xpos=SUBSTR(responseToken,AT('Data', responseToken)+7)

	***Retorna o valor total da string
	local tamstrg
	tamstrg=len(xpos)

	***Subtrai ao valor total da string menos o "} (2 caracteres)
	my_token=SUBSTR(xpos,1,tamstrg-2)
	*msg(my_token)


	SELECT FT
	my_ftstamp=""
	my_ftstamp=ft.ftstamp

	**Update token
	LOCAL my_updt2
	my_updt2=""
	my_updt2=my_updt2+[update ft set ]
	my_updt2=my_updt2+[ft.U_TOKEN=']+alltrim(my_token)+[' ]
	my_updt2=my_updt2+[where ft.ftstamp=']+alltrim(my_ftstamp)+[' ]
	u_sqlexec(my_updt2)
	*msg("feito update do token na ft")



*************************************************************************************************
*************************************************************************************************
*************************************************************************************************
****LER O FICHEIRO XML GERADO E GUARDAR NUMA VARIAVEL
	LOCAL loXml
	LOCAL lcStrXML
	LOCAL lnSuccess

	LOCAL my_data
	my_data=""

	*msg(my_pathXML)
	my_data=filetostr(my_pathXML)
	*my_data=filetostr('F:\04-GRINCOP_PHC\ft03900000000272021.xml')


*************************************************************************************************
*************************************************************************************************
*************************************************************************************************
****2. Send invoice request (CountryFormatAsyncRequest/processDocument)
	Set Point To "."

	LOCAL my_payload
	my_payload=""
	my_payload=my_data

	*!*SANDBOX
	*my_serverBaseURL="https://dcn-solution.saphety.com/Dcn.Sandbox.WebApi/api/CountryFormatAsyncRequest/processDocument/PT502635673/Invoice/PT"
	my_serverBaseURL="https://dcn-solution.saphety.com/Dcn.Sandbox.WebApi/api/CountryFormatAsyncRequest/processDocument/"+nifEmpresa+"/Invoice/PT"

	

	*!*PRODUCAO
	*!*my_serverBaseURL=""https://dcn-solution.saphety.com/Dcn.Business.WebApi/api/CountryFormatAsyncRequest/processDocument/PT502635673/Invoice/PT"

	loHTTP3 = CREATEOBJECT("WinHttp.WinHttpRequest.5.1")
	loHTTP3.Open("POST", my_serverBaseURL)

	*Headers da chamada
	loHTTP3.SetRequestHeader("content-type", "application/xml")

	*Caso necessite de alguma autenticacao, incluir o Header abaixo com os dados da autenticacao
	loHTTP3.SetRequestHeader("Authorization","bearer " + my_token)


	messagebox("payload que vai ser enviado")
	msg(my_payload)
	loHTTP3.Send(my_payload)


**********************************************
**********************************************


*******************FORMATAR MENSAGEM E APRESENTAR Requestid*******************
	***Resposta completa
	responseRequestID=loHTTP3.responsetext
	*messagebox("Resposta apos ter sido enviado o payload ->")
	*msg(responseRequestID)


	***Substitui a resposta pelo valor a partir da data:
	xpos2=SUBSTR(responseRequestID,AT('Data', responseRequestID)+7)

	***Retorna o valor total da string
	local tamstrg2
	tamstrg2=len(xpos2)

	***Subtrai ao valor total da string menos o "} (2 caracteres)
	my_requestid=SUBSTR(xpos2,1,tamstrg2-2)
	*messagebox("separado o request id")
	*msg(my_requestid)


*************************************************************************************************
*************************************************************************************************
*****3. Check to success of your request (CountryFormatAsyncRequest/{RequestId})

	*!*SANDBOX
	my_serviceURL="https://dcn-solution.saphety.com/Dcn.Sandbox.WebApi/api/CountryFormatAsyncRequest/"+my_requestid

	*!*PRODUCAO
	*!*my_serverBaseURL=""https://dcn-solution.saphety.com/Dcn.Business.WebApi/api/CountryFormatAsyncRequest/"+my_requestid


	loHTTP3 = CREATEOBJECT("WinHttp.WinHttpRequest.5.1")
	loHTTP3.Open("GET", my_serviceURL)

	*Headers da chamada
	loHTTP3.SetRequestHeader("content-type", "application/json")

	*Caso necessite de alguma autenticacao, incluir o Header abaixo com os dados da autenticacao
	loHTTP3.SetRequestHeader("Authorization","bearer " + my_token)

	loHTTP3.Send(my_serviceURL)

	responseRequestStatus=loHTTP3.responsetext
	*messagebox("Resposta Ccompleta apos ter sido enviado o my_serviceURL->")
	*msg(responseRequestStatus)


	**errorCode
	LOCAL errorCodeInicial,errorCodeFinal,errorCodeResultado

	errorCodeInicial=0
	errorCodeFinal=0
	errorCodeResultado=0
	errorCode=""

	errorCodeInicial=AT('{"Code',responseRequestStatus)+9
	errorCodeFinal=AT('Field',responseRequestStatus)-3
	errorCodeResultado=(errorCodeFinal)-(errorCodeInicial)
	errorCode=SUBSTR(responseRequestStatus,errorCodeInicial,errorCodeResultado)
	*messagebox("ola errorCode")
	*msg(errorCode)

	****CHAMADA AO PROCEDIMENTO PARA VALIDAR ERROS
	DO ProcValidaErros
	***********************************************

	****Check your request status
	LOCAL asyncStatusInicial,asyncStatusFinal,asyncStatusResultado
	LOCAL asyncStatus

	asyncStatusInicial=""
	asyncStatusFinal=0
	asyncStatusResultado=0
	asyncStatus=""

	asyncStatusInicial=SUBSTR(responseRequestStatus,AT('AsyncStatus', responseRequestStatus)+14)
	asyncStatusFinal=SUBSTR(asyncStatusInicial,AT('","', asyncStatusInicial))
	asyncStatusResultado=(len(asyncStatusInicial)-len(asyncStatusFinal))
	asyncStatus=LEFT(asyncStatusInicial,asyncStatusResultado)
	*messagebox("asynsstatus status")
	*msg(asyncStatus)


*********************************************************************************
*********************************************************************************

	LOCAL nrTentativas
	nrTentativas=0
	DO WHILE asyncStatus!="Finished"
		*msg(responseRequestStatus)
		*messagebox(asyncStatus,"asynsstatus status dentro do while")

	**************************************
		IF asyncStatus="Running"
			nrTentativas=nrTentativas+1
			msg("Tentativa: "+astr(nrTentativas)+" de 5")
			*DO ProcAtualizaEstado
			asyncStatus=""
			**************************************
			loHTTP3.Open("GET", my_serviceURL)

			*Headers da chamada
			loHTTP3.SetRequestHeader("content-type", "application/json")

			*Caso necessite de alguma autenticacao, incluir o Header abaixo com os dados da autenticacao
			loHTTP3.SetRequestHeader("Authorization","bearer "+my_token)

			loHTTP3.Send(my_requestid)

			*WAIT WINDOW loHTTP3.status

			responseRequestStatus=loHTTP3.responsetext

			status=SUBSTR(responseRequestStatus,AT('AsyncStatus', responseRequestStatus)+14)
			teste=SUBSTR(status,AT('","', status))
			teste2=0
			teste2=(len(status)-len(teste))

			asyncStatus=LEFT(status,teste2)
			*messagebox("asynsstatus status")
			msg("Estado do seu pedido: �"+asyncStatus+"�"+chr(13)+chr(10)+chr(13)+chr(10)+"Clique na tecla OK para continuar.")
			*messagebox("asyncStatus")
			*msg(asyncStatus)
			
			If nrTentativas=5
				msg("Algo correu mal... Erro de comunica��o e excesso de tentativas, tente novamente mais tarde")
			RETURN
			Endif
		ENDIF
	
		IF asyncStatus="Error"
			errorCodeInicial=AT('{"Code',responseRequestStatus)+9
			errorCodeFinal=AT('Field',responseRequestStatus)-3
			errorCodeResultado=(errorCodeFinal)-(errorCodeInicial)
			errorCode=SUBSTR(responseRequestStatus,errorCodeInicial,errorCodeResultado)

			msg("Aten��o! O documento �"+nomeDoc+" "+astr(numFact)+"� do cliente: �"+nomeCliente+"� tem erros que devem ser corrigidos")

			****CHAMADA AO PROCEDIMENTO PARA VALIDAR ERROS
			DO ProcValidaErros
			***********************************************
			EXIT
			return
		Endif


*************************************************************************************************
*************************************************************************************************
*****3.1 Get integrated destinations


	**SANDBOX
	my_IntegratedURL="https://dcn-solution.saphety.com/Dcn.Sandbox.WebApi/api/CompanyConnections/destinations/TRUSTED"

	*!*PRODUCAO
	*!*my_serverBaseURL=""https://dcn-solution.saphety.com/Dcn.Business.WebApi/api/CompanyConnections/destinations/TRUSTED"

	loHTTP3 = CREATEOBJECT("WinHttp.WinHttpRequest.5.1")
	loHTTP3.Open("GET", my_IntegratedURL)

	*Headers da chamada
	loHTTP3.SetRequestHeader("content-type", "application/json")

	*Caso necessite de alguma autenticacao, incluir o Header abaixo com os dados da autenticacao
	loHTTP3.SetRequestHeader("Authorization","bearer " + my_token)

	loHTTP3.Send(my_IntegratedURL)

	responseIntegrated=loHTTP3.responsetext
	messagebox("Resposta Ccompleta apos ter sido enviado o o get integrated->")
	msg(responseIntegrated)


	ENDDO
******


	If asyncStatus="Finished"
		*messagebox("Finalizado e responseRequestStatus para retirar outbound")
		*msg(responseRequestStatus)

		**OutboundFinancialDocumentId
		LOCAL my_outbound_inicial,my_outbound_final,my_outbound_resultado
		my_outbound=""
		my_outbound_inicial=""
		my_outbound_final=""
		my_outbound_resultado=""

		my_outbound_inicial=AT('OutboundFinancialDocumentId',responseRequestStatus)+30
		my_outbound_final=AT('IntlVatCode',responseRequestStatus)-3
		my_outbound_resultado=my_outbound_final-my_outbound_inicial
		my_outbound=SUBSTR(responseRequestStatus,my_outbound_inicial,my_outbound_resultado)
		*msg(my_outbound)

		**************************************************************************
		***CHAMADA AO PROCEDIMENTO PARA GUARDAR OUTBOUND FINANCIAL DOCUMENT ID NA FT3
		DO ProcSaveOutbound
		******************************************************************************
	Endif


*************************************************************************************************
*************************************************************************************************

Set Point To se_pointer

	ENDIF
*ENDSCAN

***********************************************************************************************
***********************************************************************************************
***********************************************************************************************
*****************************************PROCEDIMENTOS*****************************************
***********************************************************************************************
***********************************************************************************************
***********************************************************************************************
*****PROCEDIMENTO PARA GUARDAR O OUTBOUND FINANCIAL ID NA FT3
PROCEDURE ProcSaveOutbound
	updt_out=""
	TEXT TO updt_out TEXTMERGE NOSHOW
		UPDATE FT3 SET
		ft3.u_outbound=trim('<<my_outbound>>')
		WHERE	
		ft3.ft3stamp='<<my_ftstamp>>'
	ENDTEXT
		*msg(updt_out)
	if u_sqlexec ([BEGIN TRANSACTION])
		if u_sqlexec(updt_out)
			u_sqlexec([COMMIT TRANSACTION])
		else	
			u_sqlexec([ROLLBACK])
			Messagebox("Erro - updt_out - p.f. contacte o seu Administrador de Sistema GRINCOP!!")
			Gowww("https://www.grincop.pt/contactos/")
			exit
		endif
	endif
ENDPROC


***********************************************************************************************
*****PROCEDIMENTO PARA VALIDAR ERRO
PROCEDURE ProcValidaErros
*messagebox("OLA ENTREI NO PROCEDURE ProcValidaErros")
DO CASE
	CASE errorCode = "COUNTRY_LEGAL_FORMAT_NOT_RECOGNIZED"
		msg("Descri��o do Erro: "+chr(13)+chr(10)+chr(13)+chr(10)+"�COUNTRY_LEGAL_FORMAT_NOT_RECOGNIZED� Formato inv�lido do ficheiro XML no documento: �"+nomeDoc+" "+astr(numFact)+"� Por favor verifique se o cliente: �"+astr(nomeCliente)+"� tem o NIF bem preenchido (Ex: PT123456789)","FORM")
		return
	CASE errorCode = "DATETIME_FORMAT_EXPECTED"
		msg("Descri��o do Erro: "+chr(13)+chr(10)+chr(13)+chr(10)+"DATA inv�lida no documento: �"+nomeDoc+" "+astr(numFact)+"� Por favor abra o �ltimo registo no ecr� das faturas","FORM")
		return
	CASE errorCode = "NO_DESTINATION_INTEGRATION_DEFINED"
		msg("Descri��o do Erro: "+chr(13)+chr(10)+chr(13)+chr(10)+"O emissor do documento: �"+nomeDoc+" "+astr(numFact)+"� pertence a outra rede e n�o h� liga��es de integra��o definidas entre o emissor e o receptor.","FORM")
		return
	CASE errorCode = "FEATURE_UNAVAILABLE_FOR_COMPANY"
		msg("Descri��o do Erro: "+chr(13)+chr(10)+chr(13)+chr(10)+"Esta funcionalidade n�o est� dispon�vel para a sua empresa","FORM")
		return
	CASE errorCode = "BE-CIUS-PT-05"
		msg("Descri��o do Erro: "+chr(13)+chr(10)+chr(13)+chr(10)+"Imposs�vel obter o emissor."+chr(13)+chr(10)+chr(13)+chr(10)+errorCode,"FORM")
		return	
	CASE errorCode = "BE-CIUS-PT-06"
		msg("Descri��o do Erro: "+chr(13)+chr(10)+chr(13)+chr(10)+"Imposs�vel obter o recetor."+chr(13)+chr(10)+chr(13)+chr(10)+errorCode,"FORM")
		return
	CASE errorCode = "BE-CIUS-PT-07"
		msg("Descri��o do Erro: "+chr(13)+chr(10)+chr(13)+chr(10)+"Imposs�vel processar o conteudo do documento."+chr(13)+chr(10)+chr(13)+chr(10)+errorCode,"FORM")
		return
	CASE errorCode = "BR-CIUS-PT-66"
		msg("Descri��o do Erro: "+chr(13)+chr(10)+chr(13)+chr(10)+"Por favor verifique se o documento: �"+nomeDoc+" "+astr(numFact)+"� tem o Local de Descarga preenchido com a morada." +chr(13)+chr(10)+chr(13)+chr(10)+errorCode,"FORM")
		return
	CASE errorCode = "BR-CIUS-PT-67"
		msg("Descri��o do Erro: "+chr(13)+chr(10)+chr(13)+chr(10)+"O conteudo fornecido como PDF n�o est� convertido para o formato v�lido"+chr(13)+chr(10)+chr(13)+chr(10)+errorCode,"FORM")
		return
	CASE errorCode = "BR-CIUS-PT-68"
		msg("Descri��o do Erro: "+chr(13)+chr(10)+chr(13)+chr(10)+"O endere�o de email n�o � v�lido."+chr(13)+chr(10)+chr(13)+"Use um endere�o de email v�lido como <alguem@grincop.pt>"+chr(13)+chr(10)+chr(13)+chr(10)+errorCode,"FORM")
		return
	CASE errorCode = "BR-CIUS-PT-69"
		msg("Descri��o do Erro: "+chr(13)+chr(10)+chr(13)+chr(10)+"A Data de vencimento � obrigat�ria."+chr(13)+chr(10)+chr(13)+chr(10)+errorCode,"FORM")
		return
	CASE errorCode = "BR-CIUS-PT-70"
		msg("Descri��o do Erro: "+chr(13)+chr(10)+chr(13)+chr(10)+"Percentagem de imposto aplicada ao desconto � obrigat�ria."+chr(13)+chr(10)+chr(13)+chr(10)+errorCode,"FORM")
		return
	CASE errorCode = "BR-CIUS-PT-71"
		msg("Descri��o do Erro: "+chr(13)+chr(10)+chr(13)+chr(10)+"Percentagem de imposto aplicada ao encargo � obrigat�ria."+chr(13)+chr(10)+chr(13)+chr(10)+errorCode,"FORM")
		return
	CASE errorCode = "BR-CIUS-PT-72"
		msg("Descri��o do Erro: "+chr(13)+chr(10)+chr(13)+chr(10)+"IBAN inv�lido"+chr(13)+chr(10)+chr(13)+chr(10)+errorCode,"FORM")
		return
	CASE empty(errorCode)
		msg("Sem erros! Em processamento...","TRADUZIR")
OTHERWISE
		msg("Erro desconhecido! Por favor contacte o administrador de sistema GRINCOP com a seguinte informa��o: "+chr(13)+chr(10)+chr(13)+chr(10)+errorCode)
		Gowww("https://www.grincop.pt/contactos/")
ENDCASE
