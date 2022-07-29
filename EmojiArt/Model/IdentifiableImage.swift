//
//  IdentifiableImage.swift
//  EmojiArt
//
//  Created by Сергей Цайбель on 01.07.2022.
//

import UIKit

struct IdentifiableImage: Identifiable {
	let id = UUID()
	let image: UIImage
}
