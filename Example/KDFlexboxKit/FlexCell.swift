//
//  FlexCell.swift
//  KDFlexboxKit_Example
//
//  Created by Kobe Dai on 2021/1/25.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import UIKit
import KDFlexboxKit

class FlexCell: UICollectionViewCell {
    
    func setCell(with model: FlexCellModel) {
        var node = FlexCell.rootNode(model)
        
        if let rootView = contentView.viewWithTag(1000) {
            for subview in rootView.subviews {
                subview.removeFromSuperview()
            }
            rootView.addSubview(node.view())
        } else {
            let rootView = node.view()
            rootView.tag = 1000
            contentView.addSubview(rootView)
        }
    }
    
    static func cellSize(with model: FlexCellModel) -> CGSize {
        var node = FlexCell.rootNode(model)
        
        return node.size()
    }
    
    static func rootNode(_ model: FlexCellModel) -> FlexNode {
        let rootNode = flexRootNode(closure: {
            $0.flexView.backgroundColor = .white
            $0.node(from: FlexView.self, closure: {
                $0.flexConfig.width = UIScreen.main.bounds.width
                $0.flexConfig.direction = .row
                $0.flexConfig.justifyContent = .spaceBetween
                $0.flexConfig.alignItems = .center
                $0.flexConfig.margin = .init(top: 0, left: 15, bottom: 0, right: 0)
                
                $0.node(from: FlexView.self, closure: {
                    $0.flexConfig.alignItems = .center
                    $0.node(from: FlexImageView.self, closure: {
                        $0.flexConfig.width = 50
                        $0.flexConfig.height = 50
                        $0.flexView.imageURL = model.avatarImageUrl
                        $0.flexView.clipsToBounds = true
                        $0.flexView.cornerRadius = 25
                        $0.flexView.borderColor = UIColor(colorString: "#EEEEEE")
                        $0.flexView.borderWidth = 1
                    })
                    $0.node(from: FlexView.self, closure: {
                        $0.flexConfig.direction = .column
                        $0.flexConfig.margin = .init(top: 0, left: 10, bottom: 0, right: 0)
                        $0.node(from: FlexView.self, closure: {
                            $0.flexConfig.alignItems = .center
                            $0.node(from: FlexLabel.self, closure: {
                                $0.flexView.text = model.nickname
                                $0.flexView.textColor = UIColor(colorString: "#333333")
                                $0.flexView.font = .systemFont(ofSize: 14)
                            })
                        })
                        if let desc = model.desc, desc.count > 0 {
                            $0.node(from: FlexLabel.self, closure: {
                                $0.flexConfig.margin = .init(top: 6, left: 0, bottom: 0, right: 0)
                                $0.flexView.text = desc
                                $0.flexView.textColor = UIColor(colorString: "#888888")
                                $0.flexView.font = .systemFont(ofSize: 10)
                            })
                        }
                    })
                })
                
                $0.node(from: FlexButton.self, closure: {
                    $0.flexConfig.margin = .init(top: 0, left: 0, bottom: 0, right: 15)
                    $0.flexConfig.width = 70
                    $0.flexConfig.height = 30
                    $0.flexView.tag = 5
                    $0.flexView.font = .systemFont(ofSize: 12, weight: .medium)
                    $0.flexView.titleColor = .white
                    $0.flexView.cornerRadius = 15
                    if model.isFollowing == true {
                        $0.flexView.backgroundColor = UIColor(colorString: "#CCCCCC")
                        $0.flexView.title = "Followed"
                    } else {
                        $0.flexView.backgroundColor = UIColor(colorString: "#F4AA1A")
                        $0.flexView.title = "Follow"
                    }
                    $0.flexView.tapGestureHandler = {
                        // button tapped
                    }
                })
            })
        })
        
        return rootNode
    }
}

struct FlexCellModel {
    var avatarImageUrl: String?
    var nickname: String?
    var desc: String?
    var isFollowing: Bool?
}





/// UIColor extensions

extension UIColor {
    /**
     The shorthand three-digit hexadecimal representation of color.
     #RGB defines to the color #RRGGBB.
     
     - parameter hex3: Three-digit hexadecimal value.
     - parameter alpha: 0.0 - 1.0. The default is 1.0.
     */
    convenience init(hex3: UInt16, alpha: CGFloat = 1) {
        let divisor = CGFloat(15)
        let red     = CGFloat((hex3 & 0xF00) >> 8) / divisor
        let green   = CGFloat((hex3 & 0x0F0) >> 4) / divisor
        let blue    = CGFloat( hex3 & 0x00F      ) / divisor
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
    
    /**
     The shorthand four-digit hexadecimal representation of color with alpha.
     #RGBA defines to the color #RRGGBBAA.
     
     - parameter hex4: Four-digit hexadecimal value.
     */
    convenience init(hex4: UInt16) {
        let divisor = CGFloat(15)
        let red     = CGFloat((hex4 & 0xF000) >> 12) / divisor
        let green   = CGFloat((hex4 & 0x0F00) >>  8) / divisor
        let blue    = CGFloat((hex4 & 0x00F0) >>  4) / divisor
        let alpha   = CGFloat( hex4 & 0x000F       ) / divisor
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
    
    /**
     The six-digit hexadecimal representation of color of the form #RRGGBB.
     
     - parameter hex6: Six-digit hexadecimal value.
     */
    convenience init(hex6: UInt32, alpha: CGFloat = 1) {
        let divisor = CGFloat(255)
        let red     = CGFloat((hex6 & 0xFF0000) >> 16) / divisor
        let green   = CGFloat((hex6 & 0x00FF00) >>  8) / divisor
        let blue    = CGFloat( hex6 & 0x0000FF       ) / divisor
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
    
    /**
     The six-digit hexadecimal representation of color with alpha of the form #RRGGBBAA.
     
     - parameter hex8: Eight-digit hexadecimal value.
     */
    convenience init(hex8: UInt32) {
        let divisor = CGFloat(255)
        let red     = CGFloat((hex8 & 0xFF000000) >> 24) / divisor
        let green   = CGFloat((hex8 & 0x00FF0000) >> 16) / divisor
        let blue    = CGFloat((hex8 & 0x0000FF00) >>  8) / divisor
        let alpha   = CGFloat( hex8 & 0x000000FF       ) / divisor
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
    
    /**
     The rgba string representation of color with alpha of the form #RRGGBBAA/#RRGGBB, throws error.
     
     - parameter rgba: String value.
     */
    convenience init(colorString rgba: String) {
        guard rgba.hasPrefix("#") else {
            let error = UIColorInputError.missingHashMarkAsPrefix(rgba)
            print(error.localizedDescription)
            self.init(hex8: 0x000000)
            return
        }
        
        let hexString: String = String(rgba[String.Index(utf16Offset: 1, in: rgba)...])
        var hexValue:  UInt32 = 0
        
        guard Scanner(string: hexString).scanHexInt32(&hexValue) else {
            let error = UIColorInputError.unableToScanHexValue(rgba)
            print(error.localizedDescription)
            self.init(hex8: 0x000000)
            return
        }
        
        switch (hexString.count) {
        case 3:
            self.init(hex3: UInt16(hexValue))
        case 4:
            self.init(hex4: UInt16(hexValue))
        case 6:
            self.init(hex6: hexValue)
        case 8:
            self.init(hex8: hexValue)
        default:
            let error = UIColorInputError.mismatchedHexStringLength(rgba)
            print(error.localizedDescription)
            self.init(hex8: 0x000000)
        }
    }
}

public enum UIColorInputError: Error {
    
    case missingHashMarkAsPrefix(String)
    case unableToScanHexValue(String)
    case mismatchedHexStringLength(String)
    case unableToOutputHexStringForWideDisplayColor
}

extension UIColorInputError: LocalizedError {
    
    public var errorDescription: String? {
        switch self {
        case .missingHashMarkAsPrefix(let hex):
            return "Invalid RGB string, missing '#' as prefix in \(hex)"
            
        case .unableToScanHexValue(let hex):
            return "Scan \(hex) error"
            
        case .mismatchedHexStringLength(let hex):
            return "Invalid RGB string from \(hex), number of characters after '#' should be either 3, 4, 6 or 8"
            
        case .unableToOutputHexStringForWideDisplayColor:
            return "Unable to output hex string for wide display color"
        }
    }
}
