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