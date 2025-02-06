public protocol LanguageModel {
    func generateText(prompt: String) async throws -> String
}
