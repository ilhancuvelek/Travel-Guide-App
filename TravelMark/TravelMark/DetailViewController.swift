//
//  DetailViewController.swift
//  TravelMark
//
//  Created by İlhan Cüvelek on 18.12.2023.
//

import UIKit
import MapKit
import CoreData
import CoreLocation

class DetailViewController: UIViewController,MKMapViewDelegate ,UIImagePickerControllerDelegate,UINavigationControllerDelegate,CLLocationManagerDelegate{

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleText: UITextField!
    @IBOutlet weak var subtitleText: UITextField!
    @IBOutlet weak var mapView: MKMapView!
    

    var chosenLatitude=0.0
    var chosenLongitude=0.0
    var chosenId:UUID?
    var chosenTitle=""
    
    var annotationTitle=""
    var annotationSubtitle=""
    var annotationLatitude=0.0
    var annotationLongitude=0.0
    
    let locationManager=CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        mapView.delegate=self
        locationManager.delegate=self
        locationManager.desiredAccuracy=kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        if chosenTitle != ""{
            let stringUUID=chosenId?.uuidString
            getPlace(id: stringUUID!)
        }
        
        let gestureRecognizer=UILongPressGestureRecognizer(target: self, action: #selector(chooseLocation(gestureRecognizer: )))
        gestureRecognizer.minimumPressDuration=2
        mapView.addGestureRecognizer(gestureRecognizer)
        
        imageView.isUserInteractionEnabled=true
        let imageRecognizer=UITapGestureRecognizer(target: self, action: #selector(pickPhoto))
        imageView.addGestureRecognizer(imageRecognizer)

    }
    func getPlace(id:String){
        
        let appDelegate=UIApplication.shared.delegate as! AppDelegate
        let context=appDelegate.persistentContainer.viewContext
        
        let fetchRequet=NSFetchRequest<NSFetchRequestResult>(entityName: "Places")
        fetchRequet.predicate=NSPredicate(format: "id=%@", id)
        fetchRequet.returnsObjectsAsFaults=false
        
        do{
            let results=try context.fetch(fetchRequet)
            if results.count>0{
                for result in results as! [NSManagedObject] {
                    if let title=result.value(forKey: "title") as? String{
                        annotationTitle=title
                        if let subtitle=result.value(forKey: "subtitle") as? String{
                            annotationSubtitle=subtitle
                            if let latitude=result.value(forKey: "latitude") as? Double{
                                annotationLatitude=latitude
                                if let longitude=result.value(forKey: "longitude") as? Double{
                                    annotationLongitude=longitude
                                    if let data=result.value(forKey: "image") as? Data{
                                        let image=UIImage(data: data)
                                        imageView.image=image
                                        
                                        let annotation=MKPointAnnotation()
                                        annotation.title=title
                                        annotation.subtitle=subtitle
                                        let coordinate=CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                                        annotation.coordinate=coordinate
                                        mapView.addAnnotation(annotation)
                                        
                                        titleText.text=annotationTitle
                                        subtitleText.text=annotationSubtitle
                                        
                                        // detay a gittiğinde kullaanıcın konumu değişmesin. zaten işaretlediği yeri db den getirdik.
                                        locationManager.stopUpdatingLocation()
                                        
                                        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                                        let region = MKCoordinateRegion(center: coordinate, span: span)
                                        mapView.setRegion(region, animated: true)
                                    }
                                }
                               
                            }
                        }
                    }
                }
            }
        }catch{
            print("error")
        }
        
    }
    @objc func chooseLocation(gestureRecognizer:UILongPressGestureRecognizer){
        if gestureRecognizer.state == .began{
            let touchedPoint=gestureRecognizer.location(in: self.mapView)
            let touchedCoordinate=self.mapView.convert(touchedPoint, toCoordinateFrom: self.mapView)
            
            chosenLatitude=touchedCoordinate.latitude//db ye eklemek için burdan aldık
            chosenLongitude=touchedCoordinate.longitude//db ye eklemek için burdan aldık
            
            let annotation=MKPointAnnotation()
            annotation.coordinate=touchedCoordinate
            annotation.title=titleText.text
            annotation.subtitle=subtitleText.text
            self.mapView.addAnnotation(annotation)
        }
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if chosenTitle == ""{
            let stringUUID=chosenId?.uuidString
            let location=CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude)
            let span=MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            let region=MKCoordinateRegion(center: location, span: span)
            mapView.setRegion(region, animated: true)
        }
    }
    // anotasyonları (pinleri) özelleştime
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        if annotation is MKUserLocation {// kullanıcının yerini anotasyon ile gösterme
            return nil
        }
        
        let reuseId = "myAnnotation"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKMarkerAnnotationView
        
        if pinView == nil {
            pinView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView?.canShowCallout = true// baloncuk ile extra bilgi göster
            pinView?.tintColor = UIColor.black
            
            let button = UIButton(type: UIButton.ButtonType.detailDisclosure)
            pinView?.rightCalloutAccessoryView = button//pine tıklandığında buton gözüksün
            
        } else {
            pinView?.annotation = annotation
        }
        return pinView
    }
    // pin e basıldığında baloncukta çıkan butona basıp navigasyona yönlendirme
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if chosenTitle != "" {
            
            let requestLocation = CLLocation(latitude: annotationLatitude, longitude: annotationLongitude)

            CLGeocoder().reverseGeocodeLocation(requestLocation) { (placemarks, error) in
                //closure
                
                if let placemark = placemarks {
                    if placemark.count > 0 {
                                      
                        let newPlacemark = MKPlacemark(placemark: placemark[0])
                        let item = MKMapItem(placemark: newPlacemark)
                        item.name = self.annotationTitle
                        let launchOptions = [MKLaunchOptionsDirectionsModeKey:MKLaunchOptionsDirectionsModeDriving]
                        item.openInMaps(launchOptions: launchOptions)
                }
            }
        }
        }
    }
    @objc func pickPhoto(){
        let picker=UIImagePickerController()
        picker.delegate=self
        picker.sourceType = .photoLibrary
        present(picker, animated: true,completion: nil)
    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        imageView.image = info[.originalImage] as? UIImage
        self.dismiss(animated: true,completion: nil)
    }
    @IBAction func saveButton(_ sender: Any) {
        
        let appDelegate=UIApplication.shared.delegate as! AppDelegate
        let context=appDelegate.persistentContainer.viewContext
        
        let newPlace=NSEntityDescription.insertNewObject(forEntityName: "Places", into: context)
        
        newPlace.setValue(UUID(), forKey: "id")
        newPlace.setValue(titleText.text, forKey: "title")
        newPlace.setValue(subtitleText.text, forKey: "subtitle")
        newPlace.setValue(chosenLatitude, forKey: "latitude")
        newPlace.setValue(chosenLongitude, forKey: "longitude")
        let data = imageView.image?.jpegData(compressionQuality: 0.5)
        newPlace.setValue(data, forKey: "image")
        
        do{
            try context.save()
            print("succes")
        }catch{
            print("error")
        }
        
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "newPlace"), object: nil)
        navigationController?.popViewController(animated: true)
    }
    

}
