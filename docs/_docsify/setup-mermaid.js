// Set up mermaid renderer

(function() {
  var num = 0;
  mermaid.initialize({ startOnLoad: false });

  if (!window.$docsify.markdown) window.$docsify.markdown = {};
  if (!window.$docsify.markdown.renderer) window.$docsify.markdown.renderer = {};

  window.$docsify.markdown.renderer.code = function(code, lang) {
    if (lang === 'mermaid') {
      return '<div class="mermaid">' + mermaid.render('mermaid-svg-' + num++, code) + '</div>';
    }
    return this.origin.code.apply(this, arguments);
  };
})();
