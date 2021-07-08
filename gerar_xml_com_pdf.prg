*================================================================================================================================================
* GRINCOP LDA
*      :: Data Cria��o:    01/07/2021
*      :: Programador:     Jo�o Mendes
*      :: Cliente:     Ambienti D Interni
*      :: Objetivo:    Gerar ficheiro XML    
* Hist�rico de Vers�es
*      :: 08/07/2021 �� JM :: Gerar pdf para incluir na variavel tcfile no XML
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

LOCAL my_pathXML
my_pathXML=""
my_pathXML=alltrim(ft3.u_pathXML)
*msg(my_pathXML)
*return


***************************************************************************************************************
***************************************************************************************************************
if !pergunta("Pretende exportar a fatura para ficheiro XML",1,"Este processo pode demorar algum tempo",.T.)
	msg("Opera��o cancelada","WAIT")
	return
endif


IF DIRECTORY(my_folder)
    msg("Sucesso! Liga��o validada ao servidor"+chr(13)+chr(13)+chr(10)+chr(13)+"Clique OK para continuar")
    msg("O servidor respondeu. A exportar a fatura, aguarde mais um momento","WAIT")
ELSE 
    msg("O servidor n�o respondeu","WAIT")
    msg("Algo correu mal... N�o foi poss�vel ligar ao servidor, tente novamente mais tarde"+chr(13)+chr(13)+chr(10)+chr(13)+"Clique OK para voltar")
    return
ENDIF 

if !empty(my_pathXML)
    msg("Aten��o! Esta fatura j� tinha sido exportada para XML"+chr(13)+chr(13)+chr(10)+chr(13)+"Clique OK para continuar")
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
makexmlubl_2_1_cius(@c_nomexml, @c_nomefilesign, tcfilepdf, y_tiposaft)
local my_xml
my_xml=""


*!*Definir a pasta de destino do XML exportado
RENAME (c_nomexml) to (my_folder+JUSTFNAME(m.c_nomexml))

msg("O ficheiro '"+my_xml+"' foi exportado com sucesso para a pasta: '"+my_folder+"'","",.t.)
msg("FIcheiro XML exportado com sucesso!","WAIT")


*************************************************************************************************
*************************************************************************************************
*******************************UPDATE COM O NOME DO CAMINHO DO XML*******************************
my_pathXML=""
my_xml=(JUSTFNAME(m.c_nomexml))
my_pathXML=my_folder+my_xml

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
	else	
		u_sqlexec([ROLLBACK])	
		Messagebox("Erro - updt_xml - p.f. contracte o seu Administrador de Sistema GRINCOP!!")	
		exit	
	endif	
endif	
************************************************************************************************
************************************************************************************************
