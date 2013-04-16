package de.s2.sim.simyo.domain.value;

import javax.validation.constraints.Pattern;


/**
 * Triggers an other "Anschreiben", which is sent by arvato during orders.
 * 
 * @author sven
 */
public class LogisticLetterKey extends PrimitiveDomainValue<String, LogisticLetterKey>
{
	private static final long serialVersionUID = 7453630669318307070L;

	public static final LogisticLetterKey DEFAULT = new LogisticLetterKey("");

	public LogisticLetterKey(String value)
	{
		super(value);
	}

	protected LogisticLetterKey()
	{
	}

	@Pattern(regexp = "^$|[a-zA-Z0-9]{3}", message = "{validation.logisticletterkey.invalid}")
	public String getValueForValidation()
	{
		return super.getValue();
	}

	@Override
	public boolean isDefaultForDomain()
	{
		return "".equals(getValue());
	}
}
