*================================================================================================================================================
*
*      :: Data Criação:    21/07/2021
*      :: Programador:     xxx
*      :: Cliente:     TESTES
*      :: Objetivo:    CRIAR XML CIUS-PT MANUALMENTE   
* Histórico de Versões
*      :: 21/07/2021 »» JM :: Criação
*================================================================================================================================================
************************************************************************************************
************************************************************************************************
***DECLARACAO DE VARIAIVEIS
PRIVATE my_folder
my_folder=""
*!* Definir qual a pasta no servidor *!*
*my_folder="xx" 
my_folder="\\xx"


IF DIRECTORY(my_folder)
    msg("Sucesso! Ligação validada ao servidor"+chr(13)+chr(13)+chr(10)+chr(13)+"Clique OK para continuar")
    msg("O servidor respondeu. A exportar fatura","WAIT")
ELSE 
    msg("O servidor não respondeu","WAIT")
    msg("Erro! Não foi possível ligar ao servidor, tente novamente mais tarde"+chr(13)+chr(13)+chr(10)+chr(13)+"Clique OK para voltar")
    return
ENDIF 

************************************************************************************************
************************************************************************************************

***CURSOR PARA SELECIONAR DADOS DA EMPRESA
u_sqlexec("Select * from e1 where estab = 0", "e1cur")
Select e1Cur


**JM CURSOR PARA SELECIONAR DADOS DO CLIEENTE
u_sqlexec("Select * from cl where no = ?ft.no and estab = ?ft.estab", "clcur")
Select clcur

***
u_sqlexec("Select * from td where ndoc = ?ft.ndoc", "tdCur")
Select tdcur

**JM CURSOR PARA TOTALIZAR VALOR REGULARIZADO
u_sqlexec("Select isnull(sum(evreg), 0) as evreg, isnull(sum(vreg), 0) as vreg from ftrd where ftstamp = ?ft.ftstamp", "ftrdcur")


************************************************************************************************
************************************************************************************************


***CURSOR PARA SELECIONAR NOME FISCAL DA FT E 1/11/21/31 CARACTERES DA ASSINATURA FISCAL 
text to getNomeFiscal textmerge noshow   
	select

	case     
	when td.docsimport = 1 AND FT3.InvoiceNoOri <> '' then
		FT3.InvoiceNoOri     
	when MFT.ftano >= 2014 AND td.manternumero = 0 then
		rtrim(case when FT2.tiposaft = '' then 
			td.tiposaft else FT2.tiposaft end) + ' ' + ltrim(str(MFT.ftano)) + 'A' + ltrim(str(MFT.ndoc)) + '/' + 
		(case when MFT.fno < 0 then '0' else ltrim(str(MFT.fno))end) 
	else
		rtrim(case when FT2.tiposaft = '' then 
			td.tiposaft else FT2.tiposaft end) + ' ' + + ltrim(str(MFT.ndoc)) + '/' +
		(case when MFT.fno < 0 then '0' else ltrim(str(MFT.fno))end)
	end as nomefisc, 

			substring(FT2.assinatura,1,1) + substring(FT2.assinatura,11,1) + substring(FT2.assinatura,21,1) + substring(FT2.assinatura,31,1) as hash
			from FT MFT (nolock)
			inner join FT2 (nolock) on MFT.FTstamp = FT2.FT2stamp
			inner join FT3 (nolock) on MFT.FTstamp=FT3.FT3stamp 
			inner join td  (nolock) on MFT.ndoc=td.ndoc
			where MFT.FTstamp = ?FT.FTstamp
endtext
u_sqlexec(getNomeFiscal, "fisccur")
Select fisccur



************************************************************************************************
************************************************************************************************

****CURSOR PARA LISTAR IVA E BASE INCIDENCIA 
Select ftrdcur
text to getIVA textmerge noshow
	Select ftt.codigo, ftt.taxa, ftt.ebaseinc, ftt.evalor, regiva.codigo as codiva
	from ftt
	inner join ft on ft.ftstamp = ftt.ftstamp
	inner join ft2 on ft2.ft2stamp = ft.ftstamp
	inner join cl on cl.no = ft.no and cl.estab = ft.estab
	inner join regiva on regiva.descricao = ft2.descregiva and regiva.tabiva = ftt.codigo
	where ft.ftstamp = ?ft.ftstamp
endtext  
u_sqlexec(getIVA, "ivaCur")

************************************************************************************************
************************************************************************************************
if pergunta("Pretende anexar PDF da factura à Factura Eletrónica?")
   base64PDF = emitePDF()
else
   base64PDF = .null.
endif


************************************************************************************************
************************************************************************************************
**JM CURSOR PARA LISTAR NOME FISCAL, HASH E FDATA
if tdCur.tipodoc = 3
	text to getFts textmerge noshow
		select distinct

		case when td.docsimport = 1 AND FT3.InvoiceNoOri <> '' then
			FT3.InvoiceNoOri
		when MFT.ftano >= 2014 AND td.manternumero = 0 then
			rtrim(case when FT2.tiposaft = '' then 
				td.tiposaft
			else 
				FT2.tiposaft end) + ' ' + ltrim(str(MFT.ftano)) + 'A' + ltrim(str(MFT.ndoc)) + '/' +
			(case when MFT.fno < 0 then 
				'0' 
			else ltrim(str(MFT.fno))end)
		else 
			rtrim(case when FT2.tiposaft = '' then
				td.tiposaft
			else FT2.tiposaft end) + ' ' + + ltrim(str(MFT.ndoc)) + '/' +

			(case when MFT.fno < 0 then
				'0' 
			else ltrim(str(MFT.fno))end)
		end as nomefisc,

		substring(FT2.assinatura,1,1) + substring(FT2.assinatura,11,1) + substring(FT2.assinatura,21,1) + substring(FT2.assinatura,31,1) as hash,
		mft.fdata
		from FT MFT (nolock)
		inner join FT2 (nolock) on MFT.FTstamp = FT2.FT2stamp
		inner join FT3 (nolock) on MFT.FTstamp=FT3.FT3stamp
		inner join td  (nolock) on MFT.ndoc=td.ndoc
		inner join fi on fi.ftstamp = mft.ftstamp
		inner join fi ofi on ofi.ofistamp = fi.fistamp
		inner join ft oft on oft.ftstamp = ofi.ftstamp
		where oft.FTstamp = ?ft.ftstamp
	endtext
	u_sqlexec(getFts, "oftscur")
	
	if reccount("oftscur") > 0
		text to oftsJSON textmerge noshow 
			[         
		endtext
		
		Select oftsCur
		go top
		Scan
		text to oftsJSON textmerge noshow additive
			<<iif(recno('oftsCur') > 1, ',', '')>>
				{       
				"nomefisc": "<<alltrim(oftsCur.nomefisc)>>",
				"fdata": "<<astr(year(oftscur.fdata)) + '-' + padl(astr(month(oftscur.fdata)), 2, '0') + '-' + padl(astr(day(oftscur.fdata)), 2, '0')>>"
				}
			endtext
			endscan

      	text to oftsJSON textmerge noshow additive
         	]
      	endtext
   	else
			oftsJSON = ""
   	endif
endif
************************************************************************************************
************************************************************************************************


****SELECT BASEINC/EVALOR/CODIVA/TAXA
text to taxesJSON textmerge noshow
   [
endtext

Select ivaCur
go top
Scan
text to taxesJSON textmerge noshow additive
    <<iif(recno('ivaCur') > 1, ',', '')>>
    {
         "ebaseinc": <<strtran(astr(ivaCur.ebaseinc), ',', '.')>>,
         "evalor": <<strtran(astr(ivaCur.evalor), ',', '.')>>,
         "codiva": "<<alltrim(ivaCur.codiva)>>",
         "taxa": <<strtran(astr(ivaCur.taxa), ',', '.')>>
    }              
endtext
endscan

text to taxesJSON textmerge noshow additive
	]
endtext
************************************************************************************************
************************************************************************************************


****SELECT NA FI 
text to linesJSON textmerge noshow
   [
endtext

i = 1
Select fi
go top
Scan for fi.qtt <> 0
Select ivaCur
go top
Locate for ivaCur.codigo = fi.tabiva
	if found()
		ivacod = alltrim(ivaCur.codiva)
	else
	    ivaCod = 'NOR'
	endif

text to linesJSON textmerge noshow additive
	<<iif(i > 1, ',', '')>>{
		"epv": <<strtran(astr(fi.epv), ',', '.')>>,
		"qtt": <<strtran(astr(fi.qtt), ',', '.')>>,
		"ivaincl": "<<iif(fi.ivaincl, 'true', 'false')>>",
		"iva": <<strtran(astr(fi.iva), ',', '.')>>,
		"desconto": <<strtran(astr(fi.desconto), ',', '.')>>,
		"desc2": <<strtran(astr(fi.desc2), ',', '.')>>,
		"desc3": <<strtran(astr(fi.desc3), ',', '.')>>,
		"desc4": <<strtran(astr(fi.desc4), ',', '.')>>,
		"desc5": <<strtran(astr(fi.desc5), ',', '.')>>,
		"desc6": <<strtran(astr(fi.desc6), ',', '.')>>,
		"design": "<<alltrim(escapeDoubleQuotes(fi.design))>>",
		"ref": "<<alltrim(escapeDoubleQuotes(fi.ref))>>",
		"codiva": "<<alltrim(ivacod)>>"
	}
endtext


i = i + 1
endscan

text to linesJSON textmerge noshow additive
   ]
endtext
************************************************************************************************
************************************************************************************************


text to invoiceJSON textmerge noshow
	{ 
	"nomefiscal": "<<alltrim(fisccur.nomefisc)>>",
	"fdata": "<<astr(year(ft.fdata)) + '-' + padl(astr(month(ft.fdata)), 2, '0') + '-' + padl(astr(day(ft.fdata)), 2, '0')>>",
	"pdata": "<<astr(year(ft.pdata)) + '-' + padl(astr(month(ft.pdata)), 2, '0') + '-' + padl(astr(day(ft.pdata)), 2, '0')>>",
	"tiposaft": "<<alltrim(tdcur.tiposaft)>>",
	"hash": "<<alltrim(fisccur.hash)>>",
	<<iif(tdCur.tipodoc = 3 and !empty(oftsJSON), ["ofts": ] + oftsJSON + [,], "")>>    "docref": "<<strtran(alltrim(ft.nmdoc), ' ', '_') + '_' + astr(ft.fno) + '_' + astr(year(ft.fdata))>>",
	"codmotiseimp": "<<alltrim(ft2.codmotiseimp)>>",
	"motiseimp": "<<alltrim(ft2.motiseimp)>>",
	<<iif(!isnull(base64PDF), ["base64": "] + base64PDF + [",], "")>>    "nif": "<<alltrim(e1cur.ncont)>>",
	"emitterName": "<<alltrim(escapeDoubleQuotes(e1cur.nomecomp))>>",
	"emitterAddress": "<<alltrim(escapeDoubleQuotes(e1cur.morada))>>",
	"emitterCity": "<<alltrim(escapeDoubleQuotes(e1cur.local))>>",
	"emitterPostalcode": "<<alltrim(escapeDoubleQuotes(e1cur.codpost))>>",
	"emitterCountry": "<<alltrim(e1Cur.codpais)>>",
	"emitterNIF": "<<'PT' + alltrim(e1cur.ncont)>>",
	"emitterSocialCapital": <<strtran(astr(e1Cur.capsocial), ',', '.')>>,
	"emitterContact": "<<alltrim(e1Cur.telefone)>>",
	"emitterEmail": "<<alltrim(e1cur.email)>>",
	"customerName": "<<alltrim(escapeDoubleQuotes(ft.nome))>>",
	"customerAddress": "<<alltrim(escapeDoubleQuotes(ft.morada))>>",
	"customerCity": "<<alltrim(ft.local)>>",
	"customerPostalcode": "<<alltrim(ft.codpost)>>",
	"customerCountry": "<<alltrim(ft3.codpais)>>",
	"customerNIF": "<<'PT' + alltrim(ft.ncont)>>",
	"customerContact": "<<alltrim(ft.telefone)>>",
	"customerEmail": "<<alltrim(clcur.email)>>",
	"taxes": <<taxesJSON>>,
	"lines": <<linesJSON>>,
	"ettiva": <<strtran(astr(ft.ettiva), ',', '.')>>,
	"ettiliq": <<strtran(astr(ft.ettiliq), ',', '.')>>,
	"etotal": <<strtran(astr(ft.etotal), ',', '.')>>,
	"efinv": <<strtran(astr(ft.efinv), ',', '.')>>,
	"evreg": <<strtran(astr(ftrdcur.evreg), ',', '.')>>,
	"erdtotal": <<strtran(astr(ft.erdtotal), ',', '.')>>,
	"evirs": <<strtran(astr(ft.evirs), ',', '.')>>
	}
endtext
*u_sqlexec("invoiceJSON", "curs_teste")
msg(invoiceJSON)
*msg(curs_teste)
*wait wind cursortoxml("invoiceJSON","\\10.0.0.13\Dados\04-GRINCOP_PHC\teste.xml",0,512)

*wait wind cursortoxml("curs_teste","\\10.0.0.13\Dados\04-GRINCOP_PHC\teste.xml",,512)
wait wind cursortoxml("e1Cur","\\10.0.0.13\Dados\04-GRINCOP_PHC\teste.xml",1,512,10000,"ublschema.xsd","C:\Users\jmendes\Desktop\ublschema.xsd")

return

loRequest = CREATEOBJECT("Microsoft.XMLHTTP")
messagebox(loRequest)
*loRequest=filetostr(my_folder)

**LER O FICHEIRO XML
*my_data = STRCONV(FILETOSTR(my_folder), 11)

msg(my_data)

*********************************************************************************************
*********************************************************************************************
*******************************************FUNCOES*******************************************

function emitePDF()

    text to getIDU textmerge noshow
        Select titulo
        from ftiduc
        where ndos = ?ft.ndoc or docmulti = 1
        order by impdef desc
    endtext

    u_sqlexec(getIDU, "iducur")
    if reccount("iducur") <= 0
        msg("Não foram encontradas impressões.")
        return
    endif

    iduStr = ""
    Select iducur
    go top
    Scan
    iduStr = iduStr + iif(!empty(iduStr), ", ", "") + alltrim(iduCur.titulo)
    endscan

    Create Cursor xVars ( no N(5), tipo c(1), Nome c(40), Pict c(100), lOrdem N(10), nValor N(18,5), cValor c(250), mValor m(10), tbVal m, lValor l, dValor d )

    Select xVars
    Append Blank
    Replace xVars.no With 1
    Replace xVars.tipo With "T"
    Replace xVars.Nome With "Impressão" 
    Replace xVars.Pict With ""
    Replace xVars.lOrdem With 1
    Replace xVars.tbVal With iduStr
    m.escolheu = .f.
    docomando("do form usqlvar with 'xvars', 'Seleccione a Impressão', .t.")

    if !m.escolheu
        return .null.
    endif

    Select xvars
    go top
    iduescolhido = xvars.cvalor
    if empty(iduescolhido)
        msg("Por favor escolha uma impressão válida.")
        return
    endif

    hora=substr(ft.usrhora,1,2)+"h"+substr(ft.usrhora,4,2)+"m" 

    *nomeficheiro = strtran(alltrim(ft.nmdoc), " ", "_") + "_" + astr(ft.fno) + "_" + astr(year(ft.fdata))   nomeficheiroext = nomeFicheiro + ".pdf"
    m.my_pdf = alltrim(ft.nmdoc)+"-"+astr(ft.fno)+"-"+dtoc(ft.usrdata)+"-"+hora

    *caminho = "C:\temp\" + nomeficheiroext
    m.cDir=my_folder+my_pdf+".pdf" 

    *idutopdf("FT","FI","FTCAMPOS","FICAMPOS","FTIDUC","FTIDUL",ft.ndoc,alltrim(iduescolhido),caminho,"","NO",.f.,"ONETOMANY")
    idutopdf("FT","FI","FTCAMPOS","FICAMPOS","FTIDUC","FTIDUL",ft.ndoc,alltrim(iduescolhido),m.cDir,"","NO",.f.,"ONETOMANY")

    loFac = CreateObject('Chilkat_9_5_0.FileAccess')

    *lcStrBase64 = loFac.ReadBinaryToEncoded(caminho,"base64")
    lcStrBase64 = loFac.ReadBinaryToEncoded(m.cDir,"base64")

    IF (loFac.LastMethodSuccess <> 1) THEN
        ? loFac.LastErrorText
        RELEASE loFac
        return .null
    ENDIF

    return lcStrBase64
endfunc

*********************************************************************************************

function escapeDoubleQuotes(lcStr)
	return strtran(lcStr, ["], [])
endfunc
