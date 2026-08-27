class BasePanicAction extends BioshockCharacterAction
	native
	collapsecategories
	hidecategories(Object,InternalParameters);

var private Protector ProtectorEscort;
var private ShockPlayer PlayerEscort;

function initAction(AI_Resource R, AI_Goal Goal)
{
	super(AI_CharacterAction).initAction(R, Goal);
	assert(__NFUN_119__(m_Pawn, none));
	ProtectorEscort = Gatherer(m_Pawn).GetProtectorEscort();
	PlayerEscort = Gatherer(m_Pawn).GetPlayerEscort();
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function NotifyPlayPickedUpAnimation()
{
	return;
}

defaultproperties
{
	satisfiesGoal=Class'ShockAI.PanicGoal'
}