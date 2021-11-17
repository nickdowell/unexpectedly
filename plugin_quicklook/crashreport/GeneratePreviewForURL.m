/*
 Copyright (c) 2021, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import <Cocoa/Cocoa.h>

#include <CoreServices/CoreServices.h>
#include <QuickLook/QuickLook.h>

#import "CUICrashLogsProvider.h"

#import "CUIIPSTransform.h"
#import "CUICrashDataTransform.h"

#import "CUIThemesManager.h"

#import "CUIApplicationPreferences+Themes.h"
#import "CUIThemeItemsGroup+UI.h"

extern NSString * const CUITextModeDisplaySettingsVisibleSectionKey;

extern NSString * const CUITextModeDisplaySettingsVisibleStackFrameComponentsKey;


OSStatus GeneratePreviewForURL(void *thisInterface, QLPreviewRequestRef preview, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options);

void CancelPreviewGeneration(void *thisInterface, QLPreviewRequestRef preview);

/* -----------------------------------------------------------------------------
   Generate a preview for file

   This function's job is to create preview for designated file
   ----------------------------------------------------------------------------- */

OSStatus GeneratePreviewForURL(void *thisInterface, QLPreviewRequestRef preview, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options)
{
    @autoreleasepool
    {
        CUIRawCrashLog * tCrashLog=[[CUICrashLogsProvider defaultProvider] crashLogWithContentsOfFile:((__bridge NSURL *)url).path error:NULL];
        
        if (tCrashLog==nil)
            return noErr;
        
        [tCrashLog finalizeParsing];
        
        CUITextModeDisplaySettings * tDisplaySettings=[CUITextModeDisplaySettings new];
        
        tDisplaySettings.visibleSections=CUIDocumentAllSections;
        tDisplaySettings.visibleStackFrameComponents=CUIStackFrameAllComponents;
        
        CUIDataTransform * tDataTransform=nil;
        
        if (tCrashLog.ipsReport!=nil)
        {
            tDataTransform=[CUIIPSTransform new];
            tDataTransform.input=tCrashLog.ipsReport;
        }
        else
        {
            tDataTransform=[CUICrashDataTransform new];
            tDataTransform.input=tCrashLog;
        }
        
        tDataTransform.displaySettings=tDisplaySettings;
        tDataTransform.fontSizeDelta=0;
        tDataTransform.hyperlinksStyle=CUIHyperlinksNone;
        
        if ([tDataTransform transform]==NO)
        {
            // A COMPLETER
        }
        
        NSAttributedString * tAttributedString=tDataTransform.output;
        
        CUIThemeItemsGroup * tGroup=[[CUIThemesManager sharedManager].currentTheme itemsGroupWithIdentifier:[CUIApplicationPreferences groupIdentifierForPresentationMode:CUIPresentationModeText]];
        
        NSColor * tBackgroundColor=[tGroup attributesForItem:CUIThemeItemBackground].color;
        
        NSData *tRTFData = [tAttributedString dataFromRange:NSMakeRange(0, tAttributedString.length)
                                        documentAttributes:@{
                                                             NSDocumentTypeDocumentAttribute:NSRTFTextDocumentType,
                                                             NSBackgroundColorDocumentAttribute:tBackgroundColor
                                                             }
                                                     error:NULL];
        
        if (tRTFData==nil)
            return noErr;
        
        QLPreviewRequestSetDataRepresentation(preview,
                                              (__bridge CFDataRef)tRTFData,
                                              kUTTypeRTF,
                                              NULL);
    }
    
    return noErr;
}

void CancelPreviewGeneration(void *thisInterface, QLPreviewRequestRef preview)
{
    // Implement only if supported
}
