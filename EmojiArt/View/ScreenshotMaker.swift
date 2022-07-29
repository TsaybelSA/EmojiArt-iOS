//
//  ScreenshotMaker.swift
//  InspectSwiftUI
//
//  Created by Gualtiero Frigerio on 21/01/22.
//

import UIKit

class ScreenshotMaker: UIView {
	func makeScreenshot(with frameSize: CGSize? = nil) -> UIImage? {
        guard let containerView = self.superview?.superview,
              let containerSuperview = containerView.superview else { return nil }
		
		var renderer: UIGraphicsImageRenderer!
		if let frameSize = frameSize {
			renderer = UIGraphicsImageRenderer(size: frameSize)
		} else {
			renderer = UIGraphicsImageRenderer(bounds: containerSuperview.frame)
		}
		let data = renderer.jpegData(withCompressionQuality: 1) { (context) in
			containerSuperview.layer.render(in: context.cgContext)
		}
		return UIImage(data: data)
    }
}
