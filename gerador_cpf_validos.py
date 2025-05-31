import time
import os

ARQUIVO = "wordlist_cpf.txt"
TOTAL = 1_000_000_000
INTERVALO_LOG = 100_000  # Atualiza o progresso a cada 100 mil gerados
BUFFER_SIZE = 1_000_000

def calcular_digito(cpf, peso_inicial):
    soma = sum(int(cpf[i]) * (peso_inicial - i) for i in range(len(cpf)))
    resto = soma % 11
    return '0' if resto < 2 else str(11 - resto)

def gerar_cpfs_validos():
    if os.path.exists(ARQUIVO):
        print(f"[✔] Arquivo '{ARQUIVO}' já existe. Pulando geração.")
        return

    print("🚀 Iniciando geração de CPFs válidos...\n")
    inicio = time.time()
    ultimo_log = 0
    escritos = 0

    with open(ARQUIVO, "w", buffering=1024*1024*8) as f:
        while escritos < TOTAL:
            buffer_inicio = escritos
            buffer_fim = min(escritos + BUFFER_SIZE, TOTAL)

            blocos = (
                f"{i:09d}{calcular_digito(f'{i:09d}', 10)}{calcular_digito(f'{i:09d}{calcular_digito(f'{i:09d}', 10)}', 11)}\n"
                for i in range(buffer_inicio, buffer_fim)
            )
            f.write(''.join(blocos))
            escritos = buffer_fim

            # Histórico organizado a cada 100 mil gerados
            if escritos - ultimo_log >= INTERVALO_LOG:
                tempo_passado = time.time() - inicio
                porcentagem = (escritos / TOTAL) * 100
                velocidade = escritos / tempo_passado
                print(
                    f"📊 Progresso: {porcentagem:6.2f}%  |  Gerados: {escritos:,}  |  Velocidade: {velocidade:,.0f} CPFs/s"
                )
                ultimo_log = escritos

    duracao = time.time() - inicio
    print("\n✅ Finalizado!")
    print(f"🕒 Tempo total: {duracao:.2f} segundos ({duracao/60:.2f} minutos)")
    print(f"📁 Arquivo salvo como: {ARQUIVO}")

if __name__ == "__main__":
    gerar_cpfs_validos()
