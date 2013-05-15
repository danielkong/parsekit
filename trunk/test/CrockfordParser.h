#import <ParseKit/PKSParser.h>

enum {
    CROCKFORD_TOKEN_KIND_OPEN_CURLY = 14,
    CROCKFORD_TOKEN_KIND_GE,
    CROCKFORD_TOKEN_KIND_DOUBLE_AMPERSAND,
    CROCKFORD_TOKEN_KIND_FOR,
    CROCKFORD_TOKEN_KIND_BREAK,
    CROCKFORD_TOKEN_KIND_CLOSE_CURLY,
    CROCKFORD_TOKEN_KIND_RETURN,
    CROCKFORD_TOKEN_KIND_PLUS_EQUALS,
    CROCKFORD_TOKEN_KIND_FUNCTION,
    CROCKFORD_TOKEN_KIND_IF,
    CROCKFORD_TOKEN_KIND_NEW,
    CROCKFORD_TOKEN_KIND_ELSE,
    CROCKFORD_TOKEN_KIND_BANG,
    CROCKFORD_TOKEN_KIND_FINALLY,
    CROCKFORD_TOKEN_KIND_COLON,
    CROCKFORD_TOKEN_KIND_CATCH,
    CROCKFORD_TOKEN_KIND_SEMI_COLON,
    CROCKFORD_TOKEN_KIND_DO,
    CROCKFORD_TOKEN_KIND_DOUBLE_NE,
    CROCKFORD_TOKEN_KIND_LT,
    CROCKFORD_TOKEN_KIND_MINUS_EQUALS,
    CROCKFORD_TOKEN_KIND_PERCENT,
    CROCKFORD_TOKEN_KIND_EQUALS,
    CROCKFORD_TOKEN_KIND_THROW,
    CROCKFORD_TOKEN_KIND_TRY,
    CROCKFORD_TOKEN_KIND_GT,
    CROCKFORD_TOKEN_KIND_REGEXBODY,
    CROCKFORD_TOKEN_KIND_TYPEOF,
    CROCKFORD_TOKEN_KIND_OPEN_PAREN,
    CROCKFORD_TOKEN_KIND_WHILE,
    CROCKFORD_TOKEN_KIND_VAR,
    CROCKFORD_TOKEN_KIND_CLOSE_PAREN,
    CROCKFORD_TOKEN_KIND_STAR,
    CROCKFORD_TOKEN_KIND_DOUBLE_PIPE,
    CROCKFORD_TOKEN_KIND_PLUS,
    CROCKFORD_TOKEN_KIND_OPEN_BRACKET,
    CROCKFORD_TOKEN_KIND_COMMA,
    CROCKFORD_TOKEN_KIND_DELETE,
    CROCKFORD_TOKEN_KIND_SWITCH,
    CROCKFORD_TOKEN_KIND_MINUS,
    CROCKFORD_TOKEN_KIND_IN,
    CROCKFORD_TOKEN_KIND_TRIPLE_EQUALS,
    CROCKFORD_TOKEN_KIND_CLOSE_BRACKET,
    CROCKFORD_TOKEN_KIND_DOT,
    CROCKFORD_TOKEN_KIND_DEFAULT,
    CROCKFORD_TOKEN_KIND_FORWARD_SLASH,
    CROCKFORD_TOKEN_KIND_CASE,
    CROCKFORD_TOKEN_KIND_LE,
};

@interface CrockfordParser : PKSParser

@end

