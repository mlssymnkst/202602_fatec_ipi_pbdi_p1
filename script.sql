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