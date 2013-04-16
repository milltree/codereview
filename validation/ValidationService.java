package de.s2.sim.simyo.vidadmintool.service.validate;

import com.google.common.collect.Lists;
import com.google.common.collect.Maps;

import de.s2.sim.simyo.domain.campaign.OrderProcessVariant;
import de.s2.sim.simyo.domain.constraints.DomainLevelValidation;
import de.s2.sim.simyo.vidadmintool.service.util.ResourceBundleNames;
import de.s2.sim.simyo.vidadmintool.service.util.ResourceBundleUtils;
import de.s2.sim.simyo.vidadmintool.service.validate.rule.RuleValidationService;

import java.util.Collection;
import java.util.Map;
import java.util.ResourceBundle;

import javax.annotation.PostConstruct;
import javax.inject.Inject;
import javax.validation.ConstraintViolation;
import javax.validation.MessageInterpolator;
import javax.validation.Validation;
import javax.validation.Validator;
import javax.validation.ValidatorContext;
import javax.validation.ValidatorFactory;
import javax.validation.groups.Default;

import org.hibernate.validator.engine.ResourceBundleMessageInterpolator;
import org.springframework.stereotype.Service;


@Service
public class ValidationService
{

	@Inject
	private UniqueVidValidationService uniqueVidValidationService;

	@Inject
	private PredefinedAspectsValidationService predefinedAspectsValidationService;

	@Inject
	private RuleValidationService ruleValidationService;

	private ValidatorFactory validatorFactory;

	private FieldViewPathExtraction fieldPathExtraction;

	private Collection<ValidationMessage> convertConstraintViolations(
		Collection<ConstraintViolation<OrderProcessVariant>> constraintViolations)
	{
		Collection<ValidationMessage> messages = Lists.newArrayList();

		for (final ConstraintViolation<OrderProcessVariant> constraintViolation : constraintViolations)
		{
			String fieldPath = fieldPathExtraction.extract(constraintViolation.getPropertyPath());
			String messageText = constraintViolation.getMessage();

			messages.add(new ValidationMessage(fieldPath, messageText));
		}
		return messages;
	}

	private Collection<ConstraintViolation<OrderProcessVariant>> detectConstraintViolations(OrderProcessVariant variant)
	{
		ResourceBundle bundle = ResourceBundleUtils.getResourceBundle(ResourceBundleNames.VALIDATION_MESSAGES);
		MessageInterpolator messageInterpolator = new ResourceBundleMessageInterpolator(bundle);

		final ValidatorContext validatorContext = validatorFactory.usingContext();
		validatorContext.messageInterpolator(messageInterpolator);
		final Validator validator = validatorContext.getValidator();

		Collection<ConstraintViolation<OrderProcessVariant>> constraintViolations =
			validator.validate(variant, new Class[]{Default.class, DomainLevelValidation.class});

		return constraintViolations;
	}

	@PostConstruct
	public void initialize()
	{
		validatorFactory = Validation.buildDefaultValidatorFactory();
		fieldPathExtraction = new FieldViewPathExtraction();
	}

	public Collection<ValidationMessage> validate(OrderProcessVariant variant)
	{
		Collection<ConstraintViolation<OrderProcessVariant>> violations = this.detectConstraintViolations(variant);

		ValidationMessages messages = new ValidationMessages();
		messages.add(this.convertConstraintViolations(violations));
		messages.add(predefinedAspectsValidationService.validate(variant));
		messages.add(ruleValidationService.validate(variant));
		messages.add(uniqueVidValidationService.validate(variant));

		return messages.getAll();
	}

	public Collection<ValidationMessage> validate(OrderProcessVariant variant, Long variantId)
	{
		Collection<ConstraintViolation<OrderProcessVariant>> violations = this.detectConstraintViolations(variant);

		ValidationMessages messages = new ValidationMessages();
		messages.add(this.convertConstraintViolations(violations));
		messages.add(predefinedAspectsValidationService.validate(variant));
		messages.add(ruleValidationService.validate(variant));
		messages.add(uniqueVidValidationService.validate(variant, variantId));

		return messages.getAll();
	}

	private class ValidationMessages
	{

		private final Map<String, ValidationMessage> messages = Maps.newHashMap();

		private void add(Collection<ValidationMessage> newMessages)
		{
			for (ValidationMessage newMessage : newMessages)
			{
				if (!messages.containsKey(newMessage.getFieldPath()))
				{
					messages.put(newMessage.getFieldPath(), newMessage);
				}
			}
		}

		public Collection<ValidationMessage> getAll()
		{
			return messages.values();
		}

	}

}
