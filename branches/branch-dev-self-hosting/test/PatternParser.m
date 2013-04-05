#import "PatternParser.h"
#import <ParseKit/ParseKit.h>
#import "PKSRecognitionException.h"

#define LT(i) [self LT:(i)]
#define LA(i) [self LA:(i)]
#define LS(i) [self LS:(i)]
#define LF(i) [self LF:(i)]

#define POP()       [self._assembly pop]
#define POP_STR()   [self _popString]
#define POP_TOK()   [self _popToken]
#define POP_BOOL()  [self _popBool]
#define POP_INT()   [self _popInteger]
#define POP_FLOAT() [self _popDouble]

#define PUSH(obj)     [self._assembly push:(id)(obj)]
#define PUSH_BOOL(yn) [self _pushBool:(BOOL)(yn)]
#define PUSH_INT(i)   [self _pushInteger:(NSInteger)(i)]
#define PUSH_FLOAT(f) [self _pushDouble:(double)(f)]

#define EQ(a, b) [(a) isEqual:(b)]
#define NE(a, b) (![(a) isEqual:(b)])
#define EQ_IGNORE_CASE(a, b) (NSOrderedSame == [(a) compare:(b)])

#define ABOVE(fence) [self._assembly objectsAbove:(fence)]

#define LOG(obj) do { NSLog(@"%@", (obj)); } while (0);
#define PRINT(str) do { printf("%s\n", (str)); } while (0);

@interface PKSParser ()
@property (nonatomic, retain) PKAssembly *_assembly;
@end

@interface PatternParser ()
@property (nonatomic, retain) NSDictionary *_tokenKindTab;
@end

@implementation PatternParser

- (id)init {
	self = [super init];
	if (self) {
		self._tokenKindTab = @{
        };
	}
	return self;
}

- (void)dealloc {
	self._tokenKindTab = nil;
	[super dealloc];
}

- (NSInteger)tokenKindForString:(NSString *)s {
    NSInteger x = TOKEN_KIND_BUILTIN_INVALID;

    id obj = _tokenKindTab[s];
    if (obj) {
        x = [obj integerValue];
    }
    
    return x;
}

- (void)_start {
    
        [self s]; 

    [self fireAssemblerSelector:@selector(parser:didMatch_start:)];
}

- (void)s {
    
        static NSRegularExpression *regex = nil;
        if (!regex) {
            NSError *err = nil;
            regex = [[NSRegularExpression regularExpressionWithPattern:@"\\w+" options:NSRegularExpressionCaseInsensitive error:&err] retain];
            if (!regex) {
                if (err) NSLog(@"%@", err);
            }
        }
        
        NSString *str = LS(1);
        
        if ([regex numberOfMatchesInString:str options:0 range:NSMakeRange(0, [str length])]) {
            [self match:TOKEN_KIND_BUILTIN_ANY]; 
        }

    [self fireAssemblerSelector:@selector(parser:didMatchS:)];
}

@synthesize _tokenKindTab = _tokenKindTab;
@end