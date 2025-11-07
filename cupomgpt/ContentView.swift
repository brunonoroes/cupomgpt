import SwiftUI
import PhotosUI // Pacote para o seletor de fotos moderno
import FirebaseStorage // Para o upload da imagem
import FirebaseFunctions // Para chamar a IA
import FirebaseFirestore // Para salvar no banco de dados
import UIKit // Para manipular a imagem

struct ContentView: View {
    
    // 1. Estados da Imagem
    @State private var selectedImageData: Data?
    @State private var selectedImage: UIImage?
    
    // 2. Estado do Seletor
    @State private var selectedItem: PhotosPickerItem?

    // 3. Estados da Interface
    @State private var analysisResult: String = "Nenhum cupom selecionado."
    @State private var isLoading: Bool = false

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("CupomGPT")
                    .font(.largeTitle)
                    .bold()

                // --- 1. ÁREA DE VISUALIZAÇÃO DA IMAGEM ---
                if let selectedImage {
                    Image(uiImage: selectedImage)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 300)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.gray, lineWidth: 1)
                        )
                } else {
                    Image(systemName: "receipt.fill")
                        .font(.system(size: 150))
                        .foregroundColor(.gray.opacity(0.3))
                        .frame(height: 300)
                }

                // --- 2. BOTÃO DE SELECIONAR FOTO ---
                PhotosPicker(
                    selection: $selectedItem,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    Text(selectedImage == nil ? "1. Selecionar Cupom" : "Trocar Cupom")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .onChange(of: selectedItem) { newItem in
                    Task {
                        if let data = try? await newItem?.loadTransferable(type: Data.self) {
                            selectedImageData = data
                            selectedImage = UIImage(data: data)
                            analysisResult = "Imagem carregada. Clique em 'Analisar'."
                        }
                    }
                }

                // --- 3. BOTÃO DE ANALISAR ---
                Button(action: startAnalysis) {
                    if isLoading {
                        ProgressView()
                    } else {
                        Text("2. Analisar Cupom")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(selectedImage == nil ? Color.gray : Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)
                .disabled(selectedImage == nil || isLoading)

                // --- 4. ÁREA DE RESULTADO DA IA ---
                TextEditor(text: .constant(analysisResult))
                    .frame(height: 200)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray, lineWidth: 1)
                    )
                
                Spacer()
            }
            .padding()
            .navigationTitle("Scanner")
            .navigationBarHidden(true)
        }
    }
    
    // --- NOSSAS FUNÇÕES LÓGICAS ---
    
    // Esta função "ajudante" formata o JSON para ficar bonito
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
    
    // Função para salvar os dados no Banco de Dados
    func saveToFirestore(data: [String: Any]) {
        let db = Firestore.firestore() // Pega a referência do banco de dados
        
        // "na coleção 'despesas', adicione este novo documento (o 'data')"
        db.collection("despesas").addDocument(data: data) { error in
            if let error = error {
                print("Erro ao salvar no Firestore: \(error.localizedDescription)")
            } else {
                print("Dados salvos no Firestore com sucesso!")
            }
        }
    }
    
    func startAnalysis() {
        guard let imageData = selectedImageData else {
            analysisResult = "Erro: Nenhuma imagem selecionada."
            return
        }
        
        isLoading = true
        analysisResult = "Passo 1/3: Enviando imagem para a nuvem..."
        
        let fileName = "cupons/\(UUID().uuidString).jpg"
        let storageRef = Storage.storage().reference(withPath: fileName)
        
        storageRef.putData(imageData, metadata: nil) { metadata, error in
            if let error = error {
                analysisResult = "Erro no Upload: \(error.localizedDescription)"
                isLoading = false
                return
            }
            
            analysisResult = "Passo 2/3: Imagem enviada. Pegando URL..."
            
            storageRef.downloadURL { url, error in
                guard let downloadURL = url else {
                    analysisResult = "Erro ao pegar URL: \(error?.localizedDescription ?? "desconhecido")"
                    isLoading = false
                    return
                }
                
                analysisResult = "Passo 3/3: Analisando imagem com IA..."
                
                // 5. CHAMA A IA com a URL da imagem
                callAILogic(url: downloadURL)
            }
        }
    }
    
    func callAILogic(url: URL) {
        let functions = Functions.functions()
        
        // O backend espera a URL como 'data' e retorna o JSON diretamente
        functions.httpsCallable("analyzeimage").call(url.absoluteString) { result, error in
            
            if let error = error {
                analysisResult = "Erro da IA: \(error.localizedDescription)"
                isLoading = false
                return
            }
            
            // O 'result.data' JÁ É o objeto JSON que queremos.
            if let data = result?.data as? [String: Any] {
                // 'data' é o seu JSON! Vamos formatá-lo para exibição
                analysisResult = "Análise Concluída!\n\n\(prettyPrint(data: data))"
                
                // SALVA NO FIREBASE
                saveToFirestore(data: data)
                
            } else {
                // Se a IA retornar algo que não é um [String: Any]
                analysisResult = "IA retornou um formato inesperado (não é [String: Any]): \(result?.data ?? "sem dados")"
            }
            
            isLoading = false // Desativa a rodinha de "carregando"
        }
    }
}

// --- PREVIEW (Apenas para o Xcode ver) ---
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
