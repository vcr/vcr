var documentTitleBase = document.title;

var versions = ["latest"].concat(window.VCR_VERSIONS);
var latestVersion = window.VCR_VERSIONS[0];
var versionSelect = '<select id="version-selector" name="version" class="sidebar-version-select">';
versions.forEach(function (version) {
  var value = version == latestVersion ? "" : version;
  versionSelect = versionSelect + '<option value="' + value + '">' + version + '</value>';
});
versionSelect = versionSelect + '</select>';

window.$docsify = {
  name: '<a id="home-link" class="app-name-link" href="/"><img src="/assets/logo.svg"></a>' +
    versionSelect,
  nameLink: false,
  repo: 'https://github.com/vcr/vcr',
  loadSidebar: true,
  relativePath: true,
  subMaxLevel: 3,
  auto2top: true,
  routerMode: "hash",
  noEmoji: true,
  alias: {
    // '/latest/': 'README.md',
    // '/latest/(.*)': '$1',
    // '/([0-9]+\.[0-9]+)/(.*)': 'https://raw.githubusercontent.com/benoittgt/vcr/v$1.0/docs/$2',
    // '/([0-9]+\.[0-9]+)/': 'https://raw.githubusercontent.com/benoittgt/vcr/v$1.0/docs/README.md',
    // '/(.*)': 'https://raw.githubusercontent.com/benoittgt/vcr/v' + latestVersion + '.0/docs/$1',
    // '/': 'https://raw.githubusercontent.com/benoittgt/vcr/v' + latestVersion + '.0/docs/README.md',
  },
  search: {
    namespace: 'docs-vcr',
    depth: 6,
    pathNamespaces: versions.map(function (v) { return "/" + v })
  },
  namespaces: [
    {
      id: "version",
      values: versions,
      optional: true,
      selector: "#version-selector"
    }
  ],
  plugins: [ ]
}
