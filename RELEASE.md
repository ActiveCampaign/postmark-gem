New versions of the gem are cut by the Postmark team, this is a quick guide to ensuring a smooth release.

1. Determine the next version of the gem by following the [SemVer](https://semver.org/) guidelines.
1. Verify all builds are passing on CircleCI for your branch.
1. Merge in your branch to main.
1. Update VERSION and lib/postmark/version.rb with the new version.
1. Update CHANGELOG.rdoc with a brief description of the changes.
1. Commit to git with a comment of "Bump version to x.y.z".
1. run `rake release` - This will push to github(with the version tag) and rubygems with the version in lib/postmark/version.rb.
  *Note that if you're on Bundler 1.17 there's a bug that hides the prompt for your OTP. If it hangs after adding the tag then it's asking for your OTP, enter your OTP and press Enter. Bundler 2.x and beyond resolved this issue. *
1. Verify the new version is on [github](https://github.com/ActiveCampaign/postmark-gem) and [rubygems](https://rubygems.org/gems/postmark).
1. Create a new release for the version on [Github releases](https://github.com/ActiveCampaign/postmark-gem/releases).
1. Add or update any related content to the [wiki](https://github.com/ActiveCampaign/postmark-gem/wiki).
