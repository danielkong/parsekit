//
//  TDParserFactory.h
//  ParseKit
//
//  Created by Todd Ditchendorf on 10/3/12.
//
//

#import <Foundation/Foundation.h>

@class PKParser;
@class PKParseTree;

@interface TDParserFactory : NSObject

+ (TDParserFactory *)factory;

- (PKParser *)parserFromGrammar:(NSString *)g assembler:(id)a error:(NSError **)outError;
- (PKParser *)parserFromGrammar:(NSString *)g assembler:(id)a preassembler:(id)pa error:(NSError **)outError;

- (PKParseTree *)syntaxTreeFromGrammar:(NSString *)g error:(NSError **)outError;
@end
