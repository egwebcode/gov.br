#!/bin/bash

# Consulta CPFs no Portal da Transparência - Adiciona todos válidos organizados em CPF_VALIDOS.txt (APPEND!)

echo -e "\e[1;32m[+] Portal da Transparência - Consulta CPF [EG WEBCODE]\e[0m"
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
