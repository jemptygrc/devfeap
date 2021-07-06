LOCAL c_nomexml, c_nomefilesign
c_nomexml= ""


*c_nomexml="blablaxml"
c_nomexml=alltrim(factFE.NOMEDOC)+"-"+astr(factFE.numdoc)+"-"+dtoc(factFE.usrdata)+"-"+substr(factFE.usrhora,1,2)+"h"+substr(factFE.usrhora,4,2)+"m"

c_nomefilesign = ""
tcfilepdf = "FaturaAzul"
*tcfilepdf = ""
makexmlubl_2_1_cius(@c_nomexml, @c_nomefilesign, tcfilepdf, y_tiposaft)



local my_xml, my_folder
my_xml=""
my_folder=""

my_folder="F:\04-GRINCOP_PHC\"
my_xml=(JUSTFNAME(m.c_nomexml))
my_pathXML=my_folder+my_xml
*msg(my_pathXML)
msg("O ficheiro '"+my_xml+"' foi exportado com sucesso para a pasta: '"+my_folder+"'","",.t.)
msg("Fatura exportada para ficheiro XML com sucesso!","WAIT")



RENAME (c_nomexml) to (my_folder+JUSTFNAME(m.c_nomexml))




