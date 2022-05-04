
import UIKit
import SQLite3

class DisplayProductViewController: UIViewController {
    
    //MARK: Collectionview Outlet
    @IBOutlet weak var collectionView: UICollectionView!
    private var isBookmarkSwitchOn = false
    
    //MARK: Array
    var productDetailsArray: [ProductModel] = []
    var dbDetailsObject: OpaquePointer?
    let tableNameProducts = "Products"
    let databaseName = "Products.sqlite" //Step 3 - create Database Name
    
    //MARK: LifeCycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
       
        collectionView.dataSource = self
        collectionView.delegate = self
        xibCellRegistration()
        gettingDataFromDB()
        openCreateDatabase()
        switchBarButton()
        fetchDataFromDBAndLoadCollectionView()
    }
    
    //MARK: Xib Registration func
    func xibCellRegistration() {
        // Collection View Cell Register
        let productCollectionViewCellXib = UINib(nibName: "ProductCollectionViewCell", bundle: .main)
        collectionView.register(productCollectionViewCellXib, forCellWithReuseIdentifier: "ProductCollectionViewCell")
    }
    private func fetchDataFromDBAndLoadCollectionView() {
        productDetailsArray = readData()
        collectionView.reloadData()
    }
    
    //MARK: Getting Data From DB func
    private func gettingDataFromDB() {
        
        // 1. Create request of GET type
        let urlString = "https://fakestoreapi.com/products"
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // Step2: Create session object
        let session = URLSession(configuration: .default)
        
        // Step3: Create Data task
        let dataTask = session.dataTask(with: request) { data, response, error in
            
            if error == nil {// No error
                guard let data = data else {
                    print("Data is Nil")
                    return
                }
                
                do {
                    guard let productsArray = try JSONSerialization.jsonObject(with: data) as? [[String:Any]]
                    else {
                        print("Invalid JSON")
                        return
                    }
                    
                    for productDictionary in productsArray {
                        let proID = productDictionary["id"] as? Int
                        let proTitle = productDictionary["title"] as? String
                        let proPrice = productDictionary["price"] as? Double
                        let proDescription = productDictionary["description"] as? String
                        let proCategory = productDictionary["category"] as? String
                        let proRating = productDictionary["rating"] as? [String:Any]
                        let proRate = proRating?["rate"] as? Double
                        let proCount = proRating?["count"] as? Double
                        
                        let imageString = productDictionary ["image"] as? String ?? ""
                        let proImageUrl = URL(string: imageString)
                        
                        let product = ProductModel(id: proID ?? 0,
                                                   title: proTitle ?? "Invalid",
                                                   price: proPrice ?? 0,
                                                   description: proDescription ?? "Invalid",
                                                   category: proCategory ?? "Invalid",
                                                   rate: proRate ?? 0,
                                                   count: proCount ?? 0,
                                                   imageUrl: proImageUrl,
                                                   image: nil )
                        self.productDetailsArray.append(product)
                    }
                    DispatchQueue.main.async {
                        self.collectionView.reloadData()
                    }
                    
                }catch {
                    print(error.localizedDescription)
                }
                
                print(data)
            } else {
                print("We have error: \(error?.localizedDescription ?? "")")
            }
        }
        
        // Step4: Call API
        dataTask.resume()
    }
        
    //MARK: Create Navigation Bar Button
    private func switchBarButton() {
        
        let customSwitch = UISwitch()
        customSwitch.isOn = false
        customSwitch.setOn(false, animated: true)
        
        customSwitch.addTarget(self, action: #selector(self.switchTarget(sender:)), for: .valueChanged)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem.init(customView: customSwitch)
    }
    
    //MARK: Button Action
    @objc func switchTarget(sender: UISwitch!)
    {
        if sender.isOn {
            clearCollectionViewData()
            isBookmarkSwitchOn = true
            self.title = "Data from API"
            gettingDataFromDB()
        } else{
            clearCollectionViewData()
            isBookmarkSwitchOn = false
            self.title = "Data from the File Directory"
            productDetailsArray = readData()
        }
    }
    
    private func clearCollectionViewData() {
        productDetailsArray.removeAll()
        collectionView.reloadData()
    }
    
    //MARK: Read From Data Base
    private func readData() -> [ProductModel] {
        var readStatement: OpaquePointer?
        let readQuery = "SELECT * FROM \(tableNameProducts)"
        
        var products = [ProductModel]()
        
        if sqlite3_prepare_v2(self.dbDetailsObject,
                              readQuery,
                              -1,
                              &readStatement,
                              nil) == SQLITE_OK {
            print("Read Query Compiled Successfully")
            while sqlite3_step(readStatement) == SQLITE_ROW {
                
                print("Read Query executed successfully")
                let idInt32 = sqlite3_column_int(readStatement, 0)
                let id = Int(idInt32)
                let price = sqlite3_column_double(readStatement, 2)
                let rate = sqlite3_column_double(readStatement, 6)
                let countInt32 = sqlite3_column_int(readStatement, 7)
                let count = Int(countInt32)
                guard
                    let titleCStr = sqlite3_column_text(readStatement, 1),
                    let descriptionCStr = sqlite3_column_text(readStatement, 3),
                    let categoryCStr = sqlite3_column_text(readStatement, 4)
                        //  let image = sqlite3_column_blob(readStatement, 5)
                else {
                    return [ProductModel]()
                }
                let title = String(cString: titleCStr)
                let description = String(cString: descriptionCStr)
                let category = String(cString: categoryCStr)
                
                print("Product Details:\nId: \(id),\nTitle:\(title),\nDescription: \(description),\nPrice: \(price),\nR: \(price),\nCategory: \(category),\nRate: \(rate),\nCount: \(count)")
                
                let product = ProductModel(id: id, title: title, price: price, description: description, category: category, rate: rate, count: Double(count), imageUrl: nil, image: nil)
                products.append(product)
                
            }
            return products
        } else {
            print("Read Query Compilation Failed")
            return [ProductModel]()
        }
    }
    
    //MARK: Step 2 - Create DataBase
    private func openCreateDatabase() {
        guard let dbPath = getPathForDocumentsDirectory() else{
            print("Documents Directory Path is Missing")
            return
        }
        print("DB Path: \(dbPath)")
        
        //Step2.1 - Importing SQLite3 and To check Database is Created or already present (bitcode.sqlite)
        var dbdetails: OpaquePointer?
        if sqlite3_open(dbPath,
                        &dbdetails) == SQLITE_OK { /* Sqlite Ok used to check the query condition*/
            print("Database is successfully created Or Already Present & we are able to access it/Open it")
            self.dbDetailsObject = dbdetails
        } else {
            print("Unable to Create Or Open DB")
            
        }
    }
    
    
    //MARK: Step 1 - To Get Path For Documents Directory
    private func getPathForDocumentsDirectory() -> String? {
        do{
            // Use to access Document Directory
            let documentDirectoryURL = try FileManager.default.url(for: .documentDirectory,
                                                                      in: .userDomainMask,
                                                                      appropriateFor: nil,
                                                                      create: false)
            // To check where the Database is in documents Directory
            let dbPath = documentDirectoryURL.appendingPathComponent(self.databaseName)
            return dbPath.absoluteString
            
        } catch {
            print(error.localizedDescription)
            return nil
        }
        
    }
    
}

extension DisplayProductViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    //MARK: UICollectionView DataSource methods
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        productDetailsArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        guard let cell = self.collectionView.dequeueReusableCell(withReuseIdentifier: "ProductCollectionViewCell", for: indexPath) as? ProductCollectionViewCell
        else {
            return UICollectionViewCell()
        }
        
        let productIndex = productDetailsArray[indexPath.row]
        cell.productTitle.text = "Title:\(productIndex.title)"
        cell.productPrice.text = "Price:\(productIndex.price)"
        
        return cell
        
    }
    
    //MARK: UICollectionView Delegate Methods
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let vc = self.storyboard?.instantiateViewController(withIdentifier: "ProductDetailViewController") as? ProductDetailViewController {
            vc.product = productDetailsArray[indexPath.row]
            vc.indexOfProduct = indexPath.row
            vc.passDataClosure = { (updatedProduct, index) in
                self.updateNewProductInArray(updatedProduct, index: index)
            }
            self.navigationController?.pushViewController(vc, animated: true)
        } else {
            print("VC not found")
        }
    }
    private func updateNewProductInArray(_ product: ProductModel?, index: Int?) {
        guard let product = product,
        let index = index else {
            print("Product is Empty")
            return
        }        
        productDetailsArray.remove(at: index)
        productDetailsArray.insert(product, at: index)
        let indexPathOfCurrentData = IndexPath(item: index, section: 0)
        collectionView.reloadItems(at: [indexPathOfCurrentData])
            
   }
}

//MARK: UICollectionView Delegate FlowLayout
extension DisplayProductViewController : UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 200.0, height: 100.0)
    }
    
}




//id    :    1
//title    :    Fjallraven - Foldsack No. 1 Backpack, Fits 15 Laptops
//price    :    109.95
//description    :    Your perfect pack for everyday use and walks in the forest. Stash your laptop (up to 15 inches) in the padded sleeve, your everyday
//category    :    men's clothing
//image    :
//    rating        {2}
//rate    :    3.9
//count    :    120






