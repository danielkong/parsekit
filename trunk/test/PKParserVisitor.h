//
//  TDParserVisitor.h
//  ParseKit
//
//  Created by Todd Ditchendorf on 10/4/12.
//
//

#import <ParseKit/ParseKit.h>

//@class PKParser;
//@class PKCollectionParser;

@class PKNodeParser;
@class PKNodeVariable;
@class PKNodeConstant;
@class PKNodePattern;
@class PKNodeComposite;
@class PKNodeCollection;
//@class PKNodeRepetition;
//@class PKNodeDifference;
//@class PKNodeNegation;

@interface PKParserVisitor : NSObject

- (void)visitVariable:(PKNodeVariable *)node;
- (void)visitConstant:(PKNodeConstant *)node;
- (void)visitPattern:(PKNodePattern *)node;
- (void)visitComposite:(PKNodeComposite *)node;
- (void)visitCollection:(PKNodeCollection *)node;
//- (void)visitRepetition:(PKNodeRepetition *)node;
//- (void)visitDifference:(PKNodeDifference *)node;
//- (void)visitNegation:(PKNodeNegation *)node;

@property (nonatomic, retain) PKParser *rootParser;
@property (nonatomic, retain) PKCompositeParser *currentParser;
@end
