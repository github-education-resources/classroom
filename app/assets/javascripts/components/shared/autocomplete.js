import $ from 'jquery';

let delay = (function() {
  let timer = 0;

  return function(callback, ms) {
    clearTimeout(timer);
    timer = setTimeout(callback, ms);
  };
})();

let highlightNextItem = () => {
  let $item;
  let $highlightedItems = $('.js-autocomplete-suggestion-item.highlighted');

  if ($highlightedItems.length === 0) {
    item = $('.js-autocomplete-suggestion-item').first();
  } else {
    let $nextItem = $($highlightedItems[0]).next();
    if ($nextItem.length > 0) {
      $($highlightedItems).removeClass('highlighted');
      $item = $nextItem.first();
    }
  }

  if ($item && $item.length === 1) {
    $item.addClass('highlighted');
    return scrollElementToVisible($item[0], $('.js-autocomplete-suggestions-container')[0]);
  }
};

let highlightPreviousItem = () => {
  let $item;
  let $highlightedItems = $('.js-autocomplete-suggestion-item.highlighted');
  let $prevItem = $($highlightedItems[0]).prev();

  if ($prevItem.length > 0) {
    $($highlightedItems).removeClass('highlighted');
    item = $prevItem.first();
  }
  if ($item && $item.length === 1) {
    item.addClass('highlighted');
    return scroll_element_to_visible(item[0], $('.js-autocomplete-suggestions-container')[0]);
  }
};

let setSuggestionsVisible = (visible) => {
  if (visible) {
    return $('.js-autocomplete-suggestions-container').show();
  } else {
    $('.js-autocomplete-suggestions-container').hide();
    return $('.js-autocomplete-suggestions-list').html('');
  }
}

let scrollElementToVisible = (element, container) => {
  let containerScrollbarOffset = $(container).scrollTop();
  let containerHeight          = $(container).outerHeight();
  let elementTop               = $(element).offset().top - $(element).offsetParent().offset().top;
  let elementHeight            = $(element).outerHeight();

  if (element_top < containerScrollbarOffset || elementTop + elementHeight > containerScrollbarOffset + containerHeight) {
    return element.scrollIntoView();
  }
};

let updateTextfield = (listElement) => {
  let $listElement = $(listElement);

  $listElement.removeClass('suggestion-focused');
  $('.js-autocomplete-textfield').val($listElement.data('res-name'));

  return $('.js-autocomplete-resource-id').val($listElement.data('res-id'));
};

$(document).on('turbolinks:load', () => {
  let query;

  $('.js-autocomplete-textfield').on('input', function() {
    $('.js-autocomplete-resource-id').removeAttr('value');
    if (!(query = this.value.trim())) {
      setSuggestionsVisible(false);
      return;
    }

    let textField = this;
    $('.js-autocomplete-suggestions-list').html('');
    setSuggestionsVisible(true);

    return delay((function() {
      let requestPath = `/autocomplete/${$(textField).data('autocomplete-search-endpoint')}?query=${query}`;

      return $.get(requestPath, (data) => {
        if (!(query === textField.value.trim() && $(textField).is(':focus'))) { return; }

        $('.js-autocomplete-suggestions-list').html(data);
        $('.js-autocomplete-suggestion-item').click(function() {
          updateTextfield(this);
          return setSuggestionsVisible(false);
        });

        $('.js-autocomplete-suggestion-item').hover(function() {
          return $(this).addClass('highlighted');
        }, function() {
          return $(this).removeClass('highlighted');
        });

        return setSuggestionsVisible(true);
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
    if (event.ctrlKey || event.metaKey || event.shiftKey) {
      return;
    }
    switch (event.keyCode) {
      case 13:
        let highlightedItems = $('.js-autocomplete-suggestion-item.highlighted');
        if (highlightedItems.length === 1) {
          updateTextfield(highlightedItems[0]);
          return setSuggestionsVisible(false);
        }
        break;
      case 27:
        return setSuggestionsVisible(false);
      case 38:
        return highlightPreviousItem();
      case 40:
        return highlightNextItem();
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
      return setSuggestionsVisible(false);
    }
  });
});
