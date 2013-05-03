#import <ParseKit/PKSParser.h>

enum {
    TREEOUTPUT_TOKEN_KIND_BAR = 14,
    TREEOUTPUT_TOKEN_KIND_INT,
    TREEOUTPUT_TOKEN_KIND_SEMI_COLON,
};

@interface TreeOutputParser : PKSParser

@end

