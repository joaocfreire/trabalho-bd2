-- Esse script deve ser executado pelo usuário Chinook;
-- Solução das questões da parte 2 do trabalho


-- RS1: Um funcionário (employee) não pode ganhar um salário maior que o do seu supervisor.

-- OBS: como o CHINOOK não contém a coluna salary em employee,
-- foram feitas modificações no esquema para comportar a regra.

ALTER TABLE employee ADD salary NUMBER(7, 2);

ALTER TABLE employee ADD CONSTRAINT chk_salary CHECK ( salary > 0 );

CREATE OR REPLACE PROCEDURE insere_funcionario(
    p_employeeId NUMBER,
    p_lastName VARCHAR2,
    p_firstName VARCHAR2,
    p_title VARCHAR2 DEFAULT NULL,
    p_reportsTo NUMBER DEFAULT NULL,
    p_birthDate DATE DEFAULT NULL,
    p_hireDate DATE DEFAULT NULL,
    p_address VARCHAR2 DEFAULT NULL,
    p_city VARCHAR2 DEFAULT NULL,
    p_state VARCHAR2 DEFAULT NULL,
    p_country VARCHAR2 DEFAULT NULL,
    p_postalCode VARCHAR2 DEFAULT NULL,
    p_phone VARCHAR2 DEFAULT NULL,
    p_fax VARCHAR2 DEFAULT NULL,
    p_email VARCHAR2 DEFAULT NULL,
    p_salary NUMBER DEFAULT NULL
) IS
    salario_supervisor employee.salary%TYPE;
BEGIN
    IF p_reportsto IS NOT NULL THEN
        SELECT e.salary
        INTO salario_supervisor
        FROM employee e
        WHERE e.employeeid = p_reportsTo;

        IF p_salary > NVL(salario_supervisor, 0) THEN
            RAISE_APPLICATION_ERROR(-20101, 'ERRO! Você não pode cadastrar um funcionário com um ' ||
                                            'salário maior do que o do seu supervisor');
        END IF;
    END IF;

    INSERT INTO employee (employeeid, lastname, firstname, title, reportsto, birthdate, hiredate,
                          address, city, state, country, postalcode, phone, fax, email, salary)
        VALUES (p_employeeid, p_lastname, p_firstname, p_title, p_reportsto, p_birthdate, p_hiredate,
                p_address, p_city, p_state, p_country, p_postalcode, p_phone, p_fax, p_email, p_salary);
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20102, 'ERRO! Supervisor informado não encontrado.');
END;
/


CREATE OR REPLACE PROCEDURE altera_salario_funcionario(
    p_employeeId NUMBER,
    p_salary NUMBER DEFAULT NULL
) IS
    id_supervisor employee.employeeid%TYPE;
    salario_supervisor employee.salary%TYPE;
    maior_salario_supervisionado employee.salary%TYPE;
BEGIN
    SELECT e.reportsto
    INTO id_supervisor
    FROM employee e
    WHERE e.employeeid = p_employeeid;

    IF id_supervisor IS NOT NULL THEN
        SELECT e.salary
        INTO salario_supervisor
        FROM employee e
        WHERE e.employeeid = id_supervisor;

        IF p_salary > NVL(salario_supervisor, 0) THEN
            RAISE_APPLICATION_ERROR(-20102, 'ERRO! Você não pode atualizar um funcionário com um ' ||
                                            'salário maior do que o do seu supervisor');
        END IF;
    END IF;

    SELECT MAX(salary)
    INTO maior_salario_supervisionado
    FROM employee
    WHERE reportsto = p_employeeid;

    IF maior_salario_supervisionado IS NOT NULL AND p_salary < maior_salario_supervisionado THEN
            RAISE_APPLICATION_ERROR(-20103, 'ERRO! Você não pode atualizar um funcionário com um ' ||
                                            'salário menor do que o do(s) seu(s) supervisonado(s)');
    END IF;

    UPDATE employee
    SET salary = p_salary
    WHERE employeeid = p_employeeid;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20104, 'ERRO! Funcionário não encontrado.');
END;
/


-- RS2 - Um cliente (customer) só pode ter um funcionário associado à ele (supportRepId)
-- que tenha o title de “Sales Support Agent”.

CREATE OR REPLACE TRIGGER biu_customer BEFORE INSERT OR UPDATE OF supportrepid ON customer
    FOR EACH ROW
    DECLARE
        employee_title employee.title%TYPE;
    BEGIN

        IF :NEW.supportrepid IS NOT NULL THEN

            SELECT e.title
            INTO employee_title
            FROM employee e
            WHERE e.employeeid = :NEW.supportrepid;

            IF employee_title != 'Sales Support Agent' THEN
                RAISE_APPLICATION_ERROR(-20102, 'ERRO! Somente um funcionário do cargo "Sales Support Agent" pode ' ||
                                                'assumir a função de suporte para um cliente');
            END IF;

        END IF;

    END;
/


-- 4 - A base original do Chinook possui uma coluna Total na tabela Invoice representada
-- de forma redundante com as informações contidas nas colunas UnitPrice e
-- Quantity na tabela InvoiceLine. Podemos identificar nesse caso uma regra
-- semântica onde o valor Total de um Invoice deve ser igual à soma de UnitPrice *
-- Quantity de todos os registros de InvoiceLine relacionados a um Invoice.
-- Implementar uma solução que garanta a integridade dessa regra.


-- Como a invoice deve ser criada antes das invoicelines, precisamos garantir que o total inicial é 0
CREATE OR REPLACE TRIGGER bi_invoice_zero BEFORE INSERT ON invoice
    FOR EACH ROW
    BEGIN
        :NEW.total := 0;
    END;
/


-- Package que guarda a flag se a alteração foi do sistema ou de um usuário
CREATE OR REPLACE PACKAGE pkg_invoice_state AS
    g_is_system_update BOOLEAN := FALSE;
END pkg_invoice_state;
/


CREATE OR REPLACE TRIGGER bu_invoice BEFORE UPDATE of total ON INVOICE
    FOR EACH ROW
    BEGIN
        IF NOT pkg_invoice_state.g_is_system_update THEN
            IF :NEW.total != :OLD.total THEN
                RAISE_APPLICATION_ERROR(-20103, 'ERRO! Impossível alterar o total manualmente');
            END IF;
        END IF;
    END;
/


-- Atualiza a consistencia do total em invoice
CREATE OR REPLACE TRIGGER aiud_invoiceline AFTER INSERT OR UPDATE OF quantity, unitprice OR DELETE ON invoiceline
    FOR EACH ROW
    BEGIN
        pkg_invoice_state.g_is_system_update := TRUE;

        IF :OLD.invoicelineid IS NULL THEN -- INSERT
            UPDATE invoice
            SET total = total + (:NEW.unitprice * :NEW.quantity)
            WHERE invoiceid = :NEW.invoiceid;

        ELSIF :NEW.invoicelineid IS NULL THEN -- DELETE
            UPDATE invoice
            SET total = total - (:OLD.unitprice * :OLD.quantity)
            WHERE invoiceid = :OLD.invoiceid;

        ELSE -- se não é INSERT nem DELETE é UPDATE
            UPDATE invoice
            SET total = total - (:OLD.unitprice * :OLD.quantity) + (:NEW.unitprice * :NEW.quantity)
            WHERE invoiceid = :NEW.invoiceid;
        END IF;

        pkg_invoice_state.g_is_system_update := FALSE;

    EXCEPTION
        WHEN OTHERS THEN
            pkg_invoice_state.g_is_system_update := FALSE;
            RAISE;
    END;
/
