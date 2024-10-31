export default class Sidebar {
  constructor() {
    this.elem = document.querySelector('.theme-container:not(.no-sidebar) #sidebar');

    if (this.elem !== null) {

      this.groups = Array.from(
        this.elem.querySelectorAll('.sidebar-links li .sidebar-group')
      );

      this.addEventListener();
      this.expandActiveGroup();
      this.setActiveLink();
    }
  }

  addEventListener() {
    this.elem.addEventListener('click', (event) => {
      const target = event.target.classList.contains('sidebar-heading')
        ? event.target
        : event.target.closest('.sidebar-heading');

      if (target) {
        const group = target.closest('.sidebar-group');
        const isHidden = group.querySelector('.sidebar-group-items').classList.contains('hidden');

        // Toggle clicked group and collapse others
        this.toggleGroup(group, !isHidden);
        this.groups.filter(g => g !== group).forEach(g => this.toggleGroup(g, true));

        // Expand all parent groups to ensure the clicked group is visible
        let parentGroup = group.parentNode.closest('.sidebar-group');
        while (parentGroup) {
          this.toggleGroup(parentGroup, false);
          parentGroup = parentGroup.parentNode.closest('.sidebar-group');
        }
      } else if (event.target.classList.contains('sidebar-link')) {
        // Manage active state for sidebar links
        const activeLink = this.elem.querySelector('.sidebar-sub-header .sidebar-link.active');
        activeLink?.classList.remove('active');
        event.target.classList.add('active');
      }
    });
  }

  toggleGroup(group, hide) {
    let items = group.querySelector('.sidebar-group-items');
    let arrow = group.querySelector('.arrow');

    arrow.classList.toggle('down', !hide);
    arrow.classList.toggle('right', hide);

    items.classList.toggle('hidden', hide);
  }

  expandActiveGroup() {
    const currentPath = window.location.pathname;
    const activeLink = this.elem.querySelector(`a[href^='${currentPath}']`);
    if (activeLink) {
      const topLevelGroup = activeLink.closest(`.sidebar-group.depth-0`);

      if (topLevelGroup !== null) {
        this.toggleGroup(topLevelGroup);

        const nestedGroup = activeLink.closest(`.sidebar-group.depth-1`);
        if (nestedGroup !== null) {
          this.toggleGroup(nestedGroup);
          nestedGroup.scrollIntoView({ behavior: "smooth", block: "center" });
        } else {
          topLevelGroup.scrollIntoView({ behavior: "smooth", block: "center" });
        }
      }
    }
  }

  setActiveLink() {
    let currentPath = window.location.pathname;
    if (window.location.hash) {
      currentPath += window.location.hash;
    }

    let activeElement = this.elem
      .querySelector(`a[href='${currentPath}']`);

    if (activeElement !== null) {
      activeElement.classList
      .add('active');
    }
  }
}
