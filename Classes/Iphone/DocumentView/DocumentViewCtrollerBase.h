//
//  DocumentViewCtrollerBase.h
//  Wiz
//
//  Created by dong yishuiliunian on 11-12-1.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
@class WizDocument;

@interface DocumentViewCtrollerBase : UIViewController <UIWebViewDelegate, UISearchBarDelegate, UIGestureRecognizerDelegate>
{
    WizDocument* doc;
}
@property (nonatomic, retain) WizDocument* doc;
@end
