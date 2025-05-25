# TERMUX

Script Bash para Consulta de CPFs no Portal da TransparÃªncia â€” Termux/Linux

## DESCRIÇÃO DE CONSULTAR CPF

Este projeto traz um script Bash â€œhacker styleâ€ para consultar CPFs no Portal da TransparÃªncia via API oficial. Ele exibe no terminal (e permite salvar em um arquivo `CPF_VALIDOS.txt`) apenas CPFs vÃ¡lidos, mostrando:

- **CPF completo**
- **Nome**
- **Data de Nascimento** (ou "NÃƒO INFORMADO" se nÃ£o existir)

Tudo organizado com separadores, pronto para uso em Termux ou Linux.

---

## Funcionalidades

- Consulta mÃºltiplos CPFs de uma vez (cole um por linha).
- Exibe resultados organizados e coloridos no terminal.
- Mostra sÃ³ as informaÃ§Ãµes essenciais.
- Ao final, escolha adicionar resultados vÃ¡lidos no arquivo `CPF_VALIDOS.txt` (sem sobrescrever, sempre agregando).
- Cada pessoa fica separada por `------------------------------`.

---

## Como usar

1. **PrÃ©-requisitos**  
   No Termux ou Linux, instale:
   ```bash
   pkg install curl jq
   ```

2. **Salve o script**  
   Salve o arquivo (por exemplo, como `consulta_cpfs.sh`).

3. **DÃª permissÃ£o de execuÃ§Ã£o**  
   ```bash
   chmod +x consulta_cpfs.sh
   ```

4. **Execute o script**  
   ```bash
   ./consulta_cpfs.sh
   ```

5. **Siga as instruÃ§Ãµes**  
   - Cole sua chave da API do dados.gov.br quando solicitado.
   - Cole os CPFs que deseja consultar (um por linha).
   - No final, escolha se quer salvar os vÃ¡lidos em `CPF_VALIDOS.txt`.

---

## Exemplo de SaÃ­da

```
------------------------------
CPF: 12345678900
NOME: JOÃƒO DA SILVA
NASCIMENTO: 1980-01-01
------------------------------
CPF: 98765432100
NOME: MARIA OLIVEIRA
NASCIMENTO: NÃƒO INFORMADO
------------------------------
```

---

## ObservaÃ§Ãµes

- O arquivo `CPF_VALIDOS.txt` serÃ¡ criado/aprimorado automaticamente no diretÃ³rio onde rodar o script.
- SÃ³ serÃ£o salvos os CPFs vÃ¡lidos e encontrados na API.
- O script **nÃ£o armazena nem revela senhas ou chaves sensÃ­veis**.

---

## LicenÃ§a

Uso livre para fins educacionais e 
pessoais. 
Â© EG WEBCODE TODOS DIRETOS AUTORAIS RESERVADOS
