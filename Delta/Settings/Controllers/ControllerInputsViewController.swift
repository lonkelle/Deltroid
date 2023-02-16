//
//  ControllerInputsViewController.swift
//  Delta
//
//  Created by Riley Testut on 7/1/17.
//  Copyright © 2017 Riley Testut. All rights reserved.
//

import Roxas
#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif



import DeltaCore

class ControllerInputsViewController: UIViewController {
    var gameController: GameController! {
        didSet {
            gameController.addReceiver(self, inputMapping: nil)
        }
    }

    var system: System = System.allCases[0] {
        didSet {
            guard system != oldValue else { return }
            updateSystem()
        }
    }

    private lazy var managedObjectContext: NSManagedObjectContext = DatabaseManager.shared.newBackgroundContext()
    private var inputMappings = [System: GameControllerInputMapping]()

    private let supportedActionInputs: [ActionInput] = [.quickSave, .quickLoad, .fastForward]

    private var gameViewController: DeltaCore.GameViewController!
    private var actionsMenuViewController: GridMenuViewController!

    private var calloutViews = [AnyInput: InputCalloutView]()

    private var activeCalloutView: InputCalloutView?

    private var _didLayoutSubviews = false

    @IBOutlet private var actionsMenuViewControllerHeightConstraint: NSLayoutConstraint!
    @IBOutlet private var cancelTapGestureRecognizer: UITapGestureRecognizer!

    override public var next: UIResponder? {
        return KeyboardResponder(nextResponder: super.next)
    }

#if !os(tvOS) && !os(macOS)
    override var shouldAutorotate: Bool {
        return false
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return .portrait
    }
#endif

    override func viewDidLoad() {
        super.viewDidLoad()

        gameViewController.controllerView.addReceiver(self)

        if let navigationController = navigationController, #available(iOS 13, tvOS 13, *) {
            navigationController.overrideUserInterfaceStyle = .dark
            navigationController.navigationBar.scrollEdgeAppearance = navigationController.navigationBar.standardAppearance // Fixes invisible navigation bar on iPad.
        } else {
            #if !os(tvOS) && !os(macOS)
            navigationController?.navigationBar.barStyle = .black
            #endif
        }

        NSLayoutConstraint.activate([gameViewController.gameView.centerYAnchor.constraint(equalTo: actionsMenuViewController.view.centerYAnchor)])

        preparePopoverMenuController()
        updateSystem()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if actionsMenuViewController.preferredContentSize.height > 0 {
            actionsMenuViewControllerHeightConstraint.constant = actionsMenuViewController.preferredContentSize.height
        }

        if let window = view.window, !_didLayoutSubviews {
            var traits = DeltaCore.ControllerSkin.Traits.defaults(for: window)
            traits.orientation = .portrait

            if traits.device == .ipad {
                // Use standard iPhone skins instead of iPad skins.
                traits.device = .iphone
                traits.displayType = .standard
            }

            gameViewController.controllerView.overrideControllerSkinTraits = traits

            _didLayoutSubviews = true
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if calloutViews.isEmpty {
            prepareCallouts()
        }

        // controllerView must be first responder to receive keyboard presses.
        gameViewController.controllerView.becomeFirstResponder()
    }
}

extension ControllerInputsViewController {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let identifier = segue.identifier else { return }

        switch identifier {
        case "embedGameViewController": gameViewController = segue.destination as? DeltaCore.GameViewController
        case "embedActionsMenuViewController":
            actionsMenuViewController = segue.destination as? GridMenuViewController
            prepareActionsMenuViewController()

        case "cancelControllerInputs": break
        case "saveControllerInputs":
            managedObjectContext.performAndWait {
                self.managedObjectContext.saveWithErrorLogging()
            }

        default: break
        }
    }
}

private extension ControllerInputsViewController {
    func makeDefaultInputMapping() -> GameControllerInputMapping {
        let deltaCoreInputMapping = gameController.defaultInputMapping as? DeltaCore.GameControllerInputMapping ?? DeltaCore.GameControllerInputMapping(gameControllerInputType: gameController.inputType)

        let inputMapping = GameControllerInputMapping(inputMapping: deltaCoreInputMapping, context: managedObjectContext)
        inputMapping.gameControllerInputType = gameController.inputType
        inputMapping.gameType = system.gameType

        if let controller = gameController, let playerIndex = controller.playerIndex {
            inputMapping.playerIndex = Int16(playerIndex)
        }

        return inputMapping
    }

    func updateSystem() {
        guard isViewLoaded else { return }

        // Update popoverMenuButton to display correctly on iOS 10.
        if let popoverMenuButton = navigationItem.popoverMenuController?.popoverMenuButton {
            popoverMenuButton.title = system.localizedShortName
            popoverMenuButton.bounds.size = popoverMenuButton.intrinsicContentSize

            navigationController?.navigationBar.layoutIfNeeded()
        }

        // Update controller view's controller skin.
        gameViewController.controllerView.controllerSkin = DeltaCore.ControllerSkin.standardControllerSkin(for: system.gameType)
        gameViewController.view.setNeedsUpdateConstraints()

        // Fetch input mapping if it hasn't already been fetched.
        if let gameController = gameController, inputMappings[system] == nil {
            managedObjectContext.performAndWait {
                let inputMapping = GameControllerInputMapping.inputMapping(for: gameController, gameType: self.system.gameType, in: self.managedObjectContext) ?? self.makeDefaultInputMapping()

                inputMapping.name = String.localizedStringWithFormat("Custom %@", gameController.name)

                self.inputMappings[self.system] = inputMapping
            }
        }

        // Update callouts, if view is already on screen.
        if view.window != nil {
            calloutViews.forEach { $1.dismissCallout(animated: true) }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.calloutViews = [:]
                self.prepareCallouts()
            }
        }
    }

    func preparePopoverMenuController() {
        let listMenuViewController = ListMenuViewController()
        listMenuViewController.title = NSLocalizedString("Game System", comment: "")

        let navigationController = UINavigationController(rootViewController: listMenuViewController)
        if #available(iOS 13, tvOS 13, *) {
            navigationController.navigationBar.scrollEdgeAppearance = navigationController.navigationBar.standardAppearance
        }

        let popoverMenuController = PopoverMenuController(popoverViewController: navigationController)
        navigationItem.popoverMenuController = popoverMenuController

        let items = System.allCases.map { [unowned self, weak popoverMenuController, weak listMenuViewController] system -> MenuItem in
            let item = MenuItem(text: system.localizedShortName, image: #imageLiteral(resourceName: "CheatCodes")) { [weak popoverMenuController, weak listMenuViewController] item in
                listMenuViewController?.items.forEach { $0.isSelected = ($0 == item) }
                popoverMenuController?.isActive = false

                self.system = system
            }
            item.isSelected = (system == self.system)

            return item
        }
        listMenuViewController.items = items
    }

    func prepareActionsMenuViewController() {
        var items = [MenuItem]()

        for input in supportedActionInputs {
            let image: UIImage
            let text: String

            switch input {
            case .quickSave:
                image = #imageLiteral(resourceName: "SaveSaveState")
                text = NSLocalizedString("Quick Save", comment: "")

            case .quickLoad:
                image = #imageLiteral(resourceName: "LoadSaveState")
                text = NSLocalizedString("Quick Load", comment: "")

            case .fastForward:
                image = #imageLiteral(resourceName: "FastForward")
                text = NSLocalizedString("Fast Forward", comment: "")

            case .toggleFastForward: continue
            }

            let item = MenuItem(text: text, image: image) { [unowned self] _ in
                guard let calloutView = self.calloutViews[AnyInput(input)] else { return }
                self.toggle(calloutView)
            }

            items.append(item)
        }

        actionsMenuViewController.items = items
        actionsMenuViewController.isVibrancyEnabled = false

        actionsMenuViewController.collectionView.backgroundColor = nil
    }

    func prepareCallouts() {
        guard
            let controllerView = gameViewController.controllerView,
            let traits = controllerView.controllerSkinTraits,
            let items = controllerView.controllerSkin?.items(for: traits),
            let controllerViewInputMapping = controllerView.defaultInputMapping,
            let inputMapping = inputMappings[system]
        else { return }

        // Implicit assumption that all skins used for controller input mapping don't have multiple items with same input.
        let mappedInputs = items.flatMap { $0.inputs.allInputs.compactMap(controllerViewInputMapping.input(forControllerInput:)) } + (supportedActionInputs as [Input])

        // Create callout view for each on-screen input.
        for input in mappedInputs {
            let calloutView = InputCalloutView()
            calloutView.delegate = self
            calloutView.permittedArrowDirection = .any
            calloutView.constrainedInsets = view.safeAreaInsets
            calloutViews[AnyInput(input)] = calloutView
        }

        managedObjectContext.performAndWait {
            // Update callout views with controller inputs that map to callout views' associated controller skin inputs.
            for input in inputMapping.supportedControllerInputs {
                let mappedInput = self.mappedInput(for: input)

                if let calloutView = self.calloutViews[mappedInput] {
                    if let previousInput = calloutView.input {
                        // Ensure the input we display has a higher priority.
                        calloutView.input = (input.displayPriority > previousInput.displayPriority) ? input : previousInput
                    } else {
                        calloutView.input = input
                    }
                }
            }
        }

        // Present only callout views that are associated with a controller input.
        for calloutView in calloutViews.values {
            if let presentationRect = presentationRect(for: calloutView), calloutView.input != nil {
                calloutView.presentCallout(from: presentationRect, in: view, constrainedTo: view, animated: true)
            }
        }
    }
}

private extension ControllerInputsViewController {
    func updateActiveCalloutView(with controllerInput: Input?) {
        guard let inputMapping = inputMappings[system] else { return }

        guard let activeCalloutView = activeCalloutView else { return }

        guard let input = calloutViews.first(where: { $0.value == activeCalloutView })?.key else { return }

        if let controllerInput = controllerInput {
            for (_, calloutView) in calloutViews {
                guard let calloutInput = calloutView.input else { continue }

                if calloutInput == controllerInput {
                    // Hide callout views that previously displayed the controller input.
                    calloutView.input = nil
                    calloutView.dismissCallout(animated: true)
                }
            }
        }

        managedObjectContext.performAndWait {
            for supportedInput in inputMapping.supportedControllerInputs {
                let mappedInput = self.mappedInput(for: supportedInput)

                if mappedInput == input {
                    // Set all existing controller inputs that currently map to "input" to instead map to nil.
                    inputMapping.set(nil, forControllerInput: supportedInput)
                }
            }

            if let controllerInput = controllerInput {
                inputMapping.set(input, forControllerInput: controllerInput)
            }
        }

        activeCalloutView.input = controllerInput

        toggle(activeCalloutView)
    }

    func toggle(_ calloutView: InputCalloutView) {
        if let activeCalloutView = activeCalloutView, activeCalloutView != calloutView {
            toggle(activeCalloutView)
        }

        let menuItem: MenuItem?

        if let input = calloutViews.first(where: { $0.value == calloutView })?.key, let index = supportedActionInputs.firstIndex(where: { $0 == input })
        {
            menuItem = actionsMenuViewController.items[index]
        } else {
            menuItem = nil
        }

        switch calloutView.state {
        case .normal:
            calloutView.state = .listening
            menuItem?.isSelected = true
            activeCalloutView = calloutView

        case .listening:
            calloutView.state = .normal
            menuItem?.isSelected = false
            activeCalloutView = nil
        }

        calloutView.dismissCallout(animated: true)

        if let presentationRect = presentationRect(for: calloutView) {
            if calloutView.state == .listening || calloutView.input != nil {
                calloutView.presentCallout(from: presentationRect, in: view, constrainedTo: view, animated: true)
            }
        }
    }

    @IBAction func resetInputMapping(_ sender: UIBarButtonItem) {
        func reset() {
            managedObjectContext.perform {
                guard let inputMapping = self.inputMappings[self.system] else { return }

                self.managedObjectContext.delete(inputMapping)
                self.inputMappings[self.system] = nil

                DispatchQueue.main.async {
                    self.updateSystem()
                }
            }
        }

        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.popoverPresentationController?.barButtonItem = sender
        alertController.addAction(.cancel)
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Reset Controls to Defaults", comment: ""), style: .destructive, handler: { _ in
            reset()
        }))
        present(alertController, animated: true, completion: nil)
    }
}

extension ControllerInputsViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return activeCalloutView != nil
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // Necessary to prevent other gestures (e.g. GameViewController's resumeEmulationIfNeeded() tap gesture) from cancelling tap.
        return true
    }

    @IBAction private func handleTapGesture(_ tapGestureRecognizer: UITapGestureRecognizer) {
        updateActiveCalloutView(with: nil)
    }
}

private extension ControllerInputsViewController {
    func mappedInput(for input: Input) -> AnyInput {
        guard let inputMapping = inputMappings[system] else {
            fatalError("Input mapping for current system does not exist.")
        }

        guard let mappedInput = inputMapping.input(forControllerInput: input) else {
            fatalError("Mapped input for provided input does not exist.")
        }

        if let standardInput = StandardGameControllerInput(input: mappedInput) {
            if let gameInput = standardInput.input(for: system.gameType) {
                return AnyInput(gameInput)
            }
        }

        return AnyInput(mappedInput)
    }

    func presentationRect(for calloutView: InputCalloutView) -> CGRect? {
        guard let input = calloutViews.first(where: { $0.value == calloutView })?.key else { return nil }

        guard
            let controllerView = gameViewController.controllerView,
            let traits = controllerView.controllerSkinTraits,
            let items = controllerView.controllerSkin?.items(for: traits)
        else { return nil }

        if let item = items.first(where: { $0.inputs.allInputs.contains(where: { $0.stringValue == input.stringValue }) }) {
            // Input is a controller skin input.

            let itemFrame: CGRect?

            switch item.inputs {
            case .standard: itemFrame = item.frame
            case .touch: itemFrame = item.frame
            case let .directional(up, down, left, right):
                let frame = (item.kind == .thumbstick) ? item.extendedFrame : item.frame

                switch input.stringValue {
                case up.stringValue:
                    itemFrame = CGRect(x: frame.minX + frame.width / 3,
                                       y: frame.minY,
                                       width: frame.width / 3,
                                       height: frame.height / 3)
                case down.stringValue:
                    itemFrame = CGRect(x: frame.minX + frame.width / 3,
                                       y: frame.minY + (frame.height / 3) * 2,
                                       width: frame.width / 3,
                                       height: frame.height / 3)

                case left.stringValue:
                    itemFrame = CGRect(x: frame.minX,
                                       y: frame.minY + (frame.height / 3),
                                       width: frame.width / 3,
                                       height: frame.height / 3)

                case right.stringValue:
                    itemFrame = CGRect(x: frame.minX + (frame.width / 3) * 2,
                                       y: frame.minY + (frame.height / 3),
                                       width: frame.width / 3,
                                       height: frame.height / 3)

                default: itemFrame = nil
                }
            }

            if let itemFrame = itemFrame {
                var presentationFrame = itemFrame.applying(CGAffineTransform(scaleX: controllerView.bounds.width, y: controllerView.bounds.height))
                presentationFrame = view.convert(presentationFrame, from: controllerView)

                return presentationFrame
            }
        } else if let index = supportedActionInputs.firstIndex(where: { $0 == input }) {
            // Input is an ActionInput.

            let indexPath = IndexPath(item: index, section: 0)

            if let attributes = actionsMenuViewController.collectionViewLayout.layoutAttributesForItem(at: indexPath) {
                let presentationFrame = view.convert(attributes.frame, from: actionsMenuViewController.view)
                return presentationFrame
            }
        } else {
            // Input is not an on-screen input.
        }

        return nil
    }
}

extension ControllerInputsViewController: GameControllerReceiver {
    func gameController(_ gameController: GameController, didActivate controllerInput: DeltaCore.Input, value: Double) {
        guard isViewLoaded, value > 0.9 else { return }

        switch gameController {
        case gameViewController.controllerView:
            if let calloutView = calloutViews[AnyInput(controllerInput)] {
                if controllerInput.isContinuous {
                    // Make sure we only toggle calloutView once in a single gesture.
                    guard calloutView.state == .normal else { break }
                }

                toggle(calloutView)
            }

        case self.gameController: updateActiveCalloutView(with: controllerInput)

        default: break
        }
    }

    func gameController(_ gameController: GameController, didDeactivate input: DeltaCore.Input) {
    }
}

extension ControllerInputsViewController: SMCalloutViewDelegate {
    func calloutViewClicked(_ calloutView: SMCalloutView) {
        guard let calloutView = calloutView as? InputCalloutView else { return }

        toggle(calloutView)
    }
}

extension ControllerInputsViewController: UIAdaptivePresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        switch (traitCollection.horizontalSizeClass, traitCollection.verticalSizeClass) {
#if !os(tvOS) && !os(macOS)
        case (.regular, .regular): return .formSheet // Regular width and height, so display as form sheet
#else
        case (.regular, .regular): return .automatic // Regular width and height, so display as form sheet
            #endif
        default: return .fullScreen // Compact width and/or height, so display full screen
        }
    }
}
