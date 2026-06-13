-- Esse script deve ser executado pelo usuário Chinook;
-- Testes das questões implementadas na parte 1 e 2


-- ****************************************************************************************************************** --
--                                             TESTES - PARTE 1                                                       --
-- ****************************************************************************************************************** --

-- Questão 2
BEGIN
    remove_indices('TRACK');
END;
/


-- Questão 4
BEGIN
    gerar_ddl('CHINOOK');
END;
/


-- Questão 5

-- 1) INSERT usando o DEFAULT 'ABERTA' (estado inicial) -- (deve FUNCIONAR)
INSERT INTO invoice (invoiceid, customerid, invoicedate, total)
VALUES (9001, 1, TO_DATE('2026-06-07', 'YYYY-MM-DD'), 0);

-- 2) INSERT começando direto em 'PAGA', que não é estado inicial -- (deve FALHAR: ORA-20201)
INSERT INTO invoice (invoiceid, customerid, invoicedate, total, status)
VALUES (9002, 1, TO_DATE('2026-06-07', 'YYYY-MM-DD'), 0, 'PAGA');

-- 3) INSERT com um valor que não existe no DTE -- (deve FALHAR: ORA-20200)
INSERT INTO invoice (invoiceid, customerid, invoicedate, total, status)
VALUES (9003, 1, TO_DATE('2026-06-07', 'YYYY-MM-DD'), 0, 'XPTO');

-- 4) Transição ABERTA -> PAGA na fatura 9001 -- (deve FUNCIONAR)
UPDATE invoice SET status = 'PAGA' WHERE invoiceid = 9001;

-- 5) Transição PAGA -> ENVIADA -- (deve FUNCIONAR)
UPDATE invoice SET status = 'ENVIADA' WHERE invoiceid = 9001;

-- 6) Transição ENVIADA -> ABERTA (não declarada no DTE) -- (deve FALHAR: ORA-20202)
UPDATE invoice SET status = 'ABERTA' WHERE invoiceid = 9001;

-- 7) Transição ENVIADA -> ENTREGUE -- (deve FUNCIONAR)
UPDATE invoice SET status = 'ENTREGUE' WHERE invoiceid = 9001;

-- 8) ENTREGUE é estado final: qualquer saída é inválida -- (deve FALHAR: ORA-20202)
UPDATE invoice SET status = 'PAGA' WHERE invoiceid = 9001;

-- 9) Estado nulo nunca é permitido -- (deve FALHAR: ORA-20203)
UPDATE invoice SET status = NULL WHERE invoiceid = 9001;

-- 10) Nova fatura ABERTA e transição direta para CANCELADA -- (deve FUNCIONAR)
INSERT INTO invoice (invoiceid, customerid, invoicedate, total)
VALUES (9004, 1, TO_DATE('2026-06-07', 'YYYY-MM-DD'), 0);

UPDATE invoice SET status = 'CANCELADA' WHERE invoiceid = 9004;

-- Conferência final: 9001 deve estar 'ENTREGUE' e 9004 'CANCELADA'.
SELECT invoiceid, status FROM invoice WHERE invoiceid IN (9001, 9004) ORDER BY invoiceid;



-- ****************************************************************************************************************** --
--                                             TESTES - PARTE 2                                                       --
-- ****************************************************************************************************************** --


-- Regra Semântica 2

-- Tenta atualizar o cliente 1 colocando o General Manager como suporte (deve FALHAR)
UPDATE customer
SET supportrepid = 1 -- id do General Manager
WHERE customerid = 1;

-- Coloca outro funcionário do suporte para o cliente 1 (deve FUNCIONAR)
UPDATE customer
SET supportrepid = 4 -- id de um Sales Support Agent
WHERE customerid = 1;


-- Regra Semântica 3

-- OBS: customer 11 na invoice 123 já comprou a track 501)

-- Registra uma nova compra para o teste
INSERT INTO invoice (invoiceid, customerid, invoicedate, total)
VALUES (414, 11, '01-06-2026', 0);

-- Cliente 11 tenta comprar a mesma track (501) novamente (deve FALHAR)
INSERT INTO invoiceline (invoicelineid, invoiceid, trackid, unitprice, quantity)
VALUES (2242, 414, 501, 1, 1);

-- Cliente 11 tenta comprar outra track (1) pela primeira vez (deve FUNCIONAR)
INSERT INTO invoiceline (invoicelineid, invoiceid, trackid, unitprice, quantity)
VALUES (2243, 414, 1, 1, 1);


-- Questão 4

-- Tenta atualizar invoice com um valor de total diferente da soma dos unitprices (1.98) - (deve FALHAR)
UPDATE invoice
SET total = 2.0
WHERE invoiceid = 1;

-- Insere uma nova invoice (deve FUNCIONAR)
INSERT INTO invoice (invoiceid, customerid, invoicedate, total)
VALUES (413, 1, '31-05-2026', 0);

-- Insere uma nova invoiceline (deve FUNCIONAR)
INSERT INTO invoiceline (invoicelineid, invoiceid, trackid, unitprice, quantity)
VALUES (2241, 413, 1, 1, 10);

-- Tenta atualizar o total de uma invoice manualmente (deve FALHAR)
UPDATE invoice
SET total = 20
WHERE invoiceid = 413;