/*
 *  CVOCVController.h
 *
 *  Created by buza on 10/02/08.
 *
 *  Brought to you by buzamoto. http://buzamoto.com
 */

#include "cv.h"
#include "fftw3.h"

#import <Cocoa/Cocoa.h>
#import <QTKit/QTkit.h>
#import <Quartz/Quartz.h>

#import "CVOCVView.h"

@interface CVOCVController : NSObject 
{
    IBOutlet CVOCVView *openGLView;
    IBOutlet IKImageView *imageView;
    IBOutlet QTCaptureView *mCaptureView;
       
    QTCaptureSession                    *mCaptureSession;
    QTCaptureMovieFileOutput            *mCaptureMovieFileOutput;
    QTCaptureDeviceInput                *mCaptureVideoDeviceInput;
    QTCaptureDecompressedVideoOutput    *mOutput;

    IplImage *frameImage;
    
    fftw_complex *fftwSingleRowIn;
    fftw_complex *fftwSingleRowOut;
    fftw_complex *fftwStore;
    
    fftw_plan fftwForwardPlan;
    fftw_plan fftwInversePlan;
    
    int pocline;

    IplImage *pocdisp;
    IplImage *poc;
    IplImage *pocOneLine;
    
    
    BOOL updated;
    BOOL grabImage;
    IplImage *capturedImage;

    NSString *cameraId;

}

@property (nonatomic, retain) NSString *cameraId;

//+ (BOOL) bgUpdated;
//+ (void) setViewed;

- (void) texturizeImage:(IplImage*) image;

@end
