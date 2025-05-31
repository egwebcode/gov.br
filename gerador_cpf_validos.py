import os
import multiprocessing
import time

DIRETORIO_SAIDA = "cpfs_gerados"
ARQUIVO_FINAL = os.path.join(DIRETORIO_SAIDA, "wordlist_cpf.txt")
TOTAL_CPFS = 1_000_000_000
N_PROCESSOS = multiprocessing.cpu_count()
BUFFER_SIZE = 1_000_000

def calcular_digito(cpf, peso_inicial):
    soma = sum(int(digito) * peso for digito, peso in zip(cpf, range(peso_inicial, 1, -1)))
    resto = soma % 11
    return '0' if resto < 2 else str(11 - resto)

def gerar_cpf_valido(nove_digitos):
    d1 = calcular_digito(nove_digitos, 10)
    d2 = calcular_digito(nove_digitos + d1, 11)
    return nove_digitos + d1 + d2

def gerar_cpfs_faixa(inicio, fim, idx):
    arquivo_saida = os.path.join(DIRETORIO_SAIDA, f"temp_cpfs_{idx}.txt")
    buffer = []
    with open(arquivo_saida, "w") as f:
        for i in range(inicio, fim):
            base = str(i).zfill(9)
            cpf = gerar_cpf_valido(base)
            buffer.append(cpf + "\n")
            if len(buffer) >= BUFFER_SIZE:
                f.writelines(buffer)
                buffer.clear()
        if buffer:
            f.writelines(buffer)

def monitorar_progresso():
    total_anterior = 0
    while not os.path.exists(ARQUIVO_FINAL):
        time.sleep(5)
        total = 0
        for nome in os.listdir(DIRETORIO_SAIDA):
            if nome.startswith("temp_cpfs_") and nome.endswith(".txt"):
                caminho = os.path.join(DIRETORIO_SAIDA, nome)
                try:
                    total += os.path.getsize(caminho)
                except:
                    pass
        linhas_estimadas = total // 12
        percentual = (linhas_estimadas / TOTAL_CPFS) * 100
        velocidade = (linhas_estimadas - total_anterior) / 5
        print(f"[📊] Progresso: {percentual:.2f}% | {linhas_estimadas:,} CPFs | {velocidade:,.0f} CPFs/s")
        total_anterior = linhas_estimadas

def main():
    os.makedirs(DIRETORIO_SAIDA, exist_ok=True)
    
    print(f"[🚀] Iniciando geração com {N_PROCESSOS} núcleos...")
    blocos = TOTAL_CPFS // N_PROCESSOS
    processos = []

    monitor = multiprocessing.Process(target=monitorar_progresso)
    monitor.start()

    for i in range(N_PROCESSOS):
        inicio = i * blocos
        fim = TOTAL_CPFS if i == N_PROCESSOS - 1 else (i + 1) * blocos
        p = multiprocessing.Process(target=gerar_cpfs_faixa, args=(inicio, fim, i))
        p.start()
        processos.append(p)

    for p in processos:
        p.join()

    print("[🔗] Unindo arquivos temporários...")
    with open(ARQUIVO_FINAL, "w") as final:
        for i in range(N_PROCESSOS):
            arquivo_temp = os.path.join(DIRETORIO_SAIDA, f"temp_cpfs_{i}.txt")
            with open(arquivo_temp, "r") as temp:
                final.writelines(temp.readlines())
            os.remove(arquivo_temp)

    print(f"[✅] Geração finalizada! Arquivo salvo em: {ARQUIVO_FINAL}")
    monitor.terminate()

if __name__ == "__main__":
    main()
