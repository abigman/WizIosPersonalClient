//
//  WizTemporaryDataBaseDelegate.h
//  Wiz
//
//  Created by 朝 董 on 12-4-27.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WizSearch.h"

@class WizAbstract;
@protocol WizTemporaryDataBaseDelegate <NSObject>
- (WizAbstract*) abstractOfDocument:(NSString *)documentGUID;
- (void) extractSummary:(NSString *)documentGUID kbGuid:(NSString*)kbguid;
- (BOOL) clearCache;
- (BOOL) deleteAbstractByGUID:(NSString *)documentGUID;
- (WizAbstract*) abstractForGroup:(NSString*)kbguid;
- (BOOL) deleteAbstractsByAccountUserId:(NSString*)accountUserID;
- (BOOL) updateWizSearch:(NSString*)keywords  notesNumber:(NSInteger)notesNumber isSerchLocal:(BOOL)isSearchLocal;
- (BOOL) deleteWizSearch:(NSString*)keywords;
- (NSArray*) allWizSearchs;
@end
