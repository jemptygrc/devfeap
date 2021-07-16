*================================================================================================================================================
* GRINCOP LDA
*      :: Data Criação:    30/06/2021
*      :: Programador:     João Mendes
*      :: Cliente:     AMBIENTI D INTERNI
*      :: Objetivo:    Verifica estado do XML assinado eletronicamente    
* Histórico de Versões
*      :: 16/07/2021 »» JM :: Registo de log
*================================================================================================================================================

*!* Definir qual a pasta no servidor *!*
LOCAL my_folder
my_folder=""
my_folder="\\192.168.0.11\Dropbox\Dados\FEAP\Log\LXML\"

************************************************************************************************


*CHECK INVOICE STATUS PRODUCAO
*https://dcn-solution.saphety.com/Dcn.Sandbox.Client/assets/api-docs/notebooks/get-document.html
if !pergunta("Pretende verificar o estado do XML?",1,"Este processo pode demorar algum tempo",.T.)
	msg("Operação cancelada","WAIT")
	return
endif
************************************************************************************************
************************************************************************************************
****1. Get a token (Account/getToken)
LOCAL my_response
LOCAL xpos
LOCAL my_token

*Parametros JSON para envio à API
TEXT TO mJSON TEXTMERGE NOSHOW
{
	"username": "geral@adinterni.com",
	"password": "Ambientifact2021*"
}
ENDTEXT

****URL da API
**Producao
mBaseURL = "https://dcn-solution.saphety.com/Dcn.Business.WebApi/api/Account/GetToken"
loHTTP3 = CREATEOBJECT("WinHttp.WinHttpRequest.5.1")
loHTTP3.Open("POST", mBaseURL)

*Headers da chamada
loHTTP3.SetRequestHeader("content-type", "application/json")

loHTTP3.Send(mJSON)

***Resposta completa
my_response=loHTTP3.responsetext

*****************************************************
***Transformacao para isolar o token
xpos=SUBSTR(my_response,AT('Data', my_response)+7)
***Retorna o valor total da string
local tamstrg
tamstrg=len(xpos)
***Subtrai ao valor total da string menos o "} (2 caracteres)
my_token=SUBSTR(xpos,1,tamstrg-2)
msg(my_token)

************************************************************************************************
************************************************************************************************
****2. Get a Document storage by DocumentId 
SELECT FT
LOCAL nomeDoc, numFact
nomeDoc=""
numFact=0
nomeDoc=alltrim(ft.Nmdoc)
numFact=astr(ft.Fno)


SELECT ft3
LOCAL my_outbound
my_outbound=alltrim(ft3.u_OUTBOUND)
*Parametros JSON para envio à API
TEXT TO payload TEXTMERGE NOSHOW
{
	"ServerBaseUrl": "https://dcn-solution.saphety.com/Dcn.Business.WebApi"
	"OutboundFinancialDocumentId": "<<my_outbound>>"
}
ENDTEXT
**SANDBOX "ServerBaseUrl": "https://dcn-solution.saphety.com/Dcn.Sandbox.WebApi"

*URL da API
**PRODUCAO
service_url = "https://dcn-solution.saphety.com/Dcn.Business.WebApi/api/OutboundFinancialDocument/"+my_outbound
*messagebox(service_url,"service_url")

loHTTP3 = CREATEOBJECT("WinHttp.WinHttpRequest.5.1")
loHTTP3.Open("POST", service_url)

*Headers da chamada
loHTTP3.SetRequestHeader("content-type", "application/json")

*Caso necessite de alguma autenticação, incluir o Header abaixo com os dados da autenticação
loHTTP3.SetRequestHeader("Authorization","bearer " + my_token)

*msg(payload)
loHTTP3.Send(payload)

*msg(loHTTP3.responsetext)
*local request_data
*request_data=loHTTP3.Send(payload)
*messagebox(request_data,"request_data")
*******************************************************
loHTTP3.Open("GET", service_url)
*Headers da chamada
*loHTTP3.SetRequestHeader("content-type", "application/json")
*Caso necessite de alguma autenticação, incluir o Header abaixo com os dados da autenticação
loHTTP3.SetRequestHeader("Authorization","bearer "+my_token)
*loHTTP3.Send(mJSONoutbound)
loHTTP3.Send(payload)
WAIT WINDOW loHTTP3.status Timeout 5

******************FORMATAR RESPOSTA PARA RETIRAR O ESTADO DO DOCUMENTO*****************
LOCAL my_response
LOCAL my_integration_inicial,my_integration_final,my_integration_resultado
LOCAL my_integration
***Resposta completa
my_response=loHTTP3.responsetext
messagebox("my_response completo:")
msg(my_response)
**IntegrationStatus
my_integration_inicial=AT('IntegrationStatus',my_response)+20
my_integration_final=AT('IntegrationDate',my_response)-3
my_integration_resultado=my_integration_final-my_integration_inicial
my_integration=SUBSTR(my_response,my_integration_inicial,my_integration_resultado)
*messagebox(my_integration)
*msg(my_integration)

***************************************************************************************
***************************************************************************************
******************************VERIFICA SE ESTADO E VALIDO******************************
LOCAL isValid
LOCAL isValidInicial,isValidFinal,isValidResultado
isValid=""
**isValid (Pode ser true ou false)
isValidInicial=AT('IsValid',my_response)+9
isValidFinal=AT('Errors',my_response)-2
isValidResultado=isValidFinal-isValidInicial
isValid=SUBSTR(my_response,isValidInicial,isValidResultado)

*messagebox("OLA isValidInicial")
*msg(isValidInicial)
*messagebox("OLA isValidFinal")
*msg(isValidFinal)
*messagebox("OLA ISVALID")
*msg(isValid)


IF isValid="false"
	LOCAL my_errorCode
	LOCAL errorCodeInicial,errorCodeFinal,errorCodeResultado
	my_errorCode=""
	errorCodeInicial=""
	errorCodeFinal=""
	errorCodeResultado=""
	
	**errorCode
	errorCodeInicial=AT('Code',my_response)+7
	errorCodeFinal=AT('Field',my_response)-3
	errorCodeResultado=(errorCodeFinal)-(errorCodeInicial)
	my_errorCode=SUBSTR(my_response,errorCodeInicial,errorCodeResultado)
	messagebox(my_errorCode,"errorCode")

	***
	StrToFile(my_errorCode, my_folder+nomeDoc+"-"+numFact+"-"+"verifica_estado.txt",4)
	*msg(my_teste)
	Create Cursor curs_err1 (nome c(250), errorCode c(250))
	SELECT curs_err1
		GO TOP
		Append Blank
		Replace curs_err1.nome with "Erro nº1"
		Replace curs_err1.ErrorCode with alltrim(my_errorCode)

	LOCAL i
	i=2
	declare list_tit(i),list_cam(i),list_pic(i),list_tam(i),list_ali(i),list_ronly(i),list_combo(i)
	*SELECT curs_err1
	i=0
	i=i+1
	list_tit(i) = "Erro"
	list_cam(i) = "curs_err1.nome"
	list_pic(i) = ""
	list_ali(i) = 0
	list_ronly(i)=.t.
	list_combo(i)=""
	i=i+1
	list_tit(i) = "Descrição do Erro"
	list_cam(i) = "curs_err1.errorCode"
	list_pic(i) = ""
	list_ali(i) = 0
	list_ronly(i)=.t.
	list_combo(i)=""


	list_tam=15*10
	****************************
	m.escolheu=.f.
	=CURSORSETPROP('Buffering',5,"curs_err1")
	browlist("ALERTA GRINCOP ","curs_err1","curs_err1")
	

	*********************************************************************
	DO CASE
	CASE my_errorCode = "INVALID_INTL_VAT_CODE"
		msg("NIF inválido na fatura: "+chr(13)+chr(10)+"Por favor verifique se o cliente: tem o NIF bem preenchido (Ex: PT123456789)","FORM")
		return
	CASE my_errorCode = "DATETIME_FORMAT_EXPECTED"
		msg("DATA inválida na fatura: "+chr(13)+chr(10)+"Por favor abra o último registo no ecrã das faturas","FORM")
	CASE my_errorCode = "OUTBOUND_FINANCIAL_DOCUMENT_ALREADY_SENT"
		msg("A fatura : já foi enviada e não pode ser enviada novamente","FORM")
		return
	CASE my_errorCode = "EXPECTED_DATA_NOT_FOUND"
		msg(" ERRO EM ANALISE GRINCOP","FORM")
		return	
	OTHERWISE
		msg("Erro desconhecido! Por favor contate o administrador de sistema GRINCOP")
		Gowww("https://www.grincop.pt/contactos/")
	ENDCASE
RETURN
ENDIF



***************************************************************************************
***************************************************************************************
***************************CONDIÇÕES DO ESTADO DE INTEGRAÇÃO***************************
DO CASE
CASE (my_integration="Sent")
	messagebox("O documento foi enviado","GRINCOP")
CASE (my_integration="Paid")
	messagebox("O documento está pago","GRINCOP")
CASE (my_integration="Error")
	messagebox("O documento tem erros","GRINCOP")
CASE (my_integration="Not_Sent")
	messagebox("O documento não foi enviado","GRINCOP")
CASE (my_integration="NotIntegrated")
	messagebox("O documento não está integrado","GRINCOP")
CASE (my_integration="Rejected")
	messagebox("O documento foi rejeitado","GRINCOP")
OTHERWISE
	messagebox("Erro desconhecido","GRINCOP")
ENDCASE



****************************************************************************************

