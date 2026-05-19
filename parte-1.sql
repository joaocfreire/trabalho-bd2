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
