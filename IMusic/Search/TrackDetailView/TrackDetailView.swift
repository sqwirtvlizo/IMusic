//
//  TableDetailView.swift
//  IMusic
//
//  Created by Евгений Кононенко on 10.11.2022.
//  Copyright © 2022 Алексей Пархоменко. All rights reserved.
//

import UIKit
import SDWebImage
import AVKit
import MediaPlayer

protocol TrackMovingDelegate {
    func movePrevious() -> SearchViewModel.Cell?
    func moveNext() -> SearchViewModel.Cell?
}

class TrackDetailView: UIView {
    
    @IBOutlet weak var iconMaxVolume: UIImageView!
    @IBOutlet weak var iconMinVolume: UIImageView!
    @IBOutlet weak var miniPlayPauseButton: UIButton!
    @IBOutlet weak var miniTrackTitleLabel: UILabel!
    @IBOutlet weak var miniTrackImageView: UIImageView!
    @IBOutlet weak var maximizedStackView: UIStackView!
    @IBOutlet weak var miniGoForwardButton: UIButton!
    @IBOutlet weak var miniTrackView: UIView!
    @IBOutlet weak var trackImageView: UIImageView!
    @IBOutlet weak var currentTimeSlider: UISlider!
    @IBOutlet weak var currentTimeLabel: UILabel!
    @IBOutlet weak var durationTimeLabel: UILabel!
    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var nextTrackButton: UIButton!
    @IBOutlet weak var backTrackButton: UIButton!
    @IBOutlet weak var volumeSlider: UISlider!
    
    var delegate: TrackMovingDelegate?
    weak var tabBarDelegate: MainTabBarControllerDelegate?
    private let commandCenter = MPRemoteCommandCenter.shared()
    
    private let scale = 0.8
    let player: AVPlayer = {
        let pl = AVPlayer()
        pl.automaticallyWaitsToMinimizeStalling = false
        return pl
    }()
    
    override func awakeFromNib() {
        super.awakeFromNib()
       
        setupGesture()
        setupRemoteTransportControls()
        setForVisualView()
        iconMinVolume.tintColor = .lightGray
        iconMaxVolume.tintColor = .black
    }
    
    private func setForVisualView() {
        trackImageView.transform = CGAffineTransform(scaleX: scale, y: scale)
        trackImageView.layer.cornerRadius = 5
        trackImageView.layer.shadowOffset = CGSize(width: 0, height: 0)
        trackImageView.layer.shadowRadius = 15
        trackImageView.layer.shadowColor = UIColor.black.cgColor
        trackImageView.layer.shadowOpacity = 15
        miniPlayPauseButton.imageEdgeInsets = .init(top: 9, left: 9, bottom: 9, right: 9)
        currentTimeSlider.transform = CGAffineTransform(translationX: 0.5, y: 0.5)
        currentTimeSlider.setThumbImage(#imageLiteral(resourceName: "Knob"), for: .normal)
    }
    
    private func playTrack(previewURL: String?) {
        self.player.automaticallyWaitsToMinimizeStalling = false
        guard let url = URL(string: previewURL ?? "") else { return }
        let playerItem = AVPlayerItem(url: url)
        self.player.replaceCurrentItem(with: playerItem)
        self.player.play()
    }
    
    func set(viewModel: SearchViewModel.Cell) {
        let str600 = viewModel.iconUrlString?.replacingOccurrences(of: "100x100", with: "600x600")
        guard let url = URL(string: str600 ?? "") else { return }
        miniTrackImageView.sd_setImage(with: url)
        var audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSession.Category.playback)
            try audioSession.setActive(true)
        } catch _ {
            
        }
        miniTrackTitleLabel.text = viewModel.trackName
        titleLabel.text = viewModel.trackName
        authorLabel.text = viewModel.artistName
        playTrack(previewURL: viewModel.previewUrl)
        observePlayerCurrentTime()
        monitorStartTime(viewModel: viewModel)
        playPauseButton.setImage(UIImage(systemName: "pause") , for: .normal)
        miniPlayPauseButton.setImage(UIImage(systemName: "pause") , for: .normal)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [self] in
            setupNowPlaying(viewModel: viewModel,photo: miniTrackImageView.image)
        }
        trackImageView.sd_setImage(with: url)
    }
    
    // MARK: Set image sizes
    private func enlargeImageTrackView() {
        UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 1, options: .curveEaseInOut) {
            self.trackImageView.transform = .identity
        }
    }
    
    private func reduceImageTrackView() {
        UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 1, options: .curveEaseInOut) {
            self.trackImageView.transform = CGAffineTransform(scaleX: self.scale, y: self.scale)
        }
    }
    
    // MARK: Set recognizes for view
    private func setupGesture() {
        miniTrackView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTapMaximized)))
        miniTrackView.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(handlePan)))
        addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(handleDismissalPan)))
    }
    
    @objc
    private func handleDismissalPan(gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .changed:
            handleDismissalPanChange(gesture: gesture)
        case .ended:
            handleDismissalPanEnd(gesture: gesture)
        @unknown default:
            print("default")
        }
    }
    
    @objc
    private func  handleDismissalPanChange(gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: self.superview)
        maximizedStackView.transform = CGAffineTransform(translationX: 0, y: translation.y)
    }
    
    @objc
    private func  handleDismissalPanEnd(gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: self.superview)
        let velocity = gesture.velocity(in: self.superview)
        
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
            self.transform = .identity
            if translation.y > 50 {
                self.tabBarDelegate?.minimizeTrackDetailController()
                self.maximizedStackView.transform = .identity
            }
        }, completion: nil)
    }
    
    @objc
    private func handlePan(gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .began:
            print("Began")
        case .changed:
            handlePanChanged(gesture: gesture)
        case .ended:
            handlePanEnded(gesture: gesture)
        @unknown default:
            print("unknown default")
        }
    }
    
    private func handlePanChanged(gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: self.superview)
        self.transform = CGAffineTransform(translationX: 0, y: translation.y)
        
        let newAlpha = 1 + translation.y / 200
        self.miniTrackView.alpha = newAlpha < 0 ? 0 : newAlpha
        self.maximizedStackView.alpha = -translation.y / 200
    }
    
    private func handlePanEnded(gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: self.superview)
        let velocity = gesture.velocity(in: self.superview)
        
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
            self.transform = .identity
            if translation.y < -200 || velocity.y < -500 {
                self.tabBarDelegate?.maximizeTrackDetailController(viewModel: nil)
            } else {
                self.miniTrackView.alpha = 1
                self.maximizedStackView.alpha = 0
            }
        }, completion: nil)
    }
    
    @objc
    private func handleTapMaximized() {
        self.tabBarDelegate?.maximizeTrackDetailController(viewModel: nil)
    }
    
    // MARK: Monitor start time
    private func monitorStartTime(viewModel: SearchViewModel.Cell) {
        let time = CMTimeMake(value: 1, timescale: 3)
        let times = [NSValue(time: time)]
        
        player.addBoundaryTimeObserver(forTimes: times, queue: .main) { [weak self] in
            self?.enlargeImageTrackView()
        }
    }
    
    // MARK: Drag and down button handler
    @IBAction func dragDownButtonTapped(_ sender: Any) {
        tabBarDelegate?.minimizeTrackDetailController()
    }
    
    // MARK: Play/Pause handler
    @IBAction func playPauseTapped(_ sender: UIButton) {
        if player.timeControlStatus == .paused {
            player.play()
            sender.setImage(UIImage(systemName: "pause"), for: .normal)
            enlargeImageTrackView()
        } else {
            player.pause()
            sender.setImage(UIImage(systemName: "play"), for: .normal)
            reduceImageTrackView()
        }
    }
    
    private func observePlayerCurrentTime() {
        let interval = CMTimeMake(value: 1, timescale: 2)
        player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            self?.currentTimeLabel.text = time.toDisplayString()
            let durationTime = self?.player.currentItem?.duration
            let currentDurationTime = ((durationTime ?? CMTimeMake(value: 1, timescale: 1)) - time).toDisplayString()
            self?.durationTimeLabel.text = "-\(currentDurationTime)"
            self?.updateCurrentTimeSlider()
        }
    }
    
    private func updateCurrentTimeSlider() {
        let currentTimeSeconds = CMTimeGetSeconds(player.currentTime())
        let durationSeconds = CMTimeGetSeconds(player.currentItem?.duration ?? CMTimeMake(value: 1, timescale: 1))
        let percentage = currentTimeSeconds / durationSeconds
        self.currentTimeSlider.value = Float(percentage)
    }
    
    // MARK: Next track handler
    @IBAction func nextTrackTapped(_ sender: Any) {
        let cellViewModel = delegate?.moveNext()
        guard let cellInfo = cellViewModel else { return }
        self.set(viewModel: cellInfo)
    }
    
    
    // MARK: Previous track handler
    @IBAction func previousTrackTapped(_ sender: Any) {
        let cellViewModel = delegate?.movePrevious()
        guard let cellInfo = cellViewModel else { return }
        self.set(viewModel: cellInfo)
    }
    
    // MARK: Volume slider handler
    @IBAction func handleVolumeSlider(_ sender: Any) {
        player.volume = volumeSlider.value
        if volumeSlider.value == 1 {
            iconMaxVolume.tintColor = .black
        } else if volumeSlider.value == 0 {
            iconMinVolume.tintColor = .black
        } else {
            iconMinVolume.tintColor = .lightGray
            iconMaxVolume.tintColor = .lightGray
        }
    }
    
    // MARK: Time slider handler
    @IBAction func handleCurrentTimerSlider(_ sender: Any) {
        let percentage = Float64(currentTimeSlider.value)
        guard let duration = player.currentItem?.duration else { return }
        let durationSeconds = CMTimeGetSeconds(duration)
        let seekTimeSeconds = durationSeconds * percentage
        let seekTime = CMTimeMakeWithSeconds(seekTimeSeconds, preferredTimescale: 1)
        player.seek(to: seekTime)
    }
    
    
    // MARK: settings remoteControllers
    func setupRemoteTransportControls() {
        commandCenter.playCommand.addTarget { [weak self] (event) -> MPRemoteCommandHandlerStatus in
            self?.player.play()
            self?.playPauseButton.setImage(UIImage(named: "pause") , for: .normal)
            self?.miniPlayPauseButton.setImage(UIImage(named: "pause") , for: .normal)
            return .success
        }
        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] (event) -> MPRemoteCommandHandlerStatus in
            guard let positionEvent = event as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }
            let seekTime = CMTimeMakeWithSeconds(positionEvent.positionTime, preferredTimescale: 1)
            self?.player.seek(to: seekTime)
            return .success
        }
        commandCenter.pauseCommand.addTarget { [weak self] (event) -> MPRemoteCommandHandlerStatus in
            self?.player.pause()
         
            self?.playPauseButton.setImage(UIImage(named: "play") , for: .normal)
            self?.miniPlayPauseButton.setImage(UIImage(named: "play") , for: .normal)
            return .success
        }
        commandCenter.previousTrackCommand.addTarget { [weak self] (event) -> MPRemoteCommandHandlerStatus in
            self?.previousTrackTapped(self?.nextTrackButton)
            return .success
        }
        commandCenter.nextTrackCommand.addTarget { [weak self] (event) -> MPRemoteCommandHandlerStatus in
            self?.nextTrackTapped(self?.nextTrackButton)
            return .success
        }
    }
    
    func setupNowPlaying(viewModel: SearchViewModel.Cell, photo: UIImage? = nil) {
        var nowPlayingInfo = [String : Any]()
        nowPlayingInfo[MPMediaItemPropertyTitle] = viewModel.trackName
        nowPlayingInfo[MPMediaItemPropertyArtist] = viewModel.artistName
        nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = viewModel.collectionName
        if let photo = photo {
            nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: photo.size, requestHandler: { _  in
                photo
            })
        }
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = player.currentTime().seconds
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = player.currentItem!.asset.duration.seconds
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = player.rate
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
}
