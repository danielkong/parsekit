//
//  TDParserFactory.h
//  ParseKit
//
//  Created by Todd Ditchendorf on 10/3/12.
//
//

#import <Foundation/Foundation.h>

@class PKParser;

@interface TDParserFactory : NSObject

+ (PKParserFactory *)factory;

- (PKParser *)parserFromGrammar:(NSString *)g assembler:(id)a error:(NSError **)outError;
- (PKParser *)parserFromGrammar:(NSString *)g assembler:(id)a preassembler:(id)pa error:(NSError **)outError;
@end
