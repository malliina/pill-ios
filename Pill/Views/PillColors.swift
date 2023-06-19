import Foundation
import SwiftUI

class PillColors {
    static let shared = PillColors()
    
    let primaryBackground = Color.white
    let almostWhite = Color(r: 244, g: 244, b: 244, alpha: 1.0)
    var secondaryBackground: Color { almostWhite }
}

extension View {
    var colors: PillColors { PillColors.shared }
}

extension Color {
    init(r: Int, g: Int, b: Int, alpha: CGFloat) {
        let redPart: CGFloat = CGFloat(r) / 255
        let greenPart: CGFloat = CGFloat(g) / 255
        let bluePart: CGFloat = CGFloat(b) / 255
        
        self.init(uiColor: UIColor(red: redPart, green: greenPart, blue: bluePart, alpha: alpha))
    }
}
