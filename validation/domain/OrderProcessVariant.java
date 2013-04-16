package de.s2.sim.simyo.domain.campaign;

import com.google.common.collect.Lists;

import de.s2.sim.simyo.domain.NamedElement;
import de.s2.sim.simyo.domain.VersionedEntity;
import de.s2.sim.simyo.domain.account.AccountMarketingData.DistributionChannel;
import de.s2.sim.simyo.domain.aspect.AspectIdentifier;
import de.s2.sim.simyo.domain.constraints.DomainLevelValidation;
import de.s2.sim.simyo.domain.constraints.OrderProcessVariantValidator;
import de.s2.sim.simyo.domain.infrastructure.util.EnumHelperMap;
import de.s2.sim.simyo.domain.order.configuration.CampaignVoucherSummation;
import de.s2.sim.simyo.domain.order.configuration.ContractAspectSpecificBonus;
import de.s2.sim.simyo.domain.order.configuration.ContractConfigurationPrototype;
import de.s2.sim.simyo.domain.tariff.Product;
import de.s2.sim.simyo.domain.tariff.Product.ProductType;
import de.s2.sim.simyo.domain.tariff.TariffOption;
import de.s2.sim.simyo.domain.value.CampaignCode;
import de.s2.sim.simyo.domain.value.DirectDebitLight;
import de.s2.sim.simyo.domain.value.LogisticLetterKey;
import de.s2.sim.simyo.domain.value.OrderProcessIdentifier;
import de.s2.sim.simyo.domain.value.OrderProcessVariantIdentifier;
import de.s2.sim.simyo.domain.value.VoucherCode;

import java.util.Collection;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedList;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import javax.persistence.AttributeOverride;
import javax.persistence.Basic;
import javax.persistence.CascadeType;
import javax.persistence.Column;
import javax.persistence.Embedded;
import javax.persistence.Entity;
import javax.persistence.EnumType;
import javax.persistence.Enumerated;
import javax.persistence.FetchType;
import javax.persistence.JoinColumn;
import javax.persistence.JoinTable;
import javax.persistence.ManyToOne;
import javax.persistence.NamedQueries;
import javax.persistence.NamedQuery;
import javax.persistence.OneToMany;
import javax.persistence.Table;
import javax.persistence.UniqueConstraint;
import javax.validation.Valid;
import javax.validation.constraints.NotNull;

import org.apache.commons.lang.StringUtils;
import org.atemsource.atem.api.attribute.annotation.Association;
import org.atemsource.atem.api.attribute.annotation.MapAssociation;
import org.hibernate.annotations.Cache;
import org.hibernate.annotations.CacheConcurrencyStrategy;
import org.hibernate.annotations.Cascade;
import org.hibernate.annotations.CollectionOfElements;
import org.joda.time.DateTime;


/**
 * <strong>Bestellprozesskonfiguration:</strong> Die Bestellprozesskonfiguration (Datenbank) umfasst eine eindeutigen
 * Schlüssel „variantIdentifier“ (vorab als „pid“ bezeichnet) sowie weitere Details zur Vorkonfiguration eines
 * Bestellprozesses:
 * <ul>
 * <li>variantIdentifier (eindeutiger Schlüssel, alphanumerisch, beliebig definierbar)</li>
 * <li>Kampagnengutschein vr (wie bisher aber in Kampagnenkonfiguration)</li>
 * <li>Kampagnengutschein cv (wie bisher aber in Kampagnenkonfiguration)</li>
 * <li>Referenz auf Vertragskonfiguration cc (wie bisher aber in Kampagnenkonfiguration)</li>
 * <li>Referenz auf Prozesskonfiguration pc (wie bisher aber in Kampagnenkonfiguration)</li>
 * <li>Steuerung Lastschrift-Light (wie bisher aber in Kampagnenkonfiguration)</li>
 * <li>Steuerung distributationChannel (wie bisher aber in Kampagnenkonfiguration)</li>
 * <li>Steuerung logisticLetterKey (wie bisher aber in Kampagnenkonfiguration)</li>
 * <li>Referenz auf einen Teaser (wie bisher aber in Kampagnenkonfiguration)</li>
 * <li>Steuerung für Kampagnenexklusivität (nur indirekt über Kampagnenkonfiguration selektierbar, welche diese
 * Konfiguration referenzieren)</li>
 * <li>Referenz auf eine Gutschein-Verrechnungskonfiguration (wie bisher aber in Kampagnenkonfiguration)</li>
 * </ul>
 * <p>
 * Information about the "uuid" field:
 * </p>
 * This "uuid" is required for the VID Admintool in order to map OrderProcessVariants across different databases (i.e.
 * stage and production). As the database IDs of the OrderProcessVariants can be different between these databases, we
 * need an explicitly set field like "uuid" for this mapping. The "variant" field is also not sufficient for this task,
 * as this field will be editable in the VID Admintool and might change. The mapping across databases is required by the
 * VID Admintool in order to publish changes on OrderProcessVariants in one database to another database. The "uuid"
 * field is only filled via the VID Admintool.
 * 
 * @author {@literal Markus Schwarz <m.schwarz@wortzwei.de>}
 */
@Entity
@NamedQueries({
	@NamedQuery(name = OrderProcessVariant.BY_VARIANT, query = "SELECT o FROM OrderProcessVariant o WHERE variantIdentifier = :variantIdentifier"),
	@NamedQuery(name = OrderProcessVariant.ALL_VARIANTS, query = "SELECT o FROM OrderProcessVariant o "),
	@NamedQuery(name = OrderProcessVariant.COUNT_VARIANTS_BY_VOUCHER, query = "SELECT count(*) FROM OrderProcessVariant o WHERE voucherCode = :voucherCode ")})
@Cache(usage = CacheConcurrencyStrategy.NONSTRICT_READ_WRITE)
@OrderProcessVariantValidator(groups = DomainLevelValidation.class)
@Table(uniqueConstraints = {@UniqueConstraint(columnNames = "variant"), @UniqueConstraint(columnNames = "uuid")})
public class OrderProcessVariant extends VersionedEntity<OrderProcessVariant> implements NamedElement
{

	public static final String ALL_VARIANTS = "findAllOrderProcessVariants";

	public static final String BY_VARIANT = "findOrderProcessVariantByVariant";

	public static final String COUNT_VARIANTS_BY_VOUCHER = "countVariantsByVoucher";

	public static final String FOLLOWING_IDENTICAL_ORDER_VID = "followingIdenticalOrder";

	public static final String FOLLOWING_ORDER_VID = "followingOrder";

	private static final long serialVersionUID = -7304117003233101097L;

	public static final String VARIANT_PREFIX_LIGHT = "einfach_";

	@Valid
	@Enumerated(EnumType.STRING)
	@AttributeOverride(name = "value", column = @Column(name = "accountRatingFlag", nullable = false))
	private AccountRatingFlag accountRatingFlag;

	@Valid
	@OneToMany(targetEntity = ContractAspectSpecificBonus.class)
	@Cascade(value = {org.hibernate.annotations.CascadeType.ALL, org.hibernate.annotations.CascadeType.DELETE_ORPHAN})
	@Association(targetType = ContractAspectSpecificBonus.class)
	@Cache(usage = CacheConcurrencyStrategy.NONSTRICT_READ_WRITE)
	@JoinColumn(name = "orderProcessVariant_id")
	private List<ContractAspectSpecificBonus> bonuses = new LinkedList<ContractAspectSpecificBonus>();

	/**
	 * Steuerung für Kampagnenexklusivität. Nur indirekt über Kampagnenkonfiguration selektierbar, welche diese
	 * Konfiguration referenzieren
	 */
	private boolean boundToCampaign = false;

	/** TODO: Remove with SIMWSN-5669. */
	@Embedded
	@AttributeOverride(name = "value", column = @Column(name = "cv", nullable = true))
	private CampaignCode campaignCode;

	/** TODO: Remove with SIMWSN-5669. */
	@ManyToOne(cascade = CascadeType.PERSIST)
	private CampaignVoucherSummation campaignVoucherSummation;

	/** TODO: Remove with SIMWSN-5669. */
	@ManyToOne(cascade = {javax.persistence.CascadeType.PERSIST}, fetch = FetchType.EAGER)
	@JoinColumn(name = "cc")
	private ContractConfigurationPrototype contractConfigurationPrototype;

	private String description;

	@Valid
	@NotNull
	@Embedded
	@AttributeOverride(name = "value", column = @Column(name = "directDebitLight", nullable = false))
	private DirectDebitLight directDebitLight;

	@Valid
	@Enumerated(EnumType.STRING)
	private DistributionChannel distributionChannel;

	/** TODO: Remove with SIMWSN-5669. */
	@Embedded
	@AttributeOverride(name = "value", column = @Column(name = "flexVr", nullable = true))
	private VoucherCode flexVoucherCode;

	/** TODO: Remove with SIMWSN-5669. */
	private String flexVoucherDescription;

	@Basic(optional = false)
	private boolean lightLayout;

	@Valid
	@Embedded
	@AttributeOverride(name = "value", column = @Column(name = "logisticLetterKey", nullable = true))
	private LogisticLetterKey logisticLetterKey;

	/** TODO: Remove with SIMWSN-5669. */
	private String marketingDescription;

	@Basic(optional = false)
	private boolean monitoringEnabled;

	private boolean multiOrder;

	@Valid
	@NotNull
	@Embedded
	@AttributeOverride(name = "value", column = @Column(name = "pc", nullable = false))
	private OrderProcessIdentifier orderProcessIdentifier;

	private boolean orderUpdateEnabled;

	@Valid
	@CollectionOfElements
	@Column(length = 128)
	@JoinTable(name = "OrderProcessVariant_PredefinedAspectIdentifier")
	@org.hibernate.annotations.Type(type = "aspectIdentifier")
	@Cache(usage = CacheConcurrencyStrategy.NONSTRICT_READ_WRITE)
	@Association(targetType = AspectIdentifier.class)
	private Set<AspectIdentifier> preDefinedContractAspects = new HashSet<AspectIdentifier>();

	@Valid
	@MapAssociation(keyType = ProductType.class, targetType = OpvProductSettings.class)
	@OneToMany(fetch = FetchType.EAGER)
	@Cascade(value = {org.hibernate.annotations.CascadeType.ALL, org.hibernate.annotations.CascadeType.DELETE_ORPHAN})
	@JoinColumn(name = "orderProcessVariant_id")
	@javax.persistence.MapKey(name = "product")
	@Cache(usage = CacheConcurrencyStrategy.NONSTRICT_READ_WRITE)
	private Map<ProductType, OpvProductSettings> productSettings = new HashMap<ProductType, OpvProductSettings>();

	private boolean resetVariantAfterSubmission = false;

	/** TODO: Remove with SIMWSN-5669. */
	private String teaserReferenceKey;

	@Valid
	@NotNull
	@Column(nullable = true, columnDefinition = "varchar(16)")
	@Enumerated(EnumType.STRING)
	private OrderProcessVariantUsage usageType;

	/**
	 * The UUID can be used for identifying OrderProcessVariants across different databases. Therefore every
	 * OrderProcessVariant should have a UUID.
	 */
	private String uuid;

	@org.hibernate.annotations.Type(type = "dateTime")
	private DateTime validFrom;

	@org.hibernate.annotations.Type(type = "dateTime")
	private DateTime validTo;

	@Valid
	@NotNull
	@Embedded
	@AttributeOverride(name = "value", column = @Column(name = "variant", nullable = false, unique = true))
	private OrderProcessVariantIdentifier variantIdentifier;

	/** TODO: Remove with SIMWSN-5669. */
	@Valid
	@Embedded
	@AttributeOverride(name = "value", column = @Column(name = "vr", nullable = true))
	private VoucherCode voucherCode;

	/** TODO: Remove with SIMWSN-5669. */
	private String voucherDescription;

	/**
	 * JPA constructor.
	 */
	public OrderProcessVariant()
	{

	}

	public void addBonus(ContractAspectSpecificBonus bonus)
	{
		if (bonuses == null)
		{
			bonuses = Lists.newArrayList();
		}
		bonuses.add(bonus);
	}

	public void addProductSettings(OpvProductSettings opvProductSettings)
	{
		if (productSettings == null)
		{
			productSettings = new HashMap<Product.ProductType, OpvProductSettings>();
		}
		productSettings.put(opvProductSettings.getProduct(), opvProductSettings);
	}

	public boolean checkVoucherAndCampaign()
	{
		for (OpvProductSettings settings : getProductSettings().values())
		{
			if (!settings.isCampaignValid() || !settings.isVoucherValid())
			{
				return false;
			}
		}
		return true;
	}

	public void deselect(AspectIdentifier selectedAspectIdentifier)
	{
		preDefinedContractAspects.remove(selectedAspectIdentifier);
	}

	public AccountRatingFlag getAccountRatingFlag()
	{
		return accountRatingFlag;
	}

	public ContractAspectSpecificBonus getBonus(AspectIdentifier id)
	{
		for (ContractAspectSpecificBonus bonus : bonuses)
		{
			if (bonus.getRequiredAspectIdentifiers().contains(id))
			{
				return bonus;
			}
		}
		return null;
	}

	public List<ContractAspectSpecificBonus> getBonuses()
	{
		return bonuses;
	}

	/**
	 * return the teaser for the preselected product type
	 * 
	 * @return
	 */
	public String getDefaultTeaserReferenceKey()
	{
		ProductType productType = this.getPreSelected(ProductType.class);
		if (productType != null)
		{
			OpvProductSettings productSettin = getProductSettings(productType);
			if (productSettin == null)
			{
				return null;
			}
			else
			{
				return productSettin.getTeaserReferenceKey();
			}
		}
		return null;
	}

	@Override
	public String getDescription()
	{
		return description;
	}

	public DirectDebitLight getDirectDebitLight()
	{
		return directDebitLight;
	}

	public DistributionChannel getDistributionChannel()
	{
		return distributionChannel;
	}

	@Override
	public String getLabel()
	{
		return variantIdentifier.getValue();
	}

	public String getLightSegment()
	{
		String segment = "";
		Pattern p = Pattern.compile(VARIANT_PREFIX_LIGHT + "([^_]+).*");
		Matcher m = p.matcher(variantIdentifier.getValue());
		if (m.matches())
		{
			segment = m.group(1);
		}
		return StringUtils.capitalize(segment);
	}

	public LogisticLetterKey getLogisticLetterKey()
	{
		return logisticLetterKey;
	}

	public OrderProcessIdentifier getOrderProcessIdentifier()
	{
		return orderProcessIdentifier;
	}

	public Set<AspectIdentifier> getPreDefinedContractAspects()
	{
		return preDefinedContractAspects;
	}

	public <A extends AspectIdentifier> A getPreSelected(Class<A> aspectClass)
	{
		for (AspectIdentifier aspectIdentifier : preDefinedContractAspects)
		{
			if (aspectClass.isInstance(aspectIdentifier))
			{
				return (A) aspectIdentifier;
			}
		}
		return null;
	}

	public <A extends AspectIdentifier> Collection<A> getPreSelectedAspects(Class<A> aspectClass)
	{
		Collection<A> aspects = new HashSet<A>();
		for (AspectIdentifier aspectIdentifier : getPreDefinedContractAspects())
		{
			if (aspectClass.isInstance(aspectIdentifier))
			{
				aspects.add((A) aspectIdentifier);
			}
		}
		return aspects;
	}

	public Map<ProductType, OpvProductSettings> getProductSettings()
	{
		return productSettings;
	}

	public OpvProductSettings getProductSettings(ProductType productType)
	{
		return productSettings.get(productType);
	}

	public OrderProcessVariantUsage getUsageType()
	{
		return usageType;
	}

	public String getUuid()
	{
		return uuid;
	}

	public DateTime getValidFrom()
	{
		return validFrom;
	}

	public DateTime getValidTo()
	{
		return validTo;
	}

	public OrderProcessVariantIdentifier getVariantIdentifier()
	{
		return variantIdentifier;
	}

	/**
	 * Steuerung für Kampagnenexklusivität. Wenn dieser Wert <code>true</code> ist, dann darf diese Prozesskonfiguration
	 * nur über campaign/att und nicht über die Variante direkt selektiert werden.
	 * <p>
	 * <strong>Aus dem Konzept:</strong> Es ist möglich, Bestellprozesse exklusiv an eine Kampagnenkonfiguration zu
	 * binden. Damit kann die so konfigurierte Bestellprozesskonfiguration nur noch implizit über die Angabe eins
	 * Marketingcodes selektiert zu werden ( <em>Exklusivität für Affiliates</em>). Eine Übernahme von konfigurierten
	 * Bonifizierungen durch nicht vorgesehene Affiliate-Partner kann so verhindert werden.
	 * </p>
	 * 
	 * @return
	 */
	public boolean isBoundToCampaign()
	{
		return boundToCampaign;
	}

	public boolean isLightLayout()
	{
		return lightLayout;
	}

	public boolean isMonitoringEnabled()
	{
		return monitoringEnabled;
	}

	public boolean isMultiOrder()
	{
		return multiOrder;
	}

	public boolean isOrderUpdateEnabled()
	{
		return orderUpdateEnabled;
	}

	public boolean isPreSelected(AspectIdentifier aspectIdentifier)
	{
		return getPreDefinedContractAspects().contains(aspectIdentifier);
	}

	public boolean isResetVariantAfterSubmission()
	{
		return resetVariantAfterSubmission;
	}

	public boolean isValid()
	{
		final DateTime today = new DateTime();
		return (validFrom != null ? today.compareTo(validFrom) >= 0 : true)
			&& (validTo != null ? today.compareTo(validTo) <= 0 : true);
	}

	public void removeAllIncludedOptions()
	{
		// TODO Check after refactoring SIMWSN-4591
		Set<TariffOption.Type> notSelectableOptions = new HashSet<TariffOption.Type>();
		for (ProductType productType : ProductType.values())
		{
			for (TariffOption.Type includedOption : productType.getIncludedOptions())
			{
				if (preDefinedContractAspects.contains(includedOption))
				{
					notSelectableOptions.add(includedOption);
				}
			}
		}
		preDefinedContractAspects.removeAll(notSelectableOptions);
	}

	public void select(AspectIdentifier selectedAspectIdentifier)
	{
		preDefinedContractAspects.add(selectedAspectIdentifier);
	}

	public void setAccountRatingFlag(AccountRatingFlag accountRatingFlag)
	{
		this.accountRatingFlag = accountRatingFlag;
	}

	public void setBonuses(List<ContractAspectSpecificBonus> bonuses)
	{
		this.bonuses = bonuses;
	}

	public void setBoundToCampaign(boolean associatedToCampaign)
	{
		this.boundToCampaign = associatedToCampaign;
	}

	@Deprecated
	public void setCampaignCode(CampaignCode campaignCode)
	{
		this.campaignCode = campaignCode;
	}

	@Deprecated
	public void setCampaignVoucherSummation(CampaignVoucherSummation campaignVoucherSummation)
	{
		this.campaignVoucherSummation = campaignVoucherSummation;
	}

	public void setDescription(String description)
	{
		this.description = description;
	}

	public void setDirectDebitLight(DirectDebitLight directDebitLight)
	{
		this.directDebitLight = directDebitLight;
	}

	public void setDistributionChannel(DistributionChannel distributionChannel)
	{
		this.distributionChannel = distributionChannel;
	}

	public void setLightLayout(boolean lightLayout)
	{
		this.lightLayout = lightLayout;
	}

	public void setLogisticLetterKey(LogisticLetterKey logisticLetterKey)
	{
		this.logisticLetterKey = logisticLetterKey;
	}

	@Deprecated
	public void setMarketingDescription(String marketingDescription)
	{
		this.marketingDescription = marketingDescription;
	}

	public void setMonitoringEnabled(boolean monitoringEnabled)
	{
		this.monitoringEnabled = monitoringEnabled;
	}

	public void setMultiOrder(boolean multiOrder)
	{
		this.multiOrder = multiOrder;
	}

	public void setOrderProcessIdentifier(OrderProcessIdentifier orderProcessIdentifier)
	{
		this.orderProcessIdentifier = orderProcessIdentifier;
	}

	public void setOrderUpdateEnabled(boolean orderUpdateEnabled)
	{
		this.orderUpdateEnabled = orderUpdateEnabled;
	}

	public void setPreDefinedContractAspects(Set<AspectIdentifier> preDefinedContractAspects)
	{
		this.preDefinedContractAspects = preDefinedContractAspects;
	}

	public void setProductSettings(Map<ProductType, OpvProductSettings> productSettings)
	{
		this.productSettings = productSettings;
	}

	public void setResetVariantAfterSubmission(boolean resetVariantAfterSubmission)
	{
		this.resetVariantAfterSubmission = resetVariantAfterSubmission;
	}

	public void setUsageType(OrderProcessVariantUsage usage)
	{
		this.usageType = usage;
	}

	public void setUuid(String uuid)
	{
		this.uuid = uuid;
	}

	public void setValidFrom(DateTime validFrom)
	{
		this.validFrom = validFrom;
	}

	public void setValidTo(DateTime validTo)
	{
		this.validTo = validTo;
	}

	public void setVariantIdentifier(OrderProcessVariantIdentifier orderProcessVariantIdentifier)
	{
		this.variantIdentifier = orderProcessVariantIdentifier;
	}

	@Deprecated
	public void setVoucherCode(VoucherCode voucherCode)
	{
		this.voucherCode = voucherCode;
	}

	/**
	 * An enum to define the possible values for the account rating flag. The values are defined by the criteria used for
	 * the account rating done by infoscore. They have been briefed this way (see SIMWSN-5146): - arvato '0': rating
	 * against soft, medium, and hard criteria. - arvato '1': rating against soft, medium, hard, and NCA criteria. -
	 * arvato '2': rating against hard, and NCA criteria. NCA stands for Non Commercial Accountcheck. The different
	 * versions are configured by simyo so that there is no real knowledge on what those criteria are. What is known is
	 * that the first version (number 0) doesn't take any account information.
	 */
	public enum AccountRatingFlag implements EnumHelperMap.Key<Character>
	{
		HARD_NCA('2'), SOFT_MEDIUM_HARD('0'), SOFT_MEDIUM_HARD_NCA('1');

		public static final EnumHelperMap<Character, AccountRatingFlag> VALUEMAP =
			new EnumHelperMap<Character, AccountRatingFlag>(AccountRatingFlag.values());

		private final Character key;

		private AccountRatingFlag(Character key)
		{
			this.key = key;
		}

		@Override
		public Character key()
		{
			return key;
		}
	};

}