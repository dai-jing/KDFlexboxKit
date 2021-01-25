//
//  KDFlexboxKit.swift
//
//  Copyright (c) 2020 Kobe Dai
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import yoga
import Kingfisher

public struct FlexConfig {
    
    public enum Position {
        case relative, absolute
    }
    
    public enum FlexDirection {
        case row, column
    }
    
    public enum FlexWrap {
        case nowrap, wrap
    }
    
    public enum JustifyContent {
        case flexStart, flexEnd, center, spaceBetween, spaceAround, spaceEvenly
    }
    
    public enum AlignItems {
        case flexDefault, flexStart, flexEnd, center
    }
    
    public var position: Position = .relative
    public var direction: FlexDirection = .row
    public var wrap: FlexWrap = .nowrap
    public var padding: UIEdgeInsets = UIEdgeInsets.zero
    public var margin: UIEdgeInsets = UIEdgeInsets.zero
    public var left: CGFloat?
    public var right: CGFloat?
    public var top: CGFloat?
    public var bottom: CGFloat?
    public var rowSpacing: CGFloat = 0
    public var columnSpacing: CGFloat = 0
    public var width: CGFloat = 0
    public var minWidth: CGFloat = 0
    public var maxWidth: CGFloat = 0
    public var height: CGFloat = 0
    public var minHeight: CGFloat = 0
    public var maxHeight: CGFloat = 0
    public var justifyContent: JustifyContent = .flexStart
    public var alignItems: AlignItems = .flexDefault
}

/// Create root node of a flexbox layout
///
/// - Parameter closure: closure that describe the FlexNode instance
/// - Returns: root FlexNode instance
public func flexRootNode(closure: (inout FlexNode) -> Void) -> FlexNode {
    var flexNode = FlexNode()
    flexNode.isRoot = true
    
    closure(&flexNode)
    flexNode.install()
    
    return flexNode
}

/// Node that enables UIKit instances layout with flexbox
public struct FlexNode {
    public static var shared: FlexNode = FlexNode()
    
    /// flex config to describe the frame of the node
    public var flexConfig: FlexConfig = FlexConfig()
    /// flex view that describes UIView attributes
    public var flexView: FlexView = FlexView()
    /// indicate whether this flexNode is root. default is false
    public var isRoot: Bool = false
    /// input for placeholder image
    public var placeholder: UIImage?
    
    var yogaNode: YGNodeRef
    var children: Array<FlexNode> = []
    var nodeSize: CGSize = CGSize.zero
    
    public init() {
        let yogaConfig = YGConfigNew()
        YGConfigSetExperimentalFeatureEnabled(yogaConfig, YGExperimentalFeature.webFlexBasis, true)
        YGConfigSetPointScaleFactor(yogaConfig, Float(UIScreen.main.scale))
        
        self.yogaNode = YGNodeNewWithConfig(yogaConfig)
        self.isRoot = false
    }
    
    /// Create a node with a specific FlexView type (subclass of FlexView)
    ///
    /// - Parameters:
    ///   - flexViewType: Subclass of FlexView (e.g. FlexLabel.self)
    ///   - closure: closure that describes the FlexWrapper instance `$0`. Using `$0.flexConfig` to setup flexConfig instance, `$0.flexView` to setup flexView instance
    /// - Returns: FlexNode instance
    @discardableResult public mutating func node<T>(from flexViewType: T.Type, closure: (inout FlexWrapper<T>) -> Void) -> FlexNode where T : FlexView {
        var flexWrapper = FlexWrapper(flexView: T())
        
        closure(&flexWrapper)
        
        let flexNode = flexWrapper.node()
        flexNode.install()
        children.append(flexNode)
        
        return flexNode
    }
    
    /// Calculate size of the flex layout
    ///
    /// - Returns: CGSize of the root node
    public mutating func size() -> CGSize {
        assert(isRoot, "This function can be used only on root flexNode")
        
        if nodeSize == CGSize.zero {
            insert(childNode: self)
            if flexView.frame.size == CGSize.zero {
                YGNodeCalculateLayout(yogaNode, YGValueUndefined.value, YGValueUndefined.value, YGNodeStyleGetDirection(yogaNode));
            } else {
                YGNodeCalculateLayout(yogaNode, Float(flexView.frame.size.width), Float(flexView.frame.size.height), YGNodeStyleGetDirection(yogaNode));
            }
            layout(childNode: self)
        }
        
        let nodeWidth = YGNodeLayoutGetWidth(yogaNode)
        let nodeHeight = YGNodeLayoutGetHeight(yogaNode)
        
        nodeSize = CGSize(width: CGFloat(nodeWidth), height: CGFloat(nodeHeight))
        
        return nodeSize
    }
    
    /// Render view of the flex layout
    ///
    /// - Returns: UIView of the root node
    public mutating func view() -> UIView {
        assert(isRoot, "This function can be used only on root flexNode")
        
        if nodeSize == CGSize.zero {
            insert(childNode: self)
            if flexView.frame.size == CGSize.zero {
                YGNodeCalculateLayout(yogaNode, YGValueUndefined.value, YGValueUndefined.value, YGNodeStyleGetDirection(yogaNode));
            } else {
                YGNodeCalculateLayout(yogaNode, Float(flexView.frame.size.width), Float(flexView.frame.size.height), YGNodeStyleGetDirection(yogaNode));
            }
            layout(childNode: self)
            
            let width = YGNodeLayoutGetWidth(yogaNode)
            let height = YGNodeLayoutGetHeight(yogaNode)
            
            nodeSize = CGSize(width: CGFloat(width), height: CGFloat(height))
        }
        
        let rootView = flexView.view(from: self)
        render(childNode: self, rootView: rootView, parentView: nil)
        
        return rootView
    }
    
    /// Return the view associate with the tag assigned in the FlexNode instance
    ///
    /// - Parameter tag: tag associated with the FlexNode
    /// - Returns: an instance of UIView
    public mutating func subview(from rootView: UIView?, with tag: Int) -> UIView? {
        if let view = rootView {
            if tag > 0 {
                return view.viewWithTag(tag)
            }
        }
        return nil
    }
    
    /// FlexNode wrapper which used for closure
    public struct FlexWrapper<T> where T : FlexView {
        public var flexView: T
        public var flexConfig: FlexConfig {
            get {
                return flexNode.flexConfig
            }
            set {
                flexNode.flexConfig = newValue
            }
        }
        
        private var flexNode: FlexNode
        
        init(flexView: T) {
            self.flexView = flexView
            self.flexNode = FlexNode()
        }
        
        /// Create a new child node with a specific FlexView type (subclass of FlexView)
        ///
        /// - Parameters:
        ///   - flexViewType: Subclass of FlexView (e.g. FlexLabel.self)
        ///   - closure: closure that describes the FlexWrapper instance `$0`. Using `$0.flexConfig` to setup flexConfig instance, `$0.flexView` to setup flexView instance
        /// - Returns: FlexNode instance
        @discardableResult public mutating func node<T>(from flexViewType: T.Type, closure: (inout FlexWrapper<T>) -> Void) -> FlexNode where T : FlexView {
            return flexNode.node(from: flexViewType, closure: closure)
        }
        
        func node() -> FlexNode {
            var node = flexNode
            node.flexView = flexView
            
            return node
        }
    }
    
    // MARK: Private Methods
    
    /// Setup the node with config
    func install() {
        YGNodeSetContext(yogaNode, Unmanaged<FlexView>.passRetained(flexView).toOpaque())
        
        switch flexConfig.position {
        case .relative:
            YGNodeStyleSetPositionType(yogaNode, YGPositionType.relative)
            if flexConfig.padding != UIEdgeInsets.zero {
                YGNodeStyleSetPadding(yogaNode, YGEdge.left, Float(flexConfig.padding.left));
                YGNodeStyleSetPadding(yogaNode, YGEdge.top, Float(flexConfig.padding.top));
                YGNodeStyleSetPadding(yogaNode, YGEdge.right, Float(flexConfig.padding.right));
                YGNodeStyleSetPadding(yogaNode, YGEdge.bottom, Float(flexConfig.padding.bottom));
            }
            if flexConfig.margin != UIEdgeInsets.zero {
                YGNodeStyleSetMargin(yogaNode, YGEdge.left, Float(flexConfig.margin.left));
                YGNodeStyleSetMargin(yogaNode, YGEdge.top, Float(flexConfig.margin.top));
                YGNodeStyleSetMargin(yogaNode, YGEdge.right, Float(flexConfig.margin.right));
                YGNodeStyleSetMargin(yogaNode, YGEdge.bottom, Float(flexConfig.margin.bottom));
            }
            break
        case .absolute:
            YGNodeStyleSetPositionType(yogaNode, YGPositionType.absolute)
            if let left = flexConfig.left {
                YGNodeStyleSetPosition(yogaNode, YGEdge.left, Float(left))
            }
            if let right = flexConfig.right {
                YGNodeStyleSetPosition(yogaNode, YGEdge.right, Float(right))
            }
            if let top = flexConfig.top {
                YGNodeStyleSetPosition(yogaNode, YGEdge.top, Float(top))
            }
            if let bottom = flexConfig.bottom {
                YGNodeStyleSetPosition(yogaNode, YGEdge.bottom, Float(bottom))
            }
            break
        }
        
        switch flexConfig.direction {
        case .row:
            YGNodeStyleSetFlexDirection(yogaNode, YGFlexDirection.row)
            break
        case .column:
            YGNodeStyleSetFlexDirection(yogaNode, YGFlexDirection.column)
            break
        }
        
        switch flexConfig.wrap {
        case .wrap:
            YGNodeStyleSetFlexWrap(yogaNode, YGWrap.wrap)
            break
        case .nowrap:
            YGNodeStyleSetFlexWrap(yogaNode, YGWrap.noWrap)
            break
        }
        
        if flexConfig.width > 0 {
            YGNodeStyleSetWidth(yogaNode, Float(flexConfig.width))
        }
        if flexConfig.minWidth > 0 {
            YGNodeStyleSetMinWidth(yogaNode, Float(flexConfig.minWidth))
        }
        if flexConfig.maxWidth > 0 {
            YGNodeStyleSetMaxWidth(yogaNode, Float(flexConfig.maxWidth))
        }
        
        if flexConfig.height > 0 {
            YGNodeStyleSetHeight(yogaNode, Float(flexConfig.height))
        }
        if flexConfig.minHeight > 0 {
            YGNodeStyleSetMinHeight(yogaNode, Float(flexConfig.minHeight))
        }
        if flexConfig.maxHeight > 0 {
            YGNodeStyleSetMaxHeight(yogaNode, Float(flexConfig.maxHeight))
        }
        
        switch flexConfig.justifyContent {
        case .flexStart:
            YGNodeStyleSetJustifyContent(yogaNode, YGJustify.flexStart)
            break
        case .flexEnd:
            YGNodeStyleSetJustifyContent(yogaNode, YGJustify.flexEnd)
            break
        case .center:
            YGNodeStyleSetJustifyContent(yogaNode, YGJustify.center)
            break
        case .spaceAround:
            YGNodeStyleSetJustifyContent(yogaNode, YGJustify.spaceAround)
            break
        case .spaceEvenly:
            YGNodeStyleSetJustifyContent(yogaNode, YGJustify.spaceEvenly)
            break
        case .spaceBetween:
            YGNodeStyleSetJustifyContent(yogaNode, YGJustify.spaceBetween)
            break
        }
        
        switch flexConfig.alignItems {
        case .flexStart:
            YGNodeStyleSetAlignItems(yogaNode, YGAlign.flexStart)
            break
        case .flexEnd:
            YGNodeStyleSetAlignItems(yogaNode, YGAlign.flexEnd)
            break
        case .center:
            YGNodeStyleSetAlignItems(yogaNode, YGAlign.center)
            break
        default:
            break
        }
        
        YGNodeStyleSetFlexShrink(yogaNode, 0);
    }
    
    /// Insert child flex node recursively
    ///
    /// - Parameter childNode: flex node
    func insert(childNode: FlexNode) {
        if childNode.children.count == 0 {
            while YGNodeGetChildCount(childNode.yogaNode) > 0 {
                YGNodeRemoveChild(childNode.yogaNode, YGNodeGetChild(childNode.yogaNode, YGNodeGetChildCount(childNode.yogaNode) - 1));
            }
            
            YGNodeSetMeasureFunc(childNode.yogaNode) { (node, width, widthMode, height, heightMode) -> YGSize in
                var nodeWidth = width;
                var nodeHeight = height;
                if widthMode == YGMeasureMode.undefined {
                    nodeWidth = Float(CGFloat.greatestFiniteMagnitude)
                }
                if heightMode == YGMeasureMode.undefined {
                    nodeHeight = Float(CGFloat.greatestFiniteMagnitude)
                }
                // https://www.jianshu.com/p/23b44cd76ce6
                let view = Unmanaged<FlexView>.fromOpaque(YGNodeGetContext(node)).takeUnretainedValue()
                
                var sizeThatFits = CGSize.zero
                if let flexLabel = view as? FlexLabel {
                    let label = UILabel()
                    if flexLabel.attributedText != nil {
                        label.attributedText = flexLabel.attributedText
                    } else {
                        label.text = flexLabel.text
                        label.font = flexLabel.font
                    }
                    label.numberOfLines = flexLabel.numberOfLines
                    
                    sizeThatFits = label.sizeThatFits(CGSize(width: Double(width), height: Double(height)))
                    if flexLabel.extraWidth > 0 {
                        sizeThatFits = .init(width: sizeThatFits.width+flexLabel.extraWidth, height: sizeThatFits.height)
                    }
                } else if let flexButton = view as? FlexButton {
                    let button = UIButton()
                    button.setTitle(flexButton.title, for: .normal)
                    button.titleLabel?.font = flexButton.font
                    if let image = flexButton.image {
                        button.setImage(image, for: .normal)
                    }
                    
                    sizeThatFits = button.sizeThatFits(CGSize(width: Double(width), height: Double(height)))
                }
                var size = CGSize.zero

                switch widthMode {
                case .exactly:
                    size.width = CGFloat(nodeWidth)
                    break
                case .atMost:
                    size.width = min(CGFloat(nodeWidth), sizeThatFits.width)
                    break
                case .undefined:
                    size.width = sizeThatFits.width
                    break
                default:
                    break
                }

                switch heightMode {
                case .exactly:
                    size.height = CGFloat(nodeHeight)
                    break
                case .atMost:
                    size.height = min(CGFloat(nodeHeight), sizeThatFits.height)
                    break
                case .undefined:
                    size.height = sizeThatFits.height
                    break
                default:
                    break
                }
                
                return YGSize(width: Float(size.width), height: Float(size.height))
            }
        } else {
            YGNodeSetMeasureFunc(childNode.yogaNode, nil);
            
            while YGNodeGetChildCount(childNode.yogaNode) > 0 {
                YGNodeRemoveChild(childNode.yogaNode, YGNodeGetChild(childNode.yogaNode, YGNodeGetChildCount(childNode.yogaNode) - 1));
            }
            for index in 0...childNode.children.count-1 {
                let child = childNode.children[index]
                if childNode.flexConfig.rowSpacing > 0 {
                    YGNodeStyleSetMargin(child.yogaNode, YGEdge.vertical, Float(childNode.flexConfig.rowSpacing/2.0))
                }
                if childNode.flexConfig.columnSpacing > 0 {
                    YGNodeStyleSetMargin(child.yogaNode, YGEdge.horizontal, Float(childNode.flexConfig.columnSpacing/2.0))
                }
                YGNodeInsertChild(childNode.yogaNode, child.yogaNode, UInt32(index));
            }
            for child in childNode.children {
                insert(childNode: child)
            }
        }
    }
    
    /// Calculate frame from flexView instance recursively
    ///
    /// - Parameter childNode: flex node
    func layout(childNode: FlexNode) {
        let top = YGNodeLayoutGetTop(childNode.yogaNode)
        let left = YGNodeLayoutGetLeft(childNode.yogaNode)
        let width = YGNodeLayoutGetWidth(childNode.yogaNode)
        let height = YGNodeLayoutGetHeight(childNode.yogaNode)
        
        if childNode.flexView.frame.origin == CGPoint.zero {
            childNode.flexView.frame = CGRect(x: CGFloat(left), y: CGFloat(top), width: CGFloat(width), height: CGFloat(height))
        } else {
            childNode.flexView.frame = CGRect(x: childNode.flexView.frame.origin.x, y: childNode.flexView.frame.origin.y, width: CGFloat(width), height: CGFloat(height))
        }
        for child in childNode.children {
            layout(childNode: child)
        }
    }
    
    /// Render view from flexView instance recursively
    ///
    /// - Parameters:
    ///   - childNode: flex node
    ///   - rootView: UIView of root flex node
    ///   - parentView: UIView of parent flex node
    func render(childNode: FlexNode, rootView: UIView, parentView: UIView?) {
        var pv: UIView!
        
        if parentView == nil {
            pv = rootView
        } else {
            pv = parentView
            if childNode.flexView.useCoreText {
                let view = childNode.flexView.asyncView(from: childNode)
                pv.addSubview(view)
                pv = view
            } else {
                let view = childNode.flexView.view(from: childNode)
                pv.addSubview(view)
                pv = view
            }
        }
        
        for node in childNode.children {
            render(childNode: node, rootView: rootView, parentView: pv)
        }
    }
}

// MARK: FlexView
open class FlexView: NSObject {
    /// The frame rectangle, which describes the view’s location and size in its superview’s coordinate system. default is CGSizeZero
    public var frame: CGRect = CGRect.zero
    /// The view’s background color. default is clear
    public var backgroundColor: UIColor = UIColor.clear
    /// A Boolean value that determines whether subviews are confined to the bounds of the view. default is false
    public var clipsToBounds: Bool = false
    /// A flag used to determine how a view lays out its content when its bounds change. default is scaleToFill
    public var contentMode: UIView.ContentMode = UIView.ContentMode.scaleToFill
    /// The corner radius of the view. default is 0.0
    public var cornerRadius: CGFloat = 0.0
    /// The corners of a rectangle. default is all corners
    public var corners: UIRectCorner = .allCorners
    /// The border color of the view. default is clear
    public var borderColor: UIColor = UIColor.clear
    /// The width of the view's border. default is 0.0
    public var borderWidth: CGFloat = 0.0
    /// Tag of the view. default is 0
    public var tag: Int = 0
    /// A Boolean value that determines whether user events are ignored. default is true
    public var userInteractionEnabled: Bool = true
    /// A Boolean value that determines whether the view is hidden. default is false
    public var hidden = false
    /// The view’s alpha value. default is 1.0
    public var alpha = 1.0
    /// Analytic spm
    public var spm: String = ""
    /// Tap gesture handler
    public var tapGestureHandler: (() -> Void)?
    /// Indicate wheather this node is rendered by Core Text. default is false
    public var useCoreText: Bool = false
    /** Shadow properties. **/
    public var shadowColor: CGColor?
    /* The opacity of the shadow. Defaults to 0. Specifying a value outside the
     * [0,1] range will give undefined results. Animatable. */
    public var shadowOpacity: Float = 0
    /* The shadow offset. Defaults to (0, -3). Animatable. */
    public var shadowOffset: CGSize = .init(width: 0, height: -3)
    /* The blur radius used to create the shadow. Defaults to 3. Animatable. */
    public var shadowRadius: CGFloat = 3
    
    public var eventId: String?
    public var eventAttributes: [String: Any]?
    
    var tapGesture: UITapGestureRecognizer?
    
    required public override init() {
        
    }
    
    open func view(from node: FlexNode) -> UIView {
        let view = UICKView(frame: self.frame)
        view.backgroundColor = self.backgroundColor
        view.clipsToBounds = self.clipsToBounds
        view.tag = self.tag > 0 ? self.tag : 0
        view.isUserInteractionEnabled = self.userInteractionEnabled
        view.isHidden = self.hidden
        view.alpha = CGFloat(self.alpha)
        if let shadowColor = self.shadowColor {
            view.addShadow(color: shadowColor, offset: shadowOffset, opacity: shadowOpacity, radius: shadowRadius, cornerRadius: cornerRadius)
        } else if borderWidth > 0 {
            view.addBorder(color: borderColor, width: borderWidth, cornerRadius: cornerRadius, corners: corners)
        } else if self.cornerRadius > 0.0 {
            view.cropCorner(self.cornerRadius, corners: corners)
        }
        
        if tapGestureHandler != nil {
            view.isUserInteractionEnabled = true
            if tapGesture != nil {
                view.removeGestureRecognizer(tapGesture!)
            }
            tapGesture = UITapGestureRecognizer(target: self, action: #selector(viewTapped))
            view.addGestureRecognizer(tapGesture!)
        }
        
        return view
    }
    
    open func asyncView(from node: FlexNode) -> UIView {
        return UIView.init()
    }
    
    @objc func viewTapped(recognizer: UITapGestureRecognizer) {
        if let handler = tapGestureHandler {
            handler()
        }
    }
}

public class FlexLabel: FlexView {
    /// The current text that is displayed by the label.
    public var text: String?
    /// The font used to display the text. default is system font 17 plain
    public var font: UIFont!
    /// The color of the text. default is text draws black
    public var textColor: UIColor!
    /// The technique to use for aligning the text. default is NSTextAlignmentNatural (before iOS 9, the default was NSTextAlignmentLeft)
    public var textAlignment: NSTextAlignment
    /// The technique to use for wrapping and truncating the label’s text. default is NSLineBreakByTruncatingTail. used for single and multiple lines of text
    public var lineBreakMode: NSLineBreakMode {
        didSet {
            
        }
    }
    /// The current styled text that is displayed by the label. default is nil
    public var attributedText: NSAttributedString?
    /// The maximum number of lines to use for rendering text. default is 1
    public var numberOfLines: Int = 1
    public var copyEnable: Bool = false
    public var extraWidth: CGFloat = 0
    
    public required init() {
        self.text = nil
        self.font = UIFont.systemFont(ofSize: 17)
        self.textColor = UIColor.black
        self.textAlignment = NSTextAlignment.natural
        self.lineBreakMode = NSLineBreakMode.byTruncatingTail
        self.attributedText = nil
        
        super.init()
        
        self.shadowColor = nil
        self.shadowOffset = CGSize(width: 0, height: -1)
        self.userInteractionEnabled = false
    }
    
    open override func view(from node: FlexNode) -> UICKLabel {
        let label = UICKLabel(frame: self.frame)
        label.backgroundColor = self.backgroundColor
        label.clipsToBounds = self.clipsToBounds
        label.tag = self.tag > 0 ? self.tag : 0
        label.isUserInteractionEnabled = self.userInteractionEnabled
        if borderWidth > 0 {
            label.addBorder(color: borderColor, width: borderWidth, cornerRadius: cornerRadius, corners: corners)
        } else if self.cornerRadius > 0.0 {
            label.cropCorner(self.cornerRadius, corners: corners)
        }
        
        label.textAlignment = self.textAlignment
        label.numberOfLines = self.numberOfLines
        label.font = self.font
        label.textColor = self.textColor
        if self.attributedText != nil {
            label.attributedText = self.attributedText
        } else {
            label.text = self.text
        }
        
        if tapGestureHandler != nil {
            label.isUserInteractionEnabled = true
            if tapGesture != nil {
                label.removeGestureRecognizer(tapGesture!)
            }
            tapGesture = UITapGestureRecognizer(target: self, action: #selector(viewTapped))
            label.addGestureRecognizer(tapGesture!)
        }
        
        return label
    }
    
    public override func asyncView(from node: FlexNode) -> UIView {
//        let view = RenderView(frame: self.frame)
//        view.draw(from: self)
//
//        return view
        
        return UIView.init()
    }
}

public class FlexButton: FlexView {
    public var title: String?
    public var titleSelected: String?
    public var titleColor: UIColor
    public var titleColorSelected: UIColor?
    public var titleNumberOfLines: Int?
    public var titleAlignment: NSTextAlignment?
    public var font: UIFont?
    public var image: UIImage?
    public var imageSelected: UIImage?
    public var backgroundImage: UIImage?
    public var attributedTitle: NSAttributedString?
    public var imageURL: String?
    public var imageEdgeInsets: UIEdgeInsets?
    /// The horizontal alignment of content within the control’s bounds. default is center
    public var contentHorizontalAlignment: UIControl.ContentHorizontalAlignment = UIControl.ContentHorizontalAlignment.center
    /// The vertical alignment of content within the control’s bounds. default is center
    public var contentVerticalAlignment: UIControl.ContentVerticalAlignment = UIControl.ContentVerticalAlignment.center
    // default is YES. if YES, image is drawn darker when highlighted(pressed)
    public var adjustsImageWhenHighlighted: Bool = true
    
    public required init() {
        self.title = nil
        self.titleSelected = nil
        self.titleColor = UIColor.black
        self.titleColorSelected = nil
        self.image = nil
        self.imageSelected = nil
        self.backgroundImage = nil
        self.attributedTitle = nil
        self.imageURL = nil
        
        super.init()
        self.userInteractionEnabled = true
    }
    
    open override func view(from node: FlexNode) -> UICKButton {
        let button = UICKButton(frame: self.frame)
        if let buttonTitle = title {
            button.setTitle(buttonTitle, for: UIControl.State.normal)
        }
        if let buttonTitleSelected = titleSelected {
            button.setTitle(buttonTitleSelected, for: UIControl.State.selected)
        }
        if let buttonTitleColorSelected = titleColorSelected {
            button.setTitleColor(buttonTitleColorSelected, for: UIControl.State.selected)
        }
        if let buttonFont = font {
            button.titleLabel?.font = buttonFont
        }
        if let buttonImage = image {
            button.setImage(buttonImage, for: UIControl.State.normal)
        }
        if let buttonBackgroundImage = backgroundImage {
            button.setBackgroundImage(buttonBackgroundImage, for: .normal)
        }
        if let buttonImageSelected = image {
            button.setImage(buttonImageSelected, for: UIControl.State.selected)
        }
        if let buttonImageEdgeInsets = imageEdgeInsets {
            button.imageEdgeInsets = buttonImageEdgeInsets
        }
        if let buttonTitleNumberOfLines = titleNumberOfLines {
            button.titleLabel?.numberOfLines = buttonTitleNumberOfLines
        }
        if let buttonTitleAlignment = titleAlignment {
            button.titleLabel?.textAlignment = buttonTitleAlignment
        }
        button.setTitleColor(titleColor, for: UIControl.State.normal)
        button.backgroundColor = self.backgroundColor
        button.clipsToBounds = self.clipsToBounds
        button.contentHorizontalAlignment = contentHorizontalAlignment
        button.contentVerticalAlignment = contentVerticalAlignment
        button.adjustsImageWhenHighlighted = adjustsImageWhenHighlighted
        button.tag = self.tag > 0 ? self.tag : 0
        if borderWidth > 0 {
            button.addBorder(color: borderColor, width: borderWidth, cornerRadius: cornerRadius)
        } else if self.cornerRadius > 0.0 {
            button.cropCorner(self.cornerRadius)
        }
        
        if self.image != nil {
            button.setImage(self.image, for: UIControl.State.normal)
        }
        button.isUserInteractionEnabled = self.userInteractionEnabled
        
        if tapGestureHandler != nil {
            button.isUserInteractionEnabled = true
            if tapGesture != nil {
                button.removeGestureRecognizer(tapGesture!)
            }
            tapGesture = UITapGestureRecognizer(target: self, action: #selector(viewTapped))
            button.addGestureRecognizer(tapGesture!)
        }
        
        return button
    }
}

public class FlexImageView: FlexView {
    public var image: UIImage?
    public var imageURL: String?
    
    public required init() {
        self.image = nil
        self.imageURL = nil
        
        super.init()
        self.userInteractionEnabled = false
    }
    
    open override func view(from node: FlexNode) -> UICKImageView {
        let imageView = UICKImageView(frame: self.frame)
        imageView.backgroundColor = self.backgroundColor
        imageView.clipsToBounds = self.clipsToBounds
        imageView.tag = self.tag > 0 ? self.tag : 0
        if let shadowColor = self.shadowColor {
            imageView.addShadow(color: shadowColor, offset: shadowOffset, opacity: shadowOpacity, radius: shadowRadius, cornerRadius: cornerRadius)
        } else if borderWidth > 0 {
            imageView.addBorder(color: borderColor, width: borderWidth, cornerRadius: cornerRadius, corners: corners)
        } else if self.cornerRadius > 0.0 {
            imageView.cropCorner(self.cornerRadius, corners: corners)
        }
        
        imageView.contentMode = self.contentMode
        if self.image != nil {
            imageView.image = self.image
        } else {
            imageView.kf.setImage(with: URL(string: self.imageURL ?? ""), placeholder: FlexNode.shared.placeholder, options: [
                .processor(DownsamplingImageProcessor(size: imageView.frame.size)),
                .scaleFactor(UIScreen.main.scale),
                .transition(.fade(0.3))
            ])
        }
        imageView.isUserInteractionEnabled = userInteractionEnabled
        
        if tapGestureHandler != nil {
            imageView.isUserInteractionEnabled = true
            if tapGesture != nil {
                imageView.removeGestureRecognizer(tapGesture!)
            }
            tapGesture = UITapGestureRecognizer(target: self, action: #selector(viewTapped))
            imageView.addGestureRecognizer(tapGesture!)
        }
        
        return imageView
    }
}

public class FlexTextField: FlexView {
    public var font: UIFont?
    public var text: String?
    public var textColor: UIColor?
    public var placeholder: String?
    public var attributedPlaceholder: NSAttributedString?
    public var returnKeyType: UIReturnKeyType?
    public var keyboardType: UIKeyboardType?
    public var isSecureTextEntry: Bool = false
    /// The technique to use for aligning the text. default is NSTextAlignmentNatural (before iOS 9, the default was NSTextAlignmentLeft)
    public var textAlignment: NSTextAlignment
    
    public required init() {
        self.text = nil
        self.font = UIFont.systemFont(ofSize: 17)
        self.textColor = UIColor.black
        self.textAlignment = .left
        
        super.init()
    }
    
    public override func view(from node: FlexNode) -> UITextField {
        let textField = UITextField(frame: self.frame)
        textField.text = text
        textField.textColor = textColor
        textField.font = font
        textField.backgroundColor = self.backgroundColor
        textField.tag = self.tag > 0 ? self.tag : 0
        if let attriPlaceholder = attributedPlaceholder {
            textField.attributedPlaceholder = attriPlaceholder
        } else {
            textField.placeholder = placeholder
        }
        if let returnKey = returnKeyType {
            textField.returnKeyType = returnKey
        }
        if let keyboard = keyboardType {
            textField.keyboardType = keyboard
        }
        textField.isSecureTextEntry = isSecureTextEntry
        textField.textAlignment = textAlignment
        if borderWidth > 0 {
            textField.addBorder(color: borderColor, width: borderWidth, cornerRadius: cornerRadius, corners: corners)
        } else if self.cornerRadius > 0.0 {
            textField.cropCorner(self.cornerRadius)
        }
        textField.isUserInteractionEnabled = self.userInteractionEnabled
        
        
        return textField
    }
}

public class FlexTextView: FlexView {
    public var font: UIFont?
    public var text: String?
    public var textColor: UIColor?
    public var placeholder: String?
    public var placeholderColor: UIColor?
    public var textContainerInset: UIEdgeInsets
    public var tintColor: UIColor?
    
    public required init() {
        self.text = nil
        self.font = UIFont.systemFont(ofSize: 17)
        self.textColor = UIColor.black
        self.textContainerInset = .zero
        
        super.init()
    }
    
    public override func view(from node: FlexNode) -> UITextView {
        let textView = UITextView(frame: self.frame)
        textView.text = text
        textView.textColor = textColor
        textView.font = font
        textView.backgroundColor = self.backgroundColor
        textView.textContainerInset = textContainerInset
        textView.tintColor = tintColor
        textView.tag = self.tag > 0 ? self.tag : 0
        
        if borderWidth > 0 {
            textView.addBorder(color: borderColor, width: borderWidth, cornerRadius: cornerRadius)
        } else if self.cornerRadius > 0.0 {
            textView.cropCorner(self.cornerRadius)
        }
        
        return textView
    }
}

public class UICKView: UIView {
    
}

public class UICKLabel: UILabel {
    
}

public class UICKButton: UIButton {
    
}

public class UICKImageView: UIImageView {
    
}

public class UICKTextField: UITextField {
    
}

struct FlexboxKit {
    
}

extension UIView {
    func cropCorner(_ cornerRadius: CGFloat, corners: UIRectCorner = .allCorners) {
        let maskLayer = CAShapeLayer()
        maskLayer.frame = CGRect(x: 0, y: 0, width: frame.width, height: frame.height)
        
        if corners != .allCorners {
            var bezierPath = UIBezierPath.init(roundedRect: maskLayer.frame, cornerRadius: cornerRadius)
            bezierPath =  UIBezierPath(roundedRect: self.bounds, byRoundingCorners: corners, cornerRadii: .init(width: cornerRadius, height: cornerRadius))
            maskLayer.path = bezierPath.cgPath
        } else {
            maskLayer.path = UIBezierPath(roundedRect: maskLayer.frame, cornerRadius: cornerRadius).cgPath
        }
        
        layer.mask = maskLayer
    }
    
    func addBorder(color: UIColor, width: CGFloat, cornerRadius: CGFloat, corners: UIRectCorner = .allCorners) {
        let borderLayer = CAShapeLayer()
        borderLayer.frame = CGRect(x: 0, y: 0, width: frame.width, height: frame.height)
        borderLayer.lineWidth = width
        borderLayer.strokeColor = color.cgColor
        borderLayer.fillColor = UIColor.clear.cgColor
        
        var bezierPath = UIBezierPath.init(roundedRect: borderLayer.frame, cornerRadius: cornerRadius)
        if corners != .allCorners {
            bezierPath =  UIBezierPath(roundedRect: self.bounds, byRoundingCorners: corners, cornerRadii: .init(width: cornerRadius, height: cornerRadius))
        }
        borderLayer.path = bezierPath.cgPath
        
        layer.insertSublayer(borderLayer, at: 0)
        
        if cornerRadius > 0 {
            let maskLayer = CAShapeLayer()
            maskLayer.frame = CGRect(x: 0, y: 0, width: frame.width, height: frame.height)
            
            maskLayer.path = bezierPath.cgPath
            layer.mask = maskLayer
        }
    }
    
    func addShadow(color: CGColor, offset: CGSize, opacity: Float, radius: CGFloat, cornerRadius: CGFloat) {
        let shadowView = UIView(frame: CGRect(x: 0, y: 0, width: frame.width, height: frame.height))
        
        shadowView.backgroundColor = .white
        
        shadowView.layer.shadowColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.2).cgColor
        shadowView.layer.shadowOffset = CGSize(width: 0, height: 1)
        shadowView.layer.shadowOpacity = 1
        shadowView.layer.shadowRadius = 4
        
        if cornerRadius > 0 {
            let bezierPath = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: frame.width, height: frame.height), cornerRadius: cornerRadius)
            
            let maskLayer = CAShapeLayer()
            maskLayer.frame = CGRect(x: 0, y: 0, width: frame.width, height: frame.height)
            
            maskLayer.path = bezierPath.cgPath
            layer.mask = maskLayer
        }
        
        addSubview(shadowView)
    }
}

