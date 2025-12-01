SELECT pais, count(*), avg(saldo)
FROM cuentas
GROUP BY pais;

SELECT date_trunc('hour', fecha) AS hora,
       sum(monto) AS total_movimientos
FROM movimientos
GROUP BY hora
ORDER BY hora DESC
LIMIT 10;


-- Forzar transaccion larga
BEGIN;

UPDATE cuentas
SET saldo = saldo - 100
WHERE pais = 'CO';

SELECT now();

COMMIT;


-- Crear rangos
ALTER TABLE banco.cuentas SPLIT AT VALUES (200000::INT8);
ALTER TABLE banco.cuentas SPLIT AT VALUES (400000::INT8);
ALTER TABLE banco.cuentas SPLIT AT VALUES (600000::INT8);
ALTER TABLE banco.cuentas SPLIT AT VALUES (800000::INT8);

-- Ver rangos
SHOW RANGES FROM TABLE banco.cuentas;
