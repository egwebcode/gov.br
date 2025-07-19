import http.server
import socketserver
import os

ip = input("Digite o IP para ouvir (ex: 0.0.0.0): ")
porta = int(input("Digite a porta (ex: 8080): "))
diretorio = input("Digite o caminho do diretório do site: ")

if not os.path.isdir(diretorio):
    print("❌ Diretório inválido!")
    exit()

os.chdir(diretorio)

class Handler(http.server.SimpleHTTPRequestHandler):
    def log_message(self, format, *args):
        print("🔗", self.address_string(), "-", format%args)

with socketserver.TCPServer((ip, porta), Handler) as httpd:
    print(f"✅ Servidor rodando em http://{ip}:{porta}/")
    print(f"📁 Servindo arquivos de: {os.path.abspath(diretorio)}")
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\n🛑 Servidor finalizado.")
        httpd.server_close()
