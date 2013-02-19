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

#import <ParseKit/PKNumberState.h>
#import <ParseKit/PKReader.h>
#import <ParseKit/PKToken.h>
#import <ParseKit/PKTokenizer.h>
#import <ParseKit/PKSymbolRootNode.h>
#import <ParseKit/PKSymbolState.h>
#import <ParseKit/PKTypes.h>

@interface PKToken ()
@property (nonatomic, readwrite) NSUInteger offset;
@end

@interface PKTokenizerState ()
- (void)resetWithReader:(PKReader *)r;
- (PKTokenizerState *)nextTokenizerStateFor:(PKUniChar)c tokenizer:(PKTokenizer *)t;
- (void)append:(PKUniChar)c;
- (void)appendString:(NSString *)s;
- (NSString *)bufferedString;

- (PKFloat)radixForPrefix:(NSString *)s;
- (PKFloat)radixForSuffix:(NSString *)s;
@property (nonatomic, retain) PKSymbolRootNode *prefixRootNode;
@property (nonatomic, retain) PKSymbolRootNode *suffixRootNode;
@property (nonatomic, retain) NSMutableDictionary *radixForPrefix;
@property (nonatomic, retain) NSMutableDictionary *radixForSuffix;
@end

@interface PKNumberState ()
- (PKFloat)absorbDigitsFromReader:(PKReader *)r;
- (PKFloat)value;
- (void)parseLeftSideFromReader:(PKReader *)r;
- (void)parseRightSideFromReader:(PKReader *)r;
- (void)parseExponentFromReader:(PKReader *)r;
- (void)reset:(PKUniChar)cin;
- (void)checkForHex:(PKReader *)r;
- (void)checkForOctal;
@end

@implementation PKNumberState

- (id)init {
    self = [super init];
    if (self) {
        self.prefixRootNode = [[[PKSymbolRootNode alloc] init] autorelease];
        self.suffixRootNode = [[[PKSymbolRootNode alloc] init] autorelease];
        self.radixForPrefix = [NSMutableDictionary dictionary];
        self.radixForSuffix = [NSMutableDictionary dictionary];
        
//        [self addPrefix:@"0b" forRadix:2.0];
        [self addPrefix:@"0"  forRadix:8.0];
//        [self addPrefix:@"0o" forRadix:8.0];
        [self addPrefix:@"0x" forRadix:16.0];
//
//        [self addPrefix:@"%"  forRadix:2.0];
//        [self addPrefix:@"$"  forRadix:16.0];
//
//        [self addSuffix:@"b"  forRadix:2.0];
//        [self addSuffix:@"h"  forRadix:16.0];

        self.allowsFloatingPoint = YES;
        self.positivePrefix = '+';
        self.negativePrefix = '-';
        self.groupingSeparator = ',';
        self.decimalSeparator = '.';
    }
    return self;
}


- (void)dealloc {
    self.prefixRootNode = nil;
    self.suffixRootNode = nil;
    self.radixForPrefix = nil;
    self.radixForSuffix = nil;
    [super dealloc];
}


- (void)addPrefix:(NSString *)s forRadix:(PKFloat)f {
    NSParameterAssert([s length]);
    NSParameterAssert(f > 0.0);
    NSAssert(radixForPrefix, @"");
    
    [prefixRootNode add:s];
    NSNumber *n = [NSNumber numberWithDouble:f];
    radixForPrefix[s] = n;
}


- (void)addSuffix:(NSString *)s forRadix:(PKFloat)f {
    NSParameterAssert([s length]);
    NSParameterAssert(f > 0.0);
    NSAssert(radixForSuffix, @"");
    
    [prefixRootNode add:s];
    NSNumber *n = [NSNumber numberWithDouble:f];
    radixForSuffix[s] = n;
}


- (PKFloat)radixForPrefix:(NSString *)s {
    NSParameterAssert([s length]);
    NSAssert(radixForPrefix, @"");
    
    NSNumber *n = radixForPrefix[s];
    PKFloat f = [n doubleValue];
    return f;
}


- (PKFloat)radixForSuffix:(NSString *)s {
    NSParameterAssert([s length]);
    NSAssert(radixForSuffix, @"");
    
    NSNumber *n = radixForSuffix[s];
    PKFloat f = [n doubleValue];
    return f;
}


- (PKToken *)nextTokenFromReader:(PKReader *)r startingWith:(PKUniChar)cin tokenizer:(PKTokenizer *)t {
    NSParameterAssert(r);
    NSParameterAssert(t);
    NSAssert1(!(allowsGroupingSeparator && (decimalSeparator == groupingSeparator)), @"You have configured your tokenizer's numberState with the same decimal and grouping separator: `%C`. You don't want to do that.", (unichar)decimalSeparator);

    [self resetWithReader:r];
    isNegative = NO;
    originalCin = cin;
    
    NSString *prefix = [prefixRootNode nextSymbol:r startingWith:cin];
    PKFloat radix = [self radixForPrefix:prefix];
    if (radix > 0.0) {
        [self appendString:prefix];
        base = radix;
        isHex = base == 16.0; // REMOVE
    } else {
        [r unread:[prefix length]];
        prefix = nil;
    }
    cin = [r read];
    
    if (negativePrefix == cin) {
        isNegative = YES;
        cin = [r read];
        [self append:negativePrefix];
    } else if (positivePrefix == cin) {
        cin = [r read];
        [self append:positivePrefix];
    }
    
    [self reset:cin];
    if (decimalSeparator == c) {
        if (allowsFloatingPoint) {
            [self parseRightSideFromReader:r];
        }
    } else {
        [self parseLeftSideFromReader:r];
        if (isDecimal && allowsFloatingPoint) {
            [self parseRightSideFromReader:r];
        }
    }
    
    // erroneous ., +, -, or 0x
    if (!gotADigit) {
        if ([prefix length] && '0' == [prefix characterAtIndex:0]) {
            [r unread];
            return [PKToken tokenWithTokenType:PKTokenTypeNumber stringValue:@"0" floatValue:0.0];
        } else {
            if ((originalCin == positivePrefix || originalCin == negativePrefix) && PKEOF != c) { // ??
                [r unread];
            }
            return [[self nextTokenizerStateFor:originalCin tokenizer:t] nextTokenFromReader:r startingWith:originalCin tokenizer:t];
        }
    }
    
    if (PKEOF != c) {
        [r unread];
    }

    if (isNegative) {
        floatValue = -floatValue;
    }
    
    PKToken *tok = [PKToken tokenWithTokenType:PKTokenTypeNumber stringValue:[self bufferedString] floatValue:[self value]];
    tok.offset = offset;
    return tok;
}


- (PKFloat)value {
    PKFloat result = (PKFloat)floatValue;
    
    for (NSUInteger i = 0; i < exp; i++) {
        if (isNegativeExp) {
            result /= (PKFloat)10.0;
        } else {
            result *= (PKFloat)10.0;
        }
    }
    
    return (PKFloat)result;
}


- (PKFloat)absorbDigitsFromReader:(PKReader *)r {
    PKFloat divideBy = 1.0;
    PKFloat v = 0.0;
    BOOL isHexAlpha = NO;
    
    while (1) {
        isHexAlpha = NO;
        if (allowsHexadecimalNotation) {
            [self checkForHex:r];
//            if ((c >= 'a' && c <= 'f') || (c >= 'A' && c <= 'F')) {
                isHexAlpha = ishexnumber(c);
//            }
        }
        
        if (isdigit(c) || isHexAlpha) {
            [self append:c];
            len++;
            gotADigit = YES;

            if (allowsOctalNotation) {
                [self checkForOctal];
            }
            
            if (isHexAlpha) {
//                if (c >= 'a' && c <= 'f') {
                    c = toupper(c);
//                }
                c -= 7;
            }
            v = v * base + (c - '0');
            c = [r read];
            if (isFraction) {
                divideBy *= base;
            }
        } else if (allowsGroupingSeparator && groupingSeparator == c) {
            [self append:c];
            len++;
            c = [r read];
        } else {
            break;
        }
    }
    
    if (isFraction) {
        v = v / divideBy;
    }

    return (PKFloat)v;
}


- (void)parseLeftSideFromReader:(PKReader *)r {
    isFraction = NO;
    floatValue = [self absorbDigitsFromReader:r];
}


- (void)parseRightSideFromReader:(PKReader *)r {
    if (decimalSeparator == c) {
        PKUniChar n = [r read];
        BOOL nextIsDigit = isdigit(n);
        if (PKEOF != n) {
            [r unread];
        }

        if (nextIsDigit || allowsTrailingDecimalSeparator) {
            [self append:decimalSeparator];
            if (nextIsDigit) {
                c = [r read];
                isFraction = YES;
                floatValue += [self absorbDigitsFromReader:r];
            }
        }
    }
    
    if (allowsScientificNotation) {
        [self parseExponentFromReader:r];
    }
}


- (void)parseExponentFromReader:(PKReader *)r {
    NSParameterAssert(r);    
    if ('e' == c || 'E' == c) {
        PKUniChar e = c;
        c = [r read];
        
        BOOL hasExp = isdigit(c);
        isNegativeExp = (negativePrefix == c);
        BOOL positiveExp = (positivePrefix == c);
        
        if (!hasExp && (isNegativeExp || positiveExp)) {
            c = [r read];
            hasExp = isdigit(c);
        }
        if (PKEOF != c) {
            [r unread];
        }
        if (hasExp) {
            [self append:e];
            if (isNegativeExp) {
                [self append:negativePrefix];
            } else if (positiveExp) {
                [self append:positivePrefix];
            }
            c = [r read];
            isFraction = NO;
            exp = [self absorbDigitsFromReader:r];
        }
    }
}


- (void)reset:(PKUniChar)cin {
    c = cin;
    firstNum = cin;
    gotADigit = NO;
    isFraction = NO;
    isDecimal = YES;
    isHex = NO;
    len = 0;
    base = (PKFloat)10.0;
    floatValue = (PKFloat)0.0;
    exp = (PKFloat)0.0;
    isNegativeExp = NO;
}


- (void)checkForHex:(PKReader *)r {
    if ('x' == c && '0' == firstNum && !isFraction && 1 == len) {
        [self append:c];
        len++;
        c = [r read];
        isDecimal = NO;
        base = (PKFloat)16.0;
        isHex = YES;
        gotADigit = NO;
    }
}


- (void)checkForOctal {
    if ('0' == firstNum && !isFraction && isDecimal && 2 == len) {
        isDecimal = NO;
        base = (PKFloat)8.0;
    }
}

@synthesize allowsTrailingDecimalSeparator;
@synthesize allowsScientificNotation;
@synthesize allowsOctalNotation;
@synthesize allowsHexadecimalNotation;
@synthesize allowsFloatingPoint;
@synthesize allowsGroupingSeparator;
@synthesize positivePrefix;
@synthesize negativePrefix;
@synthesize groupingSeparator;
@synthesize decimalSeparator;
@synthesize prefixRootNode;
@synthesize suffixRootNode;
@synthesize radixForPrefix;
@synthesize radixForSuffix;
@end
