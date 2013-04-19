#import "HTMLParser.h"
#import <ParseKit/ParseKit.h>
#import "PKSRecognitionException.h"

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

@interface HTMLParser ()
@property (nonatomic, retain) NSMutableDictionary *anything_memo;
@property (nonatomic, retain) NSMutableDictionary *procInstr_memo;
@property (nonatomic, retain) NSMutableDictionary *text_memo;
@property (nonatomic, retain) NSMutableDictionary *tag_memo;
@property (nonatomic, retain) NSMutableDictionary *emptyTag_memo;
@property (nonatomic, retain) NSMutableDictionary *startTag_memo;
@property (nonatomic, retain) NSMutableDictionary *endTag_memo;
@property (nonatomic, retain) NSMutableDictionary *tagName_memo;
@property (nonatomic, retain) NSMutableDictionary *attr_memo;
@property (nonatomic, retain) NSMutableDictionary *attrName_memo;
@property (nonatomic, retain) NSMutableDictionary *attrValue_memo;
@property (nonatomic, retain) NSMutableDictionary *eq_memo;
@property (nonatomic, retain) NSMutableDictionary *lt_memo;
@property (nonatomic, retain) NSMutableDictionary *gt_memo;
@property (nonatomic, retain) NSMutableDictionary *fwdSlash_memo;
@property (nonatomic, retain) NSMutableDictionary *comment_memo;
@end

@implementation HTMLParser

- (id)init {
	self = [super init];
	if (self) {
        self._tokenKindTab[@"<?,?>"] = @(TOKEN_KIND_PROCINSTR);
        self._tokenKindTab[@"="] = @(TOKEN_KIND_EQ);
        self._tokenKindTab[@"/"] = @(TOKEN_KIND_FWDSLASH);
        self._tokenKindTab[@">"] = @(TOKEN_KIND_GT);
        self._tokenKindTab[@"<"] = @(TOKEN_KIND_LT);

        self.anything_memo = [NSMutableDictionary dictionary];
        self.procInstr_memo = [NSMutableDictionary dictionary];
        self.text_memo = [NSMutableDictionary dictionary];
        self.tag_memo = [NSMutableDictionary dictionary];
        self.emptyTag_memo = [NSMutableDictionary dictionary];
        self.startTag_memo = [NSMutableDictionary dictionary];
        self.endTag_memo = [NSMutableDictionary dictionary];
        self.tagName_memo = [NSMutableDictionary dictionary];
        self.attr_memo = [NSMutableDictionary dictionary];
        self.attrName_memo = [NSMutableDictionary dictionary];
        self.attrValue_memo = [NSMutableDictionary dictionary];
        self.eq_memo = [NSMutableDictionary dictionary];
        self.lt_memo = [NSMutableDictionary dictionary];
        self.gt_memo = [NSMutableDictionary dictionary];
        self.fwdSlash_memo = [NSMutableDictionary dictionary];
        self.comment_memo = [NSMutableDictionary dictionary];
    }
	return self;
}

- (void)dealloc {
    self.anything_memo = nil;
    self.procInstr_memo = nil;
    self.text_memo = nil;
    self.tag_memo = nil;
    self.emptyTag_memo = nil;
    self.startTag_memo = nil;
    self.endTag_memo = nil;
    self.tagName_memo = nil;
    self.attr_memo = nil;
    self.attrName_memo = nil;
    self.attrValue_memo = nil;
    self.eq_memo = nil;
    self.lt_memo = nil;
    self.gt_memo = nil;
    self.fwdSlash_memo = nil;
    self.comment_memo = nil;

    [super dealloc];
}

- (void)_clearMemo {
    [_anything_memo removeAllObjects];
    [_procInstr_memo removeAllObjects];
    [_text_memo removeAllObjects];
    [_tag_memo removeAllObjects];
    [_emptyTag_memo removeAllObjects];
    [_startTag_memo removeAllObjects];
    [_endTag_memo removeAllObjects];
    [_tagName_memo removeAllObjects];
    [_attr_memo removeAllObjects];
    [_attrName_memo removeAllObjects];
    [_attrValue_memo removeAllObjects];
    [_eq_memo removeAllObjects];
    [_lt_memo removeAllObjects];
    [_gt_memo removeAllObjects];
    [_fwdSlash_memo removeAllObjects];
    [_comment_memo removeAllObjects];
}

- (void)_start {
    
    [self execute:(id)^{
        
    PKTokenizer *t = self.tokenizer;

    // symbols
    [t.symbolState add:@"<!--"];
    [t.symbolState add:@"-->"];
    [t.symbolState add:@"<?"];
    [t.symbolState add:@"?>"];

	// comments	
    [t setTokenizerState:t.commentState from:'<' to:'<'];
    [t.commentState addMultiLineStartMarker:@"<!--" endMarker:@"-->"];
    [t.commentState setFallbackState:t.delimitState from:'<' to:'<'];

	// pi
	[t.delimitState addStartMarker:@"<?" endMarker:@"?>" allowedCharacterSet:nil];
    [t.delimitState setFallbackState:t.symbolState from:'<' to:'<'];

    }];
    while ([self predicts:TOKEN_KIND_BUILTIN_COMMENT, TOKEN_KIND_LT, TOKEN_KIND_PROCINSTR, 0]) {
        if ([self speculate:^{ [self anything]; }]) {
            [self anything]; 
        } else {
            break;
        }
    }

    [self fireAssemblerSelector:@selector(parser:didMatch_start:)];
}

- (void)__anything {
    
    if ([self speculate:^{ [self tag]; }]) {
        [self tag]; 
    } else if ([self speculate:^{ [self text]; }]) {
        [self text]; 
    } else if ([self speculate:^{ [self procInstr]; }]) {
        [self procInstr]; 
    } else if ([self speculate:^{ [self comment]; }]) {
        [self comment]; 
    } else {
        [self raise:@"no viable alternative found in anything"];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchAnything:)];
}

- (void)anything {
    [self parseRule:@selector(__anything) withMemo:_anything_memo];
}

- (void)__procInstr {
    
    [self match:TOKEN_KIND_PROCINSTR]; 

    [self fireAssemblerSelector:@selector(parser:didMatchProcInstr:)];
}

- (void)procInstr {
    [self parseRule:@selector(__procInstr) withMemo:_procInstr_memo];
}

- (void)__text {
    
    if (![self predicts:TOKEN_KIND_LT, 0]) {
        [self match:TOKEN_KIND_BUILTIN_ANY];
    } else {
        [self raise:@"negation test failed in text"];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchText:)];
}

- (void)text {
    [self parseRule:@selector(__text) withMemo:_text_memo];
}

- (void)__tag {
    
    if ([self speculate:^{ [self emptyTag]; }]) {
        [self emptyTag]; 
    } else if ([self speculate:^{ [self startTag]; }]) {
        [self startTag]; 
    } else if ([self speculate:^{ [self endTag]; }]) {
        [self endTag]; 
    } else {
        [self raise:@"no viable alternative found in tag"];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchTag:)];
}

- (void)tag {
    [self parseRule:@selector(__tag) withMemo:_tag_memo];
}

- (void)__emptyTag {
    
    [self lt]; 
    [self tagName]; 
    while ([self predicts:TOKEN_KIND_BUILTIN_WORD, 0]) {
        if ([self speculate:^{ [self attr]; }]) {
            [self attr]; 
        } else {
            break;
        }
    }
    [self fwdSlash]; 
    [self gt]; 

    [self fireAssemblerSelector:@selector(parser:didMatchEmptyTag:)];
}

- (void)emptyTag {
    [self parseRule:@selector(__emptyTag) withMemo:_emptyTag_memo];
}

- (void)__startTag {
    
    [self lt]; 
    [self tagName]; 
    while ([self predicts:TOKEN_KIND_BUILTIN_WORD, 0]) {
        if ([self speculate:^{ [self attr]; }]) {
            [self attr]; 
        } else {
            break;
        }
    }
    [self gt]; 

    [self fireAssemblerSelector:@selector(parser:didMatchStartTag:)];
}

- (void)startTag {
    [self parseRule:@selector(__startTag) withMemo:_startTag_memo];
}

- (void)__endTag {
    
    [self lt]; 
    [self fwdSlash]; 
    [self tagName]; 
    [self gt]; 

    [self fireAssemblerSelector:@selector(parser:didMatchEndTag:)];
}

- (void)endTag {
    [self parseRule:@selector(__endTag) withMemo:_endTag_memo];
}

- (void)__tagName {
    
    [self Word]; 

    [self fireAssemblerSelector:@selector(parser:didMatchTagName:)];
}

- (void)tagName {
    [self parseRule:@selector(__tagName) withMemo:_tagName_memo];
}

- (void)__attr {
    
    [self attrName]; 
    if ([self speculate:^{ [self eq]; [self attrValue]; }]) {
        [self eq]; 
        [self attrValue]; 
    }

    [self fireAssemblerSelector:@selector(parser:didMatchAttr:)];
}

- (void)attr {
    [self parseRule:@selector(__attr) withMemo:_attr_memo];
}

- (void)__attrName {
    
    [self Word]; 

    [self fireAssemblerSelector:@selector(parser:didMatchAttrName:)];
}

- (void)attrName {
    [self parseRule:@selector(__attrName) withMemo:_attrName_memo];
}

- (void)__attrValue {
    
    if ([self predicts:TOKEN_KIND_BUILTIN_WORD, 0]) {
        [self Word]; 
    } else if ([self predicts:TOKEN_KIND_BUILTIN_QUOTEDSTRING, 0]) {
        [self QuotedString]; 
    } else {
        [self raise:@"no viable alternative found in attrValue"];
    }

    [self fireAssemblerSelector:@selector(parser:didMatchAttrValue:)];
}

- (void)attrValue {
    [self parseRule:@selector(__attrValue) withMemo:_attrValue_memo];
}

- (void)__eq {
    
    [self match:TOKEN_KIND_EQ]; 

    [self fireAssemblerSelector:@selector(parser:didMatchEq:)];
}

- (void)eq {
    [self parseRule:@selector(__eq) withMemo:_eq_memo];
}

- (void)__lt {
    
    [self match:TOKEN_KIND_LT]; 

    [self fireAssemblerSelector:@selector(parser:didMatchLt:)];
}

- (void)lt {
    [self parseRule:@selector(__lt) withMemo:_lt_memo];
}

- (void)__gt {
    
    [self match:TOKEN_KIND_GT]; 

    [self fireAssemblerSelector:@selector(parser:didMatchGt:)];
}

- (void)gt {
    [self parseRule:@selector(__gt) withMemo:_gt_memo];
}

- (void)__fwdSlash {
    
    [self match:TOKEN_KIND_FWDSLASH]; 

    [self fireAssemblerSelector:@selector(parser:didMatchFwdSlash:)];
}

- (void)fwdSlash {
    [self parseRule:@selector(__fwdSlash) withMemo:_fwdSlash_memo];
}

- (void)__comment {
    
    [self Comment]; 

    [self fireAssemblerSelector:@selector(parser:didMatchComment:)];
}

- (void)comment {
    [self parseRule:@selector(__comment) withMemo:_comment_memo];
}

@end