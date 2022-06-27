import Foundation

protocol NodeSelectionViewModelFactoryProtocol {
    func buildViewModel(
        from chain: ChainModel,
        locale: Locale,
        cellsDelegate: NodeSelectionTableCellViewModelDelegate?
    ) -> NodeSelectionViewModel
    func buildDeleteNodeAlertViewModel(
        node: ChainNodeModel,
        locale: Locale,
        deleteHandler: @escaping () -> Void
    ) -> AlertPresentableViewModel
}

class NodeSelectionViewModelFactory: NodeSelectionViewModelFactoryProtocol {
    func buildViewModel(
        from chain: ChainModel,
        locale: Locale,
        cellsDelegate: NodeSelectionTableCellViewModelDelegate?
    ) -> NodeSelectionViewModel {
        let defaultNodeCellViewModels: [NodeSelectionTableCellViewModel] = chain.nodes.compactMap { node in
            NodeSelectionTableCellViewModel(
                node: node,
                selected: node.url == chain.selectedNode?.url,
                selectable: chain.selectedNode != nil,
                editable: false,
                delegate: cellsDelegate
            )
        }

        let customNodeCellViewModels: [NodeSelectionTableCellViewModel] = chain.customNodes.map { node in
            NodeSelectionTableCellViewModel(
                node: node,
                selected: node.url == chain.selectedNode?.url,
                selectable: chain.selectedNode != nil,
                editable: true,
                delegate: cellsDelegate
            )
        }

        var sections: [NodeSelectionTableSection] = []

        if !customNodeCellViewModels.isEmpty {
            sections.append(NodeSelectionTableSection(
                title: R.string.localizable.connectionManagementCustomTitle(preferredLanguages: locale.rLanguages).uppercased(),
                viewModels: customNodeCellViewModels
            ))
        }

        if !defaultNodeCellViewModels.isEmpty {
            sections.append(NodeSelectionTableSection(
                title: R.string.localizable.connectionManagementDefaultTitle(preferredLanguages: locale.rLanguages).uppercased(),
                viewModels: defaultNodeCellViewModels
            ))
        }

        return NodeSelectionViewModel(
            title: chain.name,
            autoSelectEnabled: chain.selectedNode == nil,
            sections: sections
        )
    }

    func buildDeleteNodeAlertViewModel(
        node: ChainNodeModel,
        locale: Locale,
        deleteHandler: @escaping () -> Void
    ) -> AlertPresentableViewModel {
        let deleteAction = AlertPresentableAction(
            title: R.string.localizable.connectionDeleteConfirm(preferredLanguages: locale.rLanguages),
            style: .destructive,
            handler: deleteHandler
        )

        return AlertPresentableViewModel(
            title: R.string.localizable.nodeSelectionDeleteNodeTitle(preferredLanguages: locale.rLanguages),
            message: node.name,
            actions: [deleteAction],
            closeAction: R.string.localizable.commonClose(preferredLanguages: locale.rLanguages)
        )
    }
}
