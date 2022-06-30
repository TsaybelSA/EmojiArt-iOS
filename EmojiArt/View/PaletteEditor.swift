//
//  PaletteEditor.swift
//  EmojiArt
//
//  Created by Сергей Цайбель on 26.03.2022.
//

import SwiftUI

struct PaletteEditor: View {
	
	@Binding var palette: Palette
	
	private let emojiFontSize: CGFloat = 40
	private var emojiFont: Font { .system(size: emojiFontSize) }
	
    var body: some View {
		Form {
			nameSection
			addEmojiSection
			removeEmojiSection
		}
		.frame(minWidth: 350, minHeight: 400)
		.navigationTitle("Edit \(palette.name)")
    }
	
	var nameSection: some View {
		Section(header: Text("Name")) {
			TextField("", text: $palette.name)
		}
	}
	
	@State var emojisToAdd = ""
	
	@ViewBuilder
	var addEmojiSection: some View {
		Section(header: Text("Add Emojis")) {
			let removedEmojis = palette.removedEmojis.withNoRepeatedCharacters.map { String($0) }
			ScrollView(.horizontal, showsIndicators: false) {
				HStack {
					ForEach(removedEmojis.reversed(), id: \.self) { emoji in
						Text(emoji).font(emojiFont)
							.padding(.leading, 0)
							.onTapGesture {
								withAnimation {
									addEmojis(emoji)
								}
							}
					}
					TextField("", text: $emojisToAdd)
						.frame(width:250)
						.onChange(of: emojisToAdd) { emojis in
							if emojis.isEmoji {
								palette.removedEmojis.insert(contentsOf: emojis, at: palette.removedEmojis.endIndex)
								emojisToAdd.removeAll(where: { String($0) == emojis })
							}
						}
				}
			}
		}
	}
	
	
	private func addEmojis(_ emojis: String) {
		palette.emojis = (palette.emojis + emojis)
			.filter { $0.isEmoji }
			.withNoRepeatedCharacters
		if let index = palette.removedEmojis.firstIndex(where: { String($0) == emojis }) {
			palette.removedEmojis.remove(at: index)
		}
	}
	
	var removeEmojiSection: some View {
		Section(header: Text("Remove Emoji")) {
			let emojis = palette.emojis.withNoRepeatedCharacters.map { String($0) }
			LazyVGrid(columns: [GridItem(.adaptive(minimum: 40))]) {
				ForEach(emojis, id: \.self) { emoji in
					Text(emoji)
						.font(emojiFont)
						.onTapGesture {
							withAnimation {
								palette.removedEmojis.insert(contentsOf: emoji, at: palette.removedEmojis.endIndex)
								palette.emojis.removeAll(where: { emoji == String($0) })
							}
						}
				}
			}
		}
	}
}

struct PaletteEditor_Previews: PreviewProvider {
    static var previews: some View {
		PaletteEditor(palette: .constant(Palette(name: "Preview", emojis: "🚨🚞✈️🚊", id: 0)))
			.previewDevice("iPhone 11")
			.previewLayout(.fixed(width: /*@START_MENU_TOKEN@*/300.0/*@END_MENU_TOKEN@*/, height: /*@START_MENU_TOKEN@*/350.0/*@END_MENU_TOKEN@*/))
    }
}
