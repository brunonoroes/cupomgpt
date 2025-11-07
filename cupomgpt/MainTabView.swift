import SwiftUI

struct MainTabView: View {
    var body: some View {
        // O TabView é o contêiner que cria as abas na parte inferior
        TabView {
            // Aba 1: O Scanner (nosso ContentView antigo)
            ContentView() // Nosso app de scanner que já funciona
                .tabItem {
                    Label("Escanear", systemImage: "camera.viewfinder")
                }
            
            // Aba 2: O novo assistente de Insights
            InsightsView() // A nova tela que vamos criar a seguir
                .tabItem {
                    Label("Insights", systemImage: "chart.bar.xaxis")
                }
        }
    }
}

#Preview {
    MainTabView()
}
