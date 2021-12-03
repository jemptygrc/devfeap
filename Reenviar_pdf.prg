*================================================================================================================================================

*      :: Data Criação:    30/06/2021
*      :: Programador:     jemptygrc
*      :: Objetivo:    Reenviar por email PDFs ja assinados    
* Histórico de Versões
*      :: 06/07/2021 »» JM :: Validação e identação codigo
*================================================================================================================================================



*Resend PDF invoice email notification
*https://dcn-solution.saphety.com/Dcn.Sandbox.Client/assets/api-docs/notebooks/sent-notifications.html
if !pergunta("Pretende reenviar a(s) fatura(s)?",1,"Este processo pode demorar algum tempo",.T.)
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
		"username": "geral@alguem.pt",
		"password": "Password"
}
ENDTEXT
*URL da API
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
*messagebox("OLA RESPOSTA COMPLETA")
*msg(my_response)
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
****2. Resend PDF invoice notifications 
LOCAL emailEnvio
emailEnvio=""
LOCAL my_outbound
my_outbound=""
select factFE
emailEnvio=alltrim(factFE.EMAIL)
my_outbound=alltrim(factFE.OUTBOUND)
numFact=factFE.NUMDOC
*Parametros JSON para envio à API
TEXT TO payload TEXTMERGE NOSHOW
{
	"OutboundFinancialDocumentId": "<<my_outbound>>",
	"DestinationEmails":[
         {
             "Email": "<<emailEnvio>>",
             "SendAttachment": true,
             "LanguageCode": "PT"
         }
	]
}
ENDTEXT
*URL da API
*mBaseURL2 = "https://dcn-solution.saphety.com/Dcn.Sandbox.WebApi/api/OutboundFinancialDocumentMaintnance/sendAditionalNotifications"
mBaseURL2 = "https://dcn-solution.saphety.com/Dcn.Business.WebApi/api/OutboundFinancialDocumentMaintnance/sendAditionalNotifications"
loHTTP3 = CREATEOBJECT("WinHttp.WinHttpRequest.5.1")
loHTTP3.Open("POST", mBaseURL2)
*Headers da chamada
loHTTP3.SetRequestHeader("content-type", "application/json")
*Caso necessite de alguma autenticação, incluir o Header abaixo com os dados da autenticação
loHTTP3.SetRequestHeader("Authorization","bearer " + my_token)
*msg(payload)
loHTTP3.Send(payload)

***
LOCAL request_data
request_data=""
request_data=loHTTP3.responsetext
*messagebox("OLA request_data")
*msg(request_data)
*******************************************
***VALIDAR SE EMAIL ESTA BEM PREENCHIDO
LOCAL errorCodeEmail_Inicial,errorCodeEmail_Final,errorCodeEmail_Resultado
errorCodeEmail_Inicial=0
errorCodeEmail_Final=0
errorCodeEmail_Resultado=0
errorCodeEmail=""
errorCodeEmail_Inicial=AT('Code',request_data)+7
errorCodeEmail_Final=AT('Field',request_data)-3
errorCodeEmail_Resultado=errorCodeEmail_Final-errorCodeEmail_Inicial
errorCodeEmail=SUBSTR(request_data,errorCodeEmail_Inicial,errorCodeEmail_Resultado)
*msg(errorCodeEmail)
DO CASE
CASE errorCodeEmail = "INVALID_EMAIL"
		msg("Atenção! A fatura: «"+astr(numFact)+"» não foi enviada! O e-mail do cliente: «"+alltrim(cliente)+"» está mal preenchido. Por favor verifique a ficha de cliente.","FORM")
	return
CASE empty(errorCodeEmail)
	msg("Sem erros! Em processamento...","TRADUZIR")
OTHERWISE
	MESSAGEBOX("Erro desconhecido no envio de e-mail! Por favor contate o administrador de sistema JM")
	return
ENDCASE

messagebox("Sucesso! E-mail(s) enviado(s)"+chr(13)+chr(10)+chr(13)+chr(10)+"Clique em OK para continuar",0+64,"JM")
msg("Operação concluída","WAIT")
