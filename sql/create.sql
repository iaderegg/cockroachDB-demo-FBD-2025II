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
