/*
 *  FIArtistInfo+Private.h
 *  radio3
 *
 *  Created by Daniel Rodríguez Troitiño on 08/03/09.
 *  Copyright 2009 Javier Quevedo and Daniel Rodríguez. All rights reserved.
 *
 */

#import "FIArtistInfo.h"
#import "TouchXML.h"

@interface FIArtistInfo (Private)

- (id)initWithXMLElement:(CXMLElement *)rootElement;

@end
