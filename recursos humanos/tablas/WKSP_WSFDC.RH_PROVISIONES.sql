CREATE TABLE WKSP_WSFDC.RH_PROVISIONES
 (
   COD_PERSONA VARCHAR2(10) NOT NULL,
   COD_TIP_PROVISION VARCHAR2(3) NOT NULL,
   FECHA DATE NOT NULL,
   MTO_DEBE NUMBER(14,2) NOT NULL,
   MTO_HABER NUMBER(14,2) NOT NULL,
   SAL_ACTUAL NUMBER(14,2) NOT NULL,
   COD_MONEDA VARCHAR2(3) NOT NULL,
   PER_DESDE NUMBER(4,0),
   PER_HASTA NUMBER(4,0),
   DIA_HABER NUMBER(3,0),
   DIA_DEBE NUMBER(3,0),
   USU_INSERCION VARCHAR2(10) DEFAULT SUBSTR(USER,1,10) NOT NULL,
   FEC_INSERCION DATE DEFAULT SYSDATE NOT NULL,
   USU_MODIFICACION VARCHAR2(10) DEFAULT SUBSTR(USER,1,10) NOT NULL,
   FEC_MODIFICACION DATE DEFAULT SYSDATE NOT NULL
 );

COMMENT ON TABLE WKSP_WSFDC.RH_PROVISIONES IS 'Provisiones de vacaciones';
COMMENT ON COLUMN WKSP_WSFDC.RH_PROVISIONES.COD_TIP_PROVISION IS 'Codigo de Tipo de Provision';
COMMENT ON COLUMN WKSP_WSFDC.RH_PROVISIONES.FECHA IS 'Fecha de Provisi?n';
COMMENT ON COLUMN WKSP_WSFDC.RH_PROVISIONES.MTO_DEBE IS 'Debe';
COMMENT ON COLUMN WKSP_WSFDC.RH_PROVISIONES.MTO_HABER IS 'Haber';
COMMENT ON COLUMN WKSP_WSFDC.RH_PROVISIONES.SAL_ACTUAL IS 'Saldo Actual';
COMMENT ON COLUMN WKSP_WSFDC.RH_PROVISIONES.PER_DESDE IS 'Periodo desde el cual se computan las vacacioens';
COMMENT ON COLUMN WKSP_WSFDC.RH_PROVISIONES.PER_HASTA IS 'Periodo hasta el cual se computan las vacaciones.';
COMMENT ON COLUMN WKSP_WSFDC.RH_PROVISIONES.DIA_HABER IS 'Cantidad de d?as correspondientes al periodo.';
COMMENT ON COLUMN WKSP_WSFDC.RH_PROVISIONES.DIA_DEBE IS 'Cantidad de dias tomados del periodo.';

--Grant/Revoke object privileges
grant select, insert, update, delete on WKSP_WSFDC.RH_PROVISIONES to PUBLIC;
