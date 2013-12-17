// Define your license here. For more information, please visit http://dev.metaio.com - you can add
// a new application at http://dev.metaio.com/get-developer-key/
#define SDK_LICENSE "0sIC0zZKT85pYgQQOLio5hAlGuix+rHUi8VoU3Z+zXE="
#if !defined (SDK_LICENSE)
#error Please provide the license string for your application
#endif

// Make sure that we're building this with an iOS SDK that at least supports iOS5
#ifndef __IPHONE_5_0
#error Please update to an iOS SDK that supports at least iOS5. iOS applications should always be built with the latest SDK
#endif

#import <CoreMotion/CoreMotion.h>
#import <AssetsLibrary/AssetsLibrary.h>

#import "CameraImageRenderer.h"
#import "Scene.h"
#import "MainViewController.h"
#import "Constants.h"

#define RESET_TRACKING_DELAY 3.0f

metaio::IMetaioSDKIOS *m_pMetaioSDK;

enum State {
    ViewingTree        = 0,
    ShowingGift        = 1,
    ShowingArrow       = 2,
    StartSeekingObject = 3,
    SeekingObject      = 4,
    Seeking2DObject    = 5,
    ViewingObject      = 6,
    BringingObjectHome = 7,
    PlacingObject      = 8,
};
    
@interface MainViewController () {
	CameraImageRenderer*		m_pCameraImageRenderer;
	Scene*						m_pScene;
    
	metaio::ISensorsComponent*	m_pSensors;
	bool						m_SDKReady;

    CMMotionManager *motionManager;
    
    State state;
    CFTimeInterval stateStartTime;
    
    NSString *trackingFilename;
    
    bool savedToCameraRoll;
    CFAbsoluteTime startShowingInfoTime;
}
@property (strong, nonatomic) EAGLContext *context;

- (void)initMetaioSDK;
- (void)setupGL;
- (void)tearDownGL;

@end

@implementation MainViewController

- (void)dealloc
{
	[self tearDownGL];
    
	if ([EAGLContext currentContext] == self.context)
		[EAGLContext setCurrentContext:nil];
	
	if (m_pMetaioSDK)
    {
        delete m_pMetaioSDK;
        m_pMetaioSDK = NULL;
    }
    
    if (m_pSensors)
    {
        delete m_pSensors;
        m_pSensors = NULL;
    }
}

- (void)viewDidLoad
{
	[super viewDidLoad];

	state = ViewingTree;
    trackingFilename = nil;
    
	self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
	if (!self.context)
		NSLog(@"Failed to create ES context");
	
	GLKView *view = (GLKView *)self.view;
	view.context = self.context;
	view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
	
	[self setupGL];

	// Listen to app pause/resume events because in those events we have to pause/resume the SDK
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onApplicationWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onApplicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    
    motionManager = [[CMMotionManager alloc] init];
    motionManager.deviceMotionUpdateInterval = 0.01f;
    [motionManager startDeviceMotionUpdatesUsingReferenceFrame:CMAttitudeReferenceFrameXArbitraryZVertical];

    savedToCameraRoll = NO;
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"trackingImageSavedToCameraRoll"] == nil) {
        savedToCameraRoll = YES;
        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
        UIImage *image = [UIImage imageNamed:@"Images/track.png"];
        [library writeImageToSavedPhotosAlbum:image.CGImage orientation:(ALAssetOrientation)image.imageOrientation completionBlock:^(NSURL *assetURL, NSError *error) {
            NSLog(@"Saved photo? %@", error != nil ? @"NO" : @"YES");
        }];
        [[NSUserDefaults standardUserDefaults] setObject:@"YES" forKey:@"trackingImageSavedToCameraRoll"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        startShowingInfoTime = CFAbsoluteTimeGetCurrent();
    }

	[self initMetaioSDK];
    [self startViewingTree];
    //[self startSeekingObject];
    
	m_pCameraImageRenderer = [[CameraImageRenderer alloc] init];
}

- (void)viewDidLayoutSubviews
{
	[super viewDidLayoutSubviews];
    
	m_pMetaioSDK->resizeRenderer(self.view.bounds.size.width, self.view.bounds.size.height);
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	if (m_pMetaioSDK) {
		// Since the metaio SDK may capture in YUV for performance reasons, we
		// enforce RGB capturing here to make it easier for us to handle the camera image
		m_pMetaioSDK->startCamera(0, 320, 240, 1, false);
	}
    
	[self willAnimateRotationToInterfaceOrientation:self.interfaceOrientation duration:0];
}

- (void)viewWillDisappear:(BOOL)animated
{
	if (m_pMetaioSDK)
        m_pMetaioSDK->stopCamera();
    
	[super viewWillDisappear:animated];
}

- (void)viewDidUnload
{
	[[NSNotificationCenter defaultCenter]
	 removeObserver:self
	 name:UIApplicationWillResignActiveNotification
	 object:nil];
	[[NSNotificationCenter defaultCenter]
	 removeObserver:self
	 name:UIApplicationDidBecomeActiveNotification
	 object:nil];
    
    [super viewDidUnload];
}

- (void)onApplicationWillResignActive:(NSDictionary*)userInfo
{
	if (m_pMetaioSDK)
		m_pMetaioSDK->pause();
}

- (void)onApplicationDidBecomeActive:(NSDictionary*)userInfo
{
	if (m_pMetaioSDK)
		m_pMetaioSDK->resume();
}

// Force fullscreen without status bar on iOS 7
- (BOOL)prefersStatusBarHidden
{
	return YES;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
	return YES;
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
	if (m_pMetaioSDK)
		m_pMetaioSDK->setScreenRotation(metaio::getScreenRotationForInterfaceOrientation(toInterfaceOrientation));
    
	[super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
}

- (void)didReceiveMemoryWarning
{
	[super didReceiveMemoryWarning];
    
	if ([self isViewLoaded] && ([[self view] window] == nil))
	{
		self.view = nil;
		
		[self tearDownGL];
		
		if ([EAGLContext currentContext] == self.context)
			[EAGLContext setCurrentContext:nil];
		
		self.context = nil;
	}
    
	// Dispose of any resources that can be recreated.
}

- (void)initMetaioSDK
{
	// Create metaio SDK instance
	m_pMetaioSDK = metaio::CreateMetaioSDKIOS(SDK_LICENSE);
    if (!m_pMetaioSDK)
    {
        NSLog(@"SDK instance could not be created. Please verify the signature string.");
        return;
    }
    
    m_pSensors = metaio::CreateSensorsComponent();
    if (!m_pSensors)
    {
        NSLog(@"Could not create the sensors interface");
        return;
    }
    m_pMetaioSDK->registerSensorsComponent(m_pSensors);
    
	// Set up custom rendering (metaio SDK will only do tracking and not render any objects itself)
	m_pMetaioSDK->initializeRenderer(0, 0, metaio::getScreenRotationForInterfaceOrientation(self.interfaceOrientation), metaio::ERENDER_SYSTEM_NULL, NULL);
    
    // Register callback method for receiving camera frames and the SDK ready event
    m_pMetaioSDK->registerDelegate(self);
}

- (void)setupGL
{
	[EAGLContext setCurrentContext:self.context];
	
	glEnable(GL_DEPTH_TEST);
    
	m_pScene = [[Scene alloc] init];
}

- (void)tearDownGL
{
	[EAGLContext setCurrentContext:self.context];
	
	m_pScene = nil;
}

#pragma mark - GLKView and GLKViewController delegate methods

- (void)update {
    m_pMetaioSDK->requestCameraImage();
    m_pMetaioSDK->render();
    
    metaio::TrackingValues trackingValues = m_pMetaioSDK->getTrackingValues(1);
    if (state == ViewingTree) {
        if (!m_SDKReady || trackingValues.quality <= 0) {
            stateStartTime = CFAbsoluteTimeGetCurrent();
        }
    }

    if (state == ViewingTree && CFAbsoluteTimeGetCurrent() > stateStartTime + VIEWING_TREE_TIME && m_pScene.giftNumber < giftCount) {
        [self startShowingGift];
    }
    if (state == ShowingGift && CFAbsoluteTimeGetCurrent() > stateStartTime + VIEWING_GIFT_TIME) {
        //[self startShowingArrow];
        [self startSeekingObject];
    }
    if (state == ShowingArrow && CFAbsoluteTimeGetCurrent() > stateStartTime + VIEWING_ARROW_TIME) {
        [self startSeekingObject];
    }
    if (state == StartSeekingObject && CFAbsoluteTimeGetCurrent() > stateStartTime + SEEKING_OBJECT_DELAY) {
        [self doSeekObject];
    }
    if (state == SeekingObject && CFAbsoluteTimeGetCurrent() > stateStartTime + SEEKING_OBJECT_TIMEOUT) {
        [self doSeek2DObject];
    }
    if (state == ViewingObject && m_pScene.distanceToTrackedObject < 250.0f) {
        [self startBringingObjectHome];
    }
    if (state == BringingObjectHome && m_SDKReady && trackingValues.quality > 0 && CFAbsoluteTimeGetCurrent() > stateStartTime + 2.0f) {
        [self startPlacingObject];
    }
    if (state == PlacingObject && [m_pScene gloomiesDistanceToTarget] < 10.0f) {
        m_pScene.giftNumber++;
        [self startViewingTree];
    }
    
    [self updateGloomiesTarget];

    [m_pScene update:motionManager.deviceMotion];
}

- (void)updateGloomiesTarget {
    int gloomiesTarget = GLOOMIES_TARGET_NONE;
    bool trackingTree = NO;
    switch (state) {
        case ViewingTree:
            gloomiesTarget = GLOOMIES_TARGET_TREE;
            trackingTree = YES;
            break;
        case ShowingGift:
            gloomiesTarget = GLOOMIES_TARGET_GIFT;
            trackingTree = YES;
            break;
        case ShowingArrow:
            gloomiesTarget = GLOOMIES_TARGET_ARROW;
            trackingTree = NO;
            break;
        case StartSeekingObject:
        case SeekingObject:
            gloomiesTarget = GLOOMIES_TARGET_SEEKING_OBJECT;
            trackingTree = NO;
            break;
        case ViewingObject:
            gloomiesTarget = GLOOMIES_TARGET_VIEWING_OBJECT;
            trackingTree = YES;
            break;
        case BringingObjectHome:
            gloomiesTarget = GLOOMIES_TARGET_BRINGING_OBJECT_HOME;
            trackingTree = YES;
            break;
        case PlacingObject:
            gloomiesTarget = GLOOMIES_TARGET_PLACE_OBJECT;
            trackingTree = YES;
            break;
        default:
            gloomiesTarget = GLOOMIES_TARGET_NONE;
            trackingTree = NO;
            break;
    }
    metaio::TrackingValues trackingValues = m_pMetaioSDK->getTrackingValues(1);
    if (trackingTree && m_SDKReady && trackingValues.quality > 0) {
        float modelMatrix[16];
        m_pMetaioSDK->getTrackingValues(1, modelMatrix, false, true);
        [m_pScene setGloomiesTargetWithTrackingValues:trackingValues modelViewMatrix:GLKMatrix4MakeWithArray(modelMatrix) deviceMotion:motionManager.deviceMotion targetMode:gloomiesTarget];
    } else {
        [m_pScene setGloomiesTargetWithDeviceMotion:motionManager.deviceMotion targetMode:gloomiesTarget];
    }
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    float projMatrix[16];
    m_pMetaioSDK->getProjectionMatrix(projMatrix, true);
    projMatrix[0] *= m_pCameraImageRenderer.scaleX;
    projMatrix[5] *= m_pCameraImageRenderer.scaleY;
    GLKMatrix4 projectionMatrix = GLKMatrix4MakeWithArray(projMatrix);

    metaio::TrackingValues trackingValues = m_pMetaioSDK->getTrackingValues(1);
    GLKMatrix4 modelViewMatrix = GLKMatrix4Identity;
    if (m_SDKReady && trackingValues.quality > 0) {
        float modelMatrix[16];
        m_pMetaioSDK->getTrackingValues(1, modelMatrix, false, true);
        modelViewMatrix = GLKMatrix4MakeWithArray(modelMatrix);
    }

    // ---
	glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    [self drawCameraImage:rect];
    switch (state) {
        case ViewingTree:
        case ShowingGift:
            [self drawTreeGloomies:projectionMatrix];
            for (int i = 0; i < m_pScene.giftNumber; i++) {
                [m_pScene drawGift:i withModelViewMatrix:modelViewMatrix projectionMatrix:projectionMatrix];
            }
            break;
        case ViewingObject:
            if (m_SDKReady && trackingValues.quality > 0) {
                [m_pScene drawGiftWithModelViewMatrix:modelViewMatrix projectionMatrix:projectionMatrix];
            }
            break;
        case BringingObjectHome:
        case PlacingObject:
            [m_pScene drawGiftWithProjectionMatrix:projectionMatrix];
            break;
        default:
            break;
    }
    if (savedToCameraRoll && CFAbsoluteTimeGetCurrent() < startShowingInfoTime + 10.0f) {
        [m_pScene drawInfoWithProjectionMatrix:projectionMatrix];
    }
    [self drawGloomies:projectionMatrix];
    [self drawSnow:projectionMatrix];
}

- (void)drawGloomies:(GLKMatrix4)projectionMatrix {
    [m_pScene drawGloomies:motionManager.deviceMotion projectionMatrix:projectionMatrix];
}

- (void)drawSnow:(GLKMatrix4)projectionMatrix {
    [m_pScene drawSnow:motionManager.deviceMotion projectionMatrix:projectionMatrix];
}

- (void)drawTreeGloomies:(GLKMatrix4)projectionMatrix {
    metaio::TrackingValues trackingValues = m_pMetaioSDK->getTrackingValues(1);
    if (m_SDKReady && trackingValues.quality > 0) {
        float modelMatrix[16];
        m_pMetaioSDK->getTrackingValues(1, modelMatrix, false, true);
        GLKMatrix4 modelViewMatrix = GLKMatrix4MakeWithArray(modelMatrix);
        
        [m_pScene drawTreeGloomiesWithModelViewMatrix:modelViewMatrix projectionMatrix:projectionMatrix];
    }
}

- (void)drawCameraImage:(CGRect)rect {
	glDisable(GL_DEPTH_TEST);
    
	[m_pCameraImageRenderer draw:m_pMetaioSDK->getScreenRotation() renderTargetAspect:((float)rect.size.width / (float)rect.size.height) alpha:[m_pScene cameraAlpha]];
    
	glEnable(GL_DEPTH_TEST);
}

#pragma mark - MetaioSDKDelegate methods

- (void)onError:(const int)errorCode description:(const NSString *)errorDescription {
    NSLog(@"ERROR: %@", errorDescription);
}

- (void) onWarning:(const int)warningCode description:(const NSString *)warningDescription {
    NSLog(@"WARNING: %@", warningDescription);
}

- (void)onNewCameraFrame:(metaio::ImageStruct*)cameraFrame {
	[m_pCameraImageRenderer updateFrame:cameraFrame];
}

- (void)onSDKReady {
	m_SDKReady = true;
}

- (void)onInstantTrackingEvent:(bool)success file:(NSString *)file {
    NSLog(@"INSTANT TRACKING EVENT");
    if(success) {
        NSLog(@"SUCCESS!");
        trackingFilename = file;
        [self startViewingObject];
    } else {
        [self resetTracking];
    }
}

- (void)startViewingObject {
    NSLog(@"Start viewing object");
    state = ViewingObject;
    stateStartTime = CFAbsoluteTimeGetCurrent();
    m_pMetaioSDK->setTrackingConfiguration(std::string([trackingFilename UTF8String]));
    [m_pScene startViewingObject];
}

- (void)startSeekingObject {
    NSLog(@"Start seeking object");
    state = StartSeekingObject;
    stateStartTime = CFAbsoluteTimeGetCurrent();
}

- (void)doSeekObject {
    state = SeekingObject;

    m_pMetaioSDK->startInstantTracking("INSTANT_3D_DRAWFEATURES=false_ANGLE=12");
    //[self performSelector:@selector(resetTracking) withObject:nil afterDelay:RESET_TRACKING_DELAY];
}

- (void)doSeek2DObject {
    NSLog(@"Start seeking 2D object");
    state = Seeking2DObject;
    stateStartTime = CFAbsoluteTimeGetCurrent();
    
    m_pMetaioSDK->startInstantTracking("INSTANT_2D");
    //[self performSelector:@selector(resetTracking) withObject:nil afterDelay:RESET_TRACKING_DELAY];
}

- (void)resetTracking {
    NSLog(@"Tracking reset!");
    switch (state) {
        case SeekingObject:
            [self doSeekObject];
            break;
        case Seeking2DObject:
            [self doSeek2DObject];
            break;
        default:
            break;
    }
}

- (void)startViewingTree {
    NSLog(@"Start viewing tree");
    state = ViewingTree;
    stateStartTime = CFAbsoluteTimeGetCurrent();
    [self startTrackingTree];
}

- (void)startShowingGift {
    NSLog(@"Start showing gift");
    state = ShowingGift;
    stateStartTime = CFAbsoluteTimeGetCurrent();
    [m_pScene startShowingGift];
}

- (void)startShowingArrow {
    state = ShowingArrow;
    stateStartTime = CFAbsoluteTimeGetCurrent();
    [m_pScene startShowingArrow];
}

- (void)startBringingObjectHome {
    NSLog(@"Start bringing object home");
    state = BringingObjectHome;
    stateStartTime = CFAbsoluteTimeGetCurrent();
    [self startTrackingTree];
}

- (void)startPlacingObject {
    NSLog(@"Start placing object");
    state = PlacingObject;
    stateStartTime = CFAbsoluteTimeGetCurrent();
}

- (void)startTrackingTree {
    NSString *trackingDataFile = [[NSBundle mainBundle] pathForResource:@"TrackingData_MarkerlessFast" ofType:@"xml" inDirectory:@"Assets"];
    if (trackingDataFile) {
        bool success = m_pMetaioSDK->setTrackingConfiguration([trackingDataFile UTF8String]);
        if (!success) {
            NSLog(@"Failed to load tracking configuration");
        }
    } else {
        NSLog(@"Could not find tracking configuration file");
    }
}

@end
