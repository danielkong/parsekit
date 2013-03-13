//
//  PKNodeVisitor.h
//  ParseKit
//
//  Created by Todd Ditchendorf on 10/4/12.
//
//

#import <ParseKit/ParseKit.h>
#import "TDParserFactory.h" // remove
//@class PKParser;
//@class PKCollectionParser;

@class PKBaseNode;
@class PKVariableNode;
@class PKConstantNode;
@class PKDelimitedNode;
@class PKPatternNode;
@class PKCompositeNode;
@class PKCollectionNode;
@class PKCardinalNode;
@class PKOptionalNode;
@class PKMultipleNode;
//@class PKNodeRepetition;
//@class PKNodeDifference;
//@class PKNodeNegation;

@interface PKNodeVisitor : NSObject

- (void)visitVariable:(PKVariableNode *)node;
- (void)visitConstant:(PKConstantNode *)node;
- (void)visitDelimited:(PKDelimitedNode *)node;
- (void)visitPattern:(PKPatternNode *)node;
- (void)visitComposite:(PKCompositeNode *)node;
- (void)visitCollection:(PKCollectionNode *)node;
- (void)visitCardinal:(PKCardinalNode *)node;
- (void)visitOptional:(PKOptionalNode *)node;
- (void)visitMultiple:(PKMultipleNode *)node;
//- (void)visitRepetition:(PKNodeRepetition *)node;
//- (void)visitDifference:(PKNodeDifference *)node;
//- (void)visitNegation:(PKNodeNegation *)node;

@property (nonatomic, retain) PKParser *rootParser;
@property (nonatomic, retain) PKCompositeParser *currentParser;

@property (nonatomic, retain) id assembler;
@property (nonatomic, retain) id preassembler;
@property (nonatomic, assign) TDParserFactoryAssemblerSettingBehavior assemblerSettingBehavior;
@end
