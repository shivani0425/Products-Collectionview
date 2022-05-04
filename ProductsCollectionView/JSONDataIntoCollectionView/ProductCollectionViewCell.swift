
import UIKit

class ProductCollectionViewCell: UICollectionViewCell {
    
//MARK: Outlets
    @IBOutlet weak var productTitle: UILabel!
    @IBOutlet weak var productPrice: UILabel!
    
 //MARK: Lifecycle Methods
    override func awakeFromNib() {
        super.awakeFromNib()
       
    }

}
