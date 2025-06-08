------------------- Criação de Tabelas --------------------
-- Tipos personalizados
CREATE TYPE eixos_enum AS ENUM ('2', '4', '6', '8');

CREATE TYPE t_endereco AS (
    logradouro VARCHAR(100),
    numero VARCHAR(10),
    cidade VARCHAR(50),
    estado CHAR(2)
);

CREATE TABLE Cliente (
    CPF VARCHAR(11) PRIMARY KEY,
    Endereco t_endereco NOT NULL,
    Name VARCHAR(100) NOT NULL,
    Telefone VARCHAR[] NOT NULL
);

CREATE TABLE Financiamento (
    Numero SERIAL PRIMARY KEY,
    cpf_cliente VARCHAR(11) NOT NULL REFERENCES Cliente(CPF),
    data DATE NOT NULL,
    valor REAL NOT NULL,
    prazo INT NOT NULL
);

-- Tabela Veiculo (superclasse)
CREATE TABLE Veiculo (
    num_renavan INT PRIMARY KEY,
    valor REAL NOT NULL,
    marca VARCHAR(20) NOT NULL,
    ano INT NOT NULL,
    numero_financiamento INT REFERENCES Financiamento(Numero) 
);

-- Subclasses 
CREATE TABLE Passeio (
    qtd_passageiros SMALLINT NOT NULL
) INHERITS (Veiculo);

CREATE TABLE Carga (
    carga_maxima INT NOT NULL,
    numero_eixos eixos_enum NOT NULL
) INHERITS (Veiculo);


------------------- Inserção de 10 registros --------------------

INSERT INTO Cliente (CPF, Endereco, Name, Telefone) VALUES
('11122233344', ROW('Rua A', '100', 'São Paulo', 'SP'), 'João', ARRAY['11999998888']),
('22233344455', ROW('Rua B', '200', 'Rio de Janeiro', 'RJ'), 'Maria', ARRAY['21988887777']),
('33344455566', ROW('Rua C', '300', 'Belo Horizonte', 'MG'), 'Carlos', ARRAY['31977776666']),
('44455566677', ROW('Rua D', '400', 'Porto Alegre', 'RS'), 'Ana', ARRAY['51966665555']),
('55566677788', ROW('Rua E', '500', 'Salvador', 'BA'), 'Pedro', ARRAY['71955554444']),
('66677788899', ROW('Rua F', '600', 'Recife', 'PE'), 'Juliana', ARRAY['81944443333']),
('77788899900', ROW('Rua G', '700', 'Fortaleza', 'CE'), 'Fernando', ARRAY['85933332222']),
('88899900011', ROW('Rua H', '800', 'Curitiba', 'PR'), 'Amanda', ARRAY['41922221111']),
('99900011122', ROW('Rua I', '900', 'Brasília', 'DF'), 'Ricardo', ARRAY['61911110000']),
('00011122233', ROW('Rua J', '1000', 'Manaus', 'AM'), 'Patrícia', ARRAY['92900009999']);

INSERT INTO Passeio (num_renavan, valor, marca, ano, qtd_passageiros) VALUES
(1001, 85000.0, 'Fiat', 2025, 5),
(1002, 120000.0, 'Volkswagen', 2025, 5),
(1003, 95000.0, 'Ford', 2025, 5),
(1004, 110000.0, 'Chevrolet', 2025, 5),
(1005, 130000.0, 'Hyundai', 2025, 5),
(1006, 140000.0, 'Toyota', 2025, 5),
(1007, 75000.0, 'Renault', 2025, 5),
(1008, 160000.0, 'Honda', 2025, 5),
(1009, 90000.0, 'Nissan', 2025, 5),
(1010, 170000.0, 'BMW', 2025, 5);

INSERT INTO Carga (num_renavan, valor, marca, ano, carga_maxima, numero_eixos) VALUES
(2001, 180000.0, 'Volvo', 2025, 5000, '6'),
(2002, 220000.0, 'Mercedes', 2025, 8000, '8'),
(2003, 150000.0, 'Scania', 2025, 4000, '4'),
(2004, 190000.0, 'MAN', 2025, 6000, '6'),
(2005, 280000.0, 'DAF', 2025, 10000, '8'),
(2006, 210000.0, 'Iveco', 2025, 7000, '6'),
(2007, 240000.0, 'Kenworth', 2025, 9000, '8'),
(2008, 170000.0, 'Volkswagen', 2025, 4500, '4'),
(2009, 200000.0, 'Ford', 2025, 6500, '6'),
(2010, 260000.0, 'Peterbilt', 2025, 11000, '8');


SELECT * FROM Cliente;
SELECT * FROM Veiculo; 
SELECT * FROM Financiamento;
SELECT * FROM Passeio;
SELECT * FROM Carga;

------------------- Função realizaFinanciamento --------------------
CREATE OR REPLACE FUNCTION realizaFinanciamento(
    f_cpf_cliente VARCHAR(11),
    f_valor REAL,
    f_data_financiamento DATE,
    f_prazo INT,
    f_renavam INT
) RETURNS VOID AS $$
DECLARE
    novo_numero INT;
BEGIN
    INSERT INTO Financiamento (cpf_cliente, data, valor, prazo)
    VALUES (f_cpf_cliente, f_data_financiamento, f_valor, f_prazo)
    RETURNING Numero INTO novo_numero;

    UPDATE Veiculo
    SET numero_financiamento = novo_numero
    WHERE num_renavan = f_renavam;
END;
$$ LANGUAGE plpgsql;

------------------- Realizar um financiamento para o veículo de passeio e um para um veículo de carga --------------------
-- Passeio
SELECT realizaFinanciamento('11122233344', 80000.0, '2025-01-15', 36, 1001);
-- Carga
SELECT realizaFinanciamento('22233344455', 200000.0, '2025-02-20', 48, 2001);

SELECT * FROM Financiamento ORDER BY numero DESC LIMIT 2;

------------------- Remodelar a tabela Cliente com Financiamento como dado complexo--------------------
DROP TABLE IF EXISTS Financiamento CASCADE;
DROP TABLE IF EXISTS Cliente CASCADE;

CREATE TYPE t_financiamento AS (
    data DATE,
    valor REAL,
    prazo INT
);

CREATE TABLE Cliente (
    CPF VARCHAR(11) PRIMARY KEY,
    Endereco t_endereco NOT NULL,
    Name VARCHAR(100) NOT NULL,
    Telefone VARCHAR[] NOT NULL,
    Financiamentos t_financiamento[] 
);

---------------------------------------
-- a) Inserir 2 financiamentos para o cliente X
INSERT INTO Cliente (CPF, Endereco, Name, Telefone, Financiamentos)
VALUES (
    '12345678900',
    ROW('Rua Exemplo', '123', 'Cidade', 'SP'),
    'Cliente X',
    ARRAY['11999990000'],
    ARRAY[
        ROW('2025-01-10', 10000.0, 12)::t_financiamento,
        ROW('2025-03-15', 15000.0, 24)::t_financiamento
    ]
);

SELECT * FROM Cliente WHERE CPF = '12345678900';

-- b) Remover o primeiro financiamento do cliente X
UPDATE Cliente
SET Financiamentos = ARRAY_REMOVE(Financiamentos, Financiamentos[1])
WHERE CPF = '12345678900';

SELECT * FROM Cliente WHERE CPF = '12345678900';

-- C) Inserir um novo financiamento para o cliente X
UPDATE Cliente
SET Financiamentos = Financiamentos || ROW('2025-06-01', 20000.0, 36)::t_financiamento
WHERE CPF = '12345678900';

SELECT * FROM Cliente WHERE CPF = '12345678900';

-- d) Atualizar o valor do primeiro financiamento do cliente X em menos 30%
UPDATE Cliente
SET Financiamentos[1] = ROW(
    Financiamentos[1].data,
    Financiamentos[1].valor * 0.7,
    Financiamentos[1].prazo
)::t_financiamento
WHERE CPF = '12345678900';

SELECT * FROM Cliente WHERE CPF = '12345678900';

-- e) Inserir um financiamento para o cliente Y
INSERT INTO Cliente (CPF, Endereco, Name, Telefone, Financiamentos)
VALUES (
    '98765432100',
    ROW('Rua Y', '456', 'Outra Cidade', 'RJ'),
    'Cliente Y',
    ARRAY['21988887777'],
    ARRAY[
        ROW('2025-05-20', 18000.0, 18)::t_financiamento
    ]
);

SELECT * FROM Cliente WHERE CPF = '98765432100';

-- F) Verificar entre os financiamentos X e Y qual o maior valor
SELECT MAX(f.valor) AS maior_valor
FROM Cliente c,
UNNEST(c.Financiamentos) AS f
WHERE c.CPF IN ('12345678900', '98765432100');


-- g) Menor prazo entre os financiamentos X e Y
SELECT MIN(f.prazo) AS menor_prazo
FROM Cliente c,
UNNEST(c.Financiamentos) AS f
WHERE c.CPF IN ('12345678900', '98765432100');
