// Generated by CoffeeScript 1.6.3
(function() {
  $(function() {
    var carousel, formSubmit, scrollCount, searchSuggest;
    carousel = function() {
      var handle, tileContainer, tileLength, tileWidth, tiles;
      tiles = $('.tile');
      tileContainer = $('.tiles');
      tileWidth = tiles.outerWidth() + 10;
      tileLength = tiles.length;
      tileContainer.addClass('slow').width(tileWidth * tileLength + "px");
      tiles.each(function() {
        var self;
        self = $(this);
        return self.animate({
          left: self.position().left + 'px'
        }, 'slow', function() {
          return self.css({
            position: 'absolute'
          });
        });
      });
      if (tileLength > Math.ceil($('.contractors .wrapper').outerWidth() / tileWidth)) {
        $('.right-arrow').removeClass('disabled');
      }
      handle = function(evt) {
        var firstTile, ftIndex, ftTile, self, tilecount;
        evt.preventDefault();
        tileContainer.removeClass('slow');
        self = $(this);
        if (tileContainer.hasClass('transitioning')) {
          return false;
        }
        if (self.hasClass('disabled')) {
          return false;
        }
        tileContainer.addClass('transitioning');
        firstTile = tiles.first();
        ftIndex = -firstTile.position().left / tileWidth;
        tilecount = $('.contractors .wrapper').outerWidth() / tileWidth;
        if (self.hasClass('right-arrow') || evt.type.indexOf('swipeleft') !== -1) {
          ftTile = tiles.eq(ftIndex);
          ftTile.addClass('fast');
          return tiles.each(function() {
            $(this).css({
              left: $(this).position().left - tileWidth
            });
            $('.left-arrow').removeClass('disabled');
            if (tiles.eq(0).position().left === -tileWidth * (tileLength - tilecount - 1)) {
              return $('.right-arrow').addClass('disabled');
            }
          });
        } else {
          ftTile = tiles.eq(ftIndex + tilecount - 1);
          ftTile.addClass('fast');
          return tiles.each(function(idx) {
            $(this).css({
              left: $(this).position().left + tileWidth
            });
            $('.right-arrow').removeClass('disabled');
            if (tiles.eq(0).position().left === -tileWidth) {
              return $('.left-arrow').addClass('disabled');
            }
          });
        }
      };
      tiles.on('swiperight swipeleft ', function(evt) {
        if ($('.right-arrow').hasClass('disabled') && evt.type.indexOf('swipeleft') !== -1) {
          return;
        } else if ($('.left-arrow').hasClass('disabled') && evt.type.indexOf('swiperight') !== -1) {
          return;
        }
        return handle.call(this, evt);
      });
      $('.left-arrow, .right-arrow').on('click', function(evt) {
        return handle.call(this, evt);
      });
      return $('.tile:not(.fast)').on('webkitTransitionEnd otransitionend oTransitionEnd msTransitionEnd transitionend', function() {
        if (tileContainer.hasClass('transitioning')) {
          tileContainer.removeClass('transitioning');
          return tiles.removeClass('fast');
        }
      });
    };
    scrollCount = function() {
      var input;
      input = $('[name=scroll_count]');
      return $('.right-arrow, .left-arrow').click(function() {
        return input.val(parseInt(input.val()) + 1);
      });
    };
    formSubmit = function() {
      return $('.the-form form').submit(function() {
        var self;
        self = $(this);
        $.post('/send?' + self.serialize(), function(content) {
          return $('.the-form').find('form, h1').fadeOut(function() {
            return $('.the-form').html(content).fadeIn();
          });
        });
        return false;
      });
    };
    searchSuggest = function(input) {
      var $input, form, suggestList;
      $input = $(input);
      suggestList = $("<ul id='suggest-list' class='suggest-list'/>").hide();
      $input.after(suggestList);
      form = $input.parents('form');
      $input.keyup(function() {
        var val;
        val = $input.val().replace(/\s+$/, '');
        if (val.length < 3) {
          return;
        }
        return $.get('/autocomplete.json', {
          q: val
        }, function(response) {
          suggestList.empty().hide();
          $(response).each(function(i, term) {
            var c, text;
            text = term.replace(val, "<strong>" + val + "</strong>");
            if (val === term) {
              c = 'current';
            } else {
              c = '';
            }
            return suggestList.append("<li data-term='" + term + "' class='" + c + "'>" + text + "</li>");
          });
          return suggestList.show();
        });
      });
      return suggestList.on('click', 'li', function() {
        $input.val($(this).data('term'));
        suggestList.hide();
        return form.submit();
      });
    };
    carousel();
    scrollCount();
    formSubmit();
    return searchSuggest('#q');
  });

}).call(this);