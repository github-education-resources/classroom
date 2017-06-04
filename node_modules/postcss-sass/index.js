var postcss = require('postcss');
var gonzales = require('gonzales-pe');
var Input = require('postcss/lib/input');
var math = require('mathjs');

var DEFAULT_RAWS_ROOT = {
    semicolon: false,
    after: ''
};

var DEFAULT_RAWS_RULE = {
    before: '',
    between: ' ',
    semicolon: false,
    after: ''
};

var DEFAULT_RAWS_DECL = {
    before: '',
    between: ': ',
    semicolon: false
};

function process(
    source,
    node,
    parent,
    input,
    selector
) {
    if (node.type === 'stylesheet') {
        // Create and set parameters for Root node
        var root = postcss.root();
        root.source = {
            start: node.start,
            end: node.end,
            input: input
        };
        root.raws = DEFAULT_RAWS_ROOT;
        for (var i = 0; i < node.content.length; i++) {
            process(source, node.content[i], root, input, selector);
        }
        return root;
    } else if (node.type === 'ruleset') {
        // Loop to find the deepest ruleset node
        var pseudoClassFirst = false;
        for (var rContent = 0; rContent < node.content.length; rContent++ ) {
            if (node.content[rContent].type === 'block') {
                // Create Rule node
                var rule = postcss.rule();
                // Object to store raws for Rule
                var rRaws = {};

                // Looking for all block nodes in current ruleset node
                for (
                    var rCurrentContent = 0;
                    rCurrentContent < node.content.length;
                    rCurrentContent++
                ) {
                    if (node.content[rCurrentContent].type === 'block') {
                        process(
                            source,
                            node.content[rCurrentContent],
                            rule,
                            input
                        );
                    } else if (node.content[rCurrentContent].type === 'space') {
                        if (!rRaws.between) {
                            rRaws.between = node
                                .content[rCurrentContent].content;
                        } else {
                            rRaws.between += node
                                .content[rCurrentContent].content;
                        }
                    }
                }

                if (rule.nodes.length !== 0) {
                    // Write selector to Rule, and remove last whitespace
                    if (selector.slice(-1) === ',') {
                        rule.selector = selector.slice(0, -1);
                    } else {
                        rule.selector = selector;
                    }

                    if (selector.charAt(0) === ' ') {
                        rule.selector = selector.substring(1);
                    }
                    // Set parameters for Rule node
                    rule.parent = parent;
                    rule.source = {
                        start: node.start,
                        end: node.end,
                        input: input
                    };
                    if (Object.keys(rRaws).length > 0) {
                        rule.raws = rRaws;
                    } else {
                        rule.raws = DEFAULT_RAWS_RULE;
                    }
                    parent.nodes.push(rule);
                }

                for (
                    var bNextContent = 0;
                    bNextContent < node.content[rContent].length;
                    bNextContent++
                ) {
                    if (node.content[rContent]
                            .content[bNextContent].type === 'ruleset') {
                        // Add to selector value of current node
                        process(
                            source,
                            node.content[rContent].content[bNextContent],
                            parent,
                            input,
                            selector
                        );
                    }
                }
            } else if (node.content[rContent].type === 'selector') {
                /* Get current selector name
                 It's always have same path,
                 so it's easier to get it without recursion */
                selector += ' ';
                for (
                    var sCurrentContent = 0;
                    sCurrentContent < node.content[rContent].length;
                    sCurrentContent++
                ) {
                    if (node.content[rContent]
                            .content[sCurrentContent].type === 'id') {
                        selector += '#';
                    } else if (node.content[rContent]
                            .content[sCurrentContent].type === 'class') {
                        selector += '.';
                    } else if (node.content[rContent]
                            .content[sCurrentContent].type === 'typeSelector') {
                        if (node.content[rContent]
                                .content[sCurrentContent + 1] &&
                            node.content[rContent]
                                .content[sCurrentContent + 1]
                                .type === 'pseudoClass' &&
                            pseudoClassFirst) {
                            selector = selector.slice(0, -1);
                            selector += ', ';
                        } else {
                            pseudoClassFirst = true;
                        }
                    } else if (node.content[rContent]
                            .content[sCurrentContent].type === 'pseudoClass') {
                        selector += ':';
                    }
                    selector += node.content[rContent]
                        .content[sCurrentContent].content;
                }
            }
        }
    } else if (node.type === 'block') {
        // Looking for declaration node in block node
        for (var bContent = 0; bContent < node.content.length; bContent++) {
            if (node.content[bContent].type === 'declaration') {
                process(
                    source,
                    node.content[bContent],
                    parent,
                    input
                );
            }
        }
        global.blockValue = '';
    } else if (node.type === 'declaration') {
        var isBlockInside = false;
        // Create Declaration node
        var decl = postcss.decl();
        // Object to store raws for Declaration
        var dRaws = {};
        // Looking for property and value node in declaration node
        for (var dContent = 0; dContent < node.content.length; dContent++) {
            if (node.content[dContent].type === 'property') {
                decl.prop = '';
                process(
                    source,
                    node.content[dContent],
                    decl,
                    input
                );
            } else if (node.content[dContent].type === 'propertyDelimiter') {
                if (!dRaws.between) {
                    dRaws.between = node.content[dContent].content;
                } else {
                    dRaws.between += node.content[dContent].content;
                }
            } else if (node.content[dContent].type === 'space') {
                if (!dRaws.between) {
                    dRaws.between = node.content[dContent].content;
                } else {
                    dRaws.between += node.content[dContent].content;
                }
            } if (node.content[dContent].type === 'value') {
                if (node.content[dContent].content[0].type === 'block') {
                    isBlockInside = true;
                    global.blockValue = node.content[0].content[0].content;
                    process(
                        source,
                        node.content[dContent].content[0],
                        parent,
                        input
                    );
                } else if (node.content[dContent].content[0].type === 'color') {
                    decl.value = '#';
                    process(
                        source,
                        node.content[dContent],
                        decl
                    );
                } else if (node.content[dContent]
                        .content[0].type === 'number') {
                    if (node.content[dContent].content.length > 1) {
                        decl.value = '';
                        for (
                            var dCurrentContent = 0;
                            dCurrentContent < node.content[dContent]
                                .content.length;
                            dCurrentContent++
                        ) {
                            decl.value += node.content[dContent]
                                .content[dCurrentContent];
                        }
                        decl.value = math.eval(decl.value).toString();
                    } else {
                        process(
                            source,
                            node.content[dContent],
                            decl
                        );
                    }
                } else {
                    process(
                        source,
                        node.content[dContent],
                        decl
                    );
                }
            }
        }

        if (!isBlockInside) {
            // Set parameters for Declaration node
            decl.source = {
                start: node.start,
                end: node.end,
                input: input
            };
            decl.parent = parent;
            if (Object.keys(dRaws) > 0) {
                dRaws.before = '';
                decl.raws = dRaws;
            } else {
                decl.raws = DEFAULT_RAWS_DECL;
            }
            parent.nodes.push(decl);
        }
    } else if (node.type === 'property') {
        // Set property for Declaration node
        if (global.blockValue && global.blockValue.length > 0) {
            parent.prop += global.blockValue + '-';
            parent.prop += node.content[0].content;
        } else {
            parent.prop += node.content[0].content;
        }
    } else if (node.type === 'value') {
        if (!parent.value) {
            parent.value = '';
        }
        // Set value for Declaration node
        if (node.content[0].content.constructor === Array) {
            for (
                var vContent = 0;
                vContent < node.content[0].content.length;
                vContent++
            ) {
                parent.value += node.content[0].content[vContent].content;
            }
        } else {
            parent.value += node.content[0].content;
        }
    }
    return null;
}

module.exports = function sassToPostCssTree(
    source,
    opts
) {
    var data = {
        node: gonzales.parse(source, { syntax: 'sass' }),
        input: new Input(source, opts),
        parent: null,
        selector: ''
    };
    return process(
        source,
        data.node,
        data.parent,
        data.input,
        data.selector);
};
