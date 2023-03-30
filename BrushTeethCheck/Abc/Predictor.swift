//
//  Predictor.swift
//  Abc
//
//  Created by Aryan Garg on 31/10/22.
//

import UIKit
import Vision

typealias BrushingClassifier = HandActionClassifier

protocol PredictorDelegate : AnyObject{
    func predictor(_ predictor: Predictor, DidFindNewRecodnisedPoints points: [CGPoint])
    func predictor(_ predictor: Predictor, didLabelAction action: String, with confidence: Double)
}

class Predictor{
    
    weak var delegate: PredictorDelegate?
    
    let predictionWindowSize = 70
    
    var posesWindow = [VNHumanHandPoseObservation]()
    
    init(){
        posesWindow.reserveCapacity(predictionWindowSize)
    }
    
    func estimation(samplebuffer : CMSampleBuffer){
        
        let requestHandler = VNImageRequestHandler(cmSampleBuffer: samplebuffer, orientation: .up)
        
        let request = VNDetectHumanHandPoseRequest(completionHandler: handpose)
        
        do{
            try requestHandler.perform([request])
        } catch {
            print("Unable to perform Operation : \(error) ")
        }
    }
    
    func handpose(request: VNRequest, error: Error?){
            
            guard let observations = request .results as? [VNHumanHandPoseObservation] else {return}
            
            observations.forEach{
                processObservation($0)
            }
        
        if let result = observations.first{
            storeObservation(result)
            labelActionType()
        }
        }
    
    func labelActionType(){
        guard let brushingClassifier = try? BrushingClassifier(configuration: MLModelConfiguration()),
              let poseMultiArray = prepareInputWithObservations(posesWindow),
              let predictions = try? brushingClassifier.prediction(poses: poseMultiArray) else {
            return
        }
        
        let label = predictions.label
        let confidence = predictions.labelProbabilities[label] ?? 0
        
            delegate?.predictor(self, didLabelAction: label, with: confidence)
        
        print("This is Multi Array!!!!!!!!!!!")
        print(poseMultiArray)
    }
    
    func prepareInputWithObservations(_ observations: [VNHumanHandPoseObservation])-> MLMultiArray?{
        
        let numAvailableFrames = observations.count
        let observationNeeded = 30
        var multiArrayBuffer = [MLMultiArray]()
        
        for frameIndex in 0 ..< min(numAvailableFrames, observationNeeded){
            let pose = observations[frameIndex]
            do{
                let oneFrameMultiArray = try pose.keypointsMultiArray()
                multiArrayBuffer.append(oneFrameMultiArray)
            }catch{
                continue
            }
        }
        
        if numAvailableFrames < observationNeeded {
            for _ in 0 ..< (observationNeeded - numAvailableFrames){
                do {
                    let oneFrameMultiArray = try MLMultiArray(shape: [1,3,21], dataType: MLMultiArrayDataType.float32)
                    try resetMultiArray(oneFrameMultiArray)
                    multiArrayBuffer.append(oneFrameMultiArray)
                }catch {
                    continue
                }
            }
        }
        return MLMultiArray(concatenating: [MLMultiArray](multiArrayBuffer), axis: 0, dataType: .float)
    }

    
    func resetMultiArray(_ predictionWindow: MLMultiArray, with value: Double = 0.0) throws {
        let pointer = try UnsafeMutableBufferPointer<Double>(predictionWindow)
        pointer.initialize(repeating: value)
    }
    
    func storeObservation(_ observation: VNHumanHandPoseObservation){
        
        if posesWindow.count >= predictionWindowSize{
            posesWindow.removeFirst()
        }
        
        posesWindow.append(observation)
    }
    
    func processObservation(_ observation: VNHumanHandPoseObservation){
        do{
            let recognisedPoints =  try observation.recognizedPoints(forGroupKey: .all )
            
            let displayedPoints = recognisedPoints.map{
                CGPoint(x: $0.value.x, y: 1 - $0.value.y)}
            
            delegate?.predictor(self, DidFindNewRecodnisedPoints: displayedPoints)
        }catch{
            print("Error in finding Recognised Points")
        }
    }

}
