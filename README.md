# gov.br

Consulta rápida de CPF no Portal da Transparência (API oficial do governo federal)

## Instalação rápida (Termux ou Linux)

```bash
pkg update -y && pkg upgrade -y && pkg install
git clone https://github.com/egwebcode/gov.br
curl jq -y
curl -O https://raw.githubusercontent.com/egwebcode/gov.br
chmod +x CPF.sh
./CPF.sh
```

## O que faz?

- Consulta um ou vários CPFs na base do gov.br
- Mostra CPF, nome e nascimento (ou "NÃO INFORMADO")
- No final, você pode salvar todos os válidos em `CPF_VALIDOS.txt` (sempre no mesmo arquivo, organizado)
- Pode rodar e salvar quantas vezes quiser, sempre adicionando no arquivo

## Exemplo de uso

```
CPF: 12345678900
NOME: JOÃO DA SILVA
NASCIMENTO: 1980-01-01
------------------------------
CPF: 98765432100
NOME: MARIA OLIVEIRA
NASCIMENTO: NÃO INFORMADO
------------------------------
```

## Observação

- Usa apenas dependências simples e públicas (`curl`, `jq`)
- Consulta apenas dados públicos do Portal da Transparência (API gov.br)
e preciso ter um token do gov.br para conseguir acessar
