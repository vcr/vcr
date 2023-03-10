#!/usr/bin/env node

// Extracted from https://github.com/benoittgt/docsify-tools
"use strict";
exports.__esModule = true;
var fs = require("fs");
var path = require("path");
var yargs = require("yargs");
var ignores = /node_modules|^\.|_sidebar|_docsify/;
var isDoc = /.md$/;
function niceName(name) {
    var splitName = name.split('-');
    if (Number.isNaN(Number(splitName[0]))) {
        var str = splitName.join(' ').replace(/_/g, ' ');
        return str.charAt(0).toUpperCase() + str.slice(1);
    }
    return splitName.slice(1).join(' ');
}
function buildTree(dirPath, name, dirLink) {
    if (name === void 0) { name = ''; }
    if (dirLink === void 0) { dirLink = ''; }
    var children = [];
    for (var _i = 0, _a = fs.readdirSync(dirPath); _i < _a.length; _i++) {
        var fileName = _a[_i];
        if (ignores.test(fileName))
            continue;
        var fileLink = dirLink + '/' + fileName;
        var filePath = path.join(dirPath, fileName);
        if (fs.statSync(filePath).isDirectory()) {
            var sub = buildTree(filePath, fileName, fileLink);
            if (sub.children != null && sub.children.length > 0)
                children.push(sub);
        }
        else if (isDoc.test(fileName)) {
            children.push({ name: fileName, link: fileLink });
        }
    }
    return { name: name, children: children, link: dirLink };
}
function renderToMd(tree, linkDir) {
    if (linkDir === void 0) { linkDir = false; }
    if (!tree.children) {
        return "- [".concat(niceName(path.basename(tree.name, '.md')), "](").concat(tree.link.replace(/ /g, '%20'), ")");
    }
    else {
        var fileNames_1 = new Set(tree.children.filter(function (c) { return !c.children; }).map(function (c) { return c.name; }));
        var dirNames_1 = new Set(tree.children.filter(function (c) { return c.children; }).map(function (c) { return c.name + '.md'; }));
        var content = tree.children
            .filter(function (c) { return (!fileNames_1.has(c.name) || !dirNames_1.has(c.name)) && c.name != 'README.md'; })
            .map(function (c) { return renderToMd(c, dirNames_1.has(c.name + '.md') && fileNames_1.has(c.name + '.md')); })
            .join('\n')
            .split('\n')
            .map(function (item) { return '  ' + item; })
            .join('\n');
        var prefix = '';
        if (tree.name) {
            if (linkDir || fileNames_1.has('README.md')) {
                var linkPath = tree.link.replace(/ /g, '%20');
                if (fileNames_1.has('README.md'))
                    linkPath += '/README.md';
                prefix = "- [".concat(niceName(path.basename(tree.name, '.md')), "](").concat(linkPath, ")\n");
            }
            else
                prefix = "- ".concat(niceName(tree.name), "\n");
        }
        return prefix + content;
    }
}
var args = yargs
    .wrap(yargs.terminalWidth() - 1)
    .usage('$0 [-d docsDir] ')
    .options({
    docsDir: {
        alias: 'd',
        type: 'string',
        describe: 'Where to look for the documentation (defaults to docs subdir of repo directory)'
    }
}).argv;
var dir = path.resolve(process.cwd(), args.docsDir || './docs');
try {
    var root = buildTree(dir);
    fs.writeFileSync(path.join(dir, '_sidebar.md'), renderToMd(root));
}
catch (e) {
    console.error('Unable to generate sidebar for directory', dir);
    console.error('Reason:', e.message);
    process.exit(1);
}
