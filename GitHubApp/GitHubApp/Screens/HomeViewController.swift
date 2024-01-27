import UIKit

class HomeViewController: UIViewController {

    @IBOutlet weak var searchingTextInput: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        let nib = UINib(nibName: "HomeViewController", bundle: nil)
        let view = nib.instantiate(withOwner: self, options: nil).first as! UIView
        self.view = view
        navigationController?.navigationBar.isHidden = true
    }

    @IBAction func searchActonButtonTapped(_ sender: Any) {

    }
}
