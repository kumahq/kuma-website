class TabsComponent {
  constructor(elem) {
    this.elem = elem;
    this.options = this.elem.dataset;

    this.addEventListeners();
    this.setInitialMeshServiceState(localStorage.getItem("meshservice"))
    this.currentTabSlug = "Kubernetes"
  }

  addEventListeners() {
    this.elem.querySelectorAll('li.tabs-component-tab').forEach((item) => {
      item.addEventListener('click', this.selectTab.bind(this));
    });

    this.elem.querySelectorAll('.meshservice input').forEach((item) => {
      item.addEventListener('change', this.onNewMeshServiceChanged.bind(this));
    });

    // Listen for the custom event to update tabs
    document.addEventListener('tabSelected', this.onTabSelected.bind(this));
  }

  setInitialMeshServiceState(checked) {
    localStorage.setItem("meshservice", checked)
    this.elem.querySelectorAll('.meshservice input').forEach((item) => {
      if (checked === "true") {
        item.setAttribute("checked", checked)
      }
    });
    this.hideMeshServiceTabs(checked)
  }

  hideMeshServiceTabs(checked) {
    // do nothing on non meshservice capable elements
    if (this.elem.querySelectorAll('.tabs-component-tabs a[data-slug$="­"]').length === 0) {
      return
    }

    const that = this
    this.elem.querySelectorAll('.tabs-component-tabs a[data-slug$="­"]').forEach((item) => {
      if (checked === "false") {
        item.parentElement.hidden = true
        item.parentElement.classList.remove("is-active")
      } else if (checked === "true") {
        item.parentElement.hidden = false
        if (item.attributes['aria-controls'].nodeValue.includes(that.currentTabSlug)) {
          item.parentElement.classList.add("is-active")
        }
      }
    });
    this.elem.querySelectorAll('.tabs-component-tabs a:not([data-slug$="­"])').forEach((item) => {
      if (checked === "true") {
        item.parentElement.hidden = true
        item.parentElement.classList.remove("is-active")
      } else if (checked === "false") {
        item.parentElement.hidden = false
        if (item.attributes['aria-controls'].nodeValue.includes(that.currentTabSlug)) {
          item.parentElement.classList.add("is-active")
        }
      }
    });
  }

  selectTab(event) {
    event.stopPropagation();
    if (!this.options['useUrlFragment']) {
      event.preventDefault();
    }
    event.target.scrollIntoView({ behavior: "smooth", block: "start" });
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
    this.currentTabSlug = tabSlug
  }

  onNewMeshServiceChanged(event) {
    if (event.currentTarget.checked === true) {
      localStorage.setItem("meshservice", "true")
      this.hideMeshServiceTabs("true")
    } else {
      localStorage.setItem("meshservice", "false")
      this.hideMeshServiceTabs("false")
    }
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
