#!/bin/bash

# ───────── CONFIGURAÇÕES ─────────
USER_AGENT="Mozilla/5.0 (X11; Linux x86_64)"
TMP_JSON="resultado.json"
LINHA="──────────────────────────────────────────────"

# ───────── CABEÇALHO BONITO COM SEU NOME ─────────
clear
echo -e "\e[1;36m$LINHA"
echo -e "\e[1;32m        EG WEBCODE - CONSULTAR NOME"
echo -e "\e[1;36m$LINHA\e[0m"

# ───────── INPUT DO USUÁRIO ─────────
echo -ne "\n\e[1;33mDigite o nome no formato: nome+sobrenome+...\e[0m\n> "
read NOME

# ───────── FORÇA minúsculas ─────────
NOME=$(echo "$NOME" | tr '[:upper:]' '[:lower:]')

# ───────── SUA URL DA API AQUI ─────────
API_URL="https://portaldatransparencia.gov.br/pessoa-fisica/busca/resultado?termo=$NOME&pagina=1&tamanhoPagina=10&t=wdUJNlyLKulB1HjVJkn0&tokenRecaptcha=03AFcWeA4DXPwC9M1vCB5CO9KM1PqzNxwp2gNs80thmXkCJLg9w9PzDwxJv14wggAUnNAWamNIMRKxSq3a5_mRzciHUo1Lq5_-ICGBofvCfeHEhQOxJwP5e-ys9FXEmiJk9jF4LIGilEujQga0SDwN-WU7IJ0aWlKB32SAxceX9iz9kS49_ZhSC2oFaWv9CTTr9JaobNyNczk3gs-gOTfCtJf1wF-j69zM5AMfAwbPorXoYETIZ7sG8qYtcIemdPKvPJc78HqbM3DS4HUm3GhqM6ZNGqY5e8kW8-U3_rGUXBI3CfXrb9IKOS-vBI2J-xvQpz3KhNWJ3k2v2-9sP0MJJ3nqkgIoB5JQS14EK1plXeaQF2Ez2YFXH03ZfUbVF4-253NAon3xsAr_8lfaM-APpuabMFJ3cF1LihK3lEo9ebkrCs7du8M95XNhwqtRCJ9AueyUTAxvKmBMsM6cs8vMap7BQvPUkPyDqc-s6bOjfp8z11ahS_sVqZ9XLMEHdJriC-eGP3rXc5wrYOU3H9dG6xS8ykm1YCBxp4tJ85vyVWqXBmxo620uIhZea_6fc11FRXkXxfwKZzVMl5P-OQvqaqjHX94k486jeHP910SAbNIkeKqEqN3SCIj-XPkHLqh0-nkdr5Hl1sYi_xNzCfCJEiNTwtjwIjQ8vTidojbIfLHbRI3jzEYLS7XZIJusJClYJm1zZnT5ePRZn14Grse2aIzGzZoyM0ANOQbtV3WZm538bGkrUl5NFWYw4pF5yYx0jf-8fHzwMQgsAMMdQcuS2SdUXOtsOQOLae71Jlxe945kxllejVW-hoi0_dsd_ebKzSD84vTIpCRRwt5Qrn-8aJXwMFZOg9Z-ToGnWlFPSo0Cpp7N613aKK2K8ozdNH5SF3MpvZM7aj-bGU2mMGrWjmjo85OaNXF04RCGqmLS58r5JNx3mp6crhzZbqcbh0qntEanK6ATdyug"

echo -e "\n\e[1;34m[*] Consultando a API...\e[0m"
curl -s -A "$USER_AGENT" "$API_URL" -o "$TMP_JSON"

# ───────── VERIFICA ERROS ─────────
if [[ ! -s "$TMP_JSON" ]]; then
  echo -e "\e[1;31m[!] Nenhuma resposta recebida da API.\e[0m"
  exit 1
fi

# ───────── VERIFICA SE HÁ REGISTROS ─────────
TOTAL=$(jq -r '.totalRegistros' "$TMP_JSON")
if [[ "$TOTAL" -eq 0 ]]; then
  echo -e "\e[1;31m[-] Nenhum resultado encontrado.\e[0m"
  exit 1
fi

echo -e "\n\e[1;32m[+] $TOTAL resultado(s) encontrado(s):\e[0m"

# ───────── EXIBE DADOS ─────────
jq -c '.registros[]' "$TMP_JSON" | while read -r item; do
  NOME_COMPLETO=$(echo "$item" | jq -r '.nome')
  CPF_NIS=$(echo "$item" | jq -r '.cpfNis')
  RELACAO=$(echo "$item" | jq -r '.descricaoRelacoesGovernoFederal')

  echo -e "\e[1;36m$LINHA"
  echo -e "\e[1;37mNOME     :\e[0m $NOME_COMPLETO"
  echo -e "\e[1;37mCPF/NIS  :\e[0m $CPF_NIS"
  echo -e "\e[1;37mRELAÇÃO  :\e[0m $RELACAO"
done

echo -e "\e[1;36m$LINHA\e[0m"
