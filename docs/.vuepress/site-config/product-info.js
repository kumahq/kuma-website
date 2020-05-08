/**
 * Product information
 *
 * This data is used throughout the site for
 * SEO, meta, deployment, sitemap building, etc.
 */

// generate a random string for cache busting
const randStr = Math.random().toString(36).substring(2, 8)

module.exports = {
  title: "Kuma",
  description: "Build, Secure and Observe your modern Service Mesh",
  twitter: "KumaMesh",
  author: "Kong",
  websiteRepo: "https://github.com/Kong/kuma-website",
  repo: "https://github.com/Kong/kuma",
  repoButtonLabel: "Star",
  logo: "/images/brand/kuma-logo-new.svg",
  hostname: "https://kuma.io",
  cliNamespace: "kumactl",
  slackInviteURL: "https://chat.kuma.io",
  slackChannelURL: "https://kuma-mesh.slack.com",
  gaCode: "UA-8499472-30",
  ogImage: "/images/social/og-image.jpg",
  fbAppId: "682375632267551",
  cacheBuster: `cb=${randStr}`
}