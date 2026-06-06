import SwiftData
import SwiftUI

struct VoiceCoachView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.modelContext) private var modelContext
    @StateObject private var speech = SpeechRecognitionService()
    @StateObject private var waveform = WaveformAnimationManager()
    @State private var editableTranscript = ""
    @State private var aiResponse = ""
    @State private var isGenerating = false

    var body: some View {
        ZStack {
            ObsidianBackground()
            ScrollView {
                VStack(spacing: 18) {
                    GlassPanel {
                        VStack(spacing: 14) {
                            Text("Voice Health Coach")
                                .font(.title2.weight(.semibold))
                            VoiceWaveformView(levels: waveform.levels, active: speech.isRecording)
                            Button {
                                toggleRecording()
                            } label: {
                                Image(systemName: speech.isRecording ? "stop.fill" : "mic.fill")
                                    .font(.title2)
                                    .frame(width: 64, height: 64)
                                    .background(speech.isRecording ? .red.opacity(0.22) : .electricBlue.opacity(0.22), in: Circle())
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    GlassPanel {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Live Transcript")
                                .font(.headline)
                            TextEditor(text: $editableTranscript)
                                .frame(minHeight: 130)
                                .scrollContentBackground(.hidden)
                                .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 8))
                        }
                    }

                    if isGenerating {
                        ProgressView("Generating wellness response...")
                            .tint(Color.electricBlue)
                    }

                    if !aiResponse.isEmpty {
                        GlassPanel {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("AI Response")
                                    .font(.headline)
                                Text(aiResponse)
                                    .foregroundStyle(Color.softText)
                            }
                        }
                    }

                    PrimaryButton(title: "Generate Response", systemImage: "sparkles") {
                        Task { await generateResponse() }
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle("Coach")
        .task { await speech.requestPermissions() }
        .onChange(of: speech.transcript) { _, newValue in
            editableTranscript = newValue
        }
        .onReceive(Timer.publish(every: 0.18, on: .main, in: .common).autoconnect()) { _ in
            waveform.tick(active: speech.isRecording)
        }
    }

    private func toggleRecording() {
        if speech.isRecording {
            speech.stop()
        } else {
            speech.start()
        }
    }

    private func generateResponse() async {
        guard !editableTranscript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        isGenerating = true
        aiResponse = (try? await appState.aiService.generateVoiceResponse(transcript: editableTranscript)) ?? "I could not generate a response right now. Try again in a moment."
        modelContext.insert(VoiceTranscript(transcript: editableTranscript, aiResponse: aiResponse))
        isGenerating = false
    }
}
