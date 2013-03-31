#import "PKSParser.h"

enum {
    TOKEN_KIND_RBRACKET = 14,
    TOKEN_KIND_LBRACKET,
    TOKEN_KIND_COMMA,
    TOKEN_KIND_EQ,
    TOKEN_KIND_SEMI,
    TOKEN_KIND_DOT,
};

@interface ElementAssignParser : PKSParser

@end

