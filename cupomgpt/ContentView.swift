import SwiftUI
// import PhotosUI (NÃO PRECISAMOS MAIS DELE)
import FirebaseStorage // Para o upload da imagem
import FirebaseFunctions // Para chamar a IA
import FirebaseFirestore // Para salvar no banco de dados
import UIKit // PARA A CÂMERA E A IMAGEM

// --- INÍCIO DO CÓDIGO DA CÂMERA ---
// Este é o "tradutor" que permite o SwiftUI usar a câmera do UIKit
struct CameraPicker: UIViewControllerRepresentable {
    
    @Binding var selectedImage: UIImage? // A imagem que o usuário tirar
    @Environment(\.presentationMode) private var presentationMode // Para fechar a câmera
    
    // 1. Cria o 'Controlador' da Câmera
    func makeUIViewController(context: UIViewControllerRepresentableContext<CameraPicker>) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator // Diz quem vai "escutar" os eventos
        picker.sourceType = .camera // FALA PARA USAR A CÂMERA DIRETAMENTE
        return picker
    }
    
    // 2. (Não precisamos fazer nada para atualizar)
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: UIViewControllerRepresentableContext<CameraPicker>) {
        // não precisa
    }
    
    // 3. Cria o "Ouvinte"
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // 4. A Classe "Ouvinte" (Coordinator)
    // Isso é o que "escuta" o usuário tirar a foto ou cancelar
    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        var parent: CameraPicker
        
        init(_ parent: CameraPicker) {
            self.parent = parent
        }
        
        // Função chamada QUANDO o usuário TIRA A FOTO
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
                parent.selectedImage = image // Envia a imagem de volta para o app
            }
            parent.presentationMode.wrappedValue.dismiss() // Fecha a câmera
        }
        
        // Função chamada se o usuário clicar em "Cancelar"
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss() // Fecha a câmera
        }
    }
}
// --- FIM DO CÓDIGO DA CÂMERA ---


// --- NOSSA TELA PRINCIPAL (MODIFICADA) ---
struct ContentView: View {
    
    // 1. Estados da Imagem
    @State private var selectedImageData: Data?
    @State private var selectedImage: UIImage? // Agora esta será a imagem da câmera
    
    // 2. Estado do Seletor
    // @State private var selectedItem: PhotosPickerItem? (NÃO PRECISAMOS MAIS)

    // 3. Estados da Interface
    @State private var analysisResult: String = "Nenhum cupom selecionado."
    @State private var isLoading: Bool = false
    @State private var showingCamera: Bool = false // Controla se a câmera está aberta

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

                // --- 2. BOTÃO DE ACIONAR A CÂMERA (MUDANÇA AQUI) ---
                Button(action: {
                    self.showingCamera = true // Manda abrir a câmera
                }) {
                    Text(selectedImage == nil ? "1. Escanear Cupom (CâMERA)" : "Tirar Nova Foto")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                // Esta "planilha" (sheet) abre a câmera
                .sheet(isPresented: $showingCamera) {
                    CameraPicker(selectedImage: $selectedImage)
                }
                // Esta função é chamada QUANDO a câmera entrega uma foto
                .onChange(of: selectedImage) { newImage in
                    guard let newImage = newImage else { return }
                    // Convertemos a imagem para dados (JPEG) para o upload
                    self.selectedImageData = newImage.jpegData(compressionQuality: 0.8)
                    self.analysisResult = "Imagem capturada. Clique em 'Analisar'."
                }

                // --- 3. BOTÃO DE ANALISAR (Sem mudanças) ---
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

                // --- 4. ÁREA DE RESULTADO DA IA (Sem mudanças) ---
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
    
    // --- NOSSAS FUNÇÕES LÓGICAS (Sem mudanças) ---
    
    func prettyPrint(data: [String: Any]) -> String {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: data, options: .prettyPrinted)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                return jsonString.replacingOccurrences(of: "\\/", with: "/")
            }
        } catch {
            return "Erro ao formatar JSON: \(error.localizedDescription)"
        }
        return "Não foi possível formatar o JSON."
    }
    
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
                callAILogic(url: downloadURL)
            }
        }
    }
    
    func callAILogic(url: URL) {
        let functions = Functions.functions()
        
        functions.httpsCallable("analyzeimage").call(url.absoluteString) { result, error in
            
            if let error = error {
                analysisResult = "Erro da IA: \(error.localizedDescription)"
                isLoading = false
                return
            }
            
            if let data = result?.data as? [String: Any] {
                analysisResult = "Análise Concluída!\n\n\(prettyPrint(data: data))"
                saveToFirestore(data: data)
                
            } else {
                analysisResult = "IA retornou um formato inesperado: \(result?.data ?? "sem dados")"
            }
            
            isLoading = false
        }
    }
}

// --- PREVIEW (Apenas para o Xcode ver) ---
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
