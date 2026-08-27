class ActionToggleAIAttachmentVisibility extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel name AILabel;
var travel name AttachmentCategory;
var travel bool bHideAttachments;

function Variable execute()
{
	local ShockAI Target;

	super.execute();
	// End:0xA1
	if(__NFUN_255__(AILabel, 'None'))
	{
		// End:0x9D
		foreach parentScript.Level.dynamicActorLabel(Class'ShockAI.ShockAI', Target, AILabel)
		{
			// End:0x9C
			if(__NFUN_119__(Target, none))
			{
				Target.ToggleAttachmentsVisibility(AttachmentCategory, bHideAttachments);								
				goto J0xD3;
				log('AI', 2, __NFUN_112__("No AILabel set for ", string(Name)));
			}
		}
		return none;
	}
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function editorDisplayString(out string S)
{
	// End:0xF0
	if(__NFUN_255__(AILabel, 'None'))
	{
		// End:0xC6
		if(__NFUN_255__(AttachmentCategory, 'None'))
		{
			// End:0x4E
			if(bHideAttachments)
			{
				S = "Hide";
				goto J0x5E;
				S = "Show";
				S = __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(S, " the attachments of category "), string(AttachmentCategory)), " of AIs with label "), string(AILabel));
			}
			goto J0xED;
			S = "AttachmentCategory not set!";
			goto J0x10C;
		}
		S = "AILabel not set!";
		return;
		@NULL
		CommanderAction
		CommanderAction
	}
	@NULL
}

defaultproperties
{
	actionDisplayName="Toggle AI Attachments Visibility"
	actionHelp="Show or hide AI Attachments"
	Category="AI"
}