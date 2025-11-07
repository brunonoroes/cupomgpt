// 1. Importações do Firebase
import * as logger from "firebase-functions/logger";
import { onCall, HttpsError } from "firebase-functions/v2/https";

// 2. Importação da IA (Vertex AI)
import { VertexAI } from "@google-cloud/vertexai";

// 3. Importação do Firestore (PARA LER OS DADOS)
import { initializeApp, getApps } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";

// 4. Inicializar o Firebase (para o Firestore)
// Isso nos dá acesso ao banco de dados
if (getApps().length === 0) {
  initializeApp();
}
const db = getFirestore();

// ===================================================================
// IA #1: ANALISAR IMAGEM (O que já fizemos)
// ===================================================================

const systemPrompt_IA1 = `Você é um especialista em extração de dados. Sua tarefa é analisar a imagem do cupom fiscal na URL fornecida e retornar APENAS um objeto JSON válido.
Não inclua \`\`\`json ... \`\`\` ou qualquer outro texto antes ou depois do objeto.
O JSON deve ter esta estrutura:
{
  "estabelecimento": "string",
  "valor_total": "string (ex: '44.40')",
  "data_transacao": "string (formato ISO YYYY-MM-DDTHH:mm:ss, se a hora não estiver visível, use T00:00:00)",
  "categoria": "string (Alimentação, Transporte, Lazer, Moradia, Saúde, Outros)"
}`;

export const analyzeimage = onCall(async (request) => {
  const imageUrl = request.data; 

  if (typeof imageUrl !== 'string' || !imageUrl) {
    throw new HttpsError("invalid-argument", "A requisição deve conter uma URL de imagem como 'data'.");
  }
  
  logger.info("Função 'analyzeimage' chamada com a URL:", imageUrl);

  try {
    const vertexAI = new VertexAI({
        project: process.env.GCLOUD_PROJECT,
        location: "us-central1",
    });
    
    const model = vertexAI.getGenerativeModel({
        model: "gemini-2.5-flash", 
        systemInstruction: { role: "system", parts: [{ text: systemPrompt_IA1 }] },
    });

    const imageResponse = await fetch(imageUrl);
    const imageBuffer = await imageResponse.arrayBuffer();
    const imageBase64 = Buffer.from(imageBuffer).toString("base64");

    const imagePart = {
      inlineData: { data: imageBase64, mimeType: "image/jpeg" },
    };

    const result = await model.generateContent({
        contents: [{ role: "user", parts: [imagePart] }],
        generationConfig: { responseMimeType: "application/json" },
    });

    const response = result.response;
    const part = response?.candidates?.[0]?.content?.parts?.[0];

    if (!part || !part.text) {
        throw new HttpsError("internal", "A IA retornou uma resposta vazível.");
    }
    
    const jsonObject = part.text;
    logger.info("IA retornou:", jsonObject);
    return JSON.parse(jsonObject);

  } catch (err) {
    logger.error("Erro ao chamar a API do Vertex AI:", err);
    throw new HttpsError("internal", "Falha ao analisar a imagem com a IA.", err);
  }
});


// ===================================================================
// IA #2: GERAR INSIGHT (O novo Assistente)
// ===================================================================

const systemPrompt_IA2 = `Você é um assistente financeiro sênior e amigável. O usuário enviará uma lista de suas despesas recentes em formato JSON. 
Sua tarefa é analisar essa lista e retornar um único parágrafo de insight (em português do Brasil). 
Seja direto e acionável. 
Exemplo: "Notei que a maior parte dos seus gastos (R$ 120,50) foi com Alimentação. Tente focar em cozinhar em casa para economizar."
Não diga "Olá" ou "Com base nos seus dados". Vá direto ao insight.`;

export const getinsights = onCall(async (request) => {
  logger.info("Função 'getinsights' chamada...");

  try {
    // 1. Ler TODAS as despesas do Firestore
    const despesasSnapshot = await db.collection("despesas").get();
    
    if (despesasSnapshot.empty) {
      return "Não há dados de despesas para analisar. Comece escaneando alguns cupons!";
    }
    
    // 2. Converter os dados para um JSON que a IA entenda
    const despesas = despesasSnapshot.docs.map(doc => doc.data());
    const despesasJson = JSON.stringify(despesas);
    
    // 3. Inicializar a IA
    const vertexAI = new VertexAI({
        project: process.env.GCLOUD_PROJECT,
        location: "us-central1",
    });
    
    const model = vertexAI.getGenerativeModel({
        model: "gemini-2.5-flash", // Usando o 2.5 Flash de novo
        systemInstruction: { role: "system", parts: [{ text: systemPrompt_IA2 }] },
    });

    // 4. Chamar a IA com o JSON dos gastos
    const result = await model.generateContent({
        contents: [{ role: "user", parts: [{ text: despesasJson }] }],
    });

    // 5. Retornar a resposta em TEXTO
    const response = result.response;
    const insightText = response?.candidates?.[0]?.content?.parts?.[0]?.text;

    if (!insightText) {
        throw new HttpsError("internal", "A IA (IA #2) retornou uma resposta vazia.");
    }
    
    logger.info("Insight gerado:", insightText);
    return insightText; // Retorna a string de insight para o Swift

  } catch (err) {
    logger.error("Erro ao gerar insight:", err);
    throw new HttpsError("internal", "Falha ao gerar o insight.", err);
  }
});