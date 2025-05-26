import os
import requests

def exibir_painel():
    painel = f"""
╔══════════════════════════════════════════════════════════╗
║             CONSULTA DE NÚMEROS - EG WEBCODE           ║
╠══════════════════════════════════════════════════════════╣
║ Ferramenta para consultar informações de números        ║
║ de telefone usando a API NumVerify.                    ║
╚══════════════════════════════════════════════════════════╝
"""
    print(painel)

def obter_api_key():
    api_key_path = os.path.expanduser("~/.api_numverify")
    if os.path.exists(api_key_path):
        with open(api_key_path, "r") as f:
            api_key = f.read().strip()
        if api_key:
            return api_key

    print("Digite sua API Key do NumVerify (você pode obter em https://numverify.com/):")
    api_key = input("> ").strip()
    with open(api_key_path, "w") as f:
        f.write(api_key)
    return api_key

def consulta_numero(numero, api_key):
    url = f"http://apilayer.net/api/validate?access_key={api_key}&number={numero}&country_code=&format=1"
    try:
        response = requests.get(url, timeout=10)
        data = response.json()
    except Exception as e:
        print("Erro ao conectar na API:", e)
        return

    print("\n════════════════ RESULTADO ════════════════")
    if data.get("valid"):
        print(f"• Número internacional: {data['international_format']}")
        print(f"• País: {data['country_name']}")
        print(f"• Localização: {data['location']}")
        print(f"• Operadora: {data['carrier']}")
        print(f"• Tipo de linha: {data['line_type']}")
    else:
        print("Número inválido ou não encontrado.")

if __name__ == "__main__":
    exibir_painel()
    api_key = obter_api_key()
    print("\nDigite o número completo com +, DDD e número (ex: +5511999999999):")
    numero = input("> ").strip()
    if numero.startswith("+") and len(numero) > 6:
        consulta_numero(numero, api_key)
    else:
        print("Formato inválido. Use: +DDDPHONE, ex: +5511999999999")