//
//  WizNotification.h
//  Wiz
//
//  Created by wiz on 12-3-15.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WizNotificationMessageType.h"
@interface WizNotificationCenter : NSObject
+(void) addObserverWithKey:(id)observer selector:(SEL)selector  name:(NSString*)name;
+ (void) removeObserverWithKey:(id) observer name:(NSString*)name;
+ (void) postNewDocumentMessage:(NSString*)documentGUID;
+ (NSString*) getNewDocumentGUIDFromMessage:(NSNotification*)nc;
@end
