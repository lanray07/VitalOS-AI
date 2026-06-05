import AVFoundation
import Foundation
import Speech
import SwiftUI

@MainActor
final class SpeechRecognitionService: NSObject, ObservableObject {
    @Published var transcript = ""
    @Published var isRecording = false
    @Published var errorMessage: String?

    private let recognizer = SFSpeechRecognizer()
    private let audioEngine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?

    func requestPermissions() async {
        _ = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { _ in continuation.resume(returning: ()) }
        }
        _ = await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    func start() {
        transcript = ""
        request = SFSpeechAudioBufferRecognitionRequest()
        guard let request else { return }
        let input = audioEngine.inputNode
        let format = input.outputFormat(forBus: 0)
        input.removeTap(onBus: 0)
        input.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            request.append(buffer)
        }
        audioEngine.prepare()
        do {
            try audioEngine.start()
            isRecording = true
            task = recognizer?.recognitionTask(with: request) { [weak self] result, error in
                Task { @MainActor in
                    if let result {
                        self?.transcript = result.bestTranscription.formattedString
                    }
                    if error != nil {
                        self?.stop()
                    }
                }
            }
        } catch {
            errorMessage = "Voice capture could not start."
        }
    }

    func stop() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        task?.cancel()
        isRecording = false
    }
}

final class VoiceRecordingService {
    func configureSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .measurement, options: .duckOthers)
        try session.setActive(true, options: .notifyOthersOnDeactivation)
    }
}

@MainActor
final class WaveformAnimationManager: ObservableObject {
    @Published var levels: [CGFloat] = Array(repeating: 0.2, count: 28)

    func tick(active: Bool) {
        levels = levels.indices.map { index in
            active ? CGFloat.random(in: 0.18...1.0) * (index.isMultiple(of: 3) ? 0.85 : 1) : 0.18
        }
    }
}
