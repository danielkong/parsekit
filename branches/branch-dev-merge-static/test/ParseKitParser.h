#import <ParseKit/PKSParser.h>

enum {
    TOKEN_KIND_SYMBOL_TITLE = 14,
    TOKEN_KIND_SEMANTICPREDICATE,
    TOKEN_KIND_PIPE,
    TOKEN_KIND_CLOSE_CURLY,
    TOKEN_KIND_TILDE,
    TOKEN_KIND_START,
    TOKEN_KIND_COMMENT_TITLE,
    TOKEN_KIND_DISCARD,
    TOKEN_KIND_NUMBER_TITLE,
    TOKEN_KIND_ANY_TITLE,
    TOKEN_KIND_SEMI_COLON,
    TOKEN_KIND_S_TITLE,
    TOKEN_KIND_ACTION,
    TOKEN_KIND_EQUALS,
    TOKEN_KIND_AMPERSAND,
    TOKEN_KIND_PATTERNNOOPTS,
    TOKEN_KIND_PHRASEQUESTION,
    TOKEN_KIND_QUOTEDSTRING_TITLE,
    TOKEN_KIND_LETTER_TITLE,
    TOKEN_KIND_AT,
    TOKEN_KIND_OPEN_PAREN,
    TOKEN_KIND_CLOSE_PAREN,
    TOKEN_KIND_PATTERNIGNORECASE,
    TOKEN_KIND_PHRASESTAR,
    TOKEN_KIND_EMPTY_TITLE,
    TOKEN_KIND_PHRASEPLUS,
    TOKEN_KIND_OPEN_BRACKET,
    TOKEN_KIND_COMMA,
    TOKEN_KIND_SPECIFICCHAR_TITLE,
    TOKEN_KIND_MINUS,
    TOKEN_KIND_WORD_TITLE,
    TOKEN_KIND_CHAR_TITLE,
    TOKEN_KIND_CLOSE_BRACKET,
    TOKEN_KIND_DIGIT_TITLE,
    TOKEN_KIND_DELIMOPEN,
};

@interface ParseKitParser : PKSParser

@end

