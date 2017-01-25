//
//  ValueStepper.swift
//  http://github.com/BalestraPatrick/ValueStepper
//
//  Created by Patrick Balestra on 2/16/16.
//  Copyright © 2016 Patrick Balestra. All rights reserved.
//

import UIKit

/// Button tags
///
/// - decrease: decrease button has tag 0.
/// - increase: increase button has tag 1.
private enum Button: Int {
    case decrease
    case increase
}

@IBDesignable public class ValueStepper: UIControl {
    
    // MARK - Public variables
    
    /// Current value and sends UIControlEventValueChanged when modified.
    @IBInspectable public var value: Double = 0.0 {
        didSet {
            if value > maximumValue || value < minimumValue {
               // Value is possibly out of range, it means we're setting up the values so discard any update to the UI.
            } else if oldValue != value {
                sendActions(for: .valueChanged)
                setFormattedValue(value)
                setState()
            }
        }
    }
    
    /// Minimum value that must be the less than the maximum value.
    @IBInspectable public var minimumValue: Double = 0.0
    
    /// Maximum value that must be greater than the minimum value.
    @IBInspectable public var maximumValue: Double = 1.0
    
    /// The value added/subtracted when one of the two buttons is pressed.
    @IBInspectable public var stepValue: Double = 0.1
    
    /// When set to true, keeping a button pressed will continuously increase/decrease the value every 0.1s.
    @IBInspectable public var autorepeat: Bool = true
    
    /// Describes the format of the value.
    public var numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        return formatter
    }() {
        didSet {
            setFormattedValue(value)
        }
    }
    
    // Default width of the stepper. Taken from the official UIStepper object.
    public let defaultWidth = 141.0
    
    // Default height of the stepper. Taken from the official UIStepper object.
    public let defaultHeight = 29.0
    
    // MARK - Private variables
    
    /// Decrease button positioned on the left of the stepper.
    private let decreaseButton: UIButton = {
        let button = UIButton(type: UIButtonType.custom)
        button.backgroundColor = UIColor.clear
        button.tag = Button.decrease.rawValue
        return button
    }()
    
    /// Increase button positioned on the right of the stepper.
    private let increaseButton: UIButton = {
        let button = UIButton(type: UIButtonType.custom)
        button.backgroundColor = UIColor.clear
        button.tag = Button.increase.rawValue
        return button
    }()
    
    /// Value label that displays the current value displayed at the center of the stepper.
    private let valueLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.backgroundColor = UIColor.clear
        label.minimumScaleFactor = 0.5
        label.adjustsFontSizeToFitWidth = true
        return label
    }()
    
    // Decrease (-) button layer. Declared here because we can change its color when not enabled.
    private var decreaseLayer = CAShapeLayer()
    
    // Increase (+) button layer. Declared here because we can change its color when not enabled.
    private var increaseLayer = CAShapeLayer()
    
    // Left separator.
    private var leftSeparator = CAShapeLayer()
    
    // Right separator.
    private var rightSeparator = CAShapeLayer()
    
    // Timer used in case that autorepeat is true to change the value continuously.
    private var continuousTimer: Timer?

    
    // MARK: Initializers
    
    override init(frame: CGRect) {
        // Override frame with default width and height
        let frameWithDefaultSize = CGRect(x: Double(frame.origin.x), y: Double(frame.origin.y), width: defaultWidth, height: defaultHeight)
        super.init(frame: frameWithDefaultSize)
        setUp()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setUp()
    }
    
    private func setUp() {
        addSubview(decreaseButton)
        addSubview(valueLabel)
        addSubview(increaseButton)
        
        // Control events
        decreaseButton.addTarget(self, action: #selector(decrease(_:)), for: .touchUpInside)
        increaseButton.addTarget(self, action: #selector(increase(_:)), for: .touchUpInside)
        increaseButton.addTarget(self, action: #selector(stopContinuous(_:)), for: .touchUpOutside)
        decreaseButton.addTarget(self, action: #selector(stopContinuous(_:)), for: .touchUpOutside)
        decreaseButton.addTarget(self, action: #selector(selected(_:)), for: .touchDown)
        increaseButton.addTarget(self, action: #selector(selected(_:)), for: .touchDown)
    }
    
    // MARK: Storyboard preview setup
    
    override public func prepareForInterfaceBuilder() {
        setUp()
    }

    public override var intrinsicContentSize: CGSize {
        get {
            return CGSize(width: defaultWidth, height: defaultHeight)
        }
    }
    
    public override static var requiresConstraintBasedLayout: Bool {
        get {
            return true
        }
    }
    
    // MARK: Lifecycle
    
    public override func layoutSubviews() {
        // Size constants
        let sliceWidth = bounds.width / 3
        let sliceHeight = bounds.height
        
        // Set frames
        decreaseButton.frame = CGRect(x: 0, y: 0, width: sliceWidth, height: sliceHeight)
        valueLabel.frame = CGRect(x: sliceWidth, y: 0, width: sliceWidth, height: sliceHeight)
        increaseButton.frame = CGRect(x: sliceWidth * 2, y: 0, width: sliceWidth, height: sliceHeight)
        
        // Set text color to tintColor
        valueLabel.textColor = tintColor
        
        // Set initial formatted value
        setFormattedValue(value)
    }
    
    public override func draw(_ rect: CGRect) {
        // Size constants
        let sliceWidth = bounds.width / 3
        let sliceHeight = bounds.height
        let thickness = 1.0 as CGFloat
        let iconSize: CGFloat = sliceHeight * 0.6
        
        // Layer customizations
        layer.borderColor = tintColor.cgColor
        layer.borderWidth = 1.0
        layer.cornerRadius = 4.0
        backgroundColor = UIColor.clear
        clipsToBounds = true
        
        let leftPath = UIBezierPath()
        // Left separator line
        leftPath.move(to: CGPoint(x: sliceWidth, y: 0.0))
        leftPath.addLine(to: CGPoint(x: sliceWidth, y: sliceHeight))
        tintColor.setStroke()
        leftPath.stroke()
        
        // Set left separator layer
        leftSeparator.path = leftPath.cgPath
        leftSeparator.strokeColor = tintColor.cgColor
        layer.addSublayer(leftSeparator)
        
        // Right separator line
        let rightPath = UIBezierPath()
        rightPath.move(to: CGPoint(x: sliceWidth * 2, y: 0.0))
        rightPath.addLine(to: CGPoint(x: sliceWidth * 2, y: sliceHeight))
        tintColor.setStroke()
        rightPath.stroke()
        
        // Set right separator layer
        rightSeparator.path = rightPath.cgPath
        rightSeparator.strokeColor = tintColor.cgColor
        layer.addSublayer(rightSeparator)
        
        // - path
        let decreasePath = UIBezierPath()
        decreasePath.lineWidth = thickness
        // Horizontal + line
        decreasePath.move(to: CGPoint(x: (sliceWidth - iconSize) / 2 + 0.5, y: sliceHeight / 2 + 0.5))
        decreasePath.addLine(to: CGPoint(x: (sliceWidth - iconSize) / 2 + 0.5 + iconSize, y: sliceHeight / 2 + 0.5))
        tintColor.setStroke()
        decreasePath.stroke()
        
        // Create layer so that we can dynamically change its color when not enabled
        decreaseLayer.path = decreasePath.cgPath
        decreaseLayer.strokeColor = tintColor.cgColor
        layer.addSublayer(decreaseLayer)
        
        // + path
        let increasePath = UIBezierPath()
        increasePath.lineWidth = thickness
        // Horizontal + line
        increasePath.move(to: CGPoint(x: (sliceWidth - iconSize) / 2 + 0.5 + sliceWidth * 2, y: sliceHeight / 2 + 0.5))
        increasePath.addLine(to: CGPoint(x: (sliceWidth - iconSize) / 2 + 0.5 + iconSize + sliceWidth * 2, y: sliceHeight / 2 + 0.5))
        // Vertical + line
        increasePath.move(to: CGPoint(x: sliceWidth / 2 + 0.5 + sliceWidth * 2, y: (sliceHeight / 2) - (iconSize / 2) + 0.5))
        increasePath.addLine(to: CGPoint(x: sliceWidth / 2 + 0.5 + sliceWidth * 2, y: (sliceHeight / 2) + (iconSize / 2) + 0.5))
        tintColor.setStroke()
        increasePath.stroke()
        
        // Create layer so that we can dynamically change its color when not enabled
        increaseLayer.path = increasePath.cgPath
        increaseLayer.strokeColor = tintColor.cgColor
        layer.addSublayer(increaseLayer)
        
        // Set initial buttons state
        setState()
    }
    
    // MARK: Control Events
    
    func decrease(_ sender: UIButton) {
        sender.backgroundColor = UIColor(white: 1.0, alpha: 0.0)
        continuousTimer?.invalidate()
        continuousTimer = nil
        decreaseValue()
    }
    
    func increase(_ sender: UIButton) {
        sender.backgroundColor = UIColor(white: 1.0, alpha: 0.0)
        continuousTimer?.invalidate()
        continuousTimer = nil
        increaseValue()
    }
    
    func continuousIncrement(_ timer: Timer) {
        // Check which one of the two buttons was continuously pressed
        let userInfo = timer.userInfo as! Dictionary<String, AnyObject>
        guard let sender = userInfo["sender"] as? UIButton else { return }
        
        if sender.tag == Button.decrease.rawValue {
            decreaseValue()
        } else {
            increaseValue()
        }
    }
    
    func selected(_ sender: UIButton) {
        // Start a timer to handle the continuous pressed case
        if autorepeat {
            continuousTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(continuousIncrement), userInfo: ["sender" : sender], repeats: true)
        }
        sender.backgroundColor = UIColor(white: 1.0, alpha: 0.1)
    }
    
    func stopContinuous(_ sender: UIButton) {
        // When dragged outside, stop the timer.
        continuousTimer?.invalidate()
    }
    
    func increaseValue() {
        let roundedValue = value.rounded(digits: numberFormatter.maximumFractionDigits)
        print(roundedValue)
        if roundedValue + stepValue <= maximumValue && roundedValue + stepValue >= minimumValue {
            value = roundedValue + stepValue
        }
    }
    
    func decreaseValue() {
        let roundedValue = value.rounded(digits: numberFormatter.maximumFractionDigits)
        if roundedValue - stepValue <= maximumValue && roundedValue - stepValue >= minimumValue {
            value = roundedValue - stepValue
        }
    }
    
    // MARK: Actions
    
    // Set correct state of the buttons (in case we reached the minimum or maximum value).
    private func setState() {
        if value >= maximumValue {
            increaseButton.isEnabled = false
            increaseLayer.strokeColor = UIColor.gray.cgColor
            continuousTimer?.invalidate()
        } else if value <= minimumValue {
            decreaseButton.isEnabled = false
            decreaseLayer.strokeColor = UIColor.gray.cgColor
            continuousTimer?.invalidate()
        } else {
            increaseButton.isEnabled = true
            decreaseButton.isEnabled = true
            increaseLayer.strokeColor = tintColor.cgColor
            decreaseLayer.strokeColor = tintColor.cgColor
        }
    }
    
    // Display the value with the
    private func setFormattedValue(_ value: Double) {
        valueLabel.text = numberFormatter.string(from: NSNumber(value: value))
    }
    
    // Update all the subviews tintColor properties.
    public override func tintColorDidChange() {
        layer.borderColor = tintColor.cgColor
        valueLabel.textColor = tintColor
        leftSeparator.strokeColor = tintColor.cgColor
        rightSeparator.strokeColor = tintColor.cgColor
    }
    
}

extension Double {

    /// Rounds a double to `digits` decimal places.
    func rounded(digits: Int) -> Double {
        let behavior = NSDecimalNumberHandler(roundingMode: NSDecimalNumber.RoundingMode.bankers, scale: Int16(digits), raiseOnExactness: false, raiseOnOverflow: false, raiseOnUnderflow: false, raiseOnDivideByZero: true)
        return NSDecimalNumber(value: self).rounding(accordingToBehavior: behavior).doubleValue
    }
}
