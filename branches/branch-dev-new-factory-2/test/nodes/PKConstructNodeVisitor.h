//
//  PKNodeVisitor.h
//  ParseKit
//
//  Created by Todd Ditchendorf on 10/4/12.
//
//

#import <ParseKit/ParseKit.h>
#import "PKNodeVisitor.h"
#import "PKParserFactory.h" // remove

@interface PKConstructNodeVisitor : NSObject <PKNodeVisitor>

@property (nonatomic, retain) PKBaseNode *rootNode;
@property (nonatomic, retain) NSMutableDictionary *parserTable;
@property (nonatomic, retain) NSMutableDictionary *productionTable;

@property (nonatomic, retain) NSDictionary *parserClassForTokenTable;

@property (nonatomic, retain) PKParser *rootParser;
@property (nonatomic, retain) PKCompositeParser *currentParser;

@property (nonatomic, retain) id assembler;
@property (nonatomic, retain) id preassembler;
@property (nonatomic, assign) PKParserFactoryAssemblerSettingBehavior assemblerSettingBehavior;
@end
