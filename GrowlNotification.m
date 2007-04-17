/****************************************************************************
 *  Copyright 2006 Aaron Rolett                                             *
 *  arolett@mail.rochester.edu                                              *
 *                                                                          *
 *  This file is part of PandoraBoy.                                        *
 *                                                                          *
 *  PandoraBoy is free software; you can redistribute it and/or modify      *
 *  it under the terms of the GNU General Public License as published by    * 
 *  the Free Software Foundation; either version 2 of the License, or       *
 *  (at your option) any later version.                                     *
 *                                                                          *
 *  PandoraBoy is distributed in the hope that it will be useful,           *
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of          *
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the           * 
 *  GNU General Public License for more details.                            *
 *                                                                          *
 *  You should have received a copy of the GNU General Public License       * 
 *  along with PandoraBoy; if not, write to the Free Software Foundation,   *
 *  Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA          *
 ***************************************************************************/

#import "GrowlNotification.h"
#import "Playlist.h"

NSString *PBGrowlNotificationSongPlaying = @"Song Playing";
NSString *PBGrowlNotificationSongPaused  = @"Song Paused";
NSString *PBGrowlNotificationSongThumbed = @"Song Thumbed";
NSString *PBGrowlNotificationError       = @"Error";

@implementation GrowlNotification

#pragma public interface

- (id) init 
{
	if ( self = [super init] ) {
        [GrowlApplicationBridge setGrowlDelegate: self];
        [[NSDistributedNotificationCenter defaultCenter] addObserver:self
                                                            selector:@selector(playerInfoChanged:)
                                                                name:PBPlayerInfoNotificationName
                                                              object:nil
                                                  suspensionBehavior:NSNotificationSuspensionBehaviorDeliverImmediately];
        thumbsUpImage = [[NSImage alloc] initWithContentsOfFile:
            [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/thumbs_up.png"]];
        thumbsDownImage = [[NSImage alloc] initWithContentsOfFile:
            [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/thumbs_down.png"]];
	}
	
	return self;
}

- (void) dealloc 
{
    [[NSDistributedNotificationCenter defaultCenter] removeObserver:self];
    [thumbsUpImage release];
    [thumbsDownImage release];
	[super dealloc];
}

- (void) playerInfoChanged:(NSNotification*)aNotification {
    Track *track = [[Playlist sharedPlaylist] currentTrack];
    
    int playerState = [[[aNotification userInfo] valueForKey:PBPlayerInfoPlayerStateKey] intValue];
    NSString *notificationName;;
    NSString *title;
    if( playerState == PBPlayerStatePlaying ) {
        notificationName = PBGrowlNotificationSongPlaying;
        title = [track name];
    }
    else if( playerState == PBPlayerStatePaused ) {
        notificationName = PBGrowlNotificationSongPaused;
        title = [[track name] stringByAppendingFormat:@" (%@)", NSLocalizedString(@"paused", @"")];
    }
    else {
        NSLog(@"BUG:playerInfoChanged called with illegal state: %@", playerState);
    }

    NSImage *artwork = [[NSImage alloc] initWithData:[track artwork]];
    if( [track rating] == PBThumbsUpRating ) {
        [artwork lockFocus];
        [thumbsUpImage dissolveToPoint:NSMakePoint(50, 10) fraction:0.65];
        [artwork unlockFocus];
    }
    
    [GrowlApplicationBridge notifyWithTitle:title
                                description:[NSString stringWithFormat:@"%@: %@\n%@: %@", 
                                    NSLocalizedString(@"by", @""), [track artist],
                                    NSLocalizedString(@"on", @""), [track album], nil]
                           notificationName:notificationName
                                   iconData:[artwork TIFFRepresentation]
                                   priority:0
                                   isSticky:false
                               clickContext:nil];
    [artwork release];
}

- (void) pandoraLikeSong
{
    Track *track = [[Playlist sharedPlaylist] currentTrack];
    
    [GrowlApplicationBridge
        notifyWithTitle:[track name]
            description:[track artist]
       notificationName:PBGrowlNotificationSongThumbed
               iconData:[thumbsUpImage TIFFRepresentation]
               priority:0
               isSticky:false
           clickContext:nil];
}

- (void) pandoraDislikeSong
{
    Track *track = [[Playlist sharedPlaylist] currentTrack];
    
    [GrowlApplicationBridge
        notifyWithTitle:[track name]
            description:[track artist]
       notificationName:PBGrowlNotificationSongThumbed
               iconData:[thumbsDownImage TIFFRepresentation]
               priority:0
               isSticky:false
           clickContext:nil];
}

// delegate methods for GrowlApplicationBridge
- (NSDictionary *) registrationDictionaryForGrowl {
  NSArray *notifications = [NSArray arrayWithObjects:
				    PBGrowlNotificationSongPlaying,
                    PBGrowlNotificationSongPaused,
                    PBGrowlNotificationSongThumbed,
				    nil];

  NSDictionary *regDict = [NSDictionary dictionaryWithObjectsAndKeys:
                    @"PandoraBoy", GROWL_APP_NAME,
                    notifications, GROWL_NOTIFICATIONS_ALL,
					notifications, GROWL_NOTIFICATIONS_DEFAULT,
					nil];
  return regDict;
}

@end
