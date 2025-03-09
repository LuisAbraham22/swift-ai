import AI
import Foundation
import OpenAPIRuntime
import SwiftOpenAIClient

public typealias OpenAIModel = Components.Schemas.CreateChatCompletionRequest.ModelPayload
    .Value2Payload

package typealias CreateChatCompletionRequest = Operations.CreateChatCompletion.Input
package typealias ChatGPTPayload = Components.Schemas.CreateChatCompletionStreamResponse

public enum OpenAIError: Error {
    case missingAPIKey(String)
    case dependencyFailure(String)
}

/// A concrete implementation of `LanguageModel` that uses OpenAI's API.
///
/// This client supports various OpenAI models including GPT-4o, O1, O1 Mini, and O3 Mini.
/// It handles API authentication and provides methods for both complete text generation
/// and streaming text responses.
public struct Client: LanguageModel {

    private static let envVariableKey = "OPENAI_API_KEY"

    private let apiKey: String
    private let model: OpenAIModel
    private let client: APIProtocol

    public init(
        apiKey: String? = nil,
        model: OpenAIModel
    ) throws {
        self.apiKey = try apiKey ?? Self.getAPIKeyFromEnvironment()
        self.model = model
        self.client = SwiftOpenAIClient.OpenAI.client(with: .default(apiKey: self.apiKey))
    }

    public static func chatGPT4o(apiKey: String? = nil) throws -> Self {
        try Client(apiKey: apiKey, model: .chatgpt4oLatest)
    }

    public static func gpt4o(apiKey: String? = nil) throws -> Self {
        try Client(apiKey: apiKey, model: .gpt4o20240806)
    }

    public static func gpt4oMini(apiKey: String? = nil) throws -> Self {
        try Client(apiKey: apiKey, model: .gpt4oMini)
    }

    public static func o1(apiKey: String? = nil) throws -> Self {
        try Client(apiKey: apiKey, model: .o1)
    }

    public static func o1Mini(apiKey: String? = nil) throws -> Self {
        try Client(apiKey: apiKey, model: .o1Mini)
    }

    public static func o3Mini(apiKey: String? = nil) throws -> Self {
        try Client(apiKey: apiKey, model: .o3Mini)
    }

    /// Generates a complete text response for the given prompt.
    ///
    /// This method sends a non-streaming request to the OpenAI API and waits for
    /// the complete response before returning.
    ///
    /// - Parameter prompt: The input text to send to the language model.
    /// - Returns: The complete text response from the model.
    /// - Throws: `OpenAIError.dependencyFailure` if the response cannot be parsed,
    ///
    public func generateText(prompt: String) async throws -> String {
        let request = createChatCompletionRequest(prompt: prompt, stream: false)
        let response = try await client.createChatCompletion(request)

        guard let message = try response.ok.body.json.choices.first?.message.content else {
            let errorMessage = "Could not obtain message from response: \(response)"
            throw OpenAIError.dependencyFailure(errorMessage)
        }

        return message
    }

    /// Streams text responses for the given prompt as they become available.
    ///
    /// This method sends a streaming request to the OpenAI API and returns an
    /// asynchronous stream that yields text chunks as they're received.
    ///
    /// - Parameter prompt: The input text to send to the language model.
    /// - Returns: An asynchronous stream of text responses.
    /// - Throws: Any network or API errors that occur during setup.
    public func streamText(prompt: String) async throws -> TextStream {
        let request = createChatCompletionRequest(prompt: prompt, stream: true)

        let response = try await client.createChatCompletion(request)

        return AsyncThrowingStream { continuation in
            // Start a task to process the stream
            Task {
                do {
                    // Get the original stream
                    let originalStream = try response.ok.body.textEventStream
                        .asDecodedServerSentEventsWithJSONData(
                            of: ChatGPTPayload.self
                        ) {
                            $0 != HTTPBody.ByteChunk("[DONE]".utf8)
                        }

                    // Process each item from the original stream
                    for try await item in originalStream {
                        if let textContent = item.data?.choices.first?.delta.content {
                            continuation.yield(TextResponse(text: textContent))
                        }
                    }

                    // End the stream normally when complete
                    continuation.finish()
                } catch {
                    // End the stream with an error if something goes wrong
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    private func createChatCompletionRequest(prompt: String, stream: Bool)
        -> CreateChatCompletionRequest
    {
        .init(
            body: .json(
                .init(
                    messages: [
                        .ChatCompletionRequestUserMessage(
                            .init(content: .case1(prompt), role: .user))
                    ],
                    model: .init(value2: self.model),
                    stream: stream
                )
            )
        )
    }

    private static func getAPIKeyFromEnvironment() throws -> String {
        guard let envAPIKey = ProcessInfo.processInfo.environment[Self.envVariableKey] else {
            let errorMessage =
                "Could not find API key in the environment: \(Self.envVariableKey)"
            // TODO: Log
            throw OpenAIError.missingAPIKey(errorMessage)
        }

        return envAPIKey
    }
}
