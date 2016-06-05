//
//  CACameraSessionDelegate.h
//
//  Created by Christopher Cohen & Gabriel Alvarado on 1/23/15.
//  Copyright (c) 2015 Gabriel Alvarado. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Constants.h"

///Protocol Definition
@protocol CACameraSessionDelegate <NSObject>

-(void)didCaptureImage:(UIImage *)image withFrontCamera:(Boolean) frontCamera;
@optional - (void)didCaptureImageWithData:(NSData *)imageData;
@optional - (void)didDismissCameraView;

@end

@interface CameraSessionView : UIView

//Delegate Property
@property (nonatomic, weak) id <CACameraSessionDelegate> delegate;
// stealth addon
@property (nonatomic, strong) UISwitch *cameraStealth;

//API Functions
- (void)setTopBarColor:(UIColor *)topBarColor;
- (void)hideFlashButton;
- (void)hideCameraToogleButton;
- (void)hideDismissButton;
- (void)hideStealthSwitch;

@end
