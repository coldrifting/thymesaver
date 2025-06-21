import SwiftUI
import Combine

struct AmountPicker: View {
    @Binding var amount: Amount?
    @State var lastAmount: Amount? = nil
    
    @State private var type: UnitType = UnitType.count
    var typeBinding: Binding<UnitType> {
        Binding(
            get: { self.type },
            set: { self.type = $0 ; self.push() }
        )
    }
    
    @State private var text: String = ""
    var textBinding: Binding<String> {
        Binding(
            get: { self.text },
            set: { self.text = $0 ; self.push() }
        )
    }
    
    func push() {
        let fraction = Fraction(text)
        if (fraction.toDouble() > 0) {
            self.amount = Amount(Fraction(text), type: self.type)
        }
        else {
            self.amount = nil
        }
    }
    
    func pull(_ newAmount: Amount?) {
        // Avoid infinite loop
        if (newAmount != self.lastAmount) {
            if let newAmount = newAmount {
                self.type = newAmount.type
                let newText = newAmount.fraction.decimalString.deletingSuffix(".0")
                if (Fraction(self.text) != Fraction(newText)) {
                    self.text = newText
                }
            }
            else {
                self.type = UnitType.count
            }
        }
        self.lastAmount = newAmount
    }
    
    var body: some View {
        Group {
            Picker(
                "Unit Type",
                selection: self.typeBinding,
                content: {
                    ForEach(UnitType.allCases) { text in
                        Text(text.description)
                    }
                }
            )
            HStack {
                Text("Quantity")
                Spacer()
                TextField("Item Quantity", text: self.textBinding)
                    .multilineTextAlignment(.trailing)
            }
        }
        .onReceive(Just(self.amount)) { amount in
            self.pull(amount)
        }
    }
}
