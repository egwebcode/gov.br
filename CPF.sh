#!/data/data/com.termux/files/usr/bin/bash

# Autor: EG WEBCODE
# Descrição: Consulta automática de CPFs

show_banner() {
  echo "=============================================="
  echo "    CONSULTA CPF AUTOMÁTICA - EG WEBCODE"
  echo "=============================================="
  echo
}

processar_resposta() {
  local CPF="$1"
  local RESP="$2"

  # Verifica JSON válido e sem erros
  echo "$RESP" | jq . >/dev/null 2>&1 || return
  local STATUS=$(echo "$RESP" | jq -r '.status // empty')
  local MSG=$(echo "$RESP" | jq -r '.msg // empty')
  [[ "$STATUS" == "erro" || "$MSG" =~ "nao encontrado" || "$MSG" =~ "invalido" ]] && return

  # Evita duplicatas no arquivo
  grep -q "CPF: $CPF" CPF_VALIDOS.txt 2>/dev/null && return

  # Extrai dados do JSON
  if echo "$RESP" | jq 'has("DADOS")' | grep -q true; then
    FIELDS=$(echo "$RESP" | jq -r '.DADOS[0] | to_entries[] | "\(.key)|\(.value)"')
  else
    FIELDS=$(echo "$RESP" | jq -r 'to_entries[] | "\(.key)|\(.value)"')
  fi

  local BLOCO="CPF: $CPF"
  declare -A CAMPOS=()

  while IFS='|' read -r chave valor; do
    [ -z "$valor" ] && continue
    [ "$valor" == "null" ] && continue

    local CHAVE_UC=$(echo "$chave" | tr '[:lower:]' '[:upper:]')
    case "$CHAVE_UC" in
      NOME) CAMPOS["NOME"]="$valor" ;;
      NOME_MAE) CAMPOS["MAE"]="$valor" ;;
      NOME_PAI) CAMPOS["PAI"]="$valor" ;;
      NASC) CAMPOS["DATA"]="$valor" ;;
      RG) CAMPOS["RG"]="$valor" ;;
      ORGAO_EMISSOR) CAMPOS["ORGAO EMISSOR"]="$valor" ;;
      UFE_MISSAO) CAMPOS["UF EMISSAO"]="$valor" ;;
      SEXO) CAMPOS["SEXO"]="$valor" ;;
      RENDA) CAMPOS["RENDA"]="$valor" ;;
      TITULO_ELEITOR) CAMPOS["TITULO ELEITOR"]="$valor" ;;
      SO) CAMPOS["SISTEMA OPERACIONAL"]="$valor" ;;
      *) 
        local CHAVE_LIMPA=$(echo "$CHAVE_UC" | tr -cd '[:alnum:] ')
        CAMPOS["$CHAVE_LIMPA"]="$valor"
        ;;
    esac
  done <<< "$FIELDS"

  # Ordem definida para exibir
  for key in "NOME" "MAE" "PAI" "DATA" "RG" "ORGAO EMISSOR" "UF EMISSAO" "SEXO" "RENDA" "TITULO ELEITOR" "SISTEMA OPERACIONAL"; do
    [ -n "${CAMPOS[$key]}" ] && BLOCO="$BLOCO\n$key: ${CAMPOS[$key]}"
  done

  BLOCO="$BLOCO\n------------------------------"

  # Imprime no terminal
  echo -e "$BLOCO"
  # Grava no arquivo (append)
  printf "%b\n" "$BLOCO" >> CPF_VALIDOS.txt
}

ler_cpfs_manual() {
  echo "[!] Digite os CPFs, um por linha."
  echo "[!] Para iniciar a consulta, pressione ENTER 3 vezes seguidas."
  echo
  CPFS=()
  EMPTY_LINES=0
  while true; do
    read -r CPF_RAW
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
}

ler_cpfs_arquivo() {
  local arquivo="$1"
  if [ ! -f "$arquivo" ]; then
    echo "[!] Arquivo '$arquivo' não encontrado."
    exit 1
  fi

  # Extrai apenas CPFs com 11 dígitos
  mapfile -t CPFS < <(grep -oE '[0-9]{11}' "$arquivo")
  if [ "${#CPFS[@]}" -eq 0 ]; then
    echo "[!] Nenhum CPF válido encontrado no arquivo."
    exit 1
  fi
}

main() {
  show_banner

  echo "Escolha uma opção:"
  echo "  [1] Digitar CPF manualmente"
  echo "  [2] Ler CPFs de arquivo .txt"
  echo
  read -p "Opção: " OPCAO

  case "$OPCAO" in
    1)
      ler_cpfs_manual
      ;;
    2)
      read -p "Digite o caminho do arquivo: " ARQ
      ler_cpfs_arquivo "$ARQ"
      ;;
    *)
      echo "[!] Opção inválida. Saindo."
      exit 1
      ;;
  esac

  if [ "${#CPFS[@]}" -eq 0 ]; then
    echo "[!] Nenhum CPF para consultar. Saindo."
    exit 1
  fi

  echo
  echo "[+] Iniciando consultas..."
  echo

  for CPF in "${CPFS[@]}"; do
    [ ${#CPF} -ne 11 ] && continue
    RESP=$(curl -s "https://valores-nu.it.com/consult/consulta.php?cpf=$CPF")
    processar_resposta "$CPF" "$RESP"
    sleep 1
  done

  echo
  echo "[✓] Consulta finalizada! Resultados em CPF_VALIDOS.txt"
}

main
