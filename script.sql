/* ENUNCIADO 1
No pgAdmin, crie o banco de dados cafe_dw com codificação UTF8 (registre essa etapa
como comentário no script). Na Query Tool desse banco, crie os schemas raw, staging e
dw, usando IF NOT EXISTS, e escreva uma consulta a information_schema.schemata que
devolva exatamente essas três linhas.*/
 
-- CREATE DATABASE cafe_dw
--     WITH
--     OWNER = postgres
--     ENCODING = 'UTF8'
--     LOCALE_PROVIDER = 'libc'
--     CONNECTION LIMIT = -1
--     IS_TEMPLATE = False;
CREATE SCHEMA IF NOT EXISTS raw;
CREATE SCHEMA IF NOT EXISTS staging;
CREATE SCHEMA IF NOT EXISTS dw;

SELECT schema_name
FROM information_schema.schemata;

/*Enunciado 2
Crie a tabela raw.cafe_sales com as oito colunas da Tabela 1, todas do tipo TEXT, sem
nenhuma restrição e na mesma ordem do arquivo CSV. Inicie o bloco com DROP TABLE IF
EXISTS ... CASCADE.*/
DROP TABLE IF EXISTS raw.cafe_sales CASCADE;
CREATE TABLE raw.cafe_sales(
	transaction_id TEXT,
	item TEXT,
	quantity TEXT,
	price_per_unit TEXT,
	total_spent TEXT,
	payment_method TEXT,
	location TEXT,
	transaction_date TEXT
)

/* ENUNCIADO 3
Importe dirty_cafe_sales.csv para raw.cafe_sales com Import/Export Data… do
pgAdmin (Format csv, Encoding UTF8, Header ligado, Delimiter vírgula). Registre em
comentário as opções usadas e escreva duas consultas de validação: o total de linhas (10.000
esperadas) e o total de valores distintos de transaction_id.*/

-- Consulta de total de linhas (retorna 10000)
SELECT * FROM raw.cafe_sales;

-- Consulta valores distintos de transaction_id
SELECT COUNT(DISTINCT transaction_id) FROM raw.cafe_sales;

/*Enunciado 4 
Para cada uma das colunas item, payment_method e location da camada raw, escreva uma
consulta que liste cada valor distinto e a quantidade de linhas em que ele aparece, da maior
para a menor quantidade. Os valores NULL também devem aparecer.*/

-- Consulta item
SELECT item as valor, 
    COUNT(*) AS quantidade
FROM raw.cafe_sales
GROUP BY item
ORDER BY quantidade DESC, valor;
-- Consulta payment_method
SELECT payment_method, 
    COUNT(*) AS quantidade
FROM raw.cafe_sales
GROUP BY payment_method
ORDER BY quantidade DESC;

-- Consulta location
SELECT location, 
    COUNT(*) AS quantidade
FROM raw.cafe_sales
GROUP BY location
ORDER BY quantidade DESC;

/* ENUNCIADO 5
Escreva uma única consulta, usando UNION ALL, que devolva uma linha para cada coluna
da camada raw, exceto transaction_id, com quatro colunas: coluna (o nome da coluna,
como texto), qtd_error, qtd_unknown e qtd_vazio (valor NULL ou texto vazio após TRIM).
O resultado terá sete linhas.*/
SELECT
    'item' AS coluna,
    COUNT(*) FILTER (WHERE TRIM(item) = 'ERROR') AS qtd_error,
    COUNT(*) FILTER (WHERE TRIM(item) = 'UNKNOWN') AS qtd_unknown,
    COUNT(*) FILTER (WHERE item IS NULL OR TRIM(item) = '') AS qtd_vazio
FROM raw.cafe_sales

UNION ALL

SELECT
    'quantity' AS coluna,
    COUNT(*) FILTER (WHERE TRIM(quantity) = 'ERROR') AS qtd_error,
    COUNT(*) FILTER (WHERE TRIM(quantity) = 'UNKNOWN') AS qtd_unknown,
    COUNT(*) FILTER (WHERE quantity IS NULL OR TRIM(quantity) = '') AS qtd_vazio
FROM raw.cafe_sales

UNION ALL

SELECT
    'price_per_unit' AS coluna,
    COUNT(*) FILTER (WHERE TRIM(price_per_unit) = 'ERROR') AS qtd_error,
    COUNT(*) FILTER (WHERE TRIM(price_per_unit) = 'UNKNOWN') AS qtd_unknown,
    COUNT(*) FILTER (WHERE price_per_unit IS NULL OR TRIM(price_per_unit) = '') AS qtd_vazio
FROM raw.cafe_sales

UNION ALL

SELECT
    'total_spent' AS coluna,
    COUNT(*) FILTER (WHERE TRIM(total_spent) = 'ERROR') AS qtd_error,
    COUNT(*) FILTER (WHERE TRIM(total_spent) = 'UNKNOWN') AS qtd_unknown,
    COUNT(*) FILTER (WHERE total_spent IS NULL OR TRIM(total_spent) = '') AS qtd_vazio
FROM raw.cafe_sales

UNION ALL

SELECT
    'payment_method' AS coluna,
    COUNT(*) FILTER (WHERE TRIM(payment_method) = 'ERROR') AS qtd_error,
    COUNT(*) FILTER (WHERE TRIM(payment_method) = 'UNKNOWN') AS qtd_unknown,
    COUNT(*) FILTER (WHERE payment_method IS NULL OR TRIM(payment_method) = '') AS qtd_vazio
FROM raw.cafe_sales

UNION ALL

SELECT
    'location' AS coluna,
    COUNT(*) FILTER (WHERE TRIM(location) = 'ERROR') AS qtd_error,
    COUNT(*) FILTER (WHERE TRIM(location) = 'UNKNOWN') AS qtd_unknown,
    COUNT(*) FILTER (WHERE location IS NULL OR TRIM(location) = '') AS qtd_vazio
FROM raw.cafe_sales

UNION ALL

SELECT
    'transaction_date' AS coluna,
    COUNT(*) FILTER (WHERE TRIM(transaction_date) = 'ERROR') AS qtd_error,
    COUNT(*) FILTER (WHERE TRIM(transaction_date) = 'UNKNOWN') AS qtd_unknown,
    COUNT(*) FILTER (WHERE transaction_date IS NULL OR TRIM(transaction_date) = '') AS qtd_vazio
FROM raw.cafe_sales;

/* ENUNCIADO 6
Crie staging.cafe_tipada conforme a Tabela 6 e carregue-a a partir de raw.cafe_sales
com um único INSERT ... SELECT, precedido de TRUNCATE. Em todas as colunas, aplique
TRIM e transforme '', 'ERROR' e 'UNKNOWN' em NULL antes de qualquer conversão; converta
as colunas numéricas com CAST e a data com TO_DATE no formato 'YYYY-MM-DD'. Em seguida,
escreva uma consulta que conte os NULL de cada coluna da tabela tipada. Para cada coluna,
o total deve ser igual à soma qtd_error + qtd_unknown + qtd_vazio obtida no Enunciado
5.*/

 DROP TABLE IF EXISTS staging.cafe_tipada CASCADE;
CREATE TABLE staging.cafe_tipada(
	transaction_id VARCHAR (20) PRIMARY KEY,
	item VARCHAR(20),
	quantity INTEGER,
	price_per_unit NUMERIC(6,2),
	total_spent NUMERIC(8,2),
	payment_method VARCHAR(20),
	location VARCHAR (20),
	transaction_date DATE
);

SELECT * FROM staging.cafe_tipada;
INSERT INTO staging.cafe_tipada
SELECT
	CASE WHEN UPPER(TRIM(transaction_id)) IN ('', 'ERROR', 'UNKNOWN') THEN NULL ELSE TRIM(transaction_id) END,
	CASE WHEN UPPER(TRIM(item)) IN ('', 'ERROR', 'UNKNOWN') THEN NULL ELSE TRIM(item) END,
	CAST(CASE WHEN UPPER(TRIM(quantity)) IN ('', 'ERROR', 'UNKNOWN') THEN NULL ELSE TRIM(quantity) END AS INTEGER),
	CAST(CASE WHEN UPPER(TRIM(price_per_unit)) IN ('', 'ERROR', 'UNKNOWN') THEN NULL ELSE TRIM(price_per_unit) END AS NUMERIC(6,2)),
	CAST(CASE WHEN UPPER(TRIM(total_spent)) IN ('', 'ERROR', 'UNKNOWN') THEN NULL ELSE TRIM(total_spent) END AS NUMERIC(8,2)),
	CASE WHEN UPPER(TRIM(payment_method)) IN ('', 'ERROR', 'UNKNOWN') THEN NULL ELSE TRIM(payment_method) END,
	CASE WHEN UPPER(TRIM(location)) IN ('', 'ERROR', 'UNKNOWN') THEN NULL ELSE TRIM(location) END,
	TO_DATE(CASE WHEN UPPER(TRIM(transaction_date)) IN ('', 'ERROR', 'UNKNOWN') THEN NULL ELSE TRIM(transaction_date) END, 'YYYY-MM-DD')
FROM raw.cafe_sales;

SELECT 'transaction_id' AS coluna, 
    COUNT(*) - COUNT(transaction_id) AS qtd_null FROM staging.cafe_tipada;

SELECT 'item',
    COUNT(*) - COUNT(item) FROM staging.cafe_tipada;

SELECT 'quantity',
    COUNT(*) - COUNT(quantity) FROM staging.cafe_tipada;

SELECT 'price_per_unit',
    COUNT(*) - COUNT(price_per_unit) FROM staging.cafe_tipada;

SELECT 'total_spent',
    COUNT(*) - COUNT(total_spent) FROM staging.cafe_tipada;

SELECT 'payment_method',
    COUNT(*) - COUNT(payment_method) FROM staging.cafe_tipada;

SELECT 'location',
    COUNT(*) - COUNT(location) FROM staging.cafe_tipada;

SELECT 'transaction_date',
    COUNT(*) - COUNT(transaction_date) FROM staging.cafe_tipada;

/*ENUNCIADO 7
Crie a tabela staging.cardapio com as colunas item (VARCHAR(20), chave primária), price
(NUMERIC(6,2) NOT NULL) e category (VARCHAR(10) NOT NULL) e insira nela as oito linhas
da Tabela 3.*/

DROP TABLE IF EXISTS staging.cardapio;
CREATE TABLE staging.cardapio(
	item VARCHAR(20) PRIMARY KEY,
	price NUMERIC(6,2) NOT NULL,
	category VARCHAR(10) NOT NULL
);

INSERT INTO staging.cardapio (item, price, category)
SELECT
    item,
    MAX(price_per_unit) AS price,
    CASE
        WHEN item IN ('Cookie', 'Cake', 'Sandwich', 'Salad') THEN 'Comida'
        WHEN item IN ('Tea', 'Coffee', 'Juice', 'Smoothie')  THEN 'Bebida'
    END AS category
FROM staging.cafe_tipada
WHERE item IS NOT NULL
  AND price_per_unit IS NOT NULL
GROUP BY item;

SELECT * FROM staging.cardapio;

/* ENUNCIADO 8
Aplique à tabela staging.cafe_tipada as regras da Tabela 7, na ordem indicada, com
um UPDATE por regra (a R6 pode usar dois). Use subconsultas sobre staging.cardapio
nas regras R1 e R5. Abaixo de cada UPDATE, registre em comentário a quantidade de linhas
afetadas informada pelo pgAdmin.*/

-- R1: preço nulo e item conhecido -> preço do item no cardápio
UPDATE staging.cafe_tipada t
SET    price_per_unit = (
    SELECT c.price
        FROM   staging.cardapio c
        WHERE  c.item = t.item)
WHERE  t.price_per_unit IS NULL
    AND  t.item IN (SELECT item FROM staging.cardapio);
-- Linhas afetadas: 479

-- R2: preço nulo, quantidade e total conhecidos -> total / quantidade
UPDATE staging.cafe_tipada
SET price_per_unit = ROUND(total_spent / quantity, 2)
WHERE price_per_unit IS NULL
    AND quantity IS NOT NULL
    AND quantity != 0
    AND total_spent IS NOT NULL;
-- Linhas afetadas: 48

-- R3: quantidade nula, preço e total conhecidos -> total / preço, arredondado para inteiro
UPDATE staging.cafe_tipada
SET quantity = CAST(ROUND(total_spent / price_per_unit) AS INTEGER)
WHERE quantity IS NULL
    AND price_per_unit IS NOT NULL
    AND price_per_unit != 0
    AND total_spent IS NOT NULL;
-- Linhas afetadas: 456

-- R4: total nulo, quantidade e preço conhecidos -> quantidade x preço
UPDATE staging.cafe_tipada
SET    total_spent = quantity * price_per_unit
WHERE  total_spent IS NULL
    AND  quantity IS NOT NULL
    AND  price_per_unit IS NOT NULL;
-- Linhas afetadas: 479

-- R5: item nulo e preço conhecido, pertencente a um único item do cardápio -> item com aquele preço
UPDATE staging.cafe_tipada t
SET    item = (SELECT c.item
        FROM   staging.cardapio c
        WHERE  c.price = t.price_per_unit)
WHERE  t.item IS NULL
    AND  t.price_per_unit IS NOT NULL
    AND  (SELECT COUNT(*)
        FROM   staging.cardapio c
        WHERE  c.price = t.price_per_unit) = 1;
-- Linhas afetadas: 489
-- R6 (1/2): forma de pagamento nula -> 'Unknown'
UPDATE staging.cafe_tipada
SET    payment_method = 'Unknown'
WHERE  payment_method IS NULL;
-- Linhas afetadas: 3178

-- R6 (2/2): local nulo -> 'Unknown'
UPDATE staging.cafe_tipada
SET    location = 'Unknown'
WHERE  location IS NULL;
-- Linhas afetadas: 3961

/* ENUNCIADO 9
Crie staging.cafe_sales com as mesmas colunas e tipos da Tabela 6, agora com NOT NULL
em todas elas e com as restrições CHECK (quantity > 0) e CHECK (price_per_unit > 0).
Carregue-a, precedida de TRUNCATE, apenas com as linhas de staging.cafe_tipada que
não têm nenhum valor nulo. Escreva então uma consulta que devolva, em uma única linha,
três colunas: linhas_tipada, linhas_limpas e descartadas. Registre os três números em
comentário.
*/

-- 1) Tabela limpa
DROP TABLE IF EXISTS staging.cafe_sales CASCADE;
CREATE TABLE staging.cafe_sales(
	transaction_id VARCHAR (20) PRIMARY KEY,
	item VARCHAR(20) NOT NULL,
	quantity INTEGER CHECK (quantity > 0) NOT NULL,
	price_per_unit NUMERIC(6,2) CHECK (price_per_unit > 0) NOT NULL,
	total_spent NUMERIC(8,2) NOT NULL,
	payment_method VARCHAR(20) NOT NULL,
	location VARCHAR (20) NOT NULL,
	transaction_date DATE NOT NULL
);

-- 2) TRUNCATE staging.cafe_sales
TRUNCATE TABLE staging.cafe_sales;

-- 3) INSERT
INSERT INTO staging.cafe_sales
SELECT transaction_id, item, quantity, price_per_unit, total_spent,
        payment_method, location, transaction_date 
FROM staging.cafe_tipada
WHERE transaction_id IS NOT NULL 
	AND item IS NOT NULL
	AND quantity IS NOT NULL
	AND price_per_unit IS NOT NULL
	AND total_spent IS NOT NULL
	AND payment_method IS NOT NULL
	AND location IS NOT NULL
	AND transaction_date IS NOT NULL;

-- 4) Contagem de linhas
SELECT (SELECT COUNT(*) FROM staging.cafe_tipada) AS linhas_tipada,
    (SELECT COUNT(*) FROM staging.cafe_sales)  AS linhas_limpas,
    (SELECT COUNT(*) FROM staging.cafe_tipada) - (SELECT COUNT(*) FROM staging.cafe_sales) AS descartadas;
-- Resultado: linhas_tipada = 10000 | linhas_limpas = 9064 | descartadas = 936

/*Enunciado 10 
Consulte a menor e a maior data de venda registradas em staging.cafe_sales. Em seguida,
crie dw.dim_date com as colunas da Figura 4 (date_sk inteiro no formato YYYYMMDD) e
carregue-a com generate_series, gerando todos os dias dos anos completos que cobrem
esse intervalo. Confira a quantidade de linhas geradas.*/

-- Consulta Maior e Menor Data
SELECT 
    MIN(transaction_date) AS menor_data,
    MAX(transaction_date) AS maior_data
FROM staging.cafe_sales;

-- Dimensão Date
DROP TABLE IF EXISTS dw.dim_date CASCADE;
CREATE TABLE dw.dim_date (
    date_sk INTEGER PRIMARY KEY,
    full_date DATE NOT NULL,
    day SMALLINT NOT NULL,
    month SMALLINT NOT NULL,
    month_name VARCHAR(20) NOT NULL,
    quarter SMALLINT NOT NULL,
    year SMALLINT NOT NULL,
    day_of_week CHAR(20) NOT NULL,
    is_weekend BOOLEAN NOT NULL
);

INSERT INTO dw.dim_date 
SELECT
    CAST(TO_CHAR(d, 'YYYYMMDD') AS INTEGER),
    d::DATE,
    EXTRACT(DAY FROM d)::SMALLINT,
    EXTRACT(MONTH FROM d)::SMALLINT,
    TO_CHAR(d, 'TMMonth'),
    EXTRACT(QUARTER FROM d)::SMALLINT,
    EXTRACT(YEAR FROM d)::SMALLINT,
    TO_CHAR(d, 'TMDay'),
    EXTRACT(DOW FROM d) IN (0, 6)
FROM GENERATE_SERIES(
    DATE '2023-01-01',
    DATE '2023-12-31',
    INTERVAL '1 day'
) AS g(d);
-- Linhas afetadas: 365

/*Enunciado 11 
Crie e carregue dw.dim_item, dw.dim_payment e dw.dim_location, com chaves SERIAL e
atributos descritivos UNIQUE. A carga usa DISTINCT sobre staging.cafe_sales; a category
de dim_item vem de staging.cardapio. Confira as três dimensões em uma única consulta
com UNION ALL: esperam-se 8 itens, 4 formas de pagamento e 3 locais, já incluído o valor
'Unknown'.*/	

-- Dimensão dim_item
DROP TABLE IF EXISTS dw.dim_item CASCADE;
CREATE TABLE dw.dim_item(
	item_sk SERIAL PRIMARY KEY,
	item VARCHAR(20) NOT NULL UNIQUE,
	category VARCHAR(10) NOT NULL
);

-- Dimensão dim_payment
DROP TABLE IF EXISTS dw.dim_payment CASCADE;
CREATE TABLE dw.dim_payment(
	payment_sk SERIAL PRIMARY KEY,
	payment VARCHAR (20) NOT NULL UNIQUE
);

-- Dimensão dim_location
DROP TABLE IF EXISTS dw.dim_location CASCADE;
CREATE TABLE dw.dim_location(
	location_sk SERIAL PRIMARY KEY,
	location VARCHAR (20) NOT NULL UNIQUE
);

-- Populando dim_item 
INSERT INTO dw.dim_item (item, category)
SELECT DISTINCT
	s.item, c.category
FROM staging.cafe_sales s
JOIN staging.cardapio c
ON s.item = c.item;

-- Populando dim_payment
INSERT INTO dw.dim_payment (payment)
SELECT DISTINCT
    s.payment_method
FROM staging.cafe_sales s;

-- Populando dim_location
INSERT INTO dw.dim_location (location)
SELECT DISTINCT
    s.location
FROM staging.cafe_sales s;

/*Enunciado 12
Crie dw.fact_sales conforme a Figura 4: transaction_nk como chave primária (dimensão
degenerada), chaves estrangeiras NOT NULL para as quatro dimensões, métricas NOT NULL e
um índice por chave estrangeira. Carregue-a a partir de staging.cafe_sales, precedida de
TRUNCATE: date_sk por formatação da data, sem JOIN; as outras três surrogate keys por JOIN
com as dimensões. Por fim, escreva uma consulta que compare, lado a lado, a quantidade de
linhas e a soma de total_spent da staging e da fato. Os dois pares devem ser iguais.*/


-- Tabela fato
DROP TABLE IF EXISTS dw.fact_sales CASCADE;

CREATE TABLE dw.fact_sales(
    transaction_nk VARCHAR(20) PRIMARY KEY,
    date_sk INTEGER NOT NULL REFERENCES dw.dim_date(date_sk),
    item_sk INTEGER NOT NULL REFERENCES dw.dim_item(item_sk),
    payment_sk INTEGER NOT NULL REFERENCES dw.dim_payment(payment_sk),
    location_sk INTEGER NOT NULL REFERENCES dw.dim_location(location_sk),
    quantity INTEGER NOT NULL,
    price_per_unit NUMERIC(6,2) NOT NULL,
    total_spent NUMERIC(8,2) NOT NULL
);

TRUNCATE TABLE dw.fact_sales;

INSERT INTO dw.fact_sales(transaction_nk, date_sk, item_sk, payment_sk, location_sk, quantity, price_per_unit, total_spent)
SELECT
    s.transaction_id,
    CAST(TO_CHAR(s.transaction_date, 'YYYYMMDD') AS INTEGER),
    di.item_sk,
    dp.payment_sk,
    dl.location_sk,
    s.quantity,
    s.price_per_unit,
    s.total_spent
FROM staging.cafe_sales s
JOIN dw.dim_item di
    ON di.item = s.item
JOIN dw.dim_payment dp
    ON dp.payment = s.payment_method
JOIN dw.dim_location dl
    ON dl.location = s.location;

-- Consulta Validação linhas e soma 
SELECT
    (SELECT COUNT(*)FROM staging.cafe_sales) AS linhas_staging,
    (SELECT COUNT(*) FROM dw.fact_sales) AS linhas_fato,
    (SELECT SUM(total_spent) FROM staging.cafe_sales) AS soma_staging,
    (SELECT SUM(total_spent) FROM dw.fact_sales) AS soma_fato;

    
/* ENUNCIADO 13
Escreva um bloco anônimo PL/pgSQL (DO), sem criar função nem procedimento, que produza
um ranking de receita para cada uma das três dimensões pequenas do DW: item, payment e
location, nessa ordem, em uma única execução. Requisitos obrigatórios:
a) deve existir um único cursor, não vinculado: declarado como REFCURSOR, sem consulta
no DECLARE;
b) o bloco percorre os nomes das três dimensões com um laço, à escolha do grupo, e, a cada
volta, guarda o nome da dimensão da vez em uma variável;
c) a cada volta, a consulta é dinâmica: um texto montado por concatenação com essa
variável, que junta dw.fact_sales à tabela dw.dim_dimensão e devolve, para cada valor
do atributo de mesmo nome, a quantidade de vendas e a receita (soma de total_spent),
da maior para a menor receita;
d) a cada volta, o cursor é aberto com OPEN ... FOR EXECUTE, percorrido com FETCH em um
LOOP, com saída por EXIT WHEN NOT FOUND, e fechado com CLOSE antes de ser reaberto
com a consulta da dimensão seguinte;
e) antes de percorrer as dimensões, o bloco calcula a receita total da fato; a cada
linha lida, emite um RAISE NOTICE no formato <dimensão> | <posição> - <valor>:
<vendas> vendas, receita <receita> (<percentual>% do total), com o percentual
arredondado para duas casas;
f) ao terminar cada dimensão, emite um RAISE NOTICE com a quantidade de linhas lidas
naquela dimensão; ao terminar as três, emite um último com o total de linhas lidas.
Para cada dimensão, a soma dos percentuais exibidos deve ser 100%, com diferença apenas
de arredondamento.*/
DO $$
DECLARE
    cur_ranking      REFCURSOR; -- a) único cursor, não vinculado REFCURSOR
    v_dimensoes      TEXT[] := ARRAY['item', 'payment', 'location']; -- b) nomes das três dimensões
    v_dimensao       TEXT; -- b) dimensão da vez
    v_consulta       TEXT;
    v_valor          TEXT;
    v_vendas         INT;
    v_receita        NUMERIC(12,2);
    v_receita_total  NUMERIC(12,2);
    v_pct            NUMERIC(5,2);
    v_posicao        INT;
    v_linhas_total   INT := 0;

BEGIN
    SELECT SUM(total_spent) INTO v_receita_total FROM dw.fact_sales; 
    -- e) antes de percorrer as dimensões, o bloco calcula a receita total da fato

    FOREACH v_dimensao IN ARRAY v_dimensoes LOOP -- b) guarda o nome da dimensão da vez em v_dimensao
        
	v_consulta :=
            'SELECT d.' || v_dimensao || '::TEXT AS valor, ' -- c)texto montado por concatenação com a variável
            || 'COUNT(*) AS vendas, ' -- c) quantidade de vendas
            || 'SUM(f.total_spent) AS receita ' -- c) receita
            || 'FROM dw.fact_sales f '
            || 'JOIN dw.dim_' || v_dimensao || ' d ' -- c)junta dw.fact_sales à tabela dw.dim_dimensão
            || 'ON d.' || v_dimensao || '_sk = f.' || v_dimensao || '_sk '
            || 'GROUP BY d.' || v_dimensao || ' '
            || 'ORDER BY receita DESC'; -- c) da maior para a menor receita

        OPEN cur_ranking FOR EXECUTE v_consulta; -- d) a cada volta, o cursor é aberto com OPEN
        v_posicao := 0;

        LOOP
            FETCH cur_ranking INTO v_valor, v_vendas, v_receita; -- d)  percorrido com FETCH em um LOOP
            EXIT WHEN NOT FOUND; -- d) com saída por EXIT WHEN NOT FOUND

            v_posicao := v_posicao + 1;
            v_pct := ROUND(v_receita * 100 / v_receita_total, 2);

            RAISE NOTICE '% | % - %: % vendas, receita % (% do total)', v_dimensao, v_posicao, v_valor, v_vendas, v_receita, v_pct || '%'; 
		-- e) RAISE NOTICE no formato <dimensão> | <posição> - <valor>: <vendas> vendas, receita <receita> (<percentual>% do total), com o percentual arredondado para duas casas;

        END LOOP;

        CLOSE cur_ranking; -- d) fechado com CLOSE antes de ser reaberto com a consulta da dimensão seguinte

        RAISE NOTICE '% | linhas lidas: %', v_dimensao, v_posicao; 
        v_linhas_total := v_linhas_total + v_posicao; -- f) RAISE NOTICE com a quantidade de linhas lidas naquela dimensão
    
	END LOOP;

    RAISE NOTICE 'Total de linhas lidas nas três dimensões: %', v_linhas_total; -- f) emite um último com o total de linhas lidas
END;
$$;

/* ENUNCIADO 14
Mostre, para cada mês, o nome do mês, a quantidade de vendas, a receita e o ticket médio
(arredondado para duas casas), em ordem cronológica.*/

SELECT d.year AS Ano,
	d.month_name AS Mês,
	COUNT (*) As qtde_vendas,
	SUM(f.total_spent) AS Receita,
	ROUND(AVG(f.total_spent),2) AS ticket_médio
FROM dw.fact_sales f
JOIN dw.dim_date d ON d.date_sk = f.date_sk
GROUP BY 1, d.month, 2
ORDER BY 1, d.month;

/* ENUNCIADO 15
Mostre o ranking de itens: categoria, item, total de unidades vendidas e receita, da maior
para a menor receita.*/

SELECT i.category AS Categoria,
	i.item AS Item,
	SUM(f.quantity) AS Total_unidades,
	SUM(f.total_spent) AS Receita
FROM dw.fact_sales f
JOIN dw.dim_item i ON i.item_sk = f.item_sk
GROUP BY 1,2 
ORDER BY 4 DESC;

/* ENUNCIADO 16 
Mostre, para cada dia da semana, se ele é fim de semana, a quantidade de vendas e a receita,
da maior para a menor receita.*/

SELECT d.day_of_week AS Dia_da_Semana,
	d.is_weekend AS Final_de_Semana,
	COUNT(*) AS qtde_vendas,
	SUM(f.total_spent) AS Receita
FROM dw.fact_sales f
JOIN dw.dim_date d on d.date_sk = f.date_Sk
GROUP BY 1, 2
ORDER BY 4 DESC;

