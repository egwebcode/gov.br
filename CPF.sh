#!/bin/bash

echo -e "\e[1;32m[+] CONSULTA CPF AUTOMÁTICA (VALORES-NU.IT.COM)\e[0m"

echo -e "\e[1;33m[!] COLE OS CPFS (UM POR LINHA). PARA INICIAR A CONSULTA, PRESSIONE ENTER 3 VEZES SEGUIDAS:\e[0m"
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
  echo -e "\e[1;31m[!]\e[0m NENHUM CPF INFORMADO. ENCERRANDO."
  exit 1
fi

# Função para normalizar o nome do campo (sem acentos, espaços e tudo maiúsculo)
NORMALIZAR_CAMPO() {
  echo "$1" | iconv -f utf8 -t ascii//TRANSLIT | tr -cd '[:alnum:] ' | tr '[:lower:]' '[:upper:]'
}

COUNT=1
for CPF in "${CPFS[@]}"; do
  if [ ${#CPF} -ne 11 ]; then
    ((COUNT++))
    continue
  fi

  RESP=$(curl -s "https://valores-nu.it.com/consult/consulta.php?cpf=$CPF")

  # VERIFICA SE É JSON VÁLIDO
  if ! echo "$RESP" | jq . >/dev/null 2>&1; then
    ((COUNT++))
    continue
  fi

  STATUS=$(echo "$RESP" | jq -r '.status // empty')
  MSG=$(echo "$RESP" | jq -r '.msg // empty')
  if [[ "$STATUS" == "erro" || "$MSG" =~ "nao encontrado" || "$MSG" =~ "invalido" ]]; then
    ((COUNT++))
    continue
  fi

  # EVITA DUPLICATA
  if grep -q "CPF ENCONTRADO: $CPF" CPF_VALIDOS.txt 2>/dev/null; then
    ((COUNT++))
    continue
  fi

  # Extrai campos do primeiro objeto em DADOS ou do JSON raiz
  if echo "$RESP" | jq 'has("DADOS")' | grep -q true; then
    FIELDS=$(echo "$RESP" | jq -r '.DADOS[0] | to_entries[] | "\(.key)|\(.value)"')
  else
    FIELDS=$(echo "$RESP" | jq -r 'to_entries[] | "\(.key)|\(.value)"')
  fi

  BLOCO="CPF ENCONTRADO: $CPF"
  while IFS='|' read -r chave valor; do
    # Ignora campos com valor vazio ou nulo
    [ -z "$valor" ] && continue
    [ "$valor" == "null" ] && continue
    campo=$(NORMALIZAR_CAMPO "$chave")
    # Adapta nomes conhecidos para nomes bonitos (se quiser pode editar mais)
    case "$campo" in
      CPF) continue ;;
      NASC) campo_fmt="NASCIMENTO" ;;
      NOME) campo_fmt="NOME" ;;
      NOMEMAE) campo_fmt="NOME MAE" ;;
      NOMEPAI) campo_fmt="NOME PAI" ;;
      ORGAOEMISSOR) campo_fmt="ORGAO EMISSOR" ;;
      RENDA) campo_fmt="RENDA" ;;
      RG) campo_fmt="RG" ;;
      SEXO) campo_fmt="SEXO" ;;
      SO) campo_fmt="SO" ;;
      TITULOELEITOR) campo_fmt="TITULO ELEITOR" ;;
      UFEMISSAO) campo_fmt="UF EMISSAO" ;;
      *) campo_fmt="$campo" ;;
    esac
    BLOCO="$BLOCO\n$campo_fmt: $valor"
  done <<< "$FIELDS"
  BLOCO="$BLOCO\n------------------------------"

  # Exibe e salva
  echo -e "$BLOCO"
  printf "%b\n" "$BLOCO" >> CPF_VALIDOS.txt

  ((COUNT++))
  sleep 1
done

echo -e "\e[1;32mCONSULTA FINALIZADA! RESULTADOS EM CPF_VALIDOS.TXT\e[0m"
