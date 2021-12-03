*************************************
****Titulo: Gerar PDF
****Cliente: 
****Data: 29/04/2021
****Ultimo Alterção: 29/06/2021
*************************************

* chama o ecra de faturas
doread("ft","Sft")
select ft


LOCAL my_folder
my_folder=""
*!* Definir qual a pasta no servidor *!*
my_folder="\\xx\Dxx\xxxC" 

********************************************************************************************
********************************************************************************************
********************************************************************************************
*****BROWLIST COM LISTA DE FATURAS PARA EMITIR
select factFe

LOCAL nomeCliente
nomeCliente=factFe.CLIENTE
************************

declare list_tit(4),list_cam(4),list_pic(4),list_tam(4),list_ali(4),list_ronly(4),list_combo(4)

list_tit(1) = "Conf?"
list_cam(1) = "factFe.sel"
list_pic(1) = "LOGIC"
list_ali(1) = 0
list_ronly(1)=.f.
list_tam(1)=8*5
list_combo(1)=""

list_tit(2) = "Nº Cliente"
list_cam(2) = "factFe.CLIENTE"
list_pic(2) = ""
list_ali(2) = 0
list_ronly(2)=.t.
list_combo(2)=""

list_tit(3) = "N.Factura"
list_cam(3) = "factFe.numdoc"
list_pic(3) = ""
list_ali(3) = 0
list_ronly(3)=.t.
list_combo(3)=""

list_tit(4) = "Data"
list_cam(4) = "factFe.usrdata"
list_pic(4) = ""
list_ali(4) = 0
list_ronly(4)=.t.
list_combo(4)=""


list_tam=15*10
****************************

m.escolheu=.f.

=CURSORSETPROP('Buffering',5,"factFe")

browlist("Escolha a(s) factura(s) a que pretende exportar para PDF ","factFe","factFe",.t.,.f.,.f.,.t.,.f.)

**
if .not. m.escolheu
    wait window "Escolheu Cancelar, vou sair..." nowait
    return
endif



if !pergunta("Pretende exportar a(s) fatura(s) para ficheiro PDF",1,"Este processo pode demorar algum tempo",.T.)
	msg("Operação cancelada","WAIT")
	return
endif

msg(my_folder)

IF DIRECTORY(my_folder)
            msg("Sucesso! Ligação validada ao servidor"+chr(13)+chr(13)+chr(10)+chr(13)+"Clique OK para continuar")
            msg("O servidor respondeu. A exportar fatura","WAIT")
        ELSE 
            msg("O servidor não respondeu","WAIT")
            msg("Erro! Não foi possível ligar ao servidor, tente novamente mais tarde"+chr(13)+chr(13)+chr(10)+chr(13)+"Clique OK para voltar")
        return
        ENDIF 

select factFe
*GO TOP

scan
    if factFe.sel
    ******************

        my_ftstamp=factFe.ftstamp

        ********************************************************************************************
        ********************************************************************************************
        ********************************************************************************************
        *****GERAR PDF

        local cTitIDU,cDir

        LOCAL pdfFileName
        LOCAL pdfFilePath
        pdfFileName=""
        pdfFilePath=""


    if not eof("factFe")
	    *!*Titulo do IDU utilizado
	    m.cTitIDU = "FaturaAzul"

	    m.pdfFileName=alltrim(factFE.NOMEDOC)+"-"+astr(factFE.numdoc)+"-"+dtoc(factFE.usrdata)+"-"+substr(factFE.usrhora,1,2)+"h"+substr(factFE.usrhora,4,2)+"m"

	    *!*Caminho onde PDF vai ser guardado
	    m.pdfFilePath="my_folder"+pdfFileName+".pdf"

	    Doread('FT','sFT')
	    navega("FT",factFe.FTstamp)

	    idutopdf("FT","FI","FTCAMPOS","FICAMPOS","FTIDUC","FTIDUL",FT.ndoc,m.cTitIDU,m.pdfFilePath,"","NO",.F.,"ONETOMANY",,,,,.T.)


        msg("Fatura(s) exportada(s) para PDF com sucesso!","WAIT")
        *return
        ****

************************************************************************************************
************************************************************************************************

******************UPDATE COM O NOME DO CAMINHO*****************
LOCAL updt_ft3
updt_ft3=''

TEXT TO updt_ft3 TEXTMERGE NOSHOW
	UPDATE FT3 SET
	ft3.U_PATHPDF=trim('<<m.pdfFilePath>>')
	WHERE	
	ft3.ft3stamp='<<my_ftstamp>>'
ENDTEXT

*msg(updt_ft2)
if u_sqlexec ([BEGIN TRANSACTION])	
	if u_sqlexec(updt_ft3)	
		u_sqlexec([COMMIT TRANSACTION])	
	else	
		u_sqlexec([ROLLBACK])	
		Messagebox("Erro - updt_ft3 - p.f. contracte o seu Administrador de Sistema!!")	
		exit	
	endif	
endif	

************************************************************************************************
************************************************************************************************



endif
endif
endscan

*sFT.release
PDU_61S0KOZD8.Actualizarsopag.Nossobutton1.click()
