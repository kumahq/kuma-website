export default class SchemaViewer {
  constructor() {
    this.viewers = Array.from(document.querySelectorAll('.schema-viewer'));
    if (this.viewers.length === 0) return;

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
      <button type="button" class="schema-viewer__btn schema-viewer__btn--expand-all">Expand all</button>
      <button type="button" class="schema-viewer__btn schema-viewer__btn--collapse-all">Collapse all</button>
    `;

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
      const truncated = fullText.substring(0, 100);
      textSpan.textContent = truncated + '...';
      button.textContent = 'show more';
    } else {
      textSpan.textContent = fullText;
      button.textContent = 'show less';
    }
  }
}
