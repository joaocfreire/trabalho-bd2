-- Esse script deve ser executado pelo usuário Chinook;
-- Cria o usuário user_aux para a efetuar o controle de acesso
-- necessário para a Regra Semântica 1 da Parte 2 implementada via procedure;

DROP USER IF EXISTS user_aux CASCADE;

CREATE USER user_aux IDENTIFIED BY user_aux;

GRANT CREATE SESSION TO user_aux;

GRANT SELECT ON employee TO user_aux;

GRANT EXECUTE ON insere_funcionario TO user_aux;

GRANT EXECUTE ON altera_salario_funcionario TO user_aux;