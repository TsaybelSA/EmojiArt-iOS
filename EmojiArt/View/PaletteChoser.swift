//
//  PaletteChooser.swift
//  EmojiArt
//
//  Created by Сергей Цайбель on 26.03.2022.
//

import SwiftUI

struct PaletteChoser: View {
	
	@EnvironmentObject var store: PaletteStore
	
	private let emojiFontSize: CGFloat = 40
	private var emojiFont: Font { .system(size: emojiFontSize) }
	
	@SceneStorage("PaletteChoser.chosenPaletteIndex")
	private var chosenPaletteIndex = 0
	
    var body: some View {
		HStack {
			paletteControllButton
			body(for: store.palette(at: chosenPaletteIndex))
		}
		.clipped()
	}
	
	func body(for palette: Palette) -> some View {
		HStack {
			Text(palette.name)
			ScrollingEmojisView(emojis: palette.emojis)
				.font(emojiFont)
		}
		.id(palette.id)
		.transition(rollTransition)
		.popover(item: $paletteToEdit) { palette in
			PaletteEditor(palette: $store.palettes[palette])
				.wrappedInNavigationViewToMakeDismissable { paletteToEdit = nil }
		}
		.sheet(isPresented: $managing) {
			PaletteManager()
		}
	}
	
	@State var managing = false
	
	@State var paletteToEdit: Palette?
	
	var rollTransition: AnyTransition {
		AnyTransition.asymmetric(
			insertion: .offset(x: 0, y: emojiFontSize),
			removal: .offset(x: 0, y: -emojiFontSize)
		)
	}
	
	var paletteControllButton: some View {
		Button {
			withAnimation {
				chosenPaletteIndex = (chosenPaletteIndex + 1) % store.palettes.count
			}
		} label: {
			Image(systemName: "paintpalette")
		}
		.font(emojiFont)
		.contextMenu { contextMenu }
	}
	
	@ViewBuilder
	var contextMenu: some View {
		AnimatedActionButton(title: "Edit", systemImage: "pencil") {
			paletteToEdit = store.palette(at: chosenPaletteIndex)
		}
		AnimatedActionButton(title: "New", systemImage: "plus") {
			store.insertPalette(named: "New")
			chosenPaletteIndex = 0
			paletteToEdit = store.palette(at: chosenPaletteIndex)
		}
		AnimatedActionButton(title: "Delete", systemImage: "minus.circle") {
			store.removePalette(at: chosenPaletteIndex)
		}
		AnimatedActionButton(title: "Manager", systemImage: "slider.vertical.3") {
			managing = true
		}
		goToMenu
	}
	var goToMenu: some View {
		Menu {
			ForEach(store.palettes) { palette in
				AnimatedActionButton(title: palette.name) {
					if let index = store.palettes.index(matching: palette) {
						chosenPaletteIndex = index
					}
				}
			}
		} label: {
			Label("Go To", systemImage: "text.insert")
		}
	}
}

private struct ScrollingEmojisView: View {
	let emojis: String

	var body: some View {
		ScrollView(.horizontal) {
			HStack {
				ForEach(emojis.withNoRepeatedCharacters.map { String($0) }, id: \.self) { emoji in
					Text(emoji)
						.onDrag { NSItemProvider(object: emoji as NSString) }
				}
			}
		}
	}
}

