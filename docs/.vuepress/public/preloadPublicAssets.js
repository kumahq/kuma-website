/**
 * Public Assets Preloader
 * 
 * This function handles the preloading of all image
 * assets for the documentation pages since they are
 * stored in the static `public` folder and not run
 * through the webpack pipeline.
 */
function preloadPublicAssets() {
  var xhr = new XMLHttpRequest();
  var manifest = '/images/docs/manifest.json';

  // create the DOM container where our images will go (for caching)
  var preloadContainer = document.createElement("div");
  preloadContainer.setAttribute("id", "preloadedImages");
  preloadContainer.style.display = "none";
  document.body.appendChild(preloadContainer);

  // set the response type and open the connection
  xhr.responseType = "json";
  xhr.open('GET', manifest, true);

  // iterate through the images and append for preloading
  xhr.onload = function() {
    if (this.status === 200) {
      var res = JSON.parse(JSON.stringify(this.response));
      var children = res.children;

      children.forEach( function(item) {
        var subChildren = item.children;
        subChildren.forEach( function(subItem) {
          // 1. clean up the path for public use
          var src = subItem.path.replace("docs/.vuepress/public", "");

          // 2. create the new image element
          var image = new Image();

          // 3. assign a src value to each created image
          image.src = src;

          // 4. append the images to a hidden container for caching
          preloadContainer.appendChild(image);
        });
      })
    }
    else {
      console.log("There was an error preloading public assets.");
    }
  };

  // for debugging only
  console.log(preloadContainer);

  xhr.send();
}

/** run the preloader */
window.onload = preloadPublicAssets();