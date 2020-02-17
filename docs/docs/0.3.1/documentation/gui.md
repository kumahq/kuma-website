# GUI

Kuma now ships with a basic web-based GUI that will serve as a visual overview of your dataplanes, meshes, and various traffic policies.

The GUI pairs with the HTTP API — Read more about the HTTP API [here](../http-api)

When launching Kuma, the GUI will start by default on port `:5683`. You can access it in your web browser by going to `http://localhost:5683/`.

## Getting Started
When you run the GUI for the first time, you’ll be presented with a simple walkthrough. This will:
1. Confirm that Kuma is running in either Universal or Kubernetes mode
2. Provide instructions on how to add dataplanes (if none have yet been added)
3. Provide a short list of dataplanes found, in order to confirm that things are working accordingly and the app can display information

## Global Overview
Once you’ve completed the setup process, you’ll be sent to the Global Overview. This is a general overview of all of the meshes found. You can then view each entity and see how many dataplanes and traffic permissions, routes, and logs are associated with that mesh.

## Mesh Overviews
If you want to view information regarding a specific mesh, you can select the desired mesh from the pulldown at the top of the sidebar. You can then click on any of the overviews in the sidebar to view the entities and policies associated with that mesh.

## What’s to come
The GUI will eventually serve as a hub to view various metrics, such as latency and number of requests (total and per entity). We will also have charts and other visual tools for measuring and monitoring performance.