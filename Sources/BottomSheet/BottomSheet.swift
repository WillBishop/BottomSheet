import UIKit
import SwiftUI
import Combine

public class BottomSheetModel: ObservableObject {
	@Published var size: CGSize = .zero
	@Published public var expanded: Bool = false
}

public class BottomSheet<T: View>: UIViewController {
	
	private let model = BottomSheetModel()
	private let host: UIHostingController<SizeReportingModal<T>>
	private let sizeReporter: SizeReportingModal<T>
	private var cancellable: [AnyCancellable] = []
	
	public init(_ content: T) {
		self.sizeReporter = SizeReportingModal(content: content, model: model)
		self.host = UIHostingController(rootView: self.sizeReporter)
		super.init(nibName: nil, bundle: nil)
	}
	
	
	public override func viewDidLoad() {
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
	
	var body: some View {
		content
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
