(function(win) {
  win.EditOnGithubPlugin = {};

  function create(opts) {
    if (!opts.repo) throw new Error('Must specify at least repo dir');

    opts = opts || {};
    opts.title = opts.title || 'Edit on github';
    opts.docDir = opts.docDir == null ? 'docs' : opts.docDir;

    function getEditUrl(docName, frontmatter) {
      if (frontmatter && frontmatter.noEdit) return null;
      let url = [];
      if (frontmatter && frontmatter.originalPath) {
        url = [opts.repo, 'edit/master', frontmatter.originalPath];
      } else {
        url = [opts.repo, 'edit/master', opts.docDir, docName];
      }
      return url.filter(item => item).join('/');
    }

    return function(hook, vm) {
      hook.afterEach(function(html) {
        let editLink = getEditUrl(vm.route.file, vm.frontmatter);
        var header = [
          '<div style="overflow: auto">',
          '<p style="float: right"><a href="',
          editLink,
          '" target="_blank">',
          opts.title,
          '</a></p>',
          '</div>',
        ].join('');
        return editLink ? header + html : html;
      });
    };
  }

  win.EditOnGithubPlugin.create = create;
})(window);
