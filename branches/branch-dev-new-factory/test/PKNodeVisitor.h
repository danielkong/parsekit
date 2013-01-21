//
//  PKNodeVisitor.h
//  ParseKit
//
//  Created by Todd Ditchendorf on 10/7/12.
//
//

#import <Foundation/Foundation.h>

@class PKNodeBase;
@class PKNodeDefinition;
@class PKNodeReference;
@class PKNodeConstant;
@class PKNodeLiteral;
@class PKNodeDelimited;
@class PKNodePattern;
@class PKNodeWhitespace;
@class PKNodeComposite;
@class PKNodeCollection;
@class PKNodeCardinal;
@class PKNodeOptional;
@class PKNodeMultiple;
//@class PKNodeRepetition;
//@class PKNodeDifference;
//@class PKNodeNegation;

@protocol PKNodeVisitor <NSObject>
- (void)visitDefinition:(PKNodeDefinition *)node;
- (void)visitReference:(PKNodeReference *)node;
- (void)visitConstant:(PKNodeConstant *)node;
- (void)visitLiteral:(PKNodeLiteral *)node;
- (void)visitDelimited:(PKNodeDelimited *)node;
- (void)visitPattern:(PKNodePattern *)node;
- (void)visitWhitespace:(PKNodeWhitespace *)node;
- (void)visitComposite:(PKNodeComposite *)node;
- (void)visitCollection:(PKNodeCollection *)node;
- (void)visitCardinal:(PKNodeCardinal *)node;
- (void)visitOptional:(PKNodeOptional *)node;
- (void)visitMultiple:(PKNodeMultiple *)node;
//- (void)visitRepetition:(PKNodeRepetition *)node;
//- (void)visitDifference:(PKNodeDifference *)node;
//- (void)visitNegation:(PKNodeNegation *)node;

@property (nonatomic, retain) PKNodeBase *rootNode;
@end
