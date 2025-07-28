#!/data/data/com.termux/files/usr/bin/bash

# Cores
RED="\033[1;31m"
GREEN="\033[1;32m"
CYAN="\033[1;36m"
RESET="\033[0m"

ARQUIVO_SAIDA="CPF_VALIDOS.txt"

show_banner() {
  clear
  echo -e "${CYAN}"
  echo "╔══════════════════════════════════════════════╗"
  echo "║     🚀 CONSULTA TURBO CPF - NOVA API        ║"
  echo "╚══════════════════════════════════════════════╝"
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
  [[ "$(echo "$RESP" | jq -r '.status')" != "200" ]] && return
  [[ "$(echo "$RESP" | jq -r '.dados[0].CPF')" != "$CPF" ]] && return

  # Evita duplicado
  grep -q "CPF: $CPF" "$ARQUIVO_SAIDA" 2>/dev/null && return

  local DADOS=$(echo "$RESP" | jq -r '.dados[0]')

  local NOME=$(echo "$DADOS" | jq -r '.NOME // "N/A"')
  local MAE=$(echo "$DADOS" | jq -r '.NOME_MAE // "N/A"')
  local PAI=$(echo "$DADOS" | jq -r '.NOME_PAI // "N/A"')
  local NASC=$(echo "$DADOS" | jq -r '.NASC // "N/A"')
  local SEXO=$(echo "$DADOS" | jq -r '.SEXO // "N/A"')
  local RG=$(echo "$DADOS" | jq -r '.RG // "N/A"')
  local EMISSOR=$(echo "$DADOS" | jq -r '.ORGAO_EMISSOR // "N/A"')
  local UF=$(echo "$DADOS" | jq -r '.UF_EMISSAO // "N/A"')
  local RENDA=$(echo "$DADOS" | jq -r '.RENDA // "N/A"')
  local TITULO=$(echo "$DADOS" | jq -r '.TITULO_ELEITOR // "N/A"')

  echo -e "${GREEN}[✓] $CPF ${RESET} - $NOME / $NASC / $SEXO / Renda: R$${RENDA}"

  {
    echo "------------------------------"
    echo "CPF: $CPF"
    echo "Nome: $NOME"
    echo "Nascimento: $NASC"
    echo "Sexo: $SEXO"
    echo "Nome da Mãe: $MAE"
    echo "Nome do Pai: $PAI"
    echo "RG: $RG"
    echo "Órgão Emissor: $EMISSOR"
    echo "UF de Emissão: $UF"
    echo "Renda: R$${RENDA}"
    echo "Título de Eleitor: $TITULO"
  } >> "$ARQUIVO_SAIDA"
}

ler_cpfs_manual() {
  echo -e "${CYAN}[!] Digite CPFs, um por linha. ENTER 3x para começar.${RESET}"
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
  [ "${#CPFS[@]}" -eq 0 ] && echo -e "${RED}[!] Nenhum CPF válido encontrado.${RESET}" && exit 1
}

main() {
  show_banner
  echo -e "${RED}[!] Uso educacional somente.${RESET}\n"
  echo -e "${CYAN}[1]${RESET} Digitar CPF manualmente"
  echo -e "${CYAN}[2]${RESET} Ler CPFs de arquivo"
  echo
  read -p "Opção: " OPCAO

  case "$OPCAO" in
    1) ler_cpfs_manual ;;
    2) read -p "Nome do arquivo: " ARQ && ler_cpfs_arquivo "$ARQ" ;;
    *) echo -e "${RED}[!] Opção inválida.${RESET}" && exit 1 ;;
  esac

  [ "${#CPFS[@]}" -eq 0 ] && echo -e "${RED}[!] Nenhum CPF fornecido.${RESET}" && exit 1

  echo -e "${GREEN}[+] Consultando...${RESET}"
  for CPF in "${CPFS[@]}"; do
    valida_cpf_simples "$CPF" || {
      echo -e "${RED}[X] Inválido: $CPF${RESET}"
      continue
    }
    RESP=$(curl -s --connect-timeout 2 --max-time 5 "https://valores-nu.it.com/consult/consulta.php?cpf=$CPF")
    processar_resposta "$CPF" "$RESP" &
  done
  wait
  echo -e "${CYAN}[✓] Tudo salvo em ${ARQUIVO_SAIDA}${RESET}"
}

main
