//
//  Screenshot.m
//
//  Version 1.1
//
//  Created by iGATE in 2013.
//

#define RETURN_CODE_EMAIL_CANCELLED 0
#define RETURN_CODE_EMAIL_SAVED 1
#define RETURN_CODE_EMAIL_SENT 2
#define RETURN_CODE_EMAIL_FAILED 3
#define RETURN_CODE_EMAIL_NOTSENT 4

#import "Screenshot.h"
#import <MobileCoreServices/MobileCoreServices.h>
#include <QuartzCore/QuartzCore.h>

@interface Screenshot ()

-(void) showScreenshotWithParameters:(NSDictionary*)parameters;
-(void) returnWithCode:(int)code;

@end

@implementation Screenshot
@synthesize webView;

// UNCOMMENT THIS METHOD if you want to use the plugin with versions of cordova < 2.2.0
- (void) showScreenshot:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options {
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:
                                [options valueForKey:@"toRecipients"], @"toRecipients",
                                [options valueForKey:@"ccRecipients"], @"ccRecipients",
                                [options valueForKey:@"bccRecipients"], @"bccRecipients",
                                [options valueForKey:@"subject"], @"subject",
                                [options valueForKey:@"body"], @"body",
                                [options valueForKey:@"bIsHTML"], @"bIsHTML",
                                [options valueForKey:@"attachments"], @"attachments",
                                nil];
    NSLog(@"in showScreenshot");
    
    [self showScreenshotWithParameters:parameters];
}

// COMMENT THIS METHOD if you want to use the plugin with versions of cordova < 2.2.0
//- (void) showScreenshot:(CDVInvokedUrlCommand*)command {
//    NSDictionary *parameters = [command.arguments objectAtIndex:0];
//    [self showScreenshotWithParameters:parameters];
//}

-(void) showScreenshotWithParameters:(NSDictionary*)parameters {
    
    
    @try {
        CGRect imageRect;
        CGRect screenRect = [[UIScreen mainScreen] bounds];
        
        // statusBarOrientation is more reliable than UIDevice.orientation
        UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
        
        if (orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight) {
            // landscape check
            imageRect = CGRectMake(0, 0, CGRectGetHeight(screenRect), CGRectGetWidth(screenRect));
        } else {
            // portrait check
            imageRect = CGRectMake(0, 0, CGRectGetWidth(screenRect), CGRectGetHeight(screenRect));
        }
        
        // Adds support for Retina Display. Code reverts back to original if iOs 4 not detected.
        if (NULL != UIGraphicsBeginImageContextWithOptions)
            UIGraphicsBeginImageContextWithOptions(imageRect.size, NO, 0);
        else
            UIGraphicsBeginImageContext(imageRect.size);
        
        
        CGContextRef ctx = UIGraphicsGetCurrentContext();
        [[UIColor clearColor] set];
        CGContextTranslateCTM(ctx, 0, 0);
        CGContextFillRect(ctx, imageRect);
        
        
        [webView.layer renderInContext:ctx];
        
        UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
        // UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
        [self saveImage:image];
        UIGraphicsEndImageContext();
    }
    @catch (NSException *exception) {
        ;
    }
    @finally {
        [self returnWithCode:RETURN_CODE_EMAIL_NOTSENT];
    }
    
}

- (NSString*)saveImage:(UIImage*)image {
    NSLog(@"Saving");
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory,NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *savedImagePath = [documentsDirectory stringByAppendingPathComponent:@"savedImage.png"];
    NSData *imageData = UIImagePNGRepresentation(image);
    UIImagePNGRepresentation(image);
    [imageData writeToFile:savedImagePath atomically:NO];
    
    return [NSString stringWithFormat:@"%@",savedImagePath];
}


// Dismisses the email composition interface when users tap Cancel or Send.
// Proceeds to update the message field with the result of the operation.
- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
    // Notifies users about errors associated with the interface
	int webviewResult = 0;
    
    switch (result) {
        case MFMailComposeResultCancelled:
			webviewResult = RETURN_CODE_EMAIL_CANCELLED;
            break;
        case MFMailComposeResultSaved:
			webviewResult = RETURN_CODE_EMAIL_SAVED;
            break;
        case MFMailComposeResultSent:
			webviewResult =RETURN_CODE_EMAIL_SENT;
            break;
        case MFMailComposeResultFailed:
            webviewResult = RETURN_CODE_EMAIL_FAILED;
            break;
        default:
			webviewResult = RETURN_CODE_EMAIL_NOTSENT;
            break;
    }
	
    [controller dismissModalViewControllerAnimated:YES];
    [self returnWithCode:webviewResult];
}

// Call the callback with the specified code
-(void) returnWithCode:(int)code {
    
    [self writeJavascript:[NSString stringWithFormat:@"window.plugins.Screenshot._didFinishWithResult(%d);", code]];
}

@end