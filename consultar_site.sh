#!/bin/bash

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
NC='\033[0m' # Sem cor

# Função para linha separadora
divider() {
    echo -e "${BLUE}==============================================${NC}"
}

# Cabeçalho
clear
divider
echo -e "${CYAN}        🔍 CONSULTA COMPLETA DE SITE 🔍        "
divider

# Solicita domínio ao usuário
read -p "$(echo -e ${YELLOW}Digite o domínio (ex: exemplo.com): ${NC})" DOMINIO

# Verifica se foi digitado algo
if [[ -z "$DOMINIO" ]]; then
    echo -e "${RED}❌ Nenhum domínio informado. Encerrando...${NC}"
    exit 1
fi

# Nome do arquivo de saída
OUTPUT="relatorio_$(echo "$DOMINIO" | tr -d '/').txt"

echo -e "${GREEN}⏳ Coletando informações sobre ${DOMINIO}...${NC}"
echo "Relatório salvo em: $OUTPUT"
echo "=====================================" > "$OUTPUT"
echo "Relatório de informações para: $DOMINIO" >> "$OUTPUT"
echo "Gerado em: $(date)" >> "$OUTPUT"
echo "=====================================" >> "$OUTPUT"

# WHOIS
divider
echo -e "${CYAN}📝 WHOIS:${NC}"
divider | tee -a "$OUTPUT"
whois "$DOMINIO" 2>/dev/null | tee -a "$OUTPUT"

# DNS (A, AAAA, MX, NS, TXT)
for tipo in A AAAA MX NS TXT; do
    divider
    echo -e "${CYAN}📡 Registros DNS - Tipo $tipo:${NC}"
    divider | tee -a "$OUTPUT"
    dig +short "$DOMINIO" "$tipo" | tee -a "$OUTPUT"
done

# IP e informações geográficas
IP=$(dig +short "$DOMINIO" | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}' | head -n 1)
if [ -n "$IP" ]; then
    divider
    echo -e "${CYAN}🌐 IP Principal: $IP${NC}"
    echo -e "🌍 ${CYAN}Localização aproximada:${NC}"
    divider | tee -a "$OUTPUT"
    echo -e "\n🌐 IP Principal: $IP" | tee -a "$OUTPUT"
    curl -s "https://ipinfo.io/$IP" | tee -a "$OUTPUT"
else
    echo -e "${RED}⚠️ IP não encontrado.${NC}" | tee -a "$OUTPUT"
fi

# Cabeçalhos HTTP
divider
echo -e "${CYAN}📨 Cabeçalhos HTTP:${NC}"
divider | tee -a "$OUTPUT"
curl -s -I "$DOMINIO" | tee -a "$OUTPUT"

# SSL
divider
echo -e "${CYAN}🔒 Informações SSL:${NC}"
divider | tee -a "$OUTPUT"
echo | openssl s_client -servername "$DOMINIO" -connect "$DOMINIO:443" 2>/dev/null | openssl x509 -noout -text | tee -a "$OUTPUT"

# Tempo de resposta e status
divider
echo -e "${CYAN}⏱️ Tempo de resposta e status:${NC}"
divider | tee -a "$OUTPUT"
curl -o /dev/null -s -w "Código HTTP: %{http_code}\nTempo Total: %{time_total} segundos\n" "$DOMINIO" | tee -a "$OUTPUT"

# Final
divider
echo -e "${GREEN}✅ Consulta finalizada! Relatório salvo em: ${YELLOW}$OUTPUT${NC}"
divider
