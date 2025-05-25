
# gov.br

Consulta automatizada de CPFs no Portal da Transparência (dados.gov.br) via Bash Script.

## Descrição

Este repositório contém um script Bash (`CPF.sh`) para consultar CPFs utilizando a API do Portal da Transparência do Governo Federal. O script lê uma lista de CPFs, faz as consultas e salva os resultados válidos em um arquivo `CPF_VALIDOS.txt`.

## Requisitos

- Bash (Linux, macOS ou WSL)
- `curl`
- [`jq`](https://stedolan.github.io/jq/download/) (para processar JSON)
- Uma chave de API válida do [dados.gov.br](https://dados.gov.br/)

## Instalação

1. Clone este repositório:
   ```bash
   git clone https://github.com/egwebcode/consultar.com.br.git
   cd consultar.com.br
   ```
2. Dê permissão de execução ao script:
   ```bash
   chmod +x CPF.sh
   ```
3. Instale o `jq` caso não tenha:
   - **Debian/Ubuntu**: `sudo apt install jq`
   - **Fedora**: `sudo dnf install jq`
   - **macOS (brew)**: `brew install jq`
   - **Windows (WSL)**: use o comando do seu Linux

## Como Usar

1. Execute o script:
   ```bash
   ./CPF.sh
   ```
2. Insira sua chave de API do dados.gov.br quando solicitado.
3. Cole os CPFs a serem consultados, um por linha. Tecle `Ctrl+D` para finalizar a entrada.
4. O script fará as consultas e mostrará os resultados no terminal.
5. Ao final, escolha:
   - `01` para salvar todos os resultados válidos em `CPF_VALIDOS.txt`
   - `02` para sair sem salvar

## Saída

- Os resultados válidos são salvos no arquivo `CPF_VALIDOS.txt` no formato:

  ```
  CPF: <número>
  NOME: <nome>
  NASCIMENTO: <data>
  ------------------------------
  ```

## Observações

- O script valida se os CPFs têm 11 dígitos.
- Cada requisição aguarda 1 segundo para evitar bloqueios na API.
- Apenas CPFs com resultado válido são salvos.

## Licença

Este projeto é open-source e está sob a licença MIT.

---

# Desenvolvido por EG Webcode TODOS DIRETOS RESERVADOS © EG WEBCODE

# REDES SOCIAIS
INSTAGRAM: https://instagram.com/egwebcode
