// Key Main 3.0.0
//
// Issues:
//
//
//
//
//
// Fixes
//=========
//
// 2.0.2
// Added submenu for wind
// Added contol over owner only or any wind
// Default Dollie name to first name of display name
// Added function to configure when reset or ownership changed
// Fixed incorect values in dollydead/alive messages
//
// Added function Float2String to fix percentage display
// Updated status message wind remaining display
//
// To be done
//
//
//
//
// Settings
//
string gDeviceName="Dollie key";
integer gCommandChannel=99;
string gWearerPrefix="";
string gMenuCommand="";
string gStatusMessage="";
integer gListenHandle;
integer gListenHandleCommandChannel;
integer gListenHandleMenu;
key gOwner; //="76d06c47-7750-47a7-82a1-471810ef64b3";
string gOwnerName;
integer gMenuChannel;
integer gSensorChannel;
integer gHasOwner=TRUE;
key gToucher;
key gWearer;
string gWearerName="";
integer gMenuExpireTime;
integer gRestrictionLevel;
float gCurrentWindLevel = 100;
integer gRLVCommandMessage=78910;
integer gTimeKeeperCommandMsg=123456;
integer gStatusUpdateMessage=11223344;
integer gRenamerCommandMessage=99887766;
integer gEmailCommandMessage=286491;
integer gExternalMessageChannel=223344;
integer gLocked=FALSE;
integer gFrozen=FALSE;
integer gDollieDead=FALSE;
integer gDollieBroken=FALSE;
string gDollieName="Dollie";
integer gRenamed=FALSE;
string gMenuLevel;
integer gAnyWind=TRUE;
integer gBlind=TRUE;
integer gIMBlock=TRUE;
integer gEmoteBlock=TRUE;
integer gCanCarry=TRUE;
integer gCanBreak=TRUE;
integer gSecureBlocks=FALSE;
float gDecayRateMultiplier=1;
integer gGetNameChannel;
integer gGetEmailChannel;
integer gGetPwdChannel;
string gOwnerEmail="";
string gEmailPassword="";
integer gEnableEmail=FALSE;


//===============================================
//
// Functions
//
//===============================================
//
string GetFirstDisplayName (key lID)
{
	// Gets the first name from the display name specified
	string lDisplayName=llGetDisplayName(lID);
	integer lFirstSpace=llSubStringIndex(lDisplayName, " ");
	string lFirstName=llGetSubString(lDisplayName, 0, (lFirstSpace-1));
	return lFirstName;
}

string Float2String ( float num, integer places, integer rnd)
{
	//allows string output of a float in a tidy text format
	//rnd (rounding) should be set to TRUE for rounding, FALSE for no rounding

	if (rnd) {
		float f = llPow( 10.0, places );
		integer i = llRound(llFabs(num) * f);
		string s = "00000" + (string)i; // number of 0s is (value of max places - 1 )
		if(num < 0.0)
			return "-" + (string)( (integer)(i / f) ) + "." + llGetSubString( s, -places, -1);
		return (string)( (integer)(i / f) ) + "." + llGetSubString( s, -places, -1);
	}
	if (!places)
		return (string)((integer)num );
	if ( (places = (places - 7 - (places < 1) ) ) & 0x80000000)
		return llGetSubString((string)num, 0, places);
	return (string)num;
}

//===============================================
//
// Procedures
//
//===============================================
initialise ()
{
	llOwnerSay("@clear");
	gWearer=llGetOwner();
	gWearerName=llGetDisplayName(gWearer);
	gOwner=gWearer;
	gDollieName = GetFirstDisplayName(gWearer) + " Dollie";
	string lLegacyName=llKey2Name(gWearer);
	string lFirstInitial=llGetSubString(lLegacyName,0,0);
	integer lIndex=llSubStringIndex(lLegacyName, " ") +1;
	string lSecondInitial=llGetSubString(lLegacyName,lIndex,lIndex);
	gWearerPrefix=llToLower((lFirstInitial + lSecondInitial));
	//llWhisper (0,"Menu command is /" + (string)gCommandChannel + " " + gWearerPrefix + "menu");
	gMenuCommand=gWearerPrefix + "menu";
}
generateStatusMessage()
{

	if (gHasOwner==FALSE)
	{
		gStatusMessage = "\n\n" + gWearerName + " is not owned";
	}
	else if (gHasOwner==TRUE)
	{
		gStatusMessage = "\n\n" + gWearerName + " is owned by " + gOwnerName;
	}
	if (gRenamed==TRUE) gStatusMessage+="\nDollie name is: " +gDollieName;
	if (gToucher==gWearer)
	{
		if (gCurrentWindLevel > 0)
		{
			gStatusMessage += "\n\nKey is wound";
			//comment out in final version
			//gStatusMessage +=  "\n\nCurrent wind level is: " + Float2String(gCurrentWindLevel,1,TRUE) + "%";
		}
		else
		{
			gStatusMessage += "\n\nKey is unwound";
		}
	}
	else
	{
		gStatusMessage += "\n\nCurrent wind level is: " + Float2String(gCurrentWindLevel,1,TRUE) + "%";
		if (gDollieBroken==TRUE) gStatusMessage += "\n\nDollie is currently broken.";
	}
}

displayMainMenu (key ID)
{
	gMenuLevel="main";
	generateStatusMessage();
	if (gListenHandleMenu !=0) llListenRemove(gListenHandleMenu);
	if (ID==gOwner || gHasOwner==FALSE || ID==gWearer || ID!=gWearer)
	{
		gMenuChannel = (integer)(llFrand(-1000000000.0) - 1000000000.0);
		list lMenuButtons=[];
		if ((gHasOwner==FALSE) && (ID==gWearer))
		{
			lMenuButtons=[" - "];
			lMenuButtons+=["choose owner"];
			lMenuButtons+=[" - "];
		}
		if ((gHasOwner==TRUE) && (ID==gOwner))
		{
			if (gFrozen==FALSE) lMenuButtons=["wind", "unwind", "freeze"];
			else lMenuButtons=["wind", "unwind", "unfreeze"];
			if (gRenamed==TRUE) lMenuButtons+=["no rename", "rem owner", "set name"];
			else lMenuButtons+=["rename", "rem owner", "set name"];
			if (gLocked==FALSE) lMenuButtons+=["lock", "settings", "configure"];
			else lMenuButtons+=["unlock", "settings", "configure"];
			if (gDollieBroken==TRUE) lMenuButtons += ["repair dollie"];
			else lMenuButtons += [" - "];
		}
		else if ((gHasOwner==TRUE) && (gToucher != gWearer))
		{
			if (gFrozen==FALSE) lMenuButtons=["freeze"];
			else lMenuButtons=["unfreeze"];
			if ((gAnyWind==TRUE) || (gDollieDead==TRUE))lMenuButtons += ["wind"," - "," - "];
		}
		else if ((gHasOwner==TRUE) && (ID==gWearer)) lMenuButtons=[" - ", " - ", " - "];
		llDialog(ID, gStatusMessage, lMenuButtons, gMenuChannel);
		gListenHandleMenu = llListen( gMenuChannel, "", ID, "");
		gMenuExpireTime=llGetUnixTime() + 120;
		return;
	}
}

displayWindMenu (key ID)
{
	gMenuLevel="wind";
	generateStatusMessage();
	list lMenuButtons=[];
	if (gListenHandleMenu !=0) llListenRemove(gListenHandleMenu);
	if (ID==gOwner || gHasOwner==FALSE || ID!=gWearer)
	{
		gMenuChannel = (integer)(llFrand(-1000000000.0) - 1000000000.0);

		if (gAnyWind==TRUE) gStatusMessage += "\nAnyone can wind the dollie.";
		else gStatusMessage += "\nOny you can wind dollie unless she is unwound.";
		if ((gHasOwner==TRUE) && (ID==gOwner))
		{
			if (gAnyWind==TRUE) lMenuButtons=["back", "only me", " - "];
			else lMenuButtons=["back", "any wind", " - "];
		}
		if (gDollieDead==FALSE)
		{
			lMenuButtons += ["15%", "25%", "50%"];
			lMenuButtons += ["1%", "5%", "10%"];
		}
		else lMenuButtons += [" - ", "help dollie", " - "];
	}
	llDialog(ID, gStatusMessage, lMenuButtons, gMenuChannel);
	gListenHandleMenu = llListen( gMenuChannel, "", ID, "");
	gMenuExpireTime=llGetUnixTime() + 120;
	return;

}

displaySettingsMenu (key ID)
{
	gMenuLevel="settings";
	generateStatusMessage();
	list lMenuButtons=[];
	if (gListenHandleMenu !=0) llListenRemove(gListenHandleMenu);
	if (ID==gOwner || gHasOwner==FALSE || ID!=gWearer)
	{
		gMenuChannel = (integer)(llFrand(-1000000000.0) - 1000000000.0);

		//if (gAnyWind==TRUE) gStatusMessage += "\nAnyone can wind the dollie.";
		//else gStatusMessage += "\nOny you can wind dollie unless she is unwound.";
		if ((gHasOwner==TRUE) && (ID==gOwner))
		{
			lMenuButtons=[" - ", "back", " - "];
			lMenuButtons+=["slow", "normal", "fast"];
			if (gIMBlock==TRUE) lMenuButtons += "allow IM";
			else lMenuButtons+="block IM";
			if (gBlind==TRUE) lMenuButtons += "no blind";
			else lMenuButtons+="blind";
			if (gEmoteBlock==TRUE) lMenuButtons += "allow emote";
			else lMenuButtons+="block emote";
			if (gCanCarry==TRUE) lMenuButtons += "no carry";
			else lMenuButtons+="allow carry";
			if (gCanBreak==TRUE) lMenuButtons += "no break";
			else lMenuButtons+="allow break";
			if (gSecureBlocks==TRUE) lMenuButtons += "not secure";
			else lMenuButtons+="secure";
			//lMenuButtons+=["can break", "can carry", "secure"];
			//lMenuButtons+=["blind", "blk IM", "blk emote"];

		}

	}
	llDialog(ID, gStatusMessage, lMenuButtons, gMenuChannel);
	gListenHandleMenu = llListen( gMenuChannel, "", ID, "");
	gMenuExpireTime=llGetUnixTime() + 120;
	return;

}
displayConfigureMenu (key ID)
{
	gMenuLevel="configure";
	generateStatusMessage();
	list lMenuButtons=[];
	if (gListenHandleMenu !=0) llListenRemove(gListenHandleMenu);
	if (ID==gOwner || gHasOwner==FALSE || ID!=gWearer)
	{
		gMenuChannel = (integer)(llFrand(-1000000000.0) - 1000000000.0);

		if (gOwnerEmail == "") gStatusMessage += "\nEmail address hs not been set.";
		else gStatusMessage += "\nCurrent email address is: " + gOwnerEmail;
		if (gEmailPassword=="") gStatusMessage += "\nPassword has not been set.";
		else gStatusMessage += "\nPassword has been set";
		lMenuButtons=[" - ", "back", " - "];
		if (gEnableEmail==TRUE)
		{
			lMenuButtons+=["no email", "set addr", "set pwd"];
		}
		else
		{
			lMenuButtons += ["email on", "set addr", "set pwd"];
		}
	}
	llDialog(ID, gStatusMessage, lMenuButtons, gMenuChannel);
	gListenHandleMenu = llListen( gMenuChannel, "", ID, "");
	gMenuExpireTime=llGetUnixTime() + 120;
	return;

}
default
{
	state_entry()
	{
		initialise ();
		// gListenHandleCommandChannel = llListen( gCommandChannel, "", "", "");
		llSetTimerEvent(30);
	}

	touch_start(integer total_number)
	{
		// get the position of the avatar touching this prim
        vector lPos = llDetectedPos(0);
        // compute how far away they are
        float lDist = llVecDist(lPos, llGetPos() );
		if (lDist <= 3.0)
		{
			gToucher=llDetectedKey(0);
			displayMainMenu(gToucher);
		}
		else llInstantMessage(llDetectedKey(0), "You are too far away to touch " + GetFirstDisplayName(llGetOwner()) + "'s key.");
		return;
	}
	listen(integer lChannel, string lName, key lID, string lMessage)
	{
		if (lChannel==gCommandChannel)
		{
			if (llToLower(lMessage)==llToLower(gMenuCommand))
			{
				displayMainMenu(lID);
				return;
			}
		}

		if (lChannel==gMenuChannel)
		{
			llListenRemove(gListenHandleMenu);
			if (lMessage=="choose owner")
			{
				llOwnerSay("Looking for possible Owners around you");
				llSensor  ("", NULL_KEY, AGENT, 30.0, PI);
			}
			else if (lMessage=="rem owner")
			{
				llInstantMessage(gOwner, "You have been removed as the owner of "+ llGetDisplayName(gWearer) + "'s key");
				llMessageLinked(LINK_SET, gRLVCommandMessage, "remove owner", NULL_KEY);
				gOwner=NULL_KEY;
				gHasOwner=FALSE;
				displayMainMenu(lID);
				return;
			}
			else if (lMessage=="lock")
			{
				gLocked=TRUE;
				llMessageLinked(LINK_SET, gRLVCommandMessage, "lock", NULL_KEY);
				llWhisper(0, llGetDisplayName(gOwner) + " locks " + llGetDisplayName(gWearer) + "'s key");
				displayMainMenu(lID);
				return;
			}
			else if (lMessage=="unlock")
			{
				gLocked=FALSE;
				llMessageLinked(LINK_SET, gRLVCommandMessage, "unlock", NULL_KEY);
				llWhisper(0, llGetDisplayName(gOwner) + " unlocks " + llGetDisplayName(gWearer) + "'s key");
				displayMainMenu(lID);
				return;
			}
			else if (lMessage=="wind")
			{
				displayWindMenu(lID);
				return;
			}
			else if (lMessage=="settings")
			{
				displaySettingsMenu(lID);
				return;
			}
			else if (lMessage=="configure")
			{
				displayConfigureMenu(lID);
				return;
			}

			else if (lMessage=="unwind")
			{
				llMessageLinked(LINK_SET, gTimeKeeperCommandMsg, "unwind", lID);
				gCurrentWindLevel=0;
				displayMainMenu(lID);
				return;
			}
			else if (lMessage=="freeze")
			{
				llWhisper(0, llGetDisplayName(lID) + " freezes " + llGetDisplayName(gWearer) + " in place for up to 5 minutes");
				gFrozen=TRUE;
				llMessageLinked(LINK_SET, gTimeKeeperCommandMsg, "freeze", lID);
				displayMainMenu(lID);
				return;
			}
			else if (lMessage=="unfreeze")
			{
				llWhisper(0, llGetDisplayName(lID) + " unfreezes " + llGetDisplayName(gWearer) );
				gFrozen=FALSE;
				llMessageLinked(LINK_SET, gTimeKeeperCommandMsg, "unfreeze", lID);
				displayMainMenu(lID);
				return;
			}
			else if (lMessage=="rename")
			{
				gRenamed=TRUE;
				llMessageLinked(LINK_SET, gRenamerCommandMessage, "set name", gDollieName);
				llMessageLinked(LINK_SET, gRenamerCommandMessage, "rename", lID);
				displayMainMenu(lID);
				return;
			}
			else if (lMessage=="no rename")
			{
				gRenamed=FALSE;
				llMessageLinked(LINK_SET, gRenamerCommandMessage, "no rename", lID);
				displayMainMenu(lID);
				return;
			}
			else if (lMessage=="set name")
			{
				gGetNameChannel=(integer)(llFrand(-1000000000.0) - 1000000000.0);
				gListenHandle = llListen(gGetNameChannel, "", "", "");
				llTextBox(lID, "Please enter new name for dollie", gGetNameChannel);
			}
			if (gMenuLevel=="wind")
			{
				if (lMessage=="1%")
				{
					llMessageLinked(LINK_SET, gTimeKeeperCommandMsg, "1", lID);
					llWhisper(gExternalMessageChannel, (string)lID+"|wind1");
					gCurrentWindLevel+=1;
					displayWindMenu(lID);
					return;
				}
				else if (lMessage=="5%")
				{
					llMessageLinked(LINK_SET, gTimeKeeperCommandMsg, "5", lID);
					llWhisper(gExternalMessageChannel, (string)lID+"|wind5");
					gCurrentWindLevel+=5;
					displayWindMenu(lID);
					return;
				}
				else if (lMessage=="10%")
				{
					llMessageLinked(LINK_SET, gTimeKeeperCommandMsg, "10", lID);
					llWhisper(gExternalMessageChannel, (string)lID+"|wind10");
					gCurrentWindLevel+=10;
					displayWindMenu(lID);
					return;
				}
				else if (lMessage=="15%")
				{
					llMessageLinked(LINK_SET, gTimeKeeperCommandMsg, "15", lID);
					llWhisper(gExternalMessageChannel, (string)lID+"|wind15");
					gCurrentWindLevel+=15;
					displayWindMenu(lID);
					return;
				}
				else if (lMessage=="25%")
				{
					llMessageLinked(LINK_SET, gTimeKeeperCommandMsg, "25", lID);
					llWhisper(gExternalMessageChannel, (string)lID+"|wind25");
					gCurrentWindLevel+=10;
					displayWindMenu(lID);
					return;
				}
				else if (lMessage=="50%")
				{
					llMessageLinked(LINK_SET, gTimeKeeperCommandMsg, "50", lID);
					llWhisper(gExternalMessageChannel, (string)lID+"|wind50");
					gCurrentWindLevel+=10;
					displayWindMenu(lID);
					return;
				}
				else if (lMessage=="only me")
				{
					gAnyWind=FALSE;
					displayWindMenu(lID);
					return;
				}
				else if (lMessage=="any wind")
				{
					gAnyWind=TRUE;
					displayWindMenu(lID);
					return;
				}
				else if (lMessage=="help dollie")
				{
					llMessageLinked(LINK_SET, gTimeKeeperCommandMsg, "random", lID);
					gDollieDead=FALSE;
					//gCurrentWindLevel+=10;
					llSleep(0.5);
					displayMainMenu(lID);
					return;
				}
				else if (lMessage=="back")
				{
					displayMainMenu(lID);
					return;
				}
			}
			if (gMenuLevel=="settings")
			{
				if (lMessage=="back")
				{
					displayMainMenu(lID);
					return;
				}
				else if (lMessage=="slow")
				{
					gDecayRateMultiplier=0.5;
					llMessageLinked(LINK_SET, gTimeKeeperCommandMsg, "DecayRateMultiplier", (string)gDecayRateMultiplier);

				}
				else if (lMessage=="normal")
				{
					gDecayRateMultiplier=1.0;
					llMessageLinked(LINK_SET, gTimeKeeperCommandMsg, "DecayRateMultiplier", (string)gDecayRateMultiplier);
				}
				else if (lMessage=="fast")
				{
					gDecayRateMultiplier=4.0;
					llMessageLinked(LINK_SET, gTimeKeeperCommandMsg, "DecayRateMultiplier", (string)gDecayRateMultiplier);
				}
				else if (lMessage=="allow IM")
				{
					gIMBlock=FALSE;
					llMessageLinked(LINK_SET, gRLVCommandMessage, "allowIM", NULL_KEY);
				}
				else if (lMessage=="block IM")
				{
					gIMBlock=TRUE;
					llMessageLinked(LINK_SET, gRLVCommandMessage, "blockIM", NULL_KEY);
				}
				else if (lMessage=="blind")
				{
					gBlind=TRUE;
					llMessageLinked(LINK_SET, gRLVCommandMessage, "allowBlind", NULL_KEY);
				}
				else if (lMessage=="no blind")
				{
					gBlind=FALSE;
					llMessageLinked(LINK_SET, gRLVCommandMessage, "noBlind", NULL_KEY);
				}
				else if (lMessage=="block emote")
				{
					gEmoteBlock=TRUE;
					llMessageLinked(LINK_SET, gRLVCommandMessage, "blockEmote", NULL_KEY);
				}
				else if (lMessage=="allow emote")
				{
					gEmoteBlock=FALSE;
					llMessageLinked(LINK_SET, gRLVCommandMessage, "allowEmote", NULL_KEY);
				}
				else if (lMessage=="allow carry")
				{
					gCanCarry=TRUE;
					llMessageLinked(LINK_SET, gRLVCommandMessage, "allowCarry", NULL_KEY);
				}
				else if (lMessage=="no carry")
				{
					gCanCarry=FALSE;
					llMessageLinked(LINK_SET, gRLVCommandMessage, "noCarry", NULL_KEY);
				}
				else if (lMessage=="allow break")
				{
					gCanBreak=TRUE;
				}
				else if (lMessage=="no break")
				{
					gCanBreak=FALSE;
				}
				else if (lMessage=="not secure")
				{
					gSecureBlocks=FALSE;
					llMessageLinked(LINK_SET, gRLVCommandMessage, "notSecure", NULL_KEY);
				}
				else if (lMessage=="secure")
				{
					gSecureBlocks=TRUE;
					llMessageLinked(LINK_SET, gRLVCommandMessage, "secure", NULL_KEY);
				}
				displaySettingsMenu(lID);
			}
			if (gMenuLevel=="configure")
			{
				if (lMessage=="no email")
				{
					gEnableEmail=FALSE;
					llMessageLinked(LINK_SET, gEmailCommandMessage, "disable", NULL_KEY);
					displayConfigureMenu(lID);
				}
				else if (lMessage=="email on")
				{
					if ((gOwnerEmail=="") || (gEmailPassword==""))
					{
						llInstantMessage (lID, "you can not enable email until an address and password are set");
					}
					else
					{
						gEnableEmail=TRUE;
						llMessageLinked(LINK_SET, gEmailCommandMessage, "enable", NULL_KEY);
						displayConfigureMenu(lID);
					}
				}
				if (lMessage=="set addr")
				{
					gGetEmailChannel=(integer)(llFrand(-1000000000.0) - 1000000000.0);
					gListenHandle = llListen(gGetEmailChannel, "", "", "");
					llTextBox(lID, "Please enter your email address", gGetEmailChannel);
				}
				else if (lMessage=="set pwd")
				{
					gGetPwdChannel=(integer)(llFrand(-1000000000.0) - 1000000000.0);
					gListenHandle = llListen(gGetPwdChannel, "", "", "");
					llTextBox(lID, "Please enter your password", gGetPwdChannel);
				}
				else if (lMessage=="back")
				{
					displayMainMenu(lID);
					return;
				}
				//displayConfigureMenu(lID);
				return;



			}


		}
		if (lChannel==gSensorChannel)
		{
			llListenRemove(gListenHandle);
			gListenHandle=0;
			gOwner=llName2Key(lMessage);
			llOwnerSay ("Owner set to: " + llGetDisplayName(gOwner) + " (" + lMessage + ")" );
			llInstantMessage (gOwner, "You have been set as owner of: " + llGetDisplayName(gWearer) + " (" + llKey2Name(gWearer) + ")");
			gHasOwner=TRUE;
			gOwnerName=llGetDisplayName(gOwner);
			llMessageLinked(LINK_SET, gRLVCommandMessage, "owner", gOwner);

		}
		if (lChannel==gGetNameChannel)
		{
			llListenRemove(gListenHandle);
			gListenHandle=0;
			gDollieName=lMessage;
			llInstantMessage(lID, "Name set to: " + gDollieName);
			llMessageLinked(LINK_SET, gRenamerCommandMessage, "set name", gDollieName);
		}
		if (lChannel==gGetEmailChannel)
		{
			llListenRemove(gListenHandle);
			gListenHandle=0;
			gOwnerEmail=lMessage;
			llInstantMessage(lID, "Email address set to: " + gOwnerEmail);
			llMessageLinked(LINK_SET, gEmailCommandMessage, "setaddress", gOwnerEmail);
		}
		if (lChannel==gGetPwdChannel)
		{
			llListenRemove(gListenHandle);
			gListenHandle=0;
			gEmailPassword=lMessage;
			llInstantMessage(lID, "Email password set to: " + gEmailPassword);
			llMessageLinked(LINK_SET, gEmailCommandMessage, "setpassword", gEmailPassword);
		}
	}
	no_sensor()
	{
		llOwnerSay ("Sorry we could not detect and people near you");

	}
	sensor (integer lNumDetected)
	{
		list lNames = [];
		integer i;
		for (i = 0; i < lNumDetected; i++)
		{
			lNames = lNames + llDetectedName(i);

		}
		gSensorChannel=(integer)(llFrand(-1000000000.0) - 1000000000.0);
		gListenHandle = llListen(gSensorChannel, "", "", "");
		llDialog(gWearer, "Please choose an owner from the following list:", lNames, gSensorChannel);

	}
	timer()
	{
		if (llGetUnixTime() >= gMenuExpireTime)
		{
			llListenRemove(gListenHandleMenu);
			//llInstantMessage (gToucher, "menu expired");
		}
	}
	link_message(integer sender_num, integer num, string msg, key id)
	{
		if (num == gStatusUpdateMessage)
		{
			if (msg=="time")
			{
				string lTime=(string)id;
				gCurrentWindLevel=(float)lTime;
			}
		}
		else if (num==gRLVCommandMessage)
		{
			if (msg=="dollythawed") gFrozen=FALSE;
			else if (msg=="dollydead") gDollieDead=TRUE;
			else if (msg=="dollyalive") gDollieDead=FALSE;
			else if (msg=="dolliebroken") gDollieBroken=TRUE;
			else if (msg=="dollierepaired") gDollieBroken=FALSE;
		}
		return;
	}
	changed(integer change)
	{
		if (change & CHANGED_OWNER)
		{
			llOwnerSay("Owner has changed re-configuring.");
			initialise ();
		}
	}



}
