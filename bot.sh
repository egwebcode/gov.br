#!/bin/bash

# Consulta CPF no Portal da Transparência e mostra o campo "cpf" mascarado corretamente

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

# Função para mascarar CPF como NNN.***.***-NN
mascara_cpf() {
  local cpf="$1"
  echo "${cpf:0:3}.***.***-${cpf:9:2}"
}

COUNT=1
for CPF in "${CPFS[@]}"; do
  if [ ${#CPF} -ne 11 ]; then
    echo "[$COUNT/$TOTAL] CPF inválido: $CPF"
    ((COUNT++))
    continue
  fi
  MASKED=$(mascara_cpf "$CPF")
  echo "[$COUNT/$TOTAL] Consultando $MASKED..."
  RESP=$(curl -s -H "chave-api-dados: $CHAVE" "https://api.portaldatransparencia.gov.br/api-de-dados/pessoa-fisica?cpf=$CPF")
  if [ "$RESP" != "[]" ] && [ -n "$RESP" ]; then
    # Substitui valor do campo "cpf" pelo mascarado antes de exibir
    NEW_JSON=$(echo "$RESP" | jq --arg mcpf "$MASKED" 'if type=="array" then map(.cpf = $mcpf) else .cpf = $mcpf end')
    echo "===> Resultado para $MASKED:"
    echo "$NEW_JSON" | jq .
  else
    echo "Nenhuma informação pública encontrada para $MASKED."
  fi
  ((COUNT++))
  sleep 1
done

echo "Consulta finalizada."
