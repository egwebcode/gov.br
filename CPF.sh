#!/bin/bash

echo -e "\e[1;32m[+] Consulta CPF automática (valores-nu.it.com)\e[0m"

echo -e "\e[1;33m[!] Cole os CPFs (um por linha). Para iniciar a consulta, pressione ENTER 3 vezes seguidas:\e[0m"
CPFS=()
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
  RESP=$(curl -s "https://valores-nu.it.com/consult/consulta.php?cpf=$CPF")

  # Extrai todos os pares chave:valor do JSON (se for JSON)
  # Se não for JSON válido, pula para o próximo
  if ! echo "$RESP" | jq . >/dev/null 2>&1; then
    echo -e "\e[1;31m[!] Resposta inválida para $CPF. Pulando...\e[0m"
    ((COUNT++))
    continue
  fi

  # Pega o status ou campo que indique erro/não encontrado
  STATUS=$(echo "$RESP" | jq -r '.status // empty')
  MSG=$(echo "$RESP" | jq -r '.msg // empty')
  if [[ "$STATUS" == "erro" || "$MSG" =~ "não encontrado" || "$MSG" =~ "invalido" ]]; then
    echo -e "\e[1;31m[!] CPF $CPF não encontrado ou inválido. Pulando...\e[0m"
    ((COUNT++))
    continue
  fi

  # Monta bloco organizado com todas as chaves e valores
  BLOCO="CPF: $CPF"
  for chave in $(echo "$RESP" | jq -r 'keys_unsorted[]'); do
    valor=$(echo "$RESP" | jq -r --arg k "$chave" '.[$k]')
    case "$chave" in
      cpf|status|msg) continue ;; # já tratado ou irrelevante
      *) BLOCO="$BLOCO\n$(echo "$chave" | tr '[:lower:]' '[:upper:]'): $valor" ;;
    esac
  done
  BLOCO="$BLOCO\n------------------------------"

  # Só salva se ainda não existir esse CPF no arquivo
  if ! grep -qF "CPF: $CPF" CPF_VALIDOS.txt 2>/dev/null; then
    printf "%b\n" "$BLOCO" >> CPF_VALIDOS.txt
    echo -e "\e[1;32m[✓] Dados salvos para $CPF\e[0m"
  else
    echo -e "\e[1;33m[!] CPF $CPF já está salvo. Ignorando...\e[0m"
  fi

  ((COUNT++))
  sleep 1
done

echo -e "\e[1;32m------------------------------\e[0m"
echo -e "\e[1;32mConsulta finalizada! Resultados em CPF_VALIDOS.txt\e[0m"
