//
//  MainViewController.swift
//  iTrackerMap
//
//  Created by Danny Tsang on 9/8/22.
//

import CoreLocation
import MapKit
import UIKit

class MainViewController: UIViewController {

    private var trackingLog: TrackingLog = TrackingLog(log: [])
    private let coreLocationManager = CLLocationManager()
    private let geoCoder = CLGeocoder()

    private var centerOnUser: Bool = false
    private var regionmeters = 100.0
    private var userLocation: CLLocationCoordinate2D?
    private var initialMapLoad: Bool = true

    private var mapView: MKMapView = {
        let mapView = MKMapView()
        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapView.showsUserLocation = true
        mapView.register(TrackingAnnotationView.self, forAnnotationViewWithReuseIdentifier: "TrackingAnnotationView")
        return mapView
    }()

    private let slider: UISlider = {
        let slider = UISlider()
        slider.minimumValue = 1000
        slider.maximumValue = 50000
        slider.value = 10000
        slider.translatesAutoresizingMaskIntoConstraints = false
        return slider
    }()

    private let followModeControl: UISegmentedControl = {
        let segmentedControl = UISegmentedControl(items: ["None", "Follow", "Heading"])
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        return segmentedControl
    }()

    private var isTracking: Bool = false
    private var trackingTimer: Timer?
    private let trackingButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "Start Tracking"
        config.showsActivityIndicator = false
        config.imagePadding = 10
        config.imagePlacement = .trailing

        let button = UIButton(configuration: config)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let detailBarButton: UIBarButtonItem = {
        let barButton = UIBarButtonItem(barButtonSystemItem: .bookmarks, target: nil, action: nil)
        return barButton
    }()

    init() {
        super.init(nibName: nil, bundle: nil)
        self.trackingLog = loadLog()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        setupView()
    }

    private func setupView() {
        title = "iTracking Map"
        view.backgroundColor = .white

        coreLocationManager.requestWhenInUseAuthorization()
        coreLocationManager.delegate = self
        coreLocationManager.startUpdatingLocation()
        coreLocationManager.startUpdatingHeading()

        mapView.delegate = self
        view.addSubview(mapView)

        slider.addTarget(self, action: #selector(sliderChanged), for: .valueChanged)
        view.addSubview(slider)

        let findUserButton = UIBarButtonItem(barButtonSystemItem: .search, target: self, action: #selector(findUserTapped))
        navigationItem.rightBarButtonItem = findUserButton

        detailBarButton.target = self
        detailBarButton.action = #selector(detailButtonTapped)
        navigationItem.leftBarButtonItem = detailBarButton

        followModeControl.addTarget(self, action: #selector(followModeChanged), for: .valueChanged)
        view.addSubview(followModeControl)

        trackingButton.addTarget(self, action: #selector(trackingButtonTapped), for: .touchUpInside)
        view.addSubview(trackingButton)

        NSLayoutConstraint.activate([
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mapView.topAnchor.constraint(equalTo: view.topAnchor, constant: -60),
            mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 60),

            followModeControl.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            followModeControl.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            followModeControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),

            slider.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            slider.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            slider.bottomAnchor.constraint(equalTo: trackingButton.topAnchor, constant: -20),

            trackingButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            trackingButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            trackingButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        ])
    }

    @objc func sliderChanged(sender: UISlider) {
        let inverseRange = sender.maximumValue - sender.value + sender.minimumValue
        setRegion(range: inverseRange, animated: false)
    }

    @objc func findUserTapped() {
        centerUserLocation()
    }

    @objc func followModeChanged(sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            slider.isEnabled = true
            mapView.setUserTrackingMode(.none, animated: true)
        case 1:
            slider.isEnabled = false
            mapView.setUserTrackingMode(.follow, animated: true)
        case 2:
            slider.isEnabled = false
            mapView.setUserTrackingMode(.followWithHeading, animated: true)
        default:
            slider.isEnabled = true
            mapView.setUserTrackingMode(.none, animated: true)
        }
    }

    @objc func trackingButtonTapped(sender: UIButton) {
        isTracking = !isTracking
        var config = sender.configuration
        config?.title = isTracking ? "Stop Tracking" : "Start Tracking"
        config?.showsActivityIndicator = isTracking ? true : false
        sender.configuration = config

        if isTracking {
            startTracking()
        } else {
            stopTracking()
        }
    }

    @objc func detailButtonTapped() {
        let detailVC = DetailViewController(log: trackingLog.log)
        detailVC.modalPresentationStyle = .popover

        let navController = UINavigationController()
        navController.pushViewController(detailVC, animated: true)

        self.present(navController, animated: true)
    }

    func startTracking() {
        trackingTimer = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(markLocation), userInfo: nil, repeats: true)
        trackingTimer?.fire()
    }

    func stopTracking() {
        trackingTimer?.invalidate()
    }

    @objc func markLocation() {
        let currentCoordinate = mapView.userLocation.coordinate
        let currentLocation = CLLocation(latitude: currentCoordinate.latitude, longitude: currentCoordinate.longitude)

        let timeStamp = Date.now
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/YYYY HH:mm:ss"

        geoCoder.reverseGeocodeLocation(currentLocation) { placemarks, error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                return
            }

            guard let placemark = placemarks?.first else {
                print("Error: No Placemarks)")
                return
            }

            let title = placemark.name ?? "Place"
            let street = placemark.thoroughfare ?? ""
            let city = placemark.locality ?? ""
            let state = placemark.subAdministrativeArea ?? ""
            let postalCode = placemark.postalCode ?? ""
            let address = "\(street), \(city), \(state) \(postalCode)"

            let newTrackPoint = TrackPoint(latitude: currentCoordinate.latitude, longitude: currentCoordinate.longitude, timestamp: timeStamp, title: title, subTitle: "Ping", address: address)
            self.trackingLog.log.append(newTrackPoint)

            let annotation = TrackingAnnotation(coordinate: currentCoordinate, title: title, subTitle: address)
            self.mapView.addAnnotation(annotation)

            self.saveLog()
        }
    }

    func saveLog() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(trackingLog)
            UserDefaults.standard.set(data, forKey: "trackingLog")
        } catch {
            print("Unable to save data.")
        }

    }

    func loadLog() -> TrackingLog {
        if let data = UserDefaults.standard.data(forKey: "trackingLog") {
            do {
                let decoder = JSONDecoder()
                let trackingLog = try decoder.decode(TrackingLog.self, from: data)
                return trackingLog
            } catch {
                print("Unable to load data")
            }
        }
        return TrackingLog(log:[])
    }

}

extension MainViewController: MKMapViewDelegate {
    func centerUserLocation() {
        let currentCoordinate = mapView.userLocation.coordinate
        mapView.setCenter(CLLocationCoordinate2DMake(currentCoordinate.latitude, currentCoordinate.longitude), animated: true)
    }

    func setRegion(range: Float, animated: Bool) {
        mapView.setRegion(MKCoordinateRegion.init(center: mapView.userLocation.coordinate, latitudinalMeters: CLLocationDistance(range), longitudinalMeters: CLLocationDistance(range)), animated: animated)
    }

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        } else {
            let mapAnnotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "TrackingAnnotationView") ?? TrackingAnnotationView(annotation: annotation, reuseIdentifier: "TrackingAnnotationView")
            mapAnnotationView.annotation = annotation
            mapAnnotationView.canShowCallout = true

//            let mapAnnotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "AnnotationView") ?? MKAnnotationView(annotation: annotation, reuseIdentifier: "AnnotationView")
//            mapAnnotationView.canShowCallout = true
//            mapAnnotationView.image = UIImage(systemName:"gear")
            return mapAnnotationView
        }
    }

    func mapViewDidFinishLoadingMap(_ mapView: MKMapView) {
        if initialMapLoad {
            initialMapLoad = false
            centerUserLocation()
        }
    }
}

extension MainViewController: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        manager.startUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        userLocation = location.coordinate
        centerUserLocation()
        manager.stopUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        print("Heading Updated")
    }
    
}
