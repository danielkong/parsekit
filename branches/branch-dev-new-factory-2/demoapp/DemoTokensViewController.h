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

#import <Cocoa/Cocoa.h>

@class PKTokenizer;

@interface DemoTokensViewController : NSViewController {
    IBOutlet NSTokenField *tokenField;

    PKTokenizer *tokenizer;
    NSString *inString;
    NSString *outString;
    NSString *tokString;
    NSMutableArray *toks;
    BOOL busy;
}

- (IBAction)parse:(id)sender;

@property (retain) PKTokenizer *tokenizer;
@property (retain) NSString *inString;
@property (retain) NSString *outString;
@property (retain) NSString *tokString;
@property (retain) NSMutableArray *toks;
@property BOOL busy;
@end
