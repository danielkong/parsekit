//
//  PKNodeVisitor.h
//  ParseKit
//
//  Created by Todd Ditchendorf on 10/7/12.
//
//

#import <Foundation/Foundation.h>

@class PKBaseNode;
@class PKDefinitionNode;
@class PKReferenceNode;
@class PKConstantNode;
@class PKLiteralNode;
@class PKDelimitedNode;
@class PKPatternNode;
@class PKWhitespaceNode;
@class PKCompositeNode;
@class PKCollectionNode;
@class PKCardinalNode;
@class PKOptionalNode;
@class PKMultipleNode;
//@class PKNodeRepetition;
//@class PKNodeDifference;
//@class PKNodeNegation;

@protocol PKNodeVisitor <NSObject>
- (void)visitDefinition:(PKDefinitionNode *)node;
- (void)visitReference:(PKReferenceNode *)node;
- (void)visitConstant:(PKConstantNode *)node;
- (void)visitLiteral:(PKLiteralNode *)node;
- (void)visitDelimited:(PKDelimitedNode *)node;
- (void)visitPattern:(PKPatternNode *)node;
- (void)visitWhitespace:(PKWhitespaceNode *)node;
- (void)visitComposite:(PKCompositeNode *)node;
- (void)visitCollection:(PKCollectionNode *)node;
- (void)visitCardinal:(PKCardinalNode *)node;
- (void)visitOptional:(PKOptionalNode *)node;
- (void)visitMultiple:(PKMultipleNode *)node;
//- (void)visitRepetition:(PKNodeRepetition *)node;
//- (void)visitDifference:(PKNodeDifference *)node;
//- (void)visitNegation:(PKNodeNegation *)node;

@property (nonatomic, retain) PKBaseNode *rootNode;
@end