//
//  TrackingAnnotationView.swift
//  iTrackerMap
//
//  Created by Danny Tsang on 9/9/22.
//

import MapKit
import UIKit

class TrackingAnnotationView: MKAnnotationView {

    let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.boldSystemFont(ofSize: 16)
        return label
    }()

    let addressLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 14)
        return label
    }()

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        setupView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupView () {
        frame = CGRect(x: 0, y: 0, width: 10, height: 10)
//        centerOffset = CGPoint(x: 0, y: -frame.size.height / 2)

        canShowCallout = true
        backgroundColor = .clear

        let circle = UIView()
        circle.backgroundColor = .red
        circle.layer.borderColor = UIColor.black.cgColor
        circle.layer.cornerRadius = 5
        circle.layer.borderWidth = 2
        circle.translatesAutoresizingMaskIntoConstraints = false
        addSubview(circle)

        NSLayoutConstraint.activate([
            circle.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            circle.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            circle.heightAnchor.constraint(equalToConstant: 10),
            circle.widthAnchor.constraint(equalToConstant: 10),
        ])
    }

    func configureView() {
        guard let annotation = annotation else { return }
        self.titleLabel.text = annotation.title ?? ""
        self.addressLabel.text = annotation.subtitle ?? ""
        self.image = UIImage(systemName: "shippingbox.fill")?.withTintColor(UIColor.blue)
    }
}
