-- Top de empresas que sus trabajadores presentan más licencias. 
select top 5 rutEmpresa, count(distinct idLicencia) Cant_Licencias
from Licencia l
inner join Trabajador t on l.idtrabajador = t.idTrabajador
inner join Empresa e on e.idEmpresa = t.idEmpresa
order by 2 desc

/* Las sucursales que reciben más documentación, segmentados por región o comuna, 
 así como sucursales que no están aptas para recibir documentación. */

 select nombreSucursal
 , nomRegion
 , nomComuna
 , case when aptaRecepcion = 1 then 'Apta para Recibir Documentos' else 'No Apta para Recibir Documentos' end as aptaRecepcion
 , count(idDoc) Cantidad_Documentos
 from GestionDocumentos gd 
 right join Sucursales s on gd.idSucursal = s.idSucursal
 inner join Region r on r.idRegion = s.idRegion
 inner join Comuna c on c.idComuna = s.idComuna
 group by nombreSucursal
 , nomRegion
 , nomComuna
 , case when aptaRecepcion = 1 then 'Apta para Recibir Documentos' else 'No Apta para Recibir Documentos' end
 order by 5 desc

 -- Top de documentos que hacen que la licencia reinicie su flujo. 
 select top 5 d.documento, count(distinct l.idLicencia) Cant_licencias
 from Licencia l 
 inner join GestionDocumentos gd on l.idLicencia = gd.idLicencia
 inner join  DocumentoRequerido d on d.idDocReq = gd.idDocReq
 inner join EstadoLicencia el on el.idEstado = l.idEstado
 where el.Estado = 'Pendiente Pago' and gd.ultEstadoDoc in ('Rechazado', 'Faltante')
 group by d.documento
 order by 2 descñ

 /* Tiempos promedios, mínimos y máximos, 
 desde el inicio del proceso hasta el cálculo del monto a pagar por cada licencia */

select 
, min(datediff(DAY,fecPresentacion, fecEstado))
, max(datediff(DAY,fecPresentacion, fecEstado))
, avg(datediff(DAY,fecPresentacion, fecEstado))
from Licencias l 
inner join EstadoLicencia el on l.idEstado = el.idEstado
where el.Estado = 'CalculoPago'

 -- Estadísticas de licencias manuales vs electrónicas vs mixtas 
 -- Min, max, promedios, y totales por periodo de licencias por Tipo de licencias de los ultimos 3 meses
 select tipoLicencia,
 concat(year(fecPresentacion),Month(fecPresentacion)) as Periodo,
 min(Cant_Licencias) Min_Periodo,
 avg(Cant_Licencias) Max_Periodo,
 max(Cant_Licencias) Avg_Periodo,
 sum(Cant_Licencias) Total_Periodo
 from (
        select 
        tipoLicencia,
        fecPresentacion,
        count(distinct idLicencia) Cant_Licencias
        from Licencia l 
        inner join TipoLicencia tl on l.idTipoLicencia = tl.idTipoLicencia
        where fecPresentacion > EOMONTH(DATEADD,-3,fecPresentacion) and fecPresentacion <= EOMONTH(fecPresentacion)
        group by tipoLicencia, fecPresentacion
 ) con  
 group by tipoLicencia, 
 concat(year(fecPresentacion),Month(fecPresentacion))

/*  Los estados del proceso que almacenan la mayor 
cantidad de licencias así como los cambios de estado que tardan más tiempo en ser modificados 
Para este ejercicio he definido 6 estados de la licencia 
1. Recibido: Cuando el cliente intruduce la licencia
2. Resolución: Cuando la licencia es resuelta por contraloría (esto lo saque de mi isapre)
3. Pendiente de Pago: Cuando falta algun documento para hacer la evaluación de pago
4. Evaluación de Pago: Cuando inicia al proceso de calculo
5. Calculo Pago: Cuando se obtiene el valor del calculo
6. Pago: Cuando se realiza el pago al cliente
7. Cancelada: Cuando por alguna razon el cliente pasa mas de x tiempo en Pendiente de Pago se cancela la licencia
*/

select 
    concat(year(fecPresentacion),Month(fecPresentacion)) as Periodo,
    avg(Dias_Pres_Lic) Tiempo_Presentacion_Licencia,
    avg(Dias_Res_Lic) Tiempo_Resolucion_Licencia, 
    avg(Dias_PenPago_Lic) Tiempo_PendientePago_Licencia,
    avg(Dias_EvalPago_Lic) Tiempo_Evaluacion_Licencia,
    avg(Dias_CalPago_Lic) Tiempo_Calculo_Licencia,
    avg(Dias_Pago_Lic) Tiempo_Pago_Licencia
from (
        select 
            idLicencia,
            fecPresentacion,
            datediff(day,fecReposo, [1]) Dias_Pres_Lic,
            datediff(day,fecPresentacion, [2]) Dias_Res_Lic,
            isnull(datediff(day,[2], [3]),0) Dias_PenPago_Lic,
            datediff(day, [3],[4]) Dias_EvalPago_Lic,
            datediff(day,[4],[5]) Dias_CalPago_Lic,
            datediff(day,[5],[6]) Dias_Pago_Lic
        from Licencias l 
        inner join
        (select idLicencia,[1],[2],[3],[4],[5],[6]
        (select *
        from LicenciaEdo le
        where idEstado not in (1,7)) qry
        pivot (
            max(fecEstado)
            for idEstado in ([1],[2],[3],[4],[5],[6])
        ) pt
        ) Estados on l.idLicencia = Estados.idLicencia
) CDE
group by concat(year(fecPresentacion),Month(fecPresentacion))

-- Trabajadores que tienen licencia y son desafiliados 
-- Para este ejercicio se tomo los del mes en curso

select rutTrabajador, pNombre, pApell
from Licencias l 
inner join Trabajador t on l.idTrabajador = t.idTrabajador
where t.afiliado = 1 and (fecPresentacion > EOMONTH(DATEADD,-1,fecPresentacion) and fecPresentacion <= EOMONTH(fecPresentacion))

-- Manejo de data histórica, de validación de procesos y log’s de cambios de estado o actualización de data relevante. 

En este caso se puede desarrollar un trigger que registre los insert, update y delete de las tablas 
que cambian estados 

Para el caso de Trabajadores hay que contar con un maestro de direcciones, telefonos, emails porque son datos 
que cambian constantemente. Además de sus datos de AFP e Isapre o fonasa pueden cambiar, y tambien los datos 
de la empresa donde trabaja. Para estos hay que crear tablas que registren todos estos cambios y que a su vez 
te dejen el dato mas reciente (o con mejor calidad en la tabla principal de trabajadores)

Para el tema de afiliados y desafiliados (aunque no lo contemplé en el diagrama) es necesario contar 
con los datos actualizados de afiliación fecha inicio fecha fin para determinar los periodos en el que 
el trabajador estuvo afliliado


