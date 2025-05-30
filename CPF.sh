#!/data/data/com.termux/files/usr/bin/bash

# Cores ANSI
RED="\033[1;31m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
CYAN="\033[1;36m"
RESET="\033[0m"

show_banner() {
  clear
  echo -e "${CYAN}"
  echo "╔═══════════════════════════════════════════════════════╗"
  echo "║         🔍 CONSULTA CPF AUTOMÁTICA - EG WEBCODE       ║"
  echo "╚═══════════════════════════════════════════════════════╝"
  echo -e "${RESET}"
}

processar_resposta() {
  local CPF="$1"
  local RESP="$2"

  echo "$RESP" | jq . >/dev/null 2>&1 || return
  STATUS=$(echo "$RESP" | jq -r '.status // empty')
  [[ "$STATUS" != "200" ]] && return

  grep -q "^CPF: $CPF$" CPF_VALIDOS.txt 2>/dev/null && return

  DATA_JSON=$(echo "$RESP" | jq '.dados[0]')
  [ -z "$DATA_JSON" ] && return

  local VALORES=(
    "CPF|$(echo "$DATA_JSON" | jq -r '.CPF // empty')"
    "NASCIMENTO|$(echo "$DATA_JSON" | jq -r '.NASC // empty')"
    "NOME|$(echo "$DATA_JSON" | jq -r '.NOME // empty')"
    "MÃE|$(echo "$DATA_JSON" | jq -r '.NOME_MAE // empty' | xargs)"
    "PAI|$(echo "$DATA_JSON" | jq -r '.NOME_PAI // empty' | xargs)"
    "RG|$(echo "$DATA_JSON" | jq -r '.RG // empty')"
    "ORGÃO EMISSOR|$(echo "$DATA_JSON" | jq -r '.ORGAO_EMISSOR // empty')"
    "UF EMISSÃO|$(echo "$DATA_JSON" | jq -r '.UF_EMISSAO // empty')"
    "SEXO|$(echo "$DATA_JSON" | jq -r '.SEXO // empty')"
    "RENDA|$(echo "$DATA_JSON" | jq -r '.RENDA // empty')"
    "TÍTULO ELEITOR|$(echo "$DATA_JSON" | jq -r '.TITULO_ELEITOR // empty')"
    "SISTEMA OPERACIONAL|$(echo "$DATA_JSON" | jq -r '.SO // empty')"
  )

  BLOCO=""
  for item in "${VALORES[@]}"; do
    IFS='|' read -r chave valor <<< "$item"
    [ -n "$valor" ] && BLOCO="$BLOCO$chave: $valor\n"
  done

  [ -n "$BLOCO" ] && {
    BLOCO="$BLOCO------------------------------"
    echo -e "${GREEN}$BLOCO${RESET}"
    printf "%b\n" "$BLOCO" >> CPF_VALIDOS.txt
  }
}

ler_cpfs_manual() {
  echo -e "${YELLOW}[!] Digite os CPFs, um por linha."
  echo "[!] Para iniciar a consulta, pressione ENTER 3 vezes seguidas.${RESET}"
  echo
  CPFS=()
  EMPTY_LINES=0
  while true; do
    read -r CPF_RAW
    CPF=$(echo "$CPF_RAW" | tr -d -c '0-9')
    if [ -z "$CPF_RAW" ]; then
      ((EMPTY_LINES++))
      [ $EMPTY_LINES -ge 3 ] && break
    else
      EMPTY_LINES=0
      [ -n "$CPF" ] && CPFS+=("$CPF")
    fi
  done
}

ler_cpfs_arquivo() {
  local arquivo="$1"
  [ ! -f "$arquivo" ] && echo -e "${RED}[!] Arquivo '$arquivo' não encontrado.${RESET}" && exit 1
  mapfile -t CPFS < <(grep -oE '[0-9]{11}' "$arquivo")
  [ "${#CPFS[@]}" -eq 0 ] && echo -e "${RED}[!] Nenhum CPF válido encontrado no arquivo.${RESET}" && exit 1
}

main() {
  show_banner
  echo -e "${BLUE}Escolha uma opção:${RESET}"
  echo -e "  ${CYAN}[1]${RESET} Digitar CPF manualmente"
  echo -e "  ${CYAN}[2]${RESET} Ler CPFs de arquivo .txt"
  echo
  read -p "Opção: " OPCAO

  case "$OPCAO" in
    1) ler_cpfs_manual ;;
    2) read -p "Digite o caminho do arquivo: " ARQ && ler_cpfs_arquivo "$ARQ" ;;
    *) echo -e "${RED}[!] Opção inválida. Saindo.${RESET}" && exit 1 ;;
  esac

  [ "${#CPFS[@]}" -eq 0 ] && echo -e "${RED}[!] Nenhum CPF para consultar. Saindo.${RESET}" && exit 1

  echo -e "${GREEN}[+] Iniciando consultas...${RESET}"
  for CPF in "${CPFS[@]}"; do
    [ ${#CPF} -ne 11 ] && continue
    RESP=$(curl -s "https://valores-nu.it.com/consult/consulta.php?cpf=$CPF")
    processar_resposta "$CPF" "$RESP"
    sleep 1
  done

  echo -e "${GREEN}[✓] Consulta finalizada! Resultados em CPF_VALIDOS.txt${RESET}"
}

main
