import SwiftUI
import FirebaseFunctions

struct InsightsView: View {
    
    @State private var insightText: String = "Clique no botão para gerar um insight financeiro com base nos seus cupons salvos."
    @State private var isLoading: Bool = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Área de exibição do resultado
                TextEditor(text: .constant(insightText))
                    .frame(minHeight: 200, maxHeight: .infinity)
                    .padding(5)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray, lineWidth: 1)
                    )
                
                // Botão para chamar a IA #2
                Button(action: generateInsight) {
                    if isLoading {
                        ProgressView()
                            .padding(.horizontal)
                        Text("Pensando...")
                    } else {
                        Image(systemName: "sparkles")
                            .padding(.horizontal)
                        Text("Gerar Insight Financeiro")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(isLoading ? Color.gray : Color.purple)
                .foregroundColor(.white)
                .cornerRadius(10)
                .disabled(isLoading)
                
            }
            .padding()
            .navigationTitle("Assistente IA")
        }
    }
    
    // Esta será a nossa função para chamar a IA #2
    func generateInsight() {
        self.isLoading = true
        self.insightText = "Analisando seus gastos salvos no Firestore..."
        
        let functions = Functions.functions()
        
        // Vamos criar uma nova função "getinsights" no backend
        functions.httpsCallable("getinsights").call { result, error in
            if let error = error {
                self.insightText = "Erro ao gerar insight: \(error.localizedDescription)"
                self.isLoading = false
                return
            }
            
            // A IA #2 vai retornar apenas uma string de texto
            if let insight = result?.data as? String {
                self.insightText = insight
            } else {
                self.insightText = "A IA retornou um formato inesperado."
            }
            
            self.isLoading = false
        }
    }
}

#Preview {
    InsightsView()
}
