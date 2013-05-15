//
//  EmailComposer.m
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

#import "EmailComposer.h"
#import <MobileCoreServices/MobileCoreServices.h>

@interface EmailComposer ()

-(void) showEmailComposerWithParameters:(NSDictionary*)parameters;
-(void) returnWithCode:(int)code;
-(NSString *) getMimeTypeFromFileExtension:(NSString *)extension;

@end

@implementation EmailComposer
@synthesize webView;

// UNCOMMENT THIS METHOD if you want to use the plugin with versions of cordova < 2.2.0
- (void) showEmailComposer:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options {
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:
                                [options valueForKey:@"toRecipients"], @"toRecipients",
                                [options valueForKey:@"ccRecipients"], @"ccRecipients",
                                [options valueForKey:@"bccRecipients"], @"bccRecipients",
                                [options valueForKey:@"subject"], @"subject",
                                [options valueForKey:@"body"], @"body",
                                [options valueForKey:@"bIsHTML"], @"bIsHTML",
                                [options valueForKey:@"attachments"], @"attachments",
                                nil];
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 6)
    {
        [self showEmailComposerWithParameters:parameters];
    }
    else{
        UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"Not Supported" message:@"OS version 6 or above is required to avail email screenshot feature." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        [alert release];
        [self returnWithCode:RETURN_CODE_EMAIL_CANCELLED];
    }
}

// COMMENT THIS METHOD if you want to use the plugin with versions of cordova < 2.2.0
//- (void) showEmailComposer:(CDVInvokedUrlCommand*)command {
//    NSDictionary *parameters = [command.arguments objectAtIndex:0];
//    [self showEmailComposerWithParameters:parameters];
//}

-(void) showEmailComposerWithParameters:(NSDictionary*)parameters {
    
    MFMailComposeViewController *mailComposer = [[MFMailComposeViewController alloc] init];
    mailComposer.mailComposeDelegate = self;
    
    // set subject
    @try {
        NSString* subject = [parameters objectForKey:@"subject"];
        if (subject) {
            [mailComposer setSubject:subject];
        }
    }
    @catch (NSException *exception) {
        NSLog(@"EmailComposer - Cannot set subject; error: %@", exception);
    }
    
    // set body
    @try {
        NSString* body = [parameters objectForKey:@"body"];
        NSLog(@"body: %@",body);
        BOOL isHTML = [[parameters objectForKey:@"bIsHTML"] boolValue];
        if(body) {
            [mailComposer setMessageBody:body isHTML:isHTML];
        }
    }
    @catch (NSException *exception) {
        NSLog(@"EmailComposer - Cannot set body; error: %@", exception);
    }
    
    // Set recipients
    @try {
        NSArray* toRecipientsArray = [parameters objectForKey:@"toRecipients"];
        if(toRecipientsArray) {
            [mailComposer setToRecipients:toRecipientsArray];
        }
    }
    @catch (NSException *exception) {
        NSLog(@"EmailComposer - Cannot set TO recipients; error: %@", exception);
    }
    
    @try {
        NSArray* ccRecipientsArray = [parameters objectForKey:@"ccRecipients"];
        if(ccRecipientsArray) {
            [mailComposer setCcRecipients:ccRecipientsArray];
        }
    }
    @catch (NSException *exception) {
        NSLog(@"EmailComposer - Cannot set CC recipients; error: %@", exception);
    }
    
    @try {
        NSArray* bccRecipientsArray = [parameters objectForKey:@"bccRecipients"];
        if(bccRecipientsArray) {
            [mailComposer setBccRecipients:bccRecipientsArray];
        }
    }
    @catch (NSException *exception) {
        NSLog(@"EmailComposer - Cannot set BCC recipients; error: %@", exception);
    }
    
    
    @try {
        
        NSArray *attachmentPaths = [parameters objectForKey:@"attachments"];
        if (attachmentPaths) {
            for (NSString* path in attachmentPaths){
                if(path != @"")
                {
                    NSLog(@"attachmentPaths %@ ",attachmentPaths);
                    UIImage *image = [self getImage];
                    NSData* data = UIImagePNGRepresentation(image);
                    
                    //  NSLog(@"data: %@",data);
                    int counter = 1;
                    @try {
                        [mailComposer addAttachmentData:data mimeType:@"image/png" fileName:@"pic.png"];
                        counter++;
                    }
                    @catch (NSException *exception) {
                        //NSLog(@"Cannot attach file at path %@; error: %@", path, exception);
                    }
                }
            }
            
        }
        //        UIImage *image = [self getImage];
        //        NSData* data = UIImagePNGRepresentation(image);
        //        
        //        //  NSLog(@"data: %@",data);
        //        int counter = 1;
        //        @try {
        //             [mailComposer addAttachmentData:data mimeType:@"image/png" fileName:@"pic.png"];
        //            counter++;
        //        }
        //        @catch (NSException *exception) {
        //            //NSLog(@"Cannot attach file at path %@; error: %@", path, exception);
        //        }
        
        
    }
    @catch (NSException *exception) {
        ;
    }
    @finally {
        ;
    }
    
    if (mailComposer != nil) {
        [self.viewController presentModalViewController:mailComposer animated:YES];
    } else {
        [self returnWithCode:RETURN_CODE_EMAIL_NOTSENT];
    }
    [mailComposer release];
}

- (NSString*)saveImage:(UIImage*)image {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *savedImagePath = [documentsDirectory stringByAppendingPathComponent:@"savedImage.png"];
    NSData *imageData = UIImagePNGRepresentation(image);
    [imageData writeToFile:savedImagePath atomically:NO];
    return [NSString stringWithFormat:@"%@",savedImagePath];
}

- (UIImage*)getImage {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *getImagePath = [documentsDirectory stringByAppendingPathComponent:@"savedImage.png"];
    UIImage *img = [UIImage imageWithContentsOfFile:getImagePath];
    return img;
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
    
    [self writeJavascript:[NSString stringWithFormat:@"window.plugins.EmailComposer._didFinishWithResult(%d);", code]];
}

// Retrieve the mime type from the file extension
-(NSString *) getMimeTypeFromFileExtension:(NSString *)extension {
    if (!extension)
        return nil;
    CFStringRef pathExtension, type;
    // Get the UTI from the file's extension
    pathExtension = (CFStringRef)extension;
    type = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension, NULL);
    
    // Converting UTI to a mime type
    return (NSString *)UTTypeCopyPreferredTagWithClass(type, kUTTagClassMIMEType);
}

@end