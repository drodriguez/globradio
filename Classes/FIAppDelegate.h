//
//  FIAppDelegate.h
//  radio3
//
//  Created by Daniel Rodríguez Troitiño on 25/12/08.
//  Copyright 2008 Daniel Rodríguez and Javier Quevedo. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FIViewController;

@interface FIAppDelegate : NSObject <UIApplicationDelegate> {
 @private
  UIWindow *window;
  FIViewController *viewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet FIViewController *viewController;

@end
