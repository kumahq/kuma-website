export default class Sidebar {
  constructor() {
    this.elem = document.querySelector(
      ".theme-container:not(.no-sidebar) #sidebar"
    );

    if (this.elem !== null) {
      this.groups = Array.from(
        this.elem.querySelectorAll(".sidebar-links li .sidebar-group")
      );

      this.addEventListener();
      this.expandActiveGroup();
      this.setActiveLink();
    }
  }

  addEventListener() {
    this.elem.addEventListener("click", (event) => {
      if (
        event.target.classList.contains("sidebar-heading") ||
        event.target.parentNode.classList.contains("sidebar-heading")
      ) {
        let group = event.target.closest(".sidebar-group");
        let hidden = group
          .querySelector(".sidebar-group-items")
          .classList.contains("hidden");

        this.groups.forEach((group) => this.toggleGroup(group, true));
        this.toggleGroup(group, !hidden);

        this.expandGroups(group, false);
      } else if (event.target.classList.contains("sidebar-link")) {
        const activeLink = this.elem.querySelector(
          ".sidebar-sub-header .sidebar-link.active"
        );
        if (activeLink !== null) {
          activeLink.classList.remove("active");
        }
        event.target.classList.add("active");
      }
    });
  }

  toggleGroup(group, hide) {
    let items = group.querySelector(".sidebar-group-items");
    let arrow = group.querySelector(".arrow");

    arrow.classList.toggle("down", !hide);
    arrow.classList.toggle("right", hide);

    items.classList.toggle("hidden", hide);
  }

  // Expand all parent groups of the passed in `group`
  expandGroups(currentGroup, includeCurrent) {
    const parents = [];
    let parentGroup;

    if (includeCurrent) {
      parents.push(currentGroup);
    }

    while ((parentGroup = currentGroup.parentNode.closest(".sidebar-group"))) {
      parents.push(parentGroup);
      currentGroup = parentGroup;
    }

    for (let parent of parents) {
      this.toggleGroup(parent, false);
    }
  }

  expandActiveGroup() {
    const currentPath = window.location.pathname;
    const activeLink = this.elem.querySelector(`a[href='${currentPath}']`);
    this.expandGroups(activeLink.closest(".sidebar-group"), true);
  }

  setActiveLink() {
    let currentPath = window.location.pathname;
    if (window.location.hash) {
      currentPath += window.location.hash;
    }

    let activeElement = this.elem.querySelector(`a[href='${currentPath}']`);

    if (activeElement !== null) {
      activeElement.classList.add("active");
    }
  }
}
