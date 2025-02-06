import AI
import Foundation
import OpenAI

@main
public struct App {
    public static func main() async throws {

        let apiKey =
            ""
        let gpt4o = try OpenAI.Client.gpt4o(apiKey: apiKey)

        let prompt = "Explain what transformers are in a few lines"
        let stream = try await gpt4o.streamText(prompt: prompt)

        for try await response in stream {
            print(response.text, terminator: "")
            fflush(stdout)
        }
    }
}
