
import UIKit
import SQLite3

class ProductDetailViewController: UIViewController {
    
    //MARK: Outlets
    @IBOutlet weak var productImage: UIImageView!
    @IBOutlet weak var productCountLabel: UILabel!
    @IBOutlet weak var productRatingLabel: UILabel!
    @IBOutlet weak var productCategoryLabel: UILabel!
    @IBOutlet weak var productDescriptionLabel: UILabel!
    
    var product: ProductModel?
    var indexOfProduct: Int?
    var dbDetailsObject: OpaquePointer?
    let tableNameProducts = "Products"
    let databaseName = "Products.sqlite" //Step 3 - create Database Name
    var isDataBaseOpened = false
    
    var passDataClosure: ((ProductModel?, _ index: Int?) -> Void)?
    
    //MARK: LifeCycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        creatCartButton()
        productCountLabel.text = "Count:\(product?.count ?? 0)"
        productDescriptionLabel.text = "Description:\(product?.description ?? "")"
        productCategoryLabel.text = "Category:\(product?.category ?? "")"
        productRatingLabel.text = "Rate:\(product?.rate ?? 0)"
        
        if let image = product?.image {
            self.productImage.image = image
        } else {
            fetchImageFromNet(product?.imageUrl)
        }
    }
    
    private func fetchImageFromNet(_ url: URL?) {
        if let url = url {
            downloadImage(url: url) { status, image in
                // Got url response
                if status {
                    // Success
                    // save image to DD
                    guard let image = image,
                          let product = self.product else {
                              return
                          }
                    self.saveImageToDocumentDirectory(name: "Image\(product.id)",
                                                      image: image)
                    
                } else {
                    // Failure
                    print("Could not fetch image from API")
                }
            }
        } else {
            print("Invalid/Empty URL")
        }
    }
    
    //MARK: Create Button
    private func creatCartButton() {
        let addtocartButton = UIBarButtonItem(barButtonSystemItem: .bookmarks,
                                              target: self,
                                              action: #selector(self.moveToCartButtonAction))
        self.navigationItem.rightBarButtonItem = addtocartButton
    }
    
    @objc func moveToCartButtonAction() {
        if !isDataBaseOpened {
            openCreateDatabase() // To call this Function
            createProductTableDB() // To call this Function
        }
        isDataBaseOpened = true
        
        guard let productObj = self.product else {
            print("Product object missing")
            return
        }
        
        insertDataInTable(product: productObj)
        
        // Back Data Passing
        guard let closure = self.passDataClosure else {
            print("Closure is missing")
            return
        }
        closure(self.product,
                indexOfProduct)
        self.navigationController?.popViewController(animated: true)
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
    //MARK: Step 3 - Create Employees Table in Database
    private func createProductTableDB() {
        var opaquePointerObject_CreateTable: OpaquePointer?
        
        let createTableQuery = "CREATE TABLE \(tableNameProducts)(ID INTEGER PRIMARY KEY, Title TEXT,Price DOUBLE,Description TEXT,Category TEXT,Image TEXT,Rate DOUBLE, Count INTEGER)"
        
        //Step-3.1 -> Preparing a Query -> we need query because sqlite understands a query language to communicate.
        // * Query has fixed Syntax
        if sqlite3_prepare_v2(self.dbDetailsObject,
                              createTableQuery,
                              -1,
                              &opaquePointerObject_CreateTable,
                              nil) == SQLITE_OK { /* Sqlite Ok used to check the query condition*/
            print("Query Prepared Successful")
            
            //Step-3.2 -> Execute Query -> If Successful
            if sqlite3_step(opaquePointerObject_CreateTable) == SQLITE_DONE { /* Sqlite Done used to execute an action  i.e To create Table */
                print("Table Employee Created Successfully")
            } else {
                print("Table Employee Not Created")
            }
            
        } else {
            print("Query Not Prepared. Some issue in Create Table Query. No proper Query Or Table Already Exists")
        }
    }
    //MARK: Step 4 - To Insert Data in Table
    private func insertDataInTable(product: ProductModel) {
        var OpaquePointerInsertData: OpaquePointer?
        let insertQuery = "INSERT INTO \(tableNameProducts)(ID,Title,Price,Description,Category,Rate,Count,Image) VALUES(?,?,?,?,?,?,?,?)"
        // Prepare
        if sqlite3_prepare_v2(self.dbDetailsObject,
                              insertQuery,
                              -1,
                              &OpaquePointerInsertData,
                              nil) == SQLITE_OK {/* Sqlite Ok used to check the query condition*/
            // Conversions
            let id = Int32(product.id)
            let title = (product.title as NSString).utf8String
            let price = Double(product.price)
            let description = (product.description as NSString).utf8String
            let category = (product.category as NSString).utf8String
            let imageName = ((product.imageName ?? "") as NSString).utf8String
            let rate = Double(product.rate)
            let count = Int32(product.count)
            
            //Binding
            sqlite3_bind_int(OpaquePointerInsertData, 1, id) // Id
            sqlite3_bind_text(OpaquePointerInsertData, 2, title, -1, nil) // Title
            sqlite3_bind_double(OpaquePointerInsertData, 3, price) // Price
            sqlite3_bind_text(OpaquePointerInsertData,4,description, -1,nil) // Description
            sqlite3_bind_text(OpaquePointerInsertData, 5, category,-1,nil) // Category
            sqlite3_bind_double(OpaquePointerInsertData, 6, rate) // Rate
            sqlite3_bind_int(OpaquePointerInsertData, 7, count) // Count
            sqlite3_bind_text(OpaquePointerInsertData, 8, imageName, -1, nil)
            // step
            if sqlite3_step(OpaquePointerInsertData) == SQLITE_DONE { /* Sqlite Done used to execute an action  i.e To Inserting Data */
                print("Data Inserted Successfully")
            } else {
                print("Insert data Failed")
            }
            
        } else {
            print("Insert Query not Prepared")
        }
        
    }
    
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
            if sqlite3_step(readStatement) == SQLITE_ROW {
                
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
                
            } else {
                print("Read Query NOT executed")
            }
            return products
        } else {
            print("Read Query Compilation Failed")
            return [ProductModel]()
        }
    }
}

// MARK: Image download
extension ProductDetailViewController {
    func downloadImage(url: URL, completionHandler: @escaping ((_ status: Bool, _ image: UIImage?) -> Void)) {
        let session = URLSession(configuration: .default)
        let dataTask = session.dataTask(with: url) { data, response, error in
            
            if let error = error {
                // Error
                print(error.localizedDescription)
                completionHandler(false, nil)
            } else {
                // No error
                guard let data = data else {
                    print("Image data not received from URL")
                    return
                }
                let image = UIImage(data: data)
                completionHandler(true, image)
            }
        }
        dataTask.resume()
    }
}
// MARK: Save data to DD
extension ProductDetailViewController {
    private func saveImageToDocumentDirectory(name: String, image: UIImage) {
        guard let documentDirPathWithImageName = getDDPathFor(imageName: name) else {
            print("DD path not found")
            return
        }
        
        // Save to DD
        if let imageData = image.jpegData(compressionQuality: 1) {
            do {
                try imageData.write(to: documentDirPathWithImageName)
                self.product?.image = image
                self.product?.imageName = name
                DispatchQueue.main.async {
                    self.productImage.image = image
                }
                print("Image data saved to DD")
            } catch {
                print("Could not save image")
            }
        } else {
            print("Unable to get the data")
        }
    }
    
    private func getDDPathFor(imageName: String) -> URL? {
        do {
            let documentDir = try FileManager.default.url(for: .documentDirectory,
                                                             in: .userDomainMask,
                                                             appropriateFor: nil,
                                                             create: false).appendingPathComponent(imageName)
            return documentDir
            
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }
}
