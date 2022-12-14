CREATE TABLE WKSP_WSFDC.RH_PER_INDEMNIZACIONES
 (
 ANO_DESDE NUMBER(2,0) NOT NULL,
 ANO_HASTA NUMBER(2,0) NOT NULL,
 DESCRIPCION VARCHAR2(40) NOT NULL,
 DIAS_INDEMNIZACION NUMBER(3,0),
 USU_INSERCION VARCHAR2(10) DEFAULT SUBSTR(USER,1,10) NOT NULL,
 FEC_INSERCION DATE DEFAULT SYSDATE NOT NULL,
 USU_MODIFICACION VARCHAR2(10) DEFAULT SUBSTR(USER,1,10) NOT NULL,
 FEC_MODIFICACION DATE DEFAULT SYSDATE NOT NULL
 );

COMMENT ON TABLE WKSP_WSFDC.RH_PER_INDEMNIZACIONES IS 'Periodos de Indenmizaci?n';
COMMENT ON COLUMN WKSP_WSFDC.RH_PER_INDEMNIZACIONES.ANO_DESDE IS 'A?o de antiguedad laboral desde';
COMMENT ON COLUMN WKSP_WSFDC.RH_PER_INDEMNIZACIONES.ANO_HASTA IS 'A?o de antiguedad laboral Hasta';
COMMENT ON COLUMN WKSP_WSFDC.RH_PER_INDEMNIZACIONES.DESCRIPCION IS 'Descripci?n';
COMMENT ON COLUMN WKSP_WSFDC.RH_PER_INDEMNIZACIONES.DIAS_INDEMNIZACION IS 'Dias de vacaciones correspondientes';
--Grant/Revoke object privileges
grant select, insert, update, delete on WKSP_WSFDC.RH_PER_INDEMNIZACIONES to PUBLIC;
