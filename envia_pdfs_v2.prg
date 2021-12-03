*================================================================================================================================================

*      :: Data Criação:    30/06/2021
*      :: Programador:     jemptygrc
*      :: Cliente:     
*      :: Objetivo:    Enviar PDFs com assinatura eletronica de seguida    
* Histórico de Versões
*      :: 20/07/2021 »» JM :: Adicionado trim ao my_ftstamp e adicionada variavel my_ftstamp aos strtofile
*================================================================================================================================================


*navega("FT",)
DOREAD("FT","SFT")
sft.hide
set date YMD 

LOCAL my_response,my_response2,my_response3,my_response4
my_response=""
my_response2=""
my_response3=""
my_response4=""
LOCAL my_async
my_async=''
LOCAL xpos,xpos2
xpos=0
xpos2=0
LOCAL my_token
my_token=""
LOCAL my_requestid
my_requestid=""
LOCAL my_requestid2
my_requestid2=""
LOCAL my_requestxml
my_requestxml=""
PRIVATE asyncStatus
asyncStatus=""
PRIVATE my_ftstamp
my_ftstamp=""
PRIVATE my_outbound
my_outbound=""
PRIVATE documentLink
documentLink=""
LOCAL nifEmpresa
nifEmpresa=""
nifEmpresa="PT508369444"

LOCAL my_folder
my_folder=""
my_folder="\\XXX.XXX.XXX.XXX\PDFs\"

PRIVATE my_folderLog
my_folderLog=""
my_folderLog="\\XXX.XXX.XXX.XXX\Log\LPDF\"
********************************************************************************************
********************************************************************************************
********************************************************************************************
if !pergunta("Pretende enviar a(s) fatura(s)?",1,"Este processo pode demorar algum tempo",.T.)
	msg("Operação cancelada","WAIT")
	return
endif

IF DIRECTORY(my_folder)
        msg("Sucesso! Ligação validada ao servidor"+chr(13)+chr(13)+chr(10)+chr(13)+"Clique OK para continuar")
        msg("O servidor respondeu! Pode selecionar a(s) fatura(s)","WAIT")
    ELSE 
        msg("O servidor não respondeu","WAIT")
        msg("Algo correu mal... Não foi possível ligar ao servidor, tente novamente mais tarde"+chr(13)+chr(13)+chr(10)+chr(13)+"Clique OK para voltar")
        return
ENDIF 


********************************************************************************************
********************************************************************************************
*****BROWLIST COM LISTA DE FATURAS PARA EMITIR
select factFe

LOCAL nomeCliente,my_pathpdf
nomeCliente=factFe.CLIENTE
my_pathpdf=factFe.caminho
************************
LOCAL i
i=5
declare list_tit(i),list_cam(i),list_pic(i),list_tam(i),list_ali(i),list_ronly(i),list_combo(i)
i=0
i=i+1
list_tit(i) = "Conf?"
list_cam(i) = "factFe.sel"
list_pic(i) = "LOGIC"
list_ali(i) = 0
list_ronly(i)=.f.
list_tam(i)=8*5
list_combo(i)=""
i=i+1
list_tit(i) = "N.º Cliente"
list_cam(i) = "factFe.CLIENTE"
list_pic(i) = ""
list_ali(i) = 0
list_ronly(i)=.t.
list_combo(i)=""
i=i+1
list_tit(i) = "N.Factura"
list_cam(i) = "factFe.numdoc"
list_pic(i) = ""
list_ali(i) = 0
list_ronly(i)=.t.
list_combo(i)=""
i=i+1
list_tit(i) = "Data"
list_cam(i) = "factFe.usrdata"
list_pic(i) = ""
list_ali(i) = 0
list_ronly(i)=.t.
list_combo(i)=""
i=i+1
list_tit(i) = "Loc PDF"
list_cam(i) = "factFe.CAMINHO"
list_pic(i) = ""
list_ali(i) = 0
list_ronly(i)=.t.
list_combo(i)=""

list_tam=15*10
****************************
m.escolheu=.f.
=CURSORSETPROP('Buffering',5,"factFe")
browlist("Escolha as facturas a enviar ","factFe","factFe",.t.,.f.,.f.,.t.,.f.)
**
if .not. m.escolheu
	wait window "Escolheu Cancelar, vou sair..." nowait
	return
endif
select factFe
*GO TOP
scan
if factFe.sel
	*if empty(my_pathpdf)
		*msg("Atenção! Desculpe, mas escolheu um documento que não tem o ficheiro PDF."+chr(13)+chr(10)+"Deve exportar o documento para ficheiro PDF e só depois fazer o envio","FORM")
		*RETURN
	*else
******************
my_ftstamp=alltrim(factFe.ftstamp)

********************************************************************************************
********************************************************************************************
********************************************************************************************
*******************GET TOKEN*******************
*Parametros JSON para envio à API
TEXT TO mJSON TEXTMERGE NOSHOW
{
		"username": "geral@alguem.pt",
		"password": "Password*"
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

*******************FORMATAR MENSAGEM E APRESENTAR TOKEN*******************
***Resposta completa
my_response=loHTTP3.responsetext
***Substitui a resposta pelo valor a partir da data:
xpos=SUBSTR(my_response,AT('Data', my_response)+7)
***Retorna o valor total da string
local tamstrg
tamstrg=len(xpos)
***Para apresentar o token subtrai ao valor total da string menos o "} (2 caracteres)
my_token=SUBSTR(xpos,1,tamstrg-2)
*msg(my_token) 

********************************************************************************************
********************************************************************************************
********************************************************************************************
select factFe
LOCAL my_path
my_path=''
my_path=factFe.caminho

********************************************************************************************
********************************************************************************************
********************************************************************************************
***ENCODE PDF PARA BASE 64 PARA OBTER SERIAL INPUT
LOCAL loFac
LOCAL lcStrBase64
LOCAL lnSuccess
*  Get the contents of a file into a base64 encoded string:
loFac = CreateObject('Chilkat_9_5_0.FileAccess')
WAIT WINDOW NOWAIT "A converter PDF aguarde..." TIMEOUT 10 &&segundos
*msg(my_path)
lcStrBase64 = loFac.ReadBinaryToEncoded(my_path,"base64")

IF (loFac.LastMethodSuccess <> 1) THEN
    messagebox(loFac.LastErrorText,"Erro ao converter o PDF, tente novamente")
    RELEASE loFac
    *CANCEL
	EXIT
ENDIF
**********************
LOCAL base64FileName
LOCAL base64FilePath
m.base64FileName=alltrim(factFe.nomedoc)+"-"+astr(factFe.numdoc)+"-"+dtoc(factFe.usrdata)+"-"+hora
m.base64FilePath=alltrim(my_folder+base64FileName+".txt")
*messagebox(base64FilePath,"base64FilePath")
*  Now write the string to a file:
lnSuccess = loFac.WriteEntireTextFile(base64FilePath,lcStrBase64,"utf-8",0)
IF (lnSuccess <> 1) THEN
    messagebox(loFac.LastErrorText,"Erro ao guardar ficheiro PDF convertido")
    RELEASE loFac
    *CANCEL
ENDIF
*? "Success!"
RELEASE loFac
*messagebox(loFac,"loFac")
*messagebox(lcStrBase64,"lcStrBase64")
	updt_base=""
	TEXT TO updt_base TEXTMERGE NOSHOW
		UPDATE FT3 SET
		ft3.u_path64='<<base64FilePath>>'
	WHERE	
		ft3.ft3stamp='<<my_ftstamp>>'
	ENDTEXT
	
	*msg(updt_base)
	if u_sqlexec ([BEGIN TRANSACTION])
		if u_sqlexec(updt_base)
			u_sqlexec([COMMIT TRANSACTION])
			StrToFile(updt_base,my_folderLog+my_ftstamp+alltrim(factFe.nomeDoc)+"-"+astr(factFe.numdoc)+"-"+"Sucesso_Update_Base64.txt",4)
		else	
			u_sqlexec([ROLLBACK])
			msg("Erro - updt_base - p.f. contacte o seu Administrador de Sistema jm!!")
			StrToFile(updt_base,my_folderLog+my_ftstamp+alltrim(factFe.nomeDoc)+"-"+astr(factFe.numdoc)+"-"+"Erro_Update_Base64.txt",4)
			Gowww("https:")
			exit
		endif
	endif
select factFe
LOCAL my_path64
my_path64=''
my_path64=factFe.path64
*****FIM DO PDF CONVERTIDO PARA BASE64 E GUARDADO EM TXT*****
********************************************************************************************
********************************************************************************************
********************************************************************************************
*****2. Send invoice request without QRCode 
LOCAL moeda,clienteNIF
LOCAL cliente
LOCAL anodoc,mesdoc,diadoc
LOCAL horadoc,mindoc,segdoc
LOCAL datadoc
LOCAL cli_email
LOCAL numFact

cli_email=alltrim(factFe.email)
moeda=alltrim(ft.moeda)
clienteNIF=alltrim(factFe.ncont)
cliente=alltrim(factFe.cliente)
numFact=factFe.numdoc
datadoc=ft.fdata
anodoc=YEAR(ft.fdata)
mesdoc=PADL(MONTH(ft.fdata), 2, '0')
diadoc=PADL(DAY(ft.fdata), 2, '0')
horadoc=ft.fdata
etotal=ft.etotal
Set Point To "." && Coloca o ponto na vez da virgula nas casas decimais
*Parametros JSON para envio à API
TEXT TO payload TEXTMERGE NOSHOW
{
	"IntlVatCode": "<<nifEmpresa>>",
	"DocumentType": "Invoice",
	"DocumentDate": "<<datadoc>>",
	"DocumentNumber": "<<factFe.numDoc>>",
	"ReceiverIntlVatCode": "PT<<clienteNIF>>",
	"ReceiverName": "<<factFe.cliente>>",
	"DocumentTotal": <<factFe.etotal>>,
	"CurrencyCode": "EUR",
	"DestinationEmails":[
         {
             "Email": "<<cli_email>>",
             "SendAttachment": true,
             "LanguageCode": "PT"
         }
	],
	"SerializedInput":"<<lcStrBase64>>",
	"ContentType" : "application/pdf"
}
ENDTEXT

********************************************************************************************
********************************************************************************************
********************************************************************************************
**POST O REQUEST PARA O PDF
**PRODUCAO
mBaseURL2 = "https://dcn-solution.saphety.com/Dcn.Business.WebApi/api/PdfAsyncRequest/storeOnly/processDocument"
loHTTP3 = CREATEOBJECT("WinHttp.WinHttpRequest.5.1")
loHTTP3.Open("POST", mBaseURL2)

*loHTTP3.SetRequestHeader("content-type", "application/pdf")
loHTTP3.SetRequestHeader("content-type", "application/json")
*Caso necessite de alguma autenticação, incluir o Header abaixo com os dados da autenticação
loHTTP3.SetRequestHeader("Authorization","bearer " + my_token)
*msg(payload)
loHTTP3.Send(payload)

*******************FORMATAR MENSAGEM E APRESENTAR *******************
****Call service and get back 
***Resposta completa
*msg("my response text apos envio pdf")
*msg(loHTTP3.responsetext)
my_response3=loHTTP3.responsetext
xpos4=SUBSTR(my_response3,AT('Data', my_response3)+7)
***Retorna o valor total da string
local tamstrg3
tamstrg3=len(xpos4)
***Subtrai ao valor total da string menos o "} (2 caracteres)
my_requestid2=SUBSTR(xpos4,1,tamstrg3-2)
*messagebox("my request id 2")
*msg(my_requestid2)

**19/05/2021 16h50
LOCAL isValid
LOCAL isValidInicial,isValidFinal,isValidResultado
isValid=""
**isValid (Pode ser true ou false)
isValidInicial=AT('IsValid',my_response3)+9
isValidFinal=AT('Errors',my_response3)-2
isValidResultado=isValidFinal-isValidInicial
isValid=SUBSTR(my_response3,isValidInicial,isValidResultado)
*messagebox("OLA ISVALID")
*msg(isValid)

if isValid="false"
	LOCAL errorCode
	LOCAL errorCodeInicial,errorCodeFinal,errorCodeResultado
	errorCode=""
	errorCodeInicial=""
	errorCodeFinal=""
	errorCodeResultado=""
	
	**errorCode
	errorCodeInicial=AT('Code',my_response3)+7
	errorCodeFinal=AT('Field',my_response3)-3
	errorCodeResultado=(errorCodeFinal)-(errorCodeInicial)
	errorCode=SUBSTR(my_response3,errorCodeInicial,errorCodeResultado)
	*messagebox(errorCode,"errorCode")

	StrToFile(errorCode,my_folderLog+my_ftstamp+alltrim(factFe.nomeDoc)+"-"+astr(factFe.numdoc)+"-"+"Erro_Enviar.txt",4)

DO CASE
CASE errorCode = "INVALID_INTL_VAT_CODE"
	msg("NIF inválido na fatura: «"+astr(numFact)+"» "+chr(13)+chr(10)+"Por favor verifique se o cliente: «"+astr(cliente)+"» tem o NIF bem preenchido (Ex: PT123456789)","FORM")
	return
CASE errorCode = "DATETIME_FORMAT_EXPECTED"
	msg("DATA inválida na fatura: «"+astr(numFact)+"» "+chr(13)+chr(10)+"Por favor abra o último registo no ecrã das faturas","FORM")
CASE errorCode = "OUTBOUND_FINANCIAL_DOCUMENT_ALREADY_SENT"
	msg("A fatura : «"+astr(numFact)+"» já foi enviada e não pode ser enviada novamente","FORM")
	return
OTHERWISE
	msg("Erro desconhecido! Por favor contate o administrador de sistema jm")
	Gowww("")
ENDCASE
Set Point To se_pointer && Repoe a virgula nas casas decimais
return
endif 

Set Point To se_pointer && Repoe a virgula nas casas decimais
********************************************************************************************
********************************************************************************************
********************************************************************************************
**Check to success of your request
**04/05/2021
LOCAL service_url

**URL de Producao
service_url="https://dcn-solution.saphety.com/Dcn.Business.WebApi/api/PdfAsyncRequest/"+my_requestid2

********************************************************************************************
********************************************************************************************
********************************************************************************************
**Call service and get back the outbound document id
**04/05/2021
loHTTP3.Open("GET", service_url)
*Headers da chamada
loHTTP3.SetRequestHeader("content-type", "application/json")
*Caso necessite de alguma autenticação, incluir o Header abaixo com os dados da autenticação
loHTTP3.SetRequestHeader("Authorization","bearer "+my_token)
*loHTTP3.Send(mJSONoutbound)
loHTTP3.Send(my_requestid2)
WAIT WINDOW loHTTP3.status

my_response_service=loHTTP3.responsetext
*messagebox("my_response_service:")
*msg(my_response_service)
*return
********************************************************************************************
********************************************************************************************
********************************************************************************************

status=SUBSTR(my_response_service,AT('AsyncStatus', my_response_service)+14)
*messagebox("asynsstatus status")
*msg(status)

teste=SUBSTR(status,AT('","', status))
*messagebox(teste, "teste")
local teste2
teste2=0
teste2=(len(status)-len(teste))
*messagebox(teste2,"comprimento do teste2")
asyncStatus=LEFT(status,teste2)
*messagebox("asyncStatus")
*msg(asyncStatus)

LOCAL nrTentativas
nrTentativas=0
*DO WHILE asyncStatus="Running"
DO WHILE asyncStatus!="Finished"


**************************************
	IF asyncStatus="Running"
		nrTentativas=nrTentativas+1
		msg("Tentativa: "+astr(nrTentativas)+" de 10")
		DO ProcAtualizaEstado
		asyncStatus=""
		**************************************
		**ADICIONADO A 07/06/2021 15H43
		loHTTP3.Open("GET", service_url)
		*Headers da chamada
		loHTTP3.SetRequestHeader("content-type", "application/json")
		*Caso necessite de alguma autenticação, incluir o Header abaixo com os dados da autenticação
		loHTTP3.SetRequestHeader("Authorization","bearer "+my_token)
		loHTTP3.Send(my_requestid2)
		WAIT WINDOW loHTTP3.status
		my_response_service=loHTTP3.responsetext
		status=SUBSTR(my_response_service,AT('AsyncStatus', my_response_service)+14)
		*messagebox("asynsstatus status")
		*msg(status)
		teste=SUBSTR(status,AT('","', status))
		teste2=0
		teste2=(len(status)-len(teste))
		asyncStatus=LEFT(status,teste2)
		*messagebox("asyncStatus")
		*msg(asyncStatus)
		If nrTentativas=10
			msg("Algo correu mal... Erro de comunicação e excesso de tentativas, tente novamente mais tarde")
			StrToFile(asyncStatus,my_folderLog+my_ftstamp+alltrim(factFe.nomeDoc)+"-"+astr(factFe.numdoc)+"-"+"-tentativas.txt",4)
			EXIT
			RETURN
		Endif
	ENDIF

	errorCodeAsyncInicial=0
	errorCodeAsyncFinal=0
	errorCodeAsyncResultado=0
	errorCodeAsync=""
	errorCodeAsyncInicial=SUBSTR(my_response_service,AT('"Code":"', my_response_service)+8)
	errorCodeAsyncFinal=SUBSTR(errorCodeAsyncInicial,AT('Field', errorCodeAsyncInicial)-3)
	errorCodeAsyncResultado=(len(errorCodeAsyncInicial)-len(errorCodeAsyncFinal))
	errorCodeAsync=LEFT(errorCodeAsyncInicial,errorCodeAsyncResultado)
	msg(errorCodeAsync)

	IF asyncStatus="Error"
	StrToFile(errorCodeAsync,my_folderLog+my_ftstamp+alltrim(factFe.nomeDoc)+"-"+astr(factFe.numdoc)+"-"+"-errorCodeAsync.txt",4)
	*MSG("OLA CONDICAO ASYNCSTATUS = ERROR E ERROR CODE")
	*MSG(errorCodeAsync)
	DO CASE
	CASE errorCodeAsync = "INVALID_INTL_VAT_CODE"
		msg("Atenção! NIF inválido na fatura: «"+astr(numFact)+"» "+chr(13)+chr(10)+"Por favor verifique se o cliente: «"+astr(cliente)+"» tem o NIF bem preenchido (Ex: PT123456789)","FORM")
		return
	CASE errorCodeAsync = "DATETIME_FORMAT_EXPECTED"
		msg("Atenção! DATA inválida na fatura: «"+astr(numFact)+"» "+chr(13)+chr(10)+"Por favor abra o último registo no ecrã das faturas","FORM")
		return
	CASE errorCodeAsync = "OUTBOUND_FINANCIAL_DOCUMENT_ALREADY_SENT"
		msg("Atenção! A fatura: «"+astr(numFact)+"» do cliente: «"+alltrim(cliente)+"» já foi enviada e não pode ser enviada novamente.","FORM")
		return
	OTHERWISE
		msg("Erro desconhecido! Por favor contate o administrador de sistema jm")
		Gowww("")
		return
	ENDCASE
	ENDIF

WAIT WINDOW "A processar aguarde..." TIMEOUT 10 &&segundos
**return
my_response4=loHTTP3.responsetext

	***CHAMADA AO PROCEDIMENTO PARA ATUALIZAR ASYNCSTATUS NA FT3
	DO ProcAtualizaEstado
ENDDO

If asyncStatus="Finished"
	*messagebox("Finalizado e my_response_service para retirar outbound")
	*msg(my_response_service)
	**OutboundFinancialDocumentId
	LOCAL my_outbound_inicial,my_outbound_final,my_outbound_resultado
	my_outbound=""
	my_outbound_inicial=""
	my_outbound_final=""
	my_outbound_resultado=""
	my_outbound_inicial=AT('OutboundFinancialDocumentId',my_response_service)+30
	my_outbound_final=AT('IntlVatCode',my_response_service)-3
	my_outbound_resultado=my_outbound_final-my_outbound_inicial
	my_outbound=SUBSTR(my_response_service,my_outbound_inicial,my_outbound_resultado)
	*msg(my_outbound)
	StrToFile(my_outbound,my_folderLog+my_ftstamp+alltrim(factFe.nomeDoc)+"-"+astr(factFe.numdoc)+"-Sucesso_outbound.txt",4)

	**SerializedInput
	*LOCAL my_serialized_inicial,my_serialized_final
	*LOCAL my_serialized_resultado,my_serialized
	*my_serialized_inicial=AT('SerializedInput',my_response_service)+18
	*my_serialized_final=AT('ContentType',my_response_service)-3
	*my_serialized_resultado=my_serialized_final-my_serialized_inicial
	*my_serialized=SUBSTR(my_response_service,my_serialized_inicial,my_serialized_resultado)
	*msg(my_serialized)

	*******************************************************************************************
	***CHAMADA AO PROCEDIMENTO PARA GUARDAR OUTBOUND FINANCIAL DOCUMENT ID NA FT3
	DO ProcSaveOutbound
	*******************************************************************************************	
	***CHAMADA AO PROCEDIMENTO PARA ATUALIZAR ASYNCSTATUS NA FT3
	DO ProcAtualizaEstado
	*******************************************************************************************

Endif
***********************************************************************************************
***********************************************************************************************
***********************************************************************************************
***17/05/2021
*messagebox(my_outbound,"17/05/2021 - my_outbound")
************************************************************************************************
************************************************************************************************
**** Get a List of Document Formats storage by DocumentId 
**COMENTADO 04/06/2021
*Parametros JSON para envio à API
*TEXT TO payload TEXTMERGE NOSHOW
*{
*	"ServerBaseUrl": "https://dcn-solution.saphety.com/Dcn.Business.WebApi"
*	"OutboundFinancialDocumentId": "<<my_outbound>>"
*}
*ENDTEXT
*********************************
service_url = "https://dcn-solution.saphety.com/Dcn.Business.WebApi/api/OutboundFinancialDocument/documentFormats/"+my_outbound

*messagebox(service_url,"service_url")
loHTTP3 = CREATEOBJECT("WinHttp.WinHttpRequest.5.1")
loHTTP3.Open("POST", service_url)
*Headers da chamada
loHTTP3.SetRequestHeader("content-type", "application/json")
*Caso necessite de alguma autenticação, incluir o Header abaixo com os dados da autenticação
loHTTP3.SetRequestHeader("Authorization","bearer " + my_token)

*msg(payload)
*loHTTP3.Send(payload)

***************

loHTTP3.Open("GET", service_url)
*Headers da chamada
*loHTTP3.SetRequestHeader("content-type", "application/json")
*Caso necessite de alguma autenticação, incluir o Header abaixo com os dados da autenticação
loHTTP3.SetRequestHeader("Authorization","bearer "+my_token)

loHTTP3.Send(service_url)
WAIT WINDOW loHTTP3.status
my_response_service=loHTTP3.responsetext
*messagebox("my_response_service:")
*msg(my_response_service)

**********************************************************************************************
*******************************************
***APRESENTAR E GUARDA LINK DO PDF ENVIADO
LOCAL documentLink_Inicial,documentLink_Final
documentLink_Inicial=0
documentLink_Final=0
documentLink_Resultado=0
********************************************************************
documentLink_Inicial=(AT('Link',my_response_service))+7
documentLink_Final=AT('}]}',my_response_service)-1
documentLink_Resultado=(documentLink_Final)-(documentLink_Inicial)
documentLink=SUBSTR(my_response_service,documentLink_Inicial,documentLink_Resultado)
StrToFile(documentLink,my_folderLog+my_ftstamp+alltrim(factFe.nomeDoc)+"-"+astr(factFe.numdoc)+"-"+"-Sucesso_documentLink.txt",4)

*msg(documentLink)
****************************************************
***CHAMADA AO PROCEDIMENTO PARA GUARDAR LINK NA FT3
DO ProcSaveLink
****************************************************

***********************************************************************************************
***********************************************************************************************
***********************************************************************************************
***ENVIAR PDF
****2. Resend PDF invoice notifications 

*Parametros JSON para envio à API
TEXT TO mSendEmail TEXTMERGE NOSHOW
{
	"OutboundFinancialDocumentId": "<<my_outbound>>",
	"DestinationEmails":[
         {
             "Email": "<<cli_email>>",
             "SendAttachment": true,
             "LanguageCode": "PT"
         }
	]
}
ENDTEXT
*URL da API
mBaseUrlEmail = "https://dcn-solution.saphety.com/Dcn.Business.WebApi/api/OutboundFinancialDocumentMaintnance/sendAditionalNotifications"
loHTTP3 = CREATEOBJECT("WinHttp.WinHttpRequest.5.1")
loHTTP3.Open("POST", mBaseUrlEmail)
*Headers da chamada
loHTTP3.SetRequestHeader("content-type", "application/json")
*Caso necessite de alguma autenticação, incluir o Header abaixo com os dados da autenticação
loHTTP3.SetRequestHeader("Authorization","bearer " + my_token)
*msg(mSendEmail)
loHTTP3.Send(mSendEmail)

LOCAL request_data
request_data=""
request_data=loHTTP3.responsetext
*messagebox("OLA request_data de envio de email")
*msg(request_data)

*******************************************
***VALIDAR SE EMAIL ESTA BEM PREENCHIDO
LOCAL isValidEmail
LOCAL isValidEmail_Inicial,isValidEmail_Final,isValidEmail_Resultado
isValidEmail_Inicial=0
isValidEmail_Final=0
isValidEmail_Resultado=0
isValidEmail=""
**isValidEmail(Pode ser true ou false)
isValidEmail_Inicial=AT('IsValid',request_data)+9
isValidEmail_Final=AT('Errors',request_data)-2
isValidEmail_Resultado=isValidEmail_Final-isValidEmail_Inicial
isValidEmail=SUBSTR(request_data,isValidEmail_Inicial,isValidEmail_Resultado)
*messagebox("OLA ISVALID email")
*msg(isValid)

IF isValidEmail="false"
	LOCAL errorCode
	LOCAL errorCodeEmail_Inicial,errorCodeEmail_Final,errorCodeEmail_Resultado
	errorCodeEmail=0
	errorCodeEmail_Inicial=0
	errorCodeEmail_Final=0
	errorCodeEmail_Resultado=""
	
	**errorCodeEmail
	errorCodeEmail_Inicial=AT('Code',request_data)+7
	errorCodeEmail_Final=AT('Field',request_data)-3
	errorCodeEmail_Resultado=errorCodeEmail_Final-errorCodeEmail_Inicial
	errorCodeEmail=SUBSTR(request_data,errorCodeEmail_Inicial,errorCodeEmail_Resultado)
	StrToFile(errorCodeEmail,my_folderLog+my_ftstamp+alltrim(factFe.nomeDoc)+"-"+astr(factFe.numdoc)+"-"+"-Erro_errorCodeEmail.txt",4)
	*msg(errorCodeEmail)

	DO CASE
	CASE errorCodeEmail = "INVALID_EMAIL"
		msg("Atenção! A fatura: «"+astr(numFact)+"» não foi enviada! O e-mail do cliente: «"+alltrim(cliente)+"» está preenchido incorretamente."+chr(13)+chr(10)+" Por favor verifique a ficha de cliente.","FORM")
		EXIT
		return
	OTHERWISE
		msg("Erro desconhecido no envio de e-mail! Por favor contate o Administrador de sistema jm")
		Gowww("https:")
		EXIT
		return
	ENDCASE
ENDIF



***********************************************************************************************
***********************************************************************************************
***********************************************************************************************
*endif
endif
endscan
***********************************************************************************************

messagebox("Sucesso! E-mail(s) enviado(s)"+chr(13)+chr(10)+chr(13)+chr(10)+"Clique em OK para continuar",0+64,"jm")
msg("Operação concluida!","WAIT")
set date DMY
PDU_62X0WTFB5.Actualizarsopag.Nossobutton1.click()

***********************************************************************************************
***********************************************************************************************
***********************************************************************************************
*****************************************PROCEDIMENTOS*****************************************
***********************************************************************************************
***********************************************************************************************
***********************************************************************************************
*****PROCEDIMENTO PARA ATUALIZAR O ESTADO (asyncStatus) DE ENVIO NA FATURA
PROCEDURE ProcAtualizaEstado
  **Lparameters updt_status
	*msg("OLA PROCEDIMENTO 1")
  **Procedure code goes here
	updt_status=""
	TEXT TO updt_status TEXTMERGE NOSHOW
		UPDATE FT3 SET
		ft3.u_status='<<asyncStatus>>'
	WHERE	
		ft3.ft3stamp='<<my_ftstamp>>'
	ENDTEXT
	
	**msg(updt_status)
	if u_sqlexec ([BEGIN TRANSACTION])
		if u_sqlexec(updt_status)
			u_sqlexec([COMMIT TRANSACTION])
			StrToFile(updt_status,my_folderLog+my_ftstamp+"-Sucesso_updt_status.txt",4)

		else	
			u_sqlexec([ROLLBACK])
			msg("Erro - updt_status - p.f. contacte o seu Administrador de Sistema jm!!")
			StrToFile(updt_status,my_folderLog+my_ftstamp+"-Erro_updt_status.txt",4)
			Gowww("https:/")
			exit
		endif
	endif
ENDPROC

***********************************************************************************************
*****PROCEDIMENTO PARA GUARDAR O OUTBOUND FINANCIAL ID NA FT3
PROCEDURE ProcSaveOutbound
	***UPDATE DO OUTBOUND FINANCIAL DO DOCUMENTO
	updt_out=""
	TEXT TO updt_out TEXTMERGE NOSHOW
		UPDATE FT3 SET
		ft3.u_outbound='<<my_outbound>>'
	WHERE	
		ft3.ft3stamp='<<my_ftstamp>>'
	ENDTEXT
	
	*msg(updt_out)
	if u_sqlexec ([BEGIN TRANSACTION])
		if u_sqlexec(updt_out)
			u_sqlexec([COMMIT TRANSACTION])
			StrToFile(updt_status,my_folderLog+my_ftstamp+"-Sucesso_updt_out.txt",4)
		else	
			u_sqlexec([ROLLBACK])
			msg("Erro - updt_out - p.f. contacte o seu Administrador de Sistema jm!!")
			StrToFile(updt_status,my_folderLog+my_ftstamp+"-Erro_updt_out.txt",4)
			Gowww("https:/")
			exit
		endif
	endif
ENDPROC
***********************************************************************************************
*****PROCEDIMENTO PARA GUARDAR LINK DO PDF ENVIADO
PROCEDURE ProcSaveLink
	updt_linkpdf=""
	TEXT TO updt_linkpdf TEXTMERGE NOSHOW
		UPDATE FT3 SET
		ft3.U_LINKPDF='<<documentLink>>'
	WHERE	
		ft3.ft3stamp='<<my_ftstamp>>'
	ENDTEXT
	
	**msg(updt_linkpdf)
	if u_sqlexec ([BEGIN TRANSACTION])
		if u_sqlexec(updt_linkpdf)
			u_sqlexec([COMMIT TRANSACTION])
			StrToFile(updt_status,my_folderLog+my_ftstamp+"-Erro_updt_status.txt",4)
		else	
			u_sqlexec([ROLLBACK])
			msg("Erro - updt_linkpdf - p.f. contacte o seu Administrador de Sistema jm!!")
Gowww("htt")
			exit
		endif
	endif
ENDPROC
