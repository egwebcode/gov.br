#!/bin/bash

# Script "hacker style" para consultar CPF, nome e nascimento no Portal da Transparência
# Exibe o CPF completo, nome e data de nascimento, separados por linhas e numeração

echo -e "\e[1;32m[+] Portal da Transparência - Consulta CPF [HACKER STYLE]\e[0m"
read -p "$(echo -e '\e[1;34m[?]\e[0m') Cole sua chave da API do dados.gov.br: " CHAVE

if [ -z "$CHAVE" ]; then
  echo -e "\e[1;31m[!]\e[0m Chave não fornecida. Encerrando."
  exit 1
fi

echo -e "\e[1;33m[!] Cole os CPFs (um por linha, tecle Ctrl+D para finalizar):\e[0m"

CPFS=()
while read CPF; do
  CPF=$(echo "$CPF" | tr -d -c '0-9')
  if [ -n "$CPF" ]; then
    CPFS+=("$CPF")
  fi
done

TOTAL=${#CPFS[@]}
if [ $TOTAL -eq 0 ]; then
  echo -e "\e[1;31m[!]\e[0m Nenhum CPF informado. Encerrando."
  exit 1
fi

COUNT=1
for CPF in "${CPFS[@]}"; do
  if [ ${#CPF} -ne 11 ]; then
    echo -e "\e[1;31m[!]\e[0m [$COUNT/$TOTAL] CPF inválido: $CPF"
    ((COUNT++))
    continue
  fi

  echo -e "\e[1;32m------------------------------\e[0m"
  echo -e "\e[1;36m($COUNT)\e[0m Consultando: \e[1;37m$CPF\e[0m"
  RESP=$(curl -s -H "chave-api-dados: $CHAVE" "https://api.portaldatransparencia.gov.br/api-de-dados/pessoa-fisica?cpf=$CPF")
  
  # Extrai nome e nascimento (pode ser nulo se não vier no JSON)
  NOME=$(echo "$RESP" | jq -r 'if type=="array" then .[0].nome else .nome end // empty')
  NASC=$(echo "$RESP" | jq -r 'if type=="array" then .[0].dataNascimento else .dataNascimento end // empty')

  if [ -n "$NOME" ]; then
    echo -e "\e[1;32mCPF:\e[0m $CPF"
    echo -e "\e[1;32mNOME:\e[0m $NOME"
    if [ -n "$NASC" ] && [ "$NASC" != "null" ]; then
      echo -e "\e[1;32mNASCIMENTO:\e[0m $NASC"
    else
      echo -e "\e[1;31mNASCIMENTO:\e[0m Não informado"
    fi
  else
    echo -e "\e[1;31m[!] Dados não encontrados para $CPF\e[0m"
  fi
  ((COUNT++))
  sleep 1
done
echo -e "\e[1;32m------------------------------\e[0m"
echo -e "\e[1;32mConsulta finalizada!\e[0m"
