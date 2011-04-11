#include <stdio.h>
#include "cv.h"
#include "highgui.h"
#include "fftw3.h"

int pocline= 0;

void phase_correlation( IplImage *ref, IplImage *tpl, IplImage *poc );

int main( int argc, char** argv )
{
	IplImage *tpl = 0;
	IplImage *ref = 0;
	IplImage *poc = 0;
	IplImage *pocdisp = 0;


    CvCapture* capture = cvCaptureFromCAM(0); 
	cvSetCaptureProperty( capture, CV_CAP_PROP_FRAME_WIDTH, 320 );
	cvSetCaptureProperty( capture, CV_CAP_PROP_FRAME_HEIGHT, 240 );
	
    CvSize imgSize;                 
    imgSize.width = 320; 
    imgSize.height = 240; 
	
    IplImage* colourImage  = cvCloneImage(cvQueryFrame(capture)); 
    IplImage* greyImage    = cvCreateImage( cvGetSize(colourImage), IPL_DEPTH_8U, 1); 
    IplImage* testOutImage    = cvCloneImage(greyImage); 
	
    IplImage* movingAverage = cvCreateImage( imgSize, IPL_DEPTH_32F, 3); 
    IplImage* difference    = cvCreateImage( imgSize, IPL_DEPTH_8U, 3); 
	
    cvNamedWindow( "Image", 1 ); 
    cvNamedWindow( "ref", 1 ); 
    cvNamedWindow( "tpl", 1 ); 
    cvNamedWindow( "poc", 1 ); 
    cvNamedWindow( "testout", 1 ); 
    cvNamedWindow( "testout2", 1 ); 
    cvNamedWindow( "Source", 1 ); 
	
    int key=-1; 
	
	cvCopyImage(cvQueryFrame(capture), colourImage); 
	cvCvtColor(colourImage,greyImage,CV_BGR2GRAY); 
	
	
		ref= cvCloneImage(greyImage);
		cvShowImage("ref",ref); 
		
	poc = cvCreateImage( cvSize( greyImage->width, 480 ), IPL_DEPTH_64F, 1 );
	pocdisp = cvCreateImage( cvSize( greyImage->width, 480 ), IPL_DEPTH_64F, 1 );

	
    while(key != 'q') 
	{ 
		double t = (double)cvGetTickCount();
//		printf( "%g ms: start.\n", (cvGetTickCount() - t)/((double)cvGetTickFrequency()*1000.));

		
		cvCopyImage(cvQueryFrame(capture), colourImage);  // cvCopy because both are allocated already!

//		printf( "%g ms: frame grabbed.\n", (cvGetTickCount() - t)/((double)cvGetTickFrequency()*1000.));

        cvCvtColor(colourImage,greyImage,CV_BGR2GRAY); 
		
		
        cvShowImage("Source",colourImage); 
//        cvShowImage("Image",greyImage); 
		
//		printf( "%g ms: converted and shown.\n", (cvGetTickCount() - t)/((double)cvGetTickFrequency()*1000.));

        key = cvWaitKey(3);
		
//		printf( "%g ms: out of waitkey.\n", (cvGetTickCount() - t)/((double)cvGetTickFrequency()*1000.));

		
		int i, j, k;
		uchar 	*grey_data = ( uchar* ) greyImage->imageData;
		uchar 	*testout_data = ( uchar* ) testOutImage->imageData;
		unsigned long acc;
		
		for( i = 0, k = 0 ; i < greyImage->height ; i++ ) {
			acc= 0;
			for( j = 0 ; j < greyImage->width ; j++, k++ ) {
				acc+= grey_data[i * greyImage->widthStep + j];
			}
			for( j = 0 ; j < 1 ; j++, k++ ) {
				testout_data[i * testOutImage->widthStep + j]= acc/greyImage->width;
			}
			
		}
		
//			cvShowImage("testout",testOutImage); 

		
		for( j = 0 ; j < greyImage->width ; j++) {
			acc= 0;
			for( i = 0; i < greyImage->height ; i++ ) {
				acc+= grey_data[i * greyImage->widthStep + j];
			}
			
			for( i = 0; i < 1 ; i++ ) {
//					testout_data[i * testOutImage->widthStep + j]= acc/greyImage->width;
//					double multiplier1 = 0.5 * (1 - cos(2*3.14159*i/(greyImage->height-1)));
				double multiplier2 = 0.5 * (1 - cos(2*3.14159*j/(greyImage->width-1)));
				testout_data[i * testOutImage->widthStep + j]=  multiplier2 * (acc/greyImage->height);
			
			}
			
		}
//			cvShowImage("testout2",testOutImage); 

//			printf( "%g ms: linear projections and hann window completed.\n", (cvGetTickCount() - t)/((double)cvGetTickFrequency()*1000.));

		
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
			
			/* create a new image, to store phase correlation result */
			
			/* get phase correlation of input images */
			
//				printf( "%g ms: phase correlation set up.\n", (cvGetTickCount() - t)/((double)cvGetTickFrequency()*1000.));

			
			phase_correlation( ref, tpl, poc );
			
//				printf( "%g ms: phase correlation completed.\n", (cvGetTickCount() - t)/((double)cvGetTickFrequency()*1000.));

			
			/* find the maximum value and its location */
			CvPoint minloc, maxloc;
			double  minval, maxval;
			cvMinMaxLoc( poc, &minval, &maxval, &minloc, &maxloc, 0 );
			
			/* print it */
			printf( "Maxval at (%d, %d) = %2.4f\n", maxloc.x, maxloc.y, maxval );
			
			cvCvtScale(poc, pocdisp, 1.0/(maxval/2), 0);
			
			cvShowImage("poc",pocdisp);
			
			cvReleaseImage(&tpl);
			
//				printf( "%g ms: max found and poc scale converted.\n", (cvGetTickCount() - t)/((double)cvGetTickFrequency()*1000.));

			
		}

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
void phase_correlation( IplImage *ref, IplImage *tpl, IplImage *poc )
{
	int 	i, j, k;
	double	tmp;
	
	/* get image properties */
	int width  	 = ref->width;
	int height   = 1;//ref->height;
	int step     = ref->widthStep;
	int fft_size = width * height;
	
	/* setup pointers to images */
	uchar 	*ref_data = ( uchar* ) ref->imageData;
	uchar 	*tpl_data = ( uchar* ) tpl->imageData;
	double 	*poc_data = ( double* )poc->imageData;
	
	/* allocate FFTW input and output arrays */
	fftw_complex *img1 = ( fftw_complex* )fftw_malloc( sizeof( fftw_complex ) * width * height );
	fftw_complex *img2 = ( fftw_complex* )fftw_malloc( sizeof( fftw_complex ) * width * height );
	fftw_complex *res  = ( fftw_complex* )fftw_malloc( sizeof( fftw_complex ) * width * height );	
		
	/* setup FFTW plans */
	fftw_plan fft_img1 = fftw_plan_dft_2d( height , width, img1, img1, FFTW_FORWARD,  FFTW_ESTIMATE );
	fftw_plan fft_img2 = fftw_plan_dft_2d( height , width, img2, img2, FFTW_FORWARD,  FFTW_ESTIMATE );
	fftw_plan ifft_res = fftw_plan_dft_2d( height , width, res,  res,  FFTW_BACKWARD, FFTW_ESTIMATE );
	
	/* load images' data to FFTW input */
	for( i = 0, k = 0 ; i < height ; i++ ) {
		for( j = 0 ; j < width ; j++, k++ ) {
			img1[k][0] = ( double )ref_data[i * step + j];
			img1[k][1] = 0.0;
			
			img2[k][0] = ( double )tpl_data[i * step + j];
			img2[k][1] = 0.0;
		}
	}
	
	/* obtain the FFT of img1 */
	fftw_execute( fft_img1 );
		
	/* obtain the FFT of img2 */
	fftw_execute( fft_img2 );
	
	/* obtain the cross power spectrum */
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
	
	/* obtain the phase correlation array */
	fftw_execute(ifft_res);
	
	/* normalize and copy to result image */
	for( i = 0 ; i < fft_size ; i++ ) {
			poc_data[i+(pocline*width)] = (res[i][0] / ( double )fft_size);
	}
//	poc_data[0]= 0;
//	pocline++;
	if(pocline==479)
		pocline= 0;
		
	/* deallocate FFTW arrays and plans */
	fftw_destroy_plan( fft_img1 );
	fftw_destroy_plan( fft_img2 );
	fftw_destroy_plan( ifft_res );
	fftw_free( img1 );
	fftw_free( img2 );
	fftw_free( res );
}
