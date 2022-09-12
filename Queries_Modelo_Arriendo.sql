-- Indicar cuales arrendatarios sus arriendos vencen el próximo mes. 
Select  rutArrendatario, 
nombre, 
count(idPropiedad) CantArriendosVence, 
max(fechaFin) FecMaxVcto 
from Arrendatario atrio  
inner join Arriendos ards on atrio.idArrendatario = ards.idArrendatario 
where fechaFin > eomonth(getdate()) and fechaFin <= EOMONTH(DATEADD(Month, 1, getdate())) 
group by rutArrendatario, nombre 

-- Indicar cuales propietarios tienen al menos una propiedad sin arrendar. 
Select  
rutPropietario, 
nombre, 
count(idPropiedad)  
from Propietarios p 
inner join Arriendos a on p.idPropietarios = a.idPropietarios 
where idArrendatario is null or (fechaFin < getdate()) 
group by rutPropietario, nombre 

-- Indicar cuantas propiedades tiene cada propietario por cada país. 
Select  rutPropietario,  
nombre, 
país, 
count(idPropiedad) 
from Propietarios p 
inner join Propiedad pd on p.idPropietario = pd.IdPropietario 
group by rutPropietario, nombre, país 

-- Indicar cuales propietarios son también arrendatarios. 
Select  
a.rutArrendatario, 
a.nombre 
From Arrendatario a 
Inner join Propietarios p on a.rutArrendatario = p.rutPropietario 

--Indicar cuales arrendatarios arriendan fuera de chile. 
Select  
a.rutArrendatario, 
a.nombre, 
pa.Pais 
From Arrendatario a 
(select  
Ads.idArrendatario, 
p.idPropiedad, 
p.Pais 
From Arriendos ads inner join Propiedad p on ads.idPropiedad = p.idPropiedad) pa 
On a.idArrendatario = pa.idArrendatario 
Where pa.Pais <> ‘Chile’ 

-- Indicar cuales son los 3 países que el monto promedio de arriendo son los más altos. 
select top 3 
p.Pais 
AVG(ads.Monto) as Promedio 
From Arriendos ads inner join Propiedad p on ads.idPropiedad = p.idPropiedad 
Where ads.idArrendatario is not null 
Group by p.Pais 
Order by 2 desc 

-- Indicar el monto promedio, mínimo y máximo que pagan arrendatarios que también son propietarios. 

Select  
AVG(ads.monto) as PromArriendo, 
Min(ads.Monto) as MinArriendo, 
Max(ads.Monto) as MaxArriendo, 
From Arriendos ads inner join  
(Select  
a.idArrendatario 
a.rutArrendatario, 
a.nombre 
From Arrendatario a 
Inner join Propietarios p on a.rutArrendatario = p.rutPropietario 
) apr on ads.idArrendatario = apr.idArrendatario 
Where ads.idArrendatario is not null 