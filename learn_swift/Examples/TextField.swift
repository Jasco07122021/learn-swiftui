import SwiftUI
import Combine

struct ExampleTextFieldView: View {
    var body: some View {
        VStackTextFieldView()
    }
}

struct VStackTextFieldView: View {
    @State private var text1 = ""
    @State private var text2 = ""
    
    @FocusState private var focusedField: FieldID?
    
    enum FieldID: String, Hashable {
        case textField1
        case textField2
    }
    
    @State var isKeyboardVisible = KeyboardObserver.shared.isKeyboardVisible
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 16) {
                    PlaceholderView()
                        .frame(height: 600)
                    
                    CustomTextField(
                        title: "Text Field 1",
                        text: $text1,
                        id: FieldID.textField1,
                        focusedField: $focusedField,
                        proxy: proxy
                    )
                    
                    CustomTextField(
                        title: "Text Field 2",
                        text: $text2,
                        id: FieldID.textField2,
                        focusedField: $focusedField,
                        proxy: proxy
                    )
                }
                .padding()
            }
            .onChange(of: focusedField) { newValue in
                if let field = newValue {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation {
                            proxy.scrollTo(field)
                        }
                    }
                }
            }
        }
        .padding(.bottom, isKeyboardVisible ? 10.0 : 0.0)
        .onAppear {
            KeyboardObserver.shared.startListening()
        }
        .onDisappear {
            KeyboardObserver.shared.stopListening()
        }
    }
}

// MARK: - Reusable TextField Component
struct CustomTextField: View {
    let title: String
    @Binding var text: String
    let id: VStackTextFieldView.FieldID
    @FocusState.Binding var focusedField: VStackTextFieldView.FieldID?
    let proxy: ScrollViewProxy
    
    var body: some View {
        TextField(title, text: $text)
            .padding(12)
            .frame(height: 48)
            .background(Color(.systemGray6))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.4), lineWidth: 1)
            )
            .id(id)
            .focused($focusedField, equals: id)
            .onTapGesture {
                focusedField = id
            }
            .submitLabel(.next)
    }
}

// MARK: - Placeholder
struct PlaceholderView: View {
    var body: some View {
        Text("Placeholder Content")
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
    }
}


class KeyboardObserver: ObservableObject {
    static let shared = KeyboardObserver()

    private var keyboardWillShowObserver: AnyCancellable?
    private var keyboardWillHideObserver: AnyCancellable?

    @Published var isKeyboardVisible = false
    @Published var keyboardHeight: CGFloat = 0
    
    private init() {}
    
    // Start observing keyboard notifications
    func startListening() {
        keyboardWillShowObserver = NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
            .sink { notification in
                self.handleKeyboardWillShow(notification)
            }
        
        keyboardWillHideObserver = NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
            .sink { notification in
                self.handleKeyboardWillHide(notification)
            }
    }
    
    // Stop observing keyboard notifications
    func stopListening() {
        keyboardWillShowObserver?.cancel()
        keyboardWillHideObserver?.cancel()
    }
    
    private func handleKeyboardWillShow(_ notification: Notification) {
        guard let userInfo = notification.userInfo else { return }
        if let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
            withAnimation {
                self.isKeyboardVisible = true
                self.keyboardHeight = keyboardFrame.height
            }
        }
    }
    
    private func handleKeyboardWillHide(_ notification: Notification) {
        withAnimation {
            self.isKeyboardVisible = false
            self.keyboardHeight = 0
        }
    }
}
