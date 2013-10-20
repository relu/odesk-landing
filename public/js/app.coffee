$ ->
  carousel = ->
    tiles = $('.tile')
    tileContainer = $('.tiles')
    tileWidth = tiles.outerWidth() + 10
    tileLength = tiles.length

    tileContainer.width(tileWidth * tileLength+"px")

    tiles.each ->
      self = $(this)

      self.animate left: self.position().left+'px', 'slow', ->
        self.css(position: 'absolute')

    if tileLength > 5
      $('.right-arrow').removeClass('disabled')

    $('.left-arrow, .right-arrow').click (evt)->
      evt.preventDefault()

      self = $(this)

      if tileContainer.hasClass('transitioning')
        return false

      if self.hasClass('disabled')
        return false

      tileContainer.addClass('transitioning')

      if self.hasClass('right-arrow')
        tiles.each ->
          $(this).css left: $(this).position().left - tileWidth
          $('.left-arrow').removeClass('disabled')

          if tiles.eq(0).position().left == -tileWidth * (tileLength - 6)
            $('.right-arrow').addClass('disabled')
      else
        tiles.each (idx)->
          $(this).css left: $(this).position().left + tileWidth
          $('.right-arrow').removeClass('disabled')

          if tiles.eq(0).position().left == -tileWidth
            $('.left-arrow').addClass('disabled')

    tiles.on 'webkitTransitionEnd otransitionend oTransitionEnd msTransitionEnd transitionend', ->
      if tileContainer.hasClass('transitioning')
        tileContainer.removeClass('transitioning')

  carousel()
