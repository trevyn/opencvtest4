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
    
    fftw_complex *fftwSingleRow;
    fftw_complex *fftwSingleRow2;
    fftw_complex *fftwStore;
    
    int pocline;

    IplImage *pocdisp;
    IplImage *poc;
    
}

+ (void) grabImage;

+ (IplImage*) capturedImage;

+ (BOOL) bgUpdated;
+ (void) setViewed;

- (void) texturizeImage:(IplImage*) image;

@end
