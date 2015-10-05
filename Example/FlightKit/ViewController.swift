//
//  ViewController.swift
//  FlightKit
//
//  Created by Nikolay Derkach on 08/06/2015.
//  Copyright (c) 2015 Nikolay Derkach. All rights reserved.
//

import UIKit
import FlightKit

class ViewController: UIViewController {
    
    @IBOutlet weak var innerView: UIView!
    var nextVc: UIViewController!
    
    func pushMain() {
        self.navigationController?.presentViewController(nextVc, animated: true, completion: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let nextStoryBoard = FlightKit.storyboard();
        nextVc = nextStoryBoard!.instantiateInitialViewController()
        
//        FlightKit.initView("SFO", to: "LAX", label:"Fly to San Francisco", sview:self.innerView);
    }
    
    override func viewDidAppear(animated: Bool) {
        pushMain()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func pushed(sender: AnyObject) {
        
        pushMain()

    }
}

