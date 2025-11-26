import WidgetKit
import SwiftUI

@main
struct Poem_Of_The_Day_WidgetBundle: WidgetBundle {
    var body: some Widget {
        Poem_Of_The_Day_Widget()
        
        if #available(iOS 18.0, *) {
            Poem_of_the_Day_WidgetControl()
        }
    }
}
