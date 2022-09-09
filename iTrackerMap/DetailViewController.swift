//
//  DetailViewController.swift
//  iTrackerMap
//
//  Created by Danny Tsang on 9/9/22.
//

import UIKit

class DetailViewController: UIViewController {

    private let log: [TrackPoint]

    private let closeButton: UIBarButtonItem = {
        let barButton = UIBarButtonItem(barButtonSystemItem: .close, target: nil, action: nil)
        return barButton
    }()

    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(TrackingCell.self, forCellReuseIdentifier: "TrackingCell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()

    init(log: [TrackPoint]) {
        self.log = log
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        setupView()
    }

    func setupView() {
        title = "Tracking Log"
        view.backgroundColor = .white
        tableView.delegate = self
        tableView.dataSource = self
        view.addSubview(tableView)

        closeButton.target = self
        closeButton.action = #selector(closeButtonTapped)
        self.navigationItem.rightBarButtonItem = closeButton

        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    @objc func closeButtonTapped() {
        self.navigationController?.dismiss(animated: true)
    }
}

extension DetailViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
}

extension DetailViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return log.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "TrackingCell", for: indexPath) as? TrackingCell else { return UITableViewCell() }

        let title = log[indexPath.row].title ?? ""
        let subTitle = log[indexPath.row].address ?? ""
        cell.configure(title: title, subTitle: subTitle)
        return cell
    }
}

class TrackingCell: UITableViewCell {

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(title: String, subTitle: String) {
        textLabel?.text = title
        detailTextLabel?.text = subTitle
    }
}
