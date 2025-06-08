------------------- Criação de Tabelas --------------------
-- Tipo ENUM para número de eixos
CREATE TYPE eixos_enum AS ENUM ('2', '4', '6', '8');

-- Tabela Cliente
CREATE TABLE Cliente (
    CPF VARCHAR(11) PRIMARY KEY,
    Endereço TEXT NOT NULL,
    Name VARCHAR(100) NOT NULL,
    Telefone VARCHAR[] NOT NULL
);

-- Tabela Veículo (superclasse)
CREATE TABLE Veículo (
    num_renavan INT PRIMARY KEY,
    valor REAL NOT NULL,
    marca VARCHAR(30) NOT NULL,
    ano INT NOT NULL
);

-- Sub-tabela para veículos de Passeio
CREATE TABLE Passeio (
    qtd_passageiros SMALLINT NOT NULL
) INHERITS (Veículo);

-- Sub-tabela para veículos de Carga
CREATE TABLE Carga (
    carga_maxima INT NOT NULL,
    numero_eixos eixos_enum NOT NULL
) INHERITS (Veículo);

-- Tabela Financiamento
CREATE TABLE Financiamento (
    Numero SERIAL PRIMARY KEY,
    cd_cliente VARCHAR(11) NOT NULL REFERENCES Cliente(CPF),
    data DATE NOT NULL,
    valor REAL NOT NULL,
    prazo INT NOT NULL
);

------------------- Inserção de 10 registros --------------------

INSERT INTO Cliente (CPF, Endereço, Name, Telefone) VALUES
('11122233344', 'Rua A, 100', 'João Silva', ARRAY['11999998888']),
('22233344455', 'Rua B, 200', 'Maria Oliveira', ARRAY['11988887777']),
('33344455566', 'Rua C, 300', 'Carlos Pereira', ARRAY['11977776666']),
('44455566677', 'Rua D, 400', 'Ana Costa', ARRAY['11966665555']),
('55566677788', 'Rua E, 500', 'Pedro Alves', ARRAY['11955554444']),
('66677788899', 'Rua F, 600', 'Juliana Mendes', ARRAY['11944443333']),
('77788899900', 'Rua G, 700', 'Fernando Souza', ARRAY['11933332222']),
('88899900011', 'Rua H, 800', 'Amanda Lima', ARRAY['11922221111']),
('99900011122', 'Rua I, 900', 'Ricardo Gomes', ARRAY['11911110000']),
('00011122233', 'Rua J, 1000', 'Patrícia Rocha', ARRAY['11900009999']);


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


INSERT INTO Financiamento (cd_cliente, data, valor, prazo) VALUES
('11122233344', '2025-01-15', 80000.0, 36),
('22233344455', '2025-02-20', 115000.0, 48),
('33344455566', '2025-03-10', 90000.0, 24),
('44455566677', '2025-04-05', 105000.0, 60),
('55566677788', '2025-05-12', 125000.0, 36),
('66677788899', '2024-06-18', 175000.0, 48),
('77788899900', '2024-07-22', 210000.0, 60),
('88899900011', '2024-08-30', 145000.0, 24),
('99900011122', '2024-09-05', 185000.0, 36),
('00011122233', '2024-10-11', 270000.0, 48);

SELECT * FROM Cliente;
SELECT * FROM Veículo; 
SELECT * FROM Financiamento;
SELECT * FROM Passeio;
SELECT * FROM Carga;

------------------- Função realizaFinanciamento --------------------
-- 1. Criar função base genérica
CREATE OR REPLACE FUNCTION realizaFinanciamento(
    cliente_cpf VARCHAR(11),
    data_fin DATE,
    valor_fin REAL,
    prazo_fin INT,
    veiculo Veículo
) RETURNS Financiamento AS $$
DECLARE
    financiamento_criado Financiamento;
BEGIN
    
    PERFORM 1 FROM Veículo WHERE num_renavan = veiculo.num_renavan;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Veículo com renavan não encontrado';
    END IF;
    
    -- Inserir financiamento
    INSERT INTO Financiamento (cd_cliente, data, valor, prazo)
    VALUES (cliente_cpf, data_fin, valor_fin, prazo_fin)
    RETURNING * INTO financiamento_criado;
    
    RETURN financiamento_criado;
END;
$$ LANGUAGE plpgsql;

-- 2. Função especializada para veículos de passeio
CREATE OR REPLACE FUNCTION realizaFinanciamento(
    cliente_cpf VARCHAR(11),
    data_fin DATE,
    valor_fin REAL,
    prazo_fin INT,
    veiculo Passeio
) RETURNS Financiamento AS $$
BEGIN
    -- Chamar função base com upcast para Veículo
    RETURN realizaFinanciamento(
        cliente_cpf, 
        data_fin, 
        valor_fin, 
        prazo_fin, 
        veiculo::Veículo
    );
END;
$$ LANGUAGE plpgsql;

-- 3. Função especializada para veículos de carga
CREATE OR REPLACE FUNCTION realizaFinanciamento(
    cliente_cpf VARCHAR(11),
    data_fin DATE,
    valor_fin REAL,
    prazo_fin INT,
    veiculo Carga
) RETURNS Financiamento AS $$
BEGIN
    -- Chamar função base com upcast para Veículo
    RETURN realizaFinanciamento(
        cliente_cpf, 
        data_fin, 
        valor_fin, 
        prazo_fin, 
        veiculo::Veículo
    );
END;
$$ LANGUAGE plpgsql;

------------------- Realizar um financiamento para o veículo de passeio e um para um veículo de carga --------------------
-- Selecionar veículo de passeio 
SELECT realizaFinanciamento(
    '11122233344',                
    '2025-11-01',                 
    90000.0,                       
    36,                            
    (SELECT p FROM Passeio p WHERE num_renavan = 1001)  
);

-- Selecionar veículo de carga 
SELECT realizaFinanciamento(
    '22233344455',                
    '2025-11-02',                 
    170000.0,                      
    48,                            
    (SELECT c FROM Carga c WHERE num_renavan = 2001)    
);

-- Verificar os financiamentos realizados
SELECT * FROM Financiamento ORDER BY numero DESC LIMIT 2;

------------------- Remodelar a tabela Cliente com Financiamento como dado complexo--------------------
-- 1. Criar tipo composto para Financiamento
CREATE TYPE FinanciamentoType AS (
    numero INT,
    data DATE,
    valor REAL,
    prazo INT
);

-- 2. Recriar tabela Cliente com financiamentos como array complexo
CREATE TABLE Cliente (
    CPF VARCHAR(11) PRIMARY KEY,
    Endereço TEXT NOT NULL,
    Name VARCHAR(100) NOT NULL,
    Telefone VARCHAR[] NOT NULL,
    Financiamentos FinanciamentoType[] -- Relacionamento 1:N como dado complexo
);

-- 3. Remover tabela Financiamento original 
DROP TABLE IF EXISTS Financiamento;
