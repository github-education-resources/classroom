'use strict';

exports.__esModule = true;

var _comment = require('postcss/lib/comment');

var _comment2 = _interopRequireDefault(_comment);

var _parser = require('postcss/lib/parser');

var _parser2 = _interopRequireDefault(_parser);

var _nestedDeclaration = require('./nested-declaration');

var _nestedDeclaration2 = _interopRequireDefault(_nestedDeclaration);

var _scssTokenize = require('./scss-tokenize');

var _scssTokenize2 = _interopRequireDefault(_scssTokenize);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

function _possibleConstructorReturn(self, call) { if (!self) { throw new ReferenceError("this hasn't been initialised - super() hasn't been called"); } return call && (typeof call === "object" || typeof call === "function") ? call : self; }

function _inherits(subClass, superClass) { if (typeof superClass !== "function" && superClass !== null) { throw new TypeError("Super expression must either be null or a function, not " + typeof superClass); } subClass.prototype = Object.create(superClass && superClass.prototype, { constructor: { value: subClass, enumerable: false, writable: true, configurable: true } }); if (superClass) Object.setPrototypeOf ? Object.setPrototypeOf(subClass, superClass) : subClass.__proto__ = superClass; }

var ScssParser = function (_Parser) {
    _inherits(ScssParser, _Parser);

    function ScssParser() {
        _classCallCheck(this, ScssParser);

        return _possibleConstructorReturn(this, _Parser.apply(this, arguments));
    }

    ScssParser.prototype.createTokenizer = function createTokenizer() {
        this.tokenizer = (0, _scssTokenize2.default)(this.input);
    };

    ScssParser.prototype.rule = function rule(tokens) {
        var withColon = false;
        var brackets = 0;
        var value = '';
        for (var _iterator = tokens, _isArray = Array.isArray(_iterator), _i = 0, _iterator = _isArray ? _iterator : _iterator[Symbol.iterator]();;) {
            var _ref;

            if (_isArray) {
                if (_i >= _iterator.length) break;
                _ref = _iterator[_i++];
            } else {
                _i = _iterator.next();
                if (_i.done) break;
                _ref = _i.value;
            }

            var i = _ref;

            if (withColon) {
                if (i[0] !== 'comment' && i[0] !== '{') {
                    value += i[1];
                }
            } else if (i[0] === 'space' && i[1].indexOf('\n') !== -1) {
                break;
            } else if (i[0] === '(') {
                brackets += 1;
            } else if (i[0] === ')') {
                brackets -= 1;
            } else if (brackets === 0 && i[0] === ':') {
                withColon = true;
            }
        }

        if (!withColon || value.trim() === '' || /^[a-zA-Z-:#]/.test(value)) {
            _Parser.prototype.rule.call(this, tokens);
        } else {

            tokens.pop();
            var node = new _nestedDeclaration2.default();
            this.init(node);

            var last = tokens[tokens.length - 1];
            if (last[4]) {
                node.source.end = { line: last[4], column: last[5] };
            } else {
                node.source.end = { line: last[2], column: last[3] };
            }

            while (tokens[0][0] !== 'word') {
                node.raws.before += tokens.shift()[1];
            }
            node.source.start = { line: tokens[0][2], column: tokens[0][3] };

            node.prop = '';
            while (tokens.length) {
                var type = tokens[0][0];
                if (type === ':' || type === 'space' || type === 'comment') {
                    break;
                }
                node.prop += tokens.shift()[1];
            }

            node.raws.between = '';

            var token = void 0;
            while (tokens.length) {
                token = tokens.shift();

                if (token[0] === ':') {
                    node.raws.between += token[1];
                    break;
                } else {
                    node.raws.between += token[1];
                }
            }

            if (node.prop[0] === '_' || node.prop[0] === '*') {
                node.raws.before += node.prop[0];
                node.prop = node.prop.slice(1);
            }
            node.raws.between += this.spacesAndCommentsFromStart(tokens);
            this.precheckMissedSemicolon(tokens);

            for (var _i2 = tokens.length - 1; _i2 > 0; _i2--) {
                token = tokens[_i2];
                if (token[1] === '!important') {
                    node.important = true;
                    var string = this.stringFrom(tokens, _i2);
                    string = this.spacesFromEnd(tokens) + string;
                    if (string !== ' !important') {
                        node.raws.important = string;
                    }
                    break;
                } else if (token[1] === 'important') {
                    var cache = tokens.slice(0);
                    var str = '';
                    for (var j = _i2; j > 0; j--) {
                        var _type = cache[j][0];
                        if (str.trim().indexOf('!') === 0 && _type !== 'space') {
                            break;
                        }
                        str = cache.pop()[1] + str;
                    }
                    if (str.trim().indexOf('!') === 0) {
                        node.important = true;
                        node.raws.important = str;
                        tokens = cache;
                    }
                }

                if (token[0] !== 'space' && token[0] !== 'comment') {
                    break;
                }
            }

            this.raw(node, 'value', tokens);

            if (node.value.indexOf(':') !== -1) {
                this.checkMissedSemicolon(tokens);
            }

            this.current = node;
        }
    };

    ScssParser.prototype.comment = function comment(token) {
        if (token[6] === 'inline') {
            var node = new _comment2.default();
            this.init(node, token[2], token[3]);
            node.raws.inline = true;
            node.source.end = { line: token[4], column: token[5] };

            var text = token[1].slice(2);
            if (/^\s*$/.test(text)) {
                node.text = '';
                node.raws.left = text;
                node.raws.right = '';
            } else {
                var match = text.match(/^(\s*)([^]*[^\s])(\s*)$/);
                var fixed = match[2].replace(/(\*\/|\/\*)/g, '*//*');
                node.text = fixed;
                node.raws.left = match[1];
                node.raws.right = match[3];
                node.raws.text = match[2];
            }
        } else {
            _Parser.prototype.comment.call(this, token);
        }
    };

    return ScssParser;
}(_parser2.default);

exports.default = ScssParser;
module.exports = exports['default'];
//# sourceMappingURL=data:application/json;charset=utf8;base64,eyJ2ZXJzaW9uIjozLCJzb3VyY2VzIjpbInNjc3MtcGFyc2VyLmVzNiJdLCJuYW1lcyI6WyJTY3NzUGFyc2VyIiwiY3JlYXRlVG9rZW5pemVyIiwidG9rZW5pemVyIiwiaW5wdXQiLCJydWxlIiwidG9rZW5zIiwid2l0aENvbG9uIiwiYnJhY2tldHMiLCJ2YWx1ZSIsImkiLCJpbmRleE9mIiwidHJpbSIsInRlc3QiLCJwb3AiLCJub2RlIiwiaW5pdCIsImxhc3QiLCJsZW5ndGgiLCJzb3VyY2UiLCJlbmQiLCJsaW5lIiwiY29sdW1uIiwicmF3cyIsImJlZm9yZSIsInNoaWZ0Iiwic3RhcnQiLCJwcm9wIiwidHlwZSIsImJldHdlZW4iLCJ0b2tlbiIsInNsaWNlIiwic3BhY2VzQW5kQ29tbWVudHNGcm9tU3RhcnQiLCJwcmVjaGVja01pc3NlZFNlbWljb2xvbiIsImltcG9ydGFudCIsInN0cmluZyIsInN0cmluZ0Zyb20iLCJzcGFjZXNGcm9tRW5kIiwiY2FjaGUiLCJzdHIiLCJqIiwicmF3IiwiY2hlY2tNaXNzZWRTZW1pY29sb24iLCJjdXJyZW50IiwiY29tbWVudCIsImlubGluZSIsInRleHQiLCJsZWZ0IiwicmlnaHQiLCJtYXRjaCIsImZpeGVkIiwicmVwbGFjZSJdLCJtYXBwaW5ncyI6Ijs7OztBQUFBOzs7O0FBQ0E7Ozs7QUFFQTs7OztBQUNBOzs7Ozs7Ozs7Ozs7SUFFcUJBLFU7Ozs7Ozs7Ozt5QkFFakJDLGUsOEJBQWtCO0FBQ2QsYUFBS0MsU0FBTCxHQUFpQiw0QkFBYyxLQUFLQyxLQUFuQixDQUFqQjtBQUNILEs7O3lCQUVEQyxJLGlCQUFLQyxNLEVBQVE7QUFDVCxZQUFJQyxZQUFZLEtBQWhCO0FBQ0EsWUFBSUMsV0FBWSxDQUFoQjtBQUNBLFlBQUlDLFFBQVksRUFBaEI7QUFDQSw2QkFBZUgsTUFBZixrSEFBd0I7QUFBQTs7QUFBQTtBQUFBO0FBQUE7QUFBQTtBQUFBO0FBQUE7QUFBQTtBQUFBOztBQUFBLGdCQUFkSSxDQUFjOztBQUNwQixnQkFBS0gsU0FBTCxFQUFpQjtBQUNiLG9C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QUFYO0FBQ0EsZ0JBQUssUUFBUWxCLElBQVIsQ0FBYWlDLElBQWIsQ0FBTCxFQUEwQjtBQUN0Qi9CLHFCQUFLK0IsSUFBTCxHQUFrQixFQUFsQjtBQUNBL0IscUJBQUtRLElBQUwsQ0FBVXdCLElBQVYsR0FBa0JELElBQWxCO0FBQ0EvQixxQkFBS1EsSUFBTCxDQUFVeUIsS0FBVixHQUFrQixFQUFsQjtBQUNILGFBSkQsTUFJTztBQUNILG9CQUFJQyxRQUFRSCxLQUFLRyxLQUFMLENBQVcseUJBQVgsQ0FBWjtBQUNBLG9CQUFJQyxRQUFRRCxNQUFNLENBQU4sRUFBU0UsT0FBVCxDQUFpQixjQUFqQixFQUFpQyxNQUFqQyxDQUFaO0FBQ0FwQyxxQkFBSytCLElBQUwsR0FBa0JJLEtBQWxCO0FBQ0FuQyxxQkFBS1EsSUFBTCxDQUFVd0IsSUFBVixHQUFrQkUsTUFBTSxDQUFOLENBQWxCO0FBQ0FsQyxxQkFBS1EsSUFBTCxDQUFVeUIsS0FBVixHQUFrQkMsTUFBTSxDQUFOLENBQWxCO0FBQ0FsQyxxQkFBS1EsSUFBTCxDQUFVdUIsSUFBVixHQUFrQkcsTUFBTSxDQUFOLENBQWxCO0FBQ0g7QUFDSixTQW5CRCxNQW1CTztBQUNILDhCQUFNTCxPQUFOLFlBQWNkLEtBQWQ7QUFDSDtBQUNKLEs7Ozs7O2tCQWhKZ0I3QixVIiwiZmlsZSI6InNjc3MtcGFyc2VyLmpzIiwic291cmNlc0NvbnRlbnQiOlsiaW1wb3J0IENvbW1lbnQgZnJvbSAncG9zdGNzcy9saWIvY29tbWVudCc7XG5pbXBvcnQgUGFyc2VyICBmcm9tICdwb3N0Y3NzL2xpYi9wYXJzZXInO1xuXG5pbXBvcnQgTmVzdGVkRGVjbGFyYXRpb24gZnJvbSAnLi9uZXN0ZWQtZGVjbGFyYXRpb24nO1xuaW1wb3J0IHNjc3NUb2tlbml6ZXIgICAgIGZyb20gJy4vc2Nzcy10b2tlbml6ZSc7XG5cbmV4cG9ydCBkZWZhdWx0IGNsYXNzIFNjc3NQYXJzZXIgZXh0ZW5kcyBQYXJzZXIge1xuXG4gICAgY3JlYXRlVG9rZW5pemVyKCkge1xuICAgICAgICB0aGlzLnRva2VuaXplciA9IHNjc3NUb2tlbml6ZXIodGhpcy5pbnB1dCk7XG4gICAgfVxuXG4gICAgcnVsZSh0b2tlbnMpIHtcbiAgICAgICAgbGV0IHdpdGhDb2xvbiA9IGZhbHNlO1xuICAgICAgICBsZXQgYnJhY2tldHMgID0gMDtcbiAgICAgICAgbGV0IHZhbHVlICAgICA9ICcnO1xuICAgICAgICBmb3IgKCBsZXQgaSBvZiB0b2tlbnMgKSB7XG4gICAgICAgICAgICBpZiAoIHdpdGhDb2xvbiApIHtcbiAgICAgICAgICAgICAgICBpZiAoIGlbMF0gIT09ICdjb21tZW50JyAmJiBpWzBdICE9PSAneycgKSB7XG4gICAgICAgICAgICAgICAgICAgIHZhbHVlICs9IGlbMV07XG4gICAgICAgICAgICAgICAgfVxuICAgICAgICAgICAgfSBlbHNlIGlmICggaVswXSA9PT0gJ3NwYWNlJyAmJiBpWzFdLmluZGV4T2YoJ1xcbicpICE9PSAtMSApIHtcbiAgICAgICAgICAgICAgICBicmVhaztcbiAgICAgICAgICAgIH0gZWxzZSBpZiAoIGlbMF0gPT09ICcoJyApIHtcbiAgICAgICAgICAgICAgICBicmFja2V0cyArPSAxO1xuICAgICAgICAgICAgfSBlbHNlIGlmICggaVswXSA9PT0gJyknICkge1xuICAgICAgICAgICAgICAgIGJyYWNrZXRzIC09IDE7XG4gICAgICAgICAgICB9IGVsc2UgaWYgKCBicmFja2V0cyA9PT0gMCAmJiBpWzBdID09PSAnOicgKSB7XG4gICAgICAgICAgICAgICAgd2l0aENvbG9uID0gdHJ1ZTtcbiAgICAgICAgICAgIH1cbiAgICAgICAgfVxuXG4gICAgICAgIGlmICggIXdpdGhDb2xvbiB8fCB2YWx1ZS50cmltKCkgPT09ICcnIHx8IC9eW2EtekEtWi06I10vLnRlc3QodmFsdWUpICkge1xuICAgICAgICAgICAgc3VwZXIucnVsZSh0b2tlbnMpO1xuICAgICAgICB9IGVsc2Uge1xuXG4gICAgICAgICAgICB0b2tlbnMucG9wKCk7XG4gICAgICAgICAgICBsZXQgbm9kZSA9IG5ldyBOZXN0ZWREZWNsYXJhdGlvbigpO1xuICAgICAgICAgICAgdGhpcy5pbml0KG5vZGUpO1xuXG4gICAgICAgICAgICBsZXQgbGFzdCA9IHRva2Vuc1t0b2tlbnMubGVuZ3RoIC0gMV07XG4gICAgICAgICAgICBpZiAobGFzdFs0XSkge1xuICAgICAgICAgICAgICAgIG5vZGUuc291cmNlLmVuZCA9IHsgbGluZTogbGFzdFs0XSwgY29sdW1uOiBsYXN0WzVdIH07XG4gICAgICAgICAgICB9IGVsc2Uge1xuICAgICAgICAgICAgICAgIG5vZGUuc291cmNlLmVuZCA9IHsgbGluZTogbGFzdFsyXSwgY29sdW1uOiBsYXN0WzNdIH07XG4gICAgICAgICAgICB9XG5cbiAgICAgICAgICAgIHdoaWxlICh0b2tlbnNbMF1bMF0gIT09ICd3b3JkJykge1xuICAgICAgICAgICAgICAgIG5vZGUucmF3cy5iZWZvcmUgKz0gdG9rZW5zLnNoaWZ0KClbMV07XG4gICAgICAgICAgICB9XG4gICAgICAgICAgICBub2RlLnNvdXJjZS5zdGFydCA9IHsgbGluZTogdG9rZW5zWzBdWzJdLCBjb2x1bW46IHRva2Vuc1swXVszXSB9O1xuXG4gICAgICAgICAgICBub2RlLnByb3AgPSAnJztcbiAgICAgICAgICAgIHdoaWxlICh0b2tlbnMubGVuZ3RoKSB7XG4gICAgICAgICAgICAgICAgbGV0IHR5cGUgPSB0b2tlbnNbMF1bMF07XG4gICAgICAgICAgICAgICAgaWYgKHR5cGUgPT09ICc6JyB8fCB0eXBlID09PSAnc3BhY2UnIHx8IHR5cGUgPT09ICdjb21tZW50Jykge1xuICAgICAgICAgICAgICAgICAgICBicmVhaztcbiAgICAgICAgICAgICAgICB9XG4gICAgICAgICAgICAgICAgbm9kZS5wcm9wICs9IHRva2Vucy5zaGlmdCgpWzFdO1xuICAgICAgICAgICAgfVxuXG4gICAgICAgICAgICBub2RlLnJhd3MuYmV0d2VlbiA9ICcnO1xuXG4gICAgICAgICAgICBsZXQgdG9rZW47XG4gICAgICAgICAgICB3aGlsZSAodG9rZW5zLmxlbmd0aCkge1xuICAgICAgICAgICAgICAgIHRva2VuID0gdG9rZW5zLnNoaWZ0KCk7XG5cbiAgICAgICAgICAgICAgICBpZiAodG9rZW5bMF0gPT09ICc6Jykge1xuICAgICAgICAgICAgICAgICAgICBub2RlLnJhd3MuYmV0d2VlbiArPSB0b2tlblsxXTtcbiAgICAgICAgICAgICAgICAgICAgYnJlYWs7XG4gICAgICAgICAgICAgICAgfSBlbHNlIHtcbiAgICAgICAgICAgICAgICAgICAgbm9kZS5yYXdzLmJldHdlZW4gKz0gdG9rZW5bMV07XG4gICAgICAgICAgICAgICAgfVxuICAgICAgICAgICAgfVxuXG4gICAgICAgICAgICBpZiAobm9kZS5wcm9wWzBdID09PSAnXycgfHwgbm9kZS5wcm9wWzBdID09PSAnKicpIHtcbiAgICAgICAgICAgICAgICBub2RlLnJhd3MuYmVmb3JlICs9IG5vZGUucHJvcFswXTtcbiAgICAgICAgICAgICAgICBub2RlLnByb3AgPSBub2RlLnByb3Auc2xpY2UoMSk7XG4gICAgICAgICAgICB9XG4gICAgICAgICAgICBub2RlLnJhd3MuYmV0d2VlbiArPSB0aGlzLnNwYWNlc0FuZENvbW1lbnRzRnJvbVN0YXJ0KHRva2Vucyk7XG4gICAgICAgICAgICB0aGlzLnByZWNoZWNrTWlzc2VkU2VtaWNvbG9uKHRva2Vucyk7XG5cbiAgICAgICAgICAgIGZvciAobGV0IGkgPSB0b2tlbnMubGVuZ3RoIC0gMTsgaSA+IDA7IGktLSkge1xuICAgICAgICAgICAgICAgIHRva2VuID0gdG9rZW5zW2ldO1xuICAgICAgICAgICAgICAgIGlmICh0b2tlblsxXSA9PT0gJyFpbXBvcnRhbnQnKSB7XG4gICAgICAgICAgICAgICAgICAgIG5vZGUuaW1wb3J0YW50ID0gdHJ1ZTtcbiAgICAgICAgICAgICAgICAgICAgbGV0IHN0cmluZyA9IHRoaXMuc3RyaW5nRnJvbSh0b2tlbnMsIGkpO1xuICAgICAgICAgICAgICAgICAgICBzdHJpbmcgPSB0aGlzLnNwYWNlc0Zyb21FbmQodG9rZW5zKSArIHN0cmluZztcbiAgICAgICAgICAgICAgICAgICAgaWYgKHN0cmluZyAhPT0gJyAhaW1wb3J0YW50Jykge1xuICAgICAgICAgICAgICAgICAgICAgICAgbm9kZS5yYXdzLmltcG9ydGFudCA9IHN0cmluZztcbiAgICAgICAgICAgICAgICAgICAgfVxuICAgICAgICAgICAgICAgICAgICBicmVhaztcblxuICAgICAgICAgICAgICAgIH0gZWxzZSBpZiAodG9rZW5bMV0gPT09ICdpbXBvcnRhbnQnKSB7XG4gICAgICAgICAgICAgICAgICAgIGxldCBjYWNoZSA9IHRva2Vucy5zbGljZSgwKTtcbiAgICAgICAgICAgICAgICAgICAgbGV0IHN0ciAgID0gJyc7XG4gICAgICAgICAgICAgICAgICAgIGZvciAobGV0IGogPSBpOyBqID4gMDsgai0tKSB7XG4gICAgICAgICAgICAgICAgICAgICAgICBsZXQgdHlwZSA9IGNhY2hlW2pdWzBdO1xuICAgICAgICAgICAgICAgICAgICAgICAgaWYgKHN0ci50cmltKCkuaW5kZXhPZignIScpID09PSAwICYmXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgdHlwZSAhPT0gJ3NwYWNlJ1xuICAgICAgICAgICAgICAgICAgICAgICAgKSB7XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgYnJlYWs7XG4gICAgICAgICAgICAgICAgICAgICAgICB9XG4gICAgICAgICAgICAgICAgICAgICAgICBzdHIgPSBjYWNoZS5wb3AoKVsxXSArIHN0cjtcbiAgICAgICAgICAgICAgICAgICAgfVxuICAgICAgICAgICAgICAgICAgICBpZiAoc3RyLnRyaW0oKS5pbmRleE9mKCchJykgPT09IDApIHtcbiAgICAgICAgICAgICAgICAgICAgICAgIG5vZGUuaW1wb3J0YW50ID0gdHJ1ZTtcbiAgICAgICAgICAgICAgICAgICAgICAgIG5vZGUucmF3cy5pbXBvcnRhbnQgPSBzdHI7XG4gICAgICAgICAgICAgICAgICAgICAgICB0b2tlbnMgPSBjYWNoZTtcbiAgICAgICAgICAgICAgICAgICAgfVxuICAgICAgICAgICAgICAgIH1cblxuICAgICAgICAgICAgICAgIGlmICh0b2tlblswXSAhPT0gJ3NwYWNlJyAmJiB0b2tlblswXSAhPT0gJ2NvbW1lbnQnKSB7XG4gICAgICAgICAgICAgICAgICAgIGJyZWFrO1xuICAgICAgICAgICAgICAgIH1cbiAgICAgICAgICAgIH1cblxuICAgICAgICAgICAgdGhpcy5yYXcobm9kZSwgJ3ZhbHVlJywgdG9rZW5zKTtcblxuICAgICAgICAgICAgaWYgKG5vZGUudmFsdWUuaW5kZXhPZignOicpICE9PSAtMSkge1xuICAgICAgICAgICAgICAgIHRoaXMuY2hlY2tNaXNzZWRTZW1pY29sb24odG9rZW5zKTtcbiAgICAgICAgICAgIH1cblxuICAgICAgICAgICAgdGhpcy5jdXJyZW50ID0gbm9kZTtcbiAgICAgICAgfVxuICAgIH1cblxuICAgIGNvbW1lbnQodG9rZW4pIHtcbiAgICAgICAgaWYgKHRva2VuWzZdID09PSAnaW5saW5lJykge1xuICAgICAgICAgICAgbGV0IG5vZGUgPSBuZXcgQ29tbWVudCgpO1xuICAgICAgICAgICAgdGhpcy5pbml0KG5vZGUsIHRva2VuWzJdLCB0b2tlblszXSk7XG4gICAgICAgICAgICBub2RlLnJhd3MuaW5saW5lID0gdHJ1ZTtcbiAgICAgICAgICAgIG5vZGUuc291cmNlLmVuZCAgPSB7IGxpbmU6IHRva2VuWzRdLCBjb2x1bW46IHRva2VuWzVdIH07XG5cbiAgICAgICAgICAgIGxldCB0ZXh0ID0gdG9rZW5bMV0uc2xpY2UoMik7XG4gICAgICAgICAgICBpZiAoIC9eXFxzKiQvLnRlc3QodGV4dCkgKSB7XG4gICAgICAgICAgICAgICAgbm9kZS50ZXh0ICAgICAgID0gJyc7XG4gICAgICAgICAgICAgICAgbm9kZS5yYXdzLmxlZnQgID0gdGV4dDtcbiAgICAgICAgICAgICAgICBub2RlLnJhd3MucmlnaHQgPSAnJztcbiAgICAgICAgICAgIH0gZWxzZSB7XG4gICAgICAgICAgICAgICAgbGV0IG1hdGNoID0gdGV4dC5tYXRjaCgvXihcXHMqKShbXl0qW15cXHNdKShcXHMqKSQvKTtcbiAgICAgICAgICAgICAgICBsZXQgZml4ZWQgPSBtYXRjaFsyXS5yZXBsYWNlKC8oXFwqXFwvfFxcL1xcKikvZywgJyovLyonKTtcbiAgICAgICAgICAgICAgICBub2RlLnRleHQgICAgICAgPSBmaXhlZDtcbiAgICAgICAgICAgICAgICBub2RlLnJhd3MubGVmdCAgPSBtYXRjaFsxXTtcbiAgICAgICAgICAgICAgICBub2RlLnJhd3MucmlnaHQgPSBtYXRjaFszXTtcbiAgICAgICAgICAgICAgICBub2RlLnJhd3MudGV4dCAgPSBtYXRjaFsyXTtcbiAgICAgICAgICAgIH1cbiAgICAgICAgfSBlbHNlIHtcbiAgICAgICAgICAgIHN1cGVyLmNvbW1lbnQodG9rZW4pO1xuICAgICAgICB9XG4gICAgfVxuXG59XG4iXX0=
