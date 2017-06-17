import UIKit
import CoreML
import Vision

class ViewController: UIViewController {
  
  // MARK: - IBOutlets
  @IBOutlet weak var scene: UIImageView!
  @IBOutlet weak var answerLabel: UILabel!
  
  // MARK: - Properties
  let vowels: [Character] = ["a", "e", "i", "o", "u"]
  
  // MARK: - View Life Cycle
  override func viewDidLoad() {
    super.viewDidLoad()
    
    guard let image = UIImage(named: "train_night") else {
      fatalError("no starting image")
    }
    
    scene.image = image
    
    guard let ciImage = CIImage(image: image) else {
      fatalError("couldn't convert UIImage to CIImage")
    }
    
    detectScene(image: ciImage)
  }
}

// MARK: - IBActions
extension ViewController {
  
  @IBAction func pickImage(_ sender: Any) {
    let pickerController = UIImagePickerController()
    pickerController.delegate = self
    pickerController.sourceType = .savedPhotosAlbum
    present(pickerController, animated: true)
  }
}

extension ViewController {
  func detectScene(image:CIImage) {
    answerLabel.text = "detecting scene..."
    // designated initializer of GoogLeNetPlaces throws an error, so you must use try when creating it.
    // VNCoreMLModel is simply a container for a Core ML model used with Vision requests.
    guard let model = try? VNCoreMLModel(for: GoogLeNetPlaces().model) else {
      fatalError("can't load Places ML Model")
    }
    
    // Create a Vision request with completion handler
    // request.results is an array of VNClassificationObservation objects, which is what the Vision framework returns when the Core ML model is a classifier, rather than a predictor or image processor. And GoogLeNetPlaces is a classifier, because it predicts only one feature: the image’s scene classification.
    let request = VNCoreMLRequest(model: model) { [weak self] (request, error) in
      guard let results = request.results as? [VNClassificationObservation], let topResult = results.first else {
        fatalError("unexpected result type frmo VNCoreMLRequest")
      }
      
      // Update UI on main queue
      let article = (self?.vowels.contains(topResult.identifier.first!))! ? "an" : "a"
      DispatchQueue.main.async { [weak self] in
        self?.answerLabel.text = "\(Int(topResult.confidence * 100))% it's \(article) \(topResult.identifier)"
      }
    }
    
    // Run the Core ML GoogleNetPlaces classifier on global dispatch queue
    // VNImageRequestHandler is the standard Vision framework request handler; it isn’t specific to Core ML models. You give it the image that came into detectScene(image:) as an argument. And then you run the handler by calling its perform method, passing an array of requests. In this case, you have only one request.
    let handler = VNImageRequestHandler(ciImage: image)
    DispatchQueue.global(qos: .userInteractive).async {
      do {
        try handler.perform([request])
      } catch {
        print(error)
      }
    }
    
  }
  
}





// MARK: - UIImagePickerControllerDelegate
extension ViewController: UIImagePickerControllerDelegate {
  
  func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
    dismiss(animated: true)
    
    guard let image = info[UIImagePickerControllerOriginalImage] as? UIImage else {
      fatalError("couldn't load image from Photos")
    }
    
    scene.image = image
    
    guard let ciImage = CIImage(image: image) else {
      fatalError("couldn't convert UIImage to CIImage")
    }
    
    detectScene(image: ciImage)
  }
}

// MARK: - UINavigationControllerDelegate
extension ViewController: UINavigationControllerDelegate {
}
