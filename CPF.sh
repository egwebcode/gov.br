#!/data/data/com.termux/files/usr/bin/bash

echo
echo "=============================================="
echo "  [+] CONSULTA CPF AUTOMÁTICA - EG WEBCODE"
echo "=============================================="
echo
echo "[!] Cole os CPFs (um por linha)."
echo "[!] Para iniciar a consulta, pressione ENTER 3 vezes seguidas:"
echo

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

[ "${#CPFS[@]}" -eq 0 ] && echo "[!] Nenhum CPF informado. Encerrando." && exit 1

for CPF in "${CPFS[@]}"; do
  [ ${#CPF} -ne 11 ] && continue

  RESP=$(curl -s "https://valores-nu.it.com/consult/consulta.php?cpf=$CPF")
  [ -z "$RESP" ] && continue

  echo "$RESP" | jq . >/dev/null 2>&1 || continue

  STATUS=$(echo "$RESP" | jq -r '.status // empty')
  MSG=$(echo "$RESP" | jq -r '.msg // empty')
  [[ "$STATUS" == "erro" || "$MSG" =~ "nao encontrado" || "$MSG" =~ "invalido" ]] && continue

  grep -q "CPF: $CPF" CPF_VALIDOS.txt 2>/dev/null && continue

  if echo "$RESP" | jq 'has("DADOS")' | grep -q true; then
    FIELDS=$(echo "$RESP" | jq -r '.DADOS[0] | to_entries[] | "
