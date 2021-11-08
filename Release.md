# Release process

1. Commit changes
2. Run tests `rake test_with_coverage`, fix tests, commit changes
3. Run `standardrb --fix` , fix issues
4. Update version number in JAT_VERSION file
5. Make local gem release `gem build jat.gemspec`
6. Run examples `rake examples` and fix all errors if any.
7. Repeat `standardrb --fix`, `rake test_with_coverage`, `gem build jat.gemspec`, `rake examples` until you have any changes
8. Commit all changes except JAT_VERSION file
9. Commit JAT_VERSION, CHANGELOG, README.
10. Add tag `git tag -a v$(cat "JAT_VERSION") -m v$(cat "JAT_VERSION")`
11. Commit and push changes `git push origin master`
12. Push gem `gem push jat-$(cat "JAT_VERSION").gem`
