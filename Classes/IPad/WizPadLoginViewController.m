//
//  WizPagLoginViewController.m
//  Wiz
//
//  Created by dong yishuiliunian on 11-12-27.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//

#import "WizPadLoginViewController.h"
#import "WizAddAcountViewController.h"
#import "WizPadRegisterController.h"
#import "WizGlobals.h"
#import "WizGlobalData.h"

#import "WizPadNotificationMessage.h"
#import "WizNotification.h"
#import "WizAccountManager.h"
#import "WizDbManager.h"

//
#import "WizPadViewController.h"



@implementation WizPadLoginViewController
@synthesize loginButton;
@synthesize backgroudView;
@synthesize registerButton;
@synthesize CripytLabel;
- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [WizNotificationCenter removeObserver:self];
    [CripytLabel release];
    [loginButton release];
    [backgroudView release];
    [registerButton release];
    [super dealloc];
}
- (void) setFrames:(UIInterfaceOrientation)interface
{
    if (UIInterfaceOrientationIsLandscape(interface)) {
        self.backgroudView.frame = CGRectMake(0.0, 0.0, 1024, 768);
        self.backgroudView.image = [UIImage imageNamed:@"Default-Landscape~ipad"];
        self.loginButton.frame = CGRectMake(292, 660, 220, 40);
        self.registerButton.frame = CGRectMake(522, 660, 220, 40);
        self.CripytLabel.frame = CGRectMake(412, 724, 200, 21);
    }
    else
    {
        self.backgroudView.frame = CGRectMake(0.0, 0.0, 768, 1024);
        self.backgroudView.image = [UIImage imageNamed:@"Default-Portrait~ipad"];
        self.loginButton.frame = CGRectMake(160, 875, 220, 40);
        self.registerButton.frame = CGRectMake(390, 875, 220, 40);
        self.CripytLabel.frame = CGRectMake(284, 972, 200, 21);
    }
}



- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        firstLoad = YES;
        [WizNotificationCenter addObserverForPadSelectedAccount:self selector:@selector(selectAccount:)];
    }
    return self;
}

- (id) init
{
    self = [super init];
    if (self) {
        firstLoad = YES;
    }
    return self;
}
- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void) viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}
- (void) didSelectedAccount:(NSString*)accountUserId
{
    [[WizAccountManager defaultManager] registerActiveAccount:accountUserId];
    WizPadViewController* pad = [[WizPadViewController alloc] init];
    [self.navigationController pushViewController:pad animated:YES];
    [pad release];
}

- (void) selecteDefaultAccount
{
    NSString* defaultUserId = [[[WizDbManager shareDbManager] getWizSettingsDataBase] defaultAccountUserId];
    if (defaultUserId == nil || [defaultUserId isEqualToString:@""]) {
        return;
    }
    [self didSelectedAccount:defaultUserId];
}
- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self setFrames:self.interfaceOrientation];
    [self.navigationController setNavigationBarHidden:YES animated:NO];
    [self.navigationController setToolbarHidden:YES];
        if (firstLoad) {
            [self selecteDefaultAccount];
            firstLoad = NO;
        }
        else {
            [self loginViewAppear:nil];
    }
    
}
- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}
- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle
- (void) selectAccount:(NSNotification*)nc
{
    NSString* accountUserId = [WizNotificationCenter getDidSelectedAccountUserId:nc];
    [self didSelectedAccount:accountUserId];
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.loginButton setBackgroundImage:[UIImage imageNamed:@"loginButtonBackgroud"] forState:UIControlStateNormal];
    [self.loginButton setTitle:WizStrSignIn forState:UIControlStateNormal];
    [self.registerButton setBackgroundImage:[UIImage imageNamed:@"loginButtonBackgroud"] forState:UIControlStateNormal];
    [self.registerButton setTitle:WizStrCreateAccount forState:UIControlStateNormal];

}

- (void)viewDidUnload
{
    [super viewDidUnload];

}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}
- (void) willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [self setFrames:toInterfaceOrientation];
}

- (IBAction)loginViewAppear:(id)sender
{
    WizAddAcountViewController* wizAddAccount = [[WizAddAcountViewController alloc] init];
    UINavigationController* controller = [[UINavigationController alloc] initWithRootViewController:wizAddAccount];
    controller.modalPresentationStyle = UIModalPresentationFormSheet;
    [self presentModalViewController:controller animated:YES];
    [wizAddAccount release];
    [controller release];
}
- (IBAction)registerViewApper:(id)sender
{
    WizPadRegisterController* wizAddAccount = [[WizPadRegisterController alloc] init];
    UINavigationController* controller = [[UINavigationController alloc] initWithRootViewController:wizAddAccount];
    controller.modalPresentationStyle = UIModalPresentationFormSheet;
    [self presentModalViewController:controller animated:YES];
    [wizAddAccount release];
    [controller release];
}

@end
