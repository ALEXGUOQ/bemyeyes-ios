//
//  BMERightToLeft.h
//  BeMyEyes
//
//  Created by Simon Støvring on 09/03/14.
//  Copyright (c) 2014 Be My Eyes. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BMERightToLeftSegue : UIStoryboardSegue

@property (assign, nonatomic, getter = isUnwinding) BOOL unwinding;

@end
