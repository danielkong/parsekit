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
#import <PEGKit/PKCommentState.h>
#import <PEGKit/PKTokenizer.h>
#import <PEGKit/PKToken.h>
#import <PEGKit/PKReader.h>
#import <PEGKit/PKSymbolRootNode.h>
#import <PEGKit/PKSingleLineCommentState.h>
#import <PEGKit/PKMultiLineCommentState.h>
#else
#import <ParseKit/PKCommentState.h>
#import <ParseKit/PKTokenizer.h>
#import <ParseKit/PKToken.h>
#import <ParseKit/PKReader.h>
#import <ParseKit/PKSymbolRootNode.h>
#import <ParseKit/PKSingleLineCommentState.h>
#import <ParseKit/PKMultiLineCommentState.h>
#endif

@interface PKToken ()
@property (nonatomic, readwrite) NSUInteger offset;
@end

@interface PKTokenizerState ()
- (void)resetWithReader:(PKReader *)r;
- (PKTokenizerState *)nextTokenizerStateFor:(PKUniChar)c tokenizer:(PKTokenizer *)t;
@end

@interface PKCommentState ()
@property (nonatomic, retain) PKSymbolRootNode *rootNode;
@property (nonatomic, retain) PKSingleLineCommentState *singleLineState;
@property (nonatomic, retain) PKMultiLineCommentState *multiLineState;
@end

@interface PKSingleLineCommentState ()
- (void)addStartMarker:(NSString *)start;
- (void)removeStartMarker:(NSString *)start;
@property (nonatomic, retain) NSMutableArray *startMarkers;
@property (nonatomic, retain) NSString *currentStartMarker;
@end

@interface PKMultiLineCommentState ()
- (void)addStartMarker:(NSString *)start endMarker:(NSString *)end;
- (void)removeStartMarker:(NSString *)start;
@property (nonatomic, retain) NSMutableArray *startMarkers;
@property (nonatomic, retain) NSMutableArray *endMarkers;
@property (nonatomic, copy) NSString *currentStartMarker;
@end

@implementation PKCommentState

- (id)init {
    self = [super init];
    if (self) {
        self.rootNode = [[[PKSymbolRootNode alloc] init] autorelease];
        self.singleLineState = [[[PKSingleLineCommentState alloc] init] autorelease];
        self.multiLineState = [[[PKMultiLineCommentState alloc] init] autorelease];
    }
    return self;
}


- (void)dealloc {
    self.rootNode = nil;
    self.singleLineState = nil;
    self.multiLineState = nil;
    [super dealloc];
}


- (void)addSingleLineStartMarker:(NSString *)start {
    NSParameterAssert([start length]);
    [_rootNode add:start];
    [_singleLineState addStartMarker:start];
}


- (void)removeSingleLineStartMarker:(NSString *)start {
    NSParameterAssert([start length]);
    [_rootNode remove:start];
    [_singleLineState removeStartMarker:start];
}


- (void)addMultiLineStartMarker:(NSString *)start endMarker:(NSString *)end {
    NSParameterAssert([start length]);
    NSParameterAssert([end length]);
    [_rootNode add:start];
    [_rootNode add:end];
    [_multiLineState addStartMarker:start endMarker:end];
}


- (void)removeMultiLineStartMarker:(NSString *)start {
    NSParameterAssert([start length]);
    [_rootNode remove:start];
    [_multiLineState removeStartMarker:start];
}


- (PKToken *)nextTokenFromReader:(PKReader *)r startingWith:(PKUniChar)cin tokenizer:(PKTokenizer *)t {
    NSParameterAssert(r);
    NSParameterAssert(t);

    [self resetWithReader:r];

    NSString *symbol = [_rootNode nextSymbol:r startingWith:cin];
    PKToken *tok = nil;
    
    while ([symbol length]) {
        if ([_multiLineState.startMarkers containsObject:symbol]) {
            _multiLineState.currentStartMarker = symbol;
            tok = [_multiLineState nextTokenFromReader:r startingWith:cin tokenizer:t];
            if (tok.isComment) {
                tok.offset = self.offset;
            }
        } else if ([_singleLineState.startMarkers containsObject:symbol]) {
            _singleLineState.currentStartMarker = symbol;
            tok = [_singleLineState nextTokenFromReader:r startingWith:cin tokenizer:t];
            if (tok.isComment) {
                tok.offset = self.offset;
            }
        }
        
        if (tok) {
            return tok;
        } else {
            if ([symbol length] > 1) {
                symbol = [symbol substringToIndex:[symbol length] - 1];
            } else {
                break;
            }
            [r unread:1];
        }
    }

    return [[self nextTokenizerStateFor:cin tokenizer:t] nextTokenFromReader:r startingWith:cin tokenizer:t];
}

@end
