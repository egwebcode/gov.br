#!/data/data/com.termux/files/usr/bin/bash

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
  grep -q "^CPF: $CPF\$" CPF_VALIDOS.txt 2>/dev/null && return

  # Extrai dados do JSON (priorizando DADOS[0])
  if echo "$RESP" | jq 'has("DADOS")' | grep -q true; then
    local DATA_JSON=$(echo "$RESP" | jq '.DADOS[0]')
  else
    local DATA_JSON="$RESP"
  fi

  # Pega cada campo (se existir) e salva em variáveis
  NOME=$(echo "$DATA_JSON" | jq -r '.NOME // empty')
  MAE=$(echo "$DATA_JSON" | jq -r '.NOMEMAE // empty')
  PAI=$(echo "$DATA_JSON" | jq -r '.NOMEPAI // empty')
  NASC=$(echo "$DATA_JSON" | jq -r '.NASC // empty')
  RG=$(echo "$DATA_JSON" | jq -r '.RG // empty')
  ORGAOEMISSOR=$(echo "$DATA_JSON" | jq -r '.ORGAOEMISSOR // empty')
  UFEMISSAO=$(echo "$DATA_JSON" | jq -r '.UFEMISSAO // empty')
  SEXO=$(echo "$DATA_JSON" | jq -r '.SEXO // empty')
  RENDA=$(echo "$DATA_JSON" | jq -r '.RENDA // empty')
  TITULOELEITOR=$(echo "$DATA_JSON" | jq -r '.TITULOELEITOR // empty')
  SO=$(echo "$DATA_JSON" | jq -r '.SO // empty')

  BLOCO="CPF: $CPF"
  [ -n "$NOME" ] && BLOCO="$BLOCO\nNOME: $NOME"
  [ -n "$MAE" ] && BLOCO="$BLOCO\nMÃE: $MAE"
  [ -n "$PAI" ] && BLOCO="$BLOCO\nPAI: $PAI"
  [ -n "$NASC" ] && BLOCO="$BLOCO\nDATA NASCIMENTO: $NASC"
  [ -n "$RG" ] && BLOCO="$BLOCO\nRG: $RG"
  [ -n "$ORGAOEMISSOR" ] && BLOCO="$BLOCO\nORGÃO EMISSOR: $ORGAOEMISSOR"
  [ -n "$UFEMISSAO" ] && BLOCO="$BLOCO\nUF EMISSÃO: $UFEMISSAO"
  [ -n "$SEXO" ] && BLOCO="$BLOCO\nSEXO: $SEXO"
  [ -n "$RENDA" ] && BLOCO="$BLOCO\nRENDA: $RENDA"
  [ -n "$TITULOELEITOR" ] && BLOCO="$BLOCO\nTÍTULO ELEITOR: $TITULOELEITOR"
  [ -n "$SO" ] && BLOCO="$BLOCO\nSISTEMA OPERACIONAL: $SO"

  BLOCO="$BLOCO\n------------------------------"

  echo -e "$BLOCO"
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
