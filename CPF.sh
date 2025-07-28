#!/data/data/com.termux/files/usr/bin/bash

# Cores ANSI
RED="\033[1;31m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
CYAN="\033[1;36m"
RESET="\033[0m"

ARQUIVO_SAIDA="CPF_VALIDOS.txt"

show_banner() {
  clear
  echo -e "${CYAN}"
  echo "╔════════════════════════════════════════════════════╗"
  echo "║       🚀 CONSULTA TURBO DE CPF - NOVA API          ║"
  echo "╚════════════════════════════════════════════════════╝"
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

  [[ -z "$RESP" || "$RESP" == "null" ]] && return

  # Detectar erro padrão
  if echo "$RESP" | jq -e '.erro? // empty' &>/dev/null; then
    return
  fi

  # Verifica se já está salvo
  grep -q "CPF: $CPF" "$ARQUIVO_SAIDA" 2>/dev/null && return

  BLOCO="CPF: $CPF\n"
  echo -e "${GREEN}[✓] Válido $CPF${RESET}"

  echo "$RESP" | jq -r 'to_entries[] | "\(.key | ascii_upcase): \(.value // "N/A")"' | while IFS=: read -r chave valor; do
    chave_formatada=$(echo "$chave" | sed 's/_/ /g' | awk '{ for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2)) }1')
    BLOCO="$BLOCO$chave_formatada: $valor\n"
  done

  BLOCO="$BLOCO------------------------------"
  printf "%b\n" "$BLOCO" >> "$ARQUIVO_SAIDA"
}

ler_cpfs_manual() {
  echo -e "${YELLOW}[!] Digite os CPFs, um por linha."
  echo "[!] Pressione ENTER 3x para iniciar a consulta.${RESET}"
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
  echo -e "  ${CYAN}[2]${RESET} Ler CPFs de arquivo .txt"
  echo
  read -p "Opção: " OPCAO

  case "$OPCAO" in
    1) ler_cpfs_manual ;;
    2) read -p "Nome do arquivo (ex: lista.txt): " ARQ && ler_cpfs_arquivo "$ARQ" ;;
    *) echo -e "${RED}[!] Opção inválida.${RESET}" && exit 1 ;;
  esac

  [ "${#CPFS[@]}" -eq 0 ] && echo -e "${RED}[!] Nenhum CPF fornecido.${RESET}" && exit 1

  echo -e "${GREEN}[+] Iniciando consultas turbo...${RESET}"
  for CPF in "${CPFS[@]}"; do
    valida_cpf_simples "$CPF" || {
      echo -e "${RED}[X] Ignorado CPF inválido: $CPF${RESET}"
      continue
    }
    echo -ne "${CYAN}[>] $CPF...${RESET} "
    RESP=$(curl -s --connect-timeout 2 --max-time 5 "https://valores-nu.it.com/consult/consulta.php?cpf=$CPF")
    processar_resposta "$CPF" "$RESP" &
  done
  wait
  echo -e "${GREEN}[✓] Consulta finalizada. Resultado salvo em:${RESET} ${CYAN}$ARQUIVO_SAIDA${RESET}"
}

main
