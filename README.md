## PINGU WALLET

Este é um sistema de gestão financeira pessoal desenvolvido para oferecer controle total sobre receitas e despesas, permitindo uma visão clara da saúde financeira através de dashboards intuitivos e previsões inteligentes.

## 📝 Descrição

O projeto consiste em um ecossistema completo composto por um aplicativo móvel desenvolvido em Flutter, uma API robusta em Node.js e um banco de dados relacional PostgreSQL. A arquitetura foi pensada para ser escalável, utilizando Docker para infraestrutura e Firebase Auth para garantir a segurança dos dados dos usuários.

## 🚀 Funcionalidades (Sprint 1)

Atualmente, o projeto encontra-se em sua fase inicial (MVP), com as seguintes funcionalidades core implementadas:

* Gestão de Transações: Cadastro de receitas e despesas com descrição e valores.

* Dashboard Resumo: Visualização em tempo real do Saldo Atual, Total de Entradas e Total de Saídas.

* Histórico de Lançamentos: Listagem cronológica de todas as movimentações financeiras.

* Infraestrutura Automatizada: Banco de dados conteinerizado pronto para uso.

## 🛠️ Tecnologias
### Mobile (Front-end)

* Flutter - Framework UI.

* Http - Consumo de API.

* Firebase Auth - Autenticação segura.

### Server (Back-end)

* Node.js - Ambiente de execução.

* Express - Framework web para a API.

* node-postgres (pg) - Driver de conexão com o banco.

### Infraestrutura & Banco

* PostgreSQL - Banco de dados relacional.

* Docker - Orquestração de containers.

## ⚙️ Como Executar

### 1. Preparar o Banco de Dados

Navegue até a pasta backend e suba o container do banco:

``` bash
cd backend
docker-compose up -d
```

### 2. Iniciar o Back-end

Ainda na pasta backend, instale as dependências e rode o servidor em modo de desenvolvimento:

``` bash
npm install
npm run dev
```

### 3. Iniciar o Front-end

Navegue até a pasta frontend, instale as dependências e execute o app:

``` bash
cd ../frontend
flutter pub get
flutter run
```

## 📄 Licença

Este projeto está sob a licença **MIT**. Veja o arquivo LICENSE para mais detalhes.

## Desenvolvido por:
 João Pedro Araújo.
 Daniel Suzuki Naves.
 Luís Fernando Moreira Beani.
 Guilherme Teruichi Nishida. 
