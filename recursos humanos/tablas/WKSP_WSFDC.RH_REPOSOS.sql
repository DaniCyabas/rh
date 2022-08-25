CREATE TABLE WKSP_WSFDC.RH_REPOSOS
 (
 COD_PERSONA VARCHAR2(10) NOT NULL,
 NRO_REPOSO NUMBER(5,0) NOT NULL,
 FEC_PROCESO DATE NOT NULL,
 FEC_INICIO DATE NOT NULL,
 FEC_FINAL DATE NOT NULL,
 CAN_DIAS NUMBER(3,0) NOT NULL,
 COD_CAU_REPOSO NUMBER(3,0) NOT NULL,
 OBSERVACION VARCHAR2(1000),
 USU_INSERCION VARCHAR2(10) DEFAULT SUBSTR(USER,1,10) NOT NULL,
 FEC_INSERCION DATE DEFAULT SYSDATE NOT NULL,
 USU_MODIFICACION VARCHAR2(10) DEFAULT SUBSTR(USER,1,10) NOT NULL,
 FEC_MODIFICACION DATE DEFAULT SYSDATE NOT NULL
 );
COMMENT ON TABLE WKSP_WSFDC.RH_REPOSOS IS 'Reposos de Empleados';
--Grant/Revoke object privileges
grant select, insert, update, delete on WKSP_WSFDC.RH_REPOSOS to PUBLIC;