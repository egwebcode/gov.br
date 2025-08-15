from flask import Flask, send_file, render_template_string, abort, request, redirect, url_for
import os, zipfile, tempfile

app = Flask(__name__)

HOME_DIR = "/data/data/com.termux/files/home"

HTML = """
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Explorador Termux</title>
<style>
body { font-family: monospace; background: black; color: white; }
a { color: cyan; text-decoration: none; display:block; margin:5px 0; }
a:hover { text-decoration: underline; }
button { padding:5px 10px; background:#333; color:white; border:none; cursor:pointer; margin:10px 0; }
</style>
</head>
<body>
<h2>📂 {{current_path}}</h2>

<form method="POST" action="{{url_for('download_all', path=rel_path)}}">
    <button type="submit">📦 Baixar Tudo</button>
</form>

<ul>
{% for name, is_dir in items %}
    {% if is_dir %}
        <li>📁 <a href="{{url_for('browse', path=rel_path + '/' + name)}}">{{name}}</a></li>
    {% else %}
        <li>📄 <a href="{{url_for('download', path=rel_path + '/' + name)}}">{{name}}</a></li>
    {% endif %}
{% endfor %}
</ul>
</body>
</html>
"""

def safe_path(path):
    full_path = os.path.abspath(os.path.join(HOME_DIR, path))
    if not full_path.startswith(HOME_DIR):
        abort(403)
    return full_path

@app.route("/", defaults={"path": ""})
@app.route("/<path:path>")
def browse(path):
    full_path = safe_path(path)
    if not os.path.isdir(full_path):
        abort(404)
    items = [(name, os.path.isdir(os.path.join(full_path, name))) for name in sorted(os.listdir(full_path))]
    return render_template_string(HTML, items=items, current_path="/" + path, rel_path=path)

@app.route("/download/<path:path>")
def download(path):
    full_path = safe_path(path)
    if os.path.isfile(full_path):
        return send_file(full_path, as_attachment=True)
    else:
        abort(404)

@app.route("/download_all/<path:path>", methods=["POST"])
def download_all(path):
    full_path = safe_path(path)
    if not os.path.isdir(full_path):
        abort(404)
    folder_name = os.path.basename(full_path.rstrip("/"))
    tmp_zip = tempfile.NamedTemporaryFile(delete=False, suffix=".zip")
    with zipfile.ZipFile(tmp_zip.name, 'w', zipfile.ZIP_DEFLATED) as zipf:
        for root, dirs, files in os.walk(full_path):
            for file in files:
                fpath = os.path.join(root, file)
                arcname = os.path.relpath(fpath, full_path)
                zipf.write(fpath, arcname)
    tmp_zip.close()
    return send_file(tmp_zip.name, as_attachment=True, download_name=f"{folder_name}.zip")

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
