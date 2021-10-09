# Release process

1. Run tests `rake test`, fix tests, commit changes
2. Run `standardrb --fix` , fix issues
3. Update version number in JAT_VERSION file
4. Make local gem release `gem build jat.gemspec`
5. Run examples `rake examples` and fix all errors if any.
6. Repeat `standardrb --fix`, `rake test`, `gem build jat.gemspec`, `rake examples` until you have any chnages
7. Update CHANGELOG.md if needed
8. Update README.md if needed
9. Commit changes
9. Push gem `gem push jat-VERSION.gem`
