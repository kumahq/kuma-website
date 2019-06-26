# Konvoy Website
This is the main website and documentation hub for Konvoy. It is built on [VuePress](https://vuepress.vuejs.org/).

### Install
```bash
yarn install
```

### Running
```bash
yarn docs:dev
```
You can now navigate to [http://localhost:8080/](http://localhost:8080/).

### Building
```bash
yarn docs:build
```
This creates a `dist` folder within `.vuepress`.

---

## Writing Documentation
Documentation files are housed in their respective folders within the `docs/master` directory.
The `sidebar` feature within `.vuepress/config.js` is where the sidebar navigation is handled.
I am looking into ways to automatically create that navigation based on documentation folder structure 
so that it doesn't have to be manually updated.
