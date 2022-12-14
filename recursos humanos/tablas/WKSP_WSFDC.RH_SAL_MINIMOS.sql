CREATE TABLE WKSP_WSFDC.RH_SAL_MINIMOS
 (
   COD_SAL_MINIMO NUMBER(3,0) NOT NULL,
   DESCRIPCION VARCHAR2(40) NOT NULL,
   MONTO NUMBER(14,2) NOT NULL,
   COD_MONEDA VARCHAR2(3) NOT NULL,
   USU_INSERCION VARCHAR2(10) DEFAULT SUBSTR(USER,1,10) NOT NULL,
   FEC_INSERCION DATE DEFAULT SYSDATE NOT NULL,
   USU_MODIFICACION VARCHAR2(10) DEFAULT SUBSTR(USER,1,10) NOT NULL,
   FEC_MODIFICACION DATE DEFAULT SYSDATE NOT NULL
 );

COMMENT ON TABLE WKSP_WSFDC.RH_SAL_MINIMOS IS 'Salarios Minimos del m?dulo de RRHH';
COMMENT ON COLUMN WKSP_WSFDC.RH_SAL_MINIMOS.COD_SAL_MINIMO IS 'Codigo de Tipo de Salario M?nimo';
COMMENT ON COLUMN WKSP_WSFDC.RH_SAL_MINIMOS.DESCRIPCION IS 'Descripci?n del tipo de salario M?nimo';
COMMENT ON COLUMN WKSP_WSFDC.RH_SAL_MINIMOS.MONTO IS 'Monto del Salario M?nimo';
-- Grant/Revoke object privileges 
grant select, insert, update, delete on WKSP_WSFDC.RH_SAL_MINIMOS to PUBLIC;
