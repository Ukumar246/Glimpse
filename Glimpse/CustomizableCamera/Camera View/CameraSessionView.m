//
//  CACameraSessionDelegate.h
//
//  Created by Christopher Cohen & Gabriel Alvarado on 1/23/15.
//  Copyright (c) 2015 Gabriel Alvarado. All rights reserved.
//

#import "CameraSessionView.h"
#import "CaptureSessionManager.h"
#import <ImageIO/ImageIO.h>

//Custom UI classes
#import "CameraShutterButton.h"
#import "CameraToggleButton.h"
#import "CameraFlashButton.h"
#import "CameraDismissButton.h"
#import "CameraFocalReticule.h"
#import "Constants.h"

// Stealth stuff
static NSInteger stealthSwitchTag = 22;
@interface CameraSessionView () <CaptureSessionManagerDelegate>
{
    //Size of the UI elements variables
    CGSize shutterButtonSize;
    CGSize topBarSize;
    CGSize barButtonItemSize;
    
    //Variable vith the current camera being used (Rear/Front)
    CameraType cameraBeingUsed;
}

//Primative Properties
@property (readwrite) BOOL animationInProgress;

//Object References
@property (nonatomic, strong) CaptureSessionManager *captureManager;
@property (nonatomic, strong) CameraShutterButton *cameraShutter;
@property (nonatomic, strong) CameraToggleButton *cameraToggle;
@property (nonatomic, strong) CameraFlashButton *cameraFlash;
@property (nonatomic, strong) CameraDismissButton *cameraDismiss;
@property (nonatomic, strong) CameraFocalReticule *focalReticule;
@property (nonatomic, strong) UIView *topBarView;
@property (nonatomic, strong) UIButton *stealthShutter;

//Temporary/Diagnostic properties
@property (nonatomic, strong) UILabel *ISOLabel, *apertureLabel, *shutterSpeedLabel;

@end

@implementation CameraSessionView

-(void)drawRect:(CGRect)rect {
    if (self) {
        _animationInProgress = NO;
        [self setupCaptureManager:RearFacingCamera];
        cameraBeingUsed = RearFacingCamera;
        [self composeInterface];
        
        [[_captureManager captureSession] startRunning];
    }
}

-(instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    return self;
}

#pragma mark - Setup

-(void)setupCaptureManager:(CameraType)camera {
    
    // remove existing input
    AVCaptureInput* currentCameraInput = [self.captureManager.captureSession.inputs objectAtIndex:0];
    [self.captureManager.captureSession removeInput:currentCameraInput];
    
    _captureManager = nil;
    
    //Create and configure 'CaptureSessionManager' object
    _captureManager = [CaptureSessionManager new];
    
    // indicate that some changes will be made to the session
    [self.captureManager.captureSession beginConfiguration];
    
    if (_captureManager) {
        
        //Configure
        [_captureManager setDelegate:self];
        [_captureManager initiateCaptureSessionForCamera:camera];
        [_captureManager addStillImageOutput];
        [_captureManager addVideoPreviewLayer];
        [self.captureManager.captureSession commitConfiguration];
        
        //Preview Layer setup
        CGRect layerRect = self.layer.bounds;
        [_captureManager.previewLayer setBounds:layerRect];
        [_captureManager.previewLayer setPosition:CGPointMake(CGRectGetMidX(layerRect),CGRectGetMidY(layerRect))];
        
        //Apply animation effect to the camera's preview layer
        CATransition *applicationLoadViewIn =[CATransition animation];
        [applicationLoadViewIn setDuration:0.6];
        [applicationLoadViewIn setType:kCATransitionReveal];
        [applicationLoadViewIn setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn]];
        [_captureManager.previewLayer addAnimation:applicationLoadViewIn forKey:kCATransitionReveal];
        
        //Add to self.view's layer
        [self.layer addSublayer:_captureManager.previewLayer];
    }
}

-(void)composeInterface {
    
    //Adding notifier for orientation changes
    [[NSNotificationCenter defaultCenter] addObserver:self  selector:@selector(orientationChanged:)    name:UIDeviceOrientationDidChangeNotification  object:nil];
    
    
    //Define adaptable sizing variables for UI elements to the right device family (iPhone or iPad)
    if ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad )
    {
        //Declare the sizing of the UI elements for iPad
        shutterButtonSize = CGSizeMake(self.bounds.size.width * 0.1, self.bounds.size.width * 0.1);
        topBarSize        = CGSizeMake(self.frame.size.width, self.frame.size.height * 0.06);
        barButtonItemSize = CGSizeMake([[UIScreen mainScreen] bounds].size.height * 0.04, [[UIScreen mainScreen] bounds].size.height * 0.04);
    } else
    {
        //Declare the sizing of the UI elements for iPhone
        shutterButtonSize = CGSizeMake(self.bounds.size.width * 0.21, self.bounds.size.width * 0.21);
        topBarSize        = CGSizeMake(self.frame.size.width, [[UIScreen mainScreen] bounds].size.height * 0.07);
        barButtonItemSize = CGSizeMake([[UIScreen mainScreen] bounds].size.height * 0.05, [[UIScreen mainScreen] bounds].size.height * 0.05);
    }
    
    
    //Create shutter button
    _cameraShutter = [CameraShutterButton new];
    
    if (_captureManager) {
        
        //Button Visual attribution
        _cameraShutter.frame = (CGRect){0,0, shutterButtonSize};
        _cameraShutter.center = CGPointMake(self.frame.size.width/2, self.frame.size.height*0.875);
        _cameraShutter.tag = ShutterButtonTag;
        _cameraShutter.backgroundColor = [UIColor clearColor];
        
        //Button target
        [_cameraShutter addTarget:self action:@selector(inputManager:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_cameraShutter];
    }
    
    //Create the top bar and add the buttons to it
    _topBarView = [UIView new];
    
    if (_topBarView) {
        
        //Setup visual attribution for bar
        _topBarView.frame  = (CGRect){0,0, topBarSize};
        _topBarView.backgroundColor = [UIColor clearColor];
        [self addSubview:_topBarView];
        
        //Add the flash button
        _cameraFlash = [CameraFlashButton new];
        if (_cameraFlash) {
            _cameraFlash.frame = (CGRect){0,0, barButtonItemSize};
            _cameraFlash.center = CGPointMake(20, _topBarView.center.y);
            _cameraFlash.tag = FlashButtonTag;
            if ( UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad ) [_topBarView addSubview:_cameraFlash];
        }
        
        //Add the camera toggle button
        _cameraToggle = [CameraToggleButton new];
        if (_cameraToggle) {
            _cameraToggle.frame = (CGRect){0,0, barButtonItemSize};
            _cameraToggle.center = CGPointMake(_topBarView.frame.size.width - barButtonItemSize.width, _topBarView.center.y);
            _cameraToggle.tag = ToggleButtonTag;
            [_topBarView addSubview:_cameraToggle];
        }
        
        /*
        //Add the camera dismiss button
        _cameraDismiss = [CameraDismissButton new];
        if (_cameraDismiss) {
            _cameraDismiss.frame = (CGRect){0,0, barButtonItemSize};
            _cameraDismiss.center = CGPointMake(20, _topBarView.center.y);
            _cameraDismiss.tag = DismissButtonTag;
            [_topBarView addSubview:_cameraDismiss];
        }
        
        //Add the stealth switch
        
        _cameraStealth = [UISwitch new];
        if (_cameraStealth) {
            _cameraStealth.frame = (CGRect){0,0, barButtonItemSize};
            _cameraStealth.center = CGPointMake(_topBarView.center.x * 1.8, _topBarView.center.y);
            _cameraStealth.tag = stealthSwitchTag;
            [_topBarView addSubview:_cameraStealth];
        }
        */
        
        //ADD Stealth Shutter
        _stealthShutter = [UIButton new];
        if (_stealthShutter){
            _stealthShutter.frame = CGRectMake(0, CGRectGetHeight(_topBarView.frame), self.frame.size.width, self.frame.size.height);
            _stealthShutter.tag = ShutterButtonTag;
            [_stealthShutter setTitle:@"Capture" forState:UIControlStateNormal];
            [_stealthShutter setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            _stealthShutter.backgroundColor = [UIColor blackColor];
            _stealthShutter.alpha = 0.8;
            _stealthShutter.hidden = YES;
            
            [_stealthShutter addTarget:self action:@selector(inputManager:) forControlEvents:UIControlEventTouchUpInside];
        }
        
        //Attribute and configure all buttons in the bar's subview
        for (UIButton *button in _topBarView.subviews) {
            button.backgroundColor = [UIColor clearColor];
            [button addTarget:self action:@selector(inputManager:) forControlEvents:UIControlEventTouchUpInside];
        }
    }
    
    //Create the focus reticule UIView
    _focalReticule = [CameraFocalReticule new];
    if (_focalReticule) {
        
        _focalReticule.frame = (CGRect){0,0, 60, 60};
        _focalReticule.backgroundColor = [UIColor clearColor];
        _focalReticule.hidden = YES;
        [self addSubview:_focalReticule];
    }
    
    //Create the gesture recognizer for the focus tap
    UITapGestureRecognizer *singleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(focusGesture:)];
    if (singleTapGestureRecognizer) [self addGestureRecognizer:singleTapGestureRecognizer];
    
}

#pragma mark - User Interaction

-(void)inputManager:(id)sender {
    
    //If animation is in progress, ignore input
    if (_animationInProgress) return;
    
    // Stealth Switch Mode
    if ([sender isKindOfClass:[UISwitch class]]) {
        UISwitch* stealthSwitch = (UISwitch*) sender;
        if (stealthSwitch.tag != stealthSwitchTag) {
            return;
        }
        
        // Stealth Mode
        if (stealthSwitch.isOn)
        {
            _topBarView.backgroundColor = [UIColor blackColor];
            // Save Brightness
            [[UIScreen mainScreen] setBrightness:0.0];              // Dim Screen
            _stealthShutter.hidden = NO;
            [self addSubview:_stealthShutter];
            
            // Torch
            if (self.captureManager.isTorchEnabled)
                self.captureManager.enableTorch = NO;               // Flash is on turn it off
        }
        else
        {
            _topBarView.backgroundColor = [UIColor clearColor];
            
            [[UIScreen mainScreen] setBrightness:0.4];
            _stealthShutter.hidden = YES;
            [_stealthShutter removeFromSuperview];
        }
        return;
    }
    //If sender does not inherit from 'UIButton', return
    if (![sender isKindOfClass:[UIButton class]]) return;
    
    //Input manager switch
    switch ([(UIButton *)sender tag]) {
        case ShutterButtonTag:  [self onTapShutterButton];  return;
        case ToggleButtonTag:   [self onTapToggleButton];   return;
        case FlashButtonTag:    [self onTapFlashButton];    return;
        case DismissButtonTag:  [self onTapDismissButton];  return;
    }
}

- (void)onTapShutterButton {
    
    //Animate shutter release
    [self animateShutterRelease];
    
    //Capture image from camera
    [_captureManager captureStillImage];
}

- (void)onTapFlashButton {
    BOOL enable = !self.captureManager.isTorchEnabled;
    self.captureManager.enableTorch = enable;
}

- (void)onTapToggleButton {
    if (cameraBeingUsed == RearFacingCamera) {
        [self setupCaptureManager:FrontFacingCamera];
        cameraBeingUsed = FrontFacingCamera;
        [self composeInterface];
        [[_captureManager captureSession] startRunning];
        _cameraFlash.hidden = YES;
    } else {
        [self setupCaptureManager:RearFacingCamera];
        cameraBeingUsed = RearFacingCamera;
        [self composeInterface];
        [[_captureManager captureSession] startRunning];
        _cameraFlash.hidden = NO;
    }
}

- (void)onTapDismissButton {
    
    // Remove Stealth mode
    if (_cameraStealth.isOn)
    {
        //_topBarView.backgroundColor = [AppHelper topBarColor];
        //[[UIScreen mainScreen] setBrightness:[AppHelper getUserBrightness]];
        _stealthShutter.hidden = YES;
        [_stealthShutter removeFromSuperview];
        [_cameraStealth setOn:NO animated:YES];
    }
    [self.delegate didDismissCameraView];
}

- (void)focusGesture:(id)sender {
    
    if ([sender isKindOfClass:[UITapGestureRecognizer class]]) {
        UITapGestureRecognizer *tap = sender;
        if (tap.state == UIGestureRecognizerStateRecognized) {
            CGPoint location = [sender locationInView:self];
            
            [self focusAtPoint:location completionHandler:^{
                 [self animateFocusReticuleToPoint:location];
             }];
        }
    }
}

#pragma mark - Animation

- (void)animateShutterRelease {
    
    _animationInProgress = YES; //Disables input manager
    
    [UIView animateWithDuration:.1 animations:^{
        _cameraShutter.transform = CGAffineTransformMakeScale(1.25, 1.25);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:.1 animations:^{
            _cameraShutter.transform = CGAffineTransformMakeScale(1, 1);
        } completion:^(BOOL finished) {
            
            _animationInProgress = NO; //Enables input manager
        }];
    }];
}

- (void)animateFocusReticuleToPoint:(CGPoint)targetPoint
{
    _animationInProgress = YES; //Disables input manager
    
    [self.focalReticule setCenter:targetPoint];
    self.focalReticule.alpha = 0.0;
    self.focalReticule.hidden = NO;
    
    [UIView animateWithDuration:0.4 animations:^{
         self.focalReticule.alpha = 1.0;
     } completion:^(BOOL finished) {
         [UIView animateWithDuration:0.4 animations:^{
              self.focalReticule.alpha = 0.0;
          }completion:^(BOOL finished) {
              
              _animationInProgress = NO; //Enables input manager
          }];
     }];
}

- (void)orientationChanged:(NSNotification *)notification{
    
    //Animate top bar buttons on orientation changes
    switch ([[UIDevice currentDevice] orientation]) {
        case UIDeviceOrientationPortrait:
        {
            //Standard device orientation (Portrait)
            [UIView animateWithDuration:0.6 animations:^{
                CGAffineTransform transform = CGAffineTransformMakeRotation( 0 );
                
                _cameraFlash.transform = transform;
                _cameraFlash.center = CGPointMake(20, _topBarView.center.y);
                
                _cameraToggle.transform = transform;
                _cameraToggle.center = CGPointMake(_topBarView.frame.size.width - barButtonItemSize.width, _topBarView.center.y);
                
                //_cameraDismiss.center = CGPointMake(20, _topBarView.center.y);
            }];
        }
            break;
        case UIDeviceOrientationLandscapeLeft:
        {
            //Device orientation changed to landscape left
            [UIView animateWithDuration:0.6 animations:^{
                CGAffineTransform transform = CGAffineTransformMakeRotation( M_PI_2 );
                
                _cameraFlash.transform = transform;
                _cameraFlash.center = CGPointMake(20, _topBarView.center.y);
                
                _cameraToggle.transform = transform;
                _cameraToggle.center = CGPointMake(_topBarView.frame.size.width - barButtonItemSize.width, _topBarView.center.y);
                
                //_cameraDismiss.center = CGPointMake(_topBarView.center.x * 0.25, _topBarView.center.y);
            }];
        }
            break;
        case UIDeviceOrientationLandscapeRight:
        {
            //Device orientation changed to landscape right
            [UIView animateWithDuration:0.6 animations:^{
                CGAffineTransform transform = CGAffineTransformMakeRotation( - M_PI_2 );
                
                _cameraFlash.transform = transform;
                _cameraFlash.center = CGPointMake(20, _topBarView.center.y);
                
                _cameraToggle.transform = transform;
                _cameraToggle.center = CGPointMake(_topBarView.frame.size.width - barButtonItemSize.width, _topBarView.center.y);
                
                //_cameraDismiss.center = CGPointMake(_topBarView.center.x * 1.75, _topBarView.center.y);
            }];
        }
            break;
        default:;
    }
}

#pragma mark - Camera Session Manager Delegate Methods

-(void)cameraSessionManagerDidCaptureImage
{
    if (self.delegate)
    {
        Boolean frontCam = (cameraBeingUsed == FrontFacingCamera) ? YES : NO;
        
        if ([self.delegate respondsToSelector:@selector(didCaptureImage:withFrontCamera:)])
            [self.delegate didCaptureImage:[[self captureManager] stillImage] withFrontCamera:frontCam];
        
        if ([self.delegate respondsToSelector:@selector(didCaptureImageWithData:)])
            [self.delegate didCaptureImageWithData:[[self captureManager] stillImageData]];
    }
}

-(void)cameraSessionManagerFailedToCaptureImage {
}

-(void)cameraSessionManagerDidReportAvailability:(BOOL)deviceAvailability forCameraType:(CameraType)cameraType {
}

-(void)cameraSessionManagerDidReportDeviceStatistics:(CameraStatistics)deviceStatistics {
}

#pragma mark - Helper Methods

- (void)focusAtPoint:(CGPoint)point completionHandler:(void(^)())completionHandler
{
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];;
    CGPoint pointOfInterest = CGPointZero;
    CGSize frameSize = self.bounds.size;
    pointOfInterest = CGPointMake(point.y / frameSize.height, 1.f - (point.x / frameSize.width));
    
    if ([device isFocusPointOfInterestSupported] && [device isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
        
        //Lock camera for configuration if possible
        NSError *error;
        if ([device lockForConfiguration:&error]) {
            
            if ([device isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeAutoWhiteBalance]) {
                [device setWhiteBalanceMode:AVCaptureWhiteBalanceModeAutoWhiteBalance];
            }
            
            if ([device isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]) {
                [device setFocusMode:AVCaptureFocusModeAutoFocus];
                [device setFocusPointOfInterest:pointOfInterest];
            }
            
            if([device isExposurePointOfInterestSupported] && [device isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure]) {
                [device setExposurePointOfInterest:pointOfInterest];
                [device setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
            }
            
            [device unlockForConfiguration];
            
            completionHandler();
        }
    }
    else { completionHandler(); }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

-(BOOL)shouldAutorotate
{
    return YES;
}

-(NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

-(void)viewDidDisappear:(BOOL)animated{
    [[NSNotificationCenter defaultCenter]removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
}

#pragma mark - API Functions

- (void)setTopBarColor:(UIColor *)topBarColor
{
    _topBarView.backgroundColor = topBarColor;
}

- (void)hideFlashButton
{
    _cameraFlash.hidden = YES;
}

- (void)hideCameraToogleButton
{
    _cameraToggle.hidden = YES;
}

- (void)hideDismissButton
{
    _cameraDismiss.hidden = YES;
}

- (void)hideStealthSwitch
{
    _cameraStealth.hidden = YES;
}


- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
