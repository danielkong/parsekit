//
//  PKNodeVisitor.h
//  ParseKit
//
//  Created by Todd Ditchendorf on 10/4/12.
//
//

#import <ParseKit/ParseKit.h>
#import "PKParserFactory.h" // remove
//@class PKParser;
//@class PKCollectionParser;

@class PKNodeBase;
@class PKNodeVariable;
@class PKNodeConstant;
@class PKNodeLiteral;
@class PKNodeDelimited;
@class PKNodePattern;
@class PKNodeComposite;
@class PKNodeCollection;
@class PKNodeCardinal;
@class PKNodeOptional;
@class PKNodeMultiple;
//@class PKNodeRepetition;
//@class PKNodeDifference;
//@class PKNodeNegation;

@interface PKNodeVisitor : NSObject

- (void)visitVariable:(PKNodeVariable *)node;
- (void)visitConstant:(PKNodeConstant *)node;
- (void)visitLiteral:(PKNodeLiteral *)node;
- (void)visitDelimited:(PKNodeDelimited *)node;
- (void)visitPattern:(PKNodePattern *)node;
- (void)visitComposite:(PKNodeComposite *)node;
- (void)visitCollection:(PKNodeCollection *)node;
- (void)visitCardinal:(PKNodeCardinal *)node;
- (void)visitOptional:(PKNodeOptional *)node;
- (void)visitMultiple:(PKNodeMultiple *)node;
//- (void)visitRepetition:(PKNodeRepetition *)node;
//- (void)visitDifference:(PKNodeDifference *)node;
//- (void)visitNegation:(PKNodeNegation *)node;

@property (nonatomic, retain) PKParser *rootParser;
@property (nonatomic, retain) PKCompositeParser *currentParser;

@property (nonatomic, retain) id assembler;
@property (nonatomic, retain) id preassembler;
@property (nonatomic, assign) PKParserFactoryAssemblerSettingBehavior assemblerSettingBehavior;
@end
