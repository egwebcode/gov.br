#!/bin/bash

# Script interativo para consultar CPFs na API do Portal da Transparência
# Requer: curl, jq

echo "=== Consulta de CPFs no Portal da Transparência ==="
read -p "Cole sua chave da API do dados.gov.br: " CHAVE

if [ -z "$CHAVE" ]; then
  echo "Chave não fornecida. Encerrando."
  exit 1
fi

echo "Cole os CPFs que deseja consultar (um por linha)."
echo "Quando terminar, pressione Ctrl+D (no final da lista):"
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

mkdir -p resultados

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
    echo "===> Resultado encontrado para $CPF:"
    echo "$RESP" | jq .
    echo "$RESP" > "resultados/$CPF.json"
  else
    echo "Nenhuma informação pública encontrada para $CPF."
  fi
  ((COUNT++))
  sleep 1
done

echo "Consulta finalizada. Resultados salvos em ./resultados/"