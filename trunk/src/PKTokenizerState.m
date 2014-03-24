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

#if PEGKIT
#import <PEGKit/PKTokenizerState.h>
#import <PEGKit/PKTokenizer.h>
#import <PEGKit/PKReader.h>
#else
#import <ParseKit/PKTokenizerState.h>
#import <ParseKit/PKTokenizer.h>
#import <ParseKit/PKReader.h>
#endif

#define STATE_COUNT 256

@interface PKTokenizer ()
- (PKTokenizerState *)defaultTokenizerStateFor:(PKUniChar)c;
@end

@interface PKTokenizerState ()
- (void)resetWithReader:(PKReader *)r;
- (void)append:(PKUniChar)c;
- (void)appendString:(NSString *)s;
- (NSString *)bufferedString;
- (PKTokenizerState *)nextTokenizerStateFor:(PKUniChar)c tokenizer:(PKTokenizer *)t;

@property (nonatomic, retain) NSMutableString *stringbuf;
@property (nonatomic, retain) NSMutableArray *fallbackStates;
@end

@implementation PKTokenizerState

- (void)dealloc {
    self.stringbuf = nil;
    self.fallbackState = nil;
    self.fallbackStates = nil;
    [super dealloc];
}


- (PKToken *)nextTokenFromReader:(PKReader *)r startingWith:(PKUniChar)cin tokenizer:(PKTokenizer *)t {
    NSAssert1(0, @"%s must be overriden", __PRETTY_FUNCTION__);
    return nil;
}


- (void)setFallbackState:(PKTokenizerState *)state from:(PKUniChar)start to:(PKUniChar)end {
    NSParameterAssert(start >= 0 && start < STATE_COUNT);
    NSParameterAssert(end >= 0 && end < STATE_COUNT);
    
    if (!_fallbackStates) {
        self.fallbackStates = [NSMutableArray arrayWithCapacity:STATE_COUNT];

        for (NSInteger i = 0; i < STATE_COUNT; i++) {
            [_fallbackStates addObject:[NSNull null]];
        }
        
    }

    for (NSInteger i = start; i <= end; i++) {
        [_fallbackStates replaceObjectAtIndex:i withObject:state];
    }
}


- (void)resetWithReader:(PKReader *)r {
    self.stringbuf = [NSMutableString string];
    self.offset = r.offset - 1;
}


- (void)append:(PKUniChar)c {
    NSParameterAssert(c != PKEOF);
    NSAssert(_stringbuf, @"");
    [_stringbuf appendFormat:@"%C", (unichar)c];
}


- (void)appendString:(NSString *)s {
    NSParameterAssert(s);
    NSAssert(_stringbuf, @"");
    [_stringbuf appendString:s];
}


- (NSString *)bufferedString {
    return [[_stringbuf copy] autorelease];
}


- (PKTokenizerState *)nextTokenizerStateFor:(PKUniChar)c tokenizer:(PKTokenizer *)t {
    NSParameterAssert(c < STATE_COUNT);
    
    if (_fallbackStates) {
        id obj = [_fallbackStates objectAtIndex:c];
        if ([NSNull null] != obj) {
            return obj;
        }
    }
    
    if (_fallbackState) {
        return _fallbackState;
    } else {
        return [t defaultTokenizerStateFor:c];
    }
}

@end
