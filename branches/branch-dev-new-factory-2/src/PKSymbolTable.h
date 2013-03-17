//
//  PKSymbolTable.h
//  ParseKit
//
//  Created by Todd Ditchendorf on 3/16/13.
//
//

#import "PKScope.h"

@interface PKSymbolTable : NSObject <PKScope>

//- (void)define:(PKBaseSymbol *)sym;
//- (PKBaseSymbol *)resolve:(NSString *)name;
//
//@property (nonatomic, copy, readonly) NSString *scopeName;
//@property (nonatomic, copy, readonly) id <PKScope>enclosingScope;
@end
