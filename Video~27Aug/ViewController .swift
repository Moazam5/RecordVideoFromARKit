//
//  ViewController.swift
//  Video~27Aug
//
//  Created by Mir Moazam Abass on 8/27/19.
//  Copyright © 2019 Mir Moazam Abass. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import AVFoundation

class ViewController: UIViewController, ARSCNViewDelegate , ARSessionDelegate{

    @IBOutlet var sceneView: ARSCNView!
    
    var rendererSettings = RendererSettings()
    
    var videoWriter: AVAssetWriter?
    var videoWriterInput: AVAssetWriterInput?
    var pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor?     //Dont know what a pixelBufferAdaptor is???
    var isReadyForData: Bool? {
        return videoWriterInput?.isReadyForMoreMediaData ?? false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        sceneView.delegate = self
        sceneView.session.delegate = self //set as session view delegate
        sceneView.showsStatistics = true
      
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let configuration = ARFaceTrackingConfiguration()
        sceneView.session.run(configuration)
    }
    
    func session(_ session: ARSession, didUpdate frame: ARFrame)
    {
        //Step 1 : get the CVPixelBuffer
        
        var newBuffer =   frame.capturedImage
   
  
        // Add the buffers to the pixelBufferAdaptor here

        if isRecord{
            let timeDifference = (( frame.timestamp - startButtonTime!) )
            print(timeDifference)
            
            if videoWriterInput?.isReadyForMoreMediaData == true{
                
                let cmTime = (CMTimeMake(value: Int64(timeDifference * 600), timescale: 600))
               // print(cmTime.value)
                addBuffer(pixelBuffer: newBuffer, withPresentationTime: cmTime)
            }

        }
    }
    
    
    func start() {
        // Create output settings as a dictonary
        let avOutputSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: 1080,// NSNumber(value: Float(rendererSettings.width)),
            AVVideoHeightKey: 720//NSNumber(value: Float(rendererSettings.height))
        ]
        
        // Function to create pixel buffer adaptor
        func createPixelBufferAdaptor() {
            let sourcePixelBufferAttributesDictionary = [
                kCVPixelBufferPixelFormatTypeKey as String: NSNumber(value: kCVPixelFormatType_32ARGB),
                kCVPixelBufferWidthKey as String: NSNumber(value: Float(rendererSettings.width)),
                kCVPixelBufferHeightKey as String: NSNumber(value: Float(rendererSettings.height))
            ]
            pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: videoWriterInput!,  //force unwrapping here
                                                                      sourcePixelBufferAttributes: sourcePixelBufferAttributesDictionary)
            print("Successfully created pixel buffer adaptor")
        }
        
        // Function to create AssetWriter
        func createAssetWriter(outputURL: URL) -> AVAssetWriter {
            guard let assetWriter = try? AVAssetWriter(outputURL: outputURL, fileType: .mov) //AVFileType.mp4)
                else {    fatalError("AVAssetWriter() failed") }
           // print("Created the asset writer")

            guard assetWriter.canApply(outputSettings: avOutputSettings, forMediaType: AVMediaType.video) else {
                fatalError("canApplyOutputSettings() failed")
            }
            
            return assetWriter
        }
        
        videoWriter = createAssetWriter(outputURL: rendererSettings.outputURL)         //create AssetWriter
//create input settings
        videoWriterInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: avOutputSettings)
        videoWriterInput?.expectsMediaDataInRealTime = true
        //add input settings
        if videoWriter!.canAdd(videoWriterInput!) {
            videoWriter!.add(videoWriterInput!)    //force unwrapping here , 4 times
            print("Successfully added the input")
        }
        else {
            fatalError("canAddInput() returned false")
        }
        
        // The pixel buffer adaptor must be created before we start writing.
        createPixelBufferAdaptor()

        //dont know how precondition works   -- Look into this
    //  precondition(pixelBufferAdaptor!.pixelBufferPool != nil, "nil pixelBufferPool")  //force unwrapping here
    }
   
    //Feed the buffers to this function
    func addBuffer(pixelBuffer: CVPixelBuffer, withPresentationTime presentationTime: CMTime) -> Bool {
        
        precondition(pixelBufferAdaptor != nil, "Call start() to initialze the writer")
        
      //  let pixelBuffer = VideoWriter.pixelBufferFromImage(image: image, pixelBufferPool: pixelBufferAdaptor.pixelBufferPool!, size: rendererSettings.size)
      //  guard let pxlBufferAdaptor = pixelBufferAdaptor else{return false}
        return pixelBufferAdaptor!.append(pixelBuffer, withPresentationTime: presentationTime)
        
        
    }
    
    //Removes the file if it already exists
    func removeFileAtURL(fileURL: URL) {
        do {
            try FileManager.default.removeItem(atPath: fileURL.path)
        }
        catch _ as NSError {
            // Assume file doesn't exist.
        }
    }
    
    
    
    var startButtonTime : Double?
    var isRecord : Bool = false
    
//Start button - Starts video recording
    @IBAction func button(_ sender: Any)
    {
        startButtonTime = sceneView.session.currentFrame?.timestamp
        removeFileAtURL(fileURL: rendererSettings.outputURL)
       
        start()
        if videoWriter!.startWriting() == false {  //force unwrapping here
            fatalError("startWriting() failed")
        }
        else {
            print("Started writing")
        }
        videoWriter!.startSession(atSourceTime: CMTime.zero)   //force unwrapping here
        
        isRecord = true

    }
    //Stops video Recording
    @IBAction func stopButton(_ sender: Any)
    {
        isRecord = false

        self.videoWriterInput!.markAsFinished()
        self.videoWriter!.finishWriting
            {
                print("Successfullt stopped the recording")

            }
    }
}

struct  RendererSettings {
    var width: CGFloat = 1080
    var height: CGFloat = 720
    var fps: Int32 = 30   // 30 frames per second
    var avCodecKey = AVVideoCodecType.h264
    var videoFilename = "Nine"
    var videoFilenameExt = "mp4"
    
    var size: CGSize {
        return CGSize(width: width, height: height)
    }
    
    var outputURL: URL {
 
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dataPath = documentsDirectory.appendingPathComponent(videoFilename).appendingPathExtension(videoFilenameExt)
        
        return dataPath
       // fatalError("URLForDirectory() failed")
    }
    
  
    

}
