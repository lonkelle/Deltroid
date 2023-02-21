//
//  SMCalloutView.swift
//  Deltroid
//
//  Created by Joseph Mattiello on 2/21/23.
//  Copyright © 2023 Riley Testut. All rights reserved.
//

import Foundation
import UIKit
import MapKit

let SMCalloutViewSubtitleViewTag = 1001
let SMCalloutViewTitleViewTag = 1000
let SMCalloutViewBackgroundViewTag = 1002
let arrowHeightFactor: CGFloat = 0.4
let borderWidth: CGFloat = 1
let contentInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
let CalloutMapViewControllerHorizontalPadding: CGFloat = 15

@objc protocol SMCalloutViewDelegate: AnyObject {
	@objc optional func calloutViewClicked(_ calloutView: SMCalloutView)
	@objc optional func calloutViewClickedSubtitle(_ calloutView: SMCalloutView)
	@objc optional func calloutViewDidDismiss(_ calloutView: SMCalloutView)
}

enum SMCalloutArrowDirection: UInt {
	case up = 0
	case down
	case any
}

class SMCalloutView: UIView {
	var contentView: UIView?
	var title: String?
	var subtitle: String?
	weak var delegate: SMCalloutViewDelegate?
	var calloutOffset: CGPoint = .zero
	var calloutAnchorPoint: CGPoint = .zero
	var contentViewInset: UIEdgeInsets = .zero
	var titleFont: UIFont = .boldSystemFont(ofSize: 16)
	var subtitleFont: UIFont = .systemFont(ofSize: 14)
	var titleColor: UIColor = .black
	var subtitleColor: UIColor = .gray
	var animationDuration: TimeInterval = 0.15
	var arrowWidth: CGFloat = 28

	var permittedArrowDirection: SMCalloutArrowDirection = .any

	lazy var constrainedInsets: UIEdgeInsets = {
		let topInset = min(contentInsets.top, arrowHeight() + borderWidth)
		let leftInset = min(contentInsets.left, arrowWidth + borderWidth)
		let bottomInset = min(contentInsets.bottom, borderWidth)
		let rightInset = min(contentInsets.right, borderWidth)

		return UIEdgeInsets(top: topInset, left: leftInset, bottom: bottomInset, right: rightInset)
	}()

	private let backgroundLayer: CAShapeLayer = {
		let layer = CAShapeLayer()
		layer.fillColor = UIColor.white.cgColor
		layer.shadowOffset = CGSize(width: 0, height: 2)
		layer.shadowRadius = 2
		layer.shadowOpacity = 0.5
		return layer
	}()

	var titleView: UIView? {
		get {
			return contentView?.viewWithTag(SMCalloutViewTitleViewTag)
		}
		set {
			if let existingTitleView = titleView {
				existingTitleView.removeFromSuperview()
			}
			if let newTitleView = newValue {
				newTitleView.tag = SMCalloutViewTitleViewTag
				contentView?.addSubview(newTitleView)
			}
			setNeedsLayout()
		}
	}

	override init(frame: CGRect) {
		super.init(frame: frame)
		backgroundColor = .clear
		layer.addSublayer(backgroundLayer)
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
		guard let contentView = contentView else { return false }
		let convertedPoint = convert(point, to: contentView)
		return contentView.bounds.contains(convertedPoint)
	}

	class func platformCalloutView() -> SMCalloutView {
//		if #available(iOS 9.0, *) {
//			return MKAnnotationView.calloutView()
//		} else {
			return SMCalloutView()
//		}
	}

	func maximumWidth() -> CGFloat {
		return UIScreen.main.bounds.width - (contentInsets.left + contentInsets.right + 2 * borderWidth + 2 * CalloutMapViewControllerHorizontalPadding)
	}

	override func sizeThatFits(_ size: CGSize) -> CGSize {
		let width = min(size.width, maximumWidth())
		let containerSize = CGSize(width: width - contentInsets.left - contentInsets.right, height: CGFloat.greatestFiniteMagnitude)
		let containerHeight = calloutContainerHeight()
		let calloutHeight = calloutHeight()

		let finalSize = CGSize(width: width, height: calloutHeight)
		return finalSize
	}

	func presentCallout(from rect: CGRect, in view: UIView, constrainedTo constrainedRect: CGRect, animated: Bool) {
		guard let contentView = contentView else { return }
		view.addSubview(self)

		let edgePadding = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
		let arrowSize = CGSize(width: 10, height: 5)
		let calloutSize = contentView.frame.size
		let anchorPoint = CGPoint(x: rect.minX + calloutAnchorPoint.x, y: rect.minY + calloutAnchorPoint.y)
		let calloutOrigin = origin(for: anchorPoint, calloutSize: calloutSize, arrowSize: arrowSize, edgePadding: edgePadding, constrainedRect: constrainedRect)

		let arrowPoint = CGPoint(x: anchorPoint.x - calloutOrigin.x + arrowSize.width / 2, y: anchorPoint.y - calloutOrigin.y)
		let path = pathFor(calloutSize: calloutSize, arrowSize: arrowSize, arrowPoint: arrowPoint, cornerRadius: 6)
		backgroundLayer.path = path.cgPath
		backgroundLayer.frame = CGRect(origin: calloutOrigin, size: calloutSize)

		contentView.frame = CGRect(origin: calloutOrigin, size: calloutSize).inset(by: contentViewInset)
		addSubview(contentView)

		if animated {
			contentView.alpha = 0
			contentView.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
			UIView.animate(withDuration: animationDuration, delay: 0, options: [.curveEaseOut], animations: {
				contentView.alpha = 1
				contentView.transform = .identity
			}, completion: nil)
		}
	}

	func dismissCallout(animated: Bool) {
		guard let contentView = contentView else { return }
		if animated {
			UIView.animate(withDuration: animationDuration, delay: 0, options: [.curveEaseOut], animations: {
				contentView.alpha = 0
				contentView.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
			}, completion: { [weak self] finished in
				contentView.removeFromSuperview()
				self?.removeFromSuperview()
			})
		} else {
			contentView.removeFromSuperview()
			removeFromSuperview()
		}
		delegate?.calloutViewDidDismiss?(self)
		self.contentView = nil
	}
}

extension SMCalloutView {
	func supportsHighlighting() -> Bool {
		guard let delegate = delegate else { return false }
		return delegate.calloutViewClicked != nil || delegate.calloutViewClickedSubtitle != nil
	}

	func highlightIfNecessary() {
		if supportsHighlighting() {
			backgroundColor = UIColor(white: 1, alpha: 0.85)
		}
	}

	func unhighlightIfNecessary() {
		if supportsHighlighting() {
			backgroundColor = UIColor.white
		}
	}

	@objc func calloutClicked() {
		guard let delegate = delegate else { return }
		if delegate.calloutViewClicked != nil {
			delegate.calloutViewClicked!(self)
		} else if delegate.calloutViewClickedSubtitle != nil {
			delegate.calloutViewClickedSubtitle!(self)
		}
	}
}

extension SMCalloutView {
	func titleViewOrDefault() -> UIView {
		if let titleView = contentView?.viewWithTag(SMCalloutViewTitleViewTag) {
			return titleView
		} else {
			let titleView = UILabel()
			titleView.font = titleFont
			titleView.textColor = titleColor
			titleView.textAlignment = .center
			titleView.numberOfLines = 0
			titleView.tag = SMCalloutViewTitleViewTag
			return titleView
		}
	}

	func subtitleViewOrDefault() -> UIView? {
		if let subtitle = subtitle {
			if let subtitleView = contentView?.viewWithTag(SMCalloutViewSubtitleViewTag) as? UILabel {
				subtitleView.text = subtitle
				return subtitleView
			} else {
				let subtitleView = UILabel()
				subtitleView.font = subtitleFont
				subtitleView.textColor = subtitleColor
				subtitleView.textAlignment = .center
				subtitleView.numberOfLines = 0
				subtitleView.text = subtitle
				subtitleView.tag = SMCalloutViewSubtitleViewTag
				return subtitleView
			}
		} else {
			return nil
		}
	}

	func backgroundView() -> UIView {
		if let backgroundView = contentView?.viewWithTag(SMCalloutViewBackgroundViewTag) {
			return backgroundView
		} else {
			let backgroundView = defaultBackgroundView()
			backgroundView.tag = SMCalloutViewBackgroundViewTag
			return backgroundView
		}
	}

	func defaultBackgroundView() -> UIView {
		let view = UIView()
		view.backgroundColor = UIColor.white
		return view
	}

	func rebuildSubviews() {
		guard let contentView = contentView else { return }

		let titleView = titleViewOrDefault()
		titleView.translatesAutoresizingMaskIntoConstraints = false
		contentView.addSubview(titleView)

		let subtitleView = subtitleViewOrDefault()
		subtitleView?.translatesAutoresizingMaskIntoConstraints = false
		if let subtitleView = subtitleView {
			contentView.addSubview(subtitleView)
		}

		let backgroundView = self.backgroundView()
		backgroundView.translatesAutoresizingMaskIntoConstraints = false
		contentView.insertSubview(backgroundView, at: 0)

		let views = ["titleView": titleView]
		let constraints = [
			NSLayoutConstraint.constraints(withVisualFormat: "H:|-8-[titleView]-8-|", options: [], metrics: nil, views: views),
			NSLayoutConstraint.constraints(withVisualFormat: "V:|-6-[titleView]", options: [], metrics: nil, views: views)
		].flatMap { $0 }
		contentView.addConstraints(constraints)

		if let subtitleView = subtitleView {
			let subtitleViews = ["subtitleView": subtitleView, "titleView": titleView]
			let subtitleConstraints = [
				NSLayoutConstraint.constraints(withVisualFormat: "H:|-8-[subtitleView]-8-|", options: [], metrics: nil, views: subtitleViews),
				NSLayoutConstraint.constraints(withVisualFormat: "V:[titleView]-0-[subtitleView]", options: [], metrics: nil, views: subtitleViews)
			].flatMap { $0 }
			contentView.addConstraints(subtitleConstraints)
		}

		let backgroundViews = ["backgroundView": backgroundView, "contentView": contentView]
		let backgroundConstraints = [
			NSLayoutConstraint.constraints(withVisualFormat: "H:|[backgroundView]|", options: [], metrics: nil, views: backgroundViews),
			NSLayoutConstraint.constraints(withVisualFormat: "V:|[backgroundView]|", options: [], metrics: nil, views: backgroundViews)
		].flatMap { $0 }
		contentView.addConstraints(backgroundConstraints)
	}
}

extension SMCalloutView {
	func leftAccessoryVerticalMargin() -> CGFloat {
		return 20
	}

	func leftAccessoryHorizontalMargin() -> CGFloat {
		return 15
	}

	func rightAccessoryVerticalMargin() -> CGFloat {
		return 20
	}

	func rightAccessoryHorizontalMargin() -> CGFloat {
		return 15
	}

	func innerContentMarginLeft() -> CGFloat {
		return 8
	}

	func innerContentMarginRight() -> CGFloat {
		return 8
	}

	func calloutContainerHeight() -> CGFloat {
		var height: CGFloat = 0
		if let titleView = contentView?.viewWithTag(SMCalloutViewTitleViewTag) {
			height += titleView.frame.size.height
		}
		if let subtitleView = contentView?.viewWithTag(SMCalloutViewSubtitleViewTag) {
			height += subtitleView.frame.size.height
		}
		height += innerContentMarginTop() + innerContentMarginBottom()
		return height
	}

	func calloutHeight() -> CGFloat {
		return calloutContainerHeight() + calloutOffset.y + arrowHeight()
	}

	func innerContentMarginTop() -> CGFloat {
		return titleViewOrDefault().frame.size.height
	}

	func innerContentMarginBottom() -> CGFloat {
		return subtitleViewOrDefault()?.frame.size.height ?? 0
	}

	func arrowHeight() -> CGFloat {
		return arrowHeightFactor * arrowWidth
	}
}

/*
 The pathFor(calloutSize:arrowSize:arrowPoint:cornerRadius:) method takes four arguments:

 calloutSize: The size of the callout view.
 arrowSize: The size of the callout arrow.
 arrowPoint: The point on the callout view where the arrow should be positioned.
 cornerRadius: The radius of the corners of the callout view.
 The method first creates a rectangle that represents the callout view, excluding the area occupied by the arrow. It also creates a rectangle that represents the arrow.

 The method then creates a UIBezierPath object and uses it to draw the path for the callout view. The path is drawn in a counterclockwise direction, starting from the top left corner.
 */
func pathFor(calloutSize: CGSize, arrowSize: CGSize, arrowPoint: CGPoint, cornerRadius: CGFloat) -> UIBezierPath {
	let calloutRect = CGRect(x: 0, y: 0, width: calloutSize.width, height: calloutSize.height - arrowSize.height)
	let arrowRect = CGRect(x: arrowPoint.x - arrowSize.width / 2, y: arrowPoint.y, width: arrowSize.width, height: arrowSize.height)
	let path = UIBezierPath()

	// Top left corner
	let topLeft = CGPoint(x: calloutRect.minX, y: calloutRect.minY + cornerRadius)
	path.move(to: topLeft)
	path.addArc(withCenter: CGPoint(x: topLeft.x + cornerRadius, y: topLeft.y), radius: cornerRadius, startAngle: .pi, endAngle: 3 * .pi / 2, clockwise: true)

	// Top side
	let topRight = CGPoint(x: calloutRect.maxX - cornerRadius, y: calloutRect.minY)
	path.addLine(to: topRight)

	// Top right corner
	path.addArc(withCenter: CGPoint(x: topRight.x, y: topRight.y + cornerRadius), radius: cornerRadius, startAngle: 3 * .pi / 2, endAngle: 0, clockwise: true)

	// Right side
	let bottomRight = CGPoint(x: calloutRect.maxX, y: calloutRect.maxY - cornerRadius)
	path.addLine(to: bottomRight)

	// Bottom right corner
	path.addArc(withCenter: CGPoint(x: bottomRight.x - cornerRadius, y: bottomRight.y), radius: cornerRadius, startAngle: 0, endAngle: .pi / 2, clockwise: true)

	// Bottom side
	let bottomLeft = CGPoint(x: calloutRect.minX + cornerRadius, y: calloutRect.maxY)
	path.addLine(to: bottomLeft)

	// Bottom left corner
	path.addArc(withCenter: CGPoint(x: bottomLeft.x, y: bottomLeft.y - cornerRadius), radius: cornerRadius, startAngle: .pi / 2, endAngle: .pi, clockwise: true)

	// Left side
	path.addLine(to: topLeft)
	path.close()

	// Arrow
	path.move(to: CGPoint(x: arrowRect.minX, y: arrowRect.maxY))
	path.addLine(to: CGPoint(x: arrowRect.midX, y: arrowRect.minY))
	path.addLine(to: CGPoint(x: arrowRect.maxX, y: arrowRect.maxY))
	path.close()

	return path
}

func origin(for point: CGPoint, calloutSize: CGSize, arrowSize: CGSize, edgePadding: UIEdgeInsets, constrainedRect: CGRect) -> CGPoint {
	let offset: CGFloat = 8
	var origin = CGPoint.zero

	// Calculate the callout frame
	let calloutFrame = CGRect(x: point.x - calloutSize.width / 2, y: point.y - calloutSize.height - arrowSize.height - offset, width: calloutSize.width, height: calloutSize.height)

	// Adjust the callout frame for edge padding and constraints
	if calloutFrame.maxX > constrainedRect.maxX - edgePadding.right {
		origin.x = constrainedRect.maxX - calloutSize.width - edgePadding.right
	} else if calloutFrame.minX < constrainedRect.minX + edgePadding.left {
		origin.x = constrainedRect.minX + edgePadding.left
	} else {
		origin.x = calloutFrame.minX
	}

	if calloutFrame.minY < constrainedRect.minY + edgePadding.top {
		origin.y = point.y + arrowSize.height + offset
	} else {
		origin.y = calloutFrame.minY
	}

	return origin
}
