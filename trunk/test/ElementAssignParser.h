#import <PEGKit/PEGParser.h>

enum {
    ELEMENTASSIGN_TOKEN_KIND_RBRACKET = 14,
    ELEMENTASSIGN_TOKEN_KIND_LBRACKET,
    ELEMENTASSIGN_TOKEN_KIND_COMMA,
    ELEMENTASSIGN_TOKEN_KIND_EQ,
    ELEMENTASSIGN_TOKEN_KIND_SEMI,
    ELEMENTASSIGN_TOKEN_KIND_DOT,
};

@interface ElementAssignParser : PEGParser

@end

