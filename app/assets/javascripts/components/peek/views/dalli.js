import $ from 'jquery';

$(document).on('peek:render', function(event, requestId, data) {
  var title;
  title = [];
  title.push("Reads: " + data.context.dalli.reads);
  title.push("Misses: " + data.context.dalli.misses);
  title.push("Writes: " + data.context.dalli.writes);
  title.push("Other: " + data.context.dalli.others);
  return $('#peek-dalli-tooltip').attr('title', title.join('<br>')).tipsy({
    html: true,
    gravity: $.fn.tipsy.autoNS
  });
});
