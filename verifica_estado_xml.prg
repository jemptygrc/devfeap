*================================================================================================================================================
* GRINCOP LDA
*      :: Data Criação:    30/06/2021
*      :: Programador:     João Mendes
*      :: Cliente:     AMBIENTI D INTERNI
*      :: Objetivo:    Verifica estado do PDF assinado eletronicamente    
* Histórico de Versões
*      :: 06/07/2021 »» JM :: Retirar mensagens de desenvolvimento
*================================================================================================================================================


*CHECK INVOICE STATUS PRODUCAO
*https://dcn-solution.saphety.com/Dcn.Sandbox.Client/assets/api-docs/notebooks/get-document.html
if !pergunta("Pretende verificar o estado do PDF?",1,"Este processo pode demorar algum tempo",.T.)
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
*Caso necessite de alguma autenticação, incluir o Header abaixo com os dados da autenticação
*loHTTP3.SetRequestHeader("Authorization","Basic OWYwODBhY2ItYmIzMC00Y2ZhLWE4YjQtODU4ZjFmZjk3NDYzOmgjQlNhWg==")
loHTTP3.Send(mJSON)
***Resposta completa
my_response=loHTTP3.responsetext
***Substitui a resposta pelo valor a partir da data:
xpos=SUBSTR(my_response,AT('Data', my_response)+7)
***Retorna o valor total da string
local tamstrg
tamstrg=len(xpos)
***Subtrai ao valor total da string menos o "} (2 caracteres)
my_token=SUBSTR(xpos,1,tamstrg-2)
*msg(my_token)
************************************************************************************************
************************************************************************************************
****2. Get a Document storage by DocumentId 
LOCAL my_outbound
SELECT factFE
my_outbound=alltrim(factFE.OUTBOUND)
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
*messagebox("my_response completo:")
*msg(my_response)
**IntegrationStatus
my_integration_inicial=AT('IntegrationStatus',my_response)+20
my_integration_final=AT('IntegrationDate',my_response)-3
my_integration_resultado=my_integration_final-my_integration_inicial
my_integration=SUBSTR(my_response,my_integration_inicial,my_integration_resultado)
*msg(my_integration)
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