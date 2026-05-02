#!/bin/bash

# Terminal Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}===============================================${NC}"
echo -e "${BLUE}   Configuração e Execução: Projeto Java-OCaml ${NC}"
echo -e "${BLUE}===============================================${NC}"

# 1. Java Environment Verification (Compiler and Runtime)
echo -e "\n${BLUE}[1/4] A verificar o ambiente Java...${NC}"
if command -v javac &> /dev/null && command -v java &> /dev/null; then
    echo -e "${GREEN}  - Java OK: $(java -version 2>&1 | head -n 1)${NC}"
else
    echo -e "${RED}  - Erro: JDK não encontrado. Por favor, instale o Java 17+.${NC}"
    exit 1
fi

# 2. OCaml Environment Verification
echo -e "${BLUE}[2/4] A verificar o ambiente OCaml...${NC}"
if command -v ocamlc &> /dev/null; then
    echo -e "${GREEN}  - OCaml OK: versão $(ocamlc -version)${NC}"
else
    echo -e "${RED}  - Erro: Compilador OCaml (ocamlc) não encontrado.${NC}"
    echo -e "    Dica: Execute 'sudo apt install ocaml' no Ubuntu/Debian.${NC}"
    exit 1
fi

# 3. Clean and Prepare Build Directory
echo -e "${BLUE}[3/4] A preparar diretórios de compilação...${NC}"
# Remove old build artifacts to ensure a clean state
rm -rf out
mkdir -p out
echo -e "  - Diretório ./out criado e limpo."

# 4. Java Source Code Compilation
echo -e "${BLUE}[4/4] A compilar ficheiros fonte Java...${NC}"

# Compile Java sources
javac -d out src/*.java

compile_status=$?

# Check compilation result
if [ $compile_status -eq 0 ]; then
    echo -e "${GREEN}  - Compilação Java concluída com sucesso!${NC}"
    echo -e "\n${BLUE}===============================================${NC}"

    # Run the Java application once
    echo -e "${GREEN}A iniciar a aplicação...${NC}"
    java -cp out Main
    java_exit_code=$?
fi

# Check if OCaml binary exists
if [ $compile_status -eq 10 ]; then
    if [ -f "bin/main.exe" ]; then
        echo -e "${GREEN}  - Executável OCaml detectado com sucesso!${NC}"
    else
        echo -e "${RED}  - Inconsistência: Java reportou sucesso, mas o binário não existe.${NC}"
    fi
fi