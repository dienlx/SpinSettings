#import <QuartzCore/QuartzCore.h>
#import <Foundation/Foundation.h>

#define kBundlePath @"/Library/PreferenceBundles/SpinSettingsSettings.bundle"
#define SYS_VER_GREAT_OR_EQUAL(v) ([[[UIDevice currentDevice] systemVersion] compare:v options:64] != NSOrderedAscending)

static NSString * SSSpeed = @"";
static BOOL enableTweak = NO;

@interface UIImage ()
@property (assign,nonatomic) CGRect mediaImageSubRect;
-(CGRect)mediaImageSubRect;
@end


@interface SBIcon : NSObject
-(id)leafIdentifier;
@end

@interface SBIconView : UIView
@end

@implementation SBIconView
@end

@interface SBIconImageView : SBIconView
@end

@implementation SBIconImageView
@end

@interface SBLiveIconImageView : SBIconImageView
@end

@implementation SBLiveIconImageView
@end

@interface SBSettingsIconImageView : SBLiveIconImageView
-(id)initWithFrame:(CGRect)frame;
- (UIImageView*)dcImage;
- (void)setDcImage:(UIImageView*)value;
-(void)dealloc;
-(void)updateAnimatingState;
-(void)updateImageAnimated:(BOOL)animated;
- (void)rotateImageView;
-(void)setIsSpinning:(BOOL)value;
-(bool)isSpinning;
-(void)setDynamicFrame:(CGRect)frame;
-(void)setHasAdjusted:(BOOL)value;
-(bool)hasAdjusted;
@end

%subclass SBSettingsIconImageView : SBLiveIconImageView

%new - (UIImageView*)dcImage
{
	return objc_getAssociatedObject(self,@selector(dcImage));
}

%new - (void)setDcImage:(UIImageView*)value
{
	objc_setAssociatedObject(self,@selector(dcImage),value,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

%new - (BOOL)hasAdjusted
{
	return [(NSNumber*)objc_getAssociatedObject(self,@selector(hasAdjusted)) boolValue];
}

%new - (void)setHasAdjusted:(BOOL)value
{
	objc_setAssociatedObject(self,@selector(hasAdjusted),[NSNumber numberWithBool:value],OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

%new - (BOOL)isSpinning
{
	return [(NSNumber*)objc_getAssociatedObject(self,@selector(isSpinning)) boolValue];
}

%new - (void)setIsSpinning:(BOOL)value
{
	objc_setAssociatedObject(self,@selector(isSpinning),[NSNumber numberWithBool:value],OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

%new - (void)setDynamicFrame:(CGRect)frameVar
{
	NSLog(@"Resetting the frame: %@", NSStringFromCGRect(frameVar));
	if (self.dcImage && !self.hasAdjusted)
	{
		CGRect imageRect = CGRectMake(frameVar.origin.x,frameVar.origin.y,frameVar.size.width,frameVar.size.height);
		[self.dcImage setFrame:imageRect];
		self.hasAdjusted = 1;
	}
}

%new - (bool)isNumeric:(NSString*)checkText
{
	return [[NSScanner scannerWithString:checkText] scanFloat:NULL];
}

-(id)initWithFrame:(CGRect)frame
{
	id orig = %orig;

	if (orig != nil)
	{
		NSLog(@"Attaching the Core image to our settings icon");
		NSBundle *bundle = [[[NSBundle alloc] initWithPath:kBundlePath] autorelease];
		NSString *imagePath = [bundle pathForResource:@"Core" ofType:@"png"];
		UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
		self.dcImage = [[UIImageView alloc] initWithImage: image];
		CGRect iconRect = CGRectMake(0,0,0,0);
		[self.dcImage setFrame:iconRect];
		self.dcImage.clipsToBounds = YES;
		self.isSpinning = 1;
		self.hasAdjusted = 0;
		[self addSubview:self.dcImage];
	}
	return orig;
}

-(void)dealloc
{
	NSLog(@"SpinSettings deallocated");
	self.isSpinning = 0;
	self.hasAdjusted = 0;
	[self.dcImage release];
	%orig;
}

-(void)updateAnimatingState
{
	%orig;

	if (enableTweak)
		[self.dcImage setHidden:0];
	else
		[self.dcImage setHidden:1];

	if (self.hasAdjusted)
	{
		if(SYS_VER_GREAT_OR_EQUAL(@"8.0"))
		{
			[self.dcImage.layer removeAllAnimations];
		}
		[self rotateImageView];
	}
}

-(void)_activeDisplayChanged:(id)_activeDisplayChanged
{
	%orig;

	if (enableTweak)
		[self.dcImage setHidden:0];
	else
		[self.dcImage setHidden:1];

	if (self.hasAdjusted)
	{
		if(SYS_VER_GREAT_OR_EQUAL(@"8.0"))
		{
			[self.dcImage.layer removeAllAnimations];
		}
		[self rotateImageView];
	}
}

%new - (void)rotateImageView
{
	if ((long)self.isSpinning)
	{
		[UIView beginAnimations:nil context:NULL];
		[UIView animateWithDuration:10.0f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
			if ([self isNumeric:SSSpeed])
			{
				[self.dcImage setTransform:CGAffineTransformRotate(self.dcImage.transform,M_PI/((1.0/[SSSpeed doubleValue])*20))];
			}
			else
				[self.dcImage setTransform:CGAffineTransformRotate(self.dcImage.transform,M_PI/20)];
		}
		completion:^(BOOL finished){
			if (finished)
			{
				[self.dcImage.layer removeAllAnimations];
				[self rotateImageView];
			}
		}];
		[UIView commitAnimations];
	}
}
%end

%subclass SBSettingsApplicationIcon : SBApplicationIcon

-(Class)iconImageViewClassForLocation:(int)arg1
{
	return %c(SBSettingsIconImageView);
}

%end

%hook SBIcon

-(Class)iconImageViewClassForLocation:(int)arg1
{
	Class orig = %orig;
	return orig;
}

%end

%hook SBApplication

-(Class)iconClass
{
	Class orig = %orig;
	NSString * identifier = MSHookIvar<NSString*>(self,"_bundleIdentifier");

	if([identifier isEqualToString:@"com.apple.Preferences"]){
		return %c(SBSettingsApplicationIcon);
		//If we just return orig here in order to disable the tweak, we would have to respring for any changes to be applied.
		//Thus hiding the view through functions in the SBSettingsIconImageView class is an alternative that does not require a respring.
	}
	else
		return orig;
}

%end

%hook SBIconView

-(void)_setIcon:(id)icon animated:(BOOL)animated
{
	%orig;

	if ([[icon leafIdentifier] isEqualToString:@"com.apple.Preferences"])
	{
		NSLog(@"_setIcon for Preferences");
		SBSettingsIconImageView * img = MSHookIvar<SBSettingsIconImageView*>(self,"_iconImageView");

		if([img isKindOfClass:%c(SBSettingsIconImageView)])
		{
			NSLog(@"Our image ivar is of the correct class.");
			[img setDynamicFrame:[img bounds]];
			if(SYS_VER_GREAT_OR_EQUAL(@"8.0"))
		 	{
		 		[img.layer removeAllAnimations];
		 	}
			[img rotateImageView];
		}	
	}
}

%end


// "Hey, why do you have different code for iOS7 and iOS8 preferences?"
// "Because I knew what worked for iOS7 and I knew what worked for iOS8. I needed to push out an update to fix a conflict with 'Spin'
// and thus couldn't test in time the code to see if the changes for iOS8 would also work for iOS7. Will be sorted out in the next update"
static void loadPrefs() 
{
    if(SYS_VER_GREAT_OR_EQUAL(@"8.0"))
    {
    	NSLog(@"Loading SpinSettings prefs for iOS8");
	    CFPreferencesAppSynchronize(CFSTR("com.joshdoctors.spinsettings"));

	    enableTweak = !CFPreferencesCopyAppValue(CFSTR("enableTweak"), CFSTR("com.joshdoctors.spinsettings")) ? NO : [(id)CFPreferencesCopyAppValue(CFSTR("enableTweak"), CFSTR("com.joshdoctors.spinsettings")) boolValue];
	    if (enableTweak) {
	        NSLog(@"[SpinSettings] We are enabled");
	    } else {
	        NSLog(@"[SpinSettings] We are NOT enabled");
	    }

	    SSSpeed = (NSString*)CFPreferencesCopyAppValue(CFSTR("SSSpeed"), CFSTR("com.joshdoctors.spinsettings")) ?: @"1.0";
	    [SSSpeed retain];
	    NSLog(@"SSSpeed: %@",SSSpeed);
    }
    else
    {
    	NSLog(@"Loading SpinSettings prefs for iOS7");
	    NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:@"/var/mobile/Library/Preferences/com.joshdoctors.spinsettings.plist"];

	    if (prefs)
	    {
	        enableTweak = ([prefs objectForKey:@"enableTweak"] ? [[prefs objectForKey:@"enableTweak"] boolValue] : enableTweak);

	        if (enableTweak) {
	        	NSLog(@"[SpinSettings] We are enabled");
		    } else {
		        NSLog(@"[SpinSettings] We are NOT enabled");
		    }

	        SSSpeed = ( [prefs objectForKey:@"SSSpeed"] ? [prefs objectForKey:@"SSSpeed"] : SSSpeed );
	        [SSSpeed retain];
	    }
	    [prefs release];
    }
}

%ctor
{
	if(SYS_VER_GREAT_OR_EQUAL(@"8.0"))
	{
		NSLog(@"Loading SpinSettings for iOS8");
		CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                    NULL,
                                    (CFNotificationCallback)loadPrefs,
                                    CFSTR("com.joshdoctors.spinsettings/settingschanged"),
                                    NULL,
                                    CFNotificationSuspensionBehaviorDeliverImmediately);
    	loadPrefs();
	}
	else
	{
		NSLog(@"Loading SpinSettings for iOS7");
		CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)loadPrefs, CFSTR("com.joshdoctors.spinsettings/settingschanged"), NULL, CFNotificationSuspensionBehaviorCoalesce);
	    loadPrefs();
	}
}