#Include "TOTVS.CH"
#Include "RESTFUL.CH"
#Include "FWMVCDEF.CH"
#Include "TOPCONN.CH"
#include "tryexception.ch"

WsRestFul hsws001 Description "API Consulta Generica Protheus"
  
  WsMethod POST  Description "Consulta tabela Protheus" WSSYNTAX "hsws001/{1}"

End WsRestFul

WsMethod POST WsReceive Receive WsService hsws001
  Local lRet     := .F.
  Local oJson	 := THashMap():New()
  Local cMsg     := ""
  Local cJsonRet := ""
  Local cBody    := ""
   
  ::SetContentType("application/json")

  cBody := Self:GetContent()
  lRet  := FWJsonDeserialize(cBody,@oJson)

  If lRet
	 lRet := FscfgTab(cBody, @cJsonRet, @cMsg)
   else	
	 cMSg := "JSon Error"	
  EndIf

  If ! lRet
     SetRestFault(400, cMsg)
   else
	 ::SetResponse(cJsonRet)	
  EndIf
Return lRet

/*/{Protheus.doc} FscfgTab
description
@type function
@version 12.1.2210 
@author aluis
@since 11/01/2023
@param cJson, character, param_description
@param cJsonRet, character, param_description
@param cMsg, character, param_description
@return variant, return_description
/*/

/* Json
{
    "Empresa":"99",
    "query":"select a1_nome, r_e_c_n_o_ from sa1990 order by 2"
}
*/
Static Function FscfgTab(cJson, cJsonRet, cMsg)
	Local oQry     := JsonObject():New()
    Local ret       := oQry:FromJson(cJson)
	Local aArea     := GetArea()
	Local aStruct   := {}  
	Local nX        := 0
	
	Local bError := {|oError| MyError(oError)}
	Local oError

	Local cCursor 	:= GetNextAlias()
	
	Default cMsg     := ""
	Default cJsonRet := ""

	TRYEXCEPTION USING bError

	if (ret) == "C"
        //conout("Falha ao transformar texto em objeto json. Erro: " + ret)
    endif
    
	lRet := .T.//RpcSetEnv(oQry['Empresa'])

	If lRet
		cQuery  := oQry['query']
				
		If Select((cCursor)) > 0
			dbSelectArea((cCursor))
			(cCursor)->(dbCloseArea())
		Endif
		
		TcQuery cQuery Alias (cCursor) New
		
		aStruct := (cCurSor)->(dbStruct())
		For nX := 1 To Len(aStruct)
			If aStruct[nX][2] <> "C"
				TcSetField(cCursor, aStruct[nX][01], aStruct[nX][02], aStruct[nX][03], aStruct[nX][04])
			EndIf
		Next		

		If ! (cCurSor)->(Eof())	
			cJsonRet := ""
			cJsonRet += '{'
			cJsonRet += ' "items" : ['

			While ! (cCurSor)->(Eof())
				cJsonRet += '  {'	
				//cJsonRet += '   "fields": {'

				For nX := 1 To Len(aStruct)	
										
					cJsonRet += '  "' + lower(aStruct[nX][01]) + '" : '
					
					Do Case 
						Case aStruct[nX][02] == "C"
							cJsonRet += '"' + (cCurSor)->(FieldGet(FieldPos(aStruct[nX][01]))) + '"'

						Case aStruct[nX][02] == "M"
							cJsonRet += '"' + &(cCurSor)->(aStruct[nX][01]) + '"'

						Case aStruct[nX][02] == "N"
							cJsonRet += Str((cCurSor)->(FieldGet(FieldPos(aStruct[nX][01]))))

						Case aStruct[nX][02] == "D"
							cJsonRet += '"' + DtoC((cCurSor)->(FieldGet(FieldPos(aStruct[nX][01])))) + '"'

						Case aStruct[nX][02] == "L"
							cJsonRet += '"' + IIf((cCurSor)->(FieldGet(FieldPos(aStruct[nX,1]))),".T.",".F.") + '"'
					EndCase

					If nX < Len(aStruct)
						cJsonRet += ','	
					Endif	
				Next

				//cJsonRet += '}'
				cJsonRet += '}'	
				
				(cCurSor)->(dbSkip())
				
				If ! (cCurSor)->(Eof())
					cJsonRet += ','
				EndIf	
			EndDo
			cJsonRet += ']'
			cJsonRet += '}'
		else
			cJsonRet := ""
			cJsonRet += '{'
			cJsonRet += ' "items" : ['
			cJsonRet += ']'
			cJsonRet += '}'
			cMsg := "Nenhum registro encontrado"
		EndIf

		(cCursor)->(dbclosearea())
	Else    
		cErro := "[Erro] - Empresa/Filial não existe!"
		SetRestFault(500, cErro)
		lRet := .F.
	Endif 
	
	CATCHEXCEPTION USING oError

		cJsonRet := '"Mensagem": "ERRO"'
		cJsonRet += ',"Mensagem Detalhada": "'+oError:Description+chr(13)+chr(10)+oError:ErrorStack+'"'
		FWJsonDeserialize(cJsonRet,@oQry)
		If ValType(oQry) != "O"
			MsgStop("ERRO: Retorno Inválido.")
			Return
		endif
		MsgStop("ERRO: "+chr(13)+chr(10)+oQry:MensagemDetalhada)
		Return

	ENDEXCEPTION

	RestArea(aArea)

Return lRet 

Static Function MyError(oError)

BREAK

Return
