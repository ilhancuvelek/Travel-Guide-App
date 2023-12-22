//
//  ViewController.swift
//  TravelMark
//
//  Created by İlhan Cüvelek on 18.12.2023.
//

import UIKit
import CoreData
class ViewController: UIViewController,UITableViewDelegate,UITableViewDataSource {

    @IBOutlet var tableView: UITableView!
    
    var idList = [UUID]()
    var titleList = [String]()
    var selectedId:UUID?
    var selectedTitle=""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate=self
        tableView.dataSource=self
        
        self.tableView.backgroundColor = UIColor.secondaryLabel
        
        navigationController?.navigationBar.topItem?.rightBarButtonItem=UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addButtonItem))
        getPlaces()
    }
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(getPlaces), name: NSNotification.Name(rawValue: "newPlace"), object: nil)
    }
    @objc func getPlaces(){
        
        idList.removeAll(keepingCapacity: false)
        titleList.removeAll(keepingCapacity: false)
        
        let appDelegate=UIApplication.shared.delegate as! AppDelegate
        let context=appDelegate.persistentContainer.viewContext
        
        let fetchRequest=NSFetchRequest<NSFetchRequestResult>(entityName: "Places")
        fetchRequest.returnsObjectsAsFaults=false
        
        do{
            let results=try context.fetch(fetchRequest)
            if results.count>0{
                for result in results as! [NSManagedObject] {
                    if let id=result.value(forKey: "id") as? UUID{
                        idList.append(id)
                    }
                    if let title=result.value(forKey: "title") as? String{
                        titleList.append(title)
                    }
                    tableView.reloadData()
                }
            }
        }catch{
            print("error")
        }
    }
    @objc func addButtonItem(){
        selectedTitle=""
        performSegue(withIdentifier: "toDetailVC", sender: nil)
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return idList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        var content=cell.defaultContentConfiguration()
        content.text=titleList[indexPath.row]
        cell.backgroundColor=UIColor.clear
        content.textProperties.color=UIColor.white
        cell.contentConfiguration=content
        return cell
    }
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            deletePlace(id:idList[indexPath.row],index: indexPath.row)
        }
    }
    func deletePlace(id:UUID?,index:Int){
        
        let appDelegate=UIApplication.shared.delegate as! AppDelegate
        let context=appDelegate.persistentContainer.viewContext
        
        let fetchRequest=NSFetchRequest<NSFetchRequestResult>(entityName: "Places")
        let stribgUUID=id?.uuidString
        fetchRequest.predicate=NSPredicate(format: "id=%@", stribgUUID!)
        fetchRequest.returnsObjectsAsFaults=false
        
        do{
            let results=try context.fetch(fetchRequest)
            if results.count>0 {
                for result in results as! [NSManagedObject] {
                    if let id=result.value(forKey: "id") as? UUID{
                        if id==idList[index]{
                            context.delete(result)
                            idList.remove(at: index)
                            titleList.remove(at: index)
                            
                            tableView.reloadData()
                            
                            do{
                                try context.save()
                            }catch{
                                print("error")
                            }
                        }
                    }
                }
            }
        }catch{
            print("error")
        }
        
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedId=idList[indexPath.row]
        selectedTitle=titleList[indexPath.row]
        performSegue(withIdentifier: "toDetailVC", sender: nil)
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier=="toDetailVC"{
            let destinationVC=segue.destination as! DetailViewController
            destinationVC.chosenId=selectedId
            destinationVC.chosenTitle=selectedTitle
        }
    }



}

