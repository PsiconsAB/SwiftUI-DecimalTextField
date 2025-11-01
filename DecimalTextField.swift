// DecimalTextField.swift
// A SwiftUI numeric input field that:
// - Accepts both . and , as decimal separator
// - Uses NumberFormatter for display
// - Formats only when editing ends
// - Blocks invalid input
// - No external dependencies

import SwiftUI

// DecimalTextField
struct DecimalTextField: View {
    private let placeholder: String
    private let formatter: NumberFormatter
    
    @Binding var value: Double
    
    @State private var text: String = ""
    @State private var isEditing = false
    @State private var allowedCharacters: String = "0123456789.,-"
    
    init(_ placeholder: String, value: Binding<Double>, formatter: NumberFormatter) {
        self.placeholder = placeholder
        self._value = value
        self.formatter = formatter
    }
    
    var body: some View {
        TextField(placeholder, text: $text)
            .keyboardType(.decimalPad)
            .onAppear {
                updateTextFromValue()
                setupAllowedCharacters()
            }
            .onChange(of: value) { _ in
                if !isEditing { updateTextFromValue() }
            }
            .onChange(of: text) { newText in
                guard isEditing else { return }
                
                // 1. FILTER
                let allowed = CharacterSet(charactersIn: allowedCharacters)
                let filtered = newText.unicodeScalars.filter { allowed.contains($0) }
                var cleaned = String(filtered)
                
                // 2. UNIFY SEPARATOR (use formatter's)
                let sep = formatter.decimalSeparator ?? "."
                cleaned = cleaned
                    .replacingOccurrences(of: ",", with: sep)
                    .replacingOccurrences(of: ".", with: sep)
                
                // 3. ONE DECIMAL
                let parts = cleaned.components(separatedBy: sep)
                if parts.count > 2 {
                    cleaned = parts[0] + sep + parts.dropFirst().joined()
                }
                
                // 4. MINUS AT START
                if cleaned.contains("-") && !cleaned.hasPrefix("-") {
                    cleaned = cleaned.replacingOccurrences(of: "-", with: "")
                }
                
                // 5. APPLY
                if cleaned != newText {
                    text = cleaned
                }
                
                // 6. PARSE (allow partial)
                if let number = formatter.number(from: cleaned)?.doubleValue {
                    value = number
                }
            }
            // EDITING STATE
            .onReceive(NotificationCenter.default.publisher(for: UITextField.textDidBeginEditingNotification)) { _ in
                isEditing = true
            }
            .onReceive(NotificationCenter.default.publisher(for: UITextField.textDidEndEditingNotification)) { _ in
                isEditing = false
                commitAndFormat()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
                if isEditing {
                    isEditing = false
                    commitAndFormat()
                }
            }
    }
    
    private func updateTextFromValue() {
        text = formatter.string(from: NSNumber(value: value)) ?? "0"
    }
    
    private func setupAllowedCharacters() {
        if formatter.maximumFractionDigits == 0 {
            allowedCharacters = "0123456789-"
        }
    }
    
    private func commitAndFormat() {
        let cleaned = text
            .replacingOccurrences(of: formatter.groupingSeparator, with: "")
        
        if let number = formatter.number(from: cleaned)?.doubleValue {
            value = number
        } else if text.isEmpty {
            value = 0.0
        }
        updateTextFromValue()
    }
}
//Example
struct ContentView: View {
    @State private var amount: Double = 1.0
    @State private var cost: Double = 5.23
    private let numberFormat: NumberFormatter =  {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.decimalSeparator = "."
        numberFormatter.minimumFractionDigits = 0
        numberFormatter.maximumFractionDigits = 2
        numberFormatter.groupingSeparator = ""
        return numberFormatter
    }()
    private let numberFormatComma: NumberFormatter =  {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.decimalSeparator = ","
        numberFormatter.minimumFractionDigits = 0
        numberFormatter.maximumFractionDigits = 2
        numberFormatter.groupingSeparator = ""
        return numberFormatter
    }()
    private let integerFormat: NumberFormatter =  {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.decimalSeparator = "."
        numberFormatter.minimumFractionDigits = 0
        numberFormatter.maximumFractionDigits = 0
        numberFormatter.groupingSeparator = ""
        numberFormatter.allowsFloats = false
        return numberFormatter
    }()
    var body: some View {
        Form {
            DecimalTextField("Amount", value: $amount, formatter: integerFormat)
                .textFieldStyle(.roundedBorder)
            DecimalTextField("Cost", value: $cost, formatter: numberFormatComma)
                .textFieldStyle(.roundedBorder)

            Text("Amount: \(integerFormat.string(from: NSNumber(value: amount)) ?? String(format: "%.2f", amount))")
                .font(.title3)
            Text("Cost: \(numberFormatComma.string(from: NSNumber(value: cost)) ?? String(format: "%.0f", cost))").font(.title3)
        }
        .padding()
        Text("Total: \(numberFormatComma.string(from: NSNumber(value: cost * amount)) ?? String(format: "%.2f", cost))").font(.title3)
    }
}

