import Foundation

/// A structure representing a chunk of text received from a language model.
///
/// Use this to access the text content from streaming responses.
public struct TextResponse: Sendable {
    /// The text content of the response chunk.
    public let text: String

    /// Creates a new text response with the specified content.
    /// - Parameter text: The text content for this response chunk.
    public init(text: String) {
        self.text = text
    }
}

/// A type representing an asynchronous stream of text responses that can throw errors.
public typealias TextStream = AsyncThrowingStream<TextResponse, Error>

/// A protocol defining the core functionality of language models.
///
/// Conforming types provide methods for generating text and streaming text responses
/// from language models using prompts.
public protocol LanguageModel {
    /// Generates a complete text response for the given prompt.
    ///
    /// This method will wait for the entire response to be generated before returning.
    ///
    /// - Parameter prompt: The input text to send to the language model.
    /// - Returns: The complete text response from the language model.
    /// - Throws: An error if the text generation fails.
    func generateText(prompt: String) async throws -> String

    /// Streams text responses for the given prompt as they become available.
    ///
    /// This method returns immediately with a stream that will yield text chunks
    /// as the language model generates them.
    ///
    /// - Parameter prompt: The input text to send to the language model.
    /// - Returns: An asynchronous stream of text responses.
    /// - Throws: An error if setting up the stream fails.
    func streamText(prompt: String) async throws -> TextStream
}
