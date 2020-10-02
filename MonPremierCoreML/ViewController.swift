//
//  ViewController.swift
//  MonPremierCoreML
//
//  Created by Rodolphe DUPUY on 10/09/2020.
//

import UIKit
import CoreML
import Vision

class ViewController: UIViewController {
    
    @IBOutlet weak var iv: UIImageView!
    @IBOutlet weak var predictionLbl: UILabel!
    @IBOutlet weak var launchML: UIButton!
    
    var picker = UIImagePickerController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        launchML.isEnabled = false
        
        picker.delegate = self
        picker.allowsEditing = false
    }
    
    @IBAction func takeAPic(_ sender: UIButton) {
        setupCamera()
    }
    
    
    // MARK: CoreML
    // 1. Convertie en cgImage
    // 2. Obtenir mon modele CoreML avec un try
    // 3. Convertir mlmodel en visonModel avec un try
    // 4. Faire request
    // 5. Handler
    // 6. Faire ma requete
    // 7.Annalyser ce que l'on recoit
    @IBAction func coreMLAction(_ sender: Any) {
        // 1. Convertie en cgImage
        if let imageToParse = iv.image?.cgImage {
            do {
                // 2. Obtenir mon modele CoreML avec un try
                let model = try SqueezeNet(configuration: MLModelConfiguration())
                let mlModel = model.model
                do {
                    // 3. Convertir mlmodel en visonModel avec un try
                    let visionModel = try VNCoreMLModel(for: mlModel)
                    // 4. Faire request
                    let request = VNCoreMLRequest(model: visionModel) { (response, error) in
                        // 7.Annalyser ce que l'on recoit
                        if let e = error {
                            print("Erreur chef: \(e.localizedDescription)")
                        }
                        if let r = response.results as? [VNClassificationObservation] {
                            print(r)
                            if let f = r.first { // On prend la 1ere ligne
                                let id = f.identifier
                                let confidenceToPercent = f.confidence * 100
                                let confidenceString = String(format: "%.2f", confidenceToPercent)
                                DispatchQueue.main.async {
                                    self.predictionLbl.numberOfLines = 0
                                    self.predictionLbl.text = "Je pense que cet objet est \(id)\n et j'en suis sûr à \(confidenceString)%"
                                }
                            }
                        }
                    }
                    // 5. Handler
                    let handler = VNImageRequestHandler(cgImage: imageToParse, options: [:])
                    // 6. Faire ma requete
                    try handler.perform([request])
                } catch {
                    print(error.localizedDescription)
                }
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    // MARK: Config Appareil photo
    func setupCamera() {
        // Ajouter dans plist: Privacy - Photo Library Usage Description
        // Ajouter dans plist: Privacy - Camera Usage Description
        let controller = UIAlertController(title: "Choisir une image", message: "Photo ou gallerie?", preferredStyle: .alert)
        let photo = UIAlertAction(title: "Appareil Photo", style: .default) { (action) in
            self.picker.sourceType = .camera
            self.present(self.picker, animated: true, completion: nil)
        }
        let gallery = UIAlertAction(title: "Gallerie de photo", style: .default) { (action) in
            self.picker.sourceType = .photoLibrary
            self.present(self.picker, animated: true, completion: nil)
        }
        
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            controller.addAction(photo)
        }
        controller.addAction(gallery)
        present(controller, animated: true, completion: nil)
    }
}

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[.originalImage] as? UIImage {
            self.iv.image = image
            self.launchML.isEnabled = true
        }
        picker.dismiss(animated: true, completion: nil)
    }
    
}

