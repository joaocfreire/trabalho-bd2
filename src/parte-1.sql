-- ************************ TRABALHO BD2 - PARTE 1 ************************ --


-- 1. Consultar as tabelas de catálogo para listar todos os índices existentes
-- acompanhados das tabelas e colunas indexadas pelo mesmo.

SELECT i.INDEX_NAME, i.TABLE_NAME, ic.COLUMN_NAME
FROM USER_INDEXES i
         JOIN USER_IND_COLUMNS ic ON i.INDEX_NAME = ic.INDEX_NAME;


-- 2. Criar usando a linguagem de programação do SGBD escolhido um procedimento
-- que remova todos os índices de uma tabela informada como parâmetro.

CREATE OR REPLACE PROCEDURE REMOVE_INDICES(tabela VARCHAR2)
    IS
BEGIN
    FOR cons IN (SELECT CONSTRAINT_NAME
                 FROM USER_CONSTRAINTS
                 WHERE TABLE_NAME = tabela
                   AND CONSTRAINT_TYPE IN ('P', 'U'))
        LOOP
            EXECUTE IMMEDIATE 'ALTER TABLE ' || tabela || ' DROP CONSTRAINT ' || cons.CONSTRAINT_NAME || ' CASCADE';
            DBMS_OUTPUT.PUT_LINE('Constraint (e seu índice) deletada: ' || cons.CONSTRAINT_NAME);
        END LOOP;

    FOR idx IN (SELECT INDEX_NAME FROM USER_INDEXES WHERE TABLE_NAME = tabela)
        LOOP
            EXECUTE IMMEDIATE 'DROP INDEX ' || idx.INDEX_NAME;
            DBMS_OUTPUT.PUT_LINE('Indíce deletado: ' || idx.INDEX_NAME);
        END LOOP;
END;

BEGIN
    REMOVE_INDICES('TRACK');
END;


-- 3. Consultar as tabelas de catálogo para listar todas as chaves estrangeiras existentes
-- informando as tabelas e colunas envolvidas.

SELECT
    c1.CONSTRAINT_NAME AS NOME_FK,
    c1.TABLE_NAME      AS TABELA_ORIGEM,
    cc1.COLUMN_NAME    AS COLUNA_ORIGEM,
    c2.TABLE_NAME      AS TABELA_DESTINO,
    cc2.COLUMN_NAME    AS COLUNA_DESTINO
FROM USER_CONSTRAINTS c1
         JOIN USER_CONS_COLUMNS cc1 ON c1.CONSTRAINT_NAME = cc1.CONSTRAINT_NAME
         JOIN USER_CONSTRAINTS c2 ON c1.R_CONSTRAINT_NAME = c2.CONSTRAINT_NAME
         JOIN USER_CONS_COLUMNS cc2 ON c2.CONSTRAINT_NAME = cc2.CONSTRAINT_NAME
    AND cc1.POSITION = cc2.POSITION
WHERE c1.CONSTRAINT_TYPE = 'R';


-- 4. Criar usando a linguagem de programação do SGBD escolhido um script que construa
-- de forma dinâmica a partir do catálogo os comandos create table das tabelas
-- existentes no esquema exemplo considerando pelo menos as informações sobre
-- colunas (nome, tipo e obrigatoriedade) e chaves primárias e estrangeiras.


CREATE OR REPLACE PROCEDURE gerar_ddl(esquema VARCHAR2) IS
    linha VARCHAR2(32767);
    primeira_linha BOOLEAN;
BEGIN
    FOR tabela IN (SELECT TABLE_NAME FROM ALL_TABLES WHERE OWNER = esquema)
    LOOP
        DBMS_OUTPUT.PUT_LINE('CREATE TABLE ' || tabela.TABLE_NAME || ' (');
        primeira_linha := TRUE;

        FOR coluna IN (SELECT COLUMN_NAME, DATA_TYPE, NULLABLE,
                              DATA_LENGTH, DATA_PRECISION, DATA_SCALE
                       FROM ALL_TAB_COLUMNS
                       WHERE tabela.TABLE_NAME = TABLE_NAME AND
                             OWNER = esquema)
        LOOP

            IF NOT primeira_linha THEN
                DBMS_OUTPUT.PUT_LINE(',');
            END IF;
            primeira_linha := FALSE;

            linha := '  ' || coluna.COLUMN_NAME || ' ' || coluna.DATA_TYPE;

            IF coluna.DATA_TYPE IN ('VARCHAR2', 'CHAR', 'NVARCHAR2', 'NCHAR') THEN
                linha := linha || '(' || coluna.DATA_LENGTH || ')';
            END IF;

            IF coluna.DATA_TYPE IN ('NUMBER', 'FLOAT') AND coluna.DATA_PRECISION IS NOT NULL THEN
                linha := linha || '(' || coluna.DATA_PRECISION;
                IF coluna.DATA_SCALE IS NOT NULL THEN
                    linha := linha || ', ' || coluna.DATA_SCALE;
                END IF;
                linha := linha || ')';
            END IF;

            IF coluna.NULLABLE = 'N' THEN
                linha := linha || ' NOT NULL';
            END IF;

            DBMS_OUTPUT.PUT(linha);

        END LOOP;

        FOR reg_constraint IN (SELECT
                                   c.CONSTRAINT_NAME,
                                   c.CONSTRAINT_TYPE,
                                   LISTAGG(cc.COLUMN_NAME, ', ') WITHIN GROUP (ORDER BY cc.POSITION) AS COLUNAS,

                                   (SELECT r.TABLE_NAME FROM ALL_CONSTRAINTS r
                                    WHERE r.CONSTRAINT_NAME = c.R_CONSTRAINT_NAME
                                        AND r.OWNER = c.R_OWNER) AS TABELA_PAI,

                                   (SELECT LISTAGG(rc.COLUMN_NAME, ', ') WITHIN GROUP (ORDER BY rc.POSITION)
                                    FROM ALL_CONS_COLUMNS rc
                                    WHERE rc.CONSTRAINT_NAME = c.R_CONSTRAINT_NAME
                                      AND rc.OWNER = c.R_OWNER) AS COLUNAS_PAI

                               FROM ALL_CONSTRAINTS c
                                    JOIN ALL_CONS_COLUMNS cc ON c.CONSTRAINT_NAME = cc.CONSTRAINT_NAME
                                    AND c.OWNER = cc.OWNER
                               WHERE c.TABLE_NAME = tabela.TABLE_NAME AND
                                     c.CONSTRAINT_TYPE IN ('P', 'R') AND
                                     c.OWNER = esquema
                               GROUP BY c.CONSTRAINT_NAME, c.CONSTRAINT_TYPE, c.R_CONSTRAINT_NAME, c.R_OWNER)
            LOOP
                DBMS_OUTPUT.PUT_LINE(',');

                IF reg_constraint.CONSTRAINT_TYPE = 'P' THEN
                    linha := '  CONSTRAINT ' || reg_constraint.CONSTRAINT_NAME ||
                             ' PRIMARY KEY (' || reg_constraint.COLUNAS || ')';
                    DBMS_OUTPUT.PUT(linha);

                ELSIF reg_constraint.CONSTRAINT_TYPE = 'R' THEN

                    linha := '  CONSTRAINT ' || reg_constraint.CONSTRAINT_NAME ||
                             ' FOREIGN KEY (' || reg_constraint.COLUNAS || ')' ||
                             ' REFERENCES ' || reg_constraint.TABELA_PAI || '(' ||
                             reg_constraint.COLUNAS_PAI || ')';
                    DBMS_OUTPUT.PUT(linha);
                END IF;
            END LOOP;

        DBMS_OUTPUT.NEW_LINE();
        DBMS_OUTPUT.PUT_LINE(');');
        DBMS_OUTPUT.PUT_LINE('/');
        DBMS_OUTPUT.NEW_LINE();
    END LOOP;
END;

BEGIN
    gerar_ddl('TRABALHO_BD2');
END;
/


-- 5. Implemente uma solução através da programação em banco de dados para validar os
-- valores de uma coluna que represente uma situação (estado) garantindo que os seus
-- valores e suas transições atendam a especificação de um diagrama de transição de
-- estados (DTE). Quanto mais genérica e reutilizável for a solução melhor a pontuação.


-- ---------- Limpeza (permite reexecução do script) ----------
BEGIN
    BEGIN EXECUTE IMMEDIATE 'DROP TRIGGER trg_dte_invoice_status';            EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'DELETE FROM invoice WHERE invoiceid IN (9001,9002,9003,9004)'; EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'ALTER TABLE invoice DROP COLUMN status';         EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'DROP TABLE dte_transicao CASCADE CONSTRAINTS';   EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'DROP TABLE dte_estado   CASCADE CONSTRAINTS';    EXCEPTION WHEN OTHERS THEN NULL; END;
    BEGIN EXECUTE IMMEDIATE 'DROP TABLE dte_maquina  CASCADE CONSTRAINTS';    EXCEPTION WHEN OTHERS THEN NULL; END;
END;
/


-- ---------- Metadados: o DTE armazenado como dados ----------

-- Uma máquina de estados por coluna-estado de uma tabela.
CREATE TABLE dte_maquina (
    maquina_id     VARCHAR2(30)  NOT NULL,
    tabela         VARCHAR2(128) NOT NULL,
    coluna         VARCHAR2(128) NOT NULL,
    valida_inicial CHAR(1)       DEFAULT 'S' NOT NULL,
    descricao      VARCHAR2(200),
    CONSTRAINT pk_dte_maquina  PRIMARY KEY (maquina_id),
    CONSTRAINT ck_dte_maq_vini CHECK (valida_inicial IN ('S', 'N'))
);

-- Conjunto de estados válidos de cada máquina (os nós do DTE).
CREATE TABLE dte_estado (
    maquina_id VARCHAR2(30) NOT NULL,
    estado     VARCHAR2(30) NOT NULL,
    inicial    CHAR(1) DEFAULT 'N' NOT NULL,
    final      CHAR(1) DEFAULT 'N' NOT NULL,
    CONSTRAINT pk_dte_estado     PRIMARY KEY (maquina_id, estado),
    CONSTRAINT fk_dte_estado_maq FOREIGN KEY (maquina_id) REFERENCES dte_maquina (maquina_id),
    CONSTRAINT ck_dte_est_ini    CHECK (inicial IN ('S', 'N')),
    CONSTRAINT ck_dte_est_fim    CHECK (final   IN ('S', 'N'))
);

-- Transições válidas (as arestas do DTE). As FKs para dte_estado garantem que só se
-- pode declarar transição entre estados que existem -- o próprio DTE é autovalidável.
CREATE TABLE dte_transicao (
    maquina_id     VARCHAR2(30) NOT NULL,
    estado_origem  VARCHAR2(30) NOT NULL,
    estado_destino VARCHAR2(30) NOT NULL,
    CONSTRAINT pk_dte_transicao PRIMARY KEY (maquina_id, estado_origem, estado_destino),
    CONSTRAINT fk_dte_trans_org FOREIGN KEY (maquina_id, estado_origem)  REFERENCES dte_estado (maquina_id, estado),
    CONSTRAINT fk_dte_trans_dst FOREIGN KEY (maquina_id, estado_destino) REFERENCES dte_estado (maquina_id, estado)
);


-- ---------- Validador genérico ----------
CREATE OR REPLACE PROCEDURE dte_validar(
    p_maquina     VARCHAR2,
    p_estado_old  VARCHAR2,
    p_estado_novo VARCHAR2
) IS
    v_inicial        dte_estado.inicial%TYPE;
    v_valida_inicial dte_maquina.valida_inicial%TYPE;
    v_qtd            NUMBER;
    v_lista          VARCHAR2(4000);
BEGIN
    -- (0) Em um DTE estrito o estado nulo nunca é um valor válido.
    IF p_estado_novo IS NULL THEN
        RAISE_APPLICATION_ERROR(-20203,
            'DTE[' || p_maquina || ']: estado nulo não é permitido.');
    END IF;

    -- (1) Valida o VALOR: o novo estado precisa existir no conjunto de estados da máquina.
    BEGIN
        SELECT inicial
        INTO v_inicial
        FROM dte_estado
        WHERE maquina_id = p_maquina
          AND estado = p_estado_novo;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            SELECT LISTAGG(estado, ', ') WITHIN GROUP (ORDER BY estado)
            INTO v_lista
            FROM dte_estado
            WHERE maquina_id = p_maquina;
            RAISE_APPLICATION_ERROR(-20200,
                'DTE[' || p_maquina || ']: estado inválido "' || p_estado_novo ||
                '". Estados válidos: ' || NVL(v_lista, '(nenhum)') || '.');
    END;

    -- (2) INSERT (sem estado anterior): se configurado, exige começar em um estado inicial.
    IF p_estado_old IS NULL THEN
        SELECT valida_inicial INTO v_valida_inicial
        FROM dte_maquina
        WHERE maquina_id = p_maquina;

        IF v_valida_inicial = 'S' AND v_inicial = 'N' THEN
            SELECT LISTAGG(estado, ', ') WITHIN GROUP (ORDER BY estado)
            INTO v_lista
            FROM dte_estado
            WHERE maquina_id = p_maquina AND inicial = 'S';
            RAISE_APPLICATION_ERROR(-20201,
                'DTE[' || p_maquina || ']: "' || p_estado_novo ||
                '" não é um estado inicial válido. Iniciais: ' || NVL(v_lista, '(nenhum)') || '.');
        END IF;
        RETURN;
    END IF;

    -- (3) Permanência: um UPDATE que não altera o estado é sempre permitido.
    IF p_estado_old = p_estado_novo THEN
        RETURN;
    END IF;

    -- (4) UPDATE: a transição origem -> destino precisa estar declarada no DTE.
    SELECT COUNT(*) INTO v_qtd
    FROM dte_transicao
    WHERE maquina_id = p_maquina
      AND estado_origem  = p_estado_old
      AND estado_destino = p_estado_novo;

    IF v_qtd = 0 THEN
        SELECT LISTAGG(estado_destino, ', ') WITHIN GROUP (ORDER BY estado_destino)
        INTO v_lista
        FROM dte_transicao
        WHERE maquina_id = p_maquina AND estado_origem = p_estado_old;
        RAISE_APPLICATION_ERROR(-20202,
            'DTE[' || p_maquina || ']: transição inválida de "' || p_estado_old ||
            '" para "' || p_estado_novo || '". A partir de "' || p_estado_old ||
            '" só é permitido ir para: ' || NVL(v_lista, '(nenhum - estado final)') || '.');
    END IF;
END;
/


-- ---------- Gerador reutilizável da trigger de enforcement ----------
CREATE OR REPLACE PROCEDURE dte_gerar_trigger(p_maquina VARCHAR2)
    AUTHID CURRENT_USER
IS
    v_tabela  dte_maquina.tabela%TYPE;
    v_coluna  dte_maquina.coluna%TYPE;
    v_trigger VARCHAR2(128);
    v_ddl     VARCHAR2(4000);
BEGIN
    SELECT tabela, coluna INTO v_tabela, v_coluna
    FROM dte_maquina
    WHERE maquina_id = p_maquina;

    v_trigger := UPPER('trg_dte_' || p_maquina);

    IF LENGTHB(v_trigger) > 128 THEN
        RAISE_APPLICATION_ERROR(-20204,
            'DTE[' || p_maquina || ']: nome de trigger "' || v_trigger ||
            '" excede o limite de identificador.');
    END IF;

    v_ddl :=
        'CREATE OR REPLACE TRIGGER ' || v_trigger || ' ' ||
        'BEFORE INSERT OR UPDATE OF ' || v_coluna || ' ON ' || v_tabela || ' ' ||
        'FOR EACH ROW ' ||
        'BEGIN ' ||
        '  IF INSERTING THEN ' ||
        '    dte_validar(''' || p_maquina || ''', NULL, :NEW.' || v_coluna || '); ' ||
        '  ELSE ' ||
        '    dte_validar(''' || p_maquina || ''', :OLD.' || v_coluna || ', :NEW.' || v_coluna || '); ' ||
        '  END IF; ' ||
        'END;';

    EXECUTE IMMEDIATE v_ddl;
    DBMS_OUTPUT.PUT_LINE('Trigger ' || v_trigger || ' criada sobre ' ||
                         v_tabela || '.' || v_coluna || ' (máquina ' || p_maquina || ').');
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20205,
            'DTE: máquina "' || p_maquina || '" não encontrada em dte_maquina.');
END;
/


-- Procedure simétrica (ciclo de vida completo): remove a trigger de uma máquina.
CREATE OR REPLACE PROCEDURE dte_remover_trigger(p_maquina VARCHAR2) IS
    v_trigger VARCHAR2(128) := UPPER('trg_dte_' || p_maquina);
BEGIN
    EXECUTE IMMEDIATE 'DROP TRIGGER ' || v_trigger;
    DBMS_OUTPUT.PUT_LINE('Trigger ' || v_trigger || ' removida.');
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -4080 THEN   -- ORA-04080: trigger não existe
            DBMS_OUTPUT.PUT_LINE('Trigger ' || v_trigger || ' não existia.');
        ELSE
            RAISE;
        END IF;
END;
/


-- ---------- Registro do DTE de exemplo (ciclo de vida da fatura) ----------
INSERT INTO dte_maquina (maquina_id, tabela, coluna, valida_inicial, descricao)
VALUES ('INVOICE_STATUS', 'INVOICE', 'STATUS', 'S', 'Ciclo de vida de uma fatura (invoice)');

INSERT INTO dte_estado (maquina_id, estado, inicial, final) VALUES ('INVOICE_STATUS', 'ABERTA',    'S', 'N');
INSERT INTO dte_estado (maquina_id, estado, inicial, final) VALUES ('INVOICE_STATUS', 'PAGA',      'N', 'N');
INSERT INTO dte_estado (maquina_id, estado, inicial, final) VALUES ('INVOICE_STATUS', 'ENVIADA',   'N', 'N');
INSERT INTO dte_estado (maquina_id, estado, inicial, final) VALUES ('INVOICE_STATUS', 'ENTREGUE',  'N', 'S');
INSERT INTO dte_estado (maquina_id, estado, inicial, final) VALUES ('INVOICE_STATUS', 'CANCELADA', 'N', 'S');

INSERT INTO dte_transicao (maquina_id, estado_origem, estado_destino) VALUES ('INVOICE_STATUS', 'ABERTA',  'PAGA');
INSERT INTO dte_transicao (maquina_id, estado_origem, estado_destino) VALUES ('INVOICE_STATUS', 'ABERTA',  'CANCELADA');
INSERT INTO dte_transicao (maquina_id, estado_origem, estado_destino) VALUES ('INVOICE_STATUS', 'PAGA',    'ENVIADA');
INSERT INTO dte_transicao (maquina_id, estado_origem, estado_destino) VALUES ('INVOICE_STATUS', 'PAGA',    'CANCELADA');
INSERT INTO dte_transicao (maquina_id, estado_origem, estado_destino) VALUES ('INVOICE_STATUS', 'ENVIADA', 'ENTREGUE');
COMMIT;

ALTER TABLE invoice ADD status VARCHAR2(30) DEFAULT 'ABERTA';

BEGIN
    dte_gerar_trigger('INVOICE_STATUS');
END;
/


-- *************** TESTES *************** --

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

