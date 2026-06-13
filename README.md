# Trabalho de Banco de Dados II - Esquema Chinook

Este repositório contém a implementação do Trabalho em Grupo da disciplina de Banco de Dados II. O projeto expande o esquema relacional **Chinook Database** utilizando programação avançada em PL/SQL (Oracle).

---

## Objetivos do Projeto

O trabalho foi dividido em duas frentes principais de implementação em SGBD:

### Parte 1: Catálogo e Metadados
* Consultas ao dicionário de dados para mapeamento de chaves estrangeiras e índices.
* Geração dinâmica de DDL (`CREATE TABLE`) a partir das tabelas de catálogo.
* Implementação de um **Diagrama de Transição de Estados (DTE)** genérico e reutilizável, validando os status das Faturas (`Invoice`) através de tabelas de metadados e triggers dinâmicas.

### Parte 2: Regras Semânticas e Integridade
* **RS1:** Um funcionário não pode ganhar um salário maior que o do seu supervisor (Implementado via Stored Procedures e controle de acesso em usuário restrito).
* **RS2:** Um cliente só pode ter suporte de um funcionário com o cargo "Sales Support Agent" (Implementado via Triggers).
* **Consistência de Fatura:** Atualização automática e bloqueio de manipulação manual da coluna redundante `Total` na tabela `Invoice`, controlada de forma segura por Triggers e Variáveis de Sessão (Package).

---

##  Ordem de Execução (Deploy)

Para garantir a resolução correta de dependências (criação de usuários, permissões, tabelas e objetos PL/SQL), os scripts devem ser executados na exata ordem numérica abaixo:

1. **`00_setup_admin.sql`** (Executar como `SYS`): Cria o esquema proprietário (`chinook`) e concede cotas e privilégios de sistema.
2. **`01_ddl_chinook.sql`** (Executar como `chinook`): Cria as tabelas originais do banco Chinook (modelo base).
3. **`02_parte1.sql`** (Executar como `chinook`): Implementa as consultas de dicionário, a procedure geradora de DDL e toda a arquitetura de validação DTE.
4. **`03_parte2.sql`** (Executar como `chinook`): Adiciona colunas auxiliares (`salary`, `status`), cria o controle de estado em Package, Procedures (RS1) e Triggers (RS2 e Invoice).
5. **`04_setup_user_aux.sql`** (Executar como `chinook`): Cria o usuário restrito (`user_aux`) e concede permissões exclusivas de execução nas procedures da RS1.
6. **`05_testes_chinook.sql`** (Executar como `chinook`): Bateria de testes das regras de negócio (DTE, Triggers, Updates) com usuário administrador.
7. **`06_testes_user_aux.sql`** (Executar como `user_aux`): Testes de segurança garantindo que o usuário secundário só manipule dados sob as restrições da procedure.

## Tecnologias Utilizadas
* **SGBD:** Oracle Database
* **Linguagem:** SQL e PL/SQL