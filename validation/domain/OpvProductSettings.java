package de.s2.sim.simyo.domain.campaign;

import de.s2.sim.simyo.domain.VersionedEntity;
import de.s2.sim.simyo.domain.article.PostloadListener;
import de.s2.sim.simyo.domain.aspect.StartingCreditIdentifier;
import de.s2.sim.simyo.domain.aspect.TopupIdentifier;
import de.s2.sim.simyo.domain.tariff.Product.ProductType;
import de.s2.sim.simyo.domain.value.CampaignCode;
import de.s2.sim.simyo.domain.value.CurrencyAmount;
import de.s2.sim.simyo.domain.value.VoucherCode;
import de.s2.sim.simyo.domain.voucher.Voucher;

import javax.persistence.AttributeOverride;
import javax.persistence.Column;
import javax.persistence.Embedded;
import javax.persistence.Entity;
import javax.persistence.EntityListeners;
import javax.persistence.EnumType;
import javax.persistence.Enumerated;
import javax.validation.Valid;


/**
 * Product-specific settings for an {@link OrderProcessVariant}.
 * <p>
 * Information about "test..Code" and "production..Code" fields:
 * </p>
 * The motivation behind these fields is that in all databases in all environments (dev, int, stage, production) both
 * voucher codes and both campaign codes (test and production) are available. Which code is used depends on the
 * environments' settings. This is necessary as the order process variants that hold these codes will only be edited via
 * the VID Admintool on a testing environment and will then simply be copied to the production environment. Therefore
 * the user should enter the production codes before copying the order process variants.
 * 
 * @author stemey
 * @since 04.04.2013
 */
@Entity
@EntityListeners(PostloadListener.class)
public class OpvProductSettings extends VersionedEntity<OpvProductSettings>
{
	private static final long serialVersionUID = -6799527106466581443L;

	@javax.persistence.Transient
	private ArvatoCampaign campaign;

	@javax.persistence.Transient
	private boolean campaignValid = true;

	@Valid
	@Embedded
	@AttributeOverride(name = "value", column = @Column(name = "campaignCode"))
	private CampaignCode productionCampaignCode;

	@Valid
	@Embedded
	@AttributeOverride(name = "value", column = @Column(name = "testCampaignCode"))
	private CampaignCode testCampaignCode;

	private String marketingDescription;

	@Enumerated(EnumType.STRING)
	private ProductType product;

	@Valid
	@org.hibernate.annotations.Type(type = "aspectIdentifier")
	@AttributeOverride(name = "value", column = @Column(name = "startingCredit"))
	private StartingCreditIdentifier startingCreditIdentifier;

	private String teaserReferenceKey;

	@Valid
	@org.hibernate.annotations.Type(type = "aspectIdentifier")
	@AttributeOverride(name = "value", column = @Column(name = "topup"))
	private TopupIdentifier topupIdentifier;

	@javax.persistence.Transient
	private Voucher voucher;

	@javax.persistence.Transient
	private boolean voucherValid = true;

	@Valid
	@Embedded
	@AttributeOverride(name = "value", column = @Column(name = "voucherCode"))
	private VoucherCode productionVoucherCode;

	@Valid
	@Embedded
	@AttributeOverride(name = "value", column = @Column(name = "testVoucherCode"))
	private VoucherCode testVoucherCode;

	private String voucherDescription;

	public CurrencyAmount getBonusAmount()
	{
		if (campaign == null)
		{
			return null;
		}
		else
		{
			return campaign.getBonusCredit();
		}
	}

	public ArvatoCampaign getCampaign()
	{

		return campaign;
	}

	public String getMarketingDescription()
	{
		return marketingDescription;
	}

	public CurrencyAmount getPriceReduction()
	{
		if (voucher == null)
		{
			return null;
		}
		else
		{
			return voucher.getValue();
		}
	}

	public ProductType getProduct()
	{
		return product;
	}

	/**
	 * Please use {@link OpvProductSettings#getCampaign()} to retrieve the currently applied campaign code.
	 * 
	 * @return the campaign code to use in a production environment.
	 */
	public CampaignCode getProductionCampaignCode()
	{
		return productionCampaignCode;
	}

	/**
	 * Please use {@link OpvProductSettings#getVoucher()} to retrieve the currently applied voucher code.
	 * 
	 * @return the voucher code to use in a production environment.
	 */
	public VoucherCode getProductionVoucherCode()
	{
		return productionVoucherCode;
	}

	public CurrencyAmount getStartingCredit()
	{
		if (startingCreditIdentifier == null)
		{
			return new CurrencyAmount(0L);
		}
		else
		{
			return startingCreditIdentifier.getCredit();
		}
	}

	public StartingCreditIdentifier getStartingCreditIdentifier()
	{
		return startingCreditIdentifier;
	}

	public String getTeaserReferenceKey()
	{
		return teaserReferenceKey;
	}

	/**
	 * Please use {@link OpvProductSettings#getCampaign()} to retrieve the currently applied campaign code.
	 * 
	 * @return the campaign code to use in a testing environment.
	 */
	public CampaignCode getTestCampaignCode()
	{
		return testCampaignCode;
	}

	/**
	 * Please use {@link OpvProductSettings#getVoucher()} to retrieve the currently applied voucher code.
	 * 
	 * @return the voucher code to use in a testing environment.
	 */
	public VoucherCode getTestVoucherCode()
	{
		return testVoucherCode;
	}

	public CurrencyAmount getTopup()
	{
		if (topupIdentifier == null)
		{
			return new CurrencyAmount(0L);
		}
		else
		{
			return topupIdentifier.getCredit();
		}
	}

	public TopupIdentifier getTopupIdentifier()
	{
		return topupIdentifier;
	}

	public Voucher getVoucher()
	{
		return voucher;
	}

	public String getVoucherDescription()
	{
		return voucherDescription;
	}

	public boolean isCampaignValid()
	{
		return campaignValid;
	}

	public boolean isVoucherValid()
	{
		return voucherValid;
	}

	public void setCampaign(ArvatoCampaign campaign)
	{
		this.campaign = campaign;
	}

	public void setCampaignValid(boolean campaignValid)
	{
		this.campaignValid = campaignValid;
	}

	public void setMarketingDescription(String marketingDescription)
	{
		this.marketingDescription = marketingDescription;
	}

	public void setProduct(ProductType product)
	{
		this.product = product;
	}

	public void setProductionCampaignCode(CampaignCode productionCampaignCode)
	{
		this.productionCampaignCode = productionCampaignCode;
	}

	public void setProductionVoucherCode(VoucherCode productionVoucherCode)
	{
		this.productionVoucherCode = productionVoucherCode;
	}

	public void setStartingCreditIdentifier(StartingCreditIdentifier startingCreditIdentifier)
	{
		this.startingCreditIdentifier = startingCreditIdentifier;
	}

	public void setTeaserReferenceKey(String teaserReferenceKey)
	{
		this.teaserReferenceKey = teaserReferenceKey;
	}

	public void setTestCampaignCode(CampaignCode testCampaignCode)
	{
		this.testCampaignCode = testCampaignCode;
	}

	public void setTestVoucherCode(VoucherCode testVoucherCode)
	{
		this.testVoucherCode = testVoucherCode;
	}

	public void setTopupIdentifier(TopupIdentifier topupIdentifier)
	{
		this.topupIdentifier = topupIdentifier;
	}

	public void setVoucher(Voucher voucher)
	{
		this.voucher = voucher;
	}

	public void setVoucherDescription(String voucherDescription)
	{
		this.voucherDescription = voucherDescription;
	}

	public void setVoucherValid(boolean voucherValid)
	{
		this.voucherValid = voucherValid;
	}
}
