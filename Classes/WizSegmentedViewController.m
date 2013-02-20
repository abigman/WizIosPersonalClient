//
//  WizSegmentedViewController.m
//  Wiz
//
//  Created by wiz on 12-8-13.
//
//
#import "WizSegmentTableViewControllerBase.h"
#import "WizSegmentedViewController.h"
#import "WizPadAllNotesViewController.h"
#define WizSegmentViewChangedDurationTime  0.5
#define WizSegmentItemWidth                 80

@interface WizSegmentedViewController ()
{
    UISegmentedControl*  segementdControl;
    NSArray* viewControllers;
    UIViewController*  selectedViewController;
}
@property (nonatomic, assign)  UIViewController*  selectedViewController;;
@end

@implementation WizSegmentedViewController
@synthesize selectedViewController;
- (void) dealloc
{
    [viewControllers release];
    [segementdControl release];
    self.selectedViewController = nil;
    [super dealloc];
}


- (void) selectedViewControllerAtIndex:(NSInteger)index
{
    UIViewController* toViewController = [viewControllers objectAtIndex:index];
    
    if ([self.selectedViewController isEqual:toViewController]) {
        return;
    }
    if (self.selectedViewController != nil) {
        [selectedViewController viewWillDisappear:YES];
        [selectedViewController.view removeFromSuperview];
        [selectedViewController viewDidDisappear:YES];
    }
    self.selectedViewController = toViewController;
    [toViewController viewWillAppear:YES];
    //
    
    UIInterfaceOrientation fromInterfaceOrientation = toViewController.interfaceOrientation;
    UIInterfaceOrientation toInterfaceOrientation = [[UIDevice currentDevice] orientation];
    
    if (fromInterfaceOrientation != toInterfaceOrientation )
    {
        if (![self shouldAutorotateToInterfaceOrientation:toInterfaceOrientation]) {
            if ([toViewController shouldAutorotateToInterfaceOrientation:UIInterfaceOrientationPortrait])
            {
                toInterfaceOrientation = UIInterfaceOrientationPortrait;
            }
            else if ([toViewController shouldAutorotateToInterfaceOrientation:UIInterfaceOrientationPortraitUpsideDown])
            {
                toInterfaceOrientation = UIInterfaceOrientationPortraitUpsideDown;
            }
            else if ([toViewController shouldAutorotateToInterfaceOrientation:UIInterfaceOrientationLandscapeLeft])
            {
                toInterfaceOrientation = UIInterfaceOrientationLandscapeLeft;
            }
            else if ([toViewController shouldAutorotateToInterfaceOrientation:UIInterfaceOrientationLandscapeRight])
            {
                toInterfaceOrientation = UIInterfaceOrientationLandscapeRight;
            }
        }
        [[UIDevice currentDevice] performSelector:@selector(setOrientation:) withObject:(id)toInterfaceOrientation];
    }
    
    toViewController.view.frame = CGRectMake(0.0, 0.0, self.view.frame.size.width, self.view.frame.size.height);
    [self.view addSubview:toViewController.view];
    [toViewController viewDidAppear:YES];
}



- (void) changedItem:(id)sender
{
    UISegmentedControl* segementControl_ = (UISegmentedControl*)sender;
    NSInteger  selectedItemIndex = segementControl_.selectedSegmentIndex;
    [self selectedViewControllerAtIndex:selectedItemIndex];
}

- (id) initWithViewControllers:(NSArray*)viewControllers_  titles:(NSArray*)titles
{
    self = [super init];
    if (self) {
        if ([viewControllers_ count] != [titles count])
        {
            return nil;
        }
        viewControllers = [viewControllers_ retain];
        
        for (UIViewController* each in viewControllers) {
            if ([each isKindOfClass:[WizSegmentTableViewControllerBase class]]) {
                WizSegmentTableViewControllerBase* viewController = (WizSegmentTableViewControllerBase*)each;
                viewController.orientationDelegate = self;
                
            }
        }
        
        segementdControl = [[UISegmentedControl alloc] initWithItems:titles];
        [segementdControl addTarget:self action:@selector(changedItem:) forControlEvents:UIControlEventValueChanged];
        segementdControl.segmentedControlStyle = UISegmentedControlStyleBar;
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //
    
    float width = [segementdControl numberOfSegments] * WizSegmentItemWidth;
    
    segementdControl.frame = CGRectMake(0.0, 0.0, width, 30);
    segementdControl.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    self.navigationItem.titleView = segementdControl;
    //
    [segementdControl setSelectedSegmentIndex:0];
    [self selectedViewControllerAtIndex:0];
    self.view.backgroundColor = [UIColor scrollViewTexturedBackgroundColor];
	// Do any additional setup after loading the view.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return [self.selectedViewController shouldAutorotateToInterfaceOrientation:interfaceOrientation];
}
- (void) willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
    [self.selectedViewController willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
}

- (void) didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    if ([self.selectedViewController isKindOfClass:[WizPadAllNotesViewController class]]) {
        return;
    }
    [self.selectedViewController didRotateFromInterfaceOrientation:fromInterfaceOrientation];
}

- (void) willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    if ([self.selectedViewController isKindOfClass:[WizPadAllNotesViewController class]]) {
        return;
    }
    [self.selectedViewController willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.selectedViewController viewWillAppear:animated];
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.selectedViewController viewDidAppear:animated];
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.selectedViewController viewWillDisappear:animated];
}

- (void) viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self.selectedViewController viewDidDisappear:animated];
}

- (void) viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    [self.selectedViewController viewWillLayoutSubviews];
}

- (void) viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    [self.selectedViewController viewDidLayoutSubviews];
}

- (UIInterfaceOrientation) parentSegmentInterfaceOrientation
{
    return self.interfaceOrientation;
}
@end
