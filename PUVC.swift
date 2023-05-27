//
//  PUVC.swift
//  PUVC
//
//  Created by Dmitry on 11.12.2022.
//

/*
 This is free and unencumbered software released into the public domain.

 Anyone is free to copy, modify, publish, use, compile, sell, or
 distribute this software, either in source code form or as a compiled
 binary, for any purpose, commercial or non-commercial, and by any
 means.

 In jurisdictions that recognize copyright laws, the author or authors
 of this software dedicate any and all copyright interest in the
 software to the public domain. We make this dedication for the benefit
 of the public at large and to the detriment of our heirs and
 successors. We intend this dedication to be an overt act of
 relinquishment in perpetuity of all present and future rights to this
 software under copyright law.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
 OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
 ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 OTHER DEALINGS IN THE SOFTWARE.

 For more information, please refer to <https://unlicense.org>
 */

import UIKit

private let threshold: CGFloat = 1000

class PUVC: UIViewController, UIGestureRecognizerDelegate
{
	private var startPosition: CGFloat = .zero
	private var prevTime: Date = Date()
	private var startLayerPosition: CGFloat = .zero
	@IBOutlet private weak var backgroundIV: UIImageView!
	@IBOutlet private weak var mover: UIView!
	@IBOutlet private weak var tableView: UITableView!
	private var layer: CALayer = CALayer()
	@IBOutlet private weak var heightTV: NSLayoutConstraint!

	private var vib = UIImpactFeedbackGenerator(style: .light)

	override var modalTransitionStyle: UIModalTransitionStyle { get { .coverVertical } set {} }
	override var modalPresentationStyle: UIModalPresentationStyle { get { .overFullScreen } set {} }

	weak var delegate: UITableViewDelegate?
	{
		get
		{
			self.tableView.delegate
		}
		set
		{
			self.tableView.delegate = newValue
		}
	}

	weak var dataSource: UITableViewDataSource?
	{
		get
		{
			self.tableView.dataSource
		}
		set
		{
			self.tableView.dataSource = newValue
			self.height = self.calcHeight()
		}
	}

	private func calcHeight() -> CGFloat
	{
		let range = 0..<(self.dataSource?.tableView(self.tableView, numberOfRowsInSection: 0) ?? 0)
		return range.reduce(into: CGFloat())
		{
			$0 += self.delegate?.tableView?(self.tableView, heightForRowAt: IndexPath(row: $1, section: 0)) ?? 0
		}
	}

	public var height: CGFloat?
	{
		didSet
		{
			self.heightTV.constant = height ?? self.heightTV.constant
		}
	}

	func register(_ nib: UINib?,
				  forCellReuseIdentifier: String)
	{
		self.tableView.register(nib, forCellReuseIdentifier: forCellReuseIdentifier)
	}

	func register(_ nib: UINib?,
				  forHeaderFooterViewReuseIdentifier: String)
	{
		self.tableView.register(nib,
								forHeaderFooterViewReuseIdentifier: forHeaderFooterViewReuseIdentifier)
	}

	func update()
	{
		self.tableView?.reloadData()
	}

	private var cellNib: UINib?
	private var identifier: String?

	convenience init(with cellNib: UINib, identifier: String) {
		self.init()
		self.cellNib = cellNib
		self.identifier = identifier
	}

	override func viewDidLoad()
	{
		super.viewDidLoad()

		if let cellNib = cellNib, let identifier = identifier
		{
			self.register(cellNib, forCellReuseIdentifier: identifier)
		}

		self.view.layer.insertSublayer(self.layer, at: 0)
		self.layer.removeAllAnimations()

		self.layer.frame = CGRect(x: -10000, y: -10000, width: 20000, height: 20000)

		if #available(iOS 11.0, *)
		{
			self.backgroundIV.layer.maskedCorners = .init(arrayLiteral: .layerMinXMinYCorner, .layerMaxXMinYCorner)
		}

		self.backgroundIV.layer.cornerRadius = 16

		let rig = UIPanGestureRecognizer(target: self,
										 action: #selector(pan(_:)))
		rig.delegate = self
		self.view.addGestureRecognizer(rig)
	}

	override func viewWillAppear(_ animated: Bool)
	{
		super.viewWillAppear(animated)

		self.layer.backgroundColor = UIColor.clear.cgColor
		self.layer.opacity = 0.5
		let color = UIColor.black.cgColor
		let colorAnimation = CABasicAnimation(keyPath: "backgroundColor")
		colorAnimation.duration = 0.5
		colorAnimation.toValue = color
		self.layer.add(colorAnimation, forKey: nil)

		UIView.animate(withDuration: 0.5, delay: 0, options: .curveLinear, animations: {})
		{ if $0 { self.layer.backgroundColor = color } }
	}

	@objc public func pan(_ s: UIPanGestureRecognizer)
	{
		let height = self.tableView.layer.frame.height
		let velocity = s.velocity(in: self.view.window).y
		let swipePosition = s.location(in: self.view.window).y

		switch s.state
		{
		case .began:
			self.startPosition = s.location(in: self.view.window).y
			self.startLayerPosition = self.view.layer.position.y
			self.prevTime = Date()

		case .changed:
			if self.startPosition > self.tableView.frame.minY
			{
				let realShift = swipePosition - self.startPosition
				let position = max(self.startLayerPosition + realShift, self.startLayerPosition)

				self.view.layer.position.y = position

				CATransaction.begin()
				CATransaction.setDisableActions(true)
				self.layer.opacity = Float(1 - position/self.view.frame.height)
				CATransaction.commit()
			}

		case .ended:
			self.view.layer.removeAllAnimations()
			if swipePosition - self.startPosition > height/2 && velocity > -threshold ||
			   swipePosition - self.startPosition > 0 && velocity > threshold
			{
				UIView.animate(withDuration: 0.1, delay: 0, options: .curveLinear)
				{
					self.layer.opacity = 0
					if abs(velocity) > abs(threshold)
					{
						self.vib.prepare()
						self.vib.impactOccurred()
					}
				}

				self.dismiss(animated: true)
				{
					self.layer.opacity = 0
				}
			}
			else
			{
				UIView.animate(withDuration: 0.1, delay: 0, options: .curveLinear)
				{
					self.layer.opacity = 0.5
					self.view.layer.position.y = self.startLayerPosition
				}
			completion:
				{
					if $0
					{
						self.view.layer.position.y = self.startLayerPosition
						if abs(velocity) > abs(threshold)
						{
							self.vib.prepare()
							self.vib.impactOccurred()
						}
					}
				}

			}

		case .cancelled, .failed: break
		default: break
		}
	}

	override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil)
	{
		super.dismiss(animated: flag, completion: completion)
		UIView.animate(withDuration: 0.1, delay: 0, options: .curveLinear)
		{
			self.layer.opacity = 0
		}
	}
}
