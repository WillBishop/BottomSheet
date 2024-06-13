import UIKit
import SwiftUI
import Combine

class SelfSizedModalModel: ObservableObject {
	@Published var size: CGSize = .zero
}

class BottomSheet<T: View>: UIViewController {
	
	private let model = SelfSizedModalModel()
	private let host: UIHostingController<SizeReportingModal<T>>
	private let sizeReporter: SizeReportingModal<T>
	private var cancellable: [AnyCancellable] = []
	
	init(_ content: T) {
		self.sizeReporter = SizeReportingModal(content: content, model: model)
		self.host = UIHostingController(rootView: self.sizeReporter)
		super.init(nibName: nil, bundle: nil)
	}
	
	
	override func viewDidLoad() {
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
	}
	
	func sizeDidChange(to: CGSize) {
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
	@ObservedObject var model: SelfSizedModalModel
	
	var body: some View {
		content
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
