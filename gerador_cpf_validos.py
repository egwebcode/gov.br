import multiprocessing
import os

ARQUIVO_FINAL = "wordlist_cpf.txt"
CPFS_TOTAL = 1_000_000_000
N_PROCESSOS = multiprocessing.cpu_count()  # Usa todos os núcleos disponíveis

def calcular_digito(cpf, peso_inicial):
    soma = sum(int(digito) * peso for digito, peso in zip(cpf, range(peso_inicial, 1, -1)))
    resto = soma % 11
    return '0' if resto < 2 else str(11 - resto)

def gerar_cpf_valido(nove_digitos):
    d1 = calcular_digito(nove_digitos, 10)
    d2 = calcular_digito(nove_digitos + d1, 11)
    return nove_digitos + d1 + d2

def gerar_cpfs_fatia(inicio, fim, id_processo):
    arquivo_parcial = f"temp_cpfs_{id_processo}.txt"
    with open(arquivo_parcial, "w") as f:
        buffer = []
        for i in range(inicio, fim):
            base = f"{i:09d}"
            cpf = gerar_cpf_valido(base)
            buffer.append(cpf + "\n")

            if len(buffer) >= 100_000:
                f.writelines(buffer)
                buffer.clear()

        if buffer:
            f.writelines(buffer)
    print(f"[✔] Processo {id_processo} finalizou: {fim - inicio:,} CPFs.")

def gerar_cpfs_com_processos():
    if os.path.exists(ARQUIVO_FINAL):
        print(f"[✔] Arquivo '{ARQUIVO_FINAL}' já existe. Pulando geração.")
        return

    print(f"[🚀] Gerando CPFs com {N_PROCESSOS} núcleos...")

    tamanho_fatia = CPFS_TOTAL // N_PROCESSOS
    processos = []

    for i in range(N_PROCESSOS):
        inicio = i * tamanho_fatia
        fim = (i + 1) * tamanho_fatia if i < N_PROCESSOS - 1 else CPFS_TOTAL
        p = multiprocessing.Process(target=gerar_cpfs_fatia, args=(inicio, fim, i))
        processos.append(p)
        p.start()

    for p in processos:
        p.join()

    print("[🔗] Unindo arquivos parciais...")

    with open(ARQUIVO_FINAL, "w") as final:
        for i in range(N_PROCESSOS):
            parcial = f"temp_cpfs_{i}.txt"
            with open(parcial, "r") as temp:
                final.writelines(temp.readlines())
            os.remove(parcial)

    print(f"[✅] Geração finalizada! Arquivo salvo como '{ARQUIVO_FINAL}'.")

if __name__ == "__main__":
    gerar_cpfs_com_processos()
