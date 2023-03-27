//
//  ViewController.swift
//  Abc
//
//  Created by Aryan Garg on 20/03/23.
//

import UIKit
import AVFoundation
import AudioToolbox

class ViewController: UIViewController {
    
    let videoCapture = VideoCapture()
    var previewLayer:AVCaptureVideoPreviewLayer?
    
    let pointslayer = CAShapeLayer()
    
    var isBrushingDone = false

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        setupVideoPreview()
        
        videoCapture.predictor.delegate = self
    }
    
    private func setupVideoPreview(){
        
        videoCapture.startCaptureSession()
        previewLayer = AVCaptureVideoPreviewLayer(session: videoCapture.captureSession)
        
        
        guard let previewLayer = previewLayer else {return}
        
        view.layer.addSublayer(previewLayer)
        previewLayer.frame = view.frame
        
        view.layer.addSublayer(pointslayer)
        pointslayer.frame = view.frame
        pointslayer.strokeColor = UIColor.green.cgColor
    }
}

extension ViewController: PredictorDelegate{
    func predictor(_ predictor: Predictor, didLabelAction action: String, with confidence: Double) {
        if action == "Correct Way Keep it Up" {
            print("Brushing is Good")
            isBrushingDone = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 3){
                self.isBrushingDone = false
            }
            
            DispatchQueue.main.async {
                AudioServicesPlayAlertSound(SystemSoundID(1322))
            }
        }
    }
    
    func predictor(_ predictor: Predictor, DidFindNewRecodnisedPoints points: [CGPoint]) {
        guard let previewLayer = previewLayer else{
            print("Preview Layer Not Found")
            return
        }
        
        let convertedPoints = points.map{
            previewLayer.layerPointConverted(fromCaptureDevicePoint: $0)
        }
        let combinedpath = CGMutablePath()
        
        for point in convertedPoints{
            let dotPath = UIBezierPath(ovalIn: CGRect(x: point.x, y: point.y, width: 10, height: 10))
            combinedpath.addPath(dotPath.cgPath)
        }
        
        pointslayer.path = combinedpath
        
        DispatchQueue.main.async {
            self.pointslayer.didChangeValue(for: \.path)
        }
    }
}

