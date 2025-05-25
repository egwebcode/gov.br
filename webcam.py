from flask import Flask, render_template_string

app = Flask(__name__)

# URL para redirecionamento após a captura (opcional)
REDIRECT_URL = "https://www.google.com"

html_template = '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Captura da Webcam</title>
</head>
<body>
    <h1>Captura da Webcam</h1>
    <video id="video" width="640" height="480" autoplay></video>
    <canvas id="canvas" width="640" height="480" style="display:none;"></canvas>
    <script>
        // Solicita acesso à webcam
        navigator.mediaDevices.getUserMedia({video: true})
        .then(function(stream) {
            var video = document.getElementById('video');
            video.srcObject = stream;
            video.play();
            // Aguarda 3 segundos para capturar a imagem
            setTimeout(function(){
                var canvas = document.getElementById('canvas');
                var context = canvas.getContext('2d');
                context.drawImage(video, 0, 0, canvas.width, canvas.height);
                // Para o stream da câmera
                stream.getTracks().forEach(track => track.stop());
                // Converte a imagem capturada para base64 (formato PNG)
                var dataURL = canvas.toDataURL('image/png');
                // Cria um link para download
                var a = document.createElement('a');
                a.href = dataURL;
                // Define o nome do arquivo (pode incluir data/hora, se desejar)
                a.download = "captura.png";
                // Adiciona o link à página, simula um clique e remove o link
                document.body.appendChild(a);
                a.click();
                document.body.removeChild(a);
                // Se desejar, redirecione para outro link após o download:
                // window.location.href = "{{ redirect_url }}";
            }, 3000);
        })
        .catch(function(err) {
            console.error("Erro ao acessar a webcam: ", err);
            // Redireciona para outro link em caso de erro (opcional)
            // window.location.href = "{{ redirect_url }}";
        });
    </script>
</body>
</html>
'''

@app.route('/')
def index():
    return render_template_string(html_template, redirect_url=REDIRECT_URL)

if __name__ == '__main__':
    app.run(host="0.0.0.0", port=5000, debug=True)