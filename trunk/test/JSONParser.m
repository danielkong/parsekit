#import "JSONParser.h"
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

@interface JSONParser ()
@property (nonatomic, retain) NSMutableDictionary *object_memo;
@property (nonatomic, retain) NSMutableDictionary *objectContent_memo;
@property (nonatomic, retain) NSMutableDictionary *actualObject_memo;
@property (nonatomic, retain) NSMutableDictionary *property_memo;
@property (nonatomic, retain) NSMutableDictionary *commaProperty_memo;
@property (nonatomic, retain) NSMutableDictionary *propertyName_memo;
@property (nonatomic, retain) NSMutableDictionary *array_memo;
@property (nonatomic, retain) NSMutableDictionary *arrayContent_memo;
@property (nonatomic, retain) NSMutableDictionary *actualArray_memo;
@property (nonatomic, retain) NSMutableDictionary *commaValue_memo;
@property (nonatomic, retain) NSMutableDictionary *value_memo;
@property (nonatomic, retain) NSMutableDictionary *comment_memo;
@property (nonatomic, retain) NSMutableDictionary *string_memo;
@property (nonatomic, retain) NSMutableDictionary *number_memo;
@property (nonatomic, retain) NSMutableDictionary *nullLiteral_memo;
@property (nonatomic, retain) NSMutableDictionary *trueLiteral_memo;
@property (nonatomic, retain) NSMutableDictionary *falseLiteral_memo;
@property (nonatomic, retain) NSMutableDictionary *openCurly_memo;
@property (nonatomic, retain) NSMutableDictionary *closeCurly_memo;
@property (nonatomic, retain) NSMutableDictionary *openBracket_memo;
@property (nonatomic, retain) NSMutableDictionary *closeBracket_memo;
@property (nonatomic, retain) NSMutableDictionary *comma_memo;
@property (nonatomic, retain) NSMutableDictionary *colon_memo;
@end

@implementation JSONParser

- (id)init {
	self = [super init];
	if (self) {
        self._tokenKindTab[@"false"] = @(JSON_TOKEN_KIND_FALSELITERAL);
        self._tokenKindTab[@"}"] = @(JSON_TOKEN_KIND_CLOSECURLY);
        self._tokenKindTab[@"["] = @(JSON_TOKEN_KIND_OPENBRACKET);
        self._tokenKindTab[@"null"] = @(JSON_TOKEN_KIND_NULLLITERAL);
        self._tokenKindTab[@","] = @(JSON_TOKEN_KIND_COMMA);
        self._tokenKindTab[@"true"] = @(JSON_TOKEN_KIND_TRUELITERAL);
        self._tokenKindTab[@"]"] = @(JSON_TOKEN_KIND_CLOSEBRACKET);
        self._tokenKindTab[@"{"] = @(JSON_TOKEN_KIND_OPENCURLY);
        self._tokenKindTab[@":"] = @(JSON_TOKEN_KIND_COLON);

        self.object_memo = [NSMutableDictionary dictionary];
        self.objectContent_memo = [NSMutableDictionary dictionary];
        self.actualObject_memo = [NSMutableDictionary dictionary];
        self.property_memo = [NSMutableDictionary dictionary];
        self.commaProperty_memo = [NSMutableDictionary dictionary];
        self.propertyName_memo = [NSMutableDictionary dictionary];
        self.array_memo = [NSMutableDictionary dictionary];
        self.arrayContent_memo = [NSMutableDictionary dictionary];
        self.actualArray_memo = [NSMutableDictionary dictionary];
        self.commaValue_memo = [NSMutableDictionary dictionary];
        self.value_memo = [NSMutableDictionary dictionary];
        self.comment_memo = [NSMutableDictionary dictionary];
        self.string_memo = [NSMutableDictionary dictionary];
        self.number_memo = [NSMutableDictionary dictionary];
        self.nullLiteral_memo = [NSMutableDictionary dictionary];
        self.trueLiteral_memo = [NSMutableDictionary dictionary];
        self.falseLiteral_memo = [NSMutableDictionary dictionary];
        self.openCurly_memo = [NSMutableDictionary dictionary];
        self.closeCurly_memo = [NSMutableDictionary dictionary];
        self.openBracket_memo = [NSMutableDictionary dictionary];
        self.closeBracket_memo = [NSMutableDictionary dictionary];
        self.comma_memo = [NSMutableDictionary dictionary];
        self.colon_memo = [NSMutableDictionary dictionary];
    }
	return self;
}

- (void)dealloc {
    self.object_memo = nil;
    self.objectContent_memo = nil;
    self.actualObject_memo = nil;
    self.property_memo = nil;
    self.commaProperty_memo = nil;
    self.propertyName_memo = nil;
    self.array_memo = nil;
    self.arrayContent_memo = nil;
    self.actualArray_memo = nil;
    self.commaValue_memo = nil;
    self.value_memo = nil;
    self.comment_memo = nil;
    self.string_memo = nil;
    self.number_memo = nil;
    self.nullLiteral_memo = nil;
    self.trueLiteral_memo = nil;
    self.falseLiteral_memo = nil;
    self.openCurly_memo = nil;
    self.closeCurly_memo = nil;
    self.openBracket_memo = nil;
    self.closeBracket_memo = nil;
    self.comma_memo = nil;
    self.colon_memo = nil;

    [super dealloc];
}

- (void)_clearMemo {
    [_object_memo removeAllObjects];
    [_objectContent_memo removeAllObjects];
    [_actualObject_memo removeAllObjects];
    [_property_memo removeAllObjects];
    [_commaProperty_memo removeAllObjects];
    [_propertyName_memo removeAllObjects];
    [_array_memo removeAllObjects];
    [_arrayContent_memo removeAllObjects];
    [_actualArray_memo removeAllObjects];
    [_commaValue_memo removeAllObjects];
    [_value_memo removeAllObjects];
    [_comment_memo removeAllObjects];
    [_string_memo removeAllObjects];
    [_number_memo removeAllObjects];
    [_nullLiteral_memo removeAllObjects];
    [_trueLiteral_memo removeAllObjects];
    [_falseLiteral_memo removeAllObjects];
    [_openCurly_memo removeAllObjects];
    [_closeCurly_memo removeAllObjects];
    [_openBracket_memo removeAllObjects];
    [_closeBracket_memo removeAllObjects];
    [_comma_memo removeAllObjects];
    [_colon_memo removeAllObjects];
}

- (void)_start {
    
    [self execute:(id)^{
        
	PKTokenizer *t = self.tokenizer;
	
    // whitespace
    t.whitespaceState.reportsWhitespaceTokens = YES;
    self.assembly.preservesWhitespaceTokens = YES;

    // comments
	t.commentState.reportsCommentTokens = YES;
	[t setTokenizerState:t.commentState from:'/' to:'/'];
	[t.commentState addSingleLineStartMarker:@"//"];
	[t.commentState addMultiLineStartMarker:@"/*" endMarker:@"*/"];

    }];
    if ([self predicts:JSON_TOKEN_KIND_OPENBRACKET, 0]) {
        [self array]; 
    } else if ([self predicts:JSON_TOKEN_KIND_OPENCURLY, 0]) {
        [self object]; 
    }
    if ([self predicts:TOKEN_KIND_BUILTIN_COMMENT, 0]) {
        [self comment]; 
    }

}

- (void)__object {
    
    [self openCurly]; 
    if ([self predicts:TOKEN_KIND_BUILTIN_COMMENT, 0]) {
        [self comment]; 
    }
    [self objectContent]; 
    [self closeCurly]; 

}

- (void)object {
    [self parseRule:@selector(__object) withMemo:_object_memo];
}

- (void)__objectContent {
    
    if ([self predicts:TOKEN_KIND_BUILTIN_QUOTEDSTRING, 0]) {
        [self actualObject]; 
    }

}

- (void)objectContent {
    [self parseRule:@selector(__objectContent) withMemo:_objectContent_memo];
}

- (void)__actualObject {
    
    [self property]; 
    while ([self predicts:JSON_TOKEN_KIND_COMMA, 0]) {
        if ([self speculate:^{ [self commaProperty]; }]) {
            [self commaProperty]; 
        } else {
            break;
        }
    }

}

- (void)actualObject {
    [self parseRule:@selector(__actualObject) withMemo:_actualObject_memo];
}

- (void)__property {
    
    [self propertyName]; 
    [self colon]; 
    if ([self predicts:TOKEN_KIND_BUILTIN_COMMENT, 0]) {
        [self comment]; 
    }
    [self value]; 

}

- (void)property {
    [self parseRule:@selector(__property) withMemo:_property_memo];
}

- (void)__commaProperty {
    
    [self comma]; 
    if ([self predicts:TOKEN_KIND_BUILTIN_COMMENT, 0]) {
        [self comment]; 
    }
    [self property]; 

}

- (void)commaProperty {
    [self parseRule:@selector(__commaProperty) withMemo:_commaProperty_memo];
}

- (void)__propertyName {
    
    [self QuotedString]; 

    [self fireAssemblerSelector:@selector(parser:didMatchPropertyName:)];
}

- (void)propertyName {
    [self parseRule:@selector(__propertyName) withMemo:_propertyName_memo];
}

- (void)__array {
    
    [self openBracket]; 
    if ([self predicts:TOKEN_KIND_BUILTIN_COMMENT, 0]) {
        [self comment]; 
    }
    [self arrayContent]; 
    [self closeBracket]; 

}

- (void)array {
    [self parseRule:@selector(__array) withMemo:_array_memo];
}

- (void)__arrayContent {
    
    if ([self predicts:JSON_TOKEN_KIND_FALSELITERAL, JSON_TOKEN_KIND_NULLLITERAL, JSON_TOKEN_KIND_OPENBRACKET, JSON_TOKEN_KIND_OPENCURLY, JSON_TOKEN_KIND_TRUELITERAL, TOKEN_KIND_BUILTIN_NUMBER, TOKEN_KIND_BUILTIN_QUOTEDSTRING, 0]) {
        [self actualArray]; 
    }

}

- (void)arrayContent {
    [self parseRule:@selector(__arrayContent) withMemo:_arrayContent_memo];
}

- (void)__actualArray {
    
    [self value]; 
    while ([self predicts:JSON_TOKEN_KIND_COMMA, 0]) {
        if ([self speculate:^{ [self commaValue]; }]) {
            [self commaValue]; 
        } else {
            break;
        }
    }

}

- (void)actualArray {
    [self parseRule:@selector(__actualArray) withMemo:_actualArray_memo];
}

- (void)__commaValue {
    
    [self comma]; 
    if ([self predicts:TOKEN_KIND_BUILTIN_COMMENT, 0]) {
        [self comment]; 
    }
    [self value]; 

}

- (void)commaValue {
    [self parseRule:@selector(__commaValue) withMemo:_commaValue_memo];
}

- (void)__value {
    
    if ([self predicts:JSON_TOKEN_KIND_NULLLITERAL, 0]) {
        [self nullLiteral]; 
    } else if ([self predicts:JSON_TOKEN_KIND_TRUELITERAL, 0]) {
        [self trueLiteral]; 
    } else if ([self predicts:JSON_TOKEN_KIND_FALSELITERAL, 0]) {
        [self falseLiteral]; 
    } else if ([self predicts:TOKEN_KIND_BUILTIN_NUMBER, 0]) {
        [self number]; 
    } else if ([self predicts:TOKEN_KIND_BUILTIN_QUOTEDSTRING, 0]) {
        [self string]; 
    } else if ([self predicts:JSON_TOKEN_KIND_OPENBRACKET, 0]) {
        [self array]; 
    } else if ([self predicts:JSON_TOKEN_KIND_OPENCURLY, 0]) {
        [self object]; 
    } else {
        [self raise:@"no viable alternative found in value"];
    }
    if ([self predicts:TOKEN_KIND_BUILTIN_COMMENT, 0]) {
        [self comment]; 
    }

}

- (void)value {
    [self parseRule:@selector(__value) withMemo:_value_memo];
}

- (void)__comment {
    
    [self Comment]; 

    [self fireAssemblerSelector:@selector(parser:didMatchComment:)];
}

- (void)comment {
    [self parseRule:@selector(__comment) withMemo:_comment_memo];
}

- (void)__string {
    
    [self QuotedString]; 

    [self fireAssemblerSelector:@selector(parser:didMatchString:)];
}

- (void)string {
    [self parseRule:@selector(__string) withMemo:_string_memo];
}

- (void)__number {
    
    [self Number]; 

    [self fireAssemblerSelector:@selector(parser:didMatchNumber:)];
}

- (void)number {
    [self parseRule:@selector(__number) withMemo:_number_memo];
}

- (void)__nullLiteral {
    
    [self match:JSON_TOKEN_KIND_NULLLITERAL]; 

    [self fireAssemblerSelector:@selector(parser:didMatchNullLiteral:)];
}

- (void)nullLiteral {
    [self parseRule:@selector(__nullLiteral) withMemo:_nullLiteral_memo];
}

- (void)__trueLiteral {
    
    [self match:JSON_TOKEN_KIND_TRUELITERAL]; 

    [self fireAssemblerSelector:@selector(parser:didMatchTrueLiteral:)];
}

- (void)trueLiteral {
    [self parseRule:@selector(__trueLiteral) withMemo:_trueLiteral_memo];
}

- (void)__falseLiteral {
    
    [self match:JSON_TOKEN_KIND_FALSELITERAL]; 

    [self fireAssemblerSelector:@selector(parser:didMatchFalseLiteral:)];
}

- (void)falseLiteral {
    [self parseRule:@selector(__falseLiteral) withMemo:_falseLiteral_memo];
}

- (void)__openCurly {
    
    [self match:JSON_TOKEN_KIND_OPENCURLY]; 

    [self fireAssemblerSelector:@selector(parser:didMatchOpenCurly:)];
}

- (void)openCurly {
    [self parseRule:@selector(__openCurly) withMemo:_openCurly_memo];
}

- (void)__closeCurly {
    
    [self match:JSON_TOKEN_KIND_CLOSECURLY]; 

    [self fireAssemblerSelector:@selector(parser:didMatchCloseCurly:)];
}

- (void)closeCurly {
    [self parseRule:@selector(__closeCurly) withMemo:_closeCurly_memo];
}

- (void)__openBracket {
    
    [self match:JSON_TOKEN_KIND_OPENBRACKET]; 

    [self fireAssemblerSelector:@selector(parser:didMatchOpenBracket:)];
}

- (void)openBracket {
    [self parseRule:@selector(__openBracket) withMemo:_openBracket_memo];
}

- (void)__closeBracket {
    
    [self match:JSON_TOKEN_KIND_CLOSEBRACKET]; 

    [self fireAssemblerSelector:@selector(parser:didMatchCloseBracket:)];
}

- (void)closeBracket {
    [self parseRule:@selector(__closeBracket) withMemo:_closeBracket_memo];
}

- (void)__comma {
    
    [self match:JSON_TOKEN_KIND_COMMA]; 

    [self fireAssemblerSelector:@selector(parser:didMatchComma:)];
}

- (void)comma {
    [self parseRule:@selector(__comma) withMemo:_comma_memo];
}

- (void)__colon {
    
    [self match:JSON_TOKEN_KIND_COLON]; 

    [self fireAssemblerSelector:@selector(parser:didMatchColon:)];
}

- (void)colon {
    [self parseRule:@selector(__colon) withMemo:_colon_memo];
}

@end