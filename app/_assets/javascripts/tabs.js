class TabsComponent {
  constructor(elem) {
    this.currentTabSlug = "Kubernetes"
    this.elem = elem;
    this.options = this.elem.dataset;

    this.addEventListeners();
    this.setInitialMeshServiceState(JSON.parse(localStorage.getItem("meshservice")) || false)
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
    // hide meshservice if not avilable
    if (this.elem.querySelectorAll('.tabs-component-tabs a[data-slug$="­"]').length === 0) {
      this.elem.querySelectorAll('.meshservice')[0].classList.add("hidden")
      return
    }

    localStorage.setItem("meshservice", JSON.stringify(checked))
    this.elem.querySelectorAll('.meshservice input').forEach((item) => {
      if (checked === true) {
        item.setAttribute("checked", checked)
      }
    });
    this.hideMeshServiceTabs(checked)
  }

  hideMeshServiceTabs(checked) {
    // do nothing on non meshservice capable elements
    if (!this.hasMeshServiceSupport()) {
      return
    }

    this.elem.querySelectorAll('.tabs-component-tabs a[data-slug$="­"]').forEach((item) => {
      if (!checked) {
        this.hideMeshServiceTab(item, true)
      } else {
        this.unhideMeshServiceTab(item)
      }
    });
    this.elem.querySelectorAll('.tabs-component-tabs a:not([data-slug$="­"])').forEach((item) => {
      if (checked) {
        this.hideMeshServiceTab(item, false)
      } else {
        this.unhideMeshServiceTab(item)
      }
    });
  }

  hasMeshServiceSupport() {
    return this.elem.querySelectorAll('.tabs-component-tabs a[data-slug$="­"]').length > 0
  }

  unhideMeshServiceTab(item) {
    item.parentElement.classList.remove("hidden")
    if (this.isShyEquivalent(item.attributes['aria-controls'].nodeValue, this.currentTabSlug)) {
      item.parentElement.classList.add("is-active")
      item.click()
    }
  }

  hideMeshServiceTab(item, isMeshService) {
    item.parentElement.classList.add("hidden")
    item.parentElement.classList.remove("is-active")
    const selector = isMeshService ? '.tabs-component-tabs a:not([data-slug$="­"])' : '.tabs-component-tabs a[data-slug$="­"]'
    this.elem.querySelectorAll(selector).forEach((item) => {
      if (this.isShyEquivalent(item.attributes['aria-controls'].nodeValue, this.currentTabSlug)) {
        item.parentElement.classList.add("is-active")
        item.click()
      }
    })
  }

  isShyEquivalent(value1, value2) {
    return value1.includes(value2) || value2.includes(value1)
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
    // if (tabSlug.includes("­")) {
    //   console.log(tabSlug + "shy")
    // } else {
    //   console.log(tabSlug)
    // }
  }

  onNewMeshServiceChanged(event) {
    if (event.currentTarget.checked === true) {
      localStorage.setItem("meshservice", JSON.stringify(true))
      this.hideMeshServiceTabs(true)
    } else {
      localStorage.setItem("meshservice", JSON.stringify(false))
      this.hideMeshServiceTabs(false)
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
    let elems
    if (slug.includes("­")) {
      console.log(slug + "shy")
    } else {
      console.log(slug)
    }
    if (this.hasMeshServiceSupport() && slug.includes("­")) {
      const childElems= this.elem.querySelectorAll('li.tabs-component-tab a[data-slug$="­"]')
      elems = [...childElems].map(e => e.parentElement)
    } else {
      elems = this.elem.querySelectorAll('li.tabs-component-tab')
    }

    const tab = Array.from(
      elems
    ).find(tab => {
      return this.isShyEquivalent(tab.querySelector('.tabs-component-tab-a').dataset.slug, slug)
    });

    if (tab) {
      console.log(tab)
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
