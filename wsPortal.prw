#INCLUDE 'PROTHEUS.CH'
#INCLUDE "TOTVS.CH"
#INCLUDE "TOTVSWEBSRV.CH"
#INCLUDE "XMLXFUN.CH"
#INCLUDE "APWEBSRV.CH"
#include "topconn.ch"
#INCLUDE "RWMAKE.CH"
#INCLUDE "TBICONN.CH"
#INCLUDE "ERROR.CH"
#INCLUDE 'APWEBEX.CH'
#include 'Fileio.ch'  
#INCLUDE "TBICODE.CH"
#INCLUDE "WEBEXDEF.CH"

USER FUNCTION wsPor02()
RETURN()

//========================================================================
// Estruturas                                                           
//========================================================================

// Informações de login e informações do usuário
WSSTRUCT STInfos
    WSDATA aInfoUsuarioLogado AS Array of String
ENDWSSTRUCT

// Informações de login e informações do usuário editado
WSSTRUCT STInfosEditado
	 WSDATA Empresa AS String
	 WSDATA Usuario AS String
	 WSDATA Email AS String
	 WSDATA Fone AS String
	 WSDATA Celular AS String
	 WSDATA CODCLI AS String
	 WSDATA TituloImagem AS String
	 WSDATA DDDFONE AS String
	 WSDATA DDDCEL AS String
ENDWSSTRUCT                         

//========================================================================
// WSSERVICE                                                            
//========================================================================

WSSERVICE wsPor02 DESCRIPTION "Webservice do Portal do Cliente Moriah"
	
	// Propriedades
    WSDATA _cNomeCliente As String
    WSDATA _cSenhaCliente As String
    WSDATA bExecutou As String   
    
    // Estruturas
    WSDATA _STInfos As STInfos
    WSDATA STInfosEditado As STInfosEditado
    
    // Métodos
    WSMETHOD AutLST DESCRIPTION "Retorna .F. caso o usuários não esteja cadastrados no sistema, e retorna .T. se o usuário estiver cadastrado. Caso esteja, lista informações do usuário em um vetor."
	 WSMETHOD setPerfil DESCRIPTION "Seta informações do perfil do usuário."

ENDWSSERVICE

//========================================================================
// MÉTODOS                                                              
//========================================================================

// Autentica e lista informações do usuário logado
WSMETHOD AutLST WSRECEIVE _cNomeCliente, _cSenhaCliente WSSEND _STInfos WSSERVICE wsPor02
	
	Local ZR_USUARIO := ::_cNomeCliente
	Local ZR_SENHA := ::_cSenhaCliente
	Local cQuery := ""
	Local _isCadastrado := .F.
	
	
	// Cria o objeto de retorno
	::_STInfos := WSClassNew("STInfos")
	::_STInfos:aInfoUsuarioLogado := {}
			
	cQuery := " SELECT * FROM " + RetSqlName("SZR")
	cQuery += " WHERE ZR_SENHA = '"+ZR_SENHA+"' "
	cQuery += "	AND ZR_USUARIO = '"+ZR_USUARIO+"' "
	cQuery += " AND ZR_STATUS = 'A' "
	
	If Select("QSZR") > 0
		QSZR->(DbCloseArea())
	Endif
	
	dbUseArea(.T., 'TOPCONN', TCGenQry(,,cQuery), "QSZR", .F., .T.)
	
	dbGoTop()
	
	_isCadastrado = !EMPTY(ALLTRIM(QSZR->ZR_USUARIO))
	
	if (_isCadastrado == .T.)
		::_STInfos:aInfoUsuarioLogado := {"true", ALLTRIM(QSZR->ZR_NOMCLI), ALLTRIM(QSZR->ZR_USUARIO), ALLTRIM(QSZR->ZR_EMAIL), ALLTRIM(QSZR->ZR_DDDFONE), ALLTRIM(QSZR->ZR_FONE), ALLTRIM(QSZR->ZR_DDDCEL), ALLTRIM(QSZR->ZR_CELULAR), ALLTRIM(QSZR->ZR_NOME), ALLTRIM(QSZR->ZR_CODCLI), ALLTRIM(QSZR->ZR_TITUIMG), ALLTRIM(QSZR->ZR_DDDFONE), ALLTRIM(QSZR->ZR_DDDCEL)}
	else
		::_STInfos:aInfoUsuarioLogado := {"false"}
	endif                    
	
	QSZR->(DbCloseArea())

RETURN .T.

// Editar informações de perfil
WSMETHOD setPerfil WSRECEIVE STInfosEditado WSSEND bExecutou WSSERVICE wsPor02

	Local bExecutou := .F.
	STInfosEditado = WSClassNew("STInfosEditado")
	                                                                                                                                                                                                    
	cQry := " SELECT R_E_C_N_O_ AS SZRRECNO FROM "+RetSqlName("SZR")
	cQry += " WHERE ZR_USUARIO = '"+::STInfosEditado:Usuario+"' AND "
	cQry += " ZR_CODCLI = '"+::STInfosEditado:CODCLI+"' AND "
	cQry += " D_E_L_E_T_ = '' "
	
	dbUseArea(.T., 'TOPCONN', TCGenQry(,,cQry), "TMP", .F., .T.)
	                                                
	SZR->(DbGoto(TMP->SZRRECNO))
	
	RECLOCK("SZR", .F.)
	SZR->ZR_EMAIL := ::STInfosEditado:Email
	SZR->ZR_FONE := ::STInfosEditado:Fone
	SZR->ZR_CELULAR := ::STInfosEditado:Celular
	SZR->ZR_NOMCLI := ::STInfosEditado:Empresa
	SZR->ZR_TITUIMG := ::STInfosEditado:TituloImagem
	SZR->ZR_DDDCEL := ::STInfosEditado:DDDCEL
	SZR->ZR_DDDFONE := ::STInfosEditado:DDDFONE
	MSUNLOCK()

	TMP->(DbCloseArea())
	bExecutou := .T.
			
RETURN .T.