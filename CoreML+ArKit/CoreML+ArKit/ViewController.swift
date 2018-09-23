//
//  ViewController.swift
//  CoreML+ArKit
//
//  Created by Sagar More on 23/09/18.
//  Copyright © 2018 Sagar More. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    private let model = GoogLeNetPlaces()
    private let textDepth : Float = 0.01 // depth of text

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self

        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Create a new scene
        let scene = SCNScene()
        
        // Set the scene to the view
        sceneView.scene = scene
        sceneView.autoenablesDefaultLighting = true

        // Tap Gesture Recognizer
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.onTappedOnScreen(gestureRecognizer:)))
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc func onTappedOnScreen(gestureRecognizer: UITapGestureRecognizer) {
        // Get screen touch point
        var screenTouchPoint = gestureRecognizer.location(in: gestureRecognizer.view)
        screenTouchPoint = sceneView.convert(screenTouchPoint, to: sceneView)
        
        // Check if getting any object on hitting.
        let arHitTestResults : [ARHitTestResult] = sceneView.hitTest(screenTouchPoint, types: [.featurePoint])
        if let closestResult = arHitTestResults.first {
            // Get Coordinates of HitTest
            let transform : matrix_float4x4 = closestResult.worldTransform
            let worldCoord : SCNVector3 = SCNVector3Make(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
            getPixelBufferOfCurrentImage(worldCoord)
        }
    }
    
    private func getPixelBufferOfCurrentImage(_ worldCoordinate : SCNVector3) {
        //Get pixel buffer from current image in scene view.
        let pixbuff : CVPixelBuffer? = (sceneView.session.currentFrame?.capturedImage)
        guard let pixelBuffer = pixbuff else {
            return
        }
        getPredictionFromImage(pixelBuffer, worldCoordinate: worldCoordinate)
    }
    
    private func getPredictionFromImage(_ pixelBuffer : CVPixelBuffer, worldCoordinate : SCNVector3) {
        //Initialise GoogleNet with pixel buffer
        let input = GoogLeNetPlacesInput.init(sceneImage: pixelBuffer)
        do {
            //Get prediction/object name from pixel buffer.
            if let output = try? model.prediction(input: input) {
                DispatchQueue.main.async {
                    // Create 3D Text with prediction text
                    let node : SCNNode = self.createNewBubbleParentNode(output.sceneLabel)
                    self.sceneView.scene.rootNode.addChildNode(node)
                    node.position = worldCoordinate
                }
            }
        }
    }
    
    private func createNewBubbleParentNode(_ text : String) -> SCNNode {
        // Text billboard constraint
        let billboardConstraint = SCNBillboardConstraint()
        billboardConstraint.freeAxes = SCNBillboardAxis.Y
        
        // 3d Text
        let scnText = SCNText(string: text, extrusionDepth: CGFloat(textDepth))
        let font = UIFont.boldSystemFont(ofSize: 0.15)
        scnText.font = font
        scnText.alignmentMode = kCAAlignmentCenter
        scnText.firstMaterial?.diffuse.contents = UIColor.darkGray
        scnText.firstMaterial?.specular.contents = UIColor.white
        scnText.firstMaterial?.isDoubleSided = true
        scnText.chamferRadius = CGFloat(textDepth)
        
        // Text Node
        let (minBound, maxBound) = scnText.boundingBox
        let textNode = SCNNode(geometry: scnText)
        // Centre Node - to Centre-Bottom point
        textNode.pivot = SCNMatrix4MakeTranslation( (maxBound.x - minBound.x)/2, minBound.y, textDepth/2)
        // Scale default text size
        textNode.scale = SCNVector3Make(0.2, 0.2, 0.2)
        
        // Sphere Node
        let sphere = SCNSphere(radius: 0.005)
        sphere.firstMaterial?.diffuse.contents = UIColor.cyan
        let sphereNode = SCNNode(geometry: sphere)
        
        // Parent Node
        let parentNode = SCNNode()
        parentNode.addChildNode(textNode)
        parentNode.addChildNode(sphereNode)
        parentNode.constraints = [billboardConstraint]
        
        return parentNode
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
}
