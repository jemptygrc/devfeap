*================================================================================================================================================
* GRINCOP LDA
*      :: Data Criação:    01/07/2021
*      :: Programador:     Joao Mendes
*      :: Cliente:     Ambienti
*      :: Objetivo:    Gerar ficheiro XML    
* Histórico de Versões
*      :: 05/07/2021 »» JM :: Revisão código
*================================================================================================================================================

*msg("GRINCOP - EM DESENVOLVILMENTO")
*RETURN

my_data=DATETIME()
LOCAL my_ftstamp
my_ftstamp=""

SELECT FT3
my_ftstamp=ft3.ft3stamp
local c_nomexml, c_nomefilesign
m.c_nomexml= ""
m.c_nomefilesign = ""
m.tcfilepdf = ""
makexmlubl_2_1_cius(@c_nomexml, @c_nomefilesign, tcfilepdf, y_tiposaft)
local my_xml
my_xml=""

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
	msg("Operação cancelada","WAIT")
	return
endif


IF DIRECTORY(my_folder)
    msg("Sucesso! Ligação validada ao servidor"+chr(13)+chr(13)+chr(10)+chr(13)+"Clique OK para continuar")
    msg("O servidor respondeu. Pode exportar a fatura","WAIT")
ELSE 
    msg("O servidor não respondeu","WAIT")
    msg("Algo correu mal... Não foi possível ligar ao servidor, tente novamente mais tarde"+chr(13)+chr(13)+chr(10)+chr(13)+"Clique OK para voltar")
    return
ENDIF 

if !empty(my_pathXML)
    msg("Atenção! Esta fatura já tinha sido exportada para XML"+chr(13)+chr(13)+chr(10)+chr(13)+"Clique OK para continuar")
endif

*!*Definir a pasta de destino do XML exportado
RENAME (c_nomexml) to ("\\192.168.0.11\Dropbox\Dados\FEAP\XML\"+JUSTFNAME(m.c_nomexml))

*****************************************************
my_pathXML=""
my_xml=(JUSTFNAME(m.c_nomexml))
my_pathXML=my_folder+my_xml
my_folder="\\192.168.0.11\Dropbox\Dados\FEAP\XML\"

msg("O ficheiro '"+my_xml+"' foi exportado com sucesso para a pasta: '"+my_folder+"'","",.t.)
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
