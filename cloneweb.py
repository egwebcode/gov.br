import os
import subprocess

def format_url():
    print("=== Baixador de Site Completo ===\n")
    protocolo = input("Escolha o protocolo (http ou https) [http]: ").strip().lower()
    if protocolo not in ['http', 'https', '']:
        print("Protocolo inválido. Use 'http' ou 'https'.")
        exit(1)
    if protocolo == '':
        protocolo = 'http'
    
    site = input("Digite o nome do site (ex: exemplo.com): ").strip()
    if not site:
        print("Nome do site não pode estar vazio.")
        exit(1)

    url = f"{protocolo}://{site}"
    return url

def baixar_site(url):
    comando = [
        "wget",
        "--mirror",
        "--convert-links",
        "--adjust-extension",
        "--page-requisites",
        "--no-parent",
        url
    ]
    print(f"\nBaixando site: {url}\n")
    try:
        subprocess.run(comando, check=True)
        print("\n✅ Download completo com sucesso!")
    except subprocess.CalledProcessError:
        print("\n❌ Ocorreu um erro ao baixar o site.")

if __name__ == "__main__":
    url = format_url()
    baixar_site(url)
