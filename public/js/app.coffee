$ ->
  carousel = ->
    tiles = $('.tile')
    tileContainer = $('.tiles')
    tileWidth = tiles.outerWidth() + 10
    tileLength = tiles.length

    tileContainer
      .addClass('slow')
      .width(tileWidth * tileLength+"px")

    tiles.each ->
      self = $(this)

      self.animate left: self.position().left+'px', 'slow', ->
        self.css(position: 'absolute')

    if tileLength > Math.ceil($('.contractors .wrapper').outerWidth() / tileWidth)
      $('.right-arrow').removeClass('disabled')

    handle = (evt)->
      evt.preventDefault()

      tileContainer.removeClass('slow')

      self = $(this)

      if tileContainer.hasClass('transitioning')
        return false

      if self.hasClass('disabled')
        return false

      tileContainer.addClass('transitioning')

      firstTile = tiles.first()
      ftIndex = -firstTile.position().left / tileWidth

      tilecount = $('.contractors .wrapper').outerWidth() / tileWidth

      if self.hasClass('right-arrow') || evt.type == 'swipeleft'
        ftTile = tiles.eq(ftIndex)
        ftTile.addClass('fast')

        tiles.each ->
          $(this).css left: $(this).position().left - tileWidth
          $('.left-arrow').removeClass('disabled')

          if tiles.eq(0).position().left == -tileWidth * (tileLength - tilecount - 1)
            $('.right-arrow').addClass('disabled')
      else
        ftTile = tiles.eq(ftIndex + tilecount - 1)
        ftTile.addClass('fast')

        tiles.each (idx)->
          $(this).css left: $(this).position().left + tileWidth
          $('.right-arrow').removeClass('disabled')

          if tiles.eq(0).position().left == -tileWidth
            $('.left-arrow').addClass('disabled')

    tiles.on 'swiperight swipeleft', (evt)->
      if $('.right-arrow').hasClass('disabled') && evt.type == 'swipeleft'
        return
      else if $('.left-arrow').hasClass('disabled') && evt.type == 'swiperight'
        return

      handle.call(this, evt)

    $('.left-arrow, .right-arrow').on 'click', (evt)->
      handle.call(this, evt)

    $('.tile:not(.fast)').on 'webkitTransitionEnd otransitionend oTransitionEnd msTransitionEnd transitionend', ->
      if tileContainer.hasClass('transitioning')
        tileContainer.removeClass('transitioning')
        tiles.removeClass('fast')

  scrollCount = ->
    input = $('[name=scroll_count]')
    $('.right-arrow, .left-arrow').click ->
     input.val parseInt(input.val()) + 1

  formSubmit = ->
    $('.the-form form').submit ->
      self = $(this)

      $.post '/send?'+self.serialize(), (content)->
        $('.the-form').find('form, h1').fadeOut ->
          $('.the-form').html(content).fadeIn()

      return false

  searchSuggest = (input)->
    $input = $(input)
    suggestList = $("<ul id='suggest-list' class='suggest-list'/>").hide()
    $input.after(suggestList)
    form = $input.parents('form')

    $input.keyup ->
      val = $input.val().replace(/\s+$/, '')

      if val.length < 3
        return

      $.get '/autocomplete.json', q: val, (response)->
        suggestList.empty().hide()
        $(response).each (i, term)->
          text = term.replace(val, "<strong>#{val}</strong>")

          if val == term
            c = 'current'
          else
            c = ''

          suggestList.append("<li data-term='#{term}' class='#{c}'>#{text}</li>")

        suggestList.show()

    suggestList.on 'click', 'li', ->
      $input.val($(this).data('term'))
      suggestList.hide()
      form.submit()

  carousel()
  scrollCount()
  formSubmit()
  searchSuggest('#q')
