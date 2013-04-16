package de.s2.sim.simyo.vidadmintool.service.validate;

public class ValidationMessage
{

	private final String message;

	private final String fieldPath;

	public ValidationMessage(String fieldPath, String message)
	{
		this.fieldPath = fieldPath;
		this.message = message;
	}

	public String getFieldPath()
	{
		return fieldPath;
	}

	public String getMessage()
	{
		return message;
	}

	@Override
	public String toString()
	{
		return fieldPath + " : " + message;
	}

}
