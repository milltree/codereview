eca.widget("eca.bookAndPay.content", ($win, $doc) ->
  $body = $(document).find("body")
  return unless $body.hasClass("book")
  
  
  class ContentController
    constructor: () ->
      @vehicle = ko.observable()
      @upgradeImage = ko.observable()
      @pickupCountry = undefined
      @errors = ko.observableArray()
      
      @formController = new eca.bookAndPay.form.FormController()
      @prepaidController = new PrepaidController(@formController)
      @couponController = new eca.bookAndPay.coupon.CouponController(@prepaidController, @formController)
      @basketController = new BasketController()
      @logoutController = new LogoutController()
      @promoStickerController = new eca.booking.promoSticker.PromoStickerController()
      
      @$options = $doc.find("ul#basketOptions").first()
      @optionsChosen = ko.observable(false)
      @mileageChosen = ko.observable(false)
      @mileageLabel = ko.observable()
      @updateOptionsController = new UpdateOptionsController(@formController, @couponController, @refreshOptionsChosen, @initUpgradeImage)
      @optionsController = new eca.booking.options.OptionsController(() =>
        @updateOptionsController.update(@vehicle(), @prepaidController.price, @optionsController.mileageController.mileage, @optionsController.extrasController.extras)
      )
      
      @youngDriverController = new eca.bookAndPay.youngDriver.YoungDriverController(@optionsController, @refreshOptionsChosen)
      @confirmController = new eca.bookAndPay.formsubmit.ConfirmController(@youngDriverController.minimumAgeController, @formController, @storeConfirmData)
      
      @initWaiting = ko.observable(true)
      @upgradeWaiting = ko.observable(false)
      
      @waiting = ko.computed(() =>
        @initWaiting() is true or
        @upgradeWaiting() is true or
        @optionsController.initFetchWaiting() is true or
        @prepaidController.submitWaiting() is true or
        @logoutController.submitWaiting() is true or
        @formController.waiting() is true
      )
      
      @confirmDisabled = ko.computed(() =>
        # disable while the basket is reloading after changing the selected options or when an error is returned on change of the selected options or while the payment choice is changing
        @updateOptionsController.errors().length > 0 or @updateOptionsController.waiting() is true or 
        @prepaidController.changeWaiting() is true or
        @formController.requiredFieldsController.confirmDisabled() is true
      )
      @paymentChoiceDisabled = ko.computed(() =>
        # disable while new selected payment choice is loading or while the total price is updated after changing the selected options
        @updateOptionsController.updateWaiting() is true or
        @prepaidController.changeWaiting() is true
      )
      @upgradeDisabled = ko.computed(() =>
        # disable while the basket is reloading after changing the selected options or while the payment choice is changing
        @updateOptionsController.waiting() is true or 
        @prepaidController.changeWaiting() is true
      )
      
      @$termsAndConditions = $doc.find("input[name=europcarTermsAndConditions]")
      @confirmErrorVisible = ko.observable(false)
      @confirmDisabled.subscribe((newValue) =>
        @confirmErrorVisible(false) if newValue is false
      )
      
      @vehicleAndRateDetailsConfig = new eca.booking.vehicleAndRateDetails.Config("/DotcarClient/bpMoreVehicleDetails.action", false, false, false)

      @init()

    init: () ->
      @initWaiting(true)
      @errors.removeAll()

      eca.storage.get("search", (search) =>
        if search
          @pickupCountry = search.pickupcountry
          @initSelectData()
        else
          @initSystemError()
      )

    initSelectData: () =>
      eca.storage.get("select", (model) =>
        if model
          @prepaidController.init(model.price, @pickupCountry)
          @initVehicleData(model.segmentId, model.mileage)
          @initUpgradeImage()
          @promoStickerController.init(model.promoId)
        else
          @initSystemError()
      )

    initVehicleData: (segmentId, mileageData) =>
      modelId = $doc.find("div#cardetails").attr("data-modelId")

      recommendedExtras = new Array()
      recommendedExtras.push($extra.getAttribute("data-extraId")) for $extra in $doc.find("div#recommendations a.extra")

      eca.ajax.get("/DotcarClient/vehicleData.json", {
        pickupCountry: @pickupCountry,
        modelId: modelId,
        _: new Date().getTime()
      }, (json) =>
        if json
          @errors.push(error) for error in json.errors

          if @errors().length <= 0
            @vehicle(new eca.booking.vehicle.Vehicle(json, segmentId))
            @updateOptionsController.init()
            @optionsController.init(@vehicle(), @prepaidController.price, mileageData, recommendedExtras, false, true, () =>
              @refreshOptionsChosen()
              @formController.init(() =>
                @youngDriverController.init()
              )
            )
            
          @initWaiting(false)
        else
          @initSystemError()
      , () =>
        @initSystemError()
      )

    initUpgradeImage: () =>
      upgradeId = $doc.find("div#upgradeContainer").data("modelid")
      if upgradeId
        eca.ajax.get("/DotcarClient/vehicleData.json", {
          pickupCountry: @pickupCountry,
          modelId: upgradeId,
          _: new Date().getTime()
        }, (json) =>
          @upgradeImage("/carvisuals/135x90/#{json?.greenwayId}_GWY_R.png")
        )
      else
        @upgradeImage(undefined)

    initSystemError: () =>
      @errors.push(eca.i18n("system.unavailable"))
      @initWaiting(false)
      
    refreshOptionsChosen: () =>
      mileage = @optionsController.mileageController.mileage
      @mileageChosen(mileage.originalValue isnt mileage.value())
      @mileageLabel(mileage.label())
      # @basketController.resizeBasket()

      extras = @$options.find("li:not(#basketMileage):not(#noOptions)").size()
      @optionsChosen(extras > 0 or @mileageChosen() is true)

    vehicleAndRateDetails: (data, event) => 
      $target = $(event.target).closest('*[data-modelid]')
      parameters = {
        'modelId': $target.data("modelid"),
        ug: $target.data("upgrade")
      }
      context = new eca.booking.vehicleAndRateDetails.Context(parameters, @optionsController.mileageController.mileage)
      eca.booking.vehicleAndRateDetails.show.apply(this, new Array(context, @vehicleAndRateDetailsConfig))

    showRecommendedExtra: (data, event) =>
      extraId = $(event.target).attr("data-extraId")
      @optionsController.showOptionsByExtra(extraId)

    placeholder: (data, event) ->
      $(event.target).closest('.visual').addClass('noimg')

    editSearch: () ->
      eca.publish("search:open", true)

    toggleContent: (data, event) ->
      $(event.target).toggleClass('open').nextAll('.content').first().slideToggle('fast')

    changePrepaidToYes: () =>
      if @paymentChoiceDisabled() is false
        @prepaidController.changeToYes(@vehicle(), @optionsController.mileageController.mileage)
      return false

    changePrepaidToNo: () =>
      if @paymentChoiceDisabled() is false
        @prepaidController.changeToNo(@vehicle(), @optionsController.mileageController.mileage)
      return false

    upgrade: (data, event) =>
      return unless @upgradeDisabled() is false
      @upgradeWaiting(true)
      @formController.storeFormData(() =>
        event.target.submit()
      )

    confirm: () =>
      if @confirmDisabled() is true
        @confirmErrorVisible(true)
        @$termsAndConditions.change()
      else
        @confirmController.confirm()

    storeConfirmData: (cb) =>
      confirmdata = {
        prepaid: @prepaidController.price.prepaid(),
        mileage: {
          originalValue: @optionsController.mileageController.mileage.originalValue,
          value: @optionsController.mileageController.mileage.value(),
          description: @optionsController.mileageController.mileage.description(),
          type: @optionsController.mileageController.mileage.type(),
          additional: @optionsController.mileageController.mileage.additional()
        },
        modelId: @vehicle().modelId,
        segmentId: @vehicle().segmentId
      }
      eca.storage.save("confirm", confirmdata, () =>
        cb() if cb?
      )


  class UpdateOptionsController
    constructor: (@formController, @couponController, @refreshOptionsChosen, @initUpgradeImage) ->
      @errors = ko.observableArray()
      @updateWaiting = ko.observable(false)
      @waitingFrameId = ko.observable()
      @waiting = ko.computed(() =>
        @waitingFrameId()?
      )
      
    init: () =>
      @$options = $doc.find("ul#basketOptions").first()
      @$includes = $doc.find("ul#basketIncludes").first()
      @$excludesContainer = $doc.find("div#basketExcludesContainer").first()
      @$cancellation = $doc.find("div#basketCancellation").first()
      @$bookingFees = $doc.find("div#basketBookingFees").first()
      @$prices = $doc.find("ul.price")
      @$cardType = $doc.find("form#reservationForm select[name=cardType]").first()
      @$upgrade = $doc.find("div#upgradeContainer").first()
      @$recommendations = $doc.find("div#recommendationsContainer").first()
      
      @$vehicle = $doc.find("div#cardetails").first()
      @$submitForm = $doc.find("form#updateOptionsForm").first()
      @$frames = $doc.find("div#updateOptionsFrame").first()
      
    update: (vehicle, price, mileage, extras) =>
      @updateWaiting(true)
      @errors.removeAll()
      
      parameters = {
        modelId: vehicle.modelId,
        segmentId: vehicle.segmentId,
        fCollectPrice1: price.currentPrice(),
        prepaid: price.prepaid(),
        mil: mileage.value()
      }
      for extra in extras()
        parameters[extra.tcParamName()] = extra.tc
        parameters[extra.idParamName()] = extra.id
        parameters[extra.quantityParamName()] = extra.quantity()

      eca.ajax.get("/DotcarClient/updatePrices.action", parameters, (json) =>
        @errors.push(data) for data in json.er
        
        if @errors().length <= 0
          price.updateTotalPrice(json.payOnLinePrice, json.payOnAgencyPrice)
          @updateSelectData(vehicle, mileage, price)
          
          frameId = "frame#{new Date().getTime()}"
          @$frames.append("<iframe id=\"#{frameId}\" src=\"about:blank\" name=\"#{frameId}\"></iframe>")
          @$frames.find("iframe##{frameId}").load(() =>
            @frameLoaded(frameId)
          )
          @$submitForm.attr("target", frameId)
          @$submitForm.submit()
          @waitingFrameId(frameId)
        else
          @waitingFrameId(undefined)
          
        @updateWaiting(false)
      , () =>
        @errors.push(eca.i18n("system.unavailable"))
        @updateWaiting(false)
        @waitingFrameId(undefined)
      )

    updateSelectData: (vehicle, mileage, price) =>
      model = {
        price: {
          onlinePrice: price.onlinePrice(),
          onlineDisplayPrice: price.onlineDisplayPrice(),
          onlineTotalDisplayPrice: price.onlineTotalDisplayPrice(),
          pickupPrice: price.pickupPrice(),
          pickupDisplayPrice: price.pickupDisplayPrice(),
          pickupTotalDisplayPrice: price.pickupTotalDisplayPrice(),
          prepaid: price.prepaid()
        },
        mileage: {
          originalValue: mileage.originalValue,
          value: mileage.value(),
          description: mileage.description(),
          type: mileage.type(),
          additional: mileage.additional()
        },
        segmentId: vehicle.segmentId
      }
      eca.storage.save('select', model)

    frameLoaded: (frameId) =>
      frame = @$frames.find("iframe##{frameId}")
      return unless frame.size() > 0
      
      if frameId is @waitingFrameId()
        @updatePageContent(frame)
        @waitingFrameId(undefined)
      
      # frame.remove()

    updatePageContent: (frame) =>
      rootContext = ko.contextFor(@$vehicle.get(0)).$root

      if frame.contents().find("ul#basketOptions").size() > 0
        @$options.find("li:not(#basketMileage):not(#noOptions):not(#unknownExtra)").remove()
        frame.contents().find("ul#basketOptions li:not(#basketMileage):not(#noOptions):not(#unknownExtra)").each((index, option) => 
          @$options.append("<li>" + $(option).html() + "</li>")
        )
        @refreshOptionsChosen()
      
      if frame.contents().find("ul#basketIncludes").size() > 0
        @$includes.children().remove()
        @$includes.append(frame.contents().find("ul#basketIncludes").html())
      
      if frame.contents().find("ul#basketExcludes").size() > 0
        @$excludesContainer.find("ul#basketExcludes").children().remove()
        @$excludesContainer.find("ul#basketExcludes").append(frame.contents().find("ul#basketExcludes").html())
        
        if @$excludesContainer.find("ul#basketExcludes li").size() > 0
          @$excludesContainer.removeClass("hidden")
        else
          @$excludesContainer.addClass("hidden")
        
      if frame.contents().find("div#basketCancellation").size() > 0
        @$cancellation.children().remove()
        @$cancellation.append(frame.contents().find("div#basketCancellation").html())
        
      if frame.contents().find("div#basketBookingFees").size() > 0
        @$bookingFees.children().remove()
        @$bookingFees.append(frame.contents().find("div#basketBookingFees").html())
        
      if frame.contents().find("ul.price").size() > 0
        @$prices.children().remove()
        @$prices.append(frame.contents().find("ul.price").first().html())
        @$prices.each((index, element) =>
          ko.applyBindings(rootContext, element)
        )
        
      currentCardType = @$cardType.val()
      if frame.contents().find("form#reservationForm select[name=cardType]").size() > 0
        @$cardType.children().remove()
        @$cardType.append(frame.contents().find("form#reservationForm select[name=cardType]").html())
        @$cardType.val(currentCardType)
        
      @$upgrade.children().remove()
      if frame.contents().find("div#upgradeContainer").first().children().size() > 0
        @$upgrade.append(frame.contents().find("div#upgradeContainer").first().html())
        @$upgrade.data("modelid", @$upgrade.find("#upgrade .visual").data("modelid"))
        ko.applyBindings(rootContext, @$upgrade.get(0))
        @updateUpgradeImage()
        
      @$recommendations.children().remove()
      if frame.contents().find("div#recommendationsContainer").first().children().size() > 0
        @$recommendations.append(frame.contents().find("div#recommendationsContainer").first().html())
        ko.applyBindings(rootContext, @$recommendations.get(0))
      
      @formController.creditCardController.refresh()
      @couponController.init()


  class PrepaidController
    constructor: (@formController) ->
      @price = new eca.booking.vehicle.Price()
      @pickupCountry = undefined
      @errors = ko.observableArray()
      @extras = ko.observableArray()
      @changeWaiting = ko.observable(false)
      @submitWaiting = ko.observable(false)
      @$submitForm = $doc.find("form#changePrepaidForm")
      @$reservationForm = $doc.find("form#reservationForm")

    init: (data, localPickupCountry) =>
      @price.init(data.onlinePrice, data.onlineDisplayPrice, data.onlineTotalDisplayPrice, data.pickupPrice, data.pickupDisplayPrice, data.pickupTotalDisplayPrice, data.prepaid)
      @pickupCountry = localPickupCountry

    changeToYes: (vehicle, mileage) =>
      return if @price.isPrepaid()
      @change(vehicle, mileage)

    changeToNo: (vehicle, mileage) =>
      return if @price.isNotPrepaid()
      @change(vehicle, mileage)

    change: (vehicle, mileage) =>
      @changeWaiting(true)
      @errors.removeAll()
      @extras.removeAll()

      eca.ajax.get("/DotcarClient/extras.action", {
        ac: vehicle.acriss,
        fCollectPrice1: @price.otherPrice(),
        prepaid: @price.otherPrepaid(),
        modelId: vehicle.modelId,
        segmentId: vehicle.segmentId,
        _: new Date().getTime()
      }, (json) =>
        @errors.push(data) for data in json.er

        if @errors().length <= 0
          @extras.push(new eca.booking.vehicle.Extra(data, i)) for data, i in json.ex
          @validatePrices(vehicle, mileage, () =>
            @submit(vehicle, mileage)
          )
        else
          @changeWaiting(false)
      , () =>
        @errors.push(eca.i18n("system.unavailable"))
        @changeWaiting(false)
      )

    validatePrices: (vehicle, mileage, success) =>
      parameters = {
        modelId: vehicle.modelId,
        segmentId: vehicle.segmentId,
        fCollectPrice1: @price.otherPrice(),
        prepaid: @price.otherPrepaid(),
        mil: mileage.value()
      }
      for extra in @extras()
        parameters[extra.tcParamName()] = extra.tc
        parameters[extra.idParamName()] = extra.id
        parameters[extra.quantityParamName()] = extra.quantity()

      eca.ajax.get("/DotcarClient/updatePrices.action", parameters, (json) =>
        @errors.push(data) for data in json.er
        if @errors().length <= 0
          success()
        else
          @changeWaiting(false)
      , () =>
        @errors.push(eca.i18n("system.unavailable"))
        @changeWaiting(false)
      )

    submit: (vehicle, mileage) =>
      model = {
        price: {
          onlinePrice: @price.onlinePrice(),
          onlineDisplayPrice: @price.onlineDisplayPrice(),
          onlineTotalDisplayPrice: @price.onlineTotalDisplayPrice(),
          pickupPrice: @price.pickupPrice(),
          pickupDisplayPrice: @price.pickupDisplayPrice(),
          pickupTotalDisplayPrice: @price.pickupTotalDisplayPrice(),
          prepaid: @price.otherPrepaid()
        },
        mileage: {
          originalValue: mileage.originalValue,
          value: mileage.value(),
          description: mileage.description(),
          type: mileage.type(),
          additional: mileage.additional()
        },
        segmentId: vehicle.segmentId
      }
      eca.storage.save('select', model, () =>
        @formController.storeFormData( () =>
          @submitWaiting(true)
          @$submitForm.submit()
        )
      )


  class BasketController
    constructor: () ->
      @documentHeight = undefined
      @basketHeight = undefined
      @headerHeight = $("#large_header").outerHeight() + $("#enquiry").outerHeight()
      @footerHeight = $("#footer").outerHeight() + $(".pagetools").outerHeight()
      @fixedPos = ko.observable(false)
      @bottomPos = ko.observable(false)

      # $win.on('scroll', () =>
      #   window.setTimeout(
      #     () => @updatePosition()
      #   , 200)
      # )
      # 
      # $win.on('resize', () =>
      #   @updatePosition()
      # )

    resizeBasket: () =>
      unless @basketHeight then return
      @basketHeight = $('#basket .quote').outerHeight()
      @updatePosition()

    updatePosition: () =>
      @documentHeight = @documentHeight or $doc.height()
      @basketHeight = @basketHeight or $('#basket .quote').outerHeight()

      @fixedPos((@basketHeight + @headerHeight) <= $win.scrollTop())
      @bottomPos((@documentHeight - $win.scrollTop()) <= (@footerHeight + @priceHeight))


  class LogoutController
    constructor: () ->
      @lightbox = undefined
      @waiting = ko.observable(true)
      @submitWaiting = ko.observable(false)
      @errors = ko.observableArray()
      @$logoutLink = $doc.find("div#loginTypes a.nfeLogout")
      @$countrySelect = $doc.find("select#countryOfResidence")
      @$lightboxNode = $doc.find("div#lbContract")
      @$logoutForm = $doc.find("form#logoutForm")
      @$logoutBackForm = $doc.find("form#logoutBackForm")
      @$reservationForm = $doc.find("form#reservationForm")
      @$formContainer = $doc.find("div#formContainer")
      
      @$logoutLink.on("click", () =>
        @logout()
      )
      @$lightboxNode.find("button.alt-button").on("click", () => 
        @lightbox.close(true)
      )
      @$lightboxNode.find("button.default-button").on("click", () => 
        @change()
      )
      
    logout: () =>
      if @$formContainer.attr("data-hasContractNumber") is 'true'
        @show()
      else
        @submitWaiting(true)
        @$logoutForm.submit()
    
    show: () =>
      unless @lightbox
        eca.lightbox.fromnode(@$lightboxNode, (lb) =>
          @lightbox = lb.klazz("contract").open()
          @fill()
        )
      else
        @lightbox.open()
        @fill()
    
    fill: () =>
      @waiting(true)
      @errors.removeAll()
      
      eca.ajax.get("/DotcarClient/getLogoutStep3NewPriceAction.action", {
        corId: @$countrySelect.val()
      }, (json) =>
        if !json.noRateFoundMessage
          # formatted price + message "estimated..."
          @$lightboxNode.find("#amount2").html(json.amount)
          @$lightboxNode.find("#priceMessage2").html(json.priceMessage)
          
          # formatted checkout price + message "guaranteed..."
          @$lightboxNode.find("#checkoutAmount2").html(json.checkoutAmount)
          @$lightboxNode.find("#checkoutMessage2").html(json.checkoutMessage) 
          
          # payment type
          @$lightboxNode.find("#paymentMethodMessage2").html(json.paymentMethodMessage)
          
          @$lightboxNode.find("#rateFound2").css("display", "block")
          @$lightboxNode.find("#noRateFound2").css("display", "none")
          @$lightboxNode.find("#buttonWhenRateFound2").css("display", "block")
          @$lightboxNode.find("#buttonWhenNoRateFound2").css("display", "none")
        else
          @$lightboxNode.find("#rateFound2").css("display", "none")
          @$lightboxNode.find("#noRateFound2").css("display", "block")
          @$lightboxNode.find("#buttonWhenRateFound2").css("display", "none")
          @$lightboxNode.find("#buttonWhenNoRateFound2").css("display", "block")
        
        @waiting(false)
      , () =>
        @errors.push(eca.i18n("system.unavailable"))
        @waiting(false)
      )
      
    change: () =>
      @submitWaiting(true)
      @$logoutBackForm.submit()
      
      @lightbox.close(true)


  ko.applyBindings(new ContentController(), document.getElementById("book"))

)

