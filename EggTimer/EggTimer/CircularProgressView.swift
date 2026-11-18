//
//  CircularProgressView.swift
//  EggTimer
//
//  Created by Arshia Moghbel on 11/17/26.
//  Copyright © 2026 The App Brewery. All rights reserved.
//

import UIKit

final class CircularProgressView: UIView {

    // MARK: - Properties

    /// Current progress in 0...1. Setting it directly never animates.
    private(set) var progress: CGFloat = 0

    var lineWidth: CGFloat = 12 {
        didSet {
            updateAppearance()
            setNeedsLayout()
        }
    }

    var progressColor: UIColor = .systemOrange {
        didSet { updateAppearance() }
    }

    var trackColor: UIColor = .systemGray5 {
        didSet { updateAppearance() }
    }

    // MARK: - Layers

    private let trackLayer = CAShapeLayer()
    private let progressLayer = CAShapeLayer()

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayers()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayers()
    }

    // MARK: - Setup

    private func setupLayers() {

        backgroundColor = .clear
        isAccessibilityElement = false

        for shape in [trackLayer, progressLayer] {
            shape.fillColor = UIColor.clear.cgColor
            shape.lineCap = .round
            layer.addSublayer(shape)
        }

        progressLayer.strokeEnd = progress

        updateAppearance()
    }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()

        let centerPoint = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius = max(min(bounds.width, bounds.height) / 2 - lineWidth / 2, 0)

        let startAngle = -CGFloat.pi / 2
        let endAngle = startAngle + 2 * CGFloat.pi

        let path = UIBezierPath(
            arcCenter: centerPoint,
            radius: radius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: true
        ).cgPath

        // Layout must not trigger implicit animations of the path.
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        trackLayer.frame = bounds
        progressLayer.frame = bounds
        trackLayer.path = path
        progressLayer.path = path
        CATransaction.commit()
    }

    // MARK: - Appearance

    private func updateAppearance() {
        // CGColors are not dynamic, so resolve them for the current trait collection
        // (keeps Light/Dark mode correct).
        trackLayer.strokeColor = trackColor.resolvedColor(with: traitCollection).cgColor
        progressLayer.strokeColor = progressColor.resolvedColor(with: traitCollection).cgColor

        trackLayer.lineWidth = lineWidth
        progressLayer.lineWidth = lineWidth
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateAppearance()
        }
    }

    // MARK: - Progress

    func setProgress(
        _ value: CGFloat,
        animated: Bool = true,
        duration: CFTimeInterval = 0.5
    ) {

        let newProgress = min(max(value, 0), 1)

        // Start from what is currently on screen, not from the model value.
        let currentValue = progressLayer.presentation()?.strokeEnd ?? progressLayer.strokeEnd

        progressLayer.removeAnimation(forKey: "progressAnimation")

        CATransaction.begin()
        CATransaction.setDisableActions(true)   // we drive the animation explicitly
        progressLayer.strokeEnd = newProgress
        CATransaction.commit()

        progress = newProgress

        guard animated, duration > 0 else { return }

        let animation = CABasicAnimation(keyPath: "strokeEnd")
        animation.fromValue = currentValue
        animation.toValue = newProgress
        animation.duration = duration
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        progressLayer.add(animation, forKey: "progressAnimation")
    }
}
