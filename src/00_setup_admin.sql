-- Esse script deve ser executado pelo user SYS;
-- Cria o usuário dono do Chinook e concede os privilégios básicos;

DROP USER IF EXISTS chinook CASCADE;

CREATE USER chinook IDENTIFIED BY chinook;

GRANT RESOURCE TO chinook;

GRANT CREATE SESSION TO chinook WITH ADMIN OPTION;

GRANT CREATE USER, ALTER USER, DROP USER TO chinook;

ALTER USER chinook QUOTA UNLIMITED ON USERS;