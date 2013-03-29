#import "PKSParser.h"

enum {
    TOKEN_KIND_LBRACKET = 14,
    TOKEN_KIND_RBRACKET,
    TOKEN_KIND_COMMA,
    TOKEN_KIND_EQ,
};

@interface ElementAssignParser : PKSParser

@end

