# pgsql-scripts

Hoy quiero compartir mi experiencia en la optimización de costos de infraestructura mediante la ejecución de PostgreSQL en una máquina virtual, junto con algunos scripts útiles para backup y restauración.
Ejecutar PostgreSQL en una VM con Linux es relativamente sencillo, eligen una distro ligera, instalación de PostgreSQL, configuración para conexiones remotas y apertura del puerto necesario. (Si usan algun dominio, configuran los DNS)
Para backups, he implementado una solución utilizando pg_basebackup, que ofrece ventajas sobre pg_dump:

• Mayor velocidad en bases de datos grandes

• Soporte para recuperación a un punto en el tiempo (PITR)

• Facilita la replicación y alta disponibilidad


He desarrollado dos scripts principales:

𝐒𝐜𝐫𝐢𝐩𝐭 𝐝𝐞 𝐛𝐚𝐜𝐤𝐮𝐩: 

• Verifica la configuración de WAL archiving 

• Realiza un backup completo del cluster PostgreSQL 

• Genera un archivo de metadatos 

• Limpia backups y archivos WAL antiguos

𝐒𝐜𝐫𝐢𝐩𝐭 𝐝𝐞 𝐫𝐞𝐬𝐭𝐚𝐮𝐫𝐚𝐜𝐢ó𝐧: 

• Localiza el backup más reciente 

• Restaura el backup base 

• Configura el proceso de recuperación 

• Inicia PostgreSQL y monitorea la recuperación

𝐂𝐨𝐦𝐩𝐚𝐫𝐚𝐭𝐢𝐯𝐚 𝐝𝐞 𝐜𝐨𝐬𝐭𝐨𝐬: 𝐕𝐌 𝐯𝐬 𝐀𝐖𝐒 𝐑𝐃𝐒

• VM dedicada (Contabo o GoDaddy): • 6 vCPUs, 16 GB RAM, 400 GB SSD • 𝐏𝐫𝐞𝐜𝐢𝐨: $25.99/𝐦𝐞𝐬
• AWS RDS (db.m5.xlarge): • 4 vCPUs, 16 GB RAM, 500 GB gp2 • Precio On-Demand: 𝐀𝐩𝐫𝐨𝐱. $398/𝐦𝐞𝐬

𝐀𝐡𝐨𝐫𝐫𝐨 𝐩𝐨𝐭𝐞𝐧𝐜𝐢𝐚𝐥: $372.01/𝐦𝐞𝐬 𝐔𝐒𝐃 (93.5% 𝐦𝐞𝐧𝐨𝐬)

Una opcion tambien, es conseguir un IP fijo y comprar un equipo para tenerlo on-premise. (Tene en cuenta que vas a tener que ponerle UPS por posibles cortes de luz)

𝐂𝐨𝐧𝐬𝐢𝐝𝐞𝐫𝐚𝐜𝐢𝐨𝐧𝐞𝐬:

•Con una VM, toda la administración, monitoreo, escalabilidad y demas es responsabilidad del usuario.

•La elección depende de tus necesidades específicas, producto con el cual estes trabajando y habilidades técnicas.


Subi estos scripts a un repositorio público en GitHub para quienes estén interesados en implementarlos o adaptarlos a sus necesidades.


Tengan en cuenta, deben modificar pg_hba.conf y postgresql.conf para habilitar la conexion, permitir replicas, configurar WAL y demas.
