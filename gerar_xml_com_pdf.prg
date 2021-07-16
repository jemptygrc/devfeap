*================================================================================================================================================
* GRINCOP LDA
*      :: Data Criação:    01/07/2021
*      :: Programador:     João Mendes
*      :: Cliente:     Ambienti D Interni
*      :: Objetivo:    Gerar ficheiro XML    
* Histórico de Versões
*      :: 16/07/2021 »» JM :: Registo Log File
*================================================================================================================================================

*msg("GRINCOP - EM DESENVOLVILMENTO")
*RETURN

my_data=DATETIME()
LOCAL my_ftstamp
my_ftstamp=""

SELECT FT3
my_ftstamp=ft3.ft3stamp


*!* Definir qual a pasta no servidor *!*
LOCAL my_folder
my_folder=""
my_folder="\\192.168.0.11\Dropbox\Dados\FEAP\XML\"

LOCAL my_folderLog
my_folderLog=""
my_folderLog="\\192.168.0.11\Dropbox\Dados\FEAP\Log\LXML\"

LOCAL my_pathXML
my_pathXML=""
my_pathXML=alltrim(ft3.u_pathXML)
*msg(my_pathXML)
*return


***************************************************************************************************************
***************************************************************************************************************
if !pergunta("Pretende exportar a fatura para ficheiro XML",1,"Este processo pode demorar algum tempo",.T.)
	msg("Operação cancelada","WAIT")
	return
endif


IF DIRECTORY(my_folder)
    msg("Sucesso! Ligação validada ao servidor"+chr(13)+chr(13)+chr(10)+chr(13)+"Clique OK para continuar")
    msg("O servidor respondeu. A exportar a fatura, aguarde mais um momento","WAIT")
ELSE 
    msg("O servidor não respondeu","WAIT")
    msg("Algo correu mal... Não foi possível ligar ao servidor, tente novamente mais tarde"+chr(13)+chr(13)+chr(10)+chr(13)+"Clique OK para voltar")
    return
ENDIF 

if !empty(my_pathXML)
    msg("Atenção! Esta fatura já tinha sido exportada para XML"+chr(13)+chr(13)+chr(10)+chr(13)+"Clique OK para continuar")
endif


**********************************************************************************************************
**********************************************************************************************************
***********************************************GERAR O PDF************************************************
m.cTitIDU = "DocumentoCertificado" 
hora=substr(ft.usrhora,1,2)+"h"+substr(ft.usrhora,4,2)+"m" 

m.my_pdf=alltrim(ft.nmdoc)+"-"+astr(ft.fno)+"-"+dtoc(ft.usrdata)+"-"+hora

m.cDir=my_folder+my_pdf+".pdf" 
*msg(m.cDir)

idutopdf("FT","FI","FTCAMPOS","FICAMPOS","FTIDUC","FTIDUL",FT.ndoc,m.cTitIDU,m.cDir,"","NO",.F.,"ONETOMANY",,,,,.T.)
msg("Ficheiro PDF exportado com sucesso!","WAIT")

**********************************************************************************************************
**********************************************************************************************************
***********************************************GERAR O XML************************************************
local c_nomexml, c_nomefilesign
m.c_nomexml= ""
m.c_nomefilesign = ""
m.tcfilepdf = m.cDir
m.cDirXML=my_folder+my_pdf+".xml" 
makexmlubl_2_1_cius(@c_nomexml, @c_nomefilesign, tcfilepdf, y_tiposaft)


*!*Definir a pasta de destino do XML exportado
RENAME (c_nomexml) to (m.cDirXML)

msg("O ficheiro '"+m.cDirXML+"' foi exportado com sucesso para a pasta: '"+my_folder+"'","",.t.)
msg("FIcheiro XML exportado com sucesso!","WAIT")


StrToFile("XML Exportado", my_folderLog+alltrim(ft.nmdoc)+"-"+astr(ft.fno)+"-"+dtoc(ft.usrdata)+"-"+hora+"-XML_Exportado.txt",4)

*************************************************************************************************
*************************************************************************************************
*******************************UPDATE COM O NOME DO CAMINHO DO XML*******************************
my_pathXML=""
my_pathXML=m.cDirXML

LOCAL updt_xml
updt_xml=''
TEXT TO updt_xml TEXTMERGE NOSHOW
	UPDATE FT3 SET
	ft3.u_pathXML='<<my_pathXML>>',
	ft3.u_lxml=1
	WHERE
	ft3.ft3stamp='<<my_ftstamp>>'
ENDTEXT
	
*msg(updt_xml)
if u_sqlexec ([BEGIN TRANSACTION])	
	if u_sqlexec(updt_xml)	
		u_sqlexec([COMMIT TRANSACTION])	
		StrToFile(updt_xml, my_folderLog+alltrim(ft.nmdoc)+"-"+astr(ft.fno)+"-"+dtoc(ft.usrdata)+"-"+hora+"-Sucesso_Updt_XML.txt",4)	

	else	
		u_sqlexec([ROLLBACK])	
		Messagebox("Erro - updt_xml - p.f. contacte o seu Administrador de Sistema GRINCOP!!")
		StrToFile(updt_xml, my_folderLog+alltrim(ft.nmdoc)+"-"+astr(ft.fno)+"-"+dtoc(ft.usrdata)+"-"+hora+"-Erro_Updt_XML.txt",4)	
		exit	
	endif	
endif	
************************************************************************************************
************************************************************************************************
