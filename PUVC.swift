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
	@IBOutlet weak var backgroundIV: UIImageView!
	@IBOutlet weak var mover: UIView!
	@IBOutlet weak var tableView: UITableView!
	private var layer: CALayer = CALayer()

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
			self.tableView.reloadData()
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

	override func viewDidLoad()
	{
		super.viewDidLoad()

		self.view.layer.insertSublayer(self.layer, at: 0)
		self.layer.backgroundColor = UIColor.black.cgColor
		self.layer.opacity = 0.0
		self.layer.frame = CGRect(origin: .init(x: 0, y: -UIScreen.main.bounds.height),
								  size: .init(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height * 2))

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
		if animated
		{
			UIView.animate(withDuration: animated ? 0.5 : 0, delay: 0, options: .curveLinear)
			{
			}
		completion:
			{
				if $0
				{
					self.layer.opacity = 0.5
				}
			}
		}
		else
		{
			self.layer.opacity = 0.5
		}
	}

	@objc public func pan(_ s: UIPanGestureRecognizer)
	{
		let height = self.view.layer.frame.height
		let velocity = s.velocity(in: self.view.window).y
		let swipePosition = s.location(in: self.view.window).y

		switch s.state
		{
		case .began:
			self.startPosition = s.location(in: self.view.window).y
			self.startLayerPosition = self.view.layer.position.y
			self.prevTime = Date()

		case .changed:
			let i2 = self.prevTime.timeIntervalSince1970 - Date().timeIntervalSince1970
			if self.startPosition < self.view.window!.frame.height - self.mover.frame.height
			{
				let realShift = swipePosition - self.startPosition
				let position = max(self.startLayerPosition + realShift, self.startLayerPosition)
				UIView.animate(withDuration: i2, delay: 0, options: .curveLinear)
				{
					self.view.layer.position.y = position
					self.layer.opacity = Float(0.5 - (position/self.view.frame.height) * 0.5)
				}
			}

		case .ended:
			self.view.layer.removeAllAnimations()
			if swipePosition - self.startPosition > height/2 && velocity > -threshold ||
			   swipePosition - self.startPosition > 0 && velocity > threshold
			{
				UIView.animate(withDuration: 0.1, delay: 0, options: .curveLinear)
				{
					self.layer.opacity = 0
				}
			completion:
				{
					if $0
					{
						self.layer.opacity = 0
						if abs(velocity) > abs(threshold)
						{
							self.vib.prepare()
							self.vib.impactOccurred()
						}
					}
				}

				self.dismiss(animated: true)
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
}
