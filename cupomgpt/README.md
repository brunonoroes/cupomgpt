CupomGPT: Assistente Financeiro com IA Generativa
Projeto de Checkpoint (CP6) para a matéria de AI Engineering, Cognitive and Semantic Computation. O objetivo é um aplicativo mobile iOS que utiliza IA Generativa (Gemini 2.5 Flash) para extrair dados de cupons fiscais e gerar insights financeiros personalizados.

🚀 Tecnologias Utilizadas
Frontend: Swift & SwiftUI (iOS Nativo)

Backend: Firebase (Cloud Functions, Firestore, Storage)

Inteligência Artificial: Google Vertex AI (com o modelo Gemini 2.5 Flash)

Ferramentas de Desenvolvimento: Xcode, Visual Studio Code, GitHub Copilot

✨ Funcionalidades
O aplicativo cumpre todos os requisitos obrigatórios da atividade:

[X] Captura de Imagem: O usuário pode selecionar um cupom fiscal da galeria do dispositivo (ou tirar uma foto, em um dispositivo físico).

[X] IA #1: Extração de Dados: Uma Cloud Function (analyzeimage) usa o Gemini 2.5 Flash para analisar a imagem e extrair os dados estruturados (Valor, Data, Estabelecimento, Categoria) em formato JSON.

[X] Persistência de Dados: O JSON extraído é salvo automaticamente em uma coleção despesas no Firebase Firestore.

[X] IA #2: Assistente de Insights: Uma segunda Cloud Function (getinsights) lê todos os cupons salvos no Firestore, envia os dados para o Gemini 2.5 Flash e gera um insight financeiro personalizado em linguagem natural.

[X] Uso do Copilot: O GitHub Copilot foi utilizado para auxiliar na escrita de código, como detalhado abaixo.

🛠️ Etapas de Desenvolvimento (A Nossa Jornada)
O desenvolvimento foi dividido em fases claras, com um grande foco na depuração e na correção de arquitetura do backend.

Fase 1: Setup do Frontend (Swift & Xcode)

Criação do projeto iOS no Xcode (CupomGPT).

Configuração da interface principal (ContentView.swift) com SwiftUI, incluindo o seletor de fotos (PhotosPicker) e a área de exibição.

Instalação dos SDKs do Firebase (Core, Storage, Functions, Firestore) via Swift Package Manager.

Fase 2: A Odisseia do Backend (IA #1 - Extração)

Tentativa 1 (Falha): Iniciamos com a arquitetura firebase init ailogic. Isso se provou uma abordagem antiga (provavelmente beta) e nos levou a uma série de erros de pacotes (npm install) e de compilação (onChat is not defined, ERR_PACKAGE_PATH_NOT_EXPORTED, etc.).

Tentativa 2 (Sucesso - A "Abordagem Clássica"): Decidimos por uma "abordagem totalmente diferente", como sugerido.

Destruímos o backend quebrado (rm -rf functions).

Recriamos um backend limpo com firebase init functions (usando TypeScript).

Instalamos as bibliotecas corretas: @google-cloud/vertexai.

Depuração (Debugging): Enfrentamos e corrigimos uma série de erros de "acesso negado" que são comuns no desenvolvimento de nuvem:

403 Forbidden (SERVICE_DISABLED): Corrigido ao ativar a Vertex AI API no Google Cloud Console.

404 Not Found (Model not found): Corrigido ao mudar o nome do modelo de gemini-2.5-flash-001 (errado) para gemini-2.5-flash (correto).

400 Bad Request (mimeType not supported): Corrigido ao "travar" o mimeType da imagem para image/jpeg no backend, já que o Firebase Storage retornava um octet-stream genérico.

Fase 3: Persistência (Conectando Tudo)

Após a IA #1 retornar o JSON com sucesso, o app Swift (ContentView.swift) foi atualizado para chamar a função saveToFirestore(), que salva os dados na coleção despesas.

Fase 4: O Assistente (IA #2 - Insights)

O app Swift foi refatorado para usar um MainTabView, separando o "Escanear" do novo "Insights" (InsightsView.swift).

Uma nova Cloud Function, getinsights, foi criada. Ela usa o firebase-admin para ler a coleção despesas, envia o JSON para o Gemini 2.5 Flash com um novo prompt ("Seja um assistente financeiro..."), e retorna o texto do insight.

🤖 Arquitetura da IA (Firebase + Gemini 2.5 Flash)
O projeto utiliza duas funções de IA distintas que rodam no backend:

IA #1: analyzeimage (Extração de Dados)
SwiftUI (App) faz upload da foto (.jpg) para o Firebase Storage.

SwiftUI chama a Cloud Function analyzeimage, passando a downloadURL da imagem.

A função analyzeimage (Node.js) chama o Vertex AI.

Nós passamos o Prompt #1 (Extração) e a imagem para o Gemini 2.5 Flash, configurado para forçar uma resposta em JSON (responseMimeType: "application/json").

O Gemini retorna o JSON estruturado para a função.

A função retorna o JSON para o app Swift.

IA #2: getinsights (Assistente Financeiro)
SwiftUI (App) chama a Cloud Function getinsights (sem enviar dados).

A função getinsights (Node.js) usa o Firebase Admin SDK para ler todos os documentos da coleção despesas no Firestore.

A função converte esses documentos em uma string JSON.

A função chama o Vertex AI com o Prompt #2 (Assistente) e o JSON dos gastos.

O Gemini retorna uma string de texto (o insight).

A função retorna o texto para o app Swift.

Prompt 1: Extração de Dados (analyzeimage)
TypeScript

const systemPrompt = `Você é um especialista em extração de dados. Sua tarefa é analisar a imagem do cupom fiscal na URL fornecida e retornar APENAS um objeto JSON válido.
Não inclua \`\`\`json ... \`\`\` ou qualquer outro texto antes ou depois do objeto.
O JSON deve ter esta estrutura:
{
  "estabelecimento": "string",
  "valor_total": "string (ex: '44.40')",
  "data_transacao": "string (formato ISO YYYY-MM-DDTHH:mm:ss, se a hora não estiver visível, use T00:00:00)",
  "categoria": "string (Alimentação, Transporte, Lazer, Moradia, Saúde, Outros)"
}`;
Prompt 2: Geração de Insights (getinsights)
TypeScript

const systemPrompt_IA2 = `Você é um assistente financeiro sênior e amigável. O usuário enviará uma lista de suas despesas recentes em formato JSON. 
Sua tarefa é analisar essa lista e retornar um único parágrafo de insight (em português do Brasil). 
Seja direto e acionável. 
Exemplo: "Notei que a maior parte dos seus gastos (R$ 120,50) foi com Alimentação. Tente focar em cozinhar em casa para economizar."
Não diga "Olá" ou "Com base nos seus dados". Vá direto ao insight.`;

🖼️ Exemplos de Respostas

Combinado. Este é o último passo e um dos mais importantes para a sua nota.

Aqui está um "esqueleto" completo para o seu README.md. Eu já preenchi 90% dele com base em tudo o que fizemos. Você só precisa copiar, colar no seu arquivo README.md no VS Code (ou direto no GitHub) e adicionar as capturas de tela.

(Copie e cole tudo abaixo desta linha no seu README.md)

CupomGPT: Assistente Financeiro com IA Generativa
Projeto de Checkpoint (CP6) para a matéria de AI Engineering, Cognitive and Semantic Computation. O objetivo é um aplicativo mobile iOS que utiliza IA Generativa (Gemini 2.5 Flash) para extrair dados de cupons fiscais e gerar insights financeiros personalizados.

🚀 Tecnologias Utilizadas
Frontend: Swift & SwiftUI (iOS Nativo)

Backend: Firebase (Cloud Functions, Firestore, Storage)

Inteligência Artificial: Google Vertex AI (com o modelo Gemini 2.5 Flash)

Ferramentas de Desenvolvimento: Xcode, Visual Studio Code, GitHub Copilot

✨ Funcionalidades
O aplicativo cumpre todos os requisitos obrigatórios da atividade:

[X] Captura de Imagem: O usuário pode selecionar um cupom fiscal da galeria do dispositivo (ou tirar uma foto, em um dispositivo físico).

[X] IA #1: Extração de Dados: Uma Cloud Function (analyzeimage) usa o Gemini 2.5 Flash para analisar a imagem e extrair os dados estruturados (Valor, Data, Estabelecimento, Categoria) em formato JSON.

[X] Persistência de Dados: O JSON extraído é salvo automaticamente em uma coleção despesas no Firebase Firestore.

[X] IA #2: Assistente de Insights: Uma segunda Cloud Function (getinsights) lê todos os cupons salvos no Firestore, envia os dados para o Gemini 2.5 Flash e gera um insight financeiro personalizado em linguagem natural.

[X] Uso do Copilot: O GitHub Copilot foi utilizado para auxiliar na escrita de código, como detalhado abaixo.

🛠️ Etapas de Desenvolvimento (A Nossa Jornada)
O desenvolvimento foi dividido em fases claras, com um grande foco na depuração e na correção de arquitetura do backend.

Fase 1: Setup do Frontend (Swift & Xcode)

Criação do projeto iOS no Xcode (CupomGPT).

Configuração da interface principal (ContentView.swift) com SwiftUI, incluindo o seletor de fotos (PhotosPicker) e a área de exibição.

Instalação dos SDKs do Firebase (Core, Storage, Functions, Firestore) via Swift Package Manager.

Fase 2: A Odisseia do Backend (IA #1 - Extração)

Tentativa 1 (Falha): Iniciamos com a arquitetura firebase init ailogic. Isso se provou uma abordagem antiga (provavelmente beta) e nos levou a uma série de erros de pacotes (npm install) e de compilação (onChat is not defined, ERR_PACKAGE_PATH_NOT_EXPORTED, etc.).

Tentativa 2 (Sucesso - A "Abordagem Clássica"): Decidimos por uma "abordagem totalmente diferente", como sugerido.

Destruímos o backend quebrado (rm -rf functions).

Recriamos um backend limpo com firebase init functions (usando TypeScript).

Instalamos as bibliotecas corretas: @google-cloud/vertexai.

Depuração (Debugging): Enfrentamos e corrigimos uma série de erros de "acesso negado" que são comuns no desenvolvimento de nuvem:

403 Forbidden (SERVICE_DISABLED): Corrigido ao ativar a Vertex AI API no Google Cloud Console.

404 Not Found (Model not found): Corrigido ao mudar o nome do modelo de gemini-2.5-flash-001 (errado) para gemini-2.5-flash (correto).

400 Bad Request (mimeType not supported): Corrigido ao "travar" o mimeType da imagem para image/jpeg no backend, já que o Firebase Storage retornava um octet-stream genérico.

Fase 3: Persistência (Conectando Tudo)

Após a IA #1 retornar o JSON com sucesso, o app Swift (ContentView.swift) foi atualizado para chamar a função saveToFirestore(), que salva os dados na coleção despesas.

Fase 4: O Assistente (IA #2 - Insights)

O app Swift foi refatorado para usar um MainTabView, separando o "Escanear" do novo "Insights" (InsightsView.swift).

Uma nova Cloud Function, getinsights, foi criada. Ela usa o firebase-admin para ler a coleção despesas, envia o JSON para o Gemini 2.5 Flash com um novo prompt ("Seja um assistente financeiro..."), e retorna o texto do insight.

🤖 Arquitetura da IA (Firebase + Gemini 2.5 Flash)
O projeto utiliza duas funções de IA distintas que rodam no backend:

IA #1: analyzeimage (Extração de Dados)
SwiftUI (App) faz upload da foto (.jpg) para o Firebase Storage.

SwiftUI chama a Cloud Function analyzeimage, passando a downloadURL da imagem.

A função analyzeimage (Node.js) chama o Vertex AI.

Nós passamos o Prompt #1 (Extração) e a imagem para o Gemini 2.5 Flash, configurado para forçar uma resposta em JSON (responseMimeType: "application/json").

O Gemini retorna o JSON estruturado para a função.

A função retorna o JSON para o app Swift.

IA #2: getinsights (Assistente Financeiro)
SwiftUI (App) chama a Cloud Function getinsights (sem enviar dados).

A função getinsights (Node.js) usa o Firebase Admin SDK para ler todos os documentos da coleção despesas no Firestore.

A função converte esses documentos em uma string JSON.

A função chama o Vertex AI com o Prompt #2 (Assistente) e o JSON dos gastos.

O Gemini retorna uma string de texto (o insight).

A função retorna o texto para o app Swift.

🗣️ Prompts Utilizados
Prompt 1: Extração de Dados (analyzeimage)
TypeScript

const systemPrompt = `Você é um especialista em extração de dados. Sua tarefa é analisar a imagem do cupom fiscal na URL fornecida e retornar APENAS um objeto JSON válido.
Não inclua \`\`\`json ... \`\`\` ou qualquer outro texto antes ou depois do objeto.
O JSON deve ter esta estrutura:
{
  "estabelecimento": "string",
  "valor_total": "string (ex: '44.40')",
  "data_transacao": "string (formato ISO YYYY-MM-DDTHH:mm:ss, se a hora não estiver visível, use T00:00:00)",
  "categoria": "string (Alimentação, Transporte, Lazer, Moradia, Saúde, Outros)"
}`;
Prompt 2: Geração de Insights (getinsights)
TypeScript

const systemPrompt_IA2 = `Você é um assistente financeiro sênior e amigável. O usuário enviará uma lista de suas despesas recentes em formato JSON. 
Sua tarefa é analisar essa lista e retornar um único parágrafo de insight (em português do Brasil). 
Seja direto e acionável. 
Exemplo: "Notei que a maior parte dos seus gastos (R$ 120,50) foi com Alimentação. Tente focar em cozinhar em casa para economizar."
Não diga "Olá" ou "Com base nos seus dados". Vá direto ao insight.`;
🖼️ Exemplos de Respostas
IA #1: Extração de Dados
Cupom Analisado: [COLE AQUI O PRINT DO SEU CUPOM DENTRO DO APP (COMO ESTE)]

JSON Gerado (Exibido no App):

JSON

{
  "valor_total" : "44.40",
  "estabelecimento" : "PIMENTA VERDE ALIMENTOS LTDA",
  "data_transacao" : "2025-11-07T15:43:00",
  "categoria" : "Alimentação"
}
IA #2: Assistente de Insights
Insight Gerado (Exibido no App):

[COLE AQUI O PRINT DO SEU INSIGHT NO APP (COMO ESTE)]

(Exemplo de texto: "Notei que 100% dos seus gastos recentes (R$ 180,42) foram com Alimentação. Tentar planejar refeições e cozinhar mais em casa pode ser uma ótima maneira de economizar.")

🤖 Trechos de Código Assistidos pelo GitHub Copilot
O GitHub Copilot foi essencial durante o desenvolvimento no VS Code, principalmente para lidar com a sintaxe do Node.js, do npm e do TypeScript.

Exemplo 1: Leitura do Firestore (Node.js)
Eu precisei ler todos os documentos da coleção despesas.

Meu "Prompt" (Comentário):

TypeScript

// Ler TODAS as despesas do Firestore
Resultado do Copilot:

TypeScript

const despesasSnapshot = await db.collection("despesas").get();
    
if (despesasSnapshot.empty) {
  return "Não há dados de despesas para analisar. Comece escaneando alguns cupons!";
}

// Converter os dados para um JSON que a IA entenda
const despesas = despesasSnapshot.docs.map(doc => doc.data());
const despesasJson = JSON.stringify(despesas);
Exemplo 2: Formatar JSON (Swift)
Eu precisei de uma função para exibir o JSON de forma legível no app.

Meu "Prompt" (Comentário):

Swift

// Função "ajudante" para formatar um dicionário [String: Any] como um JSON string bonito
Resultado do Copilot:

Swift

func prettyPrint(data: [String: Any]) -> String {
    do {
        let jsonData = try JSONSerialization.data(withJSONObject: data, options: .prettyPrinted)
        if let jsonString = String(data: jsonData, encoding: .utf8) {
            return jsonString.replacingOccurrences(of: "\\/", with: "/") // Corrige barras
        }
    } catch {
        return "Erro ao formatar JSON: \(error.localizedDescription)"
    }
    return "Não foi possível formatar o JSON."
}
Exemplo 3: Salvar no Firestore (Swift)
Eu precisei salvar o JSON recebido da IA #1 no banco de dados.

Meu "Prompt" (Comentário):

Swift

// Salva um dicionário [String: Any] na coleção 'despesas' do Firestore
Resultado do Copilot:

Swift

func saveToFirestore(data: [String: Any]) {
    let db = Firestore.firestore()
    
    db.collection("despesas").addDocument(data: data) { error in
        if let error = error {
            print("Erro ao salvar no Firestore: \(error.localizedDescription)")
        } else {
            print("Dados salvos no Firestore com sucesso!")
        }
    }
}