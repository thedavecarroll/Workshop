$CurrentBranch = (git branch | Select-Object -First 1).Replace('*','').Trim()
"Current branch '{0}'" -f $CurrentBranch
git checkout master
git fetch --all
git rebase upstream/master
git push -u origin master
git checkout $CurrentBranch