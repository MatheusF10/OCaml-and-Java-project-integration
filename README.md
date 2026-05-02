
# Projeto de Integração Java-OCaml (e-Fólio)

Este projeto consiste numa aplicação Java que utiliza uma interface gráfica (Swing/Terminal) para comunicar com um motor de lógica desenvolvido em OCaml. O sistema permite a gestão e consulta de uma base de dados de alunos.

## 📁 Estrutura do Projeto

```text

├── bin/ # Recursos e binários

│      ├── main.ml # Código fonte OCaml

│      ├── database_26.pl # Base de dados (Prolog/Texto)

│      └── main.exe # Executável (gerado automaticamente)

├── src/ # Código fonte Java

│      ├── Main.java # Ponto de entrada e orquestração

│      ├── Interface.java # Gestão da UI

│      └── IntegratorOCaml.java # Ponte de comunicação ProcessBuilder

├── setup.sh

└── README.md # Instruções de utilização
```

## 🛠️ Pré-requisitos

### Para que o projeto funcione corretamente, o ambiente deve ter instalado:  

* Linux ou WSL

* Java JDK 17+

* OCaml Compiler (ocamlc)  

* Biblioteca str do OCaml (geralmente incluída na instalação padrão)

#### Comando recomendado: 
```bash 
sudo apt update sudo apt install default-jdk ocaml 
```

## 🚀 Execução do projeto

### Execução Rápida (Linux) Para facilitar a execução do projeto, foi incluido um script .sh que verifica os pré-requisitos e compila o projeto automaticamente, pelo S.O

```bash 
chmod +x setup.sh ./setup.sh
```