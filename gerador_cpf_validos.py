import http.server
import socketserver
import threading
import os

ARQUIVO = "cpfs_validos.txt"

def calcular_digito(cpf, peso_inicial):
    soma = sum(int(digito) * peso for digito, peso in zip(cpf, range(peso_inicial, 1, -1)))
    resto = soma % 11
    return '0' if resto < 2 else str(11 - resto)

def gerar_cpf_valido(nove_digitos):
    d1 = calcular_digito(nove_digitos, 10)
    d2 = calcular_digito(nove_digitos + d1, 11)
    return nove_digitos + d1 + d2

def formatar_cpf(cpf):
    return f"{cpf[:3]}.{cpf[3:6]}.{cpf[6:9]}-{cpf[9:]}"

def gerar_cpfs_validos():
    if os.path.exists(ARQUIVO):
        print(f"[✔] Arquivo '{ARQUIVO}' já existe. Pulando geração.")
        return

    print("[...] Gerando CPFs válidos...")
    with open(ARQUIVO, "w") as f:
        for i in range(1000000000):  # 9 primeiros dígitos
            base = str(i).zfill(9)
            cpf_completo = gerar_cpf_valido(base)
            f.write(formatar_cpf(cpf_completo) + "\n")

            if i % 1000000 == 0:
                print(f" > {i:,} CPFs válidos gerados...")

    print(f"[✔] Arquivo '{ARQUIVO}' gerado com sucesso!")

def iniciar_servidor():
    porta = 8000
    os.chdir(os.path.abspath("."))

    handler = http.server.SimpleHTTPRequestHandler
    with socketserver.TCPServer(("", porta), handler) as httpd:
        print(f"[🌐] Servidor iniciado: http://localhost:{porta}")
        print(f"[⬇] Baixe aqui: http://localhost:{porta}/{ARQUIVO}")
        httpd.serve_forever()

if __name__ == "__main__":
    gerar_cpfs_validos()

    servidor_thread = threading.Thread(target=iniciar_servidor)
    servidor_thread.daemon = True
    servidor_thread.start()

    input("\nPressione ENTER para encerrar o servidor...\n")
