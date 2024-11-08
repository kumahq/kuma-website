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

  getActiveLink(includeHash = false) {
    const pathname = window.location.pathname;
    const path = includeHash ? `${pathname}${window.location.hash}` : pathname;

    let activeLink = this.elem.querySelector(`a[href='${path}']`);

    if (!activeLink && path.endsWith('/')) {
      const pathWithoutSlash = path.slice(0, -1);
      activeLink = this.elem.querySelector(`a[href='${pathWithoutSlash}']`);
    }

    return activeLink;
  }

  expandActiveGroup() {
    const activeLink = this.getActiveLink();

    if (activeLink) {
      let group = activeLink.closest('.sidebar-group');

      while (group) {
        this.toggleGroup(group, false);
        group = group.parentElement.closest('.sidebar-group');
      }

      this.elem.querySelector('.sidebar-links')?.scroll({
        top: activeLink.offsetTop,
        behavior: 'smooth'
      });
    }
  }

  setActiveLink() {
    this.getActiveLink(true)?.classList.add('active')
  }
}
