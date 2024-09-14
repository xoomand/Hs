User Function MT103MNT()

Local cNatureza     := MaFisRet(,"NF_NATUREZA") 
//Local aHeadSev      := PARAMIXB[1]
Local aColsSev      := PARAMIXB[2]

If FwIsInCallStack("u_hsapp001")
    aColsSev := {}

    aAdd(aColsSev,{cNatureza,100,"          ","SEV",0,.F.})
Endif 

Return aColsSev    
