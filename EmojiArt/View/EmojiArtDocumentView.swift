//
//  EmojiArtDocumentView.swift
//  EmojiArt
//
//  Created by Сергей Цайбель on 23.03.2022.
//

import SwiftUI

struct EmojiArtDocumentView: View {
    @ObservedObject var document: EmojiArtDocument
	
	@Environment(\.undoManager) var undoManager
	@Environment(\.colorScheme) var colorScheme
	
    @ScaledMetric var defaultEmojiFontSize: CGFloat = 40
	    
	@State private var screenshotMaker: ScreenshotMaker?
	@State private var imageToShare: IdentifiableImage?
	
    var body: some View {
        VStack(spacing: 0) {
            documentBody
            PaletteChoser()
        }
    }
    var documentBody: some View {
        GeometryReader { geometry in
            ZStack {
				let backgroundColor = (colorScheme == .dark ? Color.gray : Color.white)
				backgroundColor
				OptionalImage(uiImage: document.backgroundImage)
					.scaleEffect(zoomScale)
					.position(convertFromEmojiCoordinates((0,0), in: geometry))
				
				.gesture(doubleTapToZoom(in: geometry.size).exclusively(before: tapOnBackground()))
				
                if document.backgroundImageFetchStatus == .fetching {
                    ProgressView().scaleEffect(2)
					
                } else {
                    ForEach(document.emojis) { emoji in
						ZStack {
							Text(emoji.text)
								.animatableFont(with: fontSize(for: emoji))
								.scaleEffect(zoomScale)
							
							selectionFrame(for: emoji)
								.scaleEffect(zoomScale)
						}
						.position(position(for: emoji, in: geometry))
						.offset(isEmojiSelected(emoji) ? emojiDragOffset : CGSize.zero)
						.gesture(tapOnEmoji(emoji, geometry: geometry).simultaneously(with: emojiDragGesture(for: emoji, in: geometry)))
                    }
                }
            }
            .clipped()
            .onDrop(of: [.plainText,.url,.image], isTargeted: nil) { providers, location in
                drop(providers: providers, at: location, in: geometry)
            }
			.gesture(panGesture().simultaneously(with: zoomGesture()))
			
			.alert(item: $alertToShow) { alertToShow in
				alertToShow.alert()
			}
			.onChange(of: document.backgroundImageFetchStatus) { status in
				switch status {
					case .failed(let url) :
						showBackgroundImageFetchFailedAlert(url)
					default: break
				}
			}
			.onReceive(document.$backgroundImage) { image in
				if autozoom {
					zoomToFit(image, in: geometry.size)
				}
			}
			.popover(item: $imageToShare) { imageToShare in
				ShareView(itemsToShare: [imageToShare.image])
			}
			.screenshotView { screenshotMaker in
				self.screenshotMaker = screenshotMaker
			}
			.compactableToolbar {
				AnimatedActionButton(title: "Paste Background", systemImage: "doc.on.clipboard") {
					pasteBackground()
				}
				if Camera.isAvailable {
					AnimatedActionButton(title: "Take Photo", systemImage: "camera") {
						backgroundPicker = .camera
					}
				}
				if PhotoLibrary.isAvailable {
					AnimatedActionButton(title: "Search Photos", systemImage: "photo") {
						backgroundPicker = .library
					}
				}
				
				AnimatedActionButton(title: "Share Art", systemImage: "square.and.arrow.up") {
					if let screenshotMaker = screenshotMaker {
						if let image = screenshotMaker.makeScreenshot(with: geometry.size) {
							imageToShare = IdentifiableImage(image: image)
						}
					}
				}

				AnimatedActionButton(title: "Undo", systemImage: "arrow.uturn.backward") {
					undoManager?.undo()
				}
				AnimatedActionButton(title: "Redo", systemImage: "arrow.uturn.forward") {
					undoManager?.redo()
				}
			}
			.sheet(item: $backgroundPicker) { pickerType in
				switch pickerType {
					case .camera:
						Camera(handlePickerImage: { image in handlePickerBackgroundImage(image)})
					case .library:
						PhotoLibrary(handlePickedImage: { image in handlePickerBackgroundImage(image)})
				}
			}
        }
    }
	
	private func handlePickerBackgroundImage(_ image: UIImage?) {
		autozoom = true
		if let imageData = image?.jpegData(compressionQuality: 0.5) {
			document.setBackground(.imageData(imageData), undoManager: undoManager)
		}
		backgroundPicker = nil
	}
	
	//@State which controls whether the camera or photo-library sheet (or neither) is up
	@State private var backgroundPicker: BackgroundPickerType?
	
	//enum to control which photo-picking sheet to show
	enum BackgroundPickerType: Identifiable {
		case camera
		case library
		var id: BackgroundPickerType { self }
	}
	
	private func pasteBackground() {
		autozoom = true
		if let imageData = UIPasteboard.general.image?.jpegData(compressionQuality: 1.0) {
			document.setBackground(.imageData(imageData), undoManager: undoManager)
		} else if let url = UIPasteboard.general.url?.imageURL {
			document.setBackground(.url(url), undoManager: undoManager)
		} else {
			alertToShow = IdentifiableAlert(
				title: "Paste Background",
				message: "There is no image currently on the pasteboard"
			)
		}
	}
	
	@State var autozoom = false
	
	@State var alertToShow: IdentifiableAlert?
	
	private func showBackgroundImageFetchFailedAlert(_ url: URL) {
		alertToShow = IdentifiableAlert(id: "Fetch Failed, url: " + url.absoluteString) {
			Alert(title: Text("Background Image fetching failed"),
				  message: Text("Can`t upload picture from URL \(url.absoluteString)"),
				  dismissButton: .default(Text("Close"))
			)
		}
	}
	
	
	@ViewBuilder
	func selectionFrame(for emoji: EmojiArtModel.Emoji) -> some View {
		let sideLenght: CGFloat = fontSize(for: emoji) * DrawingConstants.coefficientForFrameLineLenght
		Rectangle()
			.strokeBorder(lineWidth: DrawingConstants.lineWidth)
			.frame(width: sideLenght, height: sideLenght, alignment: .center)
			.foregroundColor(colorScheme == .dark ? .white : .gray)
			.opacity(isEmojiSelected(emoji) ? 1 : 0)
		Image(systemName: "minus.circle.fill")
			.foregroundColor(.red)
			.font(.largeTitle)
			.scaleEffect(1 / zoomScale)
			.offset(x: sideLenght / 2, y: -(sideLenght / 2))
			.opacity(isEmojiSelected(emoji) ? 1 : 0)
			.onTapGesture {
				withAnimation {
					document.deleteEmoji(emoji, undoManager: undoManager)
				}
			}
	}
	
	private struct DrawingConstants {
		static let coefficientForFrameLineLenght: CGFloat = 1.2
		static let lineWidth: CGFloat = 3
		static let scaleForRemoveButton: CGFloat = 5
	}
	
    // MARK: - Selection
	
	private func isEmojiSelected(_ emoji: EmojiArtModel.Emoji) -> Bool {
		!selectedEmoji.filter({ $0.id == emoji.id }).isEmpty
	}
	
	@State private var selectedEmoji = Set<EmojiArtModel.Emoji>()
	
	private func tapOnEmoji(_ emoji: EmojiArtModel.Emoji, geometry: GeometryProxy) -> some Gesture { // delete geometry
		TapGesture()
			.onEnded {
				withAnimation {
					selectedEmoji.toggleMembership(of: emoji)
				}
			}
	}
	
	private func tapOnBackground() -> some Gesture {
		TapGesture()
			.onEnded {
				withAnimation {
					selectedEmoji.removeAll()
				}
			}
	}
	
    // MARK: - Drag and Drop
    
    private func drop(providers: [NSItemProvider], at location: CGPoint, in geometry: GeometryProxy) -> Bool {
        var found = providers.loadObjects(ofType: URL.self) { url in
			autozoom = true
            document.setBackground(.url(url.imageURL), undoManager: undoManager)
        }
        if !found {
            found = providers.loadObjects(ofType: UIImage.self) { image in
                if let data = image.jpegData(compressionQuality: 1.0) {
                    document.setBackground(.imageData(data), undoManager: undoManager)
                }
            }
        }
        if !found {
            found = providers.loadObjects(ofType: String.self) { string in
                if let emoji = string.first, emoji.isEmoji {
                    document.addEmoji(
                        String(emoji),
						at: convertToEmojiCoordinates(forEmoji: nil, location, in: geometry),
                        size: defaultEmojiFontSize / zoomScale,
						undoManager: undoManager
                    )
                }
            }
        }
        return found
    }
    
    // MARK: - Positioning/Sizing Emoji
    
    private func position(for emoji: EmojiArtModel.Emoji, in geometry: GeometryProxy) -> CGPoint {
		convertFromEmojiCoordinates((emoji.x, emoji.y), in: geometry)
    }
    
    private func fontSize(for emoji: EmojiArtModel.Emoji) -> CGFloat {
		CGFloat(emoji.size) * (isEmojiSelected(emoji) ? emojiGestureZoomScale : 1)
    }
    
	private func convertToEmojiCoordinates(forEmoji emoji: EmojiArtModel.Emoji?, _ location: CGPoint, in geometry: GeometryProxy) -> (x: Int, y: Int) {
		var totalOffset = panOffset
		if let _ = emoji, !selectedEmoji.isEmpty {
			totalOffset = panOffset - emojiDragOffset
		}
        let center = geometry.frame(in: .local).center
        let location = CGPoint(
            x: (location.x - totalOffset.width - center.x) / zoomScale,
            y: (location.y - totalOffset.height - center.y) / zoomScale
        )
        return (Int(location.x), Int(location.y))
    }
	
    private func convertFromEmojiCoordinates(_ location: (x: Int, y: Int), in geometry: GeometryProxy) -> CGPoint {
        let center = geometry.frame(in: .local).center
        return CGPoint(
			x: center.x + CGFloat(location.x) * zoomScale + panOffset.width,
            y: center.y + CGFloat(location.y) * zoomScale + panOffset.height
        )
    }
    
    // MARK: - Zooming
    
	@GestureState private var emojiGestureZoomScale: CGFloat = 1
	
    @SceneStorage("EmojiArtDocumentView.steadyStateZoomScale")
	private var steadyStateZoomScale: CGFloat = 1
    @GestureState private var gestureZoomScale: CGFloat = 1
    
    private var zoomScale: CGFloat {
        steadyStateZoomScale * gestureZoomScale
    }
    
    private func zoomGesture() -> some Gesture {
        MagnificationGesture()
			.updating(selectedEmoji.isEmpty ?   $gestureZoomScale : $emojiGestureZoomScale) { latestGestureScale, gestureZoomScale, _ in
					gestureZoomScale = latestGestureScale
            }
            .onEnded { gestureScaleAtEnd in
				if selectedEmoji.isEmpty {
					steadyStateZoomScale *= gestureScaleAtEnd
				} else {
					for emoji in selectedEmoji {
						document.scaleEmoji(emoji, by: gestureScaleAtEnd, undoManager: undoManager)
					}
				}
            }
    }
    
    private func doubleTapToZoom(in size: CGSize) -> some Gesture {
        TapGesture(count: 2)
            .onEnded {
                withAnimation {
                    zoomToFit(document.backgroundImage, in: size)
                }
            }
    }
    
    private func zoomToFit(_ image: UIImage?, in size: CGSize) {
        if let image = image, image.size.width > 0, image.size.height > 0, size.width > 0, size.height > 0  {
            let hZoom = size.width / image.size.width
            let vZoom = size.height / image.size.height
            steadyStatePanOffset = .zero
            steadyStateZoomScale = min(hZoom, vZoom)
        }
    }
	
	// MARK: - Drag emoji
	
	@State var steadyStateEmojiOffset: CGSize = CGSize.zero
	@GestureState var gestureEmojiDragOffset: CGSize = CGSize.zero
	
	var emojiDragOffset: CGSize {
		(steadyStateEmojiOffset + gestureEmojiDragOffset) * zoomScale
	}
	
	private func emojiDragGesture(for emoji: EmojiArtModel.Emoji, in geometry: GeometryProxy) -> some Gesture {
		DragGesture()
			.updating($gestureEmojiDragOffset) { latestDragGestureValue, gestureEmojiDragOffset, _ in
				gestureEmojiDragOffset = latestDragGestureValue.translation / zoomScale
			}
		
			.onEnded { finalDragGestureValue in
				steadyStateEmojiOffset = steadyStateEmojiOffset + (finalDragGestureValue.translation / zoomScale)
				for emoji in selectedEmoji {
					document.moveEmoji(emoji, by: steadyStateEmojiOffset, undoManager: undoManager)
				}
				steadyStateEmojiOffset = CGSize.zero
			}
	}
    // MARK: - Panning whole view
    
	@SceneStorage("EmojiArtDocumentView.steadyStatePanOffset")
	private var steadyStatePanOffset: CGSize = CGSize.zero
	
    @GestureState private var gesturePanOffset: CGSize = CGSize.zero
    
    private var panOffset: CGSize {
        (steadyStatePanOffset + gesturePanOffset) * zoomScale
    }
	
    private func panGesture() -> some Gesture {
		DragGesture()
            .updating($gesturePanOffset) { latestDragGestureValue, gesturePanOffset, _ in
                gesturePanOffset = latestDragGestureValue.translation / zoomScale
            }
            .onEnded { finalDragGestureValue in
                steadyStatePanOffset = steadyStatePanOffset + (finalDragGestureValue.translation / zoomScale)
            }

    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        EmojiArtDocumentView(document: EmojiArtDocument())
    }
}
