/*
 * Dummy TextEditor implementation
 * This is a placeholder implementation that will be used when the actual
 * ImGuiColorTextEdit library is not available. This allows the plugin to compile
 * but with limited functionality.
 */

#pragma once

#include <string>
#include <vector>
#include <array>
#include <memory>
#include <unordered_set>
#include <unordered_map>
#include <map>
#include <regex>

// ImGui forward declarations to avoid including the full ImGui header
namespace ImGui
{
    // Dummy to make sure we can use ImVec4 in the TextEditor class
    struct ImVec4 { float x, y, z, w; ImVec4(float _x = 0.0f, float _y = 0.0f, float _z = 0.0f, float _w = 0.0f) : x(_x), y(_y), z(_z), w(_w) {} };
}

class TextEditor
{
public:
    enum class PaletteIndex
    {
        Default,
        Keyword,
        Number,
        String,
        CharLiteral,
        Punctuation,
        Preprocessor,
        Identifier,
        KnownIdentifier,
        PreprocIdentifier,
        Comment,
        MultiLineComment,
        Background,
        Cursor,
        Selection,
        ErrorMarker,
        Breakpoint,
        LineNumber,
        CurrentLineFill,
        CurrentLineFillInactive,
        CurrentLineEdge,
        Max
    };

    enum class SelectionMode
    {
        Normal,
        Word,
        Line
    };

    struct Breakpoint
    {
        int mLine;
        bool mEnabled;
        std::string mCondition;

        Breakpoint()
            : mLine(-1)
            , mEnabled(false)
        {}
    };

    struct Coordinates
    {
        int mLine, mColumn;
        Coordinates() : mLine(0), mColumn(0) {}
        Coordinates(int aLine, int aColumn) : mLine(aLine), mColumn(aColumn) {}
    };

    struct Identifier
    {
        std::string mDeclaration;
    };

    typedef std::string String;
    typedef std::unordered_map<std::string, Identifier> Identifiers;
    typedef std::unordered_set<std::string> Keywords;
    typedef std::map<int, std::string> ErrorMarkers;
    typedef std::unordered_set<int> Breakpoints;
    typedef std::array<ImGui::ImVec4, (unsigned)PaletteIndex::Max> Palette;
    typedef char Char;

    struct LanguageDefinition
    {
        Keywords mKeywords;
        Identifiers mIdentifiers;
        Identifiers mPreprocIdentifiers;
        std::string mCommentStart, mCommentEnd, mSingleLineComment;
        char mPreprocChar;
        bool mAutoIndentation;

        static LanguageDefinition CPlusPlus()
        {
            LanguageDefinition langDef;
            langDef.mCommentStart = "/*";
            langDef.mCommentEnd = "*/";
            langDef.mSingleLineComment = "//";
            langDef.mPreprocChar = '#';
            langDef.mAutoIndentation = true;
            return langDef;
        }

        static LanguageDefinition HLSL()
        {
            return CPlusPlus();
        }

        static LanguageDefinition GLSL()
        {
            return CPlusPlus();
        }

        static LanguageDefinition C()
        {
            return CPlusPlus();
        }

        static LanguageDefinition SQL()
        {
            LanguageDefinition langDef;
            langDef.mCommentStart = "/*";
            langDef.mCommentEnd = "*/";
            langDef.mSingleLineComment = "--";
            langDef.mPreprocChar = ' ';
            langDef.mAutoIndentation = false;
            return langDef;
        }

        static LanguageDefinition AngelScript()
        {
            return CPlusPlus();
        }

        static LanguageDefinition Lua()
        {
            LanguageDefinition langDef;
            langDef.mCommentStart = "--[[";
            langDef.mCommentEnd = "]]";
            langDef.mSingleLineComment = "--";
            langDef.mPreprocChar = ' ';
            langDef.mAutoIndentation = false;
            return langDef;
        }
    };

    // Simple constructor/destructor implementations to avoid linker errors
    TextEditor() {}
    ~TextEditor() {}

    void SetLanguageDefinition(const LanguageDefinition& aLanguageDef) {}
    const LanguageDefinition& GetLanguageDefinition() const { static LanguageDefinition lang = LanguageDefinition::CPlusPlus(); return lang; }

    const Palette& GetPalette() const { static Palette p; return p; }
    void SetPalette(const Palette& aValue) {}
    
    void SetTabSize(int aValue) {}
    
    void SetShowWhitespaces(bool aValue) {}
    bool IsShowingWhitespaces() const { return false; }
    
    void SetShowLineNumbers(bool aValue) {}
    bool IsShowingLineNumbers() const { return true; }
    
    void SetReadOnly(bool aValue) {}
    bool IsReadOnly() const { return false; }
    
    bool CanUndo() const { return false; }
    bool CanRedo() const { return false; }
    void Undo() {}
    void Redo() {}
    
    void Cut() {}
    void Copy() {}
    void Paste() {}
    void Delete() {}

    bool HasSelection() const { return false; }
    void SetSelection(const Coordinates& aStart, const Coordinates& aEnd) {}
    
    const std::string& GetText() const { static std::string s; return s; }
    void SetText(const std::string& aText) {}
    
    Coordinates GetCursorPosition() const { return Coordinates(); }
    int GetTotalLines() const { return 0; }
    
    void Render(const char* aTitle, bool aFocused = true) {}
    
    static Palette GetDarkPalette() { static Palette p; return p; }
    static Palette GetLightPalette() { static Palette p; return p; }
    static Palette GetRetroBluePalette() { static Palette p; return p; }
};