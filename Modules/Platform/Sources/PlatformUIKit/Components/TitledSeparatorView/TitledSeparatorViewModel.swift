// Copyright © Blockchain Luxembourg S.A. All rights reserved.

public struct TitledSeparatorViewModel {
    let titleLabelContent: LabelContent
    let separatorColor: Color
    let accessibility: Accessibility

    public init(title: String = "", separatorColor: Color = .clear, accessibilityId: String = "") {
        self.titleLabelContent = LabelContent(
            text: title,
            font: .main(.semibold, 12),
            color: .titleText
        )
        self.separatorColor = separatorColor
        self.accessibility = .id(accessibilityId)
    }
}
