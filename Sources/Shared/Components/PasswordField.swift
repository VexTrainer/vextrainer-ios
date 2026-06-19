//
//  PasswordField.swift
//  VexTrainer
//
//  SecureField with a show/hide toggle in the trailing edge. Toggling between
//  SecureField and TextField is a SwiftUI quirk — we use a Group with explicit
//  branches rather than a ternary, otherwise the focus state can drop.
//

import SwiftUI

struct PasswordField: View {
    let placeholder: String
    @Binding var text: String
    var contentType: UITextContentType = .password
    var onSubmit: (() -> Void)?

    @State private var isVisible = false
    @FocusState private var isFocused: Bool

    var body: some View {
        ZStack(alignment: .trailing) {
            Group {
                if isVisible {
                    TextField(placeholder, text: $text)
                        .focused($isFocused)
                } else {
                    SecureField(placeholder, text: $text)
                        .focused($isFocused)
                }
            }
            .textContentType(contentType)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .onSubmit { onSubmit?() }
            .submitLabel(onSubmit == nil ? .next : .go)
            .vexFieldStyle()
            .padding(.trailing, 40)   // make room for the toggle

            Button {
                isVisible.toggle()
                // Re-focus after toggling so the keyboard doesn't dismiss.
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 50_000_000)
                    isFocused = true
                }
            } label: {
                Image(systemName: isVisible ? "eye.slash" : "eye")
                    .foregroundStyle(.white.opacity(0.5))
                    .frame(width: 40, height: 40)
            }
        }
    }
}
