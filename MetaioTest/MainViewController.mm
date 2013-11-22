// Define your license here. For more information, please visit http://dev.metaio.com - you can add
// a new application at http://dev.metaio.com/get-developer-key/
#define SDK_LICENSE "k9r8rzscv1FSaUictM5ZE/be3jxbpyyCVl/h7edHHUk="
#if !defined (SDK_LICENSE)
#error Please provide the license string for your application
#endif

// Make sure that we're building this with an iOS SDK that at least supports iOS5
#ifndef __IPHONE_5_0
#error Please update to an iOS SDK that supports at least iOS5. iOS applications should always be built with the latest SDK
#endif

#import <CoreMotion/CoreMotion.h>

#import "CameraImageRenderer.h"
#import "Scene.h"
#import "MainViewController.h"
#import "Constants.h"

#define RESET_TRACKING_DELAY 3.0f

metaio::IMetaioSDKIOS *m_pMetaioSDK;

enum State {
    ViewingTree      = 0,
    BeingGuided      = 1,
    SeekingObject    = 2
};
    
@interface MainViewController () {
	CameraImageRenderer*		m_pCameraImageRenderer;
	Scene*						m_pScene;
    
	metaio::ISensorsComponent*	m_pSensors;
	bool						m_SDKReady;

    CMMotionManager *motionManager;
    
    State state;
    NSString *treeFilename;
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
    treeFilename = nil;
    
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

	[self initMetaioSDK];
    [self startViewingTree];
    
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
    
    [self updateGloomiesTarget];

    [m_pScene update:motionManager.deviceMotion];
}

- (void)updateGloomiesTarget {
    if (state != ViewingTree) {
        return;
    }
    metaio::TrackingValues trackingValues = m_pMetaioSDK->getTrackingValues(1);
    
    if (m_SDKReady && trackingValues.quality > 0) {
        float modelMatrix[16];
        m_pMetaioSDK->getTrackingValues(1, modelMatrix, false, true);
        [m_pScene setGloomiesTargetWithTrackingValues:trackingValues modelViewMatrix:GLKMatrix4MakeWithArray(modelMatrix) deviceMotion:motionManager.deviceMotion];
    } else {
        [m_pScene setGloomiesTargetWithDeviceMotion:motionManager.deviceMotion];
    }
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    float projMatrix[16];
    m_pMetaioSDK->getProjectionMatrix(projMatrix, true);
    projMatrix[0] *= m_pCameraImageRenderer.scaleX;
    projMatrix[5] *= m_pCameraImageRenderer.scaleY;
    GLKMatrix4 projectionMatrix = GLKMatrix4MakeWithArray(projMatrix);

    // ---
	glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    [self drawCameraImage:rect];
    switch (state) {
        case ViewingTree:
            [self drawTreeGloomies:projectionMatrix];
            break;
        case BeingGuided:
            break;
        case SeekingObject:
            break;
        default:
            break;
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
    
	[m_pCameraImageRenderer draw:m_pMetaioSDK->getScreenRotation() renderTargetAspect:((float)rect.size.width / (float)rect.size.height)];
    
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
        switch (state) {
            /*case SeekingTree:
                treeFilename = file;
                [self startViewingTree];
                break;*/
            case SeekingObject:
                break;
            default:
                break;
        }
    } else {
        [self resetTracking];
    }
}

- (void)startSeekingObject {
    state = SeekingObject;
    m_pMetaioSDK->startInstantTracking("INSTANT_3D_DRAWFEATURES=false_ANGLE=12");
    [self performSelector:@selector(resetTracking) withObject:nil afterDelay:RESET_TRACKING_DELAY];
}

- (void)startTrackingGuide {
    state = BeingGuided;
    m_pMetaioSDK->startInstantTracking("INSTANT_2D");
}

- (void)resetTracking {
    NSLog(@"Tracking reset!");
    switch (state) {
        case SeekingObject:
            [self startSeekingObject];
            break;
        default:
            break;
    }
}

- (void)startViewingTree {
    state = ViewingTree;
    
    //m_pMetaioSDK->setTrackingConfiguration(std::string([treeFilename UTF8String]));
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
