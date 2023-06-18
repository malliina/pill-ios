# Pill

Take your pills.

## Distribution

### Setup

Disable "Automatically manage signing" in Xcode.

If you get nonsense errors about provisioning profiles and certificates:

1. Export your certificate from Keychain as a p12 file.
1. Delete the Keychain entry.
1. Double-click the p12 file to reimport the certificate.

### Deployments

GitHub Actions uses fastlane to deploy updates. To deploy, push to the master branch.
