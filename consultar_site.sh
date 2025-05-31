#!/bin/bash

# Verifica se o domínio foi passado como argumento
if [ -z "$1" ]; then
    echo "Uso: $0 dominio.com"
    exit 1
fi

DOMINIO="$1"
OUTPUT="relatorio_$DOMINIO.txt"

echo "🔍 Coletando informações sobre $DOMINIO..."
echo "Relatório salvo em: $OUTPUT"
echo "=====================================" > "$OUTPUT"
echo "Relatório de informações para: $DOMINIO" >> "$OUTPUT"
echo "Gerado em: $(date)" >> "$OUTPUT"
echo "=====================================" >> "$OUTPUT"

# WHOIS
echo -e "\n📝 WHOIS:" | tee -a "$OUTPUT"
whois "$DOMINIO" 2>/dev/null | tee -a "$OUTPUT"

# DNS (A, AAAA, MX, NS, TXT)
for tipo in A AAAA MX NS TXT; do
    echo -e "\n📡 Registros DNS - Tipo $tipo:" | tee -a "$OUTPUT"
    dig +short "$DOMINIO" "$tipo" | tee -a "$OUTPUT"
done

# IP e informações geográficas
IP=$(dig +short "$DOMINIO" | head -n 1)
if [ -n "$IP" ]; then
    echo -e "\n🌐 IP Principal: $IP" | tee -a "$OUTPUT"
    echo -e "\n🗺️ Localização do IP:" | tee -a "$OUTPUT"
    curl -s "https://ipinfo.io/$IP" | tee -a "$OUTPUT"
else
    echo -e "\n⚠️ IP não encontrado." | tee -a "$OUTPUT"
fi

# Cabeçalhos HTTP
echo -e "\n📨 Cabeçalhos HTTP:" | tee -a "$OUTPUT"
curl -s -I "$DOMINIO" | tee -a "$OUTPUT"

# SSL (Certificado)
echo -e "\n🔒 Informações SSL:" | tee -a "$OUTPUT"
echo | openssl s_client -servername "$DOMINIO" -connect "$DOMINIO:443" 2>/dev/null | openssl x509 -noout -text | tee -a "$OUTPUT"

# Tempo de resposta e status
echo -e "\n⏱️ Tempo de resposta:" | tee -a "$OUTPUT"
curl -o /dev/null -s -w "Código HTTP: %{http_code}\nTempo Total: %{time_total} segundos\n" "$DOMINIO" | tee -a "$OUTPUT"

echo -e "\n✅ Fim da consulta. Relatório salvo em $OUTPUT"
