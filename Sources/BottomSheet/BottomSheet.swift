import UIKit
import SwiftUI
import Combine

public class BottomSheetModel: ObservableObject {
	@Published var size: CGSize = .zero
	@Published public var expanded: Bool = false
}


public struct BottomSheetOptions: OptionSet {

    public let rawValue: Int
    public static let disableSafeArea = BottomSheetOptions(rawValue: 1 << 0)

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
}

public class BottomSheet<T: View>: UIViewController {


	private let model = BottomSheetModel()
	private var host: UIHostingController<SizeReportingModal<T>>?
	private var sizeReporter: SizeReportingModal<T>?
	private var cancellable: [AnyCancellable] = []
	
    public init(_ content: T, options: BottomSheetOptions) {
        super.init(nibName: nil, bundle: nil)
        self.sizeReporter = SizeReportingModal(content: content, model: model) {
            self.dismiss(animated: true)
        }
        self.host = UIHostingController(rootView: self.sizeReporter!)
        if options.contains(.disableSafeArea) {
            if #available(iOS 16.4, *) {
                self.host?.safeAreaRegions = SafeAreaRegions()
            }
        }
    }

	
	public override func viewDidLoad() {
		super.viewDidLoad()
		guard let host else { return }
		self.view.addSubview(host.view)
		host.view.translatesAutoresizingMaskIntoConstraints = false
		NSLayoutConstraint.activate([
			host.view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
			host.view.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
			host.view.topAnchor.constraint(equalTo: self.view.topAnchor),
			host.view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
		])
		host.didMove(toParent: self)
		model.$size.sink { size in
			self.sizeDidChange(to: size)
		}.store(in: &cancellable)
		model.$expanded.sink { size in
			
			self.sheetPresentationController?.animateChanges {
				self.sheetPresentationController?.detents = [.large()]
			}
		}.store(in: &cancellable)
	}
	
	func sizeDidChange(to: CGSize) {
		guard !model.expanded else { return }
		self.sheetPresentationController?.animateChanges {
			self.sheetPresentationController?.detents = [.custom(resolver: { context in
				return to.height
			})]
		}
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
}

struct SizeReportingModal<Content: View>: View {
	
	let content: Content
	@ObservedObject var model: BottomSheetModel
	let dismiss: () -> Void
	
	var body: some View {
		content
			.environment(\.sheetDismiss, DismissBottomSheetAction(action: dismiss))
			.environmentObject(self.model)
			.fixedSize(horizontal: false, vertical: !model.expanded)
			.overlay(
				GeometryReader { geo in
					Color.clear
						.onAppear {
							self.model.size = geo.size
						}
						.onChange(of: geo.size) { _ in
							self.model.size = geo.size
						}
				}
			)
	}
	
}
public struct DismissBottomSheetAction {
	typealias Action = () -> ()
	let action: Action
	public func callAsFunction() {
		action()
	}
}

public struct DismissBottomSheetKey: EnvironmentKey {
	public static var defaultValue: DismissBottomSheetAction? = nil
}

public extension EnvironmentValues {
	var sheetDismiss: DismissBottomSheetAction? {
		get { self[DismissBottomSheetKey.self] }
		set { self[DismissBottomSheetKey.self] = newValue }
	}
}
