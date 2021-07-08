*================================================================================================================================================
* GRINCOP LDA
*      :: Data Criação:    21/05/2021
*      :: Programador:     João Mendes
*      :: Cliente:     INTERNO
*      :: Objetivo:    Gerar varios ficheiros XML de seguida com PDF     
* Histórico de Versões
*      :: 08/07/2021 »» JM :: Revisao da funcao makexmlubl_2_1_cius
*================================================================================================================================================

doread("ft","Sft")
SELECT ft

LOCAL my_ftstamp
my_ftstamp=""

LOCAL my_pathXML
my_pathXML=""

SELECT factFe
my_ftstamp=factFe.ftstamp
my_pathXML=alltrim(factFe.PATHXML)

**************************************************************************************************
**************************************************************************************************
**************************************************************************************************
***********************BROWLIST COM LISTA DE FATURAS PARA EXPORTAR PARA XML***********************

LOCAL i
i=4
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


list_tam=15*10
****************************

m.escolheu=.f.

=CURSORSETPROP('Buffering',5,"factFe")

browlist("Escolha as facturas a que pretende exportar para XML ","factFe","factFe",.t.,.f.,.f.,.t.,.f.)

**
if .not. m.escolheu
    wait window "Escolheu Cancelar, vou sair..." nowait
    return
endif

*msg("Vai exportar a(s) fatura(s) para XML, este processo pode demorar algum tempo","FORM",.t.)

SELECT factFe
*GO TOP
*GOTO TOP
SCAN
    if factFe.sel
    
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


        ***************************************************************************************************
        ***************************************************************************************************
        ********************************************GERAR O PDF********************************************
        m.cTitIDU = "FaturaAzul" 
        hora=substr(ft.usrhora,1,2)+"h"+substr(ft.usrhora,4,2)+"m" 

        m.my_pdf=alltrim(factFE.NOMEDOC)+"-"+astr(factFE.numdoc)+"-"+dtoc(factFE.usrdata)+"-"+substr(factFE.usrhora,1,2)+"h"+substr(factFE.usrhora,4,2)+"m"
        m.cDir=my_folder+my_pdf+".pdf" 
        *msg(m.cDir)

        Doread('FT','sFT')
        navega("FT",factFe.FTstamp)

	    idutopdf("FT","FI","FTCAMPOS","FICAMPOS","FTIDUC","FTIDUL",FT.ndoc,m.cTitIDU,m.cDir,"","NO",.F.,"ONETOMANY",,,,,.T.)

        msg("Ficheiro PDF exportado com sucesso!","WAIT")


        ****************************************************************************************************
        ****************************************************************************************************
        ***********************************************GERAR O XML*****************************************
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




*************************************************************************************************
*************************************************************************************************
*******************************UPDATE COM O NOME DO CAMINHO DO XML*******************************
LOCAL updt_xml
updt_xml=''

TEXT TO updt_xml TEXTMERGE NOSHOW
	UPDATE FT3 SET
	ft3.u_pathXML=trim('<<my_pathXML>>'),
	ft3.u_lxml=1
	WHERE	
	ft3.ft3stamp='<<my_ftstamp>>'
ENDTEXT
	
msg(updt_xml)
if u_sqlexec ([BEGIN TRANSACTION])	
	if u_sqlexec(updt_xml)	
		u_sqlexec([COMMIT TRANSACTION])	
	else	
		u_sqlexec([ROLLBACK])	
		Messagebox("Erro - updt_xml - p.f. contracte o seu Administrador de Sistema!!")	
		exit	
	endif	
endif	

************************************************************************************************
************************************************************************************************


ENDIF
ENDIF
ENDSCAN

c_nomexml= ""
c_nomefilesign = ""
tcfilepdf = ""

my_xml=""
my_folder=""
PDU_61S0KOZD8.Actualizarsopag.Nossobutton1.click()