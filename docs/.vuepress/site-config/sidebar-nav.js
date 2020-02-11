module.exports = {
  "/docs/draft/": [
    "",
    "documentation/",
    "policies/",
    "other/"
  ],
  "/docs/0.1.0/": [
    "",
    "documentation/",
    "policies/",
    "other/"
  ],
  "/docs/0.1.1/": [
    "",
    "documentation/",
    "policies/",
    "other/"
  ],
  "/docs/0.1.2/": [
    "",
    "documentation/",
    "policies/",
    "other/"
  ],
  "/docs/0.2.0/": [
    "",
    "documentation/",
    "policies/",
    "other/"
  ],
  "/docs/0.2.1/": [
    "",
    "documentation/",
    "policies/",
    "other/"
  ],
  "/docs/0.2.2/": [
    "",
    "documentation/",
    "policies/",
    "other/"
  ],
  "/docs/0.3.0/": [
    "",
    "documentation/",
    "policies/",
    "other/"
  ],
  "/docs/0.3.1/": [
    "",
    "documentation/",
    "policies/",
    "other/"
  ],
  "/docs/0.3.2/": [
    {
      title: "Overview",
      collapsable: true,
      sidebarDepth: 3,
      path: "",
      children: [
        "", // root page (overview/README.md)
        "overview/what-is-kuma",
        "overview/what-is-a-service-mesh",
        "overview/why-kuma",
        "overview/kuma-vs-xyz",
        "overview/vm-and-k8s-support",
      ]
    },
    {
      title: "Documentation",
      collapsable: true,
      sidebarDepth: 3,
      path: "",
      children: [
        "", // root page (documentation/README.md)
        "documentation/backends",
        "documentation/dependencies",
        "documentation/dps-and-data-model",
        "documentation/cli",
        "documentation/kumactl",
        "documentation/gui",
        "documentation/http-api",
        "documentation/security",
        "documentation/networking",
        "documentation/fine-tuning"
      ]
    },
    {
      title: "Policies",
      collapsable: true,
      sidebarDepth: 3,
      path: "",
      children: [
        "", // root page (policies/README.md)
        "policies/applying-policies",
        "policies/mesh",
        "policies/mutual-tls",
        "policies/traffic-permissions",
        "policies/traffic-route",
        "policies/traffic-metrics",
        "policies/traffic-tracing",
        "policies/traffic-log",
        "policies/health-check",
        "policies/proxy-template",
        "policies/general-notes-about-kuma-policies",
        "policies/how-kuma-chooses-the-right-policy-to-apply",
      ]
    },
    {
      title: "Other",
      collapsable: true,
      sidebarDepth: 3,
      path: "",
      children: [
        "", // root page (other/README.md)
        "other/enterprise",
        "other/license"
      ]
    },
  ]
}