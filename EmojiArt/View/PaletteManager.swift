//
//  PaletteManager.swift
//  EmojiArt
//
//  Created by Сергей Цайбель on 26.03.2022.
//

import SwiftUI

struct PaletteManager: View {
	
	@EnvironmentObject var store: PaletteStore
	@Environment(\.presentationMode) var presentationMode
	
	@State private var editMode: EditMode = .inactive
	
	var body: some View {
		NavigationView {
			List {
				ForEach(store.palettes) { palette in
					NavigationLink(destination: PaletteEditor(palette: $store.palettes[palette])) {
						VStack(alignment: .leading) {
							Text(palette.name)
							Text(palette.emojis)
						}
					}
				}
				.onDelete { indexSet in
					withAnimation {
						store.palettes.remove(atOffsets: indexSet)
					}
				}
				.onMove { indexSet, newOffset in
					store.palettes.move(fromOffsets: indexSet, toOffset: newOffset)
				}
			}
			.navigationTitle("Palette Manager")
			.dismissable { presentationMode.wrappedValue.dismiss() }
			.toolbar {
				ToolbarItem {
					EditButton()
				}
			}
			.environment(\.editMode, $editMode)
		}
    }
}

struct PaletteManager_Previews: PreviewProvider {
    static var previews: some View {
		PaletteManager()
			.previewDevice("iPhone 11")
			.environmentObject(PaletteStore(named: "Preview"))
    }
}
