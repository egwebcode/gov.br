#!/bin/bash

# Script simples e direto: consulta CPFs na API do Portal da Transparência e exibe o resultado no terminal

echo "=== Consulta de CPF (Portal da Transparência) ==="
read -p "Cole sua chave da API do dados.gov.br: " CHAVE

if [ -z "$CHAVE" ]; then
  echo "Chave não fornecida. Encerrando."
  exit 1
fi

echo "Cole os CPFs (um por linha, tecle Ctrl+D para finalizar):"

CPFS=()
while read CPF; do
  CPF=$(echo "$CPF" | tr -d -c '0-9')
  if [ -n "$CPF" ]; then
    CPFS+=("$CPF")
  fi
done

TOTAL=${#CPFS[@]}
if [ $TOTAL -eq 0 ]; then
  echo "Nenhum CPF informado. Encerrando."
  exit 1
fi

COUNT=1
for CPF in "${CPFS[@]}"; do
  if [ ${#CPF} -ne 11 ]; then
    echo "[$COUNT/$TOTAL] CPF inválido: $CPF"
    ((COUNT++))
    continue
  fi
  echo "[$COUNT/$TOTAL] Consultando $CPF..."
  RESP=$(curl -s -H "chave-api-dados: $CHAVE" "https://api.portaldatransparencia.gov.br/api-de-dados/pessoa-fisica?cpf=$CPF")
  if [ "$RESP" != "[]" ] && [ -n "$RESP" ]; then
    echo "===> Resultado para $CPF:"
    echo "$RESP" | jq .
  else
    echo "Nenhuma informação pública encontrada para $CPF."
  fi
  ((COUNT++))
  sleep 1
done

echo "Consulta finalizada."
