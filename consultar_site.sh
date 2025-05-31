#!/data/data/com.termux/files/usr/bin/bash

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
NC='\033[0m'

divider() {
    echo -e "${BLUE}--------------------------------------------------${NC}"
}

clear
divider
echo -e "${CYAN}         🔍 CONSULTA AVANÇADA DE SITE (Termux) 🔍"
divider

echo -ne "${YELLOW}Digite a URL do site (ex: https://exemplo.com): ${NC}"
read SITE

# Sanitiza domínio
DOMINIO=$(echo "$SITE" | sed -E 's~https?://~~' | cut -d/ -f1)
OUTPUT="relatorio_${DOMINIO}.txt"

echo -e "${GREEN}🔧 Gerando relatório para: ${SITE}${NC}"
echo -e "Relatório salvo em: ${OUTPUT}"

# Início do arquivo
echo "RELATÓRIO DE ANÁLISE DE SITE" > "$OUTPUT"
echo "Site: $SITE" >> "$OUTPUT"
echo "Gerado em: $(date)" >> "$OUTPUT"
echo "==================================================" >> "$OUTPUT"

### 1. WHOIS
echo -e "\n[1] WHOIS DO DOMÍNIO:\n" >> "$OUTPUT"
whois "$DOMINIO" 2>/dev/null >> "$OUTPUT"

### 2. DNS
echo -e "\n[2] REGISTROS DNS:\n" >> "$OUTPUT"
for tipo in A AAAA MX NS TXT; do
    echo "==> Tipo $tipo:" >> "$OUTPUT"
    dig +short "$DOMINIO" "$tipo" >> "$OUTPUT"
done

### 3. IP e Localização
IP=$(dig +short "$DOMINIO" | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}' | head -n 1)
if [ -n "$IP" ]; then
    echo -e "\n[3] IP PRINCIPAL: $IP" >> "$OUTPUT"
    echo -e "[3.1] GEOLOCALIZAÇÃO:\n" >> "$OUTPUT"
    curl -s "https://ipinfo.io/$IP" >> "$OUTPUT"
else
    echo -e "\n[3] IP NÃO ENCONTRADO" >> "$OUTPUT"
fi

### 4. Cabeçalhos HTTP
echo -e "\n[4] CABEÇALHOS HTTP:\n" >> "$OUTPUT"
curl -s -I "$SITE" >> "$OUTPUT"

### 5. SSL
echo -e "\n[5] CERTIFICADO SSL:\n" >> "$OUTPUT"
echo | openssl s_client -servername "$DOMINIO" -connect "$DOMINIO:443" 2>/dev/null | openssl x509 -noout -text >> "$OUTPUT"

### 6. Sitemap e Robots
echo -e "\n[6] ARQUIVOS DO SITE (robots.txt e sitemap.xml):\n" >> "$OUTPUT"
echo "[robots.txt]" >> "$OUTPUT"
curl -s "$SITE/robots.txt" >> "$OUTPUT"
echo -e "\n[sitemap.xml]" >> "$OUTPUT"
curl -s "$SITE/sitemap.xml" >> "$OUTPUT"

### 7. Análise do HTML
echo -e "\n[7] ANÁLISE DO CÓDIGO FONTE HTML:\n" >> "$OUTPUT"

TEMPFILE="tmp_html_$DOMINIO.html"
curl -s "$SITE" -o "$TEMPFILE"

echo "[7.1] TÍTULO DA PÁGINA:" >> "$OUTPUT"
grep -oP '(?<=<title>).*?(?=</title>)' "$TEMPFILE" >> "$OUTPUT"

echo -e "\n[7.2] META TAGS:" >> "$OUTPUT"
grep -i '<meta ' "$TEMPFILE" >> "$OUTPUT"

echo -e "\n[7.3] LINKS ENCONTRADOS:" >> "$OUTPUT"
grep -oP '(?i)href=["'\''](http[s]?://[^"'\'' >]+)' "$TEMPFILE" | sort -u >> "$OUTPUT"

echo -e "\n[7.4] ARQUIVOS JS, CSS, IMAGENS:" >> "$OUTPUT"
grep -Eo 'src=["'\''][^"'\'' >]+|href=["'\''][^"'\'' >]+' "$TEMPFILE" | cut -d'"' -f2 | grep -E '\.(js|css|png|jpg|jpeg|gif|svg|ico|woff|ttf)' | sort -u >> "$OUTPUT"

rm "$TEMPFILE"

### Finalização
echo -e "\n✅ RELATÓRIO CONCLUÍDO!"
echo -e "📄 Arquivo salvo como: ${YELLOW}$OUTPUT${NC}"
