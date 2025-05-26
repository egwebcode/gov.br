import requests

def exibir_painel():
    painel = """
╔══════════════════════════════════════════════════════════╗
║             CONSULTA DE NÚMEROS - EG WEBCODE           ║
╠══════════════════════════════════════════════════════════╣
║ Ferramenta para consultar informações de números        ║
║ de telefone usando a API NumVerify.                    ║
╚══════════════════════════════════════════════════════════╝
"""
    print(painel)

def obter_api_key():
    print("Digite sua API Key do NumVerify (https://numverify.com/):")
    api_key = input("API Key: ").strip()
    return api_key

def obter_numero():
    print("Digite o número completo no formato internacional (ex: +5511999999999):")
    numero = input("Número: ").strip()
    return numero

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
        print(f"• Número internacional: {data.get('international_format', 'Desconhecido')}")
        print(f"• País: {data.get('country_name', 'Desconhecido')}")
        print(f"• Localização: {data.get('location', 'Desconhecido')}")
        print(f"• Operadora: {data.get('carrier', 'Desconhecida')}")
        print(f"• Tipo de linha: {data.get('line_type', 'Desconhecido')}")
    else:
        print("Número inválido ou não encontrado.")

if __name__ == "__main__":
    exibir_painel()
    api_key = obter_api_key()
    numero = obter_numero()
    if numero.startswith("+") and len(numero) > 6:
        consulta_numero(numero, api_key)
    else:
        print("Formato inválido. Use: +DDDPHONE, ex: +5511987654321")
