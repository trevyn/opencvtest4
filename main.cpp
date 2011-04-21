#include <stdio.h>
#include "cv.h"
#include "highgui.h"
#include "fftw3.h"

#define kFFTStoreSize 240
#define kFFTWidth 320

int pocline= 0;

void phase_correlation( IplImage *ref, IplImage *tpl, IplImage *poc );

int main( int argc, char** argv )
{
    CvSize imgSize;                 
    imgSize.width = 320; 
    imgSize.height = 240; 
	
	int key= -1; 
	
	// set up opencv capture objects

    CvCapture* capture= cvCaptureFromCAM(0); 
	cvSetCaptureProperty(capture, CV_CAP_PROP_FRAME_WIDTH, 320);
	cvSetCaptureProperty(capture, CV_CAP_PROP_FRAME_HEIGHT, 240);
	
    CvCapture* capture2= cvCaptureFromCAM(1); 
	cvSetCaptureProperty(capture2, CV_CAP_PROP_FRAME_WIDTH, 320);
	cvSetCaptureProperty(capture2, CV_CAP_PROP_FRAME_HEIGHT, 240);

    CvCapture* capture3= cvCaptureFromCAM(2); 
	cvSetCaptureProperty(capture3, CV_CAP_PROP_FRAME_WIDTH, 320);
	cvSetCaptureProperty(capture3, CV_CAP_PROP_FRAME_HEIGHT, 240);

    
	// allocate image storage (other createimage specifiers: IPL_DEPTH_32F, IPL_DEPTH_8U)
	
    IplImage* colourImage  = cvCloneImage(cvQueryFrame(capture)); 
    IplImage* greyImage    = cvCreateImage(cvGetSize(colourImage), IPL_DEPTH_8U, 1); 
    IplImage* hannImage    = cvCloneImage(greyImage); 
	IplImage *poc= cvCreateImage( cvSize( greyImage->width, kFFTStoreSize ), IPL_DEPTH_64F, 1 );
	IplImage *pocdisp= cvCreateImage( cvSize( greyImage->width, kFFTStoreSize ), IPL_DEPTH_8U, 1 );
	
	// set up opencv windows
	
    cvNamedWindow("hannImage", 1);
    cvNamedWindow("greyImage", 1); 
    cvNamedWindow("greyImage2", 1); 
    cvNamedWindow("greyImage3", 1); 
    cvNamedWindow("poc", 1);
	cvMoveWindow("greyImage", 40, 0);
	cvMoveWindow("hannImage", 40, 270);
	cvMoveWindow("poc", 365, 0);
	cvMoveWindow("greyImage2", 40, 540);
	cvMoveWindow("greyImage3", 365, 540);
	
	// set up storage for fftw
	
	fftw_complex *fftwSingleRow = ( fftw_complex* )fftw_malloc( sizeof( fftw_complex ) * kFFTWidth * 1 );
	fftw_complex *fftwSingleRow2 = ( fftw_complex* )fftw_malloc( sizeof( fftw_complex ) * kFFTWidth * 1 );
	fftw_complex *fftwStore = ( fftw_complex* )fftw_malloc( sizeof( fftw_complex ) * kFFTWidth * kFFTStoreSize );
		
	// loop
	
    while(key != 'q') 
	{ 

		//		double t = (double)cvGetTickCount();
		//		printf( "%g ms: start.\n", (cvGetTickCount() - t)/((double)cvGetTickFrequency()*1000.));

		// capture a frame, convert to greyscale, and show it
		
		cvCopyImage(cvQueryFrame(capture), colourImage);  // cvCopy because both are allocated already!
		cvCvtColor(colourImage,greyImage,CV_BGR2GRAY); 
		cvShowImage("greyImage",greyImage); 

        cvCopyImage(cvQueryFrame(capture2), colourImage);  // cvCopy because both are allocated already!
		cvCvtColor(colourImage,greyImage,CV_BGR2GRAY); 
		cvShowImage("greyImage2",greyImage); 

        cvCopyImage(cvQueryFrame(capture3), colourImage);  // cvCopy because both are allocated already!
		cvCvtColor(colourImage,greyImage,CV_BGR2GRAY); 
		cvShowImage("greyImage3",greyImage);

        
        key = cvWaitKey(3);

		// project and calculate hann window
		
		int i, j, k;
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
			
			for( i = 0; i < 240 ; i++ ) {
				double hannMultiplier = 0.5 * (1 - cos(2*3.14159*j/(greyImage->width-1)));  // hann window coefficient
				hannImageData[i * hannImage->widthStep + j]=  hannMultiplier * (acc/greyImage->height);
			}
			
		}

		cvShowImage("hannImage",hannImage); 

		// set up forward FFT into store plan
		
		fftw_plan fft_plan = fftw_plan_dft_2d( 1 , kFFTWidth, fftwSingleRow, &(fftwStore[kFFTWidth * pocline]), FFTW_FORWARD,  FFTW_ESTIMATE );
				
		// load data for fftw
		
		for( int j = 0 ; j < kFFTWidth ; j++) {
			fftwSingleRow[j][0] = ( double )hannImageData[j];
			fftwSingleRow[j][1] = 0.0;
		}
		
		// run and release plan
		
		fftw_execute( fft_plan );
		fftw_destroy_plan( fft_plan );

		// compare pocline against ALL OTHER IN STORE

		for( int j = 0 ; j < kFFTStoreSize ; j++) {
			
			fftw_complex *img1= &(fftwStore[kFFTWidth * pocline]);
			fftw_complex *img2= &(fftwStore[kFFTWidth * j]);
			
			// obtain the cross power spectrum
			for( int i = 0; i < kFFTWidth ; i++ ) {
				
				// complex multiply complex img2 by complex conjugate of complex img1
				
				fftwSingleRow[i][0] = ( img2[i][0] * img1[i][0] ) - ( img2[i][1] * ( -img1[i][1] ) );
				fftwSingleRow[i][1] = ( img2[i][0] * ( -img1[i][1] ) ) + ( img2[i][1] * img1[i][0] );
				
				// set tmp to (real) absolute value of complex number res[i]
				
				double tmp = sqrt( pow( fftwSingleRow[i][0], 2.0 ) + pow( fftwSingleRow[i][1], 2.0 ) );
				
				// complex divide res[i] by (real) absolute value of res[i]
				// (this is the normalization step)
				
				if(tmp == 0) {
					fftwSingleRow[i][0]= 0;
					fftwSingleRow[i][1]= 0;
				}
				else {
					fftwSingleRow[i][0] /= tmp;
					fftwSingleRow[i][1] /= tmp;
				}
			}
				
			// run inverse
			
			fft_plan = fftw_plan_dft_2d( 1 , kFFTWidth, fftwSingleRow, fftwSingleRow2, FFTW_BACKWARD,  FFTW_ESTIMATE );
			fftw_execute(fft_plan);
			fftw_destroy_plan( fft_plan );

			// normalize and copy to result image

			double 	*poc_data = ( double* )poc->imageData;
			
			for( int k = 0 ; k < kFFTWidth ; k++ ) {
				poc_data[k+(j*kFFTWidth)] = (fftwSingleRow2[k][0] / ( double )kFFTWidth);
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
		
//        cvConvertScale(dft_re,dft_orig,255,0); //255.0*(max-min),0);

        
        
		cvCvtScale(poc, pocdisp, (1.0/(maxval/2))*255, 0);
		
		cvShowImage("poc",pocdisp);
		
		
		// set up fftw plans
//		fftw_plan fft_plan = fftw_plan_dft_2d( 1 , kFFTWidth, img2, img2, FFTW_FORWARD,  FFTW_ESTIMATE );
//		fftw_plan ifft_plan = fftw_plan_dft_2d( 1 , kFFTWidth, res,  res,  FFTW_BACKWARD, FFTW_ESTIMATE );
		
		
		
		// TODO FROM HERE
		
		/*
		
		if(key == 'r') {
			cvReleaseImage(&ref);
			ref= cvCloneImage(testOutImage);
			cvShowImage("ref",ref); 
		}
		
		
		
		{  // try phase correlating full img
			
			tpl= cvCloneImage(testOutImage);
			//				ref= cvCloneImage(testOutImage);
//				cvShowImage("tpl",tpl); 
//				cvShowImage("ref",ref); 
			
			
			if(ref == 0)
				continue;
			
			if( ( tpl->width != ref->width ) || ( tpl->height != ref->height ) ) {
				fprintf( stderr, "Both images must have equal width and height!\n" );
				continue
				;
			}
			
			// get phase correlation of input images
			
			phase_correlation( ref, tpl, poc );
			
			// find the maximum value and its location
			CvPoint minloc, maxloc;
			double  minval, maxval;
			cvMinMaxLoc( poc, &minval, &maxval, &minloc, &maxloc, 0 );
			
			// print it
			printf( "Maxval at (%d, %d) = %2.4f\n", maxloc.x, maxloc.y, maxval );
			
			cvCvtScale(poc, pocdisp, 1.0/(maxval/2), 0);
			
			cvShowImage("poc",pocdisp);
			
			cvReleaseImage(&tpl);
		
			
		}*/

//			cvReleaseImage(&ref);
//			ref= cvCloneImage(testOutImage);

//			printf( "%g ms: done.\n", (cvGetTickCount() - t)/((double)cvGetTickFrequency()*1000.));
			

	} 
	
	
	cvReleaseImage(&poc);

	
	return 0;
}

/*
 * get phase correlation from two images and save result to the third image
 */
/*void phase_correlation( IplImage *ref, IplImage *tpl, IplImage *poc )
{
	int 	i, j, k;
	double	tmp;
	
	// get image properties
	int width  	 = ref->width;
	int height   = 1;//ref->height;
	int step     = ref->widthStep;
	int fft_size = width * height;
	
	// setup pointers to images
	uchar 	*ref_data = ( uchar* ) ref->imageData;
	uchar 	*tpl_data = ( uchar* ) tpl->imageData;
	double 	*poc_data = ( double* )poc->imageData;
	
	
	// load images' data to FFTW input
	for( i = 0, k = 0 ; i < height ; i++ ) {
		for( j = 0 ; j < width ; j++, k++ ) {
			img1[k][0] = ( double )ref_data[i * step + j];
			img1[k][1] = 0.0;
			
			img2[k][0] = ( double )tpl_data[i * step + j];
			img2[k][1] = 0.0;
		}
	}
	
	// obtain the FFT of img1
	fftw_execute( fft_plan );
		
	// obtain the FFT of img2
	fftw_execute( fft_plan );
	
	// obtain the cross power spectrum
	for( i = 0; i < fft_size ; i++ ) {
		
		// complex multiply complex img2 by complex conjugate of complex img1
		
		res[i][0] = ( img2[i][0] * img1[i][0] ) - ( img2[i][1] * ( -img1[i][1] ) );
		res[i][1] = ( img2[i][0] * ( -img1[i][1] ) ) + ( img2[i][1] * img1[i][0] );
		
		// set tmp to (real) absolute value of complex number res[i]
		
		tmp = sqrt( pow( res[i][0], 2.0 ) + pow( res[i][1], 2.0 ) );

		// complex divide res[i] by (real) absolute value of res[i]
		// (this is the normalization step)
		
		if(tmp == 0) {
			res[i][0]= 0;
			res[i][1]= 0;
		}
		else {
			res[i][0] /= tmp;
			res[i][1] /= tmp;
		}
		
	}
	
	// obtain the phase correlation array
	fftw_execute(ifft_plan);
	
	// normalize and copy to result image
	for( i = 0 ; i < fft_size ; i++ ) {
			poc_data[i+(pocline*width)] = (res[i][0] / ( double )fft_size);
	}
//	poc_data[0]= 0;
//	pocline++;
	if(pocline==kFFTStoreSize-1)
		pocline= 0;
		
	// deallocate FFTW arrays and plans
	fftw_destroy_plan( fft_plan );
	fftw_destroy_plan( ifft_plan );
	fftw_free( img1 );
	fftw_free( img2 );
	fftw_free( res );
}*/
