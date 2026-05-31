-- ************************ TRABALHO BD2 - PARTE 2 ************************ --


-- RS1: Um funcionário (employee) não pode ganhar um salário maior que o do seu supervisor.
-- OBS: como o CHINOOK não contém a coluna salary em employee,
-- foram feitas modificações no esquema para comportar a regra.

ALTER TABLE employee ADD salary NUMBER(7, 2);

ALTER TABLE employee ADD CONSTRAINT chk_salary CHECK ( salary > 0 );

CREATE OR REPLACE TRIGGER bi_employee BEFORE INSERT OR UPDATE OF salary ON employee
    FOR EACH ROW
    DECLARE
        salario_superior employee.salary%TYPE;

        PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
        IF :NEW.reportsto IS NOT NULL THEN

            SELECT salary
            INTO salario_superior
            FROM employee
            WHERE employeeid = :NEW.reportsto;

            IF :NEW.salary > salario_superior THEN
                RAISE_APPLICATION_ERROR(-20101, 'ERRO! Você não pode cadastrar um salário de um funcionário ' ||
                                                'com um valor maior do que o do seu supervisor');
            END IF;

        END IF;

        DBMS_OUTPUT.PUT_LINE('Operação realizada com sucesso!');
    END;


-- *************** TESTES *************** --

-- atualiza o salário do General Manager (topo da hierarquia)
UPDATE employee
SET salary = 15000.00
WHERE employeeid = 1;

-- tenta atualizar o salário do Sales Manager, cujo chefe é o General Manager com um salário maior (deve FALHAR)
UPDATE employee
SET salary = 16000.00
WHERE employeeid = 2;

-- atualiza o salário do Sales Manager, cujo chefe é o General Manager com um salário menor (deve FUNCIONAR)
UPDATE employee
SET salary = 10000.00
WHERE employeeid = 2;
