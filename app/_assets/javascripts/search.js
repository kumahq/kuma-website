document.addEventListener('DOMContentLoaded', () => {
  const container = document.getElementById('docsearch');
  if (!container) return;

  const docsVersion = window.location.pathname.split('/')[2];

  docsearch({
    container: '#docsearch',
    appId: 'RSEEOBCB49',
    indexName: 'kuma',
    apiKey: '4224b11bee5bf294f73032a4988a00ea',
    searchParameters: {
      facetFilters: ['section:docs', `docsversion:${docsVersion}`]
    },
    transformItems(items) {
      return items.map((item) => ({
        ...item,
        url: item.url.replace('https://kuma.io', '')
      }));
    }
  });
});
