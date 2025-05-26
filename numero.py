import requests
import json
import os

# Função para colorir texto (ANSI)
def cor(texto, cor_nome):
    cores = {
        'vermelho': '\033[91m',
        'verde': '\033[92m',
        'amarelo': '\033[93m',
        'azul': '\033[94m',
        'roxo': '\033[95m',
        'ciano': '\033[96m',
        'cinza': '\033[90m',
        'bold': '\033[1m',
        'reset': '\033[0m'
    }
    return f"{cores.get(cor_nome, '')}{texto}{cores['reset']}"

def exibir_painel():
    os.system("clear")
    print(cor("-"*55, "ciano"))
    print(cor("             CONSULTA DE NÚMEROS - EG WEBCODE", "bold"))
    print(cor("-"*55, "ciano"))
    print(cor(" Ferramenta para consultar informações detalhadas", "amarelo"))
    print(cor(" de números de telefone usando a API NumVerify.", "amarelo"))
    print(cor("-"*55, "ciano"))

def obter_api_key():
    print(cor("Digite sua API Key do NumVerify (https://numverify.com/):", "azul"))
    api_key = input(cor("API Key: ", "verde")).strip()
    return api_key

def obter_numero():
    print(cor("Digite o número completo no formato internacional", "azul"))
    print(cor("(exemplo: +5511999999999):", "azul"))
    numero = input(cor("Número: ", "verde")).strip()
    return numero

def consulta_numero(numero, api_key):
    url = f"http://apilayer.net/api/validate?access_key={api_key}&number={numero}&country_code=&format=1"
    try:
        response = requests.get(url, timeout=10)
        data = response.json()
    except Exception as e:
        print(cor("Erro ao conectar na API: " + str(e), "vermelho"))
        return

    print(cor("\n----------------------- RESULTADO -----------------------", "ciano"))
    if data.get("valid"):
        # Lista de campos conhecidos para destacar primeiro
        campos_principais = [
            ("international_format", "Número Internacional"),
            ("local_format", "Formato Local"),
            ("country_name", "País"),
            ("country_code", "Código do País"),
            ("location", "Localização"),
            ("carrier", "Operadora"),
            ("line_type", "Tipo de Linha"),
            ("country_prefix", "Prefixo do País"),
            ("country_code", "Código do País"),
            ("region", "Região"),
            ("city", "Cidade"),
            ("zip", "CEP"),
            ("latitude", "Latitude"),
            ("longitude", "Longitude"),
        ]
        for campo, nome in campos_principais:
            if campo in data and data[campo]:
                print(f"{cor(nome+':', 'bold')} {cor(str(data[campo]), 'verde')}")
        # Exibir demais campos não exibidos acima
        print(cor("\n----------------------- OUTROS DADOS -----------------------", "ciano"))
        for chave, valor in data.items():
            if chave not in [c[0] for c in campos_principais]:
                print(f"{cor(chave.capitalize()+':', 'amarelo')} {cor(str(valor), 'cinza')}")
    else:
        print(cor("Número inválido ou não encontrado.", "vermelho"))
        print(cor("\nResposta bruta da API:", "amarelo"))
        print(json.dumps(data, indent=2, ensure_ascii=False))

    print(cor("-"*55, "ciano"))

if __name__ == "__main__":
    exibir_painel()
    api_key = obter_api_key()
    numero = obter_numero()
    if numero.startswith("+") and len(numero) > 6:
        consulta_numero(numero, api_key)
    else:
        print(cor("Formato inválido. Use: +DDDPHONE, ex: +5511999999999", "vermelho"))
