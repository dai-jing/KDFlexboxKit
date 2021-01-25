# KDFlexboxKit

[![CI Status](https://img.shields.io/travis/dai-jing/KDFlexboxKit.svg?style=flat)](https://travis-ci.org/dai-jing/KDFlexboxKit)
[![Version](https://img.shields.io/cocoapods/v/KDFlexboxKit.svg?style=flat)](https://cocoapods.org/pods/KDFlexboxKit)
[![License](https://img.shields.io/cocoapods/l/KDFlexboxKit.svg?style=flat)](https://cocoapods.org/pods/KDFlexboxKit)
[![Platform](https://img.shields.io/cocoapods/p/KDFlexboxKit.svg?style=flat)](https://cocoapods.org/pods/KDFlexboxKit)

## Features

- [x] Write UI elements in a declarative way
- [x] Supports user customized FlexView
- [ ] Support aysnc UI Rendering by using Core Text
- [ ] Using diff algorithms to only re-render state changed UI elements

## KDFlexboxKit 101
KDFlexboxKit is a declarative UI framework by using CSS flexbox. You can use a declarative way to declare the UI elements and group them by using CSS flexbox semantics. You can declare a nested UI element just by adding child nodes in the Swift closure. You do not even have to declare the local variables and writing UI codes line by line. You can directly get the view instance and size from the rootNode. Here's some sample codes that you can generate this view:

![img](https://s3.us-west-2.amazonaws.com/secure.notion-static.com/f7b8e3be-404c-4204-85e6-99ceec9902a0/Screen_Shot_2021-01-25_at_3.38.02_PM.png?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAT73L2G45O3KS52Y5%2F20210125%2Fus-west-2%2Fs3%2Faws4_request&X-Amz-Date=20210125T093915Z&X-Amz-Expires=86400&X-Amz-Signature=a3758cb3829f8815921053a4b0541ae0d8176f6ac23878db9248afd8601a234a&X-Amz-SignedHeaders=host&response-content-disposition=filename%20%3D%22Screen_Shot_2021-01-25_at_3.38.02_PM.png%22)

```Swift
/// root node that represents the container view
let rootNode = flexRootNode(closure: {
    $0.flexView.backgroundColor = .white
    /// create a child container that represents a subview of the previous container view
    $0.node(from: FlexView.self, closure: {
        $0.flexConfig.width = UIScreen.main.bounds.width
        /// this node has a row direction in regarding to CSS flexbox
        $0.flexConfig.direction = .row
        /// align the first child node on the left side, and second child node on the right side
        $0.flexConfig.justifyContent = .spaceBetween
        /// make child nodes vertically center align.
        $0.flexConfig.alignItems = .center
        $0.flexConfig.margin = .init(top: 0, left: 15, bottom: 0, right: 0)
        /// left child node - Avatar + Titles View
        $0.node(from: FlexView.self, closure: {
            $0.flexConfig.alignItems = .center
            /// Image View
            $0.node(from: FlexImageView.self, closure: {
                $0.flexConfig.width = 50
                $0.flexConfig.height = 50
                $0.flexView.imageURL = model.avatarImageUrl
                $0.flexView.clipsToBounds = true
                $0.flexView.cornerRadius = 25
                $0.flexView.borderColor = UIColor(colorString: "#EEEEEE")
                $0.flexView.borderWidth = 1
            })
            /// Node that wraps two title nodes
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
        /// right child node - Follow Button
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
            }
            else {
                $0.flexView.backgroundColor = UIColor(colorString: "#F4AA1A")
                $0.flexView.title = "Follow"
            }
            $0.flexView.tapGestureHandler = {
                // button tapped
            }
        })
    })
})

let view = rootNode.view()
let viewSize = rootNode.size()
```

## Customization
You can use built-in FlexNode for UIView, UIImageView, UILabel, UIButton, UITextField
+ `FlexView` is used for `UIView`
+ `FlexImageView` is used for `UIImageView`
+ `FlexLabel` is used for `UILabel`
+ `FlexButton` is used for `UIButton`
+ `FlexTextField` is used for `UITextField`

You can also make your own FlexView simply by subclassing `FlexView`:
```Swift
public class FlexSeparatorLine: FlexView {
    public required init() {
    }

    public override func view(from node: FlexNode) -> UIView {
        let separatorLine = UIView(frame: frame)
        separatorLine.backgroundColor = UIColor(colorString: "#FAFAFA")
        let shadowLayer = CAShapeLayer()
        shadowLayer.frame = separatorLine.bounds
        shadowLayer.shadowColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.05).cgColor
        shadowLayer.shadowOffset = .init(width: 0, height: 1)
        shadowLayer.shadowOpacity = 1
        shadowLayer.fillRule = .evenOdd
        let path = CGMutablePath()
        path.addRect(separatorLine.bounds.insetBy(dx: 0, dy: -42))
        let innerPath = UIBezierPath.init(rect: separatorLine.bounds).cgPath
        path.addPath(innerPath)
        path.closeSubpath()
        shadowLayer.path = path
        separatorLine.layer.addSublayer(shadowLayer)
        let maskLayer = CAShapeLayer()
        maskLayer.path = innerPath
        shadowLayer.mask = maskLayer
        return separatorLine
    }
}
```

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

## Installation

KDFlexboxKit is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'KDFlexboxKit'
```

## Author

dai-jing, kobedai24@gmail.com

## License

KDFlexboxKit is available under the MIT license. See the LICENSE file for more info.
