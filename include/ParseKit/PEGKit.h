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

/*!
    @mainpage   ParseKit
                ParseKit is a Mac OS X Framework written by Todd Ditchendorf in Objective-C 2.0 and released under the MIT Open Source License.
				The framework is an Objective-C implementation of the tools described in <a href="http://www.amazon.com/Building-Parsers-Java-Steven-Metsker/dp/0201719622" title="Amazon.com: Building Parsers With Java(TM): Steven John Metsker: Books">"Building Parsers with Java" by Steven John Metsker</a>. 
				ParseKit includes some significant additions beyond the designs from the book (many of them hinted at in the book itself) in order to enhance the framework's feature set, usefulness and ease-of-use. Other changes have been made to the designs in the book to match common Cocoa/Objective-C design patterns and conventions. 
				However, these changes are relatively superficial, and Metsker's book is the best documentation available for this framework.
                
                Classes in the ParseKit Framework offer 2 basic services of general use to Cocoa developers:
    @li Tokenization via a tokenizer class
    @li Parsing via a high-level parser-building toolkit
                Learn more on the <a target="_top" href="http://parsekit.com">project site</a>
*/
 
#import <Foundation/Foundation.h>

// io
#import <ParseKit/PKTypes.h>
#import <ParseKit/PKReader.h>

// tokens
#import <ParseKit/PKToken.h>
#import <ParseKit/PKTokenizer.h>
#import <ParseKit/PKTokenArraySource.h>
#import <ParseKit/PKTokenAssembly.h>
#import <ParseKit/PKTokenizerState.h>
#import <ParseKit/PKNumberState.h>
#import <ParseKit/PKQuoteState.h>
#import <ParseKit/PKDelimitState.h>
#import <ParseKit/PKURLState.h>
#import <ParseKit/PKEmailState.h>
#if PK_PLATFORM_TWITTER_STATE
#import <ParseKit/PKTwitterState.h>
#import <ParseKit/PKHashtagState.h>
#endif
#import <ParseKit/PKCommentState.h>
#import <ParseKit/PKSingleLineCommentState.h>
#import <ParseKit/PKMultiLineCommentState.h>
#import <ParseKit/PKSymbolNode.h>
#import <ParseKit/PKSymbolRootNode.h>
#import <ParseKit/PKSymbolState.h>
#import <ParseKit/PKWordState.h>
#import <ParseKit/PKWhitespaceState.h>

// static
#import <ParseKit/PEGParser.h>
#import <ParseKit/PEGTokenAssembly.h>
#import <ParseKit/PEGRecognitionException.h>

