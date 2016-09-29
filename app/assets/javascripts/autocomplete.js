(function() {
  var delay, highlight_next_item, highlight_previous_item, ready, scroll_element_to_visible, set_suggestions_visible, update_textfield;

  delay = (function() {
    var timer;
    timer = 0;
    return function(callback, ms) {
      clearTimeout(timer);
      timer = setTimeout(callback, ms);
    };
  })();

  update_textfield = function(list_element) {
    $(list_element).removeClass('suggestion-focused');
    $('.js-autocomplete-textfield').val($(list_element).data('res-name'));
    return $('.js-autocomplete-resource-id').val($(list_element).data('res-id'));
  };

  set_suggestions_visible = function(visible) {
    if (visible) {
      return $('.js-autocomplete-suggestions-container').show();
    } else {
      $('.js-autocomplete-suggestions-container').hide();
      return $('.js-autocomplete-suggestions-list').html('');
    }
  };

  scroll_element_to_visible = function(element, container) {
    var container_height, container_scrollbar_offset, element_height, element_top;
    container_scrollbar_offset = $(container).scrollTop();
    container_height = $(container).outerHeight();
    element_top = $(element).offset().top - $(element).offsetParent().offset().top;
    element_height = $(element).outerHeight();
    if (element_top < container_scrollbar_offset || element_top + element_height > container_scrollbar_offset + container_height) {
      return element.scrollIntoView();
    }
  };

  highlight_next_item = function() {
    var highlighted_items, item, nextItem;
    highlighted_items = $('.js-autocomplete-suggestion-item.highlighted');
    if (highlighted_items.length === 0) {
      item = $('.js-autocomplete-suggestion-item').first();
    } else {
      nextItem = $(highlighted_items[0]).next();
      if (nextItem.length > 0) {
        $(highlighted_items).removeClass('highlighted');
        item = nextItem.first();
      }
    }
    if (item && item.length === 1) {
      item.addClass('highlighted');
      return scroll_element_to_visible(item[0], $('.js-autocomplete-suggestions-container')[0]);
    }
  };

  highlight_previous_item = function() {
    var highlighted_items, item, prevItem;
    highlighted_items = $('.js-autocomplete-suggestion-item.highlighted');
    prevItem = $(highlighted_items[0]).prev();
    if (prevItem.length > 0) {
      $(highlighted_items).removeClass('highlighted');
      item = prevItem.first();
    }
    if (item && item.length === 1) {
      item.addClass('highlighted');
      return scroll_element_to_visible(item[0], $('.js-autocomplete-suggestions-container')[0]);
    }
  };

  ready = function() {
    $('.js-autocomplete-textfield').on('input', function() {
      var query, textfield;
      $('.js-autocomplete-resource-id').removeAttr('value');
      if (!(query = this.value.trim())) {
        set_suggestions_visible(false);
        return;
      }
      textfield = this;
      $('.js-autocomplete-suggestions-list').html('');
      set_suggestions_visible(true);
      return delay((function() {
        return $.get("/autocomplete/" + ($(textfield).data('autocomplete-search-endpoint')) + "?query=" + query, function(data) {
          if (!(query === textfield.value.trim() && $(textfield).is(':focus'))) {
            return;
          }
          $('.js-autocomplete-suggestions-list').html(data);
          $('.js-autocomplete-suggestion-item').click(function() {
            update_textfield(this);
            return set_suggestions_visible(false);
          });
          $('.js-autocomplete-suggestion-item').hover(function() {
            return $(this).addClass('highlighted');
          }, function() {
            return $(this).removeClass('highlighted');
          });
          return set_suggestions_visible(true);
        });
      }), 500);
    });
    $('.js-autocomplete-textfield').on('keydown', function(event) {
      if (event.keyCode === 13) {
        event.preventDefault();
        return false;
      }
    });
    $('.js-autocomplete-textfield').on('keyup', function(event) {
      var highlighted_items;
      if (event.ctrlKey || event.metaKey || event.shiftKey) {
        return;
      }
      switch (event.keyCode) {
        case 13:
          highlighted_items = $('.js-autocomplete-suggestion-item.highlighted');
          if (highlighted_items.length === 1) {
            update_textfield(highlighted_items[0]);
            return set_suggestions_visible(false);
          }
          break;
        case 27:
          return set_suggestions_visible(false);
        case 38:
          return highlight_previous_item();
        case 40:
          return highlight_next_item();
      }
    });

    // Behavior:
    //   keep the suggestion list when:
    //     - right clicking
    //     - click js-autocomplete-textfield
    //     - click js-autocomplete-suggestion-item and its children
    //   dismiss the suggestion list when:
    //     - js-autocomplete-textfield and user click other element
    //     - focus other elements
    return $('.js-autocomplete-textfield').on('blur', function(event) {
      if (event.relatedTarget) {
        return set_suggestions_visible(false);
      }
    });
  };

  $(document).ready(ready);

  $(document).on('mousedown', function(event) {
    if (event.button === 2 || $(event.target).hasClass('js-autocomplete-suggestion-item') || $(event.target).parents('.js-autocomplete-suggestion-item').length > 0 || $(event.target).hasClass('js-autocomplete-textfield')) {
      return;
    }
    if ($('.js-autocomplete-textfield').is(':focus')) {
      return set_suggestions_visible(false);
    }
  });
}).call(this);
