//
//  ViewController.swift
//  theyCallMeSIGABRT
//
//  Created by Kevin Pradjinata on 1/15/21.
//

import UIKit
import Speech
import CorePlot
import SceneKit
import ARKit    

class ViewController: UIViewController, SFSpeechRecognizerDelegate, ARSessionDelegate {
    
    @IBOutlet weak var textView: UITextView!
    @IBOutlet var microphoneButton: UIButton!
    @IBOutlet var liveUpdate: UITextView!
    @IBOutlet var eyeContactLabel: UILabel!
    
    
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet var textProcessing: UILabel!
    
    private let screenRecorder = ScreenRecorder()
    private var eyeList = [Double: Double]()
    
    private var times = [Double]()
    private var attentionScores = [Double]()
    private var sTime:Double = 0.0
    private var timer = Timer()
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    
    static var cum: Double = 0.0 // CUMMULATIVE TIME
    static var someCum = [Int]() // WORDCOUNT
    static var dicCum = [Int: Double]() // WORDCOUNT : TIM-ELA
    static var pubicHair = [Double]() // TIME-ELA
    static var assHair = [Double]() // TIME-DIFF
    static var daddy = [Double]() // WPM
    static var isRecording = false
    
    static var elaTime:Double = 0.0
    
    
    
    
    static var count:Double = 0.0
    
    static var sTime = CFAbsoluteTimeGetCurrent()

    var contentControllers: [VirtualContentType: VirtualContentController] = [:]
    
    var selectedVirtualContent: VirtualContentType = VirtualContentType(rawValue: 0)!

    var selectedContentController: VirtualContentController {
        if let controller = contentControllers[selectedVirtualContent] {
            return controller
        }
        else {
            let controller = selectedVirtualContent.makeController()
            contentControllers[selectedVirtualContent] = controller
            return controller
        }

    }
    
    var currentFaceAnchor: ARFaceAnchor?

//    let timer = Timer.scheduledTimer(withTimeInterval: 0.001, repeats: true) { timer in
//        //print("Timer fired!")
//        cum+=1
//       // print(cum)
//
//    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Soojue" { // change
                let destinationVC = segue.destination as! GraphViewController
                destinationVC.wpm = ViewController.daddy
                destinationVC.totTime = ViewController.pubicHair
                destinationVC.hOmO = textView.text
                destinationVC.elaTime = ViewController.elaTime
        }
        
        if segue.identifier == "contactSegue"{
            let destinationVC = segue.destination as! Graph2ViewController
            destinationVC.times = times
            destinationVC.attentionScores = attentionScores
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        microphoneButton.layer.cornerRadius = 40
        microphoneButton.isEnabled = false
        sceneView.delegate = self // error cuz its plugs into old view controller
        sceneView.session.delegate = self
        sceneView.automaticallyUpdatesLighting = true
        speechRecognizer?.delegate = self  //created a question mark here
            
            SFSpeechRecognizer.requestAuthorization { (authStatus) in
                
                var isButtonEnabled = false
                
                switch authStatus {
                case .authorized:
                    isButtonEnabled = true
                    
                case .denied:
                    isButtonEnabled = false
                    print("User denied access to speech recognition")
                    
                case .restricted:
                    isButtonEnabled = false
                    print("Speech recognition restricted on this device")
                    
                case .notDetermined:
                    isButtonEnabled = false
                    print("Speech recognition not yet authorized")
                }
                
                OperationQueue.main.addOperation() {
                    self.microphoneButton.isEnabled = isButtonEnabled
                }
            }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        
        // AR experiences typically involve moving the device without
        // touch input for some time, so prevent auto screen dimming.
        UIApplication.shared.isIdleTimerDisabled = true
        
        // "Reset" to run the AR session for the first time.
        resetTracking()
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        guard error is ARError else { return }
        
        let errorWithInfo = error as NSError
        let messages = [
            errorWithInfo.localizedDescription,
            errorWithInfo.localizedFailureReason,
            errorWithInfo.localizedRecoverySuggestion
        ]
        let errorMessage = messages.compactMap({ $0 }).joined(separator: "\n")
        
        DispatchQueue.main.async {
            self.displayErrorMessage(title: "The AR session failed.", message: errorMessage)
        }
    }
    
    /// - Tag: ARFaceTrackingSetup
    func resetTracking() {
        guard ARFaceTrackingConfiguration.isSupported else { return }
        let configuration = ARFaceTrackingConfiguration()
        configuration.isLightEstimationEnabled = true
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    private func displayTime() {
        if ViewController.someCum.count<10 {
            liveUpdate.text = "WPM: ..."
            print("not working")
        }else{
            print("working")
            let wpm =  (Double(ViewController.someCum.last!)/Double(ViewController.count)*60) + 15.00
            ViewController.daddy.append(wpm)
            liveUpdate.text = String(format: "WPM: %.2f", wpm)
            
            if wpm > 130 && wpm < 170{
                textProcessing.text = "✅: Perfect"
            }
            else if wpm >= 170 {
                textProcessing.text = "🚨: Too FAST!"
            }
            else{
                textProcessing.text = "⚠️: Too Slow!"// too slow
            }
            
            
        }
    }
    
    func displayErrorMessage(title: String, message: String) {
        // Present an alert informing about the error that has occurred.
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let restartAction = UIAlertAction(title: "Restart Session", style: .default) { _ in
            alertController.dismiss(animated: true, completion: nil)
            self.resetTracking()
        }
        alertController.addAction(restartAction)
        present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func processRecord(_ sender: UIButton) {
        if !ViewController.isRecording && !audioEngine.isRunning{
            resetTracking() // new
            sTime = CFAbsoluteTimeGetCurrent()
            timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true, block: {(timer) in
                ViewController.count += timer.timeInterval
                self.displayTime()
                let aSpan = TransformVisualization.attentionSpan
                self.times.append(TransformVisualization.cTime - self.sTime)
                self.attentionScores.append(aSpan)
                if aSpan > 0.1{
                    self.eyeContactLabel.text = "😡"
                }
                else{
                    self.eyeContactLabel.text = "🤩"
                }
                
            })
            
            startRecording()
            microphoneButton.setTitle("", for: .normal)
            screenRecorder.startRecording(saveToCameraRoll: true, errorHandler: { error in
                      print("Error when recording \(error)")
                })
                
        }else{
            audioEngine.stop()
            recognitionRequest?.endAudio()
            microphoneButton.isEnabled = false
            microphoneButton.setTitle("", for: .normal)
            
            screenRecorder.stoprecording(errorHandler: { error in
                print("Error when stop recording \(error)")
            })
            
            ViewController.elaTime = CFAbsoluteTimeGetCurrent() - ViewController.sTime
//            ViewController.pubicHair = [Double]()
            subtract()
//            print(self.eyeList)
            timer.invalidate()
            sceneView.pause(sender)
            print("WC-TIME-ELA: \(ViewController.dicCum)")
            print("CUMM-TIME: \(ViewController.cum)")
            print("WORD COUNT: \(ViewController.someCum)")
            print("TIME-ELA: \(ViewController.pubicHair)")
            print("TIME-DIFF: \(ViewController.assHair)")
            print("WPM: \(ViewController.daddy)")
            }
        }
    
    func subtract() {
        ViewController.pubicHair.append(ViewController.dicCum[ViewController.someCum[1]]!)
        for wordCount in ViewController.someCum {
            let diff = ViewController.dicCum[wordCount]
            ViewController.pubicHair.append(diff!)
        }
        print(ViewController.pubicHair)
        ViewController.pubicHair = Array(Set(ViewController.pubicHair)).sorted()
        print(ViewController.pubicHair)
//
//        for crust in 1...ViewController.pubicHair.count-2{
//            ViewController.assHair.append(ViewController.pubicHair[crust+1]-ViewController.pubicHair[crust])
//        }
//        //print(ViewController.pubicHair)
//        //print(ViewController.assHair)
//        for penis in ViewController.assHair {
//            ViewController.daddy.append(abs(1/(penis/1000)*60))
//        }
//        print(ViewController.daddy)
    
//        return ViewController.daddy
    }
    
//    @IBAction func microphoneTapped(_ sender: AnyObject) {
//        if audioEngine.isRunning {
//                audioEngine.stop()
//                recognitionRequest?.endAudio()
//                microphoneButton.isEnabled = false
//                microphoneButton.setTitle("Start Recording", for: .normal)
//
//            } else {
//                startRecording()
//                microphoneButton.setTitle("Stop Recording", for: .normal)
//            }
//    }
    
//    @IBAction func saveButton(_ sender: Any) {
//        guard let text = textView.text else {return}
//        print(text)
//        subtract()
//        print("WC-TIME-ELA: \(ViewController.dicCum)")
//        print("CUMM-TIME: \(ViewController.cum)")
//        print("WORD COUNT: \(ViewController.someCum)")
//        print("TIME-ELA: \(ViewController.pubicHair)")
//        print("TIME-DIFF: \(ViewController.assHair)")
//        print("WPM: \(ViewController.daddy)")
//
//        //performSegue(withIdentifier: "Soojue", sender: sender)
//
//    }
    
    
    
    func spaceCounter(_ s: String) -> Int{
            let c =  s.components(separatedBy:" ")
            return c.count
    }
    
    func startRecording() {
        
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSession.Category.record)
            try audioSession.setMode(AVAudioSession.Mode.measurement)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("audioSession properties weren't set because of an error.")
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
       let inputNode = audioEngine.inputNode
        
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in //added question mark here
            
            var isFinal = false
            
            if result != nil {
                let cTime = CFAbsoluteTimeGetCurrent()
                ViewController.cum = (cTime - ViewController.sTime) * 1000
                self.textView.text = result?.bestTranscription.formattedString //bestTranscriptiuon is black
                isFinal = (result?.isFinal)!
                if ViewController.someCum.count==0 {
                    ViewController.someCum.append(self.spaceCounter(self.textView.text))
                    ViewController.dicCum[ViewController.someCum.last!] = 0
                }
                else{
                    if let oldText = ViewController.someCum.last {
                        if oldText - self.spaceCounter(self.textView.text) != 0 {
                            ViewController.someCum.append(self.spaceCounter(self.textView.text))
                            ViewController.dicCum[ViewController.someCum.last!] = ViewController.cum
                            //print(ViewController.someCum)
                        }
                    }
                    
                }
                //print(ViewController.someCum)
                //print("Te:\(self.textView.text) T: \(ViewController.cum)")
            }
            
            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                self.microphoneButton.isEnabled = true
            }
        })
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) {(buffer, when) in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            print("audioEngine couldn't start because of an error.")
        }
        textView.text = "Say something, I'm listening!"
    }
    
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            microphoneButton.isEnabled = true
        } else {
            microphoneButton.isEnabled = false
        }
    }
}

extension ViewController: ARSCNViewDelegate {
        
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let faceAnchor = anchor as? ARFaceAnchor else { return }
        currentFaceAnchor = faceAnchor
        
        // If this is the first time with this anchor, get the controller to create content.
        // Otherwise (switching content), will change content when setting `selectedVirtualContent`.
        if node.childNodes.isEmpty, let contentNode = selectedContentController.renderer(renderer, nodeFor: faceAnchor) {
            node.addChildNode(contentNode)
            
        }
    }
    
    /// - Tag: ARFaceGeometryUpdate
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard anchor == currentFaceAnchor,
            let contentNode = selectedContentController.contentNode,
            contentNode.parent == node
            else { return }
        
        selectedContentController.renderer(renderer, didUpdate: contentNode, for: anchor)
    }
}
