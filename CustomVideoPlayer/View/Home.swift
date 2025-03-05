//
//  Home.swift
//  CustomVideoPlayer
//
//  Created by AVINASH IOS Dev on 05/03/25.
//

import SwiftUI
import AVKit

struct Home: View {
    
    var size : CGSize
    var safeArea: EdgeInsets
    ///View Properties
    @State private var player: AVPlayer? = {
        if let bundle = Bundle.main.path(forResource: "Sample Video", ofType: "mp4") {
            return .init(url: URL(filePath: bundle))
    }
        return nil
   }()
    @State private var showPlayerControlls : Bool = false
    @State private var isPlaying : Bool = false
    @State private var timeoutTask : DispatchWorkItem?
    @State private var isFinishedPlaying : Bool = false
        /// Videi Seekar
    @GestureState private var isDragging : Bool = false
    @State private var isSeeking : Bool = false
    @State private var progress : CGFloat = 0
    @State private var lastDraggedProgress : CGFloat = 0
    @State private var isObserverAdded : Bool = false
    @State private var selectedButton: String = "Info"
    @State private var thumbnailFrames : [UIImage] = []
    @State private var draggingImage : UIImage?
    @State private var playerStatusObserver : NSKeyValueObservation?
    @State private var showInsight: Bool = false
    @State private var isRotated : Bool = false
    @State private var showInfo: Bool = true
    @State private var isMuted: Bool = false
    
    var body: some View {
        VStack {
            
            let videoPlayerSize : CGSize = .init(width: isRotated ? size.height : size.width, height: isRotated ? size.width : (size.height/3.5))
            
            ZStack {
                if let player {
                    CustomVideoPlayer(player: player)
                        .overlay {
                            Rectangle()
                                .fill(.black.opacity(0.4))
                                .opacity(showPlayerControlls || isDragging ? 1 : 0)
                                .animation(.easeInOut(duration: 0.35), value: isDragging)
                                .overlay {
                                    PlayerBackControls()
                                }
                        }
                        .overlay(content: {
                            HStack(spacing: 60) {
                                DoubleTapSeek {
                                    let seconds = player.currentTime().seconds - 15
                                    player.seek(to: .init(seconds: seconds, preferredTimescale: 600))
                                }
                                DoubleTapSeek(isForward: true) {
                                    let seconds = player.currentTime().seconds + 15
                                    player.seek(to: .init(seconds: seconds, preferredTimescale: 600))
                                }
                            }
                        })
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.35)) {
                                showPlayerControlls.toggle()
                            }
                            if showPlayerControlls && isPlaying {
                                timeOutControls()
                            }
                        }
                        .overlay(alignment: .bottomLeading, content: {
                            SeekerThumbnailView(videoPlayerSize)
                                .offset(y: isRotated ? -85 : -60)
                        })
                        .overlay(alignment : .bottom) {
                            videoSeekerView(videoPlayerSize)
                                .offset(y: isRotated ? -15 : 0)
                        }
                    VStack {
                        HStack {
                            Spacer()
                            Button(action: {
                                isMuted.toggle()
                                player.isMuted = isMuted
                            }) {
                                Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .padding(10)
                                    .background(Circle().fill(Color.black.opacity(0.5)))
                                    .padding(.trailing, 15)
                                    .padding(.top, 10)
                            }
                        }
                        Spacer()
                    }
                }
            }
            .background(content: {
                Rectangle()
                    .fill(.black)
                    .padding(.trailing, isRotated ? -safeArea.bottom : 0)
            })
            .gesture(
                
                DragGesture()
                    .onEnded { value in
                        if -value.translation.height > 100 {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isRotated = true
                            }
                        }else {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isRotated = false
                            }
                        }
                    }
            )
            .frame(width: videoPlayerSize.width ,height: videoPlayerSize.height)
            .frame(width: size.width ,height: size.height / 3.5 , alignment: .bottomLeading)
            .offset(y : isRotated ? -((size.width / 2) + safeArea.bottom) : 0)
            .rotationEffect(.init(degrees: isRotated ? 90 : 0) , anchor: .topLeading)
            .zIndex(10000)
            metadataSection
            Spacer()
        }
        .padding(.top , safeArea.top)
        .onAppear {
            guard !isObserverAdded else { return }
            player?.addPeriodicTimeObserver(forInterval: .init(seconds: 1, preferredTimescale: 1), queue: .main, using: { time in
                if let currentPlayerItem = player?.currentItem {
                    let totalDuration = currentPlayerItem.duration.seconds
                    guard let currentDuration = player?.currentTime().seconds else { return }
                    let calculatedProgress = currentDuration / totalDuration
                    if !isSeeking {
                        progress = calculatedProgress
                        lastDraggedProgress = progress
                    }
                    if calculatedProgress == 1 {
                        isFinishedPlaying = true
                        isPlaying = false
                    }
                }
            })
            isObserverAdded = true
            playerStatusObserver = player?.observe(\.status, options: .new, changeHandler: { player, _ in
                if player.status == .readyToPlay {
                    generateThumbnailFrames()
                }
            })
        }
        .onDisappear {
            playerStatusObserver?.invalidate()
        }
    }
    
    //MARK: Details
    private var metadataSection: some View {
        VStack {
            HStack(spacing: 10) {
                Button(action: {
                    selectedButton = "Info"
                    showInsight = false
                    showInfo.toggle()
                }) {
                    Text("Info").buttonStyle(selectedButton == "Info")
                }
                Button(action: {
                    selectedButton = "Insight"
                    showInfo = false
                    showInsight = true
                }) {
                    Text("Insight").buttonStyle(selectedButton == "Insight")
                }
                Button(action: {
                    selectedButton = "Continue Watching"
                    showInfo = false
                    showInsight = false
                }) {
                    Text("Continue Watching").buttonStyle(selectedButton == "Continue Watching")
                }
            }
            .padding(.horizontal, 15)
            .frame(maxWidth: .infinity, alignment: .leading)
            
            if showInfo {
                videoInfo
            }
            if showInsight {
                insightSection
            }
        }
    }
    
    private var insightSection: some View {
        VStack(spacing: 10) {
            Text("Inside This Scene")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
            Text("When available, Insight will show you information about actors or music in a scene.")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
    private var videoInfo: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Elephants Dream")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            Text("Elephants Dream is a surreal animated short where Emo and Proog explore a vast mechanical world, facing conflicts that challenge their perceptions.")
                .font(.subheadline)
                .foregroundColor(.white)
            Text("Sci-Fi 1hr 5min")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            HStack(spacing: 20) {
                Button(action: {
                    player?.seek(to: .zero)
                   player?.play()
                }) {
                    HStack {
                        Image(systemName: "pause.fill")
                            .foregroundColor(.white)
                        Text("from Beginning")
                            .foregroundColor(.white)
                    }
                    .padding(8)
                    .background(Color.blue)
                    .cornerRadius(10)
                }
                
                Button(action: { print("Details Button Clicked") }) {
                    Text("Details").buttonStyle(false)
                }
            }
        }
        .padding()
        .background(Color.black.opacity(0.8))
        .cornerRadius(10)
    }
    @ViewBuilder func SeekerThumbnailView(_ videoSize : CGSize) -> some View {
        let thumbSize : CGSize = .init(width: 175, height: 100)
        ZStack {
            if let draggingImage {
                Image(uiImage: draggingImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: thumbSize.width , height: thumbSize.height)
                    .clipShape(RoundedRectangle(cornerRadius: 15,style: .continuous))
                    .overlay(alignment: .bottom, content: {
                    })
                    .overlay {
                        RoundedRectangle(cornerRadius: 15, style: .continuous)
                            .stroke(.white , lineWidth: 2)
                    }
            } else {
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .fill(.black)
                    .overlay {
                        RoundedRectangle(cornerRadius: 15, style: .continuous)
                            .stroke(.white , lineWidth: 2)
                    }
            }
        }
        .frame(width: thumbSize.width , height: thumbSize.height)
        .opacity(isDragging ? 1 : 0)
        .offset(x : progress * (videoSize.width - thumbSize.width - 20))
        .offset(x: 10)
    }
    
    
    @ViewBuilder func videoSeekerView(_ videoSize :CGSize) -> some View {
        ZStack (alignment : .leading){
          Rectangle()
                .fill(.gray)
            Rectangle()
                .fill(.red)
                .frame(width: max(videoSize.width * progress , 0))
            
        }.frame(height: 3)
            .overlay(alignment : .leading){
                Circle()
                    .fill(.red)
                    .frame(width: 15 , height: 15)
                    .scaleEffect(showPlayerControlls || isDragging ? 1 : 0.001, anchor: progress * videoSize.width > 15 ? .trailing : .leading)
                
                    .frame(width: 50 , height: 50)
                    .contentShape(Rectangle())
                    .offset(x: videoSize.width * progress)
                    .gesture(
                    DragGesture()
                        .updating($isDragging, body: { _, out, _ in
                        out = true
                        })
                        .onChanged({value in
                            if let timeoutTask {
                                timeoutTask.cancel()
                            }
                            let translationX: CGFloat = value.translation.width
                            let calculatedProgress = (translationX / videoSize.width)
                            
                            progress = max(min(calculatedProgress , 1 ),0)
                            isSeeking = true
                            let dragIndex = Int(progress / 0.01)
                            if thumbnailFrames.indices.contains(dragIndex) {
                                draggingImage = thumbnailFrames[dragIndex]
                            }
                        })
                        .onEnded({ value in
                            lastDraggedProgress = progress
                            
                            if let currentPlayerItem = player?.currentItem {
                                let totalDuration = currentPlayerItem.duration.seconds
                                
                                player?.seek(to: .init(seconds: totalDuration * progress, preferredTimescale: 600))
                                
                                if isPlaying {
                                    timeOutControls()
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                    isSeeking = false
                                }
                            }
                        })
                    )
                    .offset(x : progress * videoSize.width > 15 ? -15 : 0)
                    .frame(width: 15,height: 15)
                
            }
    }
    
    
    @ViewBuilder func PlayerBackControls() -> some View {
        HStack(spacing: 20) {
            Button {
                
            } label: {
                 Image(systemName: "backward.end.fill")
                    .font(.title2)
                    .fontWeight(.ultraLight)
                    .foregroundColor(.white)
                    .padding(15)
                    .background {
                        Circle()
                            .fill(.black.opacity(0.35))
                    }
            }
            .disabled(true)
            .opacity(0.6)
            Button {
                if isFinishedPlaying {
                    isFinishedPlaying = false
                    player?.seek(to: .zero)
                    progress = .zero
                    lastDraggedProgress = .zero
                }
                
                if isPlaying {
                    player?.pause()
                    if let timeoutTask {
                        timeoutTask.cancel()
                    }
                }else {
                    player?.play()
                    timeOutControls()
                }
                
                withAnimation(.easeInOut(duration: 0.2)) {
                    isPlaying.toggle()
                }
            } label: {
                
                Image(systemName: isFinishedPlaying  ? "arrow.clockwise" : (isPlaying ? "pause.fill" : "play.fill"))
                    .font(.title)
                    .foregroundColor(.white)
                    .padding(15)
                    .background {
                        Circle()
                            .fill(.black.opacity(0.35))
                    }
            }
            .scaleEffect(1.1)
            
            Button {
                
            } label: {
                 Image(systemName: "forward.end.fill")
                    .font(.title2)
                    .fontWeight(.ultraLight)
                    .foregroundColor(.white)
                    .padding(15)
                    .background {
                        Circle()
                            .fill(.black.opacity(0.35))
                    }
            }
            .disabled(true)
            .opacity(0.6)
        }
        .opacity(showPlayerControlls ? 1 : 0)
        .animation(.easeInOut(duration: 0.2),value: showPlayerControlls && !isDragging)
    }
    func timeOutControls() {
        timeoutTask?.cancel()
        
        timeoutTask = DispatchWorkItem {
            withAnimation(.easeInOut(duration: 0.35)) {
                showPlayerControlls = false
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: timeoutTask!)
    }

    func generateThumbnailFrames() {
        Task.detached {
            guard let asset = player?.currentItem?.asset else {return}
            let generator = AVAssetImageGenerator(asset: asset)
            generator.appliesPreferredTrackTransform = true
            generator.maximumSize = .init(width : 250, height: 250)
            
            do {
                let totalDuration = try await asset.load(.duration).seconds
                var frameTime : [CMTime] = []
                for progress in stride(from: 0, through: 1, by: 0.01) {
                    let time = CMTime(seconds: progress * totalDuration, preferredTimescale: 600)
                    frameTime.append(time)
                }
                
                for await result in generator.images(for: frameTime) {
                    let cgImage = try result.image
                    
                    await MainActor.run {
                        thumbnailFrames.append(UIImage(cgImage: cgImage))
                    }
                }
                
            } catch {
                print(error.localizedDescription)
            }
            
            
        }
    }
}

extension View {
    func buttonStyle(_ isSelected: Bool) -> some View {
        self
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(isSelected ? Color.white : Color.gray.opacity(0.2))
            .foregroundColor(isSelected ? .black : .white)
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white, lineWidth: 2))
    }
}
