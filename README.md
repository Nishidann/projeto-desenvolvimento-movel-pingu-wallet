# PINGU WALLET - MOBILE

Aplicação de gestão financeira pessoal desenvolvida em **Flutter**, focada em oferecer uma interface fluida para controle de receitas, despesas e metas financeiras.

## 📝 Sobre o Projeto
O Pingu Wallet ajuda estudantes e usuários a manterem o controle total sobre suas finanças. O front-end utiliza o **Material 3** para garantir uma interface moderna, responsiva e alinhada com a identidade visual **Azul Ártico (#1E3A8A)**.

## 🚀 Funcionalidades
* **Dashboard Ártico**: Visualização de saldo total e gráfico de evolução patrimonial dinâmico (via `fl_chart`).
* **Relatórios Inteligentes**: Análise de gastos e receitas por categoria com detalhamento interativo.
* **Metas e Objetivos**: Gestão de economias com histórico de aportes detalhado.
* **Autenticação**: Fluxo seguro via JWT, armazenado localmente com `SharedPreferences`.

## 🛠️ Tecnologias
* **Framework**: Flutter (Dart)
* **Design**: Material 3
* **Conectividade**: `http` (Consumo de API RESTful)

## ⚙️ Como Executar
1. Certifique-se de ter o Flutter SDK instalado.
2. Clone este repositório.
3. No terminal, na raiz do projeto:
   ```bash
   flutter pub get
   flutter run
