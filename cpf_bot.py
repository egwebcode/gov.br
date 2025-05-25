from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
import time

# Configurações para execução headless (se desejar rodar sem abrir janela gráfica)
chrome_options = Options()
chrome_options.add_argument("--headless")  # comente esta linha se quiser ver o navegador
chrome_options.add_argument("--no-sandbox")
chrome_options.add_argument("--disable-dev-shm-usage")

# Inicializa o driver (certifique-se de ter o chromedriver instalado e no PATH)
driver = webdriver.Chrome(options=chrome_options)

# URL do site e chave de acesso
url_site = "https://bruteforce-cpf.netlify.app"
access_key = "EGWEBCODE-H4SWR8EE"

# Recebe os 6 dígitos do meio do CPF no Termux
middle_digits = input("Digite os 6 dígitos do meio do CPF: ")

wait = WebDriverWait(driver, 15)

# Acessa o site
driver.get(url_site)

# --- Etapa 1: Inserir a chave de acesso ---
# Procura pelo campo de chave de acesso (ajuste o seletor se necessário)
access_input = wait.until(EC.presence_of_element_located((By.ID, "access-key")))
access_input.clear()
access_input.send_keys(access_key)
access_input.send_keys(Keys.RETURN)
time.sleep(2)  # aguarda resposta

# --- Etapa 2: Inserir os 6 dígitos do meio do CPF ---
# Procura pelo campo para os dígitos do meio (ajuste o seletor conforme a página)
middle_input = wait.until(EC.presence_of_element_located((By.ID, "middle-cpf")))
middle_input.clear()
middle_input.send_keys(middle_digits)
middle_input.send_keys(Keys.RETURN)
time.sleep(2)  # aguarda que os CPFs sejam gerados

# --- Etapa 3: Coletar os CPFs gerados ---
# Supomos que os CPFs gerados estão em elementos com a classe "generated-cpf"
cpf_elements = driver.find_elements(By.CSS_SELECTOR, ".generated-cpf")
cpfs = [cpf_el.text.strip() for cpf_el in cpf_elements if cpf_el.text.strip() != ""]

print("CPFs encontrados:")
for cpf in cpfs:
    print(cpf)

# --- Etapa 4: Para cada CPF gerado, interagir com o iframe e extrair data de nascimento ---
results = []
for cpf in cpfs:
    try:
        # Muda para o iframe que contém o form de cadastro
        # Ajuste o seletor do iframe - aqui usamos o id "registration-frame"
        wait.until(EC.frame_to_be_available_and_switch_to_it((By.ID, "registration-frame")))
        
        # Clica no botão "Cadastrar" (ajuste o seletor conforme necessário, aqui assumimos id "register-btn")
        register_btn = wait.until(EC.element_to_be_clickable((By.ID, "register-btn")))
        register_btn.click()
        time.sleep(1)
        
        # Preenche o CPF completo no campo de cadastro (assumindo id "cpf-input")
        cpf_input = wait.until(EC.presence_of_element_located((By.ID, "cpf-input")))
        cpf_input.clear()
        cpf_input.send_keys(cpf)
        
        # Submete o cadastro (assumindo botão com id "submit-btn")
        submit_btn = driver.find_element(By.ID, "submit-btn")
        submit_btn.click()
        time.sleep(2)
        
        # Aguarda o elemento que contém a data de nascimento ser exibido (assumindo id "birth-date")
        birth_date_elem = wait.until(EC.presence_of_element_located((By.ID, "birth-date")))
        birth_date = birth_date_elem.text.strip()
        results.append((cpf, birth_date))
    except Exception as e:
        print(f"Erro ao processar CPF {cpf}: {e}")
    finally:
        # Retorna para o conteúdo principal para o próximo loop
        driver.switch_to.default_content()
        time.sleep(1)

# --- Etapa 5: Exibe os resultados ---
print("\nResultados obtidos:")
for cpf, birth_date in results:
    print(f"CPF: {cpf} -> Data de Nascimento: {birth_date}")

driver.quit()