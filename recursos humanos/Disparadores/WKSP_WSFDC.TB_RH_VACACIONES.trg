CREATE OR REPLACE TRIGGER WKSP_WSFDC.TB_RH_VACACIONES
 BEFORE DELETE OR INSERT OR UPDATE
 ON RH_VACACIONES
 REFERENCING OLD AS OLD NEW AS NEW
 FOR EACH ROW
DECLARE
   v_dia_prov     rh_provisiones.dia_haber%type;
   v_saldo_prov   rh_provisiones.sal_actual%type;
   v_ing_vacacion rh_tip_ingresos.cod_tip_ingreso%type;
BEGIN
   IF inserting THEN
    --:new.fec_hasta     := :new.fec_desde + :new.can_dias;
      :new.fec_hasta     := fuh_obt_dias_habiles(:new.fec_desde,:new.can_dias);
      :new.ind_procesado := 'N';
      IF :new.fec_desde > :new.fec_hasta THEN
         raise_application_error(-20000,
         'Rango de fechas invalido');
      END IF;
      --- Recuperar periodo al que pertenece y monto correspondiente
      BEGIN
         begin
            select rh_par_empresas.cod_tip_prov_vacacion
            into   v_ing_vacacion
            from   rh_par_empresas, ge_par_generales
            where  rh_par_empresas.cod_empresa = ge_par_generales.cod_persona;
         exception
            when no_data_found then
               raise_application_error(-20000,
               'No se existe tipo de ingreso para vacación');
            when others then
               raise_application_error(-20000,
               'Error al obtener tipo de ingreso para vacación');
         end;

         select p1.per_desde, p1.per_hasta, p1.dia_haber - nvl(p1.dia_debe,0),
                p1.sal_actual, p1.cod_moneda
         into :new.per_desde, :new.per_hasta, v_dia_prov,
               v_saldo_prov,  :new.cod_moneda
         from rh_provisiones p1
         where p1.cod_persona = :new.cod_persona
         and p1.cod_tip_provision = v_ing_vacacion --- vacaciones
         and p1.fecha = (select min(p2.fecha)
                         from   rh_provisiones p2
                         where  p1.cod_persona = p2.cod_persona
                         and    p2.cod_tip_provision = v_ing_vacacion --- vacaciones
                         and    p2.sal_actual > 0
                         and    p2.per_desde is not null);
      exception
         when no_data_found then
            raise_application_error(-20000,
            'El empleado '||:new.cod_persona||' no posee vacaciones computadas (provision)');
      END;
      IF :new.can_dias > v_dia_prov then
         raise_application_error(-20000,
         'Cantidad de dias '||to_char(:new.can_dias)||
         ' supera a saldo dias segun periodo '||to_char(v_dia_prov));
      END IF;
      IF :new.can_dias = v_dia_prov then
         :new.monto := v_saldo_prov;
      ELSE
         :new.monto := round((v_saldo_prov/v_dia_prov)*:new.can_dias,0);
      END IF;
   ELSIF updating THEN
      IF :new.can_dias     <> :old.can_dias
      or :new.fec_hasta    <> :old.fec_hasta
      or :new.monto <> :old.monto THEN
         raise_application_error(-20000,
         'No pueden modificarse datos iniciales de vacaciones');
      END IF;
      --- Si cambia el proceso
      IF :new.ind_procesado = 'S' and :old.ind_procesado = 'N' then
         --- Actualizar provision
         update rh_provisiones
         set dia_debe = dia_debe + :new.can_dias,
             mto_debe = mto_debe + :new.monto
         where cod_persona = :new.cod_persona
         and per_desde = :new.per_desde
         and per_hasta = :new.per_hasta;
         IF sql%notfound THEN
            raise_application_error(-20000,
            'No pudo actualizarse provision periodo '||to_char(:new.per_desde)||' empleado '||:new.cod_persona);
         END IF;
      ELSIF :new.ind_procesado = 'N' and :old.ind_procesado = 'S' THEN
         --- Reversar provision
         update rh_provisiones
         set dia_debe = dia_debe - :new.can_dias,
             mto_debe = mto_debe - :new.monto
         where cod_persona = :new.cod_persona
         and per_desde = :new.per_desde
         and per_hasta = :new.per_hasta;
         IF sql%notfound THEN
            raise_application_error(-20000,
            'No pudo actualizarse provision periodo '||to_char(:new.per_desde)||' empleado '||:new.cod_persona);
         END IF;
      END IF;
   ELSIF deleting THEN
      IF :old.ind_procesado = 'S' THEN
         raise_application_error(-20000,
         'No puede eliminar vacacion procesada '||to_char(:old.fec_desde,'DD/MM/YYYY')||' del empleado '||:old.cod_persona);
      END IF;
   END IF;
END;
/
