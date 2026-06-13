-- Esse script deve ser executado pelo usuário user_aux;
-- Contém o teste da Regra Semântica 1 da Parte 2, implementada via procedure

-- Regra Semântica 1

-- Atualiza o salário do General Manager - topo da hierarquia (deve FUNCIONAR)
BEGIN
    chinook.altera_salario_funcionario(1, 15000.00);
END;

-- Tenta atualizar o salário do Sales Manager, cujo chefe é o General Manager com um salário maior (deve FALHAR)
BEGIN
    chinook.altera_salario_funcionario(2, 16000.00);
END;

-- Atualiza o salário do Sales Manager, cujo chefe é o General Manager com um salário menor (deve FUNCIONAR)
BEGIN
    chinook.altera_salario_funcionario(2, 10000.00);
END;

-- Tenta inserir um novo funcionário respondendo ao General Manager (Employee 1, salário 15000),
-- mas com um salário maior (16000) (deve FALHAR)
BEGIN
    chinook.insere_funcionario(
            p_employeeId => 9,
            p_lastName => 'Freire',
            p_firstName => 'João',
            p_reportsTo => 1,
            p_salary => 16000.00
    );
END;
/

-- Insere um novo funcionário respondendo ao General Manager com um salário válido (deve FUNCIONAR)
BEGIN
    chinook.insere_funcionario(
            p_employeeId => 9,
            p_lastName => 'Freire',
            p_firstName => 'João',
            p_reportsTo => 1,
            p_salary => 8000.00
    );
END;
/


-- Regra Semântica 4

INSERT INTO chinook.playlist (playlistid, name)
VALUES (20, 'Playlist 20');

-- Insere 500 músicas na playlist 20 (deve FUNCIONAR)
BEGIN
    FOR i IN 1..500 LOOP
        chinook.insere_playlist_track(20, i);
    END LOOP;
END;

-- Tenta inserir a 501° música (deve FALHAR)
BEGIN
    chinook.insere_playlist_track(20, 501);
END;

