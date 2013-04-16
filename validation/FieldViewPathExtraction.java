package de.s2.sim.simyo.vidadmintool.service.validate;

import java.util.regex.Matcher;
import java.util.regex.Pattern;

import javax.validation.Path;


public class FieldViewPathExtraction
{

	private static final Pattern FIELD_ID_INDEX_PATTERN = Pattern.compile("\\[(.*?)\\]");

	private static final String PRODUCT_SETTINGS_PREFIX = "productSettings.";

	private static final String VALIDATION_VALUE_SUFFIX = ".valueForValidation";

	private static final String VALUE_SUFFIX = ".value";

	public String extract(Path propertyPath)
	{
		if (propertyPath == null)
		{
			return null;
		}
		String fieldId = propertyPath.toString();

		fieldId = rewriteDomainValues(fieldId);
		fieldId = rewriteIndexes(fieldId);
		fieldId = rewriteProductSettingsPrefix(fieldId);

		return fieldId;
	}

	private String rewriteDomainValues(String fieldId)
	{
		String rewrittenFieldId = fieldId;
		if (rewrittenFieldId.endsWith(VALIDATION_VALUE_SUFFIX))
		{
			rewrittenFieldId = rewrittenFieldId.substring(0, rewrittenFieldId.lastIndexOf(VALIDATION_VALUE_SUFFIX));
		}
		else if (rewrittenFieldId.endsWith(VALUE_SUFFIX))
		{
			rewrittenFieldId = rewrittenFieldId.substring(0, rewrittenFieldId.lastIndexOf(VALUE_SUFFIX));
		}
		return rewrittenFieldId;
	}

	private String rewriteIndexes(String fieldId)
	{
		Matcher matcher = FIELD_ID_INDEX_PATTERN.matcher(fieldId);
		StringBuffer fieldIdBuffer = new StringBuffer();
		while (matcher.find())
		{
			matcher.appendReplacement(fieldIdBuffer, "");
			fieldIdBuffer.append("." + matcher.group(1));
		}
		matcher.appendTail(fieldIdBuffer);

		return fieldIdBuffer.toString();
	}

	private String rewriteProductSettingsPrefix(String fieldId)
	{
		String rewrittenFieldId = fieldId;
		if (rewrittenFieldId.startsWith(PRODUCT_SETTINGS_PREFIX))
		{
			rewrittenFieldId = rewrittenFieldId.replaceFirst(PRODUCT_SETTINGS_PREFIX, "");
		}
		return rewrittenFieldId;
	}

}
