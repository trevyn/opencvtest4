#define kFFTStoreSize 120
#define kFFTWidth 160
#define kImageWidth 160
#define kImageHeight 120

#import "CVOCVController.h"
#import "OpenCVProcessor.h"

//For IKImageView dealings.
#import "CGImageWrapper.h"

@implementation CVOCVController

@synthesize cameraId;


/*+ (void) grabImage
{
    grabImage = YES;
}

+ (IplImage*) capturedImage
{
    return capturedImage;
}

+ (BOOL) bgUpdated
{
    return updated;
}

+ (void) setViewed
{       
    updated = NO;
}*/

- (void)awakeFromNib  // do setup stuff
{
    // set up storage for fftw
	
	fftwSingleRowIn = ( fftw_complex* )fftw_malloc( sizeof( fftw_complex ) * kFFTWidth * 1 );
	fftwSingleRowOut = ( fftw_complex* )fftw_malloc( sizeof( fftw_complex ) * kFFTWidth * 1 );
	fftwStore = ( fftw_complex* )fftw_malloc( sizeof( fftw_complex ) * kFFTWidth * kFFTStoreSize );
    
    // set up fftw plans
    
    fftwForwardPlan = fftw_plan_dft_2d( 1 , kFFTWidth, fftwSingleRowIn, fftwSingleRowOut, FFTW_FORWARD,  FFTW_ESTIMATE );
    fftwInversePlan = fftw_plan_dft_2d( 1 , kFFTWidth, fftwSingleRowIn, fftwSingleRowOut, FFTW_BACKWARD,  FFTW_ESTIMATE );

    // set up poc Images
    
    poc= cvCreateImage( cvSize( kFFTWidth, kFFTStoreSize ), IPL_DEPTH_64F, 1 );
	pocdisp= cvCreateImage( cvSize( kFFTWidth, kFFTStoreSize ), IPL_DEPTH_8U, 1 );

    // one-pixel-high line for doing range detection
    pocOneLine= cvCreateImage( cvSize( kFFTWidth, 1 ), IPL_DEPTH_64F, 1 );

    
    // Create the capture session
	mCaptureSession = [[QTCaptureSession alloc] init];
    
    mOutput = [[QTCaptureDecompressedVideoOutput alloc] init];

    [mOutput setPixelBufferAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                        [NSNumber numberWithDouble:kImageWidth], (id)kCVPixelBufferWidthKey,
                                        [NSNumber numberWithDouble:kImageHeight], (id)kCVPixelBufferHeightKey,
                                        [NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA], (id)kCVPixelBufferPixelFormatTypeKey,
                                        nil]];
    
//    [mOutput setMinimumVideoFrameInterval:1];
    
    [mOutput setDelegate:self];

    frameImage = cvCreateImage(cvSize(kImageWidth, kImageHeight), IPL_DEPTH_8U, 3);
    
    //(IplImage*)malloc(sizeof(IplImage));
    
    capturedImage = 0;
        
	BOOL success = NO;
	NSError *error;
	
    //Find a device  
    QTCaptureDevice *videoDevice;
    
 //   = [QTCaptureDevice defaultInputDeviceWithMediaType:QTMediaTypeVideo];
    
    NSLog(@"Devices found:");
    
    
    for (QTCaptureDevice *element in [QTCaptureDevice inputDevicesWithMediaType:QTMediaTypeVideo]) {
        NSLog(@"%@", [element description]);
        NSLog(@"%@", [element uniqueID]);
    }
        
    videoDevice = [QTCaptureDevice deviceWithUniqueID:cameraId];
   
    NSLog(@"Selecting device %@", videoDevice);
    
    [videoDevice open:&error];
    
    if (error != nil) {
        NSLog(@"Had some trouble selecting that device. I'm leaving now.");
        return;
    }
    
    //Add the video device to the session as a device input
    if (videoDevice) {

		mCaptureVideoDeviceInput = [[QTCaptureDeviceInput alloc] initWithDevice:videoDevice];
		success = [mCaptureSession addInput:mCaptureVideoDeviceInput error:&error];
        
		if (!success) {
            NSLog(@"Couldn't set up the input device. I'm leaving now.");
            return;
		}
        
        success = [mCaptureSession addOutput:mOutput error:&error];
        
		if (!success) {
            NSLog(@"Couldn't set up the output device. I'm leaving now.");
            return;
		}
        
        [mCaptureView setCaptureSession:mCaptureSession];
        
        //Looks like we're good to go.
        [mCaptureSession startRunning];
        
        grabImage = NO;
        imageView.autoresizes = YES;
        
        
        
        
        
	}
}

- (void)windowWillClose:(NSNotification *)notification
{
	[mCaptureSession stopRunning];
    
    if ([[mCaptureVideoDeviceInput device] isOpen])
        [[mCaptureVideoDeviceInput device] close];
}

- (void)dealloc
{
    fftw_destroy_plan( fftwForwardPlan );
    fftw_destroy_plan( fftwInversePlan );
    
	[mCaptureSession release];
	[mCaptureVideoDeviceInput release];

    free(frameImage);
    if(capturedImage) {
        cvReleaseImage(&capturedImage);
    }
	
	[super dealloc];
}

//Create a CGImageRef from the video frame so we can send it to the ImageKitView.
static CGImageRef CreateCGImageFromPixelBuffer(CVImageBufferRef inImage, OSType inPixelFormat)
{
    CGColorSpaceRef colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
    
    void *baseAddress = CVPixelBufferGetBaseAddress(inImage);
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(inImage);
    
    size_t width = CVPixelBufferGetWidth(inImage);
    size_t height = CVPixelBufferGetHeight(inImage);
    CGImageAlphaInfo alphaInfo = kCGImageAlphaNoneSkipLast;
    CGDataProviderRef provider = provider = CGDataProviderCreateWithData(NULL, baseAddress, bytesPerRow * height, NULL);

    CGImageRef image = CGImageCreate(width, height, 8, 32, bytesPerRow, colorSpace, alphaInfo, provider, NULL, false, kCGRenderingIntentDefault);
    
    // Once the image is created we can release our reference to the provider and the colorspace, they are retained by the image
    if (provider) {
        CGDataProviderRelease(provider);
    if (colorSpace) 
        CGColorSpaceRelease(colorSpace);
    }
    
    return image;
}

/*
 * Here, we would like to allow the user to capture video frames and send them to 
 * the special ImageKit view for background subtraction or other OpenCV-related tasks
 * that require a reference frame. If we don't call setImage: on the main thread,
 * we won't see an update. For the uninitiated, callback procedures like 
 * captureOutput: below are typically *not* called from the main thread. We also 
 * get to wrap our CGImageRef up into a custom Cocoa object just to hold it while 
 * we pass it to this method, because performSelectorOnMainThread takes an id.
 */
-(void) updateView:(CGImageWrapper*)wrappedImage
{
    [imageView setImage:wrappedImage.theImage imageProperties:nil];
    [imageView zoomImageToFit:self];

    [wrappedImage release];
}



- (NSString *)qtTimeAsString:(QTTime)currQTTime
{
	int actualSeconds = currQTTime.timeValue/currQTTime.timeScale;
	div_t hours = div(actualSeconds,3600);
	div_t minutes = div(hours.rem,60);
	
	// TODO: Internationalize these time strings if necessary.
	if (hours.quot == 0) {
		return [NSString stringWithFormat:@"%d:%.2d", minutes.quot, minutes.rem];
	}
	else {
		return [NSString stringWithFormat:@"%d:%02d:%02d", hours.quot, minutes.quot, minutes.rem];
	}	
}


/*
 * Here's one reference that I found moderately useful for this CoreVideo stuff:
 * http://developer.apple.com/documentation/graphicsimaging/Reference/CoreVideoRef/Reference/reference.html
 */
- (void)captureOutput:(QTCaptureOutput *)captureOutput didOutputVideoFrame:(CVImageBufferRef)videoFrame withSampleBuffer:(QTSampleBuffer *)sampleBuffer fromConnection:(QTCaptureConnection *)connection
{
    
//    NSLog([self qtTimeAsString:[sampleBuffer presentationTime]]);
    
    int err= CVPixelBufferLockBaseAddress((CVPixelBufferRef)videoFrame, 0);
    if(err)
        printf("CVPixelBufferLockBaseAddress fail\n");
    
    UInt8 *outBuf= frameImage->imageData;
    UInt8 *inBuf= (UInt8 *) CVPixelBufferGetBaseAddress((CVPixelBufferRef)videoFrame);
    int length = CVPixelBufferGetDataSize((CVPixelBufferRef)videoFrame);

    // convert bgra to greyscale rgb from green channel
    
    for (int index = 0; index < length; index+= 4) {
        ++inBuf;
        *(outBuf++)= *inBuf;
        *(outBuf++)= *inBuf;
        *(outBuf++)= *inBuf;
        inBuf+= 3;
    }
    
    CVPixelBufferUnlockBaseAddress((CVPixelBufferRef)videoFrame, 0);

//    tmpByte = pixelData[index + 1];
//        pixelData[index + 1] = pixelData[index + 3];
//        pixelData[index + 3] = tmpByte;
//    }

    
//    cvCreateImage(cvGetSize(frameImage), IPL_DEPTH_8U, 3);
//    int length = CVPixelBufferGetDataSize((CVPixelBufferRef)videoFrame);

    
        // the data retrieved from the image ref has 4 bytes per pixel (ABGR).
/*        UInt8 *pixelData = (UInt8 *) CVPixelBufferGetBaseAddress((CVPixelBufferRef)videoFrame);
        int length = CVPixelBufferGetDataSize((CVPixelBufferRef)videoFrame);
        
        // abgr to rgba
        // swap the blue and red components for each pixel...
        UInt8 tmpByte = 0;
        for (int index = 0; index < length; index+= 4) {
            tmpByte = pixelData[index + 1];
            pixelData[index + 1] = pixelData[index + 3];
            pixelData[index + 3] = tmpByte;
        }
    */
    
    //Fill in the OpenCV image struct from the data from CoreVideo.
/*    frameImage->nSize       = sizeof(IplImage);
    frameImage->ID          = 0;
    frameImage->nChannels   = 3;
    frameImage->depth       = IPL_DEPTH_8U;
    frameImage->dataOrder   = 0;
    frameImage->origin      = 0; //Top left origin.
    frameImage->width       = CVPixelBufferGetWidth((CVPixelBufferRef)videoFrame);
    frameImage->height      = CVPixelBufferGetHeight((CVPixelBufferRef)videoFrame);
    frameImage->roi         = 0; //Region of interest. (struct IplROI).
    frameImage->maskROI     = 0;
    frameImage->imageId     = 0;
    frameImage->tileInfo    = 0;
    frameImage->imageSize   = CVPixelBufferGetDataSize((CVPixelBufferRef)videoFrame);
    frameImage->imageData   = (char*)CVPixelBufferGetBaseAddress((CVPixelBufferRef)videoFrame);
    frameImage->widthStep   = CVPixelBufferGetBytesPerRow((CVPixelBufferRef)videoFrame);
    frameImage->imageDataOrigin = (char*)CVPixelBufferGetBaseAddress((CVPixelBufferRef)videoFrame);
*/
    
    
    
    
    
    
    
    
    
    
    
    
    //If we were asked to capture a background frame. Do it now before we unlock the pixels.
/*    if(grabImage) {
        CGImageWrapper *iwrap = [[CGImageWrapper alloc] initWithCGImage:CreateCGImageFromPixelBuffer(videoFrame, kCVPixelFormatType_32BGRA)];
        [self performSelectorOnMainThread:@selector(updateView:) withObject:iwrap waitUntilDone:YES];
        if(!capturedImage) {
            //capturedImage = (IplImage*)malloc(sizeof(IplImage));
            capturedImage = cvCreateImage(cvGetSize(frameImage), IPL_DEPTH_8U, 3); 
        }
        cvCopy(frameImage, capturedImage, 0);
        updated = YES;
        grabImage = NO;
    }*/
    
    //Process the frame, and get the result.
//    IplImage *resultImage = [OpenCVProcessor passThrough:frameImage];
    //IplImage *resultImage = [OpenCVProcessor noiseFilter:frameImage];
    //IplImage *resultImage = [OpenCVProcessor findSquares:frameImage];
    //IplImage *resultImage = [OpenCVProcessor hueSatHistogram:frameImage];
    
    CvSize imgSize;                 
    imgSize.width = kImageWidth; 
    imgSize.height = kImageHeight; 

    IplImage* hannImage=     cvCreateImage(imgSize, IPL_DEPTH_8U, 1); 
    IplImage* greyImage=     cvCreateImage(imgSize, IPL_DEPTH_8U, 1); 

    cvCvtColor(frameImage,greyImage,CV_BGR2GRAY); 
    
    // project and calculate hann window
    
    int i, j;
    uchar 	*inData= ( uchar* ) greyImage->imageData;
    uchar 	*hannImageData= ( uchar* ) hannImage->imageData;
    unsigned long acc;
    
    for( j = 0 ; j < greyImage->width ; j++) {
        
        // sum input column
        
        acc= 0;
        for( i = 0; i < greyImage->height ; i++ ) {
            acc+= inData[i * greyImage->widthStep + j];
        }
        
        // hann window and output
        
        double hannMultiplier = 0.5 * (1 - cos(2*3.14159*j/(greyImage->width-1)));  // hann window coefficient

        for( i = 0; i < (openGLView->toggleStatus == YES ? kImageHeight : 1) ; i++ ) {
            hannImageData[i * hannImage->widthStep + j]=  hannMultiplier * (acc/greyImage->height);
        }
        
    }
    
    // display hann image
    
    if(openGLView->toggleStatus == YES) {
        IplImage *resultImage = cvCreateImage(cvSize(kImageWidth, kImageHeight), IPL_DEPTH_8U, 3);
            
        cvCvtColor(hannImage,resultImage,CV_GRAY2BGR); 

        [self texturizeImage:resultImage];  // resultImage will get dealloc'd after being pushed to OpenGL.
    }
    
    
    
    // load data for fftw
    
    for( int j = 0 ; j < kFFTWidth ; j++) {
        fftwSingleRowIn[j][0] = ( double )hannImageData[j];
        fftwSingleRowIn[j][1] = 0.0;
    }
    
    // run forward fft
    
    fftw_execute( fftwForwardPlan );
    
    // copy data to store
    
    for(int j= 0; j < kFFTWidth ; j++) {
        fftwStore[(kFFTWidth * pocline) + j][0]= fftwSingleRowOut[j][0];
        fftwStore[(kFFTWidth * pocline) + j][1]= fftwSingleRowOut[j][1];
    }
    
    // compare pocline against ALL OTHER IN STORE
    
    for( int j = 0 ; j < kFFTStoreSize ; j++) {
        
        fftw_complex *img1= &(fftwStore[kFFTWidth * pocline]);
        fftw_complex *img2= &(fftwStore[kFFTWidth * j]);
        
        // obtain the cross power spectrum
        for( int i = 0; i < kFFTWidth ; i++ ) {
            
            // complex multiply complex img2 by complex conjugate of complex img1
            
            fftwSingleRowIn[i][0] = ( img2[i][0] * img1[i][0] ) - ( img2[i][1] * ( -img1[i][1] ) );
            fftwSingleRowIn[i][1] = ( img2[i][0] * ( -img1[i][1] ) ) + ( img2[i][1] * img1[i][0] );
            
            // set tmp to (real) absolute value of complex number res[i]
            
            double tmp = sqrt( pow( fftwSingleRowIn[i][0], 2.0 ) + pow( fftwSingleRowIn[i][1], 2.0 ) );
            
            // complex divide res[i] by (real) absolute value of res[i]
            // (this is the normalization step)
            
            if(tmp == 0) {
                fftwSingleRowIn[i][0]= 0;
                fftwSingleRowIn[i][1]= 0;
            }
            else {
                fftwSingleRowIn[i][0] /= tmp;
                fftwSingleRowIn[i][1] /= tmp;
            }
        }
        
        // run inverse
        
        fftw_execute(fftwInversePlan);
        
        // normalize and copy to result image
        
        double 	*pocOneLine_data = ( double* )pocOneLine->imageData;
        if( j == (pocline-1) ) {
            for( int k = 0 ; k < kFFTWidth ; k++ ) {
                pocOneLine_data[k] = (fftwSingleRowOut[k][0] / ( double )kFFTWidth);
            }
        }
            
        double 	*poc_data = ( double* )poc->imageData;
        
        for( int k = 0 ; k < kFFTWidth ; k++ ) {
            poc_data[(((kFFTWidth*3/2)-k)%kFFTWidth)+(j*kFFTWidth)] = (fftwSingleRowOut[k][0] / ( double )kFFTWidth);
        }
        
        
    }
    
    
    
    
    // inc pocline
    
    pocline++;
    if(pocline == kFFTStoreSize-1)
        pocline= 0;
    
    
    // display??
    
    
    //		for(int i = 0 ; i < kFFTWidth ; i++ ) {
    //			poc_data[i+(pocline*kFFTWidth)] = (fftwStore[(kFFTWidth * pocline)+i])[1];
    //		}
    
    // find the maximum value and its location
    CvPoint minloc, maxloc;
    double  minval, maxval;
    cvMinMaxLoc( poc, &minval, &maxval, &minloc, &maxloc, 0 );
    
    // print it
    //		printf( "Maxval at (%d, %d) = %2.4f\n", maxloc.x, maxloc.y, maxval );
    
    
    if(openGLView->toggleStatus == NO) {
    
        cvCvtScale(poc, pocdisp, (1.0/(maxval/2))*255, 0);

        IplImage *resultImage = cvCreateImage(cvSize(kImageWidth, kImageHeight), IPL_DEPTH_8U, 3);
        
        cvCvtColor(pocdisp,resultImage,CV_GRAY2BGR); 
        
        [self texturizeImage:resultImage];  // resultImage will get dealloc'd after being pushed to OpenGL.
    }
    
    
    cvMinMaxLoc( pocOneLine, &minval, &maxval, &minloc, &maxloc, 0 );
    int pocoffset= maxloc.x;
    if (pocoffset > kImageWidth/2)
        pocoffset-= kImageWidth;
    if(pocoffset != 0)
        printf("%d\n", pocoffset);
    
//    cvShowImage("poc",pocdisp);    
    
    
    cvReleaseImage(&hannImage);
    cvReleaseImage(&greyImage);
    
    
    
    //       IplImage *resultImage = [OpenCVProcessor passThrough:hannImage];

    
//    IplImage *resultImage = [OpenCVProcessor houghLinesStandard:frameImage];
    
    //IplImage *resultImage = [OpenCVProcessor downsize8:frameImage];
    
    //Back project example. Hit the space bar to capture the reference image.
    //IplImage *resultImage = [OpenCVProcessor backProject:frameImage];
    
    
    //IplImage *resultImage = [OpenCVProcessor cannyTest:frameImage];

    
//CVPixelBufferUnlockBaseAddress((CVPixelBufferRef)videoFrame, 0);
}

-(void) texturizeImage:(IplImage*) image
{
    int newIndex = openGLView->imageIndex;
    newIndex = (newIndex + 1) % IMAGE_CACHE_SIZE;
    openGLView->cvTextures[newIndex].texImage = image;
    openGLView->imageIndex = newIndex;
    [openGLView setNeedsDisplay:YES];
}

@end
