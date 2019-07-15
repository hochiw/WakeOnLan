//
//  ViewController.swift
//  WakeOnLan
//
//  Created by Hochiw on 15/7/2019.
//  Copyright © 2019 Hochiw. All rights reserved.
//
//  Partial code are reproduction from https://github.com/jesper-lindberg/Awake 
//  temporary AppIcon taken from https://play.google.com/store/apps/details?id=co.uk.mrwebb.wakeonlan&hl=en_US

import UIKit

extension String: Error {}

enum errs: Error {
    case SocketSetupFailed(rsn: String)
    case SetSocketOptionsFailed(rsn: String)
    case SendMagicPacketFailed(rsn: String)
}

class ViewController: UIViewController, UITextFieldDelegate {
    // Properties
    
    
    @IBOutlet weak var macTextField: UITextField!
    @IBOutlet weak var broadTextField: UITextField!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        macTextField.delegate = self
        broadTextField.delegate = self
        
        macTextField.text = UserDefaults.standard.string(forKey: "mac") ?? ""
        broadTextField.text = UserDefaults.standard.string(forKey: "ip") ?? ""
    }
    func parse16<T: StringProtocol>(string: T) throws -> UInt8 {
        guard let value: UInt8 = UInt8(string, radix: 16) else { throw "parsing \(string) with 16 radix" }
        return value
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder();
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if (textField == macTextField) {
            macTextField.text = textField.text
            UserDefaults.standard.set(macTextField.text, forKey: "mac")
        } else if (textField == broadTextField) {
            broadTextField.text = textField.text;
            UserDefaults.standard.set(broadTextField.text, forKey: "ip")
        }
    }
    
    func createMagicPacket(mac: String) -> [CUnsignedChar] {
        var buffer = [CUnsignedChar]()
        
        // Create header
        for _ in 1...6 {
            buffer.append(0xFF)
        }
        
        let components = mac.components(separatedBy: "-")
        let numbers = components.map {
            return strtoul($0, nil, 16)
        }
        
        // Repeat MAC address 16 times
        for _ in 1...16 {
            for number in numbers {
                buffer.append(CUnsignedChar(number))
            }
        }
        
        return buffer
    }
    
    func wake(ip: String, mac: String, port: UInt16) {
        
        var sock: Int32
        var target = sockaddr_in()
        
        target.sin_family = sa_family_t(AF_INET)
        target.sin_addr.s_addr = inet_addr(ip)
        
        let isLittleEndian = Int(OSHostByteOrder()) == OSLittleEndian
        target.sin_port = isLittleEndian ? _OSSwapInt16(port) : port
        
        sock = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)
        if sock < 0 {
            return
        }
        
        let packet = createMagicPacket(mac: mac)
        let sockaddrLen = socklen_t(MemoryLayout<sockaddr>.stride)
        let intLen = socklen_t(MemoryLayout<Int>.stride)
        
        var bc = 1
        if setsockopt(sock,SOL_SOCKET, SO_BROADCAST, &bc, intLen) == 1  {
            close(sock)
            return
        }
        
        var t = unsafeBitCast(target, to: sockaddr.self)
        if sendto(sock,packet,packet.count,0,&t,sockaddrLen) != packet.count {
            close(sock)
            return
        }
        
        close(sock)
        
        return
    }
    
    // Action
    @IBAction func wakeBtn(_ sender: UIButton) {
        
        if (!(macTextField.text ?? "").isEmpty && !(broadTextField.text ?? "").isEmpty) {
            let ip = broadTextField.text!
            let mac = macTextField.text!
            let port: UInt16 = 9
            
            wake(ip: ip,mac: mac,port: port)
        }
        
        
        
    }
    
}

