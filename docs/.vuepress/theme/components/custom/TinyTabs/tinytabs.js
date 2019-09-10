/*
	tinytabs
	A tiny Javascript library for rendering tabbed UIs.

	Kailash Nadh (https://nadh.in), June 2019.
	MIT License
*/

// (function() {
    // export function tinytabs (container, newOpts) {
        var tinytabs = function(container, newOpts) {
            var opts = {
              anchor: true,
              hideTitle: true,
              sectionClass: "section",
              tabsClass: "tabs",
              tabClass: "tab",
              titleClass: "title",
              selClass: "sel"
            };
            
            var tabs = [], sections = {};
                opts = Object.assign(opts, newOpts);
      
          create();
      
            // Initialize.
          function create() {
              tabs = document.createElement("nav");
              tabs.classList.add(opts.tabsClass);
              container.classList.add("tinytabs");
              container.prepend(tabs);
        
              // Create individual tabs from sections.
              var all = container.querySelectorAll(" ." + opts.sectionClass);
              Array.from(all).map(section => {
                var id = section.getAttribute("id"),
                    title = section.querySelector("." + opts.titleClass);
        
                // Tab section has to have an ID.
                if (!id) return true;
        
                sections[id] = section;
                opts.hideTitle ? hide(title) : null;
        
                // Create close element inside tab.
                var span = document.createElement("span");
                span.classList.add("close");
                span.setAttribute("data-id", "close-" + id);
                span.innerHTML = "×";
        
                // Create the tab handle.
                var a = document.createElement("a");
                a.classList.add(opts.tabClass, "tab-" + id);
                a.setAttribute("href", "#tab-" + id);
                a.setAttribute("data-id", id);
                a.innerHTML = title.innerHTML;
                if (opts.closable) {
                  a.appendChild(span);
                }
      
                span.onclick = function(event) {
        
                  // get selected tab
                  var getDataId = this.getAttribute("data-id").split("-")[1],
                      currentTab = document.querySelector(".tab-"+getDataId),
                      nextTab = currentTab.nextElementSibling,
                      prevTab = currentTab.previousElementSibling,
                      section = document.querySelector("#"+getDataId);
        
                  // remove current tab and section container
                  currentTab.parentNode.removeChild(currentTab);
                  section.parentNode.removeChild(section);
        
                  // callback on close
                  opts.onClose && opts.onClose(id);
        
                  // choose next tab on closing current tab if not choose prev tab
                  if (nextTab) {
                    activate(nextTab.getAttribute("data-id"));
                  } else if (prevTab) {
                    activate(prevTab.getAttribute("data-id"));
                  }
        
                  // prevent parent's onclick event from firing when close elem is clicked
                  // technically preventing event bubbling
                  event.stopPropagation();
                  // tells the browser to stop following events
                  return false;
                };
        
                a.onclick = function() {
                  activate(this.getAttribute("data-id"));
                  return opts.anchor;
                };
        
                // Add the tab to the tabs list.
                tabs.appendChild(a);
              });
        
              // Is anchoring enabled?
              var href = document.location.hash.replace("#tab-", "");
              if (opts.anchor && href) {
                activate(href);
              } else {
                for (var id in sections) {
                  activate(id);
                  break;
                }
              }
            }
      
            function hide(e) {
              e.style.display = "none";
            }
        
            function show(e) {
              e.style.display = "block";
            }
        
            // activate a tab
            function activate(id) {
              var section = null;
              if (sections[id]) {
                section = sections[id];
              } else {
                return false;
              }
              reset();
        
              var newTab = tabs.querySelector(".tab-" + id);
              if (newTab) {
                newTab.classList.add(opts.selClass);
              }
        
              // before and after callbacks
              opts.onBefore && opts.onBefore(id, newTab);
              show(sections[id]);
              opts.onAfter && opts.onAfter(id, newTab);
              if (opts.anchor) {
                document.location.href = "#tab-" + id;
              }
              return true;
            }
        
            // Reset all tabs.
            function reset() {
              Array.from(tabs.querySelectorAll("." + opts.tabClass)).map(e => e.classList.remove(opts.selClass));
              Object.values(sections).map(e => hide(e));
            }
            
            return this;
          };
        
            export default tinytabs;

            //
            // The below lines break compiling in VuePress.
            // Commented out because they're not needed anyway.
            //

            // if (typeof define === "function" && define.amd) {
            //     define(tinytabs);
            // } else {
            //     window.tinytabs = tinytabs;
            // }
        