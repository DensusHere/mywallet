// Copyright © Blockchain Luxembourg S.A. All rights reserved.

public struct TitledSeparatorViewModel {
    let titleLabelContent: LabelContent
    let separatorColor: UIColor
    let accessibility: Accessibility

    public init(title: String = "", separatorColor: UIColor = .clear, accessibilityId: String = "") {
        self.titleLabelContent = LabelContent(
            text: title,
            font: .main(.semibold, 12),
            color: .semantic.title
        )
        self.separatorColor = separatorColor
        self.accessibility = .id(accessibilityId)
    }
}
