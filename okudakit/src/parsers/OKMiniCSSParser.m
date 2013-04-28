#import "OKMiniCSSParser.h"
#import <ParseKit/ParseKit.h>

#define LT(i) [self LT:(i)]
#define LA(i) [self LA:(i)]
#define LS(i) [self LS:(i)]
#define LF(i) [self LF:(i)]

#define POP()       [self.assembly pop]
#define POP_STR()   [self _popString]
#define POP_TOK()   [self _popToken]
#define POP_BOOL()  [self _popBool]
#define POP_INT()   [self _popInteger]
#define POP_FLOAT() [self _popDouble]

#define PUSH(obj)     [self.assembly push:(id)(obj)]
#define PUSH_BOOL(yn) [self _pushBool:(BOOL)(yn)]
#define PUSH_INT(i)   [self _pushInteger:(NSInteger)(i)]
#define PUSH_FLOAT(f) [self _pushDouble:(double)(f)]

#define EQ(a, b) [(a) isEqual:(b)]
#define NE(a, b) (![(a) isEqual:(b)])
#define EQ_IGNORE_CASE(a, b) (NSOrderedSame == [(a) compare:(b)])

#define ABOVE(fence) [self.assembly objectsAbove:(fence)]

#define LOG(obj) do { NSLog(@"%@", (obj)); } while (0);
#define PRINT(str) do { printf("%s\n", (str)); } while (0);

@interface PKSParser ()
@property (nonatomic, retain) NSMutableDictionary *_tokenKindTab;

- (BOOL)_popBool;
- (NSInteger)_popInteger;
- (double)_popDouble;
- (PKToken *)_popToken;
- (NSString *)_popString;

- (void)_pushBool:(BOOL)yn;
- (void)_pushInteger:(NSInteger)i;
- (void)_pushDouble:(double)d;
@end

@interface OKMiniCSSParser ()
@property (nonatomic, retain) NSMutableDictionary *ruleset_memo;
@property (nonatomic, retain) NSMutableDictionary *selectors_memo;
@property (nonatomic, retain) NSMutableDictionary *selector_memo;
@property (nonatomic, retain) NSMutableDictionary *commaSelector_memo;
@property (nonatomic, retain) NSMutableDictionary *decls_memo;
@property (nonatomic, retain) NSMutableDictionary *actualDecls_memo;
@property (nonatomic, retain) NSMutableDictionary *decl_memo;
@property (nonatomic, retain) NSMutableDictionary *property_memo;
@property (nonatomic, retain) NSMutableDictionary *expr_memo;
@property (nonatomic, retain) NSMutableDictionary *pixelValue_memo;
@property (nonatomic, retain) NSMutableDictionary *rgbValue_memo;
@property (nonatomic, retain) NSMutableDictionary *constants_memo;
@property (nonatomic, retain) NSMutableDictionary *num_memo;
@property (nonatomic, retain) NSMutableDictionary *string_memo;
@property (nonatomic, retain) NSMutableDictionary *px_memo;
@property (nonatomic, retain) NSMutableDictionary *rgb_memo;
@property (nonatomic, retain) NSMutableDictionary *color_memo;
@property (nonatomic, retain) NSMutableDictionary *backgroundColor_memo;
@property (nonatomic, retain) NSMutableDictionary *fontFamily_memo;
@property (nonatomic, retain) NSMutableDictionary *fontSize_memo;
@property (nonatomic, retain) NSMutableDictionary *bold_memo;
@property (nonatomic, retain) NSMutableDictionary *normal_memo;
@property (nonatomic, retain) NSMutableDictionary *italic_memo;
@end

@implementation OKMiniCSSParser

- (id)init {
    self = [super init];
    if (self) {
        self._tokenKindTab[@":"] = @(OKMINICSS_TOKEN_KIND_COLON);
        self._tokenKindTab[@"bold"] = @(OKMINICSS_TOKEN_KIND_BOLD);
        self._tokenKindTab[@"italic"] = @(OKMINICSS_TOKEN_KIND_ITALIC);
        self._tokenKindTab[@";"] = @(OKMINICSS_TOKEN_KIND_SEMI_COLON);
        self._tokenKindTab[@","] = @(OKMINICSS_TOKEN_KIND_COMMA);
        self._tokenKindTab[@"font-family"] = @(OKMINICSS_TOKEN_KIND_FONTFAMILY);
        self._tokenKindTab[@"font-size"] = @(OKMINICSS_TOKEN_KIND_FONTSIZE);
        self._tokenKindTab[@"normal"] = @(OKMINICSS_TOKEN_KIND_NORMAL);
        self._tokenKindTab[@"px"] = @(OKMINICSS_TOKEN_KIND_PX);
        self._tokenKindTab[@"color"] = @(OKMINICSS_TOKEN_KIND_COLOR);
        self._tokenKindTab[@"rgb"] = @(OKMINICSS_TOKEN_KIND_RGB);
        self._tokenKindTab[@"{"] = @(OKMINICSS_TOKEN_KIND_OPEN_CURLY);
        self._tokenKindTab[@"("] = @(OKMINICSS_TOKEN_KIND_OPEN_PAREN);
        self._tokenKindTab[@"background-color"] = @(OKMINICSS_TOKEN_KIND_BACKGROUNDCOLOR);
        self._tokenKindTab[@"}"] = @(OKMINICSS_TOKEN_KIND_CLOSE_CURLY);
        self._tokenKindTab[@")"] = @(OKMINICSS_TOKEN_KIND_CLOSE_PAREN);

        self.ruleset_memo = [NSMutableDictionary dictionary];
        self.selectors_memo = [NSMutableDictionary dictionary];
        self.selector_memo = [NSMutableDictionary dictionary];
        self.commaSelector_memo = [NSMutableDictionary dictionary];
        self.decls_memo = [NSMutableDictionary dictionary];
        self.actualDecls_memo = [NSMutableDictionary dictionary];
        self.decl_memo = [NSMutableDictionary dictionary];
        self.property_memo = [NSMutableDictionary dictionary];
        self.expr_memo = [NSMutableDictionary dictionary];
        self.pixelValue_memo = [NSMutableDictionary dictionary];
        self.rgbValue_memo = [NSMutableDictionary dictionary];
        self.constants_memo = [NSMutableDictionary dictionary];
        self.num_memo = [NSMutableDictionary dictionary];
        self.string_memo = [NSMutableDictionary dictionary];
        self.px_memo = [NSMutableDictionary dictionary];
        self.rgb_memo = [NSMutableDictionary dictionary];
        self.color_memo = [NSMutableDictionary dictionary];
        self.backgroundColor_memo = [NSMutableDictionary dictionary];
        self.fontFamily_memo = [NSMutableDictionary dictionary];
        self.fontSize_memo = [NSMutableDictionary dictionary];
        self.bold_memo = [NSMutableDictionary dictionary];
        self.normal_memo = [NSMutableDictionary dictionary];
        self.italic_memo = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)dealloc {
    self.ruleset_memo = nil;
    self.selectors_memo = nil;
    self.selector_memo = nil;
    self.commaSelector_memo = nil;
    self.decls_memo = nil;
    self.actualDecls_memo = nil;
    self.decl_memo = nil;
    self.property_memo = nil;
    self.expr_memo = nil;
    self.pixelValue_memo = nil;
    self.rgbValue_memo = nil;
    self.constants_memo = nil;
    self.num_memo = nil;
    self.string_memo = nil;
    self.px_memo = nil;
    self.rgb_memo = nil;
    self.color_memo = nil;
    self.backgroundColor_memo = nil;
    self.fontFamily_memo = nil;
    self.fontSize_memo = nil;
    self.bold_memo = nil;
    self.normal_memo = nil;
    self.italic_memo = nil;

    [super dealloc];
}

- (void)_clearMemo {
    [_ruleset_memo removeAllObjects];
    [_selectors_memo removeAllObjects];
    [_selector_memo removeAllObjects];
    [_commaSelector_memo removeAllObjects];
    [_decls_memo removeAllObjects];
    [_actualDecls_memo removeAllObjects];
    [_decl_memo removeAllObjects];
    [_property_memo removeAllObjects];
    [_expr_memo removeAllObjects];
    [_pixelValue_memo removeAllObjects];
    [_rgbValue_memo removeAllObjects];
    [_constants_memo removeAllObjects];
    [_num_memo removeAllObjects];
    [_string_memo removeAllObjects];
    [_px_memo removeAllObjects];
    [_rgb_memo removeAllObjects];
    [_color_memo removeAllObjects];
    [_backgroundColor_memo removeAllObjects];
    [_fontFamily_memo removeAllObjects];
    [_fontSize_memo removeAllObjects];
    [_bold_memo removeAllObjects];
    [_normal_memo removeAllObjects];
    [_italic_memo removeAllObjects];
}

- (void)_start {
    
    while ([self predicts:TOKEN_KIND_BUILTIN_WORD, 0]) {
        if ([self speculate:^{ [self ruleset]; }]) {
            [self ruleset]; 
        } else {
            break;
        }
    }
    [self matchEOF:YES]; 

}

- (void)__ruleset {
    
    [self selectors]; 
    [self match:OKMINICSS_TOKEN_KIND_OPEN_CURLY discard:NO];
    [self decls]; 
    [self match:OKMINICSS_TOKEN_KIND_CLOSE_CURLY discard:YES];

    [self fireAssemblerSelector:@selector(parser:didMatchRuleset:)];
}

- (void)ruleset {
    [self parseRule:@selector(__ruleset) withMemo:_ruleset_memo];
}

- (void)__selectors {
    
    [self selector]; 
    while ([self predicts:OKMINICSS_TOKEN_KIND_COMMA, 0]) {
        if ([self speculate:^{ [self commaSelector]; }]) {
            [self commaSelector]; 
        } else {
            break;
        }
    }

    [self fireAssemblerSelector:@selector(parser:didMatchSelectors:)];
}

- (void)selectors {
    [self parseRule:@selector(__selectors) withMemo:_selectors_memo];
}

- (void)__selector {
    
    [self matchWord:NO];

    [self fireAssemblerSelector:@selector(parser:didMatchSelector:)];
}

- (void)selector {
    [self parseRule:@selector(__selector) withMemo:_selector_memo];
}

- (void)__commaSelector {
    
    [self match:OKMINICSS_TOKEN_KIND_COMMA discard:YES];
    [self selector]; 

    [self fireAssemblerSelector:@selector(parser:didMatchCommaSelector:)];
}

- (void)commaSelector {
    [self parseRule:@selector(__commaSelector) withMemo:_commaSelector_memo];
}

- (void)__decls {
    
    if ([self predicts:OKMINICSS_TOKEN_KIND_BACKGROUNDCOLOR, OKMINICSS_TOKEN_KIND_COLOR, OKMINICSS_TOKEN_KIND_FONTFAMILY, OKMINICSS_TOKEN_KIND_FONTSIZE, 0]) {
        [self actualDecls]; 
    }

    [self fireAssemblerSelector:@selector(parser:didMatchDecls:)];
}

- (void)decls {
    [self parseRule:@selector(__decls) withMemo:_decls_memo];
}

- (void)__actualDecls {
    
    [self decl]; 
    while ([self predicts:OKMINICSS_TOKEN_KIND_BACKGROUNDCOLOR, OKMINICSS_TOKEN_KIND_COLOR, OKMINICSS_TOKEN_KIND_FONTFAMILY, OKMINICSS_TOKEN_KIND_FONTSIZE, 0]) {
        if ([self speculate:^{ [self decl]; }]) {
            [self decl]; 
        } else {
            break;
        }
    }

    [self fireAssemblerSelector:@selector(parser:didMatchActualDecls:)];
}

- (void)actualDecls {
    [self parseRule:@selector(__actualDecls) withMemo:_actualDecls_memo];
}

- (void)__decl {
    
    [self property]; 
    [self match:OKMINICSS_TOKEN_KIND_COLON discard:YES];
    [self expr]; 
    if ([self predicts:OKMINICSS_TOKEN_KIND_SEMI_COLON, 0]) {
        [self match:OKMINICSS_TOKEN_KIND_SEMI_COLON discard:YES];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchDecl:)];
}

- (void)decl {
    [self parseRule:@selector(__decl) withMemo:_decl_memo];
}

- (void)__property {
    
    if ([self predicts:OKMINICSS_TOKEN_KIND_COLOR, 0]) {
        [self color]; 
    } else if ([self predicts:OKMINICSS_TOKEN_KIND_BACKGROUNDCOLOR, 0]) {
        [self backgroundColor]; 
    } else if ([self predicts:OKMINICSS_TOKEN_KIND_FONTFAMILY, 0]) {
        [self fontFamily]; 
    } else if ([self predicts:OKMINICSS_TOKEN_KIND_FONTSIZE, 0]) {
        [self fontSize]; 
    } else {
        [self raise:@"no viable alternative found in property"];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchProperty:)];
}

- (void)property {
    [self parseRule:@selector(__property) withMemo:_property_memo];
}

- (void)__expr {
    
    if ([self predicts:TOKEN_KIND_BUILTIN_NUMBER, 0]) {
        [self pixelValue]; 
    } else if ([self predicts:OKMINICSS_TOKEN_KIND_RGB, 0]) {
        [self rgbValue]; 
    } else if ([self predicts:TOKEN_KIND_BUILTIN_QUOTEDSTRING, 0]) {
        [self string]; 
    } else if ([self predicts:OKMINICSS_TOKEN_KIND_BOLD, OKMINICSS_TOKEN_KIND_ITALIC, OKMINICSS_TOKEN_KIND_NORMAL, 0]) {
        [self constants]; 
    } else {
        [self raise:@"no viable alternative found in expr"];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchExpr:)];
}

- (void)expr {
    [self parseRule:@selector(__expr) withMemo:_expr_memo];
}

- (void)__pixelValue {
    
    [self num]; 
    [self px]; 

    [self fireAssemblerSelector:@selector(parser:didMatchPixelValue:)];
}

- (void)pixelValue {
    [self parseRule:@selector(__pixelValue) withMemo:_pixelValue_memo];
}

- (void)__rgbValue {
    
    [self rgb]; 
    [self match:OKMINICSS_TOKEN_KIND_OPEN_PAREN discard:NO];
    [self matchNumber:NO];
    [self match:OKMINICSS_TOKEN_KIND_COMMA discard:YES];
    [self matchNumber:NO];
    [self match:OKMINICSS_TOKEN_KIND_COMMA discard:YES];
    [self matchNumber:NO];
    [self match:OKMINICSS_TOKEN_KIND_CLOSE_PAREN discard:YES];

    [self fireAssemblerSelector:@selector(parser:didMatchRgbValue:)];
}

- (void)rgbValue {
    [self parseRule:@selector(__rgbValue) withMemo:_rgbValue_memo];
}

- (void)__constants {
    
    if ([self predicts:OKMINICSS_TOKEN_KIND_BOLD, 0]) {
        [self bold]; 
    } else if ([self predicts:OKMINICSS_TOKEN_KIND_NORMAL, 0]) {
        [self normal]; 
    } else if ([self predicts:OKMINICSS_TOKEN_KIND_ITALIC, 0]) {
        [self italic]; 
    } else {
        [self raise:@"no viable alternative found in constants"];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchConstants:)];
}

- (void)constants {
    [self parseRule:@selector(__constants) withMemo:_constants_memo];
}

- (void)__num {
    
    [self matchNumber:NO];

    [self fireAssemblerSelector:@selector(parser:didMatchNum:)];
}

- (void)num {
    [self parseRule:@selector(__num) withMemo:_num_memo];
}

- (void)__string {
    
    [self matchQuotedString:NO];

    [self fireAssemblerSelector:@selector(parser:didMatchString:)];
}

- (void)string {
    [self parseRule:@selector(__string) withMemo:_string_memo];
}

- (void)__px {
    
    [self match:OKMINICSS_TOKEN_KIND_PX discard:YES];

    [self fireAssemblerSelector:@selector(parser:didMatchPx:)];
}

- (void)px {
    [self parseRule:@selector(__px) withMemo:_px_memo];
}

- (void)__rgb {
    
    [self match:OKMINICSS_TOKEN_KIND_RGB discard:YES];

    [self fireAssemblerSelector:@selector(parser:didMatchRgb:)];
}

- (void)rgb {
    [self parseRule:@selector(__rgb) withMemo:_rgb_memo];
}

- (void)__color {
    
    [self match:OKMINICSS_TOKEN_KIND_COLOR discard:NO];

    [self fireAssemblerSelector:@selector(parser:didMatchColor:)];
}

- (void)color {
    [self parseRule:@selector(__color) withMemo:_color_memo];
}

- (void)__backgroundColor {
    
    [self match:OKMINICSS_TOKEN_KIND_BACKGROUNDCOLOR discard:NO];

    [self fireAssemblerSelector:@selector(parser:didMatchBackgroundColor:)];
}

- (void)backgroundColor {
    [self parseRule:@selector(__backgroundColor) withMemo:_backgroundColor_memo];
}

- (void)__fontFamily {
    
    [self match:OKMINICSS_TOKEN_KIND_FONTFAMILY discard:NO];

    [self fireAssemblerSelector:@selector(parser:didMatchFontFamily:)];
}

- (void)fontFamily {
    [self parseRule:@selector(__fontFamily) withMemo:_fontFamily_memo];
}

- (void)__fontSize {
    
    [self match:OKMINICSS_TOKEN_KIND_FONTSIZE discard:NO];

    [self fireAssemblerSelector:@selector(parser:didMatchFontSize:)];
}

- (void)fontSize {
    [self parseRule:@selector(__fontSize) withMemo:_fontSize_memo];
}

- (void)__bold {
    
    [self match:OKMINICSS_TOKEN_KIND_BOLD discard:NO];

    [self fireAssemblerSelector:@selector(parser:didMatchBold:)];
}

- (void)bold {
    [self parseRule:@selector(__bold) withMemo:_bold_memo];
}

- (void)__normal {
    
    [self match:OKMINICSS_TOKEN_KIND_NORMAL discard:NO];

    [self fireAssemblerSelector:@selector(parser:didMatchNormal:)];
}

- (void)normal {
    [self parseRule:@selector(__normal) withMemo:_normal_memo];
}

- (void)__italic {
    
    [self match:OKMINICSS_TOKEN_KIND_ITALIC discard:NO];

    [self fireAssemblerSelector:@selector(parser:didMatchItalic:)];
}

- (void)italic {
    [self parseRule:@selector(__italic) withMemo:_italic_memo];
}

@end