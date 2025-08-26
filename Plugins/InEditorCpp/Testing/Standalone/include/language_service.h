#pragma once

#include <string>
#include <vector>
#include <memory>

class LanguageService {
public:
    LanguageService();
    ~LanguageService();

    bool Initialize();
    void Shutdown();

    // Language features
    void UpdateFile(const std::string& path, const std::string& content);
    std::vector<std::string> GetCompletions(const std::string& path, int line, int column);
    std::vector<std::string> GetDiagnostics(const std::string& path);

private:
    bool StartServer();
    void StopServer();
    void HandleServerMessages();

private:
    struct Impl;
    std::unique_ptr<Impl> pImpl;
    bool initialized;
};
