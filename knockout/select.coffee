eca.widget("eca.booking.select", ($win, $doc) ->
  $body = $(document).find("body")
  return unless $body.hasClass("select")


  class ContentController
    constructor: ->
      @waiting = ko.observable(true)
      @errors = ko.observableArray()
      @segments = ko.observableArray()
      @activeSegmentId = ko.observable("")
      @activeSegmentCode = ko.observable("")
      @activeSorttype = ko.observable("")
      @vehicleControllers = ko.observableArray()
      @categoryVehicleControllers = ko.observableArray()
      @categoryVehicleControllersVisible = ko.observable(false)
      @numberOfVehicles = ko.observable("")
      @pages = ko.observableArray()
      @activePage = ko.observable()
      @includes = ko.observableArray()
      @withInsurance = ko.observable("")
      @segmentsVisible = ko.computed(() =>
        # show segments also in case of errors if segments are available and an active segment id is set
        @errors().length is 0 or (@segments().length > 0 and @activeSegmentId())
      )
      @vehicleAndRateDetailsConfig = new eca.booking.vehicleAndRateDetails.Config("/DotcarClient/slAlVehicles.action", true, true, true)
      @isFavoriteQuoteAvailable = ko.observable(true)
      @promoStickerController = new eca.booking.promoSticker.PromoStickerController()

      @init()
    
    init: () =>
      @promoStickerController.init($doc.find("#select").attr("data-promoId"))
      @fetch()

    adjustSearch: () =>
      eca.booking.search.form?.open()
    
    vehicleAndRateDetails: (vehicleController, event) => 
      parameters = {
        modelId: vehicleController.vehicle.modelId,
        segmentId: vehicleController.vehicle.segmentId
      }
      context = new eca.booking.vehicleAndRateDetails.Context(parameters, vehicleController.optionsController.mileageController.mileage, vehicleController.addToFavorites, vehicleController.removeFavorite, vehicleController.isFavorite, () =>
        @sendQuote(vehicleController, event)
      )
      eca.booking.vehicleAndRateDetails.show.apply(this, new Array(context, @vehicleAndRateDetailsConfig))
      
    sendQuote: (vehicleController, event) =>
      parameters = $(event.target).closest("form").serialize()
      eca.booking.sendQuote.show.apply(this, new Array(parameters))
 
    placeholder: (data, event) ->
      $(event.target).closest('.visual').addClass('noimg')

    editSearch: () ->
      eca.publish("search:open", true)

    activateSegment: (segment) =>
      if @activeSegmentId() isnt segment.id
        @activeSegmentId(segment.id)
        @activeSegmentCode(segment.code)
        @activePage(1)
        @fetch()

    activatePage: (page) =>
      if @activePage() isnt page and @pages.indexOf(page) isnt -1
        @activePage(page)
        @fetch()

    activatePreviousPage: () =>
      @activatePage(@activePage() - 1)

    activateNextPage: () =>
      @activatePage(@activePage() + 1)

    fetch: () ->
      @waiting(true)

      @vehicleControllers.removeAll()
      @segments.removeAll()
      @includes.removeAll()
      @errors.removeAll()
      @pages.removeAll()

      eca.booking.search.getSearchData((data) =>
        eca.storage.get("favoriteQuote", (favorite) =>
          eca.ajax.get(eca.data.SEGMENT_MODEL_ACTION_URL, {
            st: @activeSorttype(),
            si: @activeSegmentId(),
            pn: @activePage(),
            wi: @withInsurance(),
            __country: data.pickupcountry,
            _: new Date().getTime()
          }, (json) =>
            @errors.push(data.erm) for data in json.er
  
            @segments.push(new Segment(data)) for data in json.sg
            @activeSegmentId(json.si)
            @activeSegmentCode(json.sn)
  
            if @errors().length is 0
              for data in json.md
                if data.id is favorite?.modelId
                  @isFavoriteQuoteAvailable(true)
                  @vehicleControllers.push(new VehicleController(json.si, json.mi, data, favorite))
                else
                  @vehicleControllers.push(new VehicleController(json.si, json.mi, data))
              
              @includes.push(data) for data in json.rc
              @pages.push(parseInt(page, 10)) for page in [1..json.mp]
              @numberOfVehicles(json.nb)
              @withInsurance(json.wi)
  
              @activeSorttype(json.st)
              @activePage(parseInt(json.pn, 10))
  
              @initCategoryVehicleControllers()
  
              $doc.find("#interstitial").addClass("hidden")
              $doc.find("#step2").removeClass("hidden")
  
              @waiting(false)
            else
              @waiting(false)
          , () =>
            @errors.push(eca.i18n("system.unavailable"))
            @waiting(false)
          )
        )
        eca.storage.remove("favoriteQuote")
      )

    initCategoryVehicleControllers: () ->
      @categoryVehicleControllers.removeAll()

      categories = []
      for vehicleController in @vehicleControllers()
        if _.indexOf(categories, vehicleController.vehicle.category) is -1 and @categoryVehicleControllers().length < 6
          categories.push(vehicleController.vehicle.category)
          @categoryVehicleControllers.push(vehicleController)

      @categoryVehicleControllersVisible(categories.length >= 2 and @vehicleControllers().length >= 3)

    getVehicleController: (modelId) =>
      return vehicleController for vehicleController in @vehicleControllers() when vehicleController.vehicle.modelId is modelId

    sort: (type) =>
      if @activeSorttype() isnt type
        @activeSorttype(type)
        @fetch()
        
    sortByPrice: () =>
      @sort('PRICE')
        
    sortBySize: () =>
      @sort('SIZE')
        
    toggleInsurance: (value) =>
      if @withInsurance() isnt value
        @withInsurance(value)
        @fetch()
        
    includeInsurance: () =>
      @toggleInsurance('Y')
        
    excludeInsurance: () =>
      @toggleInsurance('N')


  class Segment
    constructor: (data) ->
      @id = data.id
      @code = data.cd
      @name = data.nm


  class VehicleController
    constructor: (segmentId, preSelectedModelId, data, favorite) ->
      @vehicle = new eca.booking.vehicle.Vehicle({
        modelId: data.id,
        greenwayId: data.greenwayId,
        acriss: data.ac,
        category: data.cc,
        name: data.nm,
        seats: data.pn,
        luggage: data.lc,
        doors: data.dn,
        aircondition: data.ar,
        emission: data.ce,
        emissionLevel: data.cl,
        drive: data.tt,
        power: data.po,
        minimumAge: data.ma,
        maximumWeight: data.mw,
        volume: data.lv,
        truck: data.tk,
        twoCreditCards: data.twoCreditCards
      }, segmentId)
      @preselected = @vehicle.modelId is preSelectedModelId

      @lowAvailability = data.or is "Y"
      @availableOnRequest = data.ortd is "Y"

      @priceController = new PriceController(data)
      
      updateCallBack = () =>
        @priceController.update(@vehicle, @optionsController.mileageController.mileage, @optionsController.extrasController.extras())
      @optionsController = new eca.booking.options.OptionsController(updateCallBack, updateCallBack)

      @bookingDisabled = ko.computed(() =>
        @availableOnRequest is true or @priceController.errors().length > 0 or @priceController.waiting() is true
      )

      @initOptionsController(data, favorite)
      @favorite = ko.observable({isVisibleFavorite:ko.observable(false)})
      @isFavorite = ko.computed(() => @favorite().isVisibleFavorite())
      this.loadFavorite()
      
    initOptionsController: (data, favorite) =>
      mileageData = undefined
      if @priceController.price.prepaid() is "Y"
        value = if data.miPn then parseInt(data.miPn, 10) else undefined
        mileageData = {
          originalValue: value,
          value: value, 
          description: data.miPnScr,
          type: data.miPnType,
          additional: data.amPn
        }
      else
        value = if data.miPas then parseInt(data.miPas, 10) else undefined
        mileageData = {
          originalValue: value,
          value: value, 
          description: data.miPasScr,
          type: data.miPasType,
          additional: data.amPas
        }
      @optionsController.init(@vehicle, @priceController.price, mileageData, new Array(), @availableOnRequest, @preselected or favorite?, () =>
        @optionsController.selectOptions(favorite.extras, favorite.mileage) if favorite?
      )

    book: (data, event) =>
      eca.storage.remove("bookAndPay")
      eca.storage.remove("youngDriver")
      eca.storage.remove("confirm")
    
      model = {
        price: {
          onlinePrice: @priceController.price.onlinePrice(),
          onlineDisplayPrice: @priceController.price.onlineDisplayPrice(),
          onlineTotalDisplayPrice: @priceController.price.onlineTotalDisplayPrice(),
          pickupPrice: @priceController.price.pickupPrice(),
          pickupDisplayPrice: @priceController.price.pickupDisplayPrice(),
          pickupTotalDisplayPrice: @priceController.price.pickupTotalDisplayPrice(),
          prepaid: @priceController.price.prepaid()
        },
        mileage: {
          originalValue: @optionsController.mileageController.mileage.originalValue,
          value: @optionsController.mileageController.mileage.value(),
          description: @optionsController.mileageController.mileage.description(),
          type: @optionsController.mileageController.mileage.type(),
          additional: @optionsController.mileageController.mileage.additional()
        },
        modelId: @vehicle.modelId,
        segmentId: @vehicle.segmentId,
        promoId: $doc.find("#select").attr("data-promoId")
      }
      eca.storage.save('select', model, () =>
        event.target.submit()
      )

    loadFavorite: () =>
      eca.favorites.api.getFavorite(@vehicle.modelId, (fav) => @favorite(fav))
      
    addToFavorites: (ctx, e) =>
      mileage = @optionsController.mileageController.mileage
      eca.favorites.api.add(
          @vehicle,
          @optionsController.extrasController.selectedExtras(),
          mileage.value(),
          @priceController.price.currentTotalDisplayPrice()
        )
      # reload favorite to trigger ko.computed
      this.loadFavorite()
    
    removeFavorite: (ctx, e) =>
      @favorite().remove()
      @favorite({isVisibleFavorite:ko.observable(false)})

  class PriceController
    constructor: (data) ->
      @errors = ko.observableArray()
      @price = new eca.booking.vehicle.Price()
      @waitingThreads = ko.observable(0)
      @waiting = ko.computed(() =>
        @waitingThreads() > 0
      )

      @init(data)

    init: (data) ->
      localOnlinePrice = if data.ol then parseFloat(data.ol) else undefined
      localOnlineDisplayPrice = data.olScr
      localOnlineTotalDisplayPrice = data.olScr
      localPickupPrice = if data.oc then parseFloat(data.oc) else undefined
      localPickupDisplayPrice = data.ocScr
      localPickupTotalDisplayPrice = data.ocScr
      localPrepaid = if localOnlinePrice and (not localPickupPrice or localOnlinePrice <= localPickupPrice) then "Y" else "N"

      @price.init(localOnlinePrice, localOnlineDisplayPrice, localOnlineTotalDisplayPrice, localPickupPrice, localPickupDisplayPrice, localPickupTotalDisplayPrice, localPrepaid)

    update: (vehicle, mileage, extras) =>
      @errors.removeAll()
      @waitingThreads(@waitingThreads() + 1)

      parameters = {
        modelId: vehicle.modelId,
        fCollectPrice1: @price.currentPrice(),
        prepaid: @price.prepaid(),
        segmentId: vehicle.segmentId,
        mil: mileage.value()
      }
      for extra in extras
        parameters[extra.tcParamName()] = extra.tc
        parameters[extra.idParamName()] = extra.id
        parameters[extra.quantityParamName()] = extra.quantity()

      eca.ajax.get("/DotcarClient/updatePrices.action", parameters, (json) =>
        @errors.push(data) for data in json.er
        @price.updateTotalPrice(json.payOnLinePrice, json.payOnAgencyPrice) if @errors().length <= 0
        @waitingThreads(@waitingThreads() - 1)
      , () =>
        @errors.push(eca.i18n("system.unavailable"))
        @waitingThreads(@waitingThreads() - 1)
      )


  ko.applyBindings(new ContentController(), document.getElementById("select"))
)
