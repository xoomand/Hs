#Include "TOTVS.CH"
#Include "RESTFUL.CH"
#Include "RPTDEF.CH"
  
WsRestFul hsws002 Description 'API para manutenção de Cadastros' Format APPLICATION_JSON
      
    WSMETHOD POST ManuCad     DESCRIPTION 'Manutenção de Cadastros'      Path "/ManuCad"   WSSYNTAX '/hsws002/ManuCad'        PRODUCES APPLICATION_JSON
    
EndWsRestFul

WSMETHOD POST ManuCad WSRECEIVE WSRESTFUL hsws002
    Local lRet          := .T.
  
    Local aArea         := GetArea()
    Local oJson

    Local aJSonret      := {}  
    Local aJson         := {}
    Local cJson         := Self:GetContent()
    
    Local cEmp_         := ""
    Local cFil_         := ""
    Local cRot_         := ""
    Local cAlias_       := ""

    Local aAutoA        := {}
    Local aAutoB        := {}
    Local aAutoC        := {}
    Local aField        := {}
    Local aField2       := {}
    Local aFields       := {}
    Local aTabela       := {}
    Local aItem         := {}
    Local aAuxDados     := {}
    Local _aArea   		:= {}
    Local _aAlias  		:= {}
    
    Local lA            := .F.
    Local cError  
    Local cErro         := ""
    Local cNos          := "" 
    
    Local i, ix, iy, ia, ib, ic
    Local nOpcAuto      := 3
    Local cPos          := 0
    Local fExec         
    Local nNos          := 0

    Private aObs            := {}
    Private lMsErroAuto     := .F.
    Private lMsHelpAuto     := .T.
    Private lAutoErrNoFile  := .T.
  
    //Se não existir o diretório de logs dentro da Protheus Data, será criado
    IF !ExistDir("\log_integ" )
        MakeDir("\log_integ" )
    EndIF    
  
    //Definindo o conteúdo como JSON, e pegando o content e dando um parse para ver se a estrutura está ok
    Self:SetContentType("application/json")
    oJson   := JsonObject():New()
    cError  := oJson:FromJson(cJson)
    
    //Se tiver algum erro no Parse, encerra a execução
    If !Empty(cError)
        SetRestFault(500,'Parser Json Error')
        lRet    := .F.
    Else
        aJson := oJson:GetNames()
        //FWJsonDeserialize(cJson,@oJson)
        For ia := 1 To Len(aJson)
            aAutoA      := {}
            aAutoB      := {}
            aAutoC      := {}
            nNos        := 0
            aField      := oJson[aJson[ia]][1]:GetNames()    
            cEmp_       := oJson[aJson[ia]][1]:GetJsonObject('empresa')
            cFil_       := oJson[aJson[ia]][1]:GetJsonObject('filial')
            nOpcAuto    := oJson[aJson[ia]][1]:GetJsonObject('acao')
            cAlias_     := oJson[aJson[ia]][1]:GetJsonObject('tabela')
            cRot_       := oJson[aJson[ia]][1]:GetJsonObject('rotina')

            If Empty(nOpcAuto)
                cErro += "[Erro] - Defina a ação, Inclui(I)/Altera(A) " + CRLF
                SetRestFault(500, cErro)
                lRet := .F.
            Else 
                If Upper(nOpcAuto) == "I"
                    nOpcAuto := "3"
                ElseIf Upper(nOpcAuto) == "A" 
                    nOpcAuto := "4"
                Else 
                    nOpcAuto := nOpcAuto
                Endif 
            Endif 

            If Empty(cEmp_)
                cErro += "[Erro] - Favor inserir a tag Empresa com seu respectivo conteudo " + CRLF
                SetRestFault(500, cErro)
                lRet := .F.
            Endif 
            
            If Empty(cAlias_)
                cErro += "[Erro] - Favor inserir a tag Tabela com seu respectivo conteudo " + CRLF
                SetRestFault(500, cErro)
                lRet := .F.
            Endif 

            If Empty(cRot_)
                cErro += "[Erro] - Favor inserir a tag Rotina com seu respectivo conteudo " + CRLF
                SetRestFault(500, cErro)
                lRet := .F.
            Endif 
            
            If lRet
                
                If Empty(cFil_)
                    For i := 1 To Len(aField)
                        If Right(Upper(aField[i]),6) == "FILIAL"
                            cFil_ := oJson[aJson[ia]][1]:GetJsonObject(aField[i])
                            Exit
                        Endif 
                    Next i 
                Endif 
                
                If Empty(cFil_)
                    rpcClearEnv()
                    lRet := RpcSetEnv(cEmp_)
                Else 
                    rpcClearEnv()
                    If cRot_ == "login"
                        lRet := RpcSetEnv(cEmp_,cFil_,oJson[aJson[ia]][1]:GetJsonObject('login'),oJson[aJson[ia]][1]:GetJsonObject('senha'))                
                    Else 
                        lRet := RpcSetEnv(cEmp_,cFil_)                
                    Endif 
                    
                EndIf 
                
                If lRet .and. (cRot_ != "login")
                    cPos := ""
                    aTabela := StrToArray(cAlias_,"|")
                    
                    CtrlArea(1,@_aArea,@_aAlias,aTabela) // GetArea

                    aSort(aField)

                    For ix := 1 To Len(aField)
                        If !aField[ix] $ "acao|action|rotina|tabela"
                            If ValType(oJson[aJson[ia]][1]:GetJsonObject(aField[ix])) <> "A" 
                                cNos := "{aAutoA"
                                aFields := fGerAuto(aField[ix],aTabela)

                                If aFields[1]
                                    cFildExec := oJson[aJson[ia]][1]:GetJsonObject(lower(aFields[2]))
                                    aAdd(aAutoA, {aFields[2], fType(aFields[2],Iif(cFildExec == NIL,;
                                                                oJson[aJson[ia]][1]:GetJsonObject(upper(aFields[2])),;
                                                                cFildExec)), NIL})
                                Endif  
                            Else
                                nNos++
                                cNos += ",aAuto"+cValtoChar(nNos)
                                &("aAuto"+cValtoChar(nNos)) := {}

                                For ib := 1 to Len(aField2 := oJson[aJson[ia]][1]:GetJsonObject(aField[ix]))
                                    aFieldA := oJson[aJson[ia]][1][aField[ix]][ib]:GetNames()
                                    //aItem := fGerAuto("_ITEM",aTabela)

                                    /*If aItem[1] .And. !Alltrim(Upper(cRot_)) $ "TICKET|TICKETINTERNO_COMPEDIDO"
                                        aAdd(aAuxDados, {aItem[2], StrZero(ib,2), ".T."})
                                    Endif */

                                    For iy := 1 To Len(aFieldA)
                                        aFields := fGerAuto(aFieldA[iy],aTabela)

                                        If aFields[1] 
                                            cFildExec := oJson[aJson[ia]][1][aField[ix]][ib]:GetJsonObject(lower(aFields[2]))
                                            aAdd(aAuxDados, {aFields[2], fType(aFields[2],Iif(cFildExec == NIL,;
                                                                            oJson[aJson[ia]][1][aField[ix]][ib]:GetJsonObject(upper(aFields[2])),;
                                                                            cFildExec)), NIL})                                    
                                        Endif

                                    Next iy
                                                                                    
                                    AAdd(&("aAuto"+cValtoChar(nNos)), aAuxDados) 
                                    aAuxDados := {}

                                Next ib 
                                
                            Endif 
                        Endif 
                    Next ix
                    cNos += "}"
                    
                    // DbSelectArea("ZZZ")
                    // DbSetOrder(1)
                    // If dbSeek(fwxFilial("ZZZ")+Alltrim(Upper(cRot_)))
                    //     fExec := "U_"+Alltrim(Upper(ZZZ->ZZZ_EXECUT))+"(&cNos,cAlias_,cRot_,nOpcAuto)"
                    //     aJSonret := &fExec
                    // Else 
                        aJSonret := U_hsapp001(&cNos,cAlias_,cRot_,nOpcAuto)
                    //Endif 
                    
                    If Len(aJSonret) > 0
                        If aJSonret[1]                            
                            Self:SetResponse(aJSonret[2])
                            lRet := .T.
                        Else 
                            SetRestFault(500, aJSonret[2])
                            lRet := .F.
                        Endif 
                    Endif 

                    CtrlArea(2,_aArea,_aAlias) // RestArea
                    RpcClearEnv()
                Else    
                    If lRet 
                        Self:SetResponse("Usuario autenticado")
                    Else
                        If cRot_ == 'login'
                            cErro := "[Erro] - Usuario/Senha não existe!"
                        Else     
                            cErro := "[Erro] - Empresa/Filial não existe!"
                        Endif 
                        SetRestFault(500, cErro)
                    Endif 
                          
                EndIf
            Endif
        Next ia      
    Endif 
    
    RestArea(aArea)
    FreeObj(oJson)
Return(lRet)

Static Function CtrlArea(_nTipo,_aArea,_aAlias,_aArqs)
Local _nN
// Tipo 1 = GetArea()
If _nTipo == 1
	_aArea   := GetArea()
	For _nN  := 1 To Len(_aArqs)
		DbSelectArea(_aArqs[_nN])
		AAdd(_aAlias,{ Alias(), IndexOrd(), Recno()})
	Next
// Tipo 2 = RestArea()
Else
	For _nN := 1 To Len(_aAlias)
		DbSelectArea(_aAlias[_nN,1])
		DbSetOrder(_aAlias[_nN,2])
		DbGoto(_aAlias[_nN,3])
	Next
	RestArea(_aArea)
Endif
Return Nil

Static Function fGerAuto(cCampo,aTab)
Local cRet    := "" 
Local cTabOn  := ""
Local cPos    := ""
Local nPos    := 0
Local lRet    := .F.

If !cCampo $ "AUTBANCO|AUTAGENCIA|AUTCONTA" 
    cCampo := Upper(U_fRetTab(cCampo,1,aTab))
    cTabOn := Upper(U_fRetTab(cCampo,2,NIL))
    If cTabOn <> cPos	
        nPos := aScan(aTab, {|x| x == cTabOn})
        If nPos > 0 
            DbSelectArea(aTab[nPos])      
            If FieldPos(cCampo) > 0
                lRet := .T.
                cRet := cCampo 
            Endif                     
        Endif 
        cPos := cTabOn
    Endif
Else 
    cRet := cCampo
    lRet := .T.
Endif 

Return {lRet,cRet}

User Function fRetTab(cCpo,nOpc,aTab_)
    Local cRetTab   := ""
    Local cCampNul  := ""
    Local i         

    If nOpc == 1        
        If Len(substr(cCpo,1,At("_", cCpo)-1))==0
            For i := 1 To Len(aTab_)
                cCampNul := Iif(Substr(aTab_[i],1,1)=="S",Substr(aTab_[i],2,2),Substr(aTab_[i],1,3))
            Next i
            cRetTab  := cCampNul+cCpo
        Else 
            cRetTab  := cCpo
        Endif 
    Else
        cRetTab := Iif(Len(substr(cCpo,1,At("_", cCpo)-1))==2,"S"+substr(cCpo,1,At("_", cCpo)-1),substr(cCpo,1,At("_", cCpo)-1))    
    Endif 
Return cRetTab

Static Function fType(cCampo, cResult)
Local cRet  := ''
Local cType := FWSX3Util():GetFieldType( cCampo )

Do Case 
    Case cType == "D" .And. ValType(cResult) == "C"
        cRet := cTod(cResult)
    Case cType == "N" .And. ValType(cResult) == "C"
        cRet := Val(cResult)
    Case cType == "C" .And. ValType(cResult) == "C" .And. AT( "-", cResult ) > 0
        cRet := strtran(strtran(cResult,"-",""),".","")
    OtherWise
        If ValType(cResult) == "N"
            cRet := cResult
        Else 
            If Empty(cType)
                cRet := cResult
            Else
                cRet := PadR(cResult,TamSX3(cCampo)[1])
            Endif 
            ConOut( "hsws002 " + cRet + " tamanho " + cValtoChar(Len(cRet)))
        Endif 
EndCase 

Return cRet
