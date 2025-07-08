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
  echo "║         🔍 CONSULTAR CPF AUTOMÁTICO - EG WEBCODE       ║"
  echo "╚═══════════════════════════════════════════════════════╝"
  echo -e "${RESET}"
}

valida_cpf_simples() {
  [[ "$1" =~ ^([0-9])\1{10}$ ]] && return 1
  [[ ${#1} -ne 11 ]] && return 1
  return 0
}

processar_resposta() {
  local CPF="$1"
  local RESP="$2"

  echo -e "${BLUE}JSON bruto da resposta:${RESET}"
  echo "$RESP" | jq . || { echo -e "${RED}[!] JSON inválido.${RESET}"; return; }

  STATUS=$(echo "$RESP" | jq -r '.status // empty')
  [[ "$STATUS" != "200" ]] && {
    echo -e "${RED}[!] Resposta sem status 200.${RESET}"
    echo "$CPF" >> "$ARQUIVO_INVALIDOS"
    return
  }

  grep -q "^CPF: $CPF$" "$ARQUIVO_VALIDOS" 2>/dev/null && return

  DATA_JSON=$(echo "$RESP" | jq '.dados[0]')
  [ -z "$DATA_JSON" ] && {
    echo -e "${RED}[!] Nenhum dado encontrado para o CPF $CPF.${RESET}"
    echo "$CPF" >> "$ARQUIVO_INVALIDOS"
    return
  }

  BLOCO="CPF: $CPF\n"
  echo -e "${GREEN}[+] Dados extraídos:${RESET}"

  # Extração dinâmica dos campos do JSON
  echo "$DATA_JSON" | jq -r 'to_entries[] | "\(.key | ascii_upcase): \(.value // "N/A")"' | while IFS=: read -r chave valor; do
    chave_formatada=$(echo "$chave" | sed 's/_/ /g' | awk '{ for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2)) }1')
    BLOCO="$BLOCO$chave_formatada: $valor\n"
    echo -e "${CYAN}$chave_formatada:${RESET} $valor"
  done

  BLOCO="$BLOCO------------------------------"
  printf "%b\n" "$BLOCO" >> "$ARQUIVO_VALIDOS"
  echo
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
  echo -e "${RED}[!] Este script é apenas para fins educacionais.${RESET}"
  echo
  echo -e "${BLUE}Escolha uma opção:${RESET}"
  echo -e "  ${CYAN}[1]${RESET} Digitar CPF manualmente"
  echo -e "  ${CYAN}[2]${RESET} Ler CPFs de arquivo .txt (no mesmo diretório)"
  echo
  read -p "Opção: " OPCAO

  case "$OPCAO" in
    1) ler_cpfs_manual ;;
    2) read -p "Digite o nome do arquivo (ex: lista.txt): " ARQ && ler_cpfs_arquivo "$ARQ" ;;
    *) echo -e "${RED}[!] Opção inválida. Saindo.${RESET}" && exit 1 ;;
  esac

  [ "${#CPFS[@]}" -eq 0 ] && echo -e "${RED}[!] Nenhum CPF para consultar. Saindo.${RESET}" && exit 1

  TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
  ARQUIVO_VALIDOS="CPF_VALIDOS_$TIMESTAMP.txt"
  ARQUIVO_INVALIDOS="CPF_INVALIDOS_$TIMESTAMP.txt"

  echo -e "${GREEN}[+] Iniciando consultas (${#CPFS[@]} CPFs)...${RESET}"
  count=0
  for CPF in "${CPFS[@]}"; do
    ((count++))
    valida_cpf_simples "$CPF" || {
      echo -e "${RED}[$count] CPF inválido ou repetido: $CPF${RESET}"
      echo "$CPF" >> "$ARQUIVO_INVALIDOS"
      continue
    }

    echo -e "${YELLOW}[$count] Consultando CPF: $CPF${RESET}"
    RESP=$(curl -s --connect-timeout 5 --max-time 10 --retry 2 "https://vazamentodados.com/api/dados.php?cpf=$CPF")
    processar_resposta "$CPF" "$RESP"
  done

  echo -e "${GREEN}[✓] Consulta finalizada!${RESET}"
  echo -e "${GREEN}[+] Resultados salvos em:${RESET} ${CYAN}$ARQUIVO_VALIDOS${RESET}"
  echo -e "${YELLOW}[+] CPFs inválidos ou não encontrados em:${RESET} ${CYAN}$ARQUIVO_INVALIDOS${RESET}"
}

main
