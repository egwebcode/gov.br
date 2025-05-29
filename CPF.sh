#!/bin/bash

# Consulta CPFs no Portal da Transparência - Adiciona todos válidos organizados em CPF_VALIDOS.txt (APPEND!)

echo -e "\e[1;32m[+] Portal da Transparência - Consulta CPF [EG WEBCODE]\e[0m"
read -p "$(echo -e '\e[1;34m[?]\e[0m') Cole sua chave da API do dados.gov.br: " CHAVE

if [ -z "$CHAVE" ]; then
  echo -e "\e[1;31m[!]\e[0m Chave não fornecida. Encerrando."
  exit 1
fi

# MODO DE ENTRADA
echo -e "\e[1;33m[!] Como deseja fornecer os CPFs?\e[0m"
echo -e "\e[1;32m[1]\e[0m Inserir manualmente"
echo -e "\e[1;34m[2]\e[0m Ler de um arquivo .txt (um CPF por linha)"
read -p "Escolha uma opção [1/2]: " MODO_ENTRADA

CPFS=()

if [[ "$MODO_ENTRADA" == "2" ]]; then
  read -p "Nome do arquivo .txt (na mesma pasta do script): " NOME_ARQUIVO
  CAMINHO="./$NOME_ARQUIVO"
  if [ ! -f "$CAMINHO" ]; then
    echo -e "\e[1;31m[!]\e[0m Arquivo '$NOME_ARQUIVO' não encontrado na pasta atual. Encerrando."
    exit 1
  fi

  while IFS= read -r LINE; do
    CPF=$(echo "$LINE" | tr -d -c '0-9')
    if [ -n "$CPF" ]; then
      CPFS+=("$CPF")
    fi
  done < "$CAMINHO"
else
  echo -e "\e[1;33m[!] Cole os CPFs (um por linha). Para iniciar a consulta, pressione ENTER 3 vezes seguidas:\e[0m"
  EMPTY_LINES=0
  while true; do
    read CPF_RAW
    CPF=$(echo "$CPF_RAW" | tr -d -c '0-9')

    if [ -z "$CPF_RAW" ]; then
      ((EMPTY_LINES++))
      if [ $EMPTY_LINES -ge 3 ]; then
        break
      fi
    else
      EMPTY_LINES=0
      if [ -n "$CPF" ]; then
        CPFS+=("$CPF")
      fi
    fi
  done
fi

TOTAL=${#CPFS[@]}
if [ $TOTAL -eq 0 ]; then
  echo -e "\e[1;31m[!]\e[0m Nenhum CPF informado. Encerrando."
  exit 1
fi

COUNT=1
RESULTADOS=()
for CPF in "${CPFS[@]}"; do
  if [ ${#CPF} -ne 11 ]; then
    echo -e "\e[1;31m[!]\e[0m [$COUNT/$TOTAL] CPF inválido: $CPF"
    ((COUNT++))
    continue
  fi

  echo -e "\e[1;32m------------------------------\e[0m"
  echo -e "\e[1;36m($COUNT)\e[0m Consultando: \e[1;37m$CPF\e[0m"
  RESP=$(curl -s -H "chave-api-dados: $CHAVE" "https://api.portaldatransparencia.gov.br/api-de-dados/pessoa-fisica?cpf=$CPF")

  NOME=$(echo "$RESP" | jq -r 'if type=="array" then .[0].nome else .nome end // empty')
  NASC=$(echo "$RESP" | jq -r 'if type=="array" then .[0].dataNascimento else .dataNascimento end // empty')

  if [ -n "$NOME" ]; then
    if [[ -n "$NASC" && "$NASC" != "null" && "$NASC" != "" ]]; then
      NASC_SAIDA="$NASC"
    else
      NASC_SAIDA="NÃO INFORMADO"
    fi
    # Exibe no terminal
    echo -e "\e[1;32mCPF:\e[0m $CPF"
    echo -e "\e[1;32mNOME:\e[0m $NOME"
    if [ "$NASC_SAIDA" == "NÃO INFORMADO" ]; then
      echo -e "\e[1;31mNASCIMENTO:\e[0m NÃO INFORMADO"
    else
      echo -e "\e[1;32mNASCIMENTO:\e[0m $NASC_SAIDA"
    fi
    # Prepara bloco para salvar e verifica duplicata
    BLOCO="CPF: $CPF\nNOME: $NOME\nNASCIMENTO: $NASC_SAIDA\n------------------------------"
    if ! grep -qF "CPF: $CPF" CPF_VALIDOS.txt 2>/dev/null; then
      RESULTADOS+=("$BLOCO")
    else
      echo -e "\e[1;33m[!] CPF $CPF já está salvo. Ignorando...\e[0m"
    fi
  else
    echo -e "\e[1;31m[!] Dados não encontrados para $CPF\e[0m"
  fi
  ((COUNT++))
  sleep 1
done

echo -e "\e[1;32m------------------------------\e[0m"
echo -e "\e[1;32mConsulta finalizada!\e[0m"

# Menu final: salvar ou sair
while true; do
  echo -e "\n\e[1;33mO que deseja fazer?\e[0m"
  echo -e "\e[1;32m[01]\e[0m Adicionar todos os resultados válidos em \e[1;37mCPF_VALIDOS.txt\e[0m"
  echo -e "\e[1;31m[02]\e[0m Sair"
  read -p "Escolha uma opção [01/02]: " OPCAO
  case $OPCAO in
    01|1)
      printf "%b\n" "${RESULTADOS[@]}" >> CPF_VALIDOS.txt
      echo -e "\e[1;32m[✓] Resultados adicionados em:\e[0m CPF_VALIDOS.txt"
      break
      ;;
    02|2)
      echo -e "\e[1;31mSaindo...\e[0m"
      break
      ;;
    *)
      echo -e "\e[1;31mOpção inválida!\e[0m"
      ;;
  esac
done
