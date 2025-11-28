export default class SchemaViewer {
  static TRUNCATE_LENGTH = 100;
  static FILTER_DEBOUNCE_MS = 150;

  constructor() {
    this.viewers = Array.from(document.querySelectorAll('.schema-viewer'));
    if (this.viewers.length === 0) return;

    this.collapsedStates = new WeakMap();
    this.filterTimers = new WeakMap();

    this.viewers.forEach(viewer => this.initViewer(viewer));
  }

  initViewer(viewer) {
    this.addToolbar(viewer);
    this.addEventHandlers(viewer);
  }

  addToolbar(viewer) {
    if (viewer.querySelector('.schema-viewer__toolbar')) return;

    const toolbar = document.createElement('div');
    toolbar.className = 'schema-viewer__toolbar';
    toolbar.innerHTML = `
      <input type="text" class="schema-viewer__search" placeholder="Filter fields..." aria-label="Filter schema fields" />
      <button type="button" class="schema-viewer__btn schema-viewer__btn--expand-all">Expand all</button>
      <button type="button" class="schema-viewer__btn schema-viewer__btn--collapse-all">Collapse all</button>
    `;

    const searchInput = toolbar.querySelector('.schema-viewer__search');
    searchInput.addEventListener('input', (e) => {
      const timer = this.filterTimers.get(viewer);
      if (timer) clearTimeout(timer);

      const newTimer = setTimeout(() => {
        this.filterFields(viewer, e.target.value);
      }, SchemaViewer.FILTER_DEBOUNCE_MS);

      this.filterTimers.set(viewer, newTimer);
    });

    toolbar.querySelector('.schema-viewer__btn--expand-all').addEventListener('click', () => {
      this.expandAll(viewer);
    });

    toolbar.querySelector('.schema-viewer__btn--collapse-all').addEventListener('click', () => {
      this.collapseAll(viewer);
    });

    viewer.insertBefore(toolbar, viewer.firstChild);
  }

  addEventHandlers(viewer) {
    viewer.addEventListener('click', (event) => {
      const header = event.target.closest('.schema-viewer__header');
      if (header) this.handleToggle(header);

      const showMoreBtn = event.target.closest('.schema-viewer__show-more');
      if (showMoreBtn) this.handleShowMore(showMoreBtn);
    });

    viewer.addEventListener('keydown', (event) => {
      if (event.key !== 'Enter' && event.key !== ' ') return;

      const showMoreBtn = event.target.closest('.schema-viewer__show-more');
      if (showMoreBtn) {
        event.preventDefault();
        this.handleShowMore(showMoreBtn);
        return;
      }

      const header = event.target.closest('.schema-viewer__header');
      if (!header) return;
      event.preventDefault();
      this.handleToggle(header);
    });
  }

  handleToggle(header) {
    const node = header.closest('.schema-viewer__node');
    if (!node || !node.classList.contains('schema-viewer__node--expandable')) return;
    this.toggleNode(node);
  }

  toggleNode(node) {
    const isCollapsed = node.classList.toggle('schema-viewer__node--collapsed');
    const header = node.querySelector('.schema-viewer__header');
    if (header) header.setAttribute('aria-expanded', !isCollapsed);
  }

  expandAll(viewer) {
    viewer.querySelectorAll('.schema-viewer__node--collapsed').forEach(node => {
      node.classList.remove('schema-viewer__node--collapsed');
      const header = node.querySelector('.schema-viewer__header');
      if (header) header.setAttribute('aria-expanded', 'true');
    });
  }

  collapseAll(viewer) {
    viewer.querySelectorAll('.schema-viewer__node--expandable').forEach(node => {
      node.classList.add('schema-viewer__node--collapsed');
      const header = node.querySelector('.schema-viewer__header');
      if (header) header.setAttribute('aria-expanded', 'false');
    });
  }

  handleShowMore(button) {
    const description = button.closest('.schema-viewer__description');
    if (!description) return;

    const textSpan = description.querySelector('.schema-viewer__description-text');
    const fullText = description.dataset.fullText;
    if (!textSpan || !fullText) return;

    const isExpanded = button.textContent === 'show less';
    if (isExpanded) {
      const truncated = fullText.substring(0, SchemaViewer.TRUNCATE_LENGTH);
      textSpan.textContent = truncated + '...';
      button.textContent = 'show more';
      button.setAttribute('aria-expanded', 'false');
    } else {
      textSpan.textContent = fullText;
      button.textContent = 'show less';
      button.setAttribute('aria-expanded', 'true');
    }
  }

  filterFields(viewer, searchTerm) {
    const term = searchTerm.toLowerCase().trim();
    const nodes = Array.from(viewer.querySelectorAll('.schema-viewer__node'));

    if (!term) {
      this.restoreCollapsedStates(viewer, nodes);
      nodes.forEach(node => node.classList.remove('schema-viewer__node--filtered'));
      return;
    }

    this.saveCollapsedStates(viewer, nodes);

    const matchResults = new Map();
    nodes.forEach(node => {
      matchResults.set(node, this.nodeMatches(node, term));
    });

    nodes.forEach(node => {
      const matches = matchResults.get(node);
      const hasMatchingDescendant = this.hasMatchingDescendantCached(node, matchResults);

      if (matches || hasMatchingDescendant) {
        node.classList.remove('schema-viewer__node--filtered');
        if (hasMatchingDescendant && !matches) {
          node.classList.remove('schema-viewer__node--collapsed');
          const header = node.querySelector('.schema-viewer__header');
          if (header) header.setAttribute('aria-expanded', 'true');
        }
      } else {
        node.classList.add('schema-viewer__node--filtered');
      }
    });

    this.ensureParentsVisible(viewer);
  }

  saveCollapsedStates(viewer, nodes) {
    if (this.collapsedStates.has(viewer)) return;

    const states = new Map();
    nodes.forEach(node => {
      states.set(node, node.classList.contains('schema-viewer__node--collapsed'));
    });
    this.collapsedStates.set(viewer, states);
  }

  restoreCollapsedStates(viewer, nodes) {
    const states = this.collapsedStates.get(viewer);
    if (!states) return;

    nodes.forEach(node => {
      const wasCollapsed = states.get(node);
      if (wasCollapsed === undefined) return;

      const header = node.querySelector('.schema-viewer__header');
      if (wasCollapsed) {
        node.classList.add('schema-viewer__node--collapsed');
        if (header) header.setAttribute('aria-expanded', 'false');
      } else {
        node.classList.remove('schema-viewer__node--collapsed');
        if (header) header.setAttribute('aria-expanded', 'true');
      }
    });

    this.collapsedStates.delete(viewer);
  }

  nodeMatches(node, term) {
    const nameEl = node.querySelector('.schema-viewer__header .schema-viewer__name');
    const descEl = node.querySelector('.schema-viewer__content .schema-viewer__description-text');

    const name = nameEl ? nameEl.textContent.toLowerCase() : '';
    const desc = descEl ? descEl.textContent.toLowerCase() : '';

    return name.includes(term) || desc.includes(term);
  }

  hasMatchingDescendant(node, term) {
    const children = node.querySelectorAll('.schema-viewer__node');
    return Array.from(children).some(child => this.nodeMatches(child, term));
  }

  hasMatchingDescendantCached(node, matchResults) {
    const children = node.querySelectorAll('.schema-viewer__node');
    return Array.from(children).some(child => matchResults.get(child));
  }

  ensureParentsVisible(viewer) {
    const matchedNodes = Array.from(viewer.querySelectorAll('.schema-viewer__node'))
      .filter(node => !node.classList.contains('schema-viewer__node--filtered'));

    matchedNodes.forEach(node => {
      let parent = node.parentElement;
      while (parent && parent !== viewer) {
        if (parent.classList.contains('schema-viewer__node')) {
          parent.classList.remove('schema-viewer__node--filtered');
        }
        parent = parent.parentElement;
      }
    });
  }
}
