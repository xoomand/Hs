#Include "Protheus.ch"
#Include "RwMake.ch"
#Include "TbiConn.ch"

/*/{Protheus.doc} Lsta001
description
ExecAuto genérico
@type function
@version 12.1.2210  
@author aluis
@since 13/01/2023
@param aExec, array, param_description
@param _cAlias_, variant, param_description
@param _cRot_, variant, param_description
@param nOpc, numeric, param_description
@return variant, return_description
/*/
User Function hsapp001(aExec,_cAlias_,_cRot_,nOpc)
Local lRet          := .F.

Local aLogAuto      := {}
Local cErro         := ""
Local nY, nx, ix, iy, iv, nI,i 

Local nPosNom       := 0
Local nPosCod       := 0
Local nPosLoj       := 0
Local cRetInt       := ""
Local cRet          := ""
Local cTabOn_       := ""
Local aTab_         := StrToArray(_cAlias_,"|")
Local fExec         := ""
Local aObs          := {}
Local aExecA        := {}
Local aExecB        := {}
Local aExecC        := {}
Local aItensRat     := {}
Local aParamAux     := {}
Local aRet          := {}

Private lMsErroAuto     := .F.
Private lMsHelpAuto     := .T.
Private lAutoErrNoFile  := .T.

nOpc := val(nOpc)

_cRot_ := Upper(_cRot_)

If nOpc == 3
    For iv := 1 to Len(aTab_)
        If aTab_[iv] == "DA4"
            aAdd(aExec[1], {"DA4_COD",GetSxeNum("DA4","DA4_COD") , Nil})
            ConfirmSx8()
        ElseIf aTab_[iv] == "SC5"
            aAdd(aExec[1], {"C5_NUM",GetSxeNum("SC5","C5_NUM") , Nil})
            ConfirmSx8()
        Endif 
    Next iv
Endif           

For nx := 1 to Len(aExec)
    If Len(aExec[nx]) > 0 
        If nx == 1 
            aExecA  := aExec[nx]
            Do Case 
            Case _cRot_ == "TMKA070"
                fExec   := "MSExecAuto({|x,y,z,a,b| " +_cRot_ +"(x,y,z,a,b)},aExecA,nOpc,"
            Case _cRot_ == "MATA410"
                fExec   := "MSExecAuto({|x,y,z|mata410(x,y,z)},aExecA,"
            OtherWise 
                fExec   := "MSExecAuto({|x,y| " +_cRot_ +"(x,y)},aExecA,nOpc)"
            EndCase 
        Else 
            Do Case 
            Case nx == 2 
                aExecB  := aClone(aExec[nx])
                fExec   += "aExecB,"
            Case nx == 3
                aExecC  := aClone(aExec[nx])
                fExec += "aExecC,"
            EndCase
        EndIf  
    Endif 
Next nx 
Do Case 
    Case  _cRot_ == "TMKA070"
        fExec += " .F.)"
    Case _cRot_ == "MATA410"
        fExec += " nOpc)"
    Case _cRot_ == "MATA103"
        If Len(aExecC) > 0            
            For i := 1 to Len(aExecB)
                aAdd(aItensRat, Array(2))
                aItensRat[Len(aItensRat)][1] := StrZero(i,4)
                aItensRat[Len(aItensRat)][2] := {}
                For nI := 1 To Len(aExecC)
                    If aExecC[nI][aScan(aExecC[nI], {|x| AllTrim(x[1]) == Alltrim("DE_ITEMNF")})][2] == aExecB[i][aScan(aExecB[i], {|x| AllTrim(x[1]) == Alltrim("D1_ITEM")})][2]
                        aAdd(aItensRat[Len(aItensRat)][2], aClone(aExecC[nI]))
                    Endif 
                Next Ni
            Next i
            fExec   := "MSExecAuto({|x,y,z,k,a,b| MATA103(x,y,z,,,,k,a,,,b)},aExecA,aExecB,3,aParamAux,aItensRat)"
        Else
            fExec   := "MSExecAuto({|x,y,z| MATA103(x,y,z)},aExecA,aExecB,3)" 
        Endif 
EndCase 

&fExec

//Se houve erro, gera um arquivo de log dentro do diretório da protheus data
If lMsErroAuto 
    cArqLog := _cAlias_+"-"+ dTos(dDatabase)+StrTran(Time(), ':', '-')+".log"
    aLogAuto    := {}
    aLogAuto    := GetAutoGrLog()
    For nY := 1 To Len(aLogAuto)
        If ValType(aLogAuto[nY]) == "C" 
            cErro += aLogAuto[nY] + CRLF
        Endif 
    Next nY
    ConOut( "hsapp001 " + cErro )
    MemoWrite("\log_integ\"  + cArqLog + ".txt",cErro)
    
    lRet    := .F.
Else
    dbSelectArea('SX2')
    SX2->(dbSeek(aTab_[1]))

    cRetInt    := '{"mensagem"'
    cRetInt    += ':"Integracao realizada, Tabela '+ Alltrim(X2Nome()) +Iif(nOpc == 3,' cadastrado(a)',' alterado(a)')+' com sucesso!"}'
    
    lRet := .T.
    
    If _cRot_ == "MATA103"    
        If !Empty(aExecA[aScan(aExecA, {|x| AllTrim(x[1]) == Alltrim("F1_XNUMCOM")})][2])
            aRet := hsappA(aExecA)                            
        Else 
            aRet := {.T.,"Integração realizada sem compensar titulo!"}
        Endif 

        lRet := aRet[1]
        If lRet
            cRetInt := '{"mensagem"'
            cRetInt += ':"Integracao realizada, Tabela '+ Alltrim(X2Nome()) +Iif(nOpc == 3,' cadastrado(a)',' alterado(a)')+' e '+aRet[2]+'!"}'
        Else
            cErro := aRet[2]
        Endif 
    Endif 
 
EndIf

If lRet
    cRet := cRetInt
Else
    cRet := cErro
Endif 

Return {lRet,cRet}

/*/{Protheus.doc} hsappA
    (long_description)
    @type  Static Function
    @author user
    @since 14/04/2024
    @version version
    @param param_name, param_type, param_descr
    @return return_var, return_type, return_description
    @example
    (examples)
    @see (links_or_references)
/*/
Static Function hsappA(aExecA)
Local lRet      := .F.
Local cQuery    := ""
Local cMsgFin   := ""
Local cTab      := GetNextAlias()
Local nTotValor := 0
Local nSldPA    := 0
Local aDados    := AClone(aExecA)
Local aRecPA    := {} 		// Array contendo os Recnos dos titulos PA
Local aRecSE2   := {} 	// Array contendo os Recnos dos titulos NF

ConOut("SELECIONANDO TITULO NACIONAL PARA COMPENSACAO")
        
cQuery := "SELECT R_E_C_N_O_ SE2REC, E2_VALOR " + CRLF
cQuery += "FROM " + RetSqlTab("SE2") + " " + CRLF
cQuery += "WHERE E2_FORNECE = '" + aDados[aScan(aDados, {|x| AllTrim(x[1]) == Alltrim("F1_FORNECE")})][2] + "' " + CRLF
cQuery += "AND E2_LOJA = '" + aDados[aScan(aDados, {|x| AllTrim(x[1]) == Alltrim("F1_LOJA")})][2] + "' " + CRLF
cQuery += "AND E2_PREFIXO = '" + aDados[aScan(aDados, {|x| AllTrim(x[1]) == Alltrim("F1_SERIE")})][2] + "' " + CRLF
cQuery += "AND E2_NUM = '" + aDados[aScan(aDados, {|x| AllTrim(x[1]) == Alltrim("F1_DOC")})][2] + "' " + CRLF
cQuery += "AND E2_BAIXA = '' " + CRLF
cQuery += "AND E2_MOEDA = 1 " + CRLF
cQuery += "AND E2_SALDO > 0 " + CRLF
cQuery += "AND E2_FILIAL = '"+xFilial("SE2")+"' " + CRLF
cQuery += "AND D_E_L_E_T_ = ' ' " + CRLF
cQuery := ChangeQuery(cQuery)

dbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), cTab, .F., .T.)

(cTab)->(dbGoTop())
While (cTab)->(!EOF())				
    AADD(aRecSE2,(cTab)->SE2REC)
    nTotValor := (cTab)->E2_VALOR
    (cTab)->(dbSkip())		
EndDo
(cTab)->(dbCloseArea())

ConOut("SELECIONANDO TITULO DE ADIANTAMENTO NACIONAL PARA COMPENSACAO")
        
cQuery := "SELECT R_E_C_N_O_ SE2REC, E2_SALDO " + CRLF
cQuery += "FROM " + RetSqlTab("SE2") + " " + CRLF
cQuery += "WHERE E2_FORNECE = '" + aDados[aScan(aDados, {|x| AllTrim(x[1]) == Alltrim("F1_FORNECE")})][2] + "' " + CRLF
cQuery += "AND E2_LOJA = '" + aDados[aScan(aDados, {|x| AllTrim(x[1]) == Alltrim("F1_LOJA")})][2] + "' " + CRLF
cQuery += "AND E2_PREFIXO = '" + aDados[aScan(aDados, {|x| AllTrim(x[1]) == Alltrim("F1_XPRECOM")})][2] + "' " + CRLF
cQuery += "AND E2_NUM = '" + aDados[aScan(aDados, {|x| AllTrim(x[1]) == Alltrim("F1_XNUMCOM")})][2] + "' " + CRLF
cQuery += "AND E2_TIPO = 'PA' " + CRLF
cQuery += "AND E2_MOEDA = 1 " + CRLF
cQuery += "AND E2_SALDO > 0 " + CRLF
cQuery += "AND E2_FILIAL = '"+FwxFilial("SE2")+"' " + CRLF
cQuery += "AND D_E_L_E_T_ = '' " + CRLF
cQuery := ChangeQuery(cQuery)
dbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), cTab, .F., .T.)

nSldPA := 0
(cTab)->(dbGoTop())
While (cTab)->(!EOF())
    AADD(aRecPA,(cTab)->SE2REC)
    nSldPA += (cTab)->E2_SALDO
    (cTab)->(dbSkip())
Enddo
(cTab)->(dbCloseArea())

If nTotValor < nSldPA
    nSldPA := nTotValor
Endif

lRet := .T.

If Len(aRecPA) > 0 .and. Len(aRecSE2) > 0

    lContabiliza := .F.
    lAglutina := .F.
    lDigita	:= .F.

    lRet := MaIntBxCP(2,aRecSE2,,aRecPA,,{lContabiliza,lAglutina,lDigita,.F.,.F.,.F.},,,,nSldPA,dDataBase)
    lRet := hsappB(aRecSE2)

    If lRet
        cMsgFin := "compensacao realizada com sucesso"
    Else
        cMsgFin := "compensacao NAO REALIZADA, fazer manualmente." + DTOC(dDataBase)
    Endif
Else
    cMsgFin := "nao existe compensacao a ser realizada"
    lRet := .T.
Endif

Return {lRet,cMsgFin}

Static Function hsappB(aRecSE2)

	Local aArea := GetArea()
	Local nX   	:= 0
	Local lRet 	:= .F.

	For nX := 1 To Len(aRecSE2)
		
		dbSelectArea("SE2")
		dbGoTo(aRecSE2[nX])	
		
		dbSelectArea("SE5")
		dbSetOrder(2)
		lRet := dbSeek(xFilial("SE5") + PadR("CP", TamSX3("E5_TIPODOC")[1]) + SE2->E2_PREFIXO + SE2->E2_NUM + SE2->E2_PARCELA + SE2->E2_TIPO + DTOS(dDataBase) + SE2->E2_FORNECE + SE2->E2_LOJA)
				
	Next

	RestArea(aArea)
	
Return lRet
