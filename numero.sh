#!/bin/bash

# Cores
BOLD="\e[1m"
RESET="\e[0m"
CYAN="\e[36m"
GREEN="\e[32m"
YELLOW="\e[33m"
RED="\e[31m"
BLUE="\e[34m"
MAGENTA="\e[35m"
UNDER="\e[4m"

clear
echo -e "${BOLD}${CYAN}╔═══════════════════════════════════════╗"
echo -e "║      EG WEBCODE LOCALIZADOR PRO      ║"
echo -e "╚═══════════════════════════════════════╝${RESET}"

echo ""
read -p "📲 Digite o número com código do país (ex: +5583991672088): " NUMERO
echo ""

TIMESTAMP=$(date +%s)
URL="https://pt.mobile-location.com/emulator/check?driver=geo&country=BR&provider=phone&uid=${NUMERO}&mode=undefined&_=${TIMESTAMP}"
USER_AGENT="Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Mobile Safari/537.36"

echo -e "${BOLD}${YELLOW}🔎 Consultando o número...${RESET}"
RESPONSE=$(curl -s -H "User-Agent: $USER_AGENT" \
                -H "Accept: */*" \
                -H "X-Requested-With: XMLHttpRequest" \
                "$URL")

if [[ -z "$RESPONSE" ]]; then
  echo -e "${RED}❌ Nenhuma resposta recebida. Verifique o número ou conexão.${RESET}"
  exit 1
fi

# Coletando dados
NUM_ID=$(echo "$RESPONSE" | jq -r '.result.uid')
NOME=$(echo "$RESPONSE" | jq -r '.result.first_name + " " + .result.last_name')
FOTO=$(echo "$RESPONSE" | jq -r '.result.photo.path')

PAIS=$(echo "$RESPONSE" | jq -r '.location.country_fullname')
REGIAO=$(echo "$RESPONSE" | jq -r '.location.region')
CIDADE=$(echo "$RESPONSE" | jq -r '.location.city // "Desconhecida"')
LAT=$(echo "$RESPONSE" | jq -r '.location.geo_city.latitude')
LON=$(echo "$RESPONSE" | jq -r '.location.geo_city.longitude')
LAT_RESUMO=$(echo "$RESPONSE" | jq -r '.location.geo_city.short_latitude')
LON_RESUMO=$(echo "$RESPONSE" | jq -r '.location.geo_city.short_longitude')

OPERADORA=$(echo "$RESPONSE" | jq -r '.location.operator')
ICON_OP=$(echo "$RESPONSE" | jq -r '.location.operator_icon')

TOTAL=$(echo "$RESPONSE" | jq -r '.volumetric.total')
MENSAGEM=$(echo "$RESPONSE" | jq -r '.volumetric.size_message')
MIDIA=$(echo "$RESPONSE" | jq -r '.volumetric.size_media')
CONTATOS=$(echo "$RESPONSE" | jq -r '.volumetric.size_contacts')

echo -e "${BOLD}${GREEN}📦 INFORMAÇÕES DO NÚMERO:${RESET}"
echo -e "  📱 Número UID: ${CYAN}$NUM_ID${RESET}"
echo -e "  👤 Nome:       ${CYAN}$NOME${RESET}"
echo -e "  🖼️ Foto:       ${UNDER}${BLUE}$FOTO${RESET}"
echo ""

echo -e "${BOLD}${MAGENTA}🗺️ LOCALIZAÇÃO:${RESET}"
echo -e "  🌍 País:       ${YELLOW}$PAIS${RESET}"
echo -e "  🗺️ Região:     ${YELLOW}$REGIAO${RESET}"
echo -e "  🏙️ Cidade:     ${YELLOW}$CIDADE${RESET}"
echo -e "  📍 Latitude:   ${GREEN}$LAT${RESET} (${LAT_RESUMO})"
echo -e "  📍 Longitude:  ${GREEN}$LON${RESET} (${LON_RESUMO})"
echo ""

echo -e "${BOLD}${BLUE}📡 OPERADORA:${RESET}"
echo -e "  🏢 Nome:       ${CYAN}$OPERADORA${RESET}"
echo -e "  🌐 Ícone:      ${UNDER}${BLUE}$ICON_OP${RESET}"
echo ""

echo -e "${BOLD}${YELLOW}📊 DADOS VOLUMÉTRICOS:${RESET}"
echo -e "  📦 Total:      ${GREEN}$TOTAL${RESET}"
echo -e "  ✉️ Mensagens:   ${CYAN}$MENSAGEM${RESET}"
echo -e "  🖼️ Mídia:       ${CYAN}$MIDIA${RESET}"
echo -e "  👥 Contatos:   ${CYAN}$CONTATOS${RESET}"
echo ""

# Mostrar JSON bruto
read -p "💾 Deseja ver o JSON bruto? (s/n): " VERJSON
if [[ "$VERJSON" == "s" || "$VERJSON" == "S" ]]; then
  echo ""
  echo -e "${BOLD}${CYAN}📄 JSON RAW:${RESET}"
  echo "$RESPONSE" | jq .
  echo ""
fi

# Salvar em .txt
read -p "📝 Deseja salvar tudo em .txt? (s/n): " SALVAR
if [[ "$SALVAR" == "s" || "$SALVAR" == "S" ]]; then
  ARQ="consulta_$(date +%Y%m%d_%H%M%S).txt"
  {
    echo "📦 INFORMAÇÕES DO NÚMERO:"
    echo "Número UID: $NUM_ID"
    echo "Nome: $NOME"
    echo "Foto: $FOTO"
    echo ""
    echo "🗺️ LOCALIZAÇÃO:"
    echo "País: $PAIS"
    echo "Região: $REGIAO"
    echo "Cidade: $CIDADE"
    echo "Latitude: $LAT ($LAT_RESUMO)"
    echo "Longitude: $LON ($LON_RESUMO)"
    echo ""
    echo "📡 OPERADORA:"
    echo "Operadora: $OPERADORA"
    echo "Ícone: $ICON_OP"
    echo ""
    echo "📊 DADOS VOLUMÉTRICOS:"
    echo "Total: $TOTAL"
    echo "Mensagens: $MENSAGEM"
    echo "Mídia: $MIDIA"
    echo "Contatos: $CONTATOS"
  } > "$ARQ"
  echo -e "${GREEN}✅ Salvo como: $ARQ${RESET}"
fi

echo ""
echo -e "${BOLD}${GREEN}✅ Consulta finalizada com sucesso.${RESET}"
