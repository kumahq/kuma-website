class TabsComponent {
  constructor(elem) {
    this.elem = elem;
    this.options = this.elem.dataset;

    this.addEventListeners();
  }

  addEventListeners() {
    this.elem.querySelectorAll('li.tabs-component-tab').forEach((item) => {
      item.addEventListener('click', this.selectTab.bind(this));
    });

    // Listen for the custom event to update tabs
    document.addEventListener('tabSelected', this.onTabSelected.bind(this));
  }

  selectTab(event) {
    event.stopPropagation();
    if (!this.options['useUrlFragment']) {
      event.preventDefault();
    }
    const selectedTab = event.currentTarget;
    this.setSelectedTab(selectedTab);
    this.dispatchTabSelectedEvent(event.target.dataset.slug);
  }

  hideTabs(selectedTab) {
    selectedTab
      .closest('.tabs-component')
      .querySelectorAll(':scope > .tabs-component-tabs > .tabs-component-tab')
      .forEach((item) => {
        item.classList.remove('is-active');
        item.querySelector('.tabs-component-tab-a').setAttribute('aria-selected', false);
      });

    selectedTab
      .closest('.tabs-component')
      .querySelectorAll(':scope > .tabs-component-panels > .tabs-component-panel')
      .forEach((item) => {
        item.classList.add('hidden');
        item.setAttribute('aria-hidden', true);
      });
  }

  dispatchTabSelectedEvent(tabSlug) {
    const event = new CustomEvent('tabSelected', { detail: { tabSlug } });
    document.dispatchEvent(event);
  }

  onTabSelected(event) {
    const { tabSlug } = event.detail;
    this.setSelectedTabBySlug(tabSlug);
  }

  onNewMeshServiceChecked(event) {
    // TODO
  }

  setSelectedTab(selectedTab) {
    this.hideTabs(selectedTab);

    selectedTab.classList.add('is-active');
    selectedTab.querySelector('.tabs-component-tab-a').setAttribute('aria-selected', true);

    const tabLink = selectedTab.querySelector('.tabs-component-tab-a');
    const panelId = tabLink.getAttribute('aria-controls');
    const selectedPanel = this.elem.querySelector(`.tabs-component-panel[id="${panelId}"]`);

    selectedPanel.classList.remove('hidden');
    selectedPanel.setAttribute('aria-hidden', false);
  }

  setSelectedTabBySlug(slug) {
    const tab = Array.from(
      this.elem.querySelectorAll('li.tabs-component-tab')
    ).find(tab => tab.querySelector('.tabs-component-tab-a').dataset.slug === slug);

    if (tab) {
      this.setSelectedTab(tab);
    }
  }
}

export default class Tabs {
  constructor() {
    document.querySelectorAll('.tabs-component').forEach((elem) => {
      new TabsComponent(elem);
    });
  }
}
