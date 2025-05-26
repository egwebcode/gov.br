import requests

def localizar_ip(ip):
    try:
        response = requests.get(f"https://ipinfo.io/{ip}/json")
        if response.status_code == 200:
            dados = response.json()
            print("Informações de localização para o IP:", ip)
            print(f"País: {dados.get('country', 'Desconhecido')}")
            print(f"Região: {dados.get('region', 'Desconhecido')}")
            print(f"Cidade: {dados.get('city', 'Desconhecido')}")
            print(f"Organização: {dados.get('org', 'Desconhecida')}")
            print(f"Localização (latitude, longitude): {dados.get('loc', 'Desconhecida')}")
        else:
            print("Não foi possível obter informações para este IP.")
    except Exception as e:
        print("Erro ao consultar o IP:", e)

if __name__ == "__main__":
    ip = input("Digite o IP para localizar: ").strip()
    localizar_ip(ip)