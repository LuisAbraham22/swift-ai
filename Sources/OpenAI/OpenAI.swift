import AI
import Foundation
import OpenAPIRuntime
import SwiftOpenAIClient

package typealias OpenAIModel = Components.Schemas.CreateChatCompletionRequest.ModelPayload
    .Value2Payload

package typealias CreateChatCompletionRequest = Operations.CreateChatCompletion.Input
package typealias ChatGPTPayload = Components.Schemas.CreateChatCompletionStreamResponse

public enum OpenAIError: Error {
    case missingAPIKey(String)
    case dependencyFailure(String)
}

public struct Client: LanguageModel {
    public struct TextResponse: Sendable {
        public let text: String
        public init(text: String) {
            self.text = text
        }
    }
    private static let envVariableKey = "OPENAI_API_KEY"

    private let apiKey: String
    private let model: OpenAIModel
    private let client: APIProtocol

    private init(
        apiKey: String? = nil,
        model: OpenAIModel
    ) throws {
        self.apiKey = try apiKey ?? Self.getAPIKeyFromEnvironment()
        self.model = model
        self.client = SwiftOpenAIClient.OpenAI.client(with: .default(apiKey: self.apiKey))
    }

    public static func gpt4o(apiKey: String? = nil) throws -> Self {
        try Client(apiKey: apiKey, model: .chatgpt4oLatest)
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

    public func generateText(prompt: String) async throws -> String {
        let request = createChatCompletionRequest(prompt: prompt, stream: false)
        let response = try await client.createChatCompletion(request)

        guard let message = try response.ok.body.json.choices.first?.message.content else {
            let errorMessage = "Could not obtain message from response: \(response)"
            throw OpenAIError.dependencyFailure(errorMessage)
        }

        return message
    }

    public func streamText(prompt: String) async throws -> (
        some AsyncSequence<TextResponse, Error> & Sendable
    ) {
        let request = createChatCompletionRequest(prompt: prompt, stream: true)

        let response = try await client.createChatCompletion(request)

        let stream = try response.ok.body.textEventStream.asDecodedServerSentEventsWithJSONData(
            of: ChatGPTPayload.self
        ) {
            $0 != HTTPBody.ByteChunk("[DONE]".utf8)
        }.compactMap {
            if let textContent = $0.data?.choices.first?.delta.content {
                return TextResponse(text: textContent)
            }
            return nil
        }

        return stream
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
