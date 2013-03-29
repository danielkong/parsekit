//  Copyright 2010 Todd Ditchendorf
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.

#import "PKSTokenAssembly.h"
#import <ParseKit/PKTokenizer.h>
#import <ParseKit/PKToken.h>

@interface PKAssembly ()
@property (nonatomic, readwrite, retain) NSString *defaultCursor;
@end

@interface PKSTokenAssembly ()
@property (nonatomic, retain) PKTokenizer *tokenizer;
@property (nonatomic, retain) NSMutableArray *tokens;
@end

@implementation PKSTokenAssembly

+ (PKSTokenAssembly *)assemblyWithTokenizer:(PKTokenizer *)t {
    return [[[self alloc] initWithTokenzier:t] autorelease];
}


- (id)initWithTokenzier:(PKTokenizer *)t {
    self = [super initWithString:nil];
    if (self) {
        self.tokenizer = t;
#if defined(NDEBUG)
        self.gathersConsumedTokens = NO;
        self.defaultCursor = @"";
#else
        self.gathersConsumedTokens = YES;
#endif
    }
    return self;
}


- (void)dealloc {
    self.tokenizer = nil;
    self.tokens = nil;
    [super dealloc];
}


- (id)copyWithZone:(NSZone *)zone {
    PKSTokenAssembly *a = (PKSTokenAssembly *)[super copyWithZone:zone];
    a->tokenizer = nil; // optimization
    a->preservesWhitespaceTokens = preservesWhitespaceTokens;
    if (tokens) a->tokens = [tokens mutableCopy];
    return a;
}


- (void)consume:(PKToken *)tok {
    if (preservesWhitespaceTokens || tok.tokenType != PKTokenTypeWhitespace) {
        [self push:tok];
        if (gathersConsumedTokens) {
            if (!tokens) {
                self.tokens = [NSMutableArray array];
            }
            ++index;
            [tokens addObject:tok];
        }
    }
}


- (id)peek {
    NSAssert2(0, @"%s cannot call %@", __PRETTY_FUNCTION__, [self class]);
    return nil;
}


- (id)next {
    NSAssert2(0, @"%s cannot call %@", __PRETTY_FUNCTION__, [self class]);
    return nil;
}


- (BOOL)hasMore {
    return YES;
}


- (NSUInteger)length {
    return NSNotFound;
} 


- (NSUInteger)objectsConsumed {
    return index;
}


- (NSUInteger)objectsRemaining {
    return NSNotFound;
}


- (NSString *)consumedObjectsJoinedByString:(NSString *)delimiter {
    NSParameterAssert(delimiter);
    return [self objectsFrom:0 to:self.objectsConsumed separatedBy:delimiter];
}


- (NSString *)remainingObjectsJoinedByString:(NSString *)delimiter {
    NSParameterAssert(delimiter);
    return @"";
}


- (NSString *)lastConsumedObjects:(NSUInteger)len joinedByString:(NSString *)delimiter {
    NSParameterAssert(delimiter);
    
    NSArray *toks = self.tokens;
    NSUInteger end = self.objectsConsumed;

    len = MIN(end, len);
    NSUInteger loc = end - len;

    NSAssert(loc < [toks count], @"");
    NSAssert(len <= [toks count], @"");
    NSAssert(loc + len <= [toks count], @"");
    
    NSRange r = NSMakeRange(loc, len);
    NSArray *objs = [toks subarrayWithRange:r];
    
    NSString *s = [objs componentsJoinedByString:delimiter];
    return s;
}


#pragma mark -
#pragma mark Private

- (NSString *)objectsFrom:(NSUInteger)start to:(NSUInteger)end separatedBy:(NSString *)delimiter {
    NSParameterAssert(delimiter);
    NSParameterAssert(start <= end);

    NSMutableString *s = [NSMutableString string];
    NSArray *toks = self.tokens;

    NSParameterAssert(end <= [toks count]);

    for (NSInteger i = start; i < end; i++) {
        PKToken *tok = [toks objectAtIndex:i];
        [s appendString:tok.stringValue];
        if (end - 1 != i) {
            [s appendString:delimiter];
        }
    }
    
    return [[s copy] autorelease];
}

@synthesize tokenizer;
@synthesize tokens;
@synthesize preservesWhitespaceTokens;
@synthesize gathersConsumedTokens;
@end
