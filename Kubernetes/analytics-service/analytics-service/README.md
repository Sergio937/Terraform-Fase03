# analytics-service (Python)

Este é o serviço de análise (analytics) do projeto ToggleMaster. Ele é um *worker* de backend e não possui uma API pública (exceto `/health`).

Sua unica funcao e:
1.  Ouvir constantemente a fila do **AWS SQS** (que o `evaluation-service` preenche).
2.  Consumir as mensagens de evento da fila.
3.  Gravar os dados de analise em uma tabela do **AWS DynamoDB**.

## 📦 Pré-requisitos (Local)

* [Python](https://www.python.org/) (versao 3.9 ou superior)
* **Credenciais AWS:** para acessar SQS e DynamoDB.
* **Recursos AWS:** a fila e a tabela DynamoDB devem existir.

## Preparando a tabela DynamoDB

Este servico espera que a tabela `ToggleMasterAnalytics` exista no DynamoDB.
O Terraform deste repositorio ja cria essa tabela.

## 🚀 Rodando Localmente
**1. Clone o repositório** e entre na pasta `analytics-service`.

**2. Configure as variaveis de ambiente:** Crie um arquivo chamado `.env` na raiz desta pasta (`analytics-service/`).
```.env
# Porta que este serviço (health check) irá rodar
PORT="8005"

# --- AWS SQS e DynamoDB ---
AWS_SQS_URL="<sqs-queue-url>"
AWS_DYNAMODB_TABLE="ToggleMasterAnalytics"
AWS_REGION="us-east-1"
```

**3. Instale as Dependências:**
```bash
pip install -r requirements.txt
```

**4. Inicie o Serviço:**
```bash
gunicorn --bind 0.0.0.0:8005 app:app
```
O servidor estara rodando em `http://localhost:8005`.

## 🧪 Testando o Serviço

Testar este serviço é diferente. Você não vai chamar uma API dele.

**1. Verifique a Saúde:**
```bash
curl http://localhost:8005/health
```
Saída esperada: `{"status":"ok"}``

**2. Gere Eventos:**

- Vá para o `evaluation-service` (que deve estar rodando) e faça algumas requisições de avaliação:
```bash
curl "http://localhost:8004/evaluate?user_id=test-user-1&flag_name=enable-new-dashboard"
curl "http://localhost:8004/evaluate?user_id=test-user-2&flag_name=enable-new-dashboard"
```
- **Alternativa:** Envie uma mensagem manualmente pelo Console do AWS SQS.

**3. Observe os Logs:**

No terminal do `analytics-service`, voce devera ver os logs aparecendo, indicando que as mensagens foram recebidas e salvas no DynamoDB:
```bash
INFO:Iniciando o worker SQS...
INFO:Recebidas 2 mensagens.
INFO:Processando mensagem ID: ...
INFO:Evento ... (Flag: enable-new-dashboard) salvo no DynamoDB.
INFO:Processando mensagem ID: ...
INFO:Evento ... (Flag: enable-new-dashboard) salvo no DynamoDB.
```

**4. Verifique o DynamoDB:**

Va ate o console da AWS, abra o **DynamoDB**, selecione a tabela `ToggleMasterAnalytics`.

Você verá os itens que o worker acabou de inserir.