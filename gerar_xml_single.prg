*================================================================================================================================================
* GRINCOP LDA
*      :: Data Criação:    08/07/2021
*      :: Programador:     João Mendes
*      :: Cliente:     Ambienti D Interni
*      :: Objetivo:     TESTES DE XML COM PDF INCLUIDO   
* Histórico de Versões
*      :: 08/07/2021 »» JM :: Alteracao TCFilepdf
*================================================================================================================================================


my_data=DATETIME()

LOCAL my_ftstamp
my_ftstamp=""


SELECT FT3
my_ftstamp=ft3.ft3stamp

*********************************************************************************************************





local my_xml
my_xml=""

LOCAL my_folder
my_folder=""
*!* Definir qual a pasta no servidor *!*
*my_folder="F:\04-GRINCOP_PHC\" 
my_folder="\\10.0.0.13\Dados\04-GRINCOP_PHC\"

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
    msg("O servidor respondeu. A exportar fatura","WAIT")
ELSE 
    msg("O servidor não respondeu","WAIT")
    msg("Erro! Não foi possível ligar ao servidor, tente novamente mais tarde"+chr(13)+chr(13)+chr(10)+chr(13)+"Clique OK para voltar")
    return
ENDIF 


if !empty(my_pathXML)
    msg("Atenção! Esta fatura já tinha sido exportada para XML"+chr(13)+chr(13)+chr(10)+chr(13)+"Clique OK para continuar")
endif


**********************************************************************************************************
**********************************************************************************************************
***********************************************GERAR O PDF************************************************
m.cTitIDU = "FaturaAzul" 
hora=substr(ft.usrhora,1,2)+"h"+substr(ft.usrhora,4,2)+"m" 

m.my_pdf=alltrim(ft.nmdoc)+"-"+astr(ft.fno)+"-"+dtoc(ft.usrdata)+"-"+hora
m.cDir=my_folder+my_pdf+".pdf" 

*msg(m.cDir)
msg(m.my_pdf)

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
**RENAME (c_nomexml) to ("F:\04-GRINCOP_PHC\"+JUSTFNAME(m.c_nomexml))
*RENAME (c_nomexml) to (my_folder+JUSTFNAME(m.c_nomexml))
RENAME (c_nomexml) to (m.cDirXML)


*****************************************************
my_pathXML=""
my_pathXML=m.cDirXML
*my_folder="F:\04-GRINCOP_PHC\"
my_folder="\\10.0.0.13\Dados\04-GRINCOP_PHC"

msg("O ficheiro '"+m.cDirXML+"' foi exportado com sucesso para a pasta: '"+my_folder+"'","",.t.)
msg("Fatura exportada com sucesso!","WAIT")

*************************************************************************************************
*************************************************************************************************
*******************************UPDATE COM O NOME DO CAMINHO DO XML*******************************
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
