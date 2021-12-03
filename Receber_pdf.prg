*================================================================================================================================================

*      :: Data Criação:    30/06/2021
*      :: Programador:     jemptygrc
*      :: Objetivo:    Receber Link dos pdfs já assinados    
* Histórico de Versões
*      :: 06/07/2021 »» JM :: Retirada mensagem de ajuda ao desenvolvimento, timeout na msg com o status
*================================================================================================================================================


*Get invoice PDF PRODUCAO
*https://dcn-solution.saphety.com/Dcn.Sandbox.Client/assets/api-docs/notebooks/get-document-formats.html#get-invoice-pdf-or-ubl-from-archive

if !pergunta("Pretende receber o ficheiro PDF",1,"Este processo pode demorar algum tempo",.T.)
	msg("Operaçãoo cancelada","WAIT")
	return
endif
************************************************************************************************
************************************************************************************************
****1. Get a token (Account/getToken)
LOCAL my_response
LOCAL xpos
LOCAL my_token
*Parametros JSON para envio paraAPI
TEXT TO mJSON TEXTMERGE NOSHOW
{
		"username": "geral@alguem.com",
		"password": "Password*"
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
msg(my_token)
************************************************************************************************
************************************************************************************************
****2. Get a Document storage by DocumentId 
LOCAL my_outbound
SELECT factFE
my_outbound=alltrim(factFE.OUTBOUND)
*Parametros JSON para envio para a API
TEXT TO payload TEXTMERGE NOSHOW
{
	"ServerBaseUrl": "https://dcn-solution.saphety.com/Dcn.Business.WebApi"
	"OutboundFinancialDocumentId": "<<my_outbound>>"
}
ENDTEXT
**SANDBOX "ServerBaseUrl": "https://dcn-solution.saphety.com/Dcn.Sandbox.WebApi"
*URL da API
service_url = "https://dcn-solution.saphety.com/Dcn.Business.WebApi/api/OutboundFinancialDocument/documentFormats/"+my_outbound
*messagebox(service_url,"service_url")
loHTTP3 = CREATEOBJECT("WinHttp.WinHttpRequest.5.1")
loHTTP3.Open("POST", service_url)
*Headers da chamada
loHTTP3.SetRequestHeader("content-type", "application/json")
*Caso necessite de alguma autenticação, incluir o Header abaixo com os dados da autenticação
loHTTP3.SetRequestHeader("Authorization","bearer " + my_token)
*msg(payload)
loHTTP3.Send(payload)
***************
loHTTP3.Open("GET", service_url)
*Caso necessite de alguma autenticação, incluir o Header abaixo com os dados da autenticação
loHTTP3.SetRequestHeader("Authorization","bearer "+my_token)
loHTTP3.Send(payload)
WAIT WINDOW loHTTP3.status TIMEOUT 5
************************************************************************************************
************************************************************************************************
******************FORMATAR RESPOSTA PARA RETIRAR O URL DO PDF*****************
LOCAL xpos
LOCAL tamStrg
LOCAL my_response
LOCAL my_url
my_response=loHTTP3.responsetext
*messagebox("my_response:")
*msg(my_response)
***Substitui a resposta pelo valor a partir da data:
xpos=SUBSTR(my_response,AT('DocumentLink', my_response)+15)
***Retorna o valor total da string
tamStrg=len(xpos)
***Subtrai ao valor total da string menos o "} (2 caracteres)
my_url=SUBSTR(xpos,1,tamStrg-4)
*messagebox("ola my_url")
messagebox("Pode fazer o download do PDF através do link apresentado na seguinte mensagem","GRINCOP")
msg(my_url)
msg("Operação concluida","WAIT")
