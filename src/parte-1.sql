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
