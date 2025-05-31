import time
import os

ARQUIVO = "wordlist_cpf.txt"
TOTAL = 1_000_000_000
BUFFER_SIZE = 1_000_000

def calcular_digito(cpf, peso_inicial):
    soma = sum(int(digito) * peso for digito, peso in zip(cpf, range(peso_inicial, 1, -1)))
    resto = soma % 11
    return '0' if resto < 2 else str(11 - resto)

def gerar_cpf_valido(nove_digitos):
    d1 = calcular_digito(nove_digitos, 10)
    d2 = calcular_digito(nove_digitos + d1, 11)
    return nove_digitos + d1 + d2

def gerar_cpfs_validos():
    if os.path.exists(ARQUIVO):
        print(f"[✔] Arquivo '{ARQUIVO}' já existe. Pulando geração.")
        return

    print("[🚀] Gerando todos os CPFs válidos (modo rápido em 1 núcleo)...")
    inicio = time.time()
    buffer = []
    escritos = 0
    ultimo_report = time.time()

    with open(ARQUIVO, "w") as f:
        for i in range(TOTAL):
            base = str(i).zfill(9)
            cpf = gerar_cpf_valido(base)
            buffer.append(cpf + "\n")
            escritos += 1

            if len(buffer) >= BUFFER_SIZE:
                f.writelines(buffer)
                buffer.clear()

            # Atualiza progresso a cada 5 segundos
            if time.time() - ultimo_report >= 5:
                porcentagem = (escritos / TOTAL) * 100
                velocidade = escritos / (time.time() - inicio)
                print(f"[⏳] {porcentagem:.2f}% gerado | {escritos:,} CPFs | {velocidade:,.0f} CPFs/s")
                ultimo_report = time.time()

        if buffer:
            f.writelines(buffer)

    duracao = time.time() - inicio
    print(f"\n[✅] Finalizado em {duracao:.2f} segundos ({duracao/60:.2f} minutos)")
    print(f"[📁] Arquivo salvo como: {ARQUIVO}")

if __name__ == "__main__":
    gerar_cpfs_validos()
