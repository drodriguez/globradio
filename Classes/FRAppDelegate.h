//
//  FRAppDelegate.h
//  radio3
//
//  Created by Javier Quevedo on 1/11/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FRViewController;

@interface FRAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    FRViewController *viewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet FRViewController *viewController;

@end
