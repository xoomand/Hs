#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} MT100GE2
Complementar a gravação na tabela dos títulos financeiros a pagar.
@type function
@version 1.0 
@author It Advanced
@since 04/10/2022
@return Nil
/*/

User Function MT100GE2()
    Local _AreaATU 	:= GetArea()
    //Local aTitAtual := PARAMIXB[1]
    Local nOpc      := PARAMIXB[2]
    //Local aHeadSE2  := PARAMIXB[3]
    Local aParcelas := ParamIXB[5]
    //Local nX        := ParamIXB[4]
    Local cHist     := SF1->F1_XOBS
    Local cForm     := SF1->F1_XFORMPG
    Local cCc       := ""
    Local i 

    SD1->(DbSetOrder(1))

	If SD1->(dbSeek(SF1->F1_FILIAL + SF1->F1_DOC + SF1->F1_SERIE + SF1->F1_FORNECE + SF1->F1_LOJA))
	    cCc := SD1->D1_CC		
	EndIF

    IF SF1->F1_TIPO == "N"
        If nOpc == 1 
            If Len(aParcelas) > 0 
                For i := 1 to Len(aParcelas)
                    SE2->E2_XFORMPG := cForm
                    SE2->E2_HIST    := cHist
                    SE2->E2_CCUSTO  := cCc
                Next i
            Else 
                SE2->E2_XFORMPG := cForm
                SE2->E2_HIST    := cHist
                SE2->E2_CCUSTO  := cCc
            Endif 
        Endif
    Endif 
    
    RestArea(_AreaATU)

Return(Nil)
