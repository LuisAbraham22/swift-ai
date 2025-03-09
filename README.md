# SwiftAI

[![Swift](https://img.shields.io/badge/Swift-6.0+-orange.svg)](https://swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-macOS%2015%20|%20iOS%2013%20|%20tvOS%2013%20|%20watchOS%206%20|%20visionOS%201-blue.svg)](https://github.com/apple/swift-openapi-runtime)

Swift-AI is a modern Swift library for interacting with large language models using a clean, protocol-based API design. Inspired by Vercel’s AI SDK, Swift-AI offers a modular and type-safe approach to generating and streaming text responses. Currently, only OpenAI is supported—but stay tuned for more providers and models in future releases!

## Features

- 🚀 Simple, protocol-based design for seamless language model interactions
- 🔍 Current Support: Integrates multiple OpenAI models, including GPT-4o, GPT-4o Mini, O1, O1 Mini, and O3 Mini.
- 🔜 Expanding Provider Support: While OpenAI is the sole supported provider at the moment, additional language model providers are coming soon.
- 📊 Synchronous and streaming text generation
- 🛡️ Built for Swift Concurrency with `async`/`await`
- 🧵 Type-safe API with proper error handling
- 📦 Modular architecture with separate AI protocol and implementation modules

## Installation

### Swift Package Manager

Add the following to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/LuisAbraham22/SwiftAI.git", from: "0.1.0")
]
```

Then, add the appropriate dependencies to your target:

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "AI", package: "SwiftAI"),
        .product(name: "OpenAI", package: "SwiftAI")
    ]
)
```

## Quick Start

```swift
import AI
import OpenAI

@main
public struct App {
    public static func main() async throws {
        // Initialize a GPT-4o model
        let model = try OpenAI.Client.gpt4o(apiKey: "your-api-key")
        
        // Define a prompt for text generation
        let prompt = "Explain what transformers are in a few lines"

        // Stream text responses as they're generated
        let stream = try await model.streamText(prompt: prompt)
        
        // Print each chunk of text as it arrives
        for try await response in stream {
            print(response.text, terminator: "")
            // Flush output immediately
            fflush(stdout)
        }
    }
}
```

## Architecture

SwiftAI is built with a modular architecture:

- `AI`: Contains the core protocol definitions and types
- `OpenAI`: Provides OpenAI-specific implementations of the protocols

### Core Protocol

The `LanguageModel` protocol defines the standard interface for all language models:

```swift
public protocol LanguageModel {
    func generateText(prompt: String) async throws -> String
    func streamText(prompt: String) async throws -> TextStream
}
```

## API Reference

### OpenAI Client

The `OpenAI.Client` provides access to various OpenAI models:

```swift
// Create specific model instances
let chatGPT4o = try OpenAI.Client.chatGPT4o(apiKey: "your-api-key")
let gpt4o = try OpenAI.Client.gpt4o(apiKey: "your-api-key")
let gpt4oMini = try OpenAI.Client.gpt4oMini(apiKey: "your-api-key")
let o1 = try OpenAI.Client.o1(apiKey: "your-api-key")
let o1Mini = try OpenAI.Client.o1Mini(apiKey: "your-api-key")
let o3Mini = try OpenAI.Client.o3Mini(apiKey: "your-api-key")
```

### Custom Model Initialization

In addition to the pre-defined model constructors, you can initialize the OpenAI client by directly specifying the model you want to use:

```swift
import AI
import OpenAI

@main
public struct App {
    public static func main() async throws {
        // Initialize the OpenAI client with a custom model (e.g., gpt-4o)
        let customModel = try OpenAI.Client(apiKey: "your-api-key", model: .gpt4o)
        
        // Generate a text response using the custom model
        let response = try await customModel.generateText(prompt: "Explain the concept of quantum entanglement")
        print(response)
    }
}
```
This approach gives you the flexibility to choose any available model, such as .gpt4o, .gpt3_5Turbo, or any other model from the OpenAIModel enum.


### Text Generation

Generate a complete response:

```swift
let response = try await model.generateText(prompt: "Explain quantum computing")
print(response)
```

### Text Streaming

Stream the response as it's generated:

```swift
let stream = try await model.streamText(prompt: "Write a short story")
for try await chunk in stream {
    print(chunk.text, terminator: "")
    // Immediately flush to STDOUT
    fflush(stdout)
}
```

## Requirements

- Swift 6.0+
- macOS 15+
- iOS 13+
- tvOS 13+
- watchOS 6+
- visionOS 1+

## License

This project is released under the MIT License. See the LICENSE file for details.
