eca.widget("eca.booking.vehicle", ($win, $doc) ->

  this.Vehicle = class Vehicle
    constructor: (data, @segmentId) ->
      @modelId = data.modelId
      @modelAnchor = '#'+ data.modelId
      @acriss = data.acriss
      @category = eca.data.CAR_CATEGORIES[data.category.toLowerCase()]
      @imageSmall = "/carvisuals/135x90/#{data.greenwayId}_GWY_R.png"
      @imageMedium = "/carvisuals/270x180/#{data.greenwayId}_GWY_R.png"
      @imageBig = "/carvisuals/450x300/#{data.greenwayId}_GWY_R.png"
      @imageUpgrade = ko.observable()
      @name = data.name
      @seats = new Feature(data.seats)
      @luggage = new Feature(data.luggage)
      @doors = new Feature(data.doors)
      @aircondition = data.aircondition
      @emission = new Emission(data.emission, data.emissionLevel)
      @drive = new Drive(data.drive)
      @power = new Feature(data.power)
      @minimumAge = new Feature(data.minimumAge)
      @maximumWeight = new Feature(data.maximumWeight)
      @volume = new Feature(data.volume)
      @truck = data.truck is "Y"
      @twoCreditCards = data.twoCreditCards is "Y"
      @tooltip = "#{@name} - #{@acriss}"


  this.Feature = class Feature
    constructor: (@value) ->
      if @value
        @valueUndefined = false
      else
        @value = eca.i18n("feature.undefined")
        @valueUndefined = true


  this.Emission = class Emission
    constructor: (emission, emissionLevel) ->
      if emission
        @value = emission
        @klazz = "emission #{["emission", emissionLevel].join("_")} tooltip"
        @valueUndefined = false
      else
        @value = eca.i18n("feature.undefined")
        @klazz = "emission tooltip"
        @valueUndefined = true


  this.Drive = class Drive
    constructor: (drive) ->
      if drive
        @value = eca.data.CAR_DRIVES[drive.toLowerCase()]
        @klazz = "drive #{drive.toLowerCase()}"
        @valueUndefined = false
      else
        @value = eca.i18n("feature.undefined")
        @klazz = "drive"
        @valueUndefined = true


  this.Mileage = class Mileage
    constructor: () ->
      @originalValue = undefined
      @value = ko.observable()
      @description = ko.observable()
      @type = ko.observable()
      @additional = ko.observable()
      @label = ko.computed(() =>
        if @value()
          if @value() is 99999
            return eca.i18n("mileage.unlimited")
          else
            return "#{@description()} #{@type()}"
        else
          return eca.i18n("feature.undefined")
      )

    init: (localOriginalValue, localValue, localDescription, localType, localAdditional) ->
      @originalValue = localOriginalValue
      @value(localValue)
      @description(localDescription)
      @type(localType)
      @additional(localAdditional)

    set: (mileageOption) =>
      @value(mileageOption.value)
      @description(mileageOption.description)
      @type(mileageOption.type)
      @additional(mileageOption.additional)


  this.MileageOption = class MileageOption
    constructor: (data) ->
      @value = data.dis
      @description = data.mileageText
      @type = data.mileageType
      @additional = data.additionalMileageText
      @difference = data.costScr
      descriptionLabel = if @value is 99999 then eca.i18n("mileage.unlimited") else @description
      @label = if @difference then "#{descriptionLabel} (#{@difference})" else descriptionLabel


  this.Price = class Price
    constructor: () ->
      @onlinePrice = ko.observable()
      @onlineDisplayPrice = ko.observable()
      @onlineTotalDisplayPrice = ko.observable()
      @pickupPrice = ko.observable()
      @pickupDisplayPrice = ko.observable()
      @pickupTotalDisplayPrice = ko.observable()
      @prepaid = ko.observable()
      @prepaidChangeable = ko.observable()

      @currentPrice = ko.computed(() =>
        if @prepaid() is "Y" then @onlinePrice() else @pickupPrice()
      )
      @currentDisplayPrice = ko.computed(() =>
        if @prepaid() is "Y" then @onlineDisplayPrice() else @pickupDisplayPrice()
      )
      @currentTotalDisplayPrice = ko.computed(() =>
        if @prepaid() is "Y" then @onlineTotalDisplayPrice() else @pickupTotalDisplayPrice()
      )
      @otherPrice = ko.computed(() =>
        if @prepaid() is "Y" then @pickupPrice() else @onlinePrice()
      )
      @otherPrepaid = ko.computed(() =>
        if @prepaid() is "Y" then "N" else "Y"
      )

      @onlinePercentage = ko.computed(() =>
        return unless @onlinePrice() <= @pickupPrice()
        parseInt(100 * (@pickupPrice() - @onlinePrice()) / @pickupPrice(), 10)
      )
      @pickupPercentage = ko.computed(() =>
        return unless @onlinePrice() > @pickupPrice()
        parseInt(100 * (@onlinePrice() - @pickupPrice()) / @onlinePrice(), 10)
      )

    isPrepaid: () =>
      return @prepaid() is "Y"

    isNotPrepaid: () =>
      return @prepaid() isnt "Y"

    init: (localOnlinePrice, localOnlineDisplayPrice, localOnlineTotalDisplayPrice, localPickupPrice, localPickupDisplayPrice, localPickupTotalDisplayPrice, localPrepaid) ->
      @onlinePrice(localOnlinePrice)
      @onlineDisplayPrice(localOnlineDisplayPrice)
      @onlineTotalDisplayPrice(localOnlineTotalDisplayPrice)
      @pickupPrice(localPickupPrice)
      @pickupDisplayPrice(localPickupDisplayPrice)
      @pickupTotalDisplayPrice(localPickupTotalDisplayPrice)
      @prepaid(localPrepaid)
      @prepaidChangeable(localOnlinePrice and localPickupPrice and localOnlineTotalDisplayPrice isnt "0" and localPickupTotalDisplayPrice isnt "0")

    updateTotalPrice: (localOnlineTotalDisplayPrice, localPickupTotalDisplayPrice) =>
      @onlineTotalDisplayPrice(localOnlineTotalDisplayPrice)
      @pickupTotalDisplayPrice(localPickupTotalDisplayPrice)
      @prepaidChangeable(localOnlineTotalDisplayPrice isnt "0" and localPickupTotalDisplayPrice isnt "0")


  this.ExtraCluster = class ExtraCluster
    constructor: (@id, @clazz = "", @label, @trackingId) ->
      @disabled = true
      @extras = []

    addExtra: (code) ->
      @extras.push(code)
      @disabled = false


  this.Extra = class Extra
    constructor: (data, @index, @preselected) ->
      @id = data.ec
      @price = data.ep
      @displayPrice = if @price is "0.00" or @price is "0,00" then "Free" else data.epBScr
      @title = data.en
      @description = data.ad
      @excess = data.ee
      @quantity = ko.observable(parseInt(data.eq, 10))
      @selectedQuantity = if @quantity() > 0 then @quantity() else 1
      @maximumQuantity = parseInt(data.et, 10)
      @inclusive = data.incl is "Y"
      @availableOnRequest = data.onRequest is "Y"
      @availableOnConfirmedRequest = data.afterOnRequest is "Y"
      @disabled = @availableOnRequest is true and @availableOnConfirmedRequest is false
      @tc = data.tc
      @quantitiesSelectable = ko.computed(() =>
        @maximumQuantity? and @maximumQuantity > 0
      )
      @quantityAndTitle = ko.computed(() =>
        if @quantitiesSelectable() is true
          "#{@quantity()} #{@title}"
        else
          @title
      )

    text: () ->
      if @description? and @excess?
        """
        #{@description}

        #{@excess}
        """
      else if @description?
        @description
      else if @excess?
        @excess
      else
        ""

    tcParamName: () ->
      "cov[#{@index}]"

    idParamName: () ->
      "extra[#{@index}]"

    quantityParamName: () ->
      "quantity[#{@index}]"

    quantities: () ->
      quantity for quantity in [1..@maximumQuantity]

    setQuantity: () ->
      if @quantitiesSelectable() is true
        @quantity(@selectedQuantity)
      else
        @quantity(1)

    resetQuantity: () ->
      @quantity(0)

    isSelectedQuantityChanged: () ->
      @quantitiesSelectable() is true and @quantity() > 0 and @quantity() isnt @selectedQuantity


)
