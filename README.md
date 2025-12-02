# 📘 Demo de NewSQL con CockroachDB

Este demo muestra los principios fundamentales de NewSQL, utilizando CockroachDB en modo local con un clúster simulado. El objetivo es entender:

- Cómo opera un sistema distribuido shared-nothing.
- Cómo se particiona una tabla en shards (rangos),
- Cómo funcionan las réplicas y los leaseholders,
- Cómo se comporta una base de datos transaccional ACID bajo distribución,
- y cómo ejecutar consultas analíticas y transaccionales sobre datos distribuidos.

Incluye:

- creación del esquema,
- generación de datos sintéticos (1M de filas),
  ejecución de consultas,
- partición manual del espacio de claves,
- visualización de rangos distribuidos entre los nodos.

## 1. Requisitos previos

- CockroachDB instalado localmente
  https://www.cockroachlabs.com/docs/stable/install-cockroachdb.html
- Terminal (Linux, macOS o WSL)
- Git (opcional, para clonar el repo)

## 2. Iniciar el clúster con cockroach demo

Ejecuta:

```bash
cockroach demo --nodes=3 --no-example-database
```

Esto levanta un clúster distribuido simulado con:

- 3 nodos
- almacenamiento en memoria
- interfaz web en:
  http://127.0.0.1:8080

Al abrir la UI podrás ver nodos, réplicas y distribución interna.

## 3. Crear la base de datos y las tablas

Ejecuta el archivo schema.sql completo:

```sql
CREATE DATABASE banco;
USE banco;

CREATE TABLE cuentas (
    id          SERIAL PRIMARY KEY,
    cliente     STRING NOT NULL,
    saldo       DECIMAL NOT NULL,
    pais        STRING NOT NULL,
    ciudad      STRING NOT NULL
);

CREATE TABLE movimientos (
    id              SERIAL PRIMARY KEY,
    cuenta_origen   INT NOT NULL REFERENCES cuentas(id),
    cuenta_destino  INT NOT NULL REFERENCES cuentas(id),
    monto           DECIMAL NOT NULL,
    fecha           TIMESTAMP NOT NULL DEFAULT now()
);
```

## 4. Generar datos sintéticos

Ejecuta `syntheticData.sql`:

```sql
INSERT INTO cuentas (cliente, saldo, pais, ciudad)
SELECT
    'Cliente ' || generate_series,
    (random() * 10000)::DECIMAL,
    (ARRAY['CO','MX','AR','US','ES'])[(floor(random()*5)::INT) + 1],
    (ARRAY['Bogotá','Cali','Medellín','CDMX','Madrid','NY'])[(floor(random()*6)::INT) + 1]
FROM generate_series(1, 1000000);

INSERT INTO movimientos (cuenta_origen, cuenta_destino, monto)
SELECT
    (SELECT id FROM cuentas ORDER BY random() LIMIT 1),
    (SELECT id FROM cuentas ORDER BY random() LIMIT 1),
    (random() * 500)::DECIMAL
FROM generate_series(1, 5000);
```

> Nota:
> Usamos subconsultas para cuenta_origen y cuenta_destino porque los IDs generados por SERIAL en CockroachDB no son secuenciales clásicos.

## Consultas analíticas de ejemplo

Estas consultas están en `queries.sql`:

### Distribución por país

```sql
SELECT pais, count(*), avg(saldo)
FROM cuentas
GROUP BY pais;

```

### Actividad agregada por hora

```sql
SELECT date_trunc('hour', fecha) AS hora,
       sum(monto) AS total_movimientos
FROM movimientos
GROUP BY hora
ORDER BY hora DESC
LIMIT 10;
```

### Forzar una transacción larga

```sql
BEGIN;

UPDATE cuentas
SET saldo = saldo - 100
WHERE pais = 'CO';

SELECT now();

COMMIT;
```

### Crear paticiones (rangos/shard)

```sql
ALTER TABLE banco.cuentas SPLIT AT VALUES (200000::INT8);
ALTER TABLE banco.cuentas SPLIT AT VALUES (400000::INT8);
ALTER TABLE banco.cuentas SPLIT AT VALUES (600000::INT8);
ALTER TABLE banco.cuentas SPLIT AT VALUES (800000::INT8);
```

### Ver cómo quedó la tabla

```sql
SHOW RANGES FROM TABLE banco.cuentas;
```

## Qué no permite `cockroach demo`

- No puedes “matar un nodo” individualmente.
- Todos los nodos corren dentro de un solo proceso.
- No puedes realojar rangos manualmente con ALTER RANGE RELOCATE.
- No recrea condiciones reales de disco ni WAL.

> Para demostración real de fallos → usar Docker o 3 procesos separados.
