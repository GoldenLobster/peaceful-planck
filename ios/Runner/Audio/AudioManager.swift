import AVFoundation
import MediaPlayer
import Flutter

class AudioManager: NSObject {
    static let shared = AudioManager()
    
    private var player: AVPlayer?
    private var playerItem: AVPlayerItem?
    
    private var eventSink: FlutterEventSink?
    private var timeObserver: Any?
    
    private var kvoStatusToken: NSKeyValueObservation?
    private var kvoBufferToken: NSKeyValueObservation?
    private var kvoPlaybackBufferEmptyToken: NSKeyValueObservation?
    private var kvoPlaybackLikelyToKeepUpToken: NSKeyValueObservation?
    
    override private init() {
        super.init()
        setupAudioSession()
        setupRemoteCommands()
    }
    
    func setupChannels(messenger: FlutterBinaryMessenger) {
        let methodChannel = FlutterMethodChannel(name: "com.ytmultimate/audio", binaryMessenger: messenger)
        methodChannel.setMethodCallHandler { [weak self] call, result in
            self?.handleMethodCall(call, result: result)
        }
        
        let eventChannel = FlutterEventChannel(name: "com.ytmultimate/audioEvents", binaryMessenger: messenger)
        eventChannel.setStreamHandler(self)
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set audio session category. Error: \(error)")
        }
    }
    
    private func handleMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "play":
            guard let args = call.arguments as? [String: Any],
                  let urlString = args["url"] as? String,
                  let url = URL(string: urlString) else {
                result(FlutterError(code: "INVALID_ARGS", message: "Missing URL", details: nil))
                return
            }
            let title = args["title"] as? String ?? ""
            let artist = args["artist"] as? String ?? ""
            let artworkUrl = args["artworkUrl"] as? String
            
            play(url: url, title: title, artist: artist, artworkUrl: artworkUrl)
            result(true)
            
        case "pause":
            pause()
            result(true)
            
        case "resume":
            resume()
            result(true)
            
        case "seek":
            if let args = call.arguments as? [String: Any], let pos = args["position"] as? Double {
                seek(to: pos)
            }
            result(true)
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    func play(url: URL, title: String, artist: String, artworkUrl: String?) {
        if let currentItem = playerItem {
            NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: currentItem)
            kvoStatusToken?.invalidate()
            kvoBufferToken?.invalidate()
            kvoPlaybackBufferEmptyToken?.invalidate()
            kvoPlaybackLikelyToKeepUpToken?.invalidate()
        }
        
        let options = ["AVURLAssetHTTPHeaderFieldsKey": ["User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"]]
        let asset = AVURLAsset(url: url, options: options)
        playerItem = AVPlayerItem(asset: asset)
        
        kvoStatusToken = playerItem?.observe(\.status, options: [.new]) { [weak self] item, _ in
            if item.status == .failed {
                self?.sendStateUpdate(state: "error", reason: item.error?.localizedDescription)
            }
        }
        
        kvoBufferToken = playerItem?.observe(\.loadedTimeRanges, options: [.new]) { [weak self] item, _ in
            if let timeRange = item.loadedTimeRanges.first?.timeRangeValue {
                let bufferedTime = timeRange.start.seconds + timeRange.duration.seconds
                if !bufferedTime.isNaN {
                    self?.eventSink?(["type": "buffer", "buffered": bufferedTime])
                }
            }
        }
        
        kvoPlaybackBufferEmptyToken = playerItem?.observe(\.isPlaybackBufferEmpty, options: [.new]) { [weak self] item, _ in
            if item.isPlaybackBufferEmpty {
                self?.sendStateUpdate(state: "buffering")
            }
        }
        
        kvoPlaybackLikelyToKeepUpToken = playerItem?.observe(\.isPlaybackLikelyToKeepUp, options: [.new]) { [weak self] item, _ in
            if item.isPlaybackLikelyToKeepUp && self?.player?.rate != 0 {
                self?.sendStateUpdate(state: "playing")
            }
        }
        
        if player == nil {
            player = AVPlayer(playerItem: playerItem)
            addTimeObserver()
        } else {
            player?.replaceCurrentItem(with: playerItem)
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(playerDidFinishPlaying), name: .AVPlayerItemDidPlayToEndTime, object: playerItem)
        
        player?.volume = 1.0
        player?.play()
        updateNowPlayingInfo(title: title, artist: artist, artworkUrl: artworkUrl)
        sendStateUpdate(state: "playing")
    }
    
    func pause() {
        player?.pause()
        sendStateUpdate(state: "paused")
    }
    
    func resume() {
        player?.play()
        sendStateUpdate(state: "playing")
    }
    
    func seek(to seconds: Double) {
        player?.seek(to: CMTime(seconds: seconds, preferredTimescale: 1000))
    }
    
    @objc private func playerDidFinishPlaying() {
        sendStateUpdate(state: "completed")
    }
    
    private func addTimeObserver() {
        let interval = CMTime(seconds: 1.0, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            self?.sendPositionUpdate()
        }
    }
    
    private func sendStateUpdate(state: String, reason: String? = nil) {
        var event: [String: Any] = ["type": "state", "value": state]
        if let r = reason {
            event["reason"] = r
        }
        eventSink?(event)
    }
    
    private func sendPositionUpdate() {
        guard let player = player, let currentItem = player.currentItem else { return }
        let duration = currentItem.duration.seconds
        let position = player.currentTime().seconds
        
        if !duration.isNaN && !position.isNaN {
            eventSink?(["type": "position", "position": position, "duration": duration])
        }
    }
    
    private func updateNowPlayingInfo(title: String, artist: String, artworkUrl: String?) {
        var nowPlayingInfo = [String: Any]()
        nowPlayingInfo[MPMediaItemPropertyTitle] = title
        nowPlayingInfo[MPMediaItemPropertyArtist] = artist
        
        if let artworkUrlString = artworkUrl, let url = URL(string: artworkUrlString) {
            URLSession.shared.dataTask(with: url) { data, _, _ in
                if let data = data, let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        let artwork = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
                        nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
                        
                        if let currentItem = self.player?.currentItem {
                            nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = currentItem.duration.seconds
                            nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = self.player?.currentTime().seconds
                            nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = self.player?.rate
                        }
                        
                        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
                    }
                }
            }.resume()
        } else {
            if let currentItem = player?.currentItem {
                nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = currentItem.duration.seconds
                nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = player?.currentTime().seconds
                nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = player?.rate
            }
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        }
    }
    
    private func setupRemoteCommands() {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        commandCenter.playCommand.addTarget { [weak self] event in
            self?.resume()
            return .success
        }
        
        commandCenter.pauseCommand.addTarget { [weak self] event in
            self?.pause()
            return .success
        }
        
        commandCenter.nextTrackCommand.addTarget { [weak self] event in
            self?.eventSink?(["type": "command", "value": "next"])
            return .success
        }
        
        commandCenter.previousTrackCommand.addTarget { [weak self] event in
            self?.eventSink?(["type": "command", "value": "previous"])
            return .success
        }
    }
}

extension AudioManager: FlutterStreamHandler {
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        return nil
    }
    
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        return nil
    }
}
