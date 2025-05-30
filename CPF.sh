#!/bin/bash

echo "[+] CONSULTA CPF AUTOMATICA (VALORES-NU.IT.COM)"

echo "[!] COLE OS CPFS (UM POR LINHA). PARA INICIAR A CONSULTA, PRESSIONE ENTER 3 VEZES SEGUIDAS:"
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

[ "${#CPFS[@]}" -eq 0 ] && echo "[!] NENHUM CPF INFORMADO. ENCERRANDO." && exit 1

for CPF in "${CPFS[@]}"; do
  [ ${#CPF} -ne 11 ] && continue

  RESP=$(curl -s "https://valores-nu.it.com/consult/consulta.php?cpf=$CPF")
  [ -z "$RESP" ] && continue

  # JSON válido?
  echo "$RESP" | jq . >/dev/null 2>&1 || continue

  STATUS=$(echo "$RESP" | jq -r '.status // empty')
  MSG=$(echo "$RESP" | jq -r '.msg // empty')
  [[ "$STATUS" == "erro" || "$MSG" =~ "nao encontrado" || "$MSG" =~ "invalido" ]] && continue

  grep -q "CPF ENCONTRADO: $CPF" CPF_VALIDOS.txt 2>/dev/null && continue

  # Extrai campos (prioriza .DADOS[0], senão pega tudo do JSON raiz)
  if echo "$RESP" | jq 'has("DADOS")' | grep -q true; then
    FIELDS=$(echo "$RESP" | jq -r '.DADOS[0] | to_entries[] | "\(.key)|\(.value)"')
  else
    FIELDS=$(echo "$RESP" | jq -r 'to_entries[] | "\(.key)|\(.value)"')
  fi

  BLOCO="CPF ENCONTRADO: $CPF"
  while IFS='|' read -r chave valor; do
    [ -z "$valor" ] && continue
    [ "$valor" == "null" ] && continue
    case "$(echo "$chave" | tr '[:lower:]' '[:upper:]')" in
      CPF) continue ;;
      NASC) campo="NASCIMENTO" ;;
      NOME) campo="NOME" ;;
      NOMEMAE) campo="NOME MAE" ;;
      NOMEPAI) campo="NOME PAI" ;;
      ORGAOEMISSOR) campo="ORGAO EMISSOR" ;;
      RENDA) campo="RENDA" ;;
      RG) campo="RG" ;;
      SEXO) campo="SEXO" ;;
      SO) campo="SO" ;;
      TITULOELEITOR) campo="TITULO ELEITOR" ;;
      UFEMISSAO) campo="UF EMISSAO" ;;
      *) campo=$(echo "$chave" | iconv -f utf8 -t ascii//TRANSLIT | tr -cd '[:alnum:] ' | tr '[:lower:]' '[:upper:]') ;;
    esac
    BLOCO="$BLOCO\n$campo: $valor"
  done <<< "$FIELDS"
  BLOCO="$BLOCO\n------------------------------"

  echo -e "$BLOCO"
  printf "%b\n" "$BLOCO" >> CPF_VALIDOS.txt
  sleep 1
done

echo "CONSULTA FINALIZADA! RESULTADOS EM CPF_VALIDOS.TXT"
