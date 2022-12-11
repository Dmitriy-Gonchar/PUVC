//
//  ViewController.swift
//  PUVC
//
//  Created by Dmitry on 11.12.2022.
//

import UIKit

private let testCell = "TestCell"

class ViewController: UIViewController
{
	let puvc = PUVC()
	var num = Int(arc4random()%10) + 2

	override func viewDidLoad()
	{
		super.viewDidLoad()
	}

	@IBAction func selection(_ sender: Any)
	{
		self.num = Int(arc4random()%10) + 3
		self.present(self.puvc, animated: true)
		let celNib = UINib(nibName: testCell, bundle: nil)
		self.puvc.register(celNib, forCellReuseIdentifier: testCell)
		self.puvc.delegate = self
		self.puvc.dataSource = self
	}
}

extension ViewController: UITableViewDataSource, UITableViewDelegate
{
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
	{
		return self.num
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
	{
		let cell = tableView.dequeueReusableCell(withIdentifier: testCell, for: indexPath)

		return cell
	}

	func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
	{
		return 50
	}

	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
	{
		self.puvc.dismiss(animated: true)
	}
}
