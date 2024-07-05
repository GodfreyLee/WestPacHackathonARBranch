import SwiftUI
import RealityKit
import ARKit
import AVFoundation

struct ContentView: View {
    @State private var showAlert = false

    var body: some View {
        ARViewContainer(showAlert: $showAlert)
            .edgesIgnoringSafeArea(.all)
    }
}

struct ARViewContainer: UIViewRepresentable {
    @Binding var showAlert: Bool

    class Coordinator: NSObject {
        var parent: ARViewContainer
        var textEntity: ModelEntity?
        var messageIndex = 0
        var audioPlayer: AVAudioPlayer?

        init(parent: ARViewContainer) {
            self.parent = parent
            super.init()
            playBackgroundMusic()
        }

        func playBackgroundMusic() {
            guard let path = Bundle.main.path(forResource: "combined_speech.mp3", ofType: nil) else {
                print("Audio file not found")
                return
            }
            let url = URL(fileURLWithPath: path)

            do {
                audioPlayer = try AVAudioPlayer(contentsOf: url)
                audioPlayer?.numberOfLoops = -1 // Loop indefinitely
                audioPlayer?.play()
                print("Background music playing")
            } catch {
                print("Error playing background music: \(error)")
            }
        }

        @objc func handleTap(recognizer: UITapGestureRecognizer) {
            guard let arView = recognizer.view as? ARView else { return }
            let location = recognizer.location(in: arView)
            print("Tap location: \(location)")

            // Update the text of the textEntity if it exists
            if let textEntity = textEntity {
                let messages = ["Hi, How can I help you today?", "Do you want to transfer $500 to Peter?", "Transaction done","Transaction done","Thanks for choosing WestPac. Have a nice one."]
                let newMessage = messages[messageIndex % messages.count]
                let newTextMesh = MeshResource.generateText(
                    newMessage,
                    extrusionDepth: 0.02,
                    font: .systemFont(ofSize: 0.1),
                    containerFrame: .zero,
                    alignment: .center,
                    lineBreakMode: .byWordWrapping
                )
                textEntity.model = ModelComponent(mesh: newTextMesh, materials: textEntity.model!.materials)
                textEntity.transform.translation = SIMD3<Float>(0.3, 0.8, -0.2) // Adjust the position if needed
                
                // Increment messageIndex to toggle messages on next tap
                messageIndex += 1
            } else {
                print("Text entity not found")
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)

        // Configure AR session
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal]
        arView.session.run(configuration)

        // Add debug options
        arView.debugOptions = [.showFeaturePoints, .showWorldOrigin, .showAnchorGeometry]

        // Load the custom 3D models
        guard let receptionDeskModel = try? ModelEntity.loadModel(named: "reception_desk") else {
            fatalError("Failed to load the reception desk model.")
        }

        guard let receptionistModel = try? ModelEntity.loadModel(named: "receptionist") else {
            fatalError("Failed to load the receptionist model.")
        }

        // Configure and position the models
        receptionDeskModel.transform.translation = SIMD3<Float>(0, 0, -0.5) // Adjust the position as needed
        receptionDeskModel.name = "receptionDesk" // Assign a unique name to the model

        receptionistModel.transform.translation = SIMD3<Float>(0.5, 0, -0.5) // Adjust the position as needed
        receptionistModel.name = "receptionist" // Assign a unique name to the model

        // Create and add a text entity at a predefined location
        let textEntity = createTextEntity(text: "Welcome to WestPac VR branch!", at: SIMD3<Float>(0.3, 0.8, -0.2))
        context.coordinator.textEntity = textEntity
        
        // Create horizontal plane anchor for the content
        let anchor = AnchorEntity(plane: .horizontal, minimumBounds: [0.2, 0.2])
        anchor.addChild(receptionDeskModel)
        anchor.addChild(receptionistModel)
        anchor.addChild(textEntity)

        // Add the horizontal plane anchor to the scene
        arView.scene.addAnchor(anchor)

        // Add a directional light
        let lightEntity = Entity()
        let light = DirectionalLightComponent(color: .white, intensity: 1000)
        lightEntity.components[DirectionalLightComponent.self] = light
        lightEntity.transform.rotation = simd_quatf(angle: -.pi / 4, axis: [1, 0, 0])
        anchor.addChild(lightEntity)

        // Add tap gesture recognizer
        let tapRecognizer = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(recognizer:)))
        arView.addGestureRecognizer(tapRecognizer)

        return arView
    }

    func createTextEntity(text: String, at position: SIMD3<Float>) -> ModelEntity {
        let textMesh = MeshResource.generateText(
            text,
            extrusionDepth: 0.02,
            font: .systemFont(ofSize: 0.1),
            containerFrame: .zero,
            alignment: .center,
            lineBreakMode: .byWordWrapping
        )

        let material = SimpleMaterial(color: .white, isMetallic: false)
        let textModel = ModelEntity(mesh: textMesh, materials: [material])
        textModel.transform.translation = position // Set the position directly
        return textModel
    }

    func updateUIView(_ uiView: ARView, context: Context) {}
}

#Preview {
    ContentView()
}
