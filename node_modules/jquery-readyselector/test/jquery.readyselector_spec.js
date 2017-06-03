var chai      = require("chai"),
    sinon     = require("sinon"),
    sinonChai = require("sinon-chai"),
    jsdom     = require("jsdom"),
    jQuery    = require("jQuery");

chai.should();
chai.use(sinonChai);

var window = jsdom.jsdom().createWindow(),
  document = window.document;

var $ = global.jQuery = jQuery.create(window);
$('body').addClass('body-class');

require("../jquery.readyselector");

describe("$.fn.ready", function() {
  beforeEach(function() {
    this.callback = sinon.spy();
  });

  it("calls the callback when bound with $(document).ready(@callback)", function() {
    $(document).ready(this.callback);
    this.callback.should.have.been.called;
    this.callback.thisValues.should.eql([document]);
  });

  it("calls the callback when bound with $(@callback)", function() {
    $(this.callback);
    this.callback.should.have.been.called;
    this.callback.thisValues.should.eql([document]);
  });

  it("calls the callback when bound with $().ready(@callback)", function() {
    $().ready(this.callback);
    this.callback.should.have.been.called;
    this.callback.thisValues.should.eql([document]);
  });

  it("calls the callback if the given selector is present", function() {
    $('.body-class').ready(this.callback);
    this.callback.should.have.been.called;
  });

  it("does not call the callback if the given selector is not present", function() {
    $('#nonesuch').ready(this.callback);
    this.callback.should.not.have.been.called;
  });

  it("calls the callback with the correct context", function() {
    $('.body-class').ready(this.callback);
    this.callback.thisValues.should.eql($('body').get());
  });

  it("calls the callback for each matching element", function() {
    $('body').html('<div id="a"></div><div id="b"></div>');
    $('body div').ready(this.callback);
    this.callback.thisValues.should.eql($('body div').get());
  });

  it("calls the callback for a delayed selection", function() {
    var selection = $('nonesuch');
    selection.selector = '.body-class';
    selection.ready(this.callback);
    this.callback.thisValues.should.eql($('body').get());
  });
});
