import SwiftUI
import UIKit

struct WindowAccessor: UIViewRepresentable {
    @Binding var window: UIWindow?
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        DispatchQueue.main.async {
            self.window = view.window
        }
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}

extension View {
    func withWindowAccessor(window: Binding<UIWindow?>) -> some View {
        self.background(WindowAccessor(window: window))
    }
}
