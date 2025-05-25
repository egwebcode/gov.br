from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.firefox.options import Options
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
import time

# Chave de acesso e URL do site
access_key = "EGWEBCODE-H4SWR8EE"
url_site = "https://bruteforce-cpf.netlify.app"

# Recebe os 6 dígitos do meio do CPF via Termux
middle_digits = input("Digite os 6 dígitos do meio do CPF: ")

# Configurações do Firefox para execução headless (sem interface gráfica)
firefox_options = Options()
firefox_options.add_argument("--headless")  # Remova essa linha se quiser visualizar o navegador

driver = webdriver.Firefox(options=firefox_options)
wait = WebDriverWait(driver, 15)

# Acessa o site
driver.get(url_site)

# --- Etapa 1: Inserir a chave de acesso ---
# Ajuste o seletor (ID "access-key") conforme necessário
access_input = wait.until(EC.presence_of_element_located((By.ID, "access-key")))
access_input.clear()
access_input.send_keys(access_key)
access_input.send_keys(Keys.RETURN)
time.sleep(2)  # Aguarda a resposta do site

# --- Etapa 2: Inserir os 6 dígitos do meio do CPF ---
# Ajuste o seletor (ID "middle-cpf") conforme a estrutura do site
middle_input = wait.until(EC.presence_of_element_located((By.ID, "middle-cpf")))
middle_input.clear()
middle_input.send_keys(middle_digits)
middle_input.send_keys(Keys.RETURN)
time.sleep(2)  # Tempo para que os CPFs sejam gerados

# --- Etapa 3: Coletar os CPFs gerados ---
# Assumindo que os CPFs aparecem em elementos com a classe "generated-cpf"
cpf_elements = driver.find_elements(By.CSS_SELECTOR, ".generated-cpf")
cpfs = [cpf_el.text.strip() for cpf_el in cpf_elements if cpf_el.text.strip() != ""]

print("CPFs encontrados:")
for cpf in cpfs:
    print(cpf)

# --- Etapa 4: Para cada CPF gerado, interagir com o iframe para cadastro e extrair data de nascimento ---
results = []
for cpf in cpfs:
    try:
        # Troca para o iframe que contém o formulário de cadastro
        # Ajuste o seletor (ID "registration-frame") conforme necessário
        wait.until(EC.frame_to_be_available_and_switch_to_it((By.ID, "registration-frame")))

        # Clica no botão "Cadastrar" (ajuste o seletor se necessário, aqui usamos ID "register-btn")
        register_btn = wait.until(EC.element_to_be_clickable((By.ID, "register-btn")))
        register_btn.click()
        time.sleep(1)

        # Preenche o CPF completo na área de cadastro (ajuste o seletor ID "cpf-input")
        cpf_input = wait.until(EC.presence_of_element_located((By.ID, "cpf-input")))
        cpf_input.clear()
        cpf_input.send_keys(cpf)

        # Submete o cadastro (assumindo botão com ID "submit-btn")
        submit_btn = driver.find_element(By.ID, "submit-btn")
        submit_btn.click()
        time.sleep(2)

        # Aguarda que a data de nascimento seja exibida (ajuste o seletor ID "birth-date" conforme necessário)
        birth_date_elem = wait.until(EC.presence_of_element_located((By.ID, "birth-date")))
        birth_date = birth_date_elem.text.strip()
        results.append((cpf, birth_date))
    except Exception as e:
        print(f"Erro ao processar CPF {cpf}: {e}")
    finally:
        # Volta para o conteúdo principal para o próximo CPF
        driver.switch_to.default_content()
        time.sleep(1)

# --- Etapa 5: Exibe os resultados ---
print("\nResultados obtidos:")
for cpf, birth_date in results:
    print(f"CPF: {cpf} -> Data de Nascimento: {birth_date}")

driver.quit()