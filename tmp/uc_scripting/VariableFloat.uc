class VariableFloat extends Variable
	native
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel float Value;

function Add(string rhs)
{
	__NFUN_184__(Value, float(rhs));
	return;
	@NULL
	Variable
}

function subtract(string rhs)
{
	__NFUN_185__(Value, float(rhs));
	return;
	@NULL
	Variable
}

function multiply(string rhs)
{
	__NFUN_182__(Value, float(rhs));
	return;
	@NULL
	Variable
}

function divide(string rhs)
{
	__NFUN_183__(Value, float(rhs));
	return;
	@NULL
	Variable
}

function bool less(string rhs)
{
	return __NFUN_176__(Value, float(rhs));
	return;
	@NULL
	Variable
}

function bool lessEqual(string rhs)
{
	return __NFUN_178__(Value, float(rhs));
	return;
	@NULL
	Variable
}

function bool equal(string rhs)
{
	return __NFUN_180__(Value, float(rhs));
	return;
	@NULL
	Variable
}

function bool notEqual(string rhs)
{
	return __NFUN_181__(Value, float(rhs));
	return;
	@NULL
	Variable
}

function bool greaterEqual(string rhs)
{
	return __NFUN_179__(Value, float(rhs));
	return;
	@NULL
	Variable
}

function bool greater(string rhs)
{
	return __NFUN_177__(Value, float(rhs));
	return;
	@NULL
	Variable
}

function bool and(string rhs)
{
	return __NFUN_130__(__NFUN_181__(Value, 0.0000000), __NFUN_181__(float(rhs), 0.0000000));
	return;
	@NULL
	Variable
}

function bool or(string rhs)
{
	return __NFUN_132__(__NFUN_181__(Value, 0.0000000), __NFUN_181__(float(rhs), 0.0000000));
	return;
	@NULL
	Variable
}

function bool not()
{
	return __NFUN_180__(Value, 0.0000000);
	return;
	@NULL
}

function bool truth()
{
	return __NFUN_181__(Value, 0.0000000);
	return;
	@NULL
}
