//
//  ShareSheet.swift
//  EmojiArt
//
//  Created by Сергей Цайбель on 30.06.2022.
//

import SwiftUI


struct ShareView: UIViewControllerRepresentable {
	var itemsToShare: [Any]
	var servicesToShareItems: [UIActivity]? = nil
	
	func makeUIViewController(context: UIViewControllerRepresentableContext<ShareView>) -> UIActivityViewController {
		let activityVC = UIActivityViewController(activityItems: itemsToShare, applicationActivities: servicesToShareItems)
		if UIDevice.current.userInterfaceIdiom == .pad {
			activityVC.popoverPresentationController?.sourceRect = CGRect(x: 0, y: 0, width: 100, height: 100)
//			sourceView = self.view
//			activityViewController.popoverPresentationController?.sourceRect = view.bounds
		}
		return activityVC
	}
	
	func updateUIViewController(_ uiViewController: UIActivityViewController, context: UIViewControllerRepresentableContext<ShareView>) {
	}
}
