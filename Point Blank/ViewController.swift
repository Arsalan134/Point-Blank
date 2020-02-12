//
//  ViewController.swift
//  Point Blank
//
//  Created by Arsalan Iravani on 30.07.16.
//  Copyright © 2016 Arsalan Iravani. All rights reserved.
//

import UIKit
import AVFoundation
import CoreMotion
import LocalAuthentication

class ViewController: UIViewController {
    
    //  Labels
    @IBOutlet weak var killTextField: UITextField!
    @IBOutlet weak var deathTextField: UITextField!
    
    @IBOutlet weak var ratioLabel: UILabel!
    
    //    Buttons
    @IBOutlet weak var killButton: UIButton!
    @IBOutlet weak var deathButton: UIButton!
    
    //    Variables
    var kill = 0
    var death = 0
    var randomNumber = 0
    let format = "%.4f"
    let timeForUpdate = 0.2
    
    //    Sounds
    var deathSound = try? AVAudioPlayer(contentsOf: URL(fileURLWithPath: Bundle.main.path(forResource: "death", ofType: "mp3")!))
    var sounds = [AVAudioPlayer]()
    
    //    Colors
    let gradient = CAGradientLayer()
    let color1 = UIColor(red: 1 , green: 149 / 255.0 , blue: 0, alpha: 1.0).cgColor
    let color2 = UIColor(red: 35.0/255.0, green: 2.0/255.0, blue: 2.0/255.0, alpha: 1.0).cgColor
    
    //    Animation
    var boundries = UICollisionBehavior()
    var bounce = UIDynamicItemBehavior()
    var gravity = UIGravityBehavior()
    var animator = UIDynamicAnimator()
    let direction = CGVector(dx: 0.0, dy: 1.0)
    
    //    Motion
    var movementManager = CMMotionManager()
    let xMotion = UIInterpolatingMotionEffect(keyPath: "center.x", type: .tiltAlongHorizontalAxis)
    let yMotion = UIInterpolatingMotionEffect(keyPath: "center.y", type: .tiltAlongVerticalAxis)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        createGradient()
        
        // Gesture
        let longGesture = UILongPressGestureRecognizer(target: self, action: #selector(ViewController.longTap(_:)))
        view.addGestureRecognizer(longGesture)
        
        // Add Sounds
        for index in 1...4 {
            sounds.append(try! AVAudioPlayer(contentsOf: URL(fileURLWithPath: Bundle.main.path(forResource: String(index), ofType: "mp3")!)))
            sounds[index-1].prepareToPlay()
        }
        
        // Motion
        movementManager.accelerometerUpdateInterval = timeForUpdate
        
        movementManager.startAccelerometerUpdates(to: .main) { (data, error) in
            guard let data = data else { return }
            self.motion(data.acceleration)
        }
        
        ratioLabel.text = "0 %"
        
        gravity.gravityDirection = direction
        
        bounce.elasticity = 0.5 // Usually between 0 (inelastic) and 1 (collide elastically)
        bounce.friction = 0.5 // 0 being no friction between objects slide along each other
        bounce.density = 1.0
        bounce.resistance = 0 // 0: no velocity damping
        bounce.angularResistance = 0 // 0: no angular velocity damping
        
        boundries.translatesReferenceBoundsIntoBoundary = true
        
        animator = UIDynamicAnimator(referenceView: self.view)
        animator.addBehavior(bounce)
        animator.addBehavior(boundries)
        animator.addBehavior(gravity)
        
    }
    
    func motion(_ acceleration: CMAcceleration){
        gravity.gravityDirection = CGVector(dx: CGFloat(acceleration.x), dy: -CGFloat(acceleration.y))
    }
    
    @IBAction func enteredNumber(_ sender: UITextField) {
        if killTextField.text != "" {
            kill = Int(killTextField.text!)!
        }
        if deathTextField.text != "" {
            death = Int(deathTextField.text!)!
        }
        showRatio()
    }
    
    @IBAction func killed(_ sender: UIButton) {
        kill += 1
        killTextField.text = "\(kill)"
        showRatio()
        createBullet(killButton.frame.midX, y: killButton.frame.midY, width: 30, height: 10)
        
        randomNumber = Int(arc4random_uniform(4))
        sounds[randomNumber].play()
        self.view.endEditing(true)
    }
    
    var access = true
    
    @IBAction func dead(_ sender: UIButton) {
        death += 1
        deathTextField.text = "\(death)"
        showRatio()
        deathSound!.play()
        self.view.endEditing(true)
    }
    
    @objc func longTap(_ sender : UIGestureRecognizer){
        if sender.state == .began {
            kill=0
            death=0
            killTextField.text?.removeAll()
            deathTextField.text?.removeAll()
            ratioLabel.text = "0 %"
        }
    }
    
    func showRatio() {
        ratioLabel.text = String(format: format, calculateRatio(kill, death: death)) + " %"
        if ratioLabel.text == "0.00 %" {
            ratioLabel.text = "0 %"
        }
        if ratioLabel.text?.last  == "0" {
            ratioLabel.text = "0 %"
            print("hee")
        }
    }
    
    func calculateRatio(_ kill: Int, death:Int) -> Double {
        return Double(kill) / (Double(kill) + Double(death)) * 100
    }
    
    func createGradient() {
        gradient.frame = self.view.bounds
        gradient.colors = [color1, color2]
        gradient.locations = [0, 1]
        view.layer.addSublayer(gradient)
        view.layer.insertSublayer(gradient, at: 0)
    }
    
    //    Bullet
    class BulletStruct {
        let x: CGFloat
        let y: CGFloat
        let width: CGFloat
        let height: CGFloat
        var bulletImageView: UIImageView
        
        init(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) {
            self.x = x
            self.y = y
            self.width = width
            self.height = height
            bulletImageView = UIImageView(frame: CGRect(x: x, y: y, width: width, height: height))
            bulletImageView.image = UIImage(named: "b2")
        }
        
        deinit {
            print("Bullet \(self) is deinitialized")
        }
        
    }
    
    func createBullet(_ x: CGFloat,y: CGFloat,width: CGFloat,height: CGFloat) {
        var newBullet = UIImageView()
        newBullet = BulletStruct(x: x, y: y, width: width, height: height).bulletImageView
        view.insertSubview(newBullet, at: 1)
        
        gravity.addItem(newBullet)
        boundries.addItem(newBullet)
        bounce.addItem(newBullet)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        killTextField.resignFirstResponder()
        deathTextField.resignFirstResponder()
        self.view.endEditing(true)
    }
}
