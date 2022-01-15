# Release process

1. Commit changes
2. Run tests `bundle exec rake`, fix tests, commit changes
3. Run `bundle exec standardrb --fix` , fix issues
4. Update version number in JAT_VERSION file
5. Make local gem release `gem build jat.gemspec`
6. Run examples `bundle exec rake examples` and `bundle exec rake benchmarks` and fix all errors if any.
7. Repeat `bundle exec standardrb --fix`, `bundle exec rake`, `gem build jat.gemspec`, `bundle exec rake examples`, `bundle exec rake benchmarks` until you have any changes
8. Commit all changes except JAT_VERSION file
9. Commit JAT_VERSION, CHANGELOG, README.
10. Add tag `git tag -a v$(cat "JAT_VERSION") -m v$(cat "JAT_VERSION")`
11. Commit and push changes `git push origin master`
12. Push tags `git push origin --tags`
13. Push gem `gem push jat-$(cat "JAT_VERSION").gem`
